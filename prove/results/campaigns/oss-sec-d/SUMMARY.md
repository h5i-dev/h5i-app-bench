# OSS security-proof campaign, session d: synctv and windmill

| Project | Upstream (pinned) | S / C / F | Gate | Mutants | Difftests |
|---|---|---|---|---|---|
| synctv | synctv-org/synctv @ `38970e0` | **30 / 9 / 2** | doctor, extract --check, check (516 theorems in the gate), lint: pass | 41/41 caught (1 equivalent, see below) | 15 pass |
| windmill | windmill-labs/windmill @ `9dedc42` | **15 / 5 / 1** | doctor, extract --check, check, lint: pass (see STATUS for the latest run) | 13/13 caught + 5 new (see STATUS) | 9 pass |
| **Total** | | **45 / 14 / 3** | | | |

Per-theorem tables, with the mutant that falsifies each S statement, are in
`prove/ports/{synctv,windmill}/STATUS.md`. Threat models, ported functions
(upstream file:line), deviations and difftest coverage are in `DEVIATIONS.md`.

## What was proved

**synctv** (`synctv-core`: room permissions, member policy, tokens)
- Guests never hold anything but the four guest-assignable permissions, whatever the
  server defaults, room settings or member override columns contain. All inputs are
  arbitrary `u64` bitmasks.
- A member's own overrides and the room settings can only move the seven
  member-assignable permissions. Admins read only the admin override columns; others
  read only the plain ones. Deny always wins. With the compiled defaults, `DeleteRoom`
  needs an explicit grant.
- Role policy: the creator role is never assignable, only the creator admits admins
  or changes roles, a role change never targets the creator, and overrides stay in the
  bitspace of the member's new role through the right channel. Permission updates
  require `ManageMemberPermissions`. The kick cooldown is bounded.
- Global roles: only root manages root or admins, users manage nobody, banned
  accounts cannot log in.
- Tokens: no acceptance after `exp + leeway` (with saturation); token types are
  separated; room-wide guest revocation works; guests are admitted only with guest
  mode on (fail closed), room consent and no room password. `SecurityPipeline::check`
  accepts only live, unbanned users with a matching password version, 2FA and a
  non-revoked JTI, and fails closed on blacklist outage. An accepted
  `Authorization` value starts with `Bearer ` and carries a non-empty token.
- Path validation (`validate_path_for_traversal`): accepted paths have no literal
  `..`, NUL, `%00`, `./.` or recognised encoded dot, and one round of
  percent-decoding never yields `..`.

**windmill** (`windmill-common` scopes, `windmill-api-auth` path checks)
- Path ownership: non-admins act only on `u/<self>/...` or folders they own.
  Preview job paths never traverse (no leading `/`, no `..`, no NUL, even for
  admins) and stay in the caller's namespace. `is_owner` needs the owner flag.
  Instance-admin actions reject job tokens.
- Scopes: no cross-domain grant; `read` grants only `read`; `jobs:write` never runs
  jobs. Delegation (`scope_contains`) stays in domain and action, and
  `resource_covers` never widens a path grant: full path-set semantics over
  arbitrary byte strings. ASCII wildcards respect the `/` boundary.
- `check_scopes`: a genuinely scoped token passes only if one of its scope strings
  has the requirement's domain field and a covering action field. A malformed
  requirement is rejected. `extra_perms` grants only through an explicit `true` entry
  for the user or one of their groups.

## Findings

All are low or info. None is exploitable from the API as far as this analysis found.
No upstream issues were filed.

- **windmill W1 (low):** the wildcard boundary check compares a character index with a
  byte length. `f/dé/*` matches `f/déx/y` (Lean F theorem plus an upstream difftest).
  It is reachable for non-ASCII sub-path prefixes within one folder; folder names are
  ASCII.
- **windmill W2 (low):** `resources_match` matches symmetrically for at most 4
  resources and asymmetrically above, so token minting is not monotone (upstream
  difftest; Lean statement open).
- **synctv F3 (low):** `validate_path_for_traversal` misses double encodings of the
  hex digits. `%2%65%2%65` is accepted and decodes twice to `..` (Lean F theorem plus
  an upstream difftest). It matters only for a consumer that decodes twice.
- **synctv F1 (info, latent):** `JwtValidator::extract_bearer_token` panics on
  non-ASCII input at byte 7. It is unreachable through the current callers, which pass
  `HeaderValue::to_str()` output.
- **synctv F2 (info):** the own-override pre-check of
  `EffectivePermissionCalculator::has_permission` is redundant (Lean F theorem). It
  yields an equivalent mutant.

## Gaps and caveats

- Proofs are about the extracted kernels. Equivalence to upstream rests on
  differential tests (fixed seeds; several hundred thousand cases per function).
  Those are evidence, not proof.
- Three synctv decisions (`plan_member_update`, `check_guest_allowed`,
  `pipeline_check`) are transcriptions of async, database-backed code and are not
  difftested.
- windmill: `intersect_job_token_scopes` is ported and difftested but has no S
  theorem yet. The route-level scope checks are not ported. W2 has no Lean statement.
- Mutation "caught" means some proof broke. For each S theorem the STATUS tables name
  a mutant that makes the *statement* false, not just its proof.
- **Harness proposal:** `h5i app lint` walks the gitignored `upstream-src` symlink and
  reports upstream's own routes. The lint results above were obtained with the
  symlink temporarily removed.
