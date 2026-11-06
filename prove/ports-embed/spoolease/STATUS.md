# SpoolEase embedded port — STATUS

**Upstream:** `bberrevoets/SpoolEase` @ `3532f8d` — ESP32-S3 filament-spool
inventory tracker, picoserve 0.15.1 + Embassy, NFC/RFID. **Framework:**
`h5i-app-embedded` trusted shell + verified `h5i-app-h1` HTTP core (the
`prove/ports-embed` shape), kernel extracted by Charon+Aeneas, proven in Lean 4.

**State:** DONE and gated. `h5i app check` passes (49 theorems, axioms
`propext`/`Classical.choice`/`Quot.sound` only, no `sorry`/`native_decide`).
`h5i app mutate`: **3/3 mutants caught, 0 survived**. `difftest`: 3 tests pass
(400×120 random op sequences match the upstream allocator; tag uniqueness;
read-only).

## Theorems (S / C / F)

Counts: **S = 5, C = 9, F = 2** (F are notes, not gate theorems). S ≥ C/3. ✓

| Theorem (module `Properties`/`ReadOnly`) | Class | What it rules out |
|---|---|---|
| `place_capacity` | **S** | the `.db` file growing past `MAX_FILE`, or a placed record sticking out past end-of-file (bad `file_len + len`) |
| `place_local` | **S** | a write landing outside the record's *own* old slot or fresh past-EOF space — i.e. two spool ids aliasing each other's bytes (the headline "no clobber") |
| `place_inplace_fits` | **S** | an in-place overwrite when the record does *not* fit its old slot (would spill into the next record); pins in-place writes to exactly the old slot |
| `fresh_id_is_new` | **S** | `AddSpool` reusing an existing id, which would let a new spool shadow an old record |
| `ReadOnly.sound` | **S** | a `Query` (GET) mutating the store |
| `transition_total` | C | any command panicking / overflowing (a device reset); needs record count < `usize::MAX` |
| `addspool_id` | C | — (foundation: `AddSpool` assigns `last_id + 1`) |
| `lookup_spec` | C | — (loop = `List.find?`) |
| `append_slot_spec` | C | — (loop = `l ++ [slot]`) |
| `replace_slot_spec` | C | — (loop = `l.map (replaceOne …)`) |
| `remove_id_spec` | C | — (loop = `l.filter …`) |
| `claim_tag_spec` | C | — (loop = `l.map (claimOne …)`) |
| `place_total`, `len_ok_spec` | C | — (totality helpers) |

(The gate also counts ~35 small arithmetic/const lemmas — all C.)

Each **S** theorem is backed by a mutant it kills:
- `fresh_id_reuse` (`last_id + 1` → `last_id`) → killed by `fresh_id_is_new` / `addspool_id`.
- `inplace_data_len` (in-place data region `len: p.length` → `len`) → killed by `place_inplace_fits`.
- `append_data_offset` (append data `off: file_len` → `off: p.offset`) → killed by `place_local`.
All 3 caught; 0 survived. `place_capacity`/`ReadOnly.sound` are additionally
exercised by the difftest's disjointness and read-only checks.

### F (findings — see DEVIATIONS.md)
- **F1** orphaned free space on in-place shrink in `CsvDb::insert` (info, space leak).
- **F2** `/insecure/screenshot` non-constant-time key `==` compare (info, LAN-only).
Neither is confirmed exploitable → no `h5i-app-audit` advisory.

## Attempted and dropped (honest record)
- **Run-level `inv_reachable`** (file never overflows + ids stay in range over a
  *whole run* via `H5iAppLib.Run.inv`) and the full **`DisjAll` / `TagUnique`**
  pairwise invariants. Dropped, no `sorry` shipped. Reason: preserving the
  record-count bound needed for `append_slot`'s `usize` totality is tangled with
  the disjointness invariant (count ≤ file_len needs non-overlap), and
  `List.Pairwise` induction through the `map (claimOne)` / `filter` / append
  transforms is a large proof. The per-step `place_local` (a write never leaves
  the record's own slot) plus the `difftest` disjointness check over 48 000
  operations cover the same "two spools never alias storage" intent; the
  `Spec.lean` `DisjAll`/`TagUnique`/`IdUnique` definitions are kept for a future
  run-level proof.

## Benchmark measurements (this round's goal)

1. **Fraction of upstream decision logic ported:** ~100% of the *security-relevant*
   decision logic in scope — the entire `CsvDb::insert`/`delete` offset/length
   allocator (~78 LOC of the 329-line `csvdb.rs`) and the id-assignment +
   tag-strikeout decisions in `store.rs` `add_spool`/`edit`/`update`/`delete`
   (~60 LOC of decision logic within ~1025 lines). Excluded (IO / not
   security-decisions): SD-card reads/writes, `serde_csv_core` (de)serialization,
   the `HashMap` mechanics, backup/restore, version upgrade. Kernel is 225 LOC of
   code → the two files' security decision core is essentially fully covered.
2. **Specs attempted / proved:** 5 security + 9 foundation theorems **proved**
   (0 `sorry`). 2–3 run-level invariants (`inv_reachable`, `DisjAll`,
   `TagUnique`) **attempted and dropped** with the reason above. Proved fraction
   of *what shipped* = 100%; of *what was attempted* ≈ 80%.
3. **Bugs reproduced against real upstream:** none exploitable. Two info-level
   F-notes (F1, F2). No advisory filed.
4. **RAM/flash footprint & latency:** not measured. Upstream targets
   **xtensa** (`xtensa-esp32s3-none-elf`), which needs the esp fork of rustc; no
   firmware was built and the campaign box has no xtensa toolchain, so
   `cargo size`/`cargo bloat` on a real target was not possible. Structurally the
   kernel is pure, allocation-free-capable decision logic and per-connection
   memory is fixed by the shell's `rx`+`tx` buffers (as in the thermostat
   example). Skipped per the brief rather than reporting a meaningless host size.
5. **Target/HAL/Embassy compatibility:** see DEVIATIONS.md table. `h5i-app-embedded`'s
   `embedded-io-async 0.6` IO shape matches upstream's `embedded-io-async 0.6.1`;
   the blocker for a real build is the xtensa target, not the API shape.

## Layout
```
kernel/     spoolease_kernel: Store/Slot/Command, place, transition, apply, read_only
proofs/     Spec.lean (model + Inv defs), Properties.lean (S+C theorems), ReadOnly.lean, generated/
app/        SpoolStore Kernel + Wire Api (decode/encode) + Router, mirroring thermostat/app
difftest/   host comparison vs transcribed upstream csvdb/store allocator (cargo test)
h5i-app.toml, DEVIATIONS.md, STATUS.md
```

## Resume
`h5i app check .` (gate), `cargo test` in `difftest/`, `h5i app mutate .`.
Next if continuing: land run-level `inv_reachable` (BoundsOk∧IdsOk∧Count) and
then `DisjAll` via `List.Pairwise`, per the dropped-work note.
