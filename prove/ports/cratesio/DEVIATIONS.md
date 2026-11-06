# crates.io: what the kernel covers and where it differs

Upstream: rust-lang/crates.io @ `e0fc83aa64e4d53b5447576f8018e3287d4e8982` (2026-11-05). The
checkout is linked as `upstream-src` (gitignored); the difftest's `build.rs` reads files with
`git show <rev>:<path>`.

## Threat model

crates.io is the Rust package registry. The security-critical decisions are who may publish (or
yank, or manage owners of) a crate, and with which credential:

| Asset / decision | Attacker | Upstream mechanism |
|---|---|---|
| Account session | CSRF from another origin, stolen old cookie | `verify_origin`; signed session with a per-user epoch |
| API tokens | leaked/revoked/expired token, over-broad token | `find_by_api_token` filter (`revoked`, `expired_at`); RFC 2947 endpoint and crate scopes; `AuthCheck::only_cookie` endpoints |
| Locked accounts | the locked user | `ensure_not_locked` on both paths |
| Crate ownership | non-owners, team non-members | `Rights::get` (user owners, GitHub team membership) |
| Publishing | non-owners, scoped tokens, CI tokens | `publish`: Trusted Publishing branch or `AuthCheck` with `publish-new`/`publish-update` + crate scope, `trustpub_only`, `Rights >= Publish` |
| Trusted Publishing | forks, other repos/workflows/environments, replay | `handle_github_token_inner`: jti replay table, event filter, repository/owner-id/workflow/environment matching |

## Covered

| Kernel | Upstream |
|---|---|
| `validation::validate_crate_name`, `validate_dependency_name` | `crates/crates_io_validation/src/lib.rs` |
| `scopes::is_valid_pattern`, `scope_matches`, `any_scope_matches`, `contains_scope` | `crates/crates_io_database/src/models/token/scopes.rs` `CrateScope::is_valid_pattern`, `matches`; `Vec::contains` on `EndpointScope` |
| `auth::parse_auth_header` | `src/auth.rs` `AuthHeader::optional_from_request_parts` (on a present header) |
| `auth::origins_ok` | `src/controllers/util.rs` `verify_origin` |
| `auth::cookie_user`, `is_locked` | `authenticate_via_cookie`, `ensure_not_locked`, `parse_epoch_from_session`, `ensure_valid_epoch` |
| `auth::token_user`, `find_token`, `token_live` | `authenticate_via_token`, `HashedToken::parse` (prefix), `ApiToken::find_by_api_token`'s filter |
| `auth::authenticate`, `check`, `endpoint_scope_matches`, `crate_scope_matches` | `authenticate`, `AuthCheck::check` and its two scope methods |
| `rights::rights` (+ `rights_loop`, `owner_step`, `membership_of`) | `src/controllers/helpers/authorization.rs` `Rights::get` |
| `publish::publish_auth`, `user_publish`, `owner_ok`, `trustpub_auth`, `publish_check`, `trustpub_only` | `src/controllers/krate/publish.rs` `publish`: auth header, trusted-publishing branch, endpoint scope choice, `AuthCheck`, `trustpub_only`, the `Rights::get(..) < Publish` check |
| `publish::parse_access_token`, `checksum` | `crates/crates_io_trustpub/src/access_token.rs` `AccessToken::from_str`, `checksum` |
| `trustpub::exchange_github` (+ `config_level`, `any_level`, `matching_ids`, `env_ok`, `jti_used`) | `src/controllers/trustpub/tokens/exchange/mod.rs` `handle_github_token_inner`, `insert_jti` |
| `trustpub::workflow_filename` | `crates/crates_io_trustpub/src/github/workflows.rs` `extract_workflow_filename` (the regex, hand-ported) |
| `trustpub::parse_i32` | `str::parse::<i32>` of `repository_owner_id` |

## How it is checked

`difftest/` (8 tests, all pass; `cargo test --release --manifest-path ports/cratesio/difftest/Cargo.toml`):
- `crates_io_validation` is linked as the upstream crate; 300k generated names (ASCII, `-_*./+`,
  space, multi-byte) for both validators, error variant compared.
- Copied verbatim from the pinned revision (`build.rs`): `CrateScope` (`TryFrom<&str>`,
  `is_valid_pattern`, `matches`), `AuthCheck::endpoint_scope_matches`/`crate_scope_matches`,
  `ensure_not_locked`, `AuthHeader::optional_from_request_parts`, `AccessToken` (`generate`,
  `finalize`, `FromStr`, `checksum`), `extract_workflow_filename` (with the real `regex` 1.13.1).
  Stubs: `EndpointScope` (same five variants, without diesel derives), `User`'s lock columns, the
  error constructors.
- 100k-300k cases each, fixed seeds; `ensure_not_locked` compares against `Utc::now()` with lock
  ends at least 10 minutes away.
- Not differentially tested: `authenticate`'s control flow (needs Postgres and the session
  layer), `Rights::get` (needs a GitHub client), `publish`'s flow and `handle_github_token_inner`
  (need Postgres). They are ported by reading; their helpers above are tested.
- Testing is evidence, not a proof of equivalence.

## Trusted (assumed, not proved)

- Hashing: API tokens and Trusted Publishing tokens are compared by plaintext in the kernel;
  upstream compares SHA-256 hashes. Assumed injective.
- The session cookie's signature and `user_id`/`epoch` parsing (the kernel receives
  `session_uid: Option<i32>` and `Epoch`), `axum`, `tower-sessions`.
- JWT verification (`GitHubClaims::decode`: signature, issuer, audience, `exp`/`nbf`/`iat` with
  leeway, JWKS fetching): the kernel receives the claims it accepted.
- GitHub's team-membership API (one answer per team) and `TokenEncryption::decrypt` (an input
  saying whether it succeeds).
- Postgres: queries return the rows the kernel filters; `lower()` on owner/repository names and
  Rust `to_lowercase()` on environments are modeled as ASCII lowercasing (GitHub owner and
  repository names are ASCII; environment names may not be — a deviation for non-ASCII
  environment names).
- `Crate::by_name` (canonical name lookup) is an input (`existing`); so are the owners of the row
  the insert-or-update lands on (`owners_at_write`).
- Transactions: the exchange's jti insert rolls back on any later error (the kernel returns the
  jti table only on success).

## Differences in form

| Where | Upstream | Kernel | Why |
|---|---|---|---|
| everywhere | `&str`, `String` | `&[u8]`, `Vec<u8>` | no strings in the subset; checks are bytewise; `chars().count()` is the count of non-continuation bytes |
| tokens | `ApiToken` row returned | its index in the table | avoids cloning a row with nested vectors; same information |
| `Rights::get` | `match` in the loop with early returns | `owner_step` returns a code `0..4` | Aeneas cannot expand an enum match with early return inside a loop |
| `extract_if` chain | three `extract_if`s, then `crate_ids` | `any_level(k)` for each step, `matching_ids` | same emptiness tests and the same ids in the same order |
| `extract_workflow_filename` | regex `([^/]+\.(yml|yaml))(@.+)` | byte scan: first slash-free segment with a match, last `@` in it | leftmost-first semantics with greedy `[^/]+`; differentially tested |
| publish | `actor_gh` is the user row's `gh_encrypted_token`/`gh_login` | two inputs `gh_token`, `gh_login` | the user row is not modeled beyond `auth::User` |
| errors | messages and status codes | error variants | |

## Not covered

Rate limiting (`rate_limiter.rs`, SQL token bucket), GitLab Trusted Publishing, config creation
validators (`github/validation.rs`), owner invitations, yank/unyank and owner-management
endpoints (they use `AuthCheck` + `Rights`, which are covered, but their handlers are not ported),
crate deletion rules, `verified_email` and daily version limits in `publish`, the rest of
`publish` after the ownership check.

## Abandoned / unfinished

- `parse_auth_header`, `parse_access_token`, `workflow_filename` and `parse_i32` have no Lean
  specs yet (they are trusted parsers in the theorems, which take their results as hypotheses);
  they are covered by the difftest only.
