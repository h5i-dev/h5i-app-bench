# M5AirQ-Rust — port deviations and trust boundary

**Upstream:** `andrico21/M5AirQ-Rust` @ `f7e35cb` ("Fix battery disable: default
usb_connected to true"), an ESP32‑S3 air‑quality monitor serving an HTTP/HTTPS
config + telemetry + OTA API with [`picoserve`](https://github.com/sammhicks/picoserve)
`0.18.0` on Embassy.

**This port** re‑implements the two most security‑critical pieces of pure
decision logic as an [`h5i-app`](../../../README.md) kernel in the Aeneas Rust
subset, extracts it to Lean 4 and proves safety/security properties about the
*extracted* code. The trusted async shell is `h5i-app-embedded` + the verified
HTTP/1.1 core `h5i-app-h1` (picoserve‑shaped, hand‑written in the Aeneas subset),
exactly as in `examples/embedded/thermostat`.

## What is covered (in scope)

1. **OTA firmware‑update state machine** — `src/ota.rs`, the high‑level session
   API `begin` (ota.rs:343), `write` (ota.rs:400), `end` (ota.rs:544),
   `abort` (ota.rs:556), `status`. Ported as `transition`/`apply` over an
   `OtaState { active, target_slot, running_slot, total, written, error }`.
2. **HTTP authentication gate** — `src/auth.rs::check_auth` (auth.rs:653),
   `validate_session` (auth.rs:258), session TTL/expiry, the bearer/API‑key
   transport‑security gate, and the `public_access`/health bypasses. Ported as
   `check_auth` + `validate_session`/`slot_valid`/`age_ok`/`ct_eq8`/`is_zero8`.

## Trusted / out of scope (assumed correct, not verified here)

- **The async shell** (`h5i-app-embedded`): socket IO, routing, request
  decoding, reply encoding (A1–A3). As in the thermostat example, the kernel's
  theorems hold for *every* command, so a decoding bug can do no more than a
  client could already ask for.
- **The verified HTTP core** (`h5i-app-h1`): parsing, chunked decoding, head
  writing — proven in its own crate, not re‑proven here.
- **Flash IO and crypto primitives.** The kernel models them as trusted inputs:
  - `End` takes `magic_ok` and `actual_crc`, which upstream computes by reading
    the freshly written image back from flash (`verify_image_header` ota.rs:289,
    `compute_image_crc32_yielding` ota.rs:…). The kernel proves the *decision*
    around them, not the flash read.
  - `check_auth` takes `bearer_match`/`akh_match`/`akq_match` (upstream's
    `constant_time_eq`, auth.rs:…) and `digest_ok` (upstream's `verify_digest`
    MD5, auth.rs:505) as trusted booleans, and `cookie_token` as the already
    XOR‑decrypted session token. The MD5/XOR code itself is not modelled.
- **esp‑hal / Embassy / mbedTLS / esp‑storage**, and the ESP‑IDF bootloader /
  `otadata` format.

## Differences from upstream (and why)

1. **`check_auth` is flattened.** Upstream nests `if present { if https {…} }`
   per credential; the kernel computes the per‑credential booleans first
   (`transport_blocks`, `bearer_block`, `bearer_ok`, …) and decides in one
   linear `if`/`else` chain. The transport (`is_https`, `allow_http_tokens`) is
   fixed per request, so a *blocked* token credential is refused with
   `Forbidden` before any lower‑priority credential — identical behaviour to the
   nested original. A 400 000‑case differential test (`difftest/`) confirms the
   two agree on every combination of inputs.
2. **Non‑short‑circuit `&` for the pre‑computed booleans.** All operands are
   already evaluated, so `a & b` is the same logical AND as `a && b` but
   extracts without an inner branch (Aeneas/`step` cannot step an `if` in
   bind position). Behaviour is unchanged.
3. **`validate_session` is computed unconditionally** and only consulted when a
   cookie is present (`cookie_present & vs`), instead of short‑circuited behind
   `cookie.is_some()`. `validate_session` is pure, so this is observationally
   identical; it just lets the extracted code bind the call directly.
4. **`validate_session` is unrolled over the four fixed slots** instead of a
   `for` loop over `[Session; MAX_SESSIONS]`, so the extraction is loop‑free
   (`MAX_SESSIONS = 4` is a compile‑time constant upstream too).
5. **Session‑expiry arithmetic.** Upstream uses `now.wrapping_sub(created) <=
   TTL`. The kernel's `age_ok` is `if now >= created then now - created <= TTL
   else false`, which is the same predicate (a `now` before `created`, i.e. a
   wrapped/backwards clock, is rejected both ways) and avoids an unsigned
   underflow so the function is total.
6. **Defensive `offset > total` guard in `write`.** Upstream checks
   `offset + data.len() > total` (release build wraps on overflow; debug
   panics). The kernel checks `offset > total` first, then `len > total -
   offset`, which rejects exactly the same chunks without any overflow, so
   `transition` is total for **every** `u32` offset/length. The 400 000‑case
   differential test (using `u64` to mirror the upstream non‑wrapping intent)
   confirms agreement.
7. **`begin` refuses `running_slot > 1`** (not just the `0xFF` sentinel) before
   computing `1 - running_slot`. Upstream's `RUNNING_SLOT` is only ever `0`,
   `1`, or `0xFF`, so this is unreachable in practice; the guard makes the
   subtraction total.
8. **Failed `end`/`abort` side effects are not modelled.** Upstream sets
   `OTA_ERROR`/`OTA_ACTIVE` atomics on a failed `end`; the kernel's `Err`
   result carries no write set (kernel refusals never mutate). This does not
   affect the integrity property proved (`end` *activates* only a complete,
   magic‑valid, CRC‑matching image).
9. **`app/` references the h5i crates by absolute path** (`/root/h5i/crates/…`)
   because this port lives in the `h5i-app-bench` repo, not inside `h5i`. The
   crate builds (`cargo build`, host) and the kernel builds for
   `thumbv7em-none-eabihf` (`no_std`, no alloc). The actual firmware target is
   ESP32‑S3 (Xtensa `xtensa-esp32s3-none-elf`); that toolchain is not installed
   here, so a real flash/RAM size and HTTP latency were not measured — see
   STATUS.md.

## Trust summary

| Item | Status |
|---|---|
| OTA `transition`/`apply` (bounds, sequential, integrity gate, slot safety, totality) | **proven** |
| `check_auth`/`validate_session` (no‑cred‑no‑grant, token‑over‑HTTP, expiry, empty‑secret, totality) | **proven** |
| kernel == upstream decision logic | **tested** (400 000 differential cases) |
| flash read‑back (`magic_ok`, `actual_crc`), MD5 Digest, XOR cookie, `constant_time_eq` | trusted |
| `h5i-app-embedded` shell, `h5i-app-h1` core | trusted (the latter proven in its own crate) |
| esp‑hal / Embassy / mbedTLS / bootloader | assumed |
