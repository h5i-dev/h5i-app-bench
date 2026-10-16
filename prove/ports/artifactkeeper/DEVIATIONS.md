# artifact-keeper: what the kernel covers and where it differs

Upstream: artifact-keeper/artifact-keeper @ 7c42891, `backend/src/`.

## Covered

| Kernel | Upstream |
|---|---|
| `middleware::repo_visibility_middleware` (+ `lookup_repo`, `no_repo`, `permission_arm`, `role_grant_exists`) | `api/middleware/auth.rs` `repo_visibility_middleware` |
| `middleware::auth_middleware`, `optional_auth_middleware`, `admin_middleware`, `csrf_guard` | `api/middleware/auth.rs`, same names |
| `middleware::guest_access_guard` | `api/middleware/guest_access.rs` `guest_access_guard`, `guard_short_circuit` |
| `paths::is_allowlisted`, `is_oci_v2_path` | `guest_access.rs` `is_allowlisted`, `oci_errors.rs` `is_oci_v2_path` |
| `resolve::try_resolve_auth_outcome`, `validate_api_token_with_scopes`, `classify_token_validation_err`, `decode_basic_credentials`, `extract_bearer_credentials`, `try_resolve_ticket_auth`, `principal_must_change_password` | `api/middleware/auth.rs`, same names |
| `resolve::validate_download_ticket` | `services/auth_config_service.rs` `AuthConfigService::validate_download_ticket` |
| `http::extract_token_from_auth_header`, `extract_token`, `session_cookie_token`, `has_header_credential`, `credential_is_session_cookie`, `request_carries_credentials`, `is_state_changing_method`, `violates_csrf_contract`, `declares_same_origin`, `is_browser_request`, `extract_nuget_push_api_key`, `extract_visibility_token` | `api/middleware/auth.rs`, same names |
| `paths::percent_hex_val`, `percent_decode_path_segment`, `extract_repo_key`, `extract_conda_url_token`, `is_nuget_push_path`, `is_non_mutating_format_post`, `is_pypi_xmlrpc_tail`, `is_anonymous_readable_format_post`, `should_allow_repo_access`, `is_write_method`, `action_for_method`, `public_read_satisfies_acl`, `authenticated_read_satisfies_acl`, `extract_ticket_from_query`, `ticket_method_allowed`, `ticket_path_allowed`, `path_exempt_from_password_change` | `api/middleware/auth.rs`, same names |
| `AuthExtension::{has_scope, access_scope, can_access_repo, require_scope, enforce_mint_ceiling, mint_repo_ceiling, with_scope_gated_admin, require_admin, require_self_or_admin}`, `token_scope::from_claims`, `from_user` | `api/middleware/auth.rs` `impl AuthExtension`, `From<Claims>`, `From<User>` |
| `handlers::require_auth_basic`, `require_auth_basic_scope`, `require_scope_response` | `api/middleware/auth.rs`, same names |
| `token_scope::validate_scopes_pure`, `enforce_admin_only_scopes`, `scopes_grant_access` | `services/token_service.rs` |
| `AccessScope::grants`, `from_option` | `models/access_scope.rs` |
| `Visibility::allows_anonymous_read`, `allows_authenticated_read` | `models/repository.rs` |
| `Claims::effective_iat_ms` | `services/auth_service.rs` |
| `permission::check_permission`, `query_actions`, `check_repository_action`, `check_anonymous_repository_action`, `has_any_rules_for_target`, `validate_principal`, `validate_conditions`, `ip_condition` | `services/permission_service.rs` `PermissionService` methods, `PermissionConditions::validate`, `ip_condition_sql` |
| `net::CidrRange::{parse, contains}`, `first_xff_token_in`, `normalize_xff_token`, `rightmost_untrusted_xff_token`, `resolve_client_ip_addr` | `api/middleware/rate_limit.rs` |
| `handlers::create_permission`, `validate_anonymous_rule`, `require_auth` | `api/handlers/permissions.rs`, up to and including the INSERT |

`difftest/extract_upstream.py` copies these files (whole, up to their test
module) or items verbatim from the commit into `difftest/src/upstream/`
under their upstream module paths, so they compile unchanged. The copied code
runs on real axum requests through `axum::middleware::from_fn_with_state`.
`difftest/sqlx-mock` is a stand-in for sqlx: each SQL statement upstream sends
is evaluated by hand in `difftest/src/shell.rs` over the kernel's snapshot
(WHERE, JOIN, EXISTS, scalar subqueries, NULL, Postgres `inet <<=`).
`create_permission` itself takes axum state, so its gate sequence is
transcribed in `tests.rs`; the gates it calls are the copied ones.

Verbatim upstream lines (non-blank, non-comment): about 2,370; of these about
100 are in functions not ported (below) and about 110 are cache machinery and
data types.

## Not covered (trusted input)

- `AuthService`: JWT verification (`validate_access_token_async`), API-token
  lookup (`validate_api_token`) and password checks (`authenticate`). Oracle
  tables in `trusted.rs`; the failure kinds callers distinguish
  (`ServiceUnavailable`, pool timeout, other) are kept.
- base64 decoding and `IpAddr` parsing: oracle tables.
- The database: `tables.rs` is a snapshot of the rows the queries read.
  `Db::failing` makes a statement fail. Repository ids, keys and tickets are
  assumed unique (they are keys upstream).
- `allowed_cidrs` entries are stored as Postgres's `::inet` reads them
  (`CidrRange`), not as text.
- The response bodies and headers: `Response` names each response shape; the
  difftest checks status, body and challenges per variant. The OCI 401
  (`oci_unauthorized_response`) and its base URL are stubs.
- Not ported: `require_auth_with_bearer_fallback`, `csrf_middleware` (a
  wrapper around `csrf_guard`), `startup_notice`, `public_repository_count`,
  `PermissionService::invalidate_cache`, `PermissionConditions::to_json`, the
  SQL text builders `ip_condition_sql`/`request_ip_sql_ref` (their meaning is
  `ip_condition`), the archive tenant scope, logging and metrics.

## Differences in form

| Where | Upstream | Kernel | Why |
|---|---|---|---|
| everywhere | `&str`, `String`, `Uuid` | `&[u8]`, `Vec<u8>`, `u64` | Aeneas has no strings; ids are opaque |
| `HeaderMap` | `http::HeaderMap` | `(name, value)` pairs in `HeaderMap::iter` order | `get` is the first value of a name, `get_all` all of them in order; `to_str` is `visible_ascii` |
| `Request` | axum request | method, path, query, headers | what the code reads; `OriginalUri` equals the path outside nested routers |
| caches | `PermissionService` caches (30 s), repo cache and miss cache (60 s) | none | the kernel answers as a cache miss; a cached entry can be stale for its TTL upstream |
| `current_client_ip()` | tokio task-local set by `client_ip_context_middleware` | `client_ip` argument | no task-locals in the subset |
| `ExtractedToken<'a>` | borrows | owns | no lifetimes in data |
| path splitting | `split('/')` iterators with `next()` | `split` into a vector and an index | no iterators |
| `extract_ticket_from_query` | `for` with `continue` | `find_ticket_pair`, `decode_ticket` | Aeneas rejects `continue` next to an early return |
| `String::from_utf8` | std | `strs::is_utf8` | checked against std in `utf8_agrees` |
| `str::trim` | Unicode whitespace | ASCII whitespace | every trimmed string passed `to_str`, so it is ASCII |
| `u8::from_str` | std | `parse_u8` | same grammar (`+`, digits, at most 255) |
| `CidrRange::contains` | `checked_shl(..).unwrap_or(0)` | explicit mask cases | no `checked_shl`; the same for every prefix `parse` admits |
| `Option::clone`, derived `Clone` on types with `Option` fields | std | `clone_opt_*`, `duplicate` | Aeneas has no model of `Option::clone` |
| `Claims::effective_iat_ms` | `saturating_mul` | explicit bounds | no `saturating_mul` |
| `create_permission` | JSON body, `CreatePermissionRequest` | decoded request | JSON decoding is not authorization |
| errors | `AppError` with messages | variants only | messages are not decisions |
| module names | | `strs`, `http`, `tables`, `trusted`, `token_scope` | Aeneas emits modules and local variables into one Lean namespace, so a module may not share a name with a variable |

## Observations

- In `repo_visibility_middleware`, `has_write_auth`'s `!authed_via_ticket`
  never changes the decision: a ticket only resolves for GET and HEAD, which
  are not writes. The mutation check confirms this mutation is equivalent.
- `mutation_needs_action` leaves out paths for which `is_non_mutating_format_post` holds.
