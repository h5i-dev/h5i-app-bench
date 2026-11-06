# SpoolEase embedded port — deviations, trust boundary, threat model

**Upstream:** `bberrevoets/SpoolEase` @ `3532f8d` (pinned, read-only at
`/mnt/scratch/oss-sec/upstream-embed/SpoolEase`). A 3D-printer filament-spool
inventory tracker on an **ESP32-S3** (xtensa), Embassy/esp-rtos, with a
**picoserve 0.15.1** web UI and NFC/RFID tag reading. Workspace crates `core/`
(firmware) and `shared/` (NFC/gcode helpers).

## What this port covers

The security-critical *decision logic* of SpoolEase's on-SD-card inventory
database and NFC-tag index — the "does writing one spool clobber another, and is
the tag↔spool mapping sound" question from the brief:

- `core/src/csvdb.rs` `CsvDb::insert` / `CsvDb::delete` — the allocator that
  maps a record's `id` to a byte slot `[offset, offset+length)` in the single
  append/overwrite `*.db` file: overwrite in place when the new serialization
  fits the old slot, else void the old slot (`-` padding) and append at EOF.
- `core/src/store.rs` `Store::add_spool` / `edit_spool_from_web` /
  `update_spool` / `delete_spool` — fresh id assignment (`id = last_id + 1`) and
  the `tag_id → spool_id` index, "striking out" (prefix `-`) any record that
  previously held an NFC tag now claimed by another spool.

These are ported to `kernel/src/lib.rs` as a pure h5i-app `Kernel`
(`transition`/`apply`/`read_only`) over a `Store = { file_len, last_id,
slots: Vec<Slot> }`, with commands `AddSpool`/`EditSpool`/`DeleteSpool`/`Query`.
The `place` function is the extracted heart of `CsvDb::insert`.

## Deviations from upstream

1. **`alloc`, not heap-free.** The kernel uses `alloc::vec::Vec` for the record
   index, exactly as upstream uses a heap `hashbrown::HashMap` on the S3's PSRAM.
   The ideal embedded kernel is `#![no_std]` + no-alloc with a fixed array; the
   inventory index is inherently dynamic, so I kept `Vec` (the subset Aeneas
   extracts, as the other `prove/ports/*` kernels do). The verified HTTP core
   (`h5i-app-h1`) stays no-alloc. Extracted Lean is identical to a
   `#![no_std] + extern crate alloc` build.
2. **The record index is a `Vec<Slot>`, not a `HashMap<String, CsvRecordInfo>`.**
   Ids are `u32` (upstream stringifies an `i32` counter); tags are `u32`
   (upstream stores NFC uids as hex text, striking out with a leading `-`, which
   we model as clearing the tag to `0`). The mapping and the offset/length
   arithmetic are faithful (verified by `difftest/`).
3. **`place` returns an explicit write `Plan`** (`void` + `data` byte regions)
   so the proofs can talk about exactly which bytes an operation writes. Upstream
   performs those writes inline via `sdcard.write_file_bytes` / `append_bytes`;
   the plan is what the trusted shell would hand the SD driver.
4. **Serialized record length is an input (`len`), not computed by `serde`.**
   Upstream derives it from `serde_csv_core::Writer::serialize`; serialization is
   IO-adjacent and out of scope. The allocator's safety is independent of the
   exact length, so `len` is a `1..=MAX_REC` parameter.
5. **Caps are explicit** (`MAX_FILE = 16 MiB`, `MAX_REC = 4096`,
   `MAX_ID = u32::MAX-1`). Upstream's `.db` file is bounded only by the SD card;
   an explicit cap is what makes the offset arithmetic provably overflow-free
   and is a fail-safe (reject rather than wrap).
6. **Auth is modelled as an `admin` flag.** SpoolEase's web API has **no bearer
   token**: every `/api/*` body is encrypted with a pre-shared key by the
   external `esp-hal-app-framework` crate (`framework_web_app::{encrypt,decrypt}`,
   not in this repo), so a request with the wrong key fails to decrypt before it
   reaches the store. We model that gate as `Device { admin }` and require it for
   mutations. The real crypto and key handling are **trusted** (A2).

## Trust boundary (assumed, not proven)

- The `esp-hal-app-framework` web layer: body encryption/decryption, the
  pre-shared key, the picoserve router and request parsing.
- `serde_csv_core` (de)serialization, the SD-card driver, `hashbrown`, Embassy,
  esp-hal, the xtensa toolchain, Charon/Aeneas/Lean.
- That the device runs the extracted code (`h5i app extract --check` /
  CI re-extract-and-diff, as for the other crates).
- SD-card IO: in particular that `append_bytes` returns the true end-of-file
  offset. The non-aliasing argument depends on appends going to fresh space.

## Target / HAL compatibility (benchmark item 5)

| Thing | Upstream pin |
|---|---|
| MCU / Rust target | ESP32-S3, `xtensa-esp32s3-none-elf` |
| esp-hal / esp-rtos | `1.0.0` / `0.2.0` |
| embassy-executor / -net / -time | `0.9.0` / `0.7.1` / `0.5.0` |
| picoserve | `0.15.1` (alloc + embassy) |
| embedded-io-async | `0.6.1` |

`h5i-app-embedded` is generic over `embedded_io_async::{Read,Write}` 0.6, which
matches upstream's `embedded-io-async 0.6.1`, so the shell's IO shape fits as-is.
The device is **xtensa**, not `thumbv*`, so cross-building firmware needs the esp
fork of rustc; not attempted here (see STATUS benchmark item 4).

## Findings (not confirmed exploitable — kept as F, no advisory)

- **F1 (info): orphaned free space in `CsvDb::insert`.** When an in-place
  overwrite shrinks a record (`serialized_len < prev_length`), upstream sets
  `v.length = serialized_len` but fills the trailing `prev_length -
  serialized_len` bytes with `-`; that region is never reclaimed (a slow space
  leak, bounded by the 16 MiB file). Not a safety or integrity bug.
- **F2 (info): `/insecure/screenshot` key compare.** `web_app.rs` compares the
  query-param `key` to `web_config_key` with `==` (not constant-time) on an
  endpoint explicitly named `insecure`, reachable only on the LAN. A timing
  side-channel in theory; not demonstrably exploitable over the exposed surface.

Neither rises to a standalone `h5i-app-audit` advisory.
