# windmill port: scope, threat model and deviations

Upstream: <https://github.com/windmill-labs/windmill>, pinned at
**`9dedc42b4ece1fbceae7d695ec51a508caa49710`** (2026-11-05, "fix: reserve the system
usernames used for jobs and audit logs (#12236)"). Only the Rust backend is in scope
(`backend/windmill-common`, `backend/windmill-api-auth`). The TypeScript frontend is
not.

## Threat model

Windmill runs scripts, flows and apps for workspaces. Within a workspace, paths
`u/<user>/...`, `f/<folder>/...` and `g/<group>/...` name what an item belongs to.
API tokens can be restricted by scopes `domain:action[:resources]`, for example
`scripts:read:f/team/*`. A job runs with a `WM_TOKEN` whose scopes are the
intersection of what its caller and the script allow. The attacker holds a
restricted token or a non-admin account and tries to:

1. reach an item outside their namespace or folder (path ownership, preview paths,
   path traversal in preview job paths);
2. use a scope for another domain, another action, or a path outside its pattern
   (`ScopeDefinition::includes`, `resource_matches_pattern`);
3. mint or derive a token broader than their own (`scope_contains`,
   `resource_covers`, `intersect_job_token_scopes`);
4. use a job token for instance-global admin actions (`require_instance_admin`).

**Trusted, not modelled:** token lookup and signature checks; the database (row-level
security, which is what actually enforces secret-variable read access); how
`ApiAuthed` is built (groups, folders, `is_admin` come from the DB); and the HTTP
framework. Route-level scope enforcement (`windmill-api-auth/src/scopes.rs`,
`check_route_access`) is not ported.

## Ported code (upstream file:line at the pinned commit)

| Kernel (`kernel/src`) | Upstream |
|---|---|
| `scopes::from_scope_string` | `windmill-common/src/scopes.rs:46` |
| `scopes::includes` (+ `action_covers`, the action `match`) | `windmill-common/src/scopes.rs:117` |
| `scopes::resources_match`, `_small`, `_large` | `windmill-common/src/scopes.rs:162, 174, 185` |
| `scopes::resource_matches_pattern`, `matches_wildcard` | `windmill-common/src/scopes.rs:212` |
| `scopes::scope_contains` | `windmill-common/src/scopes.rs:490` |
| `scopes::resource_set_contains`, `resource_covers` | `windmill-common/src/scopes.rs:531, 544` |
| `scopes::intersect_job_token_scopes` (`Some`/`Some` case) | `windmill-common/src/scopes.rs:598` |
| `authz::check_scopes` | `windmill-api-auth/src/lib.rs:423` |
| `authz::is_effectively_unscoped` (+ `scope_restrictions`) | `windmill-api-auth/src/lib.rs:458, 471` |
| `authz::is_owner`, `require_is_owner`, `require_owner_of_path` | `windmill-api-auth/src/lib.rs:815, 823, 834` |
| `authz::get_perm_in_extra_perms` | `windmill-api-auth/src/lib.rs:1348` |
| `authz::require_path_read_access_for_preview` | `windmill-api-auth/src/lib.rs:1440` |
| `authz::is_instance_admin`, `require_instance_admin` | `windmill-api-auth/src/lib.rs:327, 333` |

## Differences from upstream

- **Strings** are UTF-8 byte strings (`&[u8]` / `Vec<u8>`), and `str::split` is the
  kernel's `bytes::split`. `resource.chars().nth(n) == Some('/')` is
  `bytes::nth_char_is_slash`: it counts character starts (bytes that are not
  `0b10xx_xxxx`), so it is exact for valid UTF-8, which every Rust `&str` is.
- **Options** (`kind: Option<String>`, `resource: Option<Vec<String>>`,
  `scopes: Option<Vec<String>>`, `job_id: Option<Uuid>`) are a flag plus a value.
- **`resources_match_large`** replaces its `HashSet` of exact scope resources with a
  scan (`exact_contains`), which is the same membership test.
- **Loops restructured for Aeneas**, with the same results:
  - The nested loop of `resources_match_small` calls a helper (`any_scope_matches`).
  - The `match` inside the loops of `intersect`/`some_contains` is a helper
    (`covered_by`, `parsed_contains`).
  - `check_scopes` is two helper loops: `any_grants`, and
    `!is_effectively_unscoped` in place of the `is_scoped_token` flag.
    Upstream returns `Ok` at the first granting non-filter scope. Otherwise it denies
    iff some non-filter scope exists. The kernel computes the same thing.
- **JSON `extra_perms`** is a list of `PermEntry { key, is_bool, value }` plus an
  `is_object` flag. `serde_json` object keys are unique, so `obj.get(k)` is the first
  entry with key `k`.
- **Errors** keep only their kind (`BadRequest`/`PermissionDenied`/`NotAuthorized`/
  `RequireAdmin`).
- **Lean preconditions:** theorems that split a path assume
  `path.length < usize::MAX`, the bound under which the last `Vec::push` of
  `split` cannot overflow.

## Differential tests (`difftest/`)

`cargo +stable test` in `difftest/` (with `SQLX_OFFLINE=true`; the workspace's
`backend/.sqlx` is used) builds `windmill-common` and `windmill-api-auth` from
`../upstream-src`. `default-features = false` gives the OSS build. The build uses the
same `[patch.crates-io]` as upstream (the windmill sqlx fork) and starts from the
upstream `Cargo.lock`. The private matchers of `scopes.rs` are copied verbatim from
`git show 9dedc42:backend/windmill-common/src/scopes.rs` by `build.rs`. Inputs come
from a fixed-seed splitmix64 over scope/resource/path alphabets that include `*`,
`/*`, non-ASCII (`é`), empty segments, `..` and NUL.

| Test | Upstream called | Cases |
|---|---|---|
| `parse_agrees` | `ScopeDefinition::from_scope_string` | 200,000 |
| `includes_agrees` | `includes`, `scope_contains` | 300,000 parsed pairs |
| `resource_matchers_agree` | `resources_match`, `_small`, `_large`, `resource_set_contains`, `resource_matches_pattern`, `resource_covers` | 300,000 list pairs |
| `intersect_agrees` | `intersect_job_token_scopes` | 50,000 |
| `check_scopes_agrees` | `check_scopes`, `is_effectively_unscoped` | 200,000 |
| `path_ownership_agrees` | `is_owner`, `require_is_owner`, `require_owner_of_path`, `require_path_read_access_for_preview`, `is_instance_admin`, `require_instance_admin` | 200,000 |
| `extra_perms_agree` | `get_perm_in_extra_perms_for_authed` | 200,000 |
| `unicode_prefix_crosses_folder_boundary` | records finding W1 on upstream | 1 |
| `delegation_not_monotone_across_size_split` | records finding W2 on upstream | 1 |

All 9 pass. They are evidence of agreement on the tested inputs, not a proof of
equivalence.

## Proofs

See STATUS.md for the theorem table (S/C/F), the gate and the mutants, and FINDINGS.md
for the findings.
