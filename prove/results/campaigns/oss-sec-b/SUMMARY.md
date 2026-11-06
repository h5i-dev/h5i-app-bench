# oss-sec session b: summary

Two projects, each ported to an h5i-app kernel, difftested against the pinned upstream code,
proved in Lean (no `sorry`, `axiom` or `native_decide`) and gated with `h5i app extract --check`,
`check`, `lint` and `mutate`. Details: `prove/ports/{atuin,defguard}/{STATUS,FINDINGS,DEVIATIONS}.md`.

| Project | Upstream commit | Gate | `[check]` theorems S / C / F | Mutants caught |
|---|---|---|---|---|
| atuin (sync server) | `df152cd4d68b4dbc2a6f13732b31b0e013470c70` | ok, 238 theorems in 13 modules | 15 / 10 / 3 | 23 / 23 |
| defguard (VPN / identity server) | `12508b40a49121f5439cdb2701b751df1b72826c` | ok, 172 theorems in 8 modules | 16 / 7 / 5 | 25 / 25 |

S = security property, independent of the implementation and falsifiable; C = correspondence or
foundation lemma; F = theorem that records a finding. Each S theorem is matched with a mutant
that makes it false (tables in each STATUS.md). Each F theorem has a `fix_*` mutant that fixes the
finding and breaks the theorem.

## atuin

What was proved, over the kernel of `crates/atuin-server` (UserAuth header parsing, the account
handlers, the record handlers, and `apply` on the SQLite tables):

- Authorization: every write of a successful request is allowed by `Spec.allowed`.
  Unauthenticated requests write nothing except registration. Account deletion and password
  change require the current password. Records go only into the requester's store and fit the
  size limit. Login returns a token only of the named user, and only after the password verifies.
- Isolation: a request's whole outcome is the same on two databases that agree on the
  requester's data. A successful request leaves every other account unchanged.
- Integrity: records are append-only. Account deletion removes all of the account's rows. In
  every reachable database there are no orphaned rows, a new account starts empty, and a token
  identifies at most one account.

Evidence: the difftest runs the real upstream server over HTTP with SQLite and compares responses
and full table dumps after every request (22,500+ requests, all agree).

Findings (no upstream issues filed):

- F1, low, by design: changing the password does not revoke sessions, and login hands back the
  existing token, so a token that leaked once stays valid (`src/handlers/user.rs:160-184`).
- F2, info: a `count` above `i64::MAX` wraps to a negative SQLite `LIMIT`, which means unlimited
  (`src/db/mod.rs:454`). The response holds only the requester's own records.
- F3, info: `idx` and `start` are compared as signed integers (`src/db/mod.rs:421,453`). This
  affects only the client's own sync state.

## defguard

What was proved:

- Login lockout (`auth/failed_login.rs`, `handlers/auth.rs`): a locked name is refused before
  the password is checked. A successful login needs a verified password. A failure typed with a
  username is recorded, and the fifth failure locks the name.
- API guards (`auth/mod.rs`, `handlers/mod.rs`): `SessionInfo` requires an unexpired stored session
  or an admin's API token, and MFA users require an MFA-verified session. `AdminRole` admits only
  active admins. Another user's account or device is returned only to an admin.
- Enrollment tokens: an expired token never starts a session. A token's first use is recorded
  once. Enrollment requests require an open session and act for the token's user.
- Device addresses (`db/models/device.rs` `assign_next_network_ip`): a fresh assignment returns the
  lowest address that is valid and free. `NetworkFull` is returned only when no such address exists.
- Firewall ranges (`enterprise/utils.rs` `merge_ranges`): the merged ranges cover exactly the
  input's values. When no range ends at the maximum, they are also sorted, disjoint and not
  adjacent, which determines the output completely.

Evidence: the difftest compiles the pinned upstream source, with time and SQL seams, against the
kernel. Seeds 1-4 cover 400,000 tracker operations, 400,000 token cases, 40,000 port sets and
40,000 address assignments, and all of them agree. The login handler's use of the tracker and the
axum/tonic guards were ported by reading the code and are not difftested.

Findings (no upstream issues filed):

- F1, medium: logging in with the account's email address bypasses the brute-force lockout. The
  tracker is checked under the string the client typed (`handlers/auth.rs:162`), but failures are
  recorded under the username (`:189`, `:208`), and the lookup falls back to a case-insensitive
  email match (`defguard_common/src/db/models/user.rs:892,900-913`). Guessing through the email
  is therefore never locked out, and those failures lock out the victim's username logins instead.
  It can be reached without authentication at `POST /api/v1/auth`.
- F2, info: an enrollment session outlives its token, because `validate_session` never checks
  `expires_at` (`defguard_proxy_manager/src/servers/enrollment.rs:79-106`).
- F3, low: `merge_ranges` returns overlapping ranges after a range that ends at the type's maximum,
  because `next()` wraps to 0 (`enterprise/utils.rs:193-239`, `:15-29`). The covered set is still
  exact.
- F4, low: on readdressing, an address the device already has inside the subnet is kept without
  any checks. It can therefore be the new subnet's gateway, network or broadcast address
  (`db/models/device.rs:762-774`). Only an admin who changes a location's subnets can trigger it.

## Gaps

- All S theorems are partial correctness: they constrain successful results. Totality (no panic
  or overflow) is not proved for either kernel. The difftests are the evidence that the kernels
  succeed where upstream does.
- Ported by reading and not difftested: defguard's login handler logic around the tracker, the
  axum/tonic extractors and the enrollment `validate_session`.
- Not covered: atuin's `client_ip.rs` (ported and extracted, not proved; upstream only logs it),
  the full ordering spec of atuin's `next_records`, defguard's firewall rule generation
  (`enterprise/firewall/mod.rs`), LDAP, OpenID and the gateway.
- atuin mutant `size_limit_strict` (a stricter record-size limit) is caught only by a C lemma,
  because a stricter limit is safe and only an acceptance theorem would rule it out.
