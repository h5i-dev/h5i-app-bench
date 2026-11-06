# defguard: what the kernel covers and where it differs

Upstream: DefGuard/defguard @ `12508b40a49121f5439cdb2701b751df1b72826c` (2026-10-28, "Update Rust
crate pulldown-cmark to v0.13.5 [SECURITY] (#3972)"). The checkout is at
`/mnt/scratch/oss-sec/upstream/defguard`; link it as `prove/results/upstream/defguard`
(gitignored) for the difftest.

## Threat model

defguard is a WireGuard VPN and identity server. This port covers the decisions that gate access
to its management API and to enrollment:

1. Login brute-force protection: the failed-login tracker and how the login handler consults it.
2. API authentication: a stored, unexpired session or (business licence) an admin's API token;
   MFA required for MFA users; admin-only routes need an active admin; per-user resources (users,
   devices) only for their owner or an admin.
3. Enrollment / desktop-activation tokens: an expired token never opens a session; a token opens
   one session; enrollment requests need an open session and act for the token's user.
4. Range merging behind firewall rules: the merged ranges cover exactly the configured values.
5. Device addresses: a device gets an address inside each subnet that is not the network,
   broadcast or gateway address and not used or reserved.

Trusted / out of scope: password hashing (`verify_password`, a table here), the database queries
(their results are inputs: the session row, the API token's user, group memberships, the token row),
axum/tonic extraction, the clock (an input), LDAP (disabled in the port), the gateway.

## Covered

| Kernel (`kernel/src/`) | Upstream |
|---|---|
| `lockout::{should_prevent_login, should_reset_counter, log_failed_attempt, verify_username}` | `crates/defguard_core/src/auth/failed_login.rs` (whole file) |
| `lockout::authenticate`, `find_by_username_or_email` | `crates/defguard_core/src/handlers/auth.rs` `authenticate` lines 150-240 (the tracker check, the lookup, the password check, the failure logging; LDAP off); `defguard_common/src/db/models/user.rs` `find_by_username_or_email` |
| `auth::{extract_session, expired}` | `crates/defguard_core/src/auth/mod.rs` `SessionExtractor::from_request_parts` (31-96); `defguard_common/src/db/models/session.rs` `Session::expired` |
| `auth::{session_info, contains_any_group, find_user}` | `auth/mod.rs` `SessionInfo::from_request_parts` (127-167), `contains_any_group`; `User::is_admin` |
| `auth::admin_role` | `auth/mod.rs` `role!(AdminRole, Permission::IsAdmin)` (169-204) |
| `auth::user_for_admin_or_self`, `device_for_admin_or_self` | `crates/defguard_core/src/handlers/mod.rs` (645-692); `Device::find_by_id_and_username` |
| `token::{is_expired, is_session_valid, start_session}` | `crates/defguard_core/src/db/models/enrollment.rs` `Token` (163-222) |
| `token::validate_session` | `crates/defguard_proxy_manager/src/servers/enrollment.rs` `validate_session` (79-106) |
| `ranges::merge_ranges` | `crates/defguard_core/src/enterprise/utils.rs` `merge_ranges` (193-239), `Next` (9-29) |
| `ipalloc::{network, broadcast, contains, assignable, first_free, find_current, pick, assign_next_network_ip}` | `crates/defguard_common/src/db/models/device.rs` `assign_next_network_ip` (741-818), the address loop up to the relation insert; `ipnetwork`'s `network`, `broadcast`, `contains` and iteration |

## How it is checked

`difftest/` compiles pinned upstream source text from the checkout (`build.rs`):

- `auth/failed_login.rs`, whole, with `Local::now()` replaced by a test clock. 100,000 random
  `log_failed_attempt` / `verify_username` calls per seed on three names (`alice`, `bob`, `Alice`),
  with time steps that hit the 60 s window and 300 s timeout exactly, one nanosecond before and
  after. After every call the full entry (count, first and last attempt, in nanoseconds) of every
  name and the refusal are compared. Seeds 1-4: 400,000 operations, all agree.
- `Token::{is_expired, is_used, is_session_valid, start_session}` from `db/models/enrollment.rs`,
  with `Utc::now()` replaced by the test clock and the one `UPDATE token SET used_at` statement
  removed (the in-memory `used_at` it also sets is compared). 100,000 random tokens per seed with
  expiry and first use around the boundaries and timeouts {0, 1, 600, 3600} s; deadlines, errors
  and `used_at` agree. Seeds 1-4: 400,000 cases.
- `enterprise/utils.rs`, whole: `merge_ranges::<u16>` on 10,000 random port sets per seed, including
  0, 1, 65534, 65535 and full-width ranges. The outputs are compared exactly (they were equal in all
  40,000 cases); a range ending at 65535 would allow a set-wise comparison, because upstream's
  `sort_unstable_by` may order equal starts differently there.
- `db/models/device.rs` `assign_next_network_ip`, its address loop (from `let mut ips` to the
  relation insert), compiled as a plain function over the real `ipnetwork` types. 10,000 random
  locations per seed with one or two subnets (IPv4 /26-/32, IPv6 /122-/128, so that subnets fill
  up), up to 40 used or reserved addresses and up to two current addresses, each one the gateway,
  network or broadcast address or a low host. The assigned addresses, or the index of the full
  subnet, agree in every case. Seeds 1-4: 26,898 assignments and 13,102 full subnets.

Not difftested (ported by reading; async axum/tonic code with database calls interleaved): the
login handler's use of the tracker, `SessionExtractor`, `SessionInfo`, `AdminRole`,
`user_for_admin_or_self`, `device_for_admin_or_self`, `validate_session`. The difftest is evidence,
not a proof of equivalence.

## Differences in form

| Where | Upstream | Kernel | Why |
|---|---|---|---|
| everywhere | `String`, `&str` | `Vec<u8>`, `&[u8]` | Aeneas has no strings; comparisons are bytewise |
| clocks | `Local::now()`, `Utc::now()` | `now: i64`, nanoseconds since the epoch | time is an input; chrono's durations are exact to the nanosecond |
| `FailedLoginMap` | `HashMap<String, FailedLogin>` | list of entries with their key | no maps |
| `FailedLogin::increment` | `attempt_count += 1` | `wrapping_add(1)` | release-build semantics |
| `Default`/`reset` | two `Local::now()` calls | one `now` | the two reads differ by nanoseconds upstream; the difftest clock returns one value |
| `authenticate` | async handler, LDAP fallback | lockout decision only, LDAP off; `password_ok[i]` is `verify_password` for account `i` | |
| `find_by_email` | `LOWER(email) = LOWER($1)` in PostgreSQL | ASCII lower-casing | PostgreSQL's `LOWER` is locale-aware; ASCII emails only |
| `SessionExtractor` | DB lookups of the cookie's session and the bearer token | `Credential` carries the lookup results | |
| `is_admin` / `AdminRole` | `User::is_admin` (SQL) and `Group::find_by_permission(IsAdmin)` names | membership of a group named in `admin_groups` | both are "member of an `is_admin` group" when group names are unique |
| `device_for_admin_or_self` | `find_by_id` / `find_by_id_and_username` (SQL) | search of the device list by id and owner id | |
| `Token` | DB row, `NaiveDateTime`, `token_type: Option<String>` | `i64` ns, `enrollment_type: bool` | |
| `start_session` | `UPDATE token SET used_at` | the returned token carries `used_at` | the shell writes it |
| `TimeDelta::seconds(timeout as i64)` | `u64` seconds | `timeout_ns: i64` | the conversion (which wraps or panics for absurd timeouts) is outside |
| `merge_ranges<T: Ord + Next>` | generic | `u128` values below `max`, `next` wraps at `max` | one function for ports, IPv4 and IPv6 |
| `sort_unstable_by` | unstable | stable insertion sort | differs only for equal starts next to the maximum |
| `Option::clone` | | `token::same` | Aeneas has no `Option::clone` |
| `IpNetwork` / `IpAddr` | enums of `Ipv4Network`/`Ipv6Network` | `Net { v4, ip: u128, prefix }`, `Ip { v4, bits: u128 }` | one function for both families; IPv4 bits are the low 32 |
| `used_ips: &HashSet<IpAddr>`, `reserved_ips: Option<&[IpAddr]>` | set, optional slice | two `Vec<Ip>` (none = empty) | no sets; membership only |
| `Err(DeviceError::NetworkFull(address.to_string()))` | the subnet as a string | the subnet's index | |
| the relation insert after the loop | `WireguardNetworkDevice::insert` | not modelled | the shell's |
