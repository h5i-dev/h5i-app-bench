# Port targets

Axum apps with real authorization or business rules, to port onto i5h and
verify. Surveyed 2026-09-25; axum confirmed from each `Cargo.toml`.

| App | Size | Authorization model | Past bug | Fit |
|---|---|---|---|---|
| [Kellnr](https://github.com/kellnr/kellnr) (crate registry) | ~12k LOC, 16 routes | admin, read-only users, crate owners/users/groups, restricted downloads | [PR #1243](https://github.com/kellnr/kellnr/pull/1243): read-only session users could change owners and ACLs | easy |
| [Atuin](https://github.com/atuinsh/atuin) sync server | ~2.6k LOC, 14 routes | per-user records, open-registration flag | [#3297](https://github.com/atuinsh/atuin/issues/3297) (open): account delete without password | easy |
| [Wastebin](https://github.com/matze/wastebin) | ~6.3k LOC | owner-only delete, expiry, burn after reading | [#190](https://github.com/matze/wastebin/issues/190): link previews burn pastes | easy |
| [RealWorld/Conduit](https://github.com/launchbadge/realworld-axum-sqlx) | ~2.1k LOC, 12 routes | author-only edit/delete; check hidden in a SQL CTE | [#16](https://github.com/launchbadge/realworld-axum-sqlx/issues/16): wrong `favorited` flag | easy (axum 0.3, needs update) |
| [crates.io](https://github.com/rust-lang/crates.io) | ~12k LOC controllers, 66 endpoints | owner rights None/Publish/Full, team owners, token scopes, delete rules | [PR #14760](https://github.com/rust-lang/crates.io/pull/14760): locked accounts passed OAuth authorization | medium (team membership comes from GitHub) |
| [Svix](https://github.com/svix/svix-webhooks) | ~6.6k LOC | org / application access levels | none found | medium |
| [Windmill](https://github.com/windmill-labs/windmill) | ~56k LOC API, 312 routes | workspaces, groups, folders, path-scoped tokens, Postgres RLS | GHSA-2ppx-66jv-wpw5 (token scope bypass), GHSA-x2wf-f962-7frq (cross-workspace resume) | hard; one slice is medium |

Not suitable: Lemmy (actix-web), the axum examples (no authorization; smoke
tests only), Rauthy and Kanidm (identity-protocol logic).

## Plan

1. **Kellnr first.** Theorem: a read-only non-admin cannot modify owners,
   users, or groups, whatever the login path. Show it fails on the code
   before PR #1243 and holds after.
2. **Atuin** as a second small target: account deletion requires the password;
   deleting a user removes all of that user's rows.
3. **crates.io** delete/yank/owner rules for credibility, with GitHub team
   membership as an input fact.
4. **Conduit** as the baseline for comparing effort against a plain app.

## Results

### Kellnr (2026-09-25): done

`examples/kellnr/` models Kellnr's registry authorization before and after
PR #1243. On the fixed code, Lean proves that a read-only non-admin commits
nothing (any login path), that ACL and yank writes need an admin or owner, the
last-owner rule, and the restricted-download rule. On the old code, Lean
proves the read-only theorem false with a concrete session login that adds an
owner, and a token login that grants a group. Effort: 329 extracted Rust lines,
a 60-line spec, 466 proof lines, 61 lines of counterexamples. See
`examples/kellnr/README.md` for what is and is not modeled.

