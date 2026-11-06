# pico-bit — STATUS

**Upstream:** `anapeksha/pico-bit` @ `b6349e2`. **Branch:** `embed-l`.
**Gate:** `h5i app check` ✅ (26 theorems, axioms = `propext, Classical.choice,
Quot.sound`; no `sorry`/`native_decide`). `h5i app mutate` ✅ 3/3 caught.
`h5i app lint` ✅. `h5i app doctor` ✅. Difftest ✅ (4 tests, 20k inputs).

## Theorems (S / C / F)

Counts: **S = 2, C = 4** in the `[check]` gate (plus the C foundation lemmas
below, all gated by the "every hand-written theorem" rule). S ≥ C/3. ✅

| Theorem | Class | Statement / what it rules out |
|---|---|---|
| `valid_name_no_traversal` | **S** | An accepted filename is non-empty, ≤64 bytes, not `.`/`..`, and contains no `/`, `\` or NUL. So `/armory/<name>` is always a direct child of `/armory` — the device can't be steered outside the armory dir. Kills `drop_slash_check`, `drop_dotdot_check`. |
| `decode_filename_confined` | **S** | Even after percent-decoding, any accepted name satisfies the same confinement policy — `%2e%2e` (`..`) and `%2f` (`/`) are decoded first, then rejected. Kills `validate_before_decode`. |
| `valid_name_total` | C | `valid_name` never panics (totality). |
| `percent_decode_total` | C | `percent_decode` never panics, any input/buffer. |
| `decode_filename_total` | C | `decode_filename` never panics. |
| `classify_total` | C | `classify` never panics, any input. |

Foundation lemmas (hand-written, also gated): `is_separator_eq/_spec`,
`is_dot_name_spec`, `valid_name_prefix_loop_sound`, `valid_name_prefix_facts`,
`percent_decode_wp`, `percent_decode_loop_total`, `hex_digit_total`,
`decode_filename_wp`, `starts_with_spec`, `starts_with_loop_sound` — all C
(totality / correspondence to the `Spec.SafeNameAt` policy).

### Mutants (S backing)

| Mutant | Breaks | Caught by |
|---|---|---|
| `drop_slash_check` (remove `SLASH` from `is_separator`) | a name with `/` passes | `valid_name_no_traversal` |
| `drop_dotdot_check` (`is_dot_name` returns false for `..`) | `..` passes | `valid_name_no_traversal` |
| `validate_before_decode` (validate raw, not decoded) | decoded `..` passes | `decode_filename_confined` |

3/3 caught, 0 survived.

## Findings (F)

- **F1 — bidirectional `request_starts_with` (not exploitable).**
  Upstream `request_starts_with(bytes, pat) = pat.starts_with(bytes) ||
  bytes.starts_with(pat)`. The first disjunct matches when fewer bytes than the
  pattern were read. Investigated against the real classifier: the preflight
  peeks up to 64 bytes, and for any **complete** request line (length ≥ the
  pattern, always true once a full line arrives) only the normal
  `bytes.starts_with(pat)` disjunct can fire. The truncated case only lets a
  client's *own* short request be classified as a prefix of a route it is
  already sending; it grants no cross-request or privilege confusion (no
  shared buffer between connections; each socket is fresh). **Not a
  vulnerability.** The kernel models the complete-line classifier and proves it
  total; the bidirectional quirk is documented, not filed.

- **F2 — unauthenticated mutating API (by design, informational).** Every
  mutating route (`POST /api/armory/upload`, `DELETE /api/armory/<name>`,
  `POST /api/payload`, `POST /api/payload/run`, `POST /api/keyboard/layout`) is
  reachable with no credential. This is intentional for an AP-mode pentest
  tool whose threat model assumes physical control of the device/AP. Recorded
  for completeness; **no advisory filed.** A related S theorem
  (`mutating_needs_unsafe_method`: a mutating class requires a `POST`/`DELETE`
  method, i.e. no GET/HEAD drive-by mutation) was modelled (`classify`,
  `is_mutating`, `starts_with_spec` give the ingredients) but the Lean proof
  was **deferred**: it needs a 14-way case analysis over the classifier
  cascade. The kernel and difftest cover the behaviour; see "Next".

**No bug was confirmed exploitable against the unmodified upstream, so nothing
was filed to `h5i-app-audit`.** The armory path logic is correct:
percent-decode-then-validate closes the classic `%2e%2e%2f` traversal, proven
by `decode_filename_confined` and witnessed over 20k inputs by the difftest.

## Benchmark measurements

1. **Rust decision logic ported:** ~120 lines of security-relevant hand-written
   logic identified in `src/runners/http.rs`; essentially all of the armory
   filename logic (`hex_digit`, decode loop, `valid_armory_asset_filename`,
   path build) and the mutating/file subset of `classify_startup_request` are
   ported into a **184-line** `no_std`/no-alloc kernel. The remaining ~2000
   lines of `http.rs` are I/O / chunked streaming / JSON / metrics (trusted).
2. **Specs attempted / proved:** 6 named `[check]` theorems, all proved (2 S,
   4 C), plus ~10 foundation lemmas, all proved. 1 further S
   (`mutating_needs_unsafe_method`) attempted and **deferred** (not `sorry`'d —
   removed from the gate; see F2). 0 shipped with `sorry`.
3. **Bugs reproduced upstream:** none. Path handling is correct; see Findings.
4. **Footprint/latency:** not measured — no firmware built this round (the
   kernel is a pure `no_std`/no-alloc decision library; per-connection memory
   in `h5i-app-embedded` is fixed at compile time by `RX+TX`). Skipped; would
   need a `thumbv*`/`riscv32`-none image. Noted, not blocking.
5. **Target/HAL compatibility:** RP235x (`rp235xa`; both Cortex-M33 and the
   RISC-V hazard3 core), `embassy-rp` 0.10, `embassy-executor` 0.9,
   `embassy-net` 0.9, `picoserve` 0.18, `littlefs2` 0.7. picoserve 0.18 already
   speaks `embedded-io-async::{Read, Write}`, the exact shape `h5i-app-embedded`
   expects, so the verified HTTP core would drop in. Notably pico-bit *bypasses*
   picoserve for its hot paths with a hand-rolled 64-byte classifier;
   `h5i-app-embedded` would replace both that classifier and picoserve with the
   verified `parse_head`, a net reduction in trusted surface.

## Layout

```
kernel/        pico_bit_kernel: decode/validate/classify (Aeneas subset)
proofs/        Spec.lean (SafeNameAt policy), Properties.lean, generated/
difftest/      kernel vs verbatim upstream functions (reference.rs), 20k inputs
h5i-app.toml   extract targets, [check] theorems, 3 mutants
DEVIATIONS.md  scope, deviations, trust boundary
```

## Next / how to resume

- Finish `mutating_needs_unsafe_method` (S): prove via a WP over `classify`
  with `starts_with_spec` threaded; needs per-class head-byte extraction (the
  5 mutating prefixes all start with `P`/`D`). Ingredients are in
  `Properties.lean` (`starts_with_spec` gives `bytes[k]! = prefix[k]!`).
- Then move to the second assigned project, **td-free**.
