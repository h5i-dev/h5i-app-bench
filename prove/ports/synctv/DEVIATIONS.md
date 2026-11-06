# synctv port: scope, threat model and deviations

Upstream: <https://github.com/synctv-org/synctv>, pinned at
**`38970e0215753a034de6b6659be577fd7e0479c2`** (2026-11-06, "fix(xiu): rotate the GOP cache
on the frame cap for audio-only streams (#521)"). synctv is a Rust workspace; this port
covers decision logic in `synctv-core`, plus one validator in `synctv-common`. (The campaign brief first called synctv a Go
project. That was wrong, so no Go harness exists. The difftest links the upstream Rust
crates directly.)

## Threat model

synctv is a watch-together server. Rooms have a creator, admins, members and guests
(anonymous viewers who hold a room-scoped JWT). Server-wide there are root, admin and
user accounts. The security-relevant decisions isolated here are:

1. **Room permissions.** These decide who may chat, manage media, control playback,
   remove members, change settings or delete the room. Effective permissions combine a
   server-wide role default, room-settings overrides and per-member overrides, each in
   a role-specific bitspace (allow/deny). An attacker is a member or guest trying to get
   a permission their role cannot hold. A room admin trying to give someone permissions
   outside that person's role's bitspace is the same kind of attacker.
2. **Member role policy.** Only the room creator may grant the admin role or change
   roles. The creator role cannot be assigned. Permission overrides must stay in the
   target role's bitspace and use the right channel (admin or plain columns). The kick
   cooldown is bounded.
3. **Global roles.** Which server role may manage which (`UserRole::can_manage`), and
   that banned accounts cannot log in.
4. **Tokens.** JWT expiry with clock-skew leeway (including saturation), token-type
   separation (refresh tokens are not access tokens), room-wide guest-token revocation
   by guest version, guest admission (global switch, room switch, no password-protected
   rooms, fail closed without runtime settings), the `SecurityPipeline::check` decision
   (password version, ban, deletion, 2FA, JTI blacklist, fail closed on blacklist
   outage), and `Authorization: Bearer` header parsing.

**Trusted, not modelled:** HS256 signing and verification, issuer/audience checks and
serde decoding (`jsonwebtoken::decode`). This includes the serde `typ` tag that keeps
guest tokens out of `Claims`. Also trusted: the system clock, PostgreSQL, Redis and the
caches (the values they return are inputs to the kernel), the HTTP/gRPC frameworks, and
the executor `execute_member_update_with_outbox`, which checks the actor's
`MANAGE_MEMBER_PERMISSIONS`. The kernel only reports that this check is required.

## Ported code (upstream file:line at the pinned commit)

| Kernel (`kernel/src`) | Upstream |
|---|---|
| `perms::RoomPermission`, `Role` | `synctv-core/src/models/permission.rs` (enums `RoomPermission`, `Role`) |
| `perms::M_*`, `A_*`, `G_*` constants | `models/permission.rs` `RoomMemberPermissionBits` (168-), `RoomAdminPermissionBits` (265-, `DEFAULT` 310), `RoomGuestPermissionBits` (513-) |
| `member_/admin_/guest_includes_only_defined` | `models/permission.rs:198, 337, 531` |
| `member_/admin_/guest_to_permissions` | `models/permission.rs:203, 371, 536` |
| `member_/admin_/guest_from_permissions` | `models/permission.rs:230, 440, 554` |
| `bit_for` | `models/permission.rs:342` |
| `has`, `has_all`, `has_any` | `models/permission.rs:127, 133, 138` |
| `all`, `default_admin/member/guest`, `guest_assignable` | `models/permission.rs:94-125` |
| `role_permissions`, `override_bits_from_permissions` | `models/permission.rs:702, 712` |
| `effective_permissions`, `member_has_permission` | `models/room_member.rs:180, 208` |
| `settings_admin/member/guest_permissions` | `models/room_settings/mod.rs:378, 387, 396` |
| `role_default`, `effective_for_member`, `calculator_has_permission` | `service/permission/calculator.rs:35, 49, 67` |
| `policy::validate_*` (7 validators) | `service/room/member_role_policy.rs:9-129` (whole file) |
| `policy::validate_kick_cooldown_seconds`, `MAX_KICK_COOLDOWN_SECONDS` | `service/room/member_kick.rs:24, 40` |
| `policy::plan_member_update` | `service/room/member_roles.rs:35-91` (validation prefix of `update_member_with_outbox`, up to the call of `execute_member_update_with_outbox` at line 92) |
| `auth::can_manage`, `is_admin_or_above` | `models/user.rs:36, 42` |
| `auth::status_*` | `models/user.rs:122-145` |
| `auth::validate_expiration` | `service/auth/jwt.rs:59` |
| `auth::accept_user_token` | `service/auth/jwt.rs:570-614` (after `decode`) |
| `auth::accept_guest_token` | `service/auth/jwt.rs:682` + `service/auth/guest_validator.rs:113` |
| `auth::check_guest_allowed` | `service/room/guest_access.rs:11-55` |
| `auth::extract_bearer_token` | `service/auth/validator.rs:29` |
| `auth::pipeline_check` | `service/auth/security_pipeline.rs:134-228` |
| `pathcheck::validate_path_for_traversal` (+ `hex_val`, `hex_pair_is`, `contains1/2/3`, `encoded_at`, `first_encoded`) | `synctv-common/src/validation.rs:45-125` |

## Differences from upstream

- **Representation.** Permission sets are the upstream `u64`. The bit constants are
  literals; `difftest::constants_match` compares every one with upstream. Rust structs
  carry only the fields the decisions read (`MemberPerms`, `SettingsPerms`, `Defaults`).
  User and room ids are `i64` (upstream `UserId(i64)`, `RoomId(i64)`).
- **Bit tables.** Upstream's `to_permissions`/`from_permissions` are sequences of
  `if bits & FROM != 0 { out |= TO }`. The kernel ors together `map_bit(bits, FROM, TO)`
  terms, which compute the same value. `admin_from_permissions` reuses
  `admin_to_permissions`, because upstream's two admin tables are identical (identity
  on the 21 admin bits).
- **Errors** keep only their kind (`InvalidInput`/`Authorization`/`NotFound`/
  `Authentication`/`ServiceUnavailable`), not the message.
- **I/O as inputs.** Clock reads, runtime-setting reads, repository reads, cache hits and
  blacklist reads are boolean or integer inputs (`now`, `GuestAccessFacts`,
  `PipelineFacts`, `current_exists`/`current_role`/`room_exists`/`room_created_by`).
  Errors from those reads are not modelled, except that `pipeline_check` models a
  blacklist read error (`ServiceUnavailable`).
- **`plan_member_update`.** `role.unwrap_or(current.role)` is the helper
  `effective_role_of`. The returned `MemberUpdatePlan` records what the executor is told
  (`needs_manage_member_permissions` = `actor_permission_check.is_some()`).
- **`validate_path_for_traversal`** works on bytes. `path.get(i+1..i+3)` followed by
  `u8::from_str_radix(_, 16)` becomes "both bytes are hex digits". Rust also accepts
  `+x`, but that value is at most 15, never 0x2E or 0x25, so it cannot change the
  outcome. The difftest covers `+`.
- **`extract_bearer_token`** works on bytes and returns the token's byte range. Its
  domain is ASCII header values. Both upstream callers obtain the value through
  `HeaderValue::to_str()`, which only admits visible ASCII. On non-ASCII input upstream
  can panic (see FINDINGS.md). Its trimming uses the ASCII whitespace set of
  `char::is_whitespace`.

## Differential tests (`difftest/`)

`cargo test` in `difftest/` builds `synctv-core` from `../upstream-src` (a symlink to the
pinned checkout; set `SQLX_OFFLINE=true`, the workspace's `.sqlx/` is used). It uses the
upstream toolchain `nightly-2026-11-03` and the upstream `Cargo.lock` as the starting
lock. Public items are called through the crate. The private items
(`member_role_policy.rs`, `validate_kick_cooldown_seconds`, `validate_expiration`) are
copied verbatim by `build.rs` from `git show 38970e0:<path>` and compiled in a module
tree that reproduces their `pub(in crate::service::room)` visibility. Inputs come from a
fixed-seed splitmix64.

| Test | Upstream called | Cases |
|---|---|---|
| `constants_match` | every bit constant, `bit_for`, defaults, `Role::permissions` | all |
| `bitspace_maps_agree` | all six `to/from_permissions`, three `includes_only_defined`, `override_bits_from_permissions` | every subset of the 21 admin bits (each also with a random high bit), all 16 guest subsets × 3, 200,000 mixed |
| `has_agrees` | `has`/`has_all`/`has_any` | 100,000 sets × 21 permissions |
| `effective_permissions_agree` | `RoomMember::{effective_permissions, has_permission}` | 200,000 |
| `calculator_agrees` | `RoomSettings::*_permissions`, `EffectivePermissionCalculator::{role_default, effective_for_member, has_permission}` | 100,000 |
| `role_validators_agree`, `override_validators_agree` | the seven `member_role_policy.rs` validators | exhaustive over ids {1,2,3} × roles; 200,000 random bit patterns |
| `kick_cooldown_agrees` | `validate_kick_cooldown_seconds` | 200,011 incl. edges |
| `global_roles_agree` | `UserRole`, `UserStatus` | exhaustive |
| `expiration_agrees` | verbatim `validate_expiration` with a test `Clock` | 200,000 incl. `i64` extremes and leeways above `i64::MAX` |
| `user_and_guest_tokens_agree` | real HS256 tokens from `JwtService::sign_*` checked by `verify_access_token`, `verify_refresh_token`, `GuestTokenValidator::validate_with_version` under a controlled clock | 24,000 rounds, boundaries ±3 s |
| `bearer_extraction_agrees` | `JwtValidator::extract_bearer_token` | 300,000 ASCII headers |
| `bearer_extraction_panics_on_non_ascii` | records finding F1 | 1 |
| `traversal_check_agrees` | `synctv_common::validation::validate_path_for_traversal` | 400,000 random over `%`/hex/`.`/`/`/`+`/NUL/non-ASCII pieces + every string of length ≤ 4 over `%2e5.0/+E` |
| `double_decoding_bypass` | records finding F3 | 2 |

Not differentially tested, because each needs a database-backed service or an async
service with repositories: `plan_member_update` (its validators are tested, but the
composition order was transcribed from `member_roles.rs` and reviewed by hand),
`check_guest_allowed` and `pipeline_check` (both transcribed). The difftests are
evidence of agreement on the tested inputs, not a proof of equivalence. A deliberate
kernel bug (dropping the guest mask) was checked to fail `effective_permissions_agree`.

## Proofs

See STATUS.md for the theorem table (S/C/F), the gate results and the mutants.
