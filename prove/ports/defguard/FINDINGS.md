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

- Theorem: `Properties.merge_ranges_overlap`. For the ports `1024-65535` and `2000`,
  `merge_ranges` returns both ranges unchanged, and they overlap (`¬ PairwiseDisjoint`). The
  security property next to it, `merge_ranges_exact`, proves that the merged ranges cover exactly
  the values the input covers, for any input of well-formed ranges (`start ≤ end ≤ max`).
- Upstream: `crates/defguard_core/src/enterprise/utils.rs:193-239`. `next_up = current_range_end.next()`
  wraps to 0 when the end is the type's maximum (port 65535, 255.255.255.255, the last IPv6 address;
  `Next` at `:15-29` uses `wrapping_add`), so every later range is pushed separately even when it lies
  inside the current one.
- Effect: none on what the rule allows or denies (`merge_ranges_exact`). The firewall rules sent to
  the gateway are not the minimal non-overlapping set the function documents. In the difftest's
  generator about a quarter of the port sets came out overlapping (2,527 / 2,571 / 2,579 / 2,599 of
  10,000 for seeds 1-4). Whether the gateway (a separate repository) accepts overlapping intervals
  was not checked.
- Severity: low. Reachable: yes, by an admin configuring an ACL with a port or address range that
  ends at the maximum.
- Fix mutant: `fix_next_saturates` (`next(max) = max`, so a range ending at the maximum absorbs every
  later one).

## F4. Readdressing keeps a device's old address without checking it (low)

- Theorems: `Properties.kept_address_unchecked` (a current address inside a subnet is returned as
  it is) and `Properties.keeps_gateway_address` (a device whose current address is the subnet's
  gateway address keeps it, and that address is not `Assignable`). For comparison,
  `fresh_addresses_valid` proves that a fresh assignment never returns a network, broadcast,
  gateway, used or reserved address.
- Upstream: `crates/defguard_common/src/db/models/device.rs:741-818` `assign_next_network_ip`;
  lines 762-774 reuse `current_ips.find(|ip| address.contains(ip))` and skip the checks at
  :776-783 (network, broadcast and gateway address, `used_ips`, `reserved_ips`). The doc comment
  (:717-718) says this is deliberate. The caller,
  `crates/defguard_core/src/location_management/mod.rs:174-186`, readdresses a device only when the
  location no longer contains all its addresses or the number of subnets changed.
- Effect: after an admin changes a location's subnets, a device can keep an address that is now
  the gateway's address, the new subnet's network or broadcast address, or a newly reserved address.
  Example: the location goes from `10.0.0.1/24` to `10.0.0.1/25, fd00::1/64`; the subnet count
  changes, so every device is readdressed, and a device at `10.0.0.127` (now the IPv4 broadcast
  address) keeps it. When the subnet count does not change and every address still fits, the
  caller does not call `assign_next_network_ip` at all (outside the kernel). The difftest
  reproduces it: of the 26,898 assignments that agree with upstream (seeds 1-4), 9,127 hold a
  network, broadcast or gateway address kept from the device's current ones (the generator picks
  current addresses at those positions on purpose, so the rate means nothing).
- Severity: low. It needs an admin to change a location's addresses, and the likely result is a
  device that cannot route traffic or an address that clashes with the gateway's own. No way to
  reach another user's traffic was found.
- Fix mutant: `fix_recheck_kept_address` (keep the current address only if it is assignable,
  otherwise take the first free one).

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
