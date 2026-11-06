# pico-bit port — deviations, scope, trust boundary

**Upstream:** `anapeksha/pico-bit` @ `b6349e2` (pinned, read-only at
`/mnt/scratch/oss-sec/upstream-embed/pico-bit`).
**Framework:** `picoserve` 0.18, `embassy-rp` 0.10 (RP235x / `rp235xa`, Cortex-M
*and* a RISC-V hazard3 variant), `embassy-executor` 0.9, `embassy-net` 0.9,
`littlefs2` 0.7. pico-bit is a USB-HID / Wi-Fi "bad-USB" research tool; its
Wi-Fi portal serves an **unauthenticated** HTTP API.

## What this port covers

pico-bit does *not* route its hot paths through picoserve. `portal_http_task`
in `src/runners/http.rs` peeks the first 64 bytes of every connection,
classifies the request itself (`classify_startup_request`), and dispatches to
**hand-written** byte-level handlers; picoserve's `Server::serve` only runs for
the `StartupRequest::Other` fallback. The security-relevant decision logic is
therefore the hand-written code, which is what this kernel models:

1. **Armory filename handling** (`src/runners/http.rs`):
   `hex_digit`, `decode_armory_asset_filename`, `valid_armory_asset_filename`,
   `armory_storage_path_unrestricted`. These decide which LittleFS path a
   `GET/HEAD /api/armory/<name>` download and a `DELETE /api/armory/<name>`
   touch. Ported as `hex_digit`, `percent_decode`, `is_separator`,
   `is_dot_name`, `valid_name`/`valid_name_prefix`, `decode_filename`.

2. **Request classification** (`classify_startup_request`, `request_starts_with`):
   ported as `classify`, `starts_with`, `is_mutating` (restricted to the
   routes that mutate state or serve files).

## Coverage (benchmark measurement #1)

| Upstream (http.rs @ b6349e2) | lines | kernel | status |
|---|---|---|---|
| `hex_digit` | 8 | `hex_digit` | ported verbatim |
| `decode_armory_asset_filename` (decode loop) | ~35 | `percent_decode` | ported (see RAW_MAX, UTF-8 deviations) |
| `valid_armory_asset_filename` | 14 | `valid_name` / `valid_name_prefix` + `is_separator` + `is_dot_name` | ported verbatim (decisions identical, see difftest) |
| `armory_storage_path_unrestricted` (path build) | ~18 | modelled in Spec (`SafeNameAt`) + difftest | path-build is trusted glue; its *confinement precondition* is proven |
| `classify_startup_request` (mutating + file routes) | ~45 of ~70 | `classify` + `starts_with` + `is_mutating` | ported (prefix-match variant, see below) |

Kernel: **184 code lines** (282 with docs). The relevant upstream decision
logic in scope is ~120 lines; essentially all of the filename logic and the
mutating/file subset of the classifier are ported. The other ~2000 lines of
`http.rs` are I/O, chunked streaming, JSON writing and metrics — trusted glue,
out of scope.

## Deviations from upstream (and why they are sound)

1. **`RAW_MAX = 192` scan cap in `percent_decode`.** Upstream has no explicit
   cap but rejects any input whose *decoded* length exceeds
   `LISTED_FILE_NAME_MAX = 64`. A raw segment longer than `64 * 3 = 192` bytes
   must decode to more than 64 bytes (each decoded byte costs ≥1 raw byte, a
   `%XX` escape costs 3), so upstream already rejects it. The cap is therefore
   accept/reject-equivalent and only exists to make the loop's index
   arithmetic provably non-overflowing. The difftest exercises inputs on both
   sides of the boundary.

2. **No UTF-8 check in `decode_filename`.** Upstream's
   `decode_armory_asset_filename` additionally requires the decoded bytes to be
   valid UTF-8. The kernel omits this (it is a validity refinement, irrelevant
   to path traversal: UTF-8-ness does not introduce `/`, `\`, NUL or `..`). The
   difftest `decode_agrees_modulo_utf8` pins the difference exactly: the two
   agree on every input except that the kernel also accepts the (rare)
   non-UTF-8 decoded names upstream rejects. The confinement theorem holds for
   all accepted names regardless.

3. **`is_dot_name` is a kernel-introduced helper** (upstream inlines the `.` /
   `..` test inside `valid_armory_asset_filename`). Behaviour is identical; it
   is factored out so the separator loop extracts as a single Aeneas loop.

4. **`classify` uses ordinary prefix matching, not upstream's bidirectional
   `request_starts_with`.** Upstream's `request_starts_with(bytes, pat)` returns
   true if `bytes` is a prefix of `pat` *or* `pat` is a prefix of `bytes`; the
   first disjunct only fires on a truncated read (fewer bytes than the pattern)
   and classifies a client's own partial request line. For any *complete*
   request line (≥ the pattern length), the two agree. The kernel models the
   complete-line case. See STATUS.md (F1) for why the bidirectional match is
   not exploitable.

5. **No authentication is modelled because pico-bit has none.** The Wi-Fi
   portal API is entirely unauthenticated by design (it is an AP-mode
   pentest tool). This is recorded as finding **F2** (informational), not a
   vulnerability: the device's threat model assumes physical control of the AP.

## Trust boundary (out of scope / assumed)

- picoserve itself, `embassy-*`, `littlefs2`, `cyw43` Wi-Fi, the TCP stack,
  chunked transfer encoding, JSON writing, upload streaming to flash, the
  LED/status state machine, USB-HID and DuckyScript execution.
- The glue that *calls* the modelled decisions (reads the socket, builds the
  path string, opens the file) is trusted. The theorems constrain what that
  glue is *permitted* to open: only a confined `/armory/<child>`.
- Charon/Aeneas/Lean and the shared Lean cache, as for every h5i-app port.
