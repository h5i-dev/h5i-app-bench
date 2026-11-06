# windmill: status

**Theorem classes: S = 12, C = 4, F = 1** (17 theorems in `[check] theorems`).
Upstream pinned at `9dedc42b4ece1fbceae7d695ec51a508caa49710`. Threat model, ported code
and deviations are in DEVIATIONS.md; findings are in FINDINGS.md.

## Theorems

Classes: **S** is a security property, stated independently of the implementation and
falsifiable by a plausible bug. **C** is a correspondence lemma (kernel = model).
**F** is a finding. "Killed by" names a mutant from `h5i-app.toml` under which the S
statement is false. The counterexample is given in brief.

| Theorem | Class | Statement (informal) | Killed by (counterexample) |
|---|---|---|---|
| `owner_of_path_sound` | S | a non-admin passes `require_owner_of_path` only for `u/<own name>/...` or `f/<owned folder>/...` | `owner_u_any_user` (`u/bob/x` for alice), `owner_f_skips_owner_check` |
| `preview_spec` | C | full postcondition of `require_path_read_access_for_preview` | — |
| `preview_never_traverses` | S | an accepted preview path has no leading `/`, no `..` segment, no NUL, even for admins | `preview_admin_skips_traversal`, `preview_no_nul_check` |
| `preview_requires_namespace` | S | a non-admin previews only in their user namespace, a folder they can read, or `hub` | `preview_any_folder` |
| `is_owner_sound` | S | `is_owner` holds only for admins and folder owners (not mere readers or writers) | `is_owner_ignores_owner_flag` |
| `instance_admin_never_job_token` | S | instance-global admin actions reject job tokens (`WM_TOKEN`) and require admin | `instance_admin_allows_job_token` |
| `covers_spec` | C | `resource_covers c r = true → coversSem c r` as a WP spec | — |
| `resource_covers_sound` | S | delegation never widens a path grant: every path the requested pattern names is named by the caller's | `covers_no_slash_boundary` (`f/a/*` would cover `f/ab`) |
| `wildcard_ascii_boundary` | S | for ASCII resources a `p/*` wildcard matches only `p` and `p/...` | `wildcard_no_boundary` |
| `wildcard_unicode_crosses_boundary` | F | `f/dé/*` matches `f/déx/y` (FINDINGS W1) | — |
| `includes_true` | C | a granting `includes` implies same domain and a covering action | — |
| `scope_never_crosses_domain` | S | a scope never grants a requirement in another domain | `includes_ignores_domain` |
| `read_never_grants_more` | S | a `read` scope grants only `read` requirements | `read_covers_write` |
| `jobs_write_never_runs` | S | `jobs:write` never grants `jobs:run` | `write_runs_in_every_domain` |
| `contains_true` | C | an accepted `scope_contains` implies same domain and a covering action | — |
| `delegation_stays_in_domain_and_action` | S | a minted scope stays in the caller's domain and in an action the caller's covers | `contains_ignores_domain` |
| `read_delegates_only_read` | S | a `read` caller can only mint `read` | `read_covers_write` |

Helper lemmas (byte loops, `split`, `prefix`, `nth_char_is_slash`, list facts) are in
`proofs/Lemmas.lean`. They are gated but not listed and not counted.

## Gate results

- `h5i app doctor ports/windmill`: 0 failed, 0 warnings.
- `h5i app extract --check ports/windmill`: extraction is up to date.
- `h5i app check ports/windmill`: proofs ok. The gate checked 143 theorems in 3 modules
  against propext, Classical.choice and Quot.sound.
- `h5i app lint ports/windmill`: lint ok, run without the `upstream-src` symlink (same
  harness issue as in synctv's STATUS).
- `cargo +stable test` in `difftest/` (`SQLX_OFFLINE=true`): 9 passed.
- `h5i app mutate -j2 ports/windmill`: see "Mutation" below.

## Mutation

13 hand-written mutants; results are recorded below when the run finishes.

## Not yet proved (next steps)

- `check_scopes`: a scoped token passes only with a granting scope, and it rejects a
  malformed requirement. This needs a `from_scope_string` spec (split on `:`/`,` plus
  part counts).
- `intersect_job_token_scopes` never widens. The proof needs reflexivity of
  `scope_contains` and a parse spec.
- W2 as a Lean F theorem. This needs a `resources_match_small/large` spec. W2 is
  currently shown by the difftest only.
- `get_perm_in_extra_perms`: `Some(true)` only with a matching `u/<user>` or
  `g/<group>` entry set to `true`.
- Route-level scope checks (`windmill-api-auth/src/scopes.rs`), job read/cancel
  confinement, and the `check_extra_perms` disagreement.

## Resume

- Proofs: `cd proofs && lake build` (about 3 minutes).
- Difftest: `cd difftest && SQLX_OFFLINE=true cargo +stable test`. This needs the
  `upstream-src` symlink to `/mnt/scratch/oss-sec/upstream/windmill` at the pinned
  commit.
