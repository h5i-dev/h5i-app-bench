# defguard: findings

Upstream DefGuard/defguard @ `12508b40a49121f5439cdb2701b751df1b72826c`. Each finding has a
theorem (class F) that states the upstream behaviour and a `fix_*` mutant in `h5i-app.toml` that
fixes it and must break that theorem. No upstream issues were filed.

## F1. Login brute-force protection is bypassed by logging in with the email address (medium)

- Theorem: `Properties.email_login_never_locked`. If the typed name is not any account's username
  but matches an account's email (case-insensitively), and the tracker has no entry under the typed
  name, then the attempt is never refused (`out ≠ Blocked`) and the tracker still has no entry under
  the typed name afterwards. By induction, an unbounded number of password guesses against that
  account all reach the password check.
- Upstream: `crates/defguard_core/src/handlers/auth.rs`
  - line 162: `check_failed_logins(&appstate.failed_logins, &username_or_email)?` checks the tracker
    under the string the client typed;
  - lines 189 and 208: `log_failed_login_attempt(&appstate.failed_logins, &user.username)` records
    a failure of a found account under its *username*;
  - `crates/defguard_common/src/db/models/user.rs:900-913` `find_by_username_or_email` falls back to
    `LOWER(email) = LOWER($1)` (`:892`).
  The tracker (`crates/defguard_core/src/auth/failed_login.rs`) is keyed by the raw string.
- Effect: the 5-failures/60 s lockout (`fifth_failure_locks`) protects only logins typed with the
  exact username. Typing `alice@example.com` (or `ALICE@example.com`, ...) is never locked out, and
  failures typed that way do lock out `alice` (the username) instead, so an attacker can also lock the
  victim out of username logins while guessing freely via the email.
- Exploitability: needs the victim's email address; each guess still costs a server-side password
  hash verification. MFA, where enabled, still protects the account after a correct password.
- Reachable: yes, `POST /api/v1/auth` (unauthenticated).
- Fix mutant: `fix_log_failure_under_typed_name` (record the failure under the typed name). The
  right fix is to check and record under the same key, e.g. the resolved username.
- Evidence: the tracker itself (`failed_login.rs`) is difftested against the pinned file (400,000
  operations, all agree); the key mismatch is in the handler, which the kernel ports by reading
  (lines cited above); it is not difftested.

## F2. An enrollment session outlives its token (info)

- Theorem: `Properties.session_outlives_token`. `validate_session` accepts an enrollment token whose
  session is open (`now < used_at + timeout`) even when `expires_at < now`.
- Upstream: `crates/defguard_proxy_manager/src/servers/enrollment.rs:79-106` `validate_session`
  checks only `is_session_valid` (`crates/defguard_core/src/db/models/enrollment.rs:176-183`), never
  `is_expired`. `start_session` (`:188-222`) refuses expired tokens, so a session can only be opened
  before expiry; it then runs for the full session timeout.
- Severity: info (probably intended: the session window, 10 minutes by default, is short).
  Reachable: yes, the enrollment gRPC calls through the proxy.
- Fix mutant: `fix_validate_checks_expiry`.

## F3. `merge_ranges` returns overlapping ranges after a range that ends at the maximum (low)

- No theorem yet (the range-merging proofs are pending); evidence is the difftest.
- Upstream: `crates/defguard_core/src/enterprise/utils.rs:193-239`. `next_up = current_range_end.next()`
  wraps to 0 when the end is the type's maximum (port 65535, 255.255.255.255, the last IPv6 address;
  `Next` at `:15-29` uses `wrapping_add`), so every later range is pushed separately even when it lies
  inside the current one. Example: ports `[1..=65535, 80..=80]` merge to `[1..=65535, 80..=80]`.
- The covered set is unchanged (the difftest checks this point by point when outputs differ), so no
  traffic is allowed or denied that was not configured. The firewall rules sent to the gateway are,
  however, not the minimal non-overlapping set the function documents; in the difftest's generator
  about a quarter of the port sets (2,527 of 10,000 for seed 1) came out overlapping. Whether the
  gateway (a separate repository, not checked) accepts overlapping intervals was not checked.
- Severity: low. Reachable: yes, by an admin configuring an ACL with a port or address range that
  ends at the maximum.

## Observations without a theorem

- `SessionInfo` (`crates/defguard_core/src/auth/mod.rs:127-167`) does not check `user.is_active`;
  only `AdminRole` does (`:186-188`). Not exploitable as far as checked: `disable_user`
  (`crates/defguard_core/src/user_management.rs:89-100`) deletes the user's sessions, and API tokens
  require an active user (`enterprise/db/models/api_tokens.rs:51-69`).
- The failed-login counter is a `u32` incremented with `+= 1` (`failed_login.rs:47`); a release
  build wraps after 2^32 refused attempts, lifting the lock. Not practical. The kernel models the
  wrap (`wrapping_add`).
- The tracker is in memory and per process (lost on restart), keyed by the raw typed string (case
  sensitive), not per client address.
