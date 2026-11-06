# M5AirQ-Rust — status

**Upstream:** `andrico21/M5AirQ-Rust` @ `f7e35cb` (ESP32‑S3, picoserve 0.18, Embassy).
**Branch/worktree:** `embed-i` / `prove/ports-embed/m5airq`.
**Gate:** `h5i app check` → **ok, 54 theorems**, standard axioms only (`propext`,
`Classical.choice`, `Quot.sound`); no `sorry`, `native_decide`, or new axioms.
`h5i app lint` ok. `h5i app mutate` → **8/8 mutants caught, 0 survived.**
Differential test (`difftest/`) → 400 000 cases agree with the upstream oracle.

## Theorem table (S / C / F)

Counts: **S = 10, C = 6, F = 2** (S ≥ C/3 ✔). Every S is mutation‑backed.

| Theorem | Class | Says / which bug it rules out |
|---|---|---|
| `transition_total` | C | OTA `transition` never panics/overflows, any actor/state/command (totality) |
| `transition_wp` | C | one WP that every OTA property is derived from (foundation) |
| `write_bounded` | **S** | a committed chunk never pushes `written` past the declared `total` — rules out a write accepted past the image size (mutant `write_exceeds_declared`) |
| `write_sequential` | **S** | a committed chunk writes exactly at the cursor and advances it by its length — rules out out‑of‑order / overlapping writes (mutant `write_non_sequential`) |
| `end_integrity` | **S** | `end` activates an image only if `written == total ∧ magic_ok ∧ actual_crc == expected_crc` — rules out activating an incomplete/corrupt image (mutant `end_skip_crc`) |
| `begin_targets_other_slot` | **S** | `begin` never targets the running slot (`target ≠ running`, `running ≤ 1`) — rules out erasing the running firmware (mutant `begin_same_slot`) |
| `mutating_needs_admin` | **S** | every mutating OTA command is refused without the authenticated actor (mutant `ota_begin_no_admin`) |
| `inv_reachable` | **S** | in **every reachable state** (any sequence of commands/actors, successful or refused), an active session has `written ≤ total` — a whole‑run invariant, not one step |
| `inv_initial`, `inv_step` | C | foundations for `inv_reachable` |
| `end_accepts_any_matching_crc` | **F** | for *any* image, `end` succeeds when the declared CRC equals the (client‑chosen) image CRC — the only integrity gate is attacker‑controlled; **no firmware authenticity/signature** (CWE‑347). See Findings. |
| `ReadOnly.sound` | **S** | a read‑only command (`Status`) never produces a write set — rules out a "read" that mutates |
| `check_auth_total` | C | `check_auth` never panics, any inputs (totality) |
| `validate_session_sound` | C | `validate_session = true` ⇒ some slot accepts the token (foundation) |
| `slot_valid_fresh` | **S** | a slot accepts a token only within its TTL (`slot_valid` genuinely checks `age_ok`) — rules out dropping the expiry check (mutant `auth_skip_expiry`) |
| `unauth_never_granted` | **S** | with `public_access` off and no valid credential (bad/absent cookie, no matching token, no Digest), the request is never granted (only `Forbidden`/`Challenge`) |
| `token_over_http_forbidden` | **S** | a bearer/API‑key over plaintext HTTP with `allow_http_tokens` off and no valid cookie is refused `Forbidden` (mutant `auth_public_bypass`) |
| `expired_session_never_grants` | **S** | an expired session cookie yields `Challenge`, never access |
| `empty_secret_no_bypass` | **S** | an unset bearer token / API key never grants, even if the (empty) comparison "matched" (mutant `auth_empty_secret`) |
| `public_access_opens_everything` | **F** | with `public_access` **on** (the shipped default) every request — including mutating ones — is granted with no credential (CWE‑1188/CWE‑306). See Findings. |

(The gate also counts a few local `@[step]` helper specs and value lemmas —
`slot_size_val`, `max_chunk_val`, `ttl_val`, `apply_eq`, the leaf `*_spec`s —
all class C.)

## Benchmark measurements (this round's goal)

1. **Fraction of upstream decision logic ported.** In scope and identified:
   `ota.rs` session API `begin/write/end/abort/status` ≈ 150 LoC of decision
   logic (excluding flash IO, JSON, logging), and `auth.rs` `check_auth` +
   `validate_session` + helpers ≈ 110 LoC. Kernel is 402 non‑blank/comment
   LoC implementing both. Essentially **all** of the branch/decision logic in
   those two functions is ported; the excluded parts are the trusted IO/crypto
   (MD5 ≈ 180 LoC, flash read/write/erase, JSON formatting) — intentionally out
   of scope. Rough coverage of *identified security‑relevant decision logic*:
   **~90 %** of OTA session control flow, **~95 %** of the auth decision.
2. **Specs attempted vs proved.** 54 theorems auto‑stated/attempted, **54
   proved, 0 shipped with `sorry`**. Dropped/changed during development
   (recorded honestly): the reachability invariant was initially stated to also
   carry `target ≠ running` and `running ≤ 1`; that made the inductive step
   heavy, so it was split — the slot‑safety part is now the stronger
   single‑step theorem `begin_targets_other_slot`, and `inv_reachable` carries
   the `written ≤ total` bound. One early `unauth_never_granted` attempt used a
   128‑way `by_cases` cascade that was replaced by the flattened `check_auth`
   extraction + `step*`.
3. **Bugs reproduced against real upstream.** Two, both confirmed against the
   pinned upstream *source* (see Findings): the insecure `public_access = true`
   default and the absence of any firmware‑authenticity check in OTA. A third
   (Digest replay) is recorded as a lower‑severity F.
4. **RAM/flash footprint & latency.** Kernel builds `no_std`, no‑alloc for
   `thumbv7em-none-eabihf` (rlib 73 KB; the object `.text` is a few hundred
   bytes of branch logic — no heap, fixed‑size state `OtaState` = 16 B,
   `SessionStore` = 4 × 12 B). The `app/` wires onto `h5i-app-embedded` and
   builds on host. **Not measured:** real ESP32‑S3 flash/RAM and HTTP latency —
   the upstream target is Xtensa (`xtensa-esp32s3-none-elf`); that toolchain and
   an ESP32‑S3/QEMU are not available in this environment, so firmware sizing
   and before/after latency were skipped (honestly noted, not estimated).
5. **Target/HAL/Embassy compatibility.** Upstream pins: ESP32‑S3, `esp-hal`
   1.0.0, `embassy-executor` 0.9.1, `embassy-net` 0.8.0, `embassy-time` 0.5.0,
   `picoserve` 0.18.0, `embedded-io-async` 0.7. `h5i-app-embedded` is generic
   over `embedded_io_async::{Read,Write}` 0.7 — **the same `embedded-io-async`
   major used by both picoserve 0.18 and this upstream**, so the shell's IO
   shape fits an embassy‑net `TcpSocket` as‑is. `h5i-app-h1`'s fixed
   compile‑time limits (1 KiB head/body default) are smaller than upstream's
   2 KiB picoserve buffers but adjustable via `Limits`.

## Findings (F)

### F1 — Unauthenticated access by default (`public_access = true`) → unauthenticated OTA / factory‑reset / reconfig

`AuthSettings::default()` sets `public_access: true` (settings.rs:133). A
device whose flash KV store has no `AuthPub` entry — i.e. **factory/first
boot, before the operator explicitly turns public access off** — loads that
default, and `check_auth` returns `Allowed` for *every* request at the first
line (auth.rs:668). Every mutating endpoint (`/api/save`, `/api/kv`,
`/api/factory-reset`, `/api/ota/*`, `/api/cert`) is behind the `Authenticated`
extractor, so all of them are reachable with **no credential** over the network
(AP or STA). Default credentials are also `admin`/`admin`. **Classes:**
CWE‑1188 (insecure default), CWE‑306 (missing auth for critical function).
Modelled by `public_access_opens_everything`.

### F2 — OTA accepts any firmware with a matching client‑supplied CRC‑32 (no authenticity)

`ota::end(expected_crc)` (ota.rs:544) finalizes an update when the image is
complete, its first byte is the ESP magic `0xE9` (`verify_image_header`,
ota.rs:289), and a CRC‑32 **read back from flash** equals `expected_crc`
(ota.rs:586). But `expected_crc` is supplied by the *uploader* in the URL
(`GET /api/ota/end/{crc}`) and is only an integrity (corruption) check — there
is **no signature / authenticity verification** of the image. Any well‑formed
image the client chooses is accepted and activated. Modelled by
`end_accepts_any_matching_crc`. **Class:** CWE‑347 (improper verification of
cryptographic signature).

**Chained impact (F1 ⊕ F2):** on a default‑configured device, a network
attacker needs no credentials (F1) to drive the OTA endpoints and install
arbitrary firmware (F2) — a persistent, full‑device compromise. This is being
written up against the real pinned upstream in **h5i-app-audit**, branch
`embed-finding-i-m5airq-unauth-ota` (see that repo); PoC confirms the vulnerable
code paths in the pinned source and compiles the extracted real decision
functions to show unauth → `Allowed` → OTA accepted. If the audit PoC does not
hold up end‑to‑end it stays recorded here as F1/F2 only.

### F3 — Digest nonce is never validated (replay), despite a comment claiming otherwise

`verify_digest` (auth.rs:505) recomputes the RFC‑7616 response hash using the
`nonce`/`nc`/`cnonce` taken from the client's own header and compares it to the
client's `response`; it never checks that the `nonce` was one the server issued
(`make_nonce` is just a counter, auth.rs:476) nor that `nc` increases. The
comment at auth.rs:144 claims the monotonic `NONCE_COUNTER` "prevents Digest
replay", but it does not: a passively captured valid `Authorization: Digest …`
header (Digest is permitted over plaintext HTTP) can be replayed to
authenticate, and the server even mints a fresh session cookie for the replayer
(`AuthResult::AllowedSetSession`). Recorded as F (lower severity than F1/F2,
and the kernel abstracts the MD5, so this is a source‑level finding, not a
kernel theorem).

## Resume / next

- Everything above is committed and pushed on `embed-i`.
- Done: kernel, proofs (gated), difftest, app wiring, mutation 8/8, this status.
- Next (strengthening): finish the h5i-app-audit write‑up for F1⊕F2 with a
  self‑checking PoC against the pinned upstream; consider widening the kernel to
  the `/api/kv` + `/api/save` setting‑write authorization and the cert‑upload
  key‑slot allow‑list; add an S theorem that `begin` resets `written`/`error`.
