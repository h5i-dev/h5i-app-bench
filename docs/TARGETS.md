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
5. **Wastebin** for time-dependent rules (expiry, burn after reading).

All five are done; see Results.

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


### Atuin (2026-09-26): done

`examples/atuin/` models the sync server's account and record rules (at
5b10eb0). Lean proves user isolation, that replies contain only the caller's
records, that deleting an account leaves no session or record behind, unique
users and names, and the record size cap, for every command. For issue #3297
(delete without password, still open), Lean proves the fixed kernel requires
the password and that Atuin's current behavior lets any signed-in user delete
without it. Effort: 470 kernel lines, a 65-line spec, 660 proof lines (about
1.4 per kernel line). See `examples/atuin/README.md`.


### Wastebin (2026-09-27): done

`examples/wastebin/` ports Wastebin's paste rules (at b27a2ab) to a kernel
with a PostgreSQL server; the shell supplies the time and random slugs.
Lean proves that the kernel never fails, that every write is allowed (only
the owner deletes a live ordinary paste), unique ids and slugs, that a read
shows only the requested paste and never an expired one, and that a
burn-after-reading paste is shown at most once. For issue #190 (link
previews burned pastes), Lean proves the paste page is preview-safe after
commit 632ddf2 and gives a reachable counterexample for the code before it;
`/raw` links still burn on a plain GET. Effort: 275 kernel lines, a 51-line
spec, 700 proof lines (about 2.5 per kernel line). See
`examples/wastebin/README.md`.


### Conduit (2026-09-27): done

`examples/conduit/` ports the RealWorld backend of realworld-axum-sqlx (at
f1b2565), every route, with a PostgreSQL server that speaks the RealWorld JSON
API. Lean proves that only an article's author edits or deletes it and its
rows, only a comment's author deletes the comment, follow and favorite writes
touch only the caller's rows, and, over reachable states, unique users, emails
and slugs, unique follow and favorite pairs, and no tag, favorite or comment
left pointing at a deleted article. Every reply equals a specification
function of the state and the caller, and every write replies with what a read
would show afterwards; the feed holds only followed authors. For issue #16
(open), Lean shows that upstream's `favorited` query, which omits the article,
breaks that reply theorem on a two-article state, and that its `?favorited=`
filter has the same flaw. Effort: 888 kernel lines plus 170 for `apply`
against 1077 lines of upstream handlers, a 127-line spec, 1611 proof lines and
213 lines of scenarios and counterexamples (about 1.5 proof lines per upstream
handler line). See `examples/conduit/README.md`.


### crates.io (2026-09-27): done

`examples/cratesio/` models crate ownership, publishing, yanking, owner
invitations, API token scopes and crate deletion (at 067b45e), with a
PostgreSQL server. Lean proves that every write is allowed by a policy stated
over Full and Publish rights, that a token writes only within its endpoint
and crate scopes, that every crate keeps a user owner, that versions are
removed only with their crate, the deletion rules (age, owners, downloads,
reverse dependencies), and that the kernel never fails. For PR #14760, Lean
proves that after the fix a locked user commits nothing, and gives a locked
sign-in that succeeds before it. GitHub team membership, the clock and
download counts are input facts. Effort: 1026 kernel lines, a 142-line spec,
1516 proof lines (about 1.5 per kernel line), `lake build` 1:48. See
`examples/cratesio/README.md`.
