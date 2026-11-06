# crates.io: status

Upstream rust-lang/crates.io @ `e0fc83aa64e4d53b5447576f8018e3287d4e8982` (2026-11-05). Gate:
`h5i app check` passes with 23 listed theorems (148 checked in total), axioms only `propext`,
`Classical.choice`, `Quot.sound`; `h5i app extract --check` up to date.

**Theorem classes: S = 22, C = 0, F = 1.** (The correspondence lemmas, about 110, live in
`proofs/Verified/` and are not listed.)

## Theorems

S: security property, falsifiable by a plausible bug. C: correspondence / helper. F: finding
(FINDINGS.md). "Kills" names an auto-generated mutant (`h5i app mutate --auto`) whose behaviour
violates the statement; results of the mutation run are in "Mutation" below.

| # | Theorem | Class | Bug it rules out | Kills |
|---|---|---|---|---|
| 1 | `cross_origin_never_authenticates` | S | a cross-origin request authenticated (CSRF) | `origins_ok@auth.rs:115:if-false` |
| 2 | `token_authentication_is_live` | S | a token accepted without a live matching row, for a missing/locked user, or alongside a session | `token_live@auth.rs:211:and-or`, `token_user@auth.rs:263:if-false` |
| 3 | `revoked_or_expired_token_rejected` | S | revoked or expired tokens accepted; expiry off by one | `token_live@auth.rs:204:if-false`, `:209:boundary` |
| 4 | `session_needs_current_epoch` | S | stale session cookies accepted after "log out everywhere" | `cookie_user@auth.rs:240:negate`, `:if-false` |
| 5 | `locked_account_never_authenticates` | S | locked accounts authenticating | `cookie_user@auth.rs:232:if-false`, `is_locked@auth.rs:138:drop-not`, `:143:boundary` |
| 6 | `cookie_only_rejects_tokens` | S | API tokens on website-only endpoints | `check@auth.rs:348:if-false` |
| 7 | `token_needs_endpoint_scope` | S | a scoped token used on an endpoint outside its scopes | `check@auth.rs:351:if-false`, `contains_scope@scopes.rs:33:if-true` |
| 8 | `token_confined_to_crate_scopes` | S | a crate-scoped token acting on another crate | `check@auth.rs:354:if-false`, `scope_matches@scopes.rs:73:if-true`, `any_scope_matches@scopes.rs:85:if-true` |
| 9 | `crate_scoped_token_needs_crate_or_opt_in` | S | crate-scoped tokens on multi-crate endpoints without explicit opt-in | `crate_scope_matches@auth.rs:319:if-true` |
| 10 | `full_rights_only_for_listed_user` | S | team members (or anyone) getting owner-management rights | `owner_step@rights.rs:86:if-true`, `rights_loop@rights.rs:110:if-true` |
| 11 | `team_rights_need_active_membership` | S | pending/inactive or unauthenticated team members publishing | `owner_step@rights.rs:89:and-or`, `rights_loop@rights.rs:119:if-true` |
| 12 | `rights_decrypt_failure_denies_direct_owner` | F | F1 | — |
| 13 | `trustpub_publish_bound_to_crate` | S | a Trusted Publishing token publishing a crate it was not issued for | `trustpub_auth@publish.rs:167:if-false`, `has_crate@publish.rs:144:if-true` |
| 14 | `trustpub_cannot_create_crates` | S | Trusted Publishing registering new crate names | (statement fixed by the `existing` match; no auto mutant) |
| 15 | `trustpub_only_rejects_users` | S | token/cookie publishes to a trusted-publishing-only crate | `user_publish@publish.rs:252:if-false` |
| 16 | `publish_existing_needs_ownership` | S | non-owners publishing new versions | `owner_ok@publish.rs:221:if-false` |
| 17 | `publish_token_scoped` | S | `publish-new`-only tokens updating, or crate scopes ignored on publish | `check@auth.rs:351:if-false`, `check@auth.rs:354:if-false` |
| 18 | `exchange_only_matching_configs` | S | access tokens for configs of another repository/owner id/workflow/environment, or for no crate | `config_level@trustpub.rs:219:and-or`, `:222:negate`, `:225:drop-not`, `exchange_github@trustpub.rs:299:if-false` |
| 19 | `exchange_environment_enforced` | S | environment-restricted configs matched without the environment | `config_level@trustpub.rs:228:if-false` |
| 20 | `exchange_jti_single_use` | S | OIDC token replay | `exchange_github@trustpub.rs:268:if-false` |
| 21 | `exchange_replay_rejected` | S | replay after a successful exchange | `jti_used@trustpub.rs:195:if-false` |
| 22 | `exchange_rejects_forbidden_events` | S | `pull_request_target` / `workflow_run` tokens exchanged | `exchange_github@trustpub.rs:271:if-false`, `:and-or` |
| 23 | `publish_rate_limit_bounded` | S | a bucket that refills past `burst`, or that never empties: more than `burst + elapsed/rate` publishes | `take_token@rate_limit.rs:28:if-true`, `:if-false` |

## Mutation

A first run over all 167 auto mutants of the 38 decision functions was stopped after 4 mutants
(all caught): under the host's load each mutant took 10-15 minutes. The run that backs the
"Kills" column is targeted: the 32 named mutants above plus two expected survivors,
`h5i app mutate --auto --no-baseline -j 2 --only <name> ...` (log
`/mnt/scratch/oss-sec/tmp/a/mutate-c2.log`, not committed). The parsers
(`parse_auth_header`, `validate_*`, `parse_access_token`, `workflow_filename`/`yml_end`/
`match_in_segment`, `parse_i32`/`digits_value`) have no Lean spec and are covered by the difftest
only; their ~200 auto mutants are not run.

Expected survivors and why:
- `exchange_github@trustpub.rs:289/292/295:if-false`: the three intermediate emptiness checks
  only choose the error message; a non-empty `matching_ids` implies all three, so on success
  they are equivalent mutants.
- `take_token@rate_limit.rs:27:*`, `check_rate_limit@rate_limit.rs:37:boundary`,
  `take_token@rate_limit.rs:28:boundary`: they make the limiter stricter (or are equivalent at
  the boundary `add = burst - kept`); the theorem is an upper bound, so they satisfy it.
- Mutants that only make a function fail or refuse (out-of-bounds `boundary` mutants, `if-true`
  on refusal branches): the S theorems are about successful runs; liveness is not claimed.

### Mutation results

(filled in when the targeted run finishes)

## Done
- Kernel, extraction, 23 gated theorems (incl. the rate limiter), DEVIATIONS.md, FINDINGS.md.
- Difftest `difftest/` (8 tests, pass).

## Next
- Lean specs for the parsers (`parse_auth_header`, `parse_access_token`, `workflow_filename`).
- Yank / owner-management handlers on top of `AuthCheck` + `Rights`.

## Resume
`cd prove && h5i app check ports/cratesio`;
`cargo test --release --manifest-path ports/cratesio/difftest/Cargo.toml`
(needs `ports/cratesio/upstream-src -> /mnt/scratch/oss-sec/upstream/crates.io`).
