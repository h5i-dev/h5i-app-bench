# Bootstrap Academy: what the kernel covers and where it differs

Upstream: Bootstrap-Academy/backend @ fbe5e60. The kernel ports the access
token check, sessions (login, refresh, impersonation, deletion), the login
throttle, MFA (TOTP devices, recovery codes, the admin second-factor rule),
coins and hearts. `transition(snapshot, env, request)` returns the writes that
take effect and the reply.

## Covered

| Kernel | Upstream |
|---|---|
| `access::ensure_admin`, `ensure_email_verified`, `ensure_self_or_admin` | `academy_auth/contracts` `impl Authentication` |
| `access::unwrap_or` | `academy_models/src/user.rs` `UserIdOrSelf::unwrap_or` |
| `access::authenticate`, `authenticate_by_password`, `authenticate_by_refresh_token`, `issue_tokens`, `invalidate_access_tokens`, `list_refresh_token_hashes`, `invalidate_access_tokens_of` | `academy_auth/impl/src/lib.rs` `AuthServiceImpl` |
| `access::invalidate`, `is_invalidated` | `academy_auth/impl/src/access_token.rs` `AuthAccessTokenServiceImpl` |
| `access::refresh_token_hash` | `academy_auth/impl/src/refresh_token.rs` `hash` |
| `throttle::check`, `record_account_failure`, `record_ip_failure`, `reset`, `blocked_for`, `ttl`, `account_key`, `ip_key` (`lock_for`, `pow2_saturating`, `saturating_mul` split out) | `academy_core/session/impl/src/login_throttle.rs` |
| `throttle::failed_auth_get`, `failed_auth_increment`, `failed_auth_reset`, `failed_auth_key` | `failed_auth_count.rs` `get`, `increment`, `reset`, `cache_key` |
| `sessions::create`, `refresh`, `delete`, `delete_user_sessions` | `academy_core/session/impl/src/session.rs` `SessionServiceImpl::{create, refresh, delete, delete_by_user}` |
| `sessions::get_current_session`, `list_by_user`, `create_session`, `prove_recipient`, `impersonate`, `refresh_session`, `delete_session`, `delete_current_session`, `delete_by_user`, `prove_credentials`, `record_failed_attempt` | `academy_core/session/impl/src/lib.rs` `SessionFeatureServiceImpl` |
| `sessions::get_composite_by_name_or_email` | `UserRepository`'s provided method |
| `mfa::authenticate` | `mfa/impl/src/authenticate.rs` |
| `mfa::disable` | `mfa/impl/src/disable.rs` |
| `mfa::create`, `confirm`, `reset` | `mfa/impl/src/totp_device.rs` |
| `mfa::setup` | `mfa/impl/src/recovery.rs` |
| `mfa::initialize`, `enable`, `disable_mfa` | `mfa/impl/src/lib.rs` `MfaFeatureServiceImpl::{initialize, enable, disable}` |
| `coin::get_balance`, `add_coins` | `coin/impl/src/lib.rs` `CoinFeatureServiceImpl` |
| `coin::service_add_coins` | `coin/impl/src/coin.rs` `CoinServiceImpl::add_coins` |
| `heart::get`, `refill` | `heart/impl/src/lib.rs` `HeartFeatureServiceImpl` |
| `heart::heart_get`, `heart_add`, `apply_auto_refill`, `last_auto_refill` | `heart/impl/src/heart.rs` `HeartServiceImpl` |
| `heart::record` | `withdrawal/impl/src/consent.rs` `WithdrawalConsentServiceImpl::record` |
| `heart::text_version` | `academy_models/src/withdrawal.rs` `WithdrawalConsentDeclaration::text_version` |
| `repo::*`, `repo::apply` | the SQL in `academy_persistence/postgres/queries/{user,session,mfa,coin,heart}.sql` and the `Postgres*Repository` methods these services call (`session.update` refuses a disabled owner, `add_coins` maps the check constraints to `NotEnoughCoins`) |
| `valkey::get`, `entry`, `apply` | `academy_cache/valkey` `get`, `set` with `PSETEX`, `remove` |

`difftest/extract_upstream.py` copies these files from the commit into
`difftest/src/upstream/`, with the contract traits they implement. The test
wires the copied services the way `academy_di` does, over an in-memory Postgres
(`mem.rs`, one working copy per transaction, kept on `commit`) and an
in-memory Valkey, and compares reply, database and cache with the kernel's
writes applied, on 400,000 random requests. `count_loc.py`: 1744 lines of
ported service code, 563 of contracts.

## Not covered (trusted input)

- JWT signing, signature and expiry checks: `Request.token` holds the claims of
  a token that verified, or `None`.
- argon2 (`Env.argon2_ok`), the TOTP check including its replay cache
  (`Env.totp`), and reCAPTCHA (`Env.captcha_ok`).
- SHA-256 is taken as injective: the kernel stores refresh tokens and recovery
  codes in place of their hashes, and cache keys by their preimage.
- Randomness: ids, refresh tokens, TOTP secrets and recovery codes come from
  the counter `Env.fresh`, in call order.
- The clock: one reading (`Env.now`, whole seconds) per request.
- Parsing and the REST layer (`PathUserIdOrSelf`, JSON bodies, the user agent
  as device name).
- Postgres row locks (`FOR UPDATE`), isolation and concurrency; the triggers
  that keep limited service subjects out of ordinary sessions (those accounts
  are not in the snapshot).
- Not ported: OAuth2, registration, email verification, password reset,
  premium, purchases, PayPal, the internal coin and heart operations,
  `CoinFeatureService::get_config`.

## Differences in form

| Where | Upstream | Kernel | Why |
|---|---|---|---|
| everywhere | `String`, UUIDs, `DateTime<Utc>`, `Duration` | `Vec<u8>`, `u64` ids, `u64` seconds | Aeneas has no strings; configured durations are whole seconds |
| name and email lookups, cache keys | `to_lowercase`, SQL `lower` | ASCII lowercase (`lower`) | the test alphabet is ASCII; Unicode case folding is not modeled |
| services, repositories | async trait objects wired by `academy_di` | direct calls, table scans over `Db` | Aeneas has no async or trait objects |
| transactions | `begin_transaction`, `commit`, rollback on drop | `Ctx.pending` moves to `Ctx.done` at `commit`; dropped otherwise | same effect: e.g. an expired refresh token's session delete is rolled back but its cache invalidation stays |
| errors | one enum per feature, `anyhow` for the rest | one `Error`; `anyhow` errors become `Internal` | the reachable variants map one to one |
| `get_by_refresh_token_hash` | `.opt()` fails on two matching rows | first match | hashes of fresh tokens are unique |
| `record_*_failure`, `increment`, `now + lock`, `updated_at + ttl`, `last_auto_refill` | `+ 1`, chrono addition (panics on overflow) | `saturating_add` | differs only past `u64::MAX` or chrono's year 262143 |
| `refill` | `-(price as i64)` | `0i64.wrapping_sub(price as i64)` | release-build semantics, so the kernel is total |
| `HeartServiceImpl::add` | `i64` amount, `NotEnoughHearts` below zero | `u64` amount | the only ported caller passes `hearts_max` |
| `Option::clone`, derived `Clone` of structs with `Option` fields | derived | written out (`clone_bytes_opt`) | Aeneas turns `Option::clone` into an axiom |
| modules | `auth`, `session`, `cache`, `db` | `access`, `sessions`, `valkey`, `repo` | in Lean a module name must not equal a local variable name |
| names | `SessionService::delete_by_user`, `MfaFeatureService::disable`, `CoinService::add_coins`, `HeartService::{get,add}` | `delete_user_sessions`, `disable_mfa`, `service_add_coins`, `heart_get`, `heart_add` | clash with the feature function of the same name |
| logging, metrics | `trace!`, `#[trace_instrument]` | removed | not logic |

In the difftest the copied files change only in their `use` lines, dropped
attributes (`trace_instrument`, mockall, the `Build` derive), cut test
modules, and `pub` on the fields of the `*Impl` structs so the test can wire
them. The model types, repository traits and patches are hand-written stubs
in `src/upstream/mod.rs`.
