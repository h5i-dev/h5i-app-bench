# synctv findings (pinned 38970e0215753a034de6b6659be577fd7e0479c2)

No exploitable vulnerability in the current code was established. No upstream
issues were filed.

## F1. `extract_bearer_token` can panic on non-ASCII input (latent)

- **Where:** `synctv-core/src/service/auth/validator.rs:30`:
  `if auth_value.len() <= 7 || !auth_value[..7].eq_ignore_ascii_case("Bearer ")`.
- **What:** `auth_value[..7]` slices a `&str` at byte 7. If byte 7 falls inside a
  multi-byte UTF-8 character, the slice panics instead of returning an error. Example:
  `"Bearer\u{e9}x"` ("Bearer" plus the two-byte "é").
- **Evidence:** `difftest/src/auth_tests.rs::bearer_extraction_panics_on_non_ascii` calls
  upstream inside `catch_unwind` and observes the panic. There is no Lean theorem for
  this, because the kernel's domain is ASCII header values.
- **Reachability:** Not reachable through the current callers.
  `synctv-api-common/src/metrics_auth.rs:203-208` and the gRPC/HTTP request context both
  get the header through `HeaderValue::to_str()` / tonic ASCII metadata, which reject
  non-visible-ASCII bytes before this function runs. A future caller that passes a
  decoded `String` (for example from a WebSocket query parameter or a JSON body) would
  turn this into a per-request panic. The release profile uses `panic = "unwind"`, so
  that would be a per-request crash, not a process abort.
- **Severity:** info (latent robustness issue). The fix is to compare bytes
  (`auth_value.as_bytes()[..7]`) or to use `get(..7)`.

## F2. The own-override pre-check in `EffectivePermissionCalculator::has_permission` is redundant

- **Where:** `synctv-core/src/service/permission/calculator.rs:73-75`:
  `if !member.has_permission(permission, RoomPermissionSet::all()) { return false; }`.
- **What:** The pre-check evaluates the member's own allow/deny overrides over a full
  default. The second test, the effective permissions over the real role default, already
  implies the pre-check for every role. Lean theorem
  `Properties.calculator_precheck_redundant` (class F) proves that `calcHas` is
  equivalent to its second conjunct alone. Mutant `calculator_skips_own_override_check`,
  which removes the pre-check, survives every proof for that reason: it is an equivalent
  mutant.
- **Impact:** None on security. The check costs one extra effective-permission
  computation per call, and it suggests the authors expected a different semantics
  (for example, overrides that could grant beyond the role default).
- **Severity:** info.

## F3. The "double-encoded dot" check of `validate_path_for_traversal` is bypassable (low)

- **Where:** `synctv-common/src/validation.rs:45-125`, Check 4 (lines 71-122).
- **What:** The validator rejects `%2e`, `%252e` and `%25252e` (any hex case). It does
  not reject encodings of the hex digits themselves. In `%2%65` the `%2` is not a
  valid escape and `%65` is `e`, so one round of percent-decoding gives `%2e` and a
  second round gives `.`. Two such sequences give `..`. The same holds for
  `%25%32%65` (decodes to `%2e`). The validator's own doc comment says it covers
  double-encoded variants.
- **Evidence:**
  - Lean theorem `Properties.double_decoding_reaches_dotdot` (class F) proves that the
    port accepts `%2%65%2%65` and that `decodeOnce (decodeOnce _)` contains `..`.
  - Difftest `pathcheck_tests::double_decoding_bypass` shows that upstream accepts
    `%2%65%2%65/etc` and `%25%32%65%25%32%65`.
  - What does hold: one round of decoding never yields `..`
    (`decoded_path_has_no_dotdot`, class S). No literal `..`, NUL, `%00`, `./.` or
    recognised encoded dot is accepted (`traversal_check_rejects_literal`,
    `traversal_check_rejects_encoded_dot`, class S). So the bypass needs a consumer
    that percent-decodes the path twice.
- **Reachability:** The validator gates provider paths in `provider/alist.rs`, for
  example lines 710, 2444, 2551, 2865, 3012 and 3086. Whether the path is decoded twice
  depends on the remote Alist server and on how the URL is built. This was not
  established. Also not rejected (not proved, by inspection): 4-layer encodings
  (`%2525252e`) and Unicode look-alikes (`．．`, U+FF0E) for consumers that normalise.
- **Severity:** low (defence-in-depth gap in a validator meant for exactly this; impact
  depends on a double-decoding consumer). A fix is to percent-decode repeatedly until
  the string stops changing, then check for `..`.

## Design observations (no finding class)

- Server-wide **member** and **admin** default permission sets
  (`service/global_settings.rs:120-131`, `MemberDefaultPermissionsSetting`,
  `AdminDefaultPermissionsSetting`) have no validator. Only the guest default is checked
  against the guest-assignable set (`service/global_settings/types.rs:80`). A root or
  admin operator can therefore give every plain member admin-only permissions such as
  `DeleteRoom` or `RemoveMembers`. Room settings and per-member rows cannot do this.
  Theorem `member_delete_room_only_from_server_default` (class S) states exactly that
  the server default is the only source. This is a privileged configuration choice, not
  a vulnerability.
- `validate_override_bits_for_role(Creator, ..)` accepts admin-space bits for the
  creator row, but `effective_permissions` ignores every override for the creator, so
  those bits are dead data.
