# Conduit (rust-h5i-app)

The [RealWorld](https://github.com/gothinkster/realworld) "Conduit" backend
on [h5i-app](https://github.com/h5i-dev/h5i): a port of
[launchbadge/realworld-axum-sqlx](https://github.com/launchbadge/realworld-axum-sqlx)
(commit f1b2565) to an h5i-app kernel, served with the RealWorld JSON API on
PostgreSQL, with properties of the extracted code proven in Lean. Conduit is
a Medium clone: users follow each other, write articles with tags, favorite
them and comment on them, and read a feed of the authors they follow.

This directory is Conduit's home and the RealWorld benchmark's fifth server,
`rust-h5i-app` (the h5i-app counterpart of `../rust-h5i`). It used to be the
`conduit` entry of the h5i-app cookbook and, before that,
`examples/app/conduit` in h5i.

| Directory | Contents |
|---|---|
| `kernel/` | the verified kernel: `transition`, `apply`, the read plans (`reads`), `read_only`, the `schema!` declaration. Extracted to Lean by Charon and Aeneas |
| `server/` | the RealWorld HTTP API (axum) and the PostgreSQL store on `h5i-app-pg`; `tests/postgres.rs`, `examples/load.rs` |
| `proofs/` | the Lean specification and proofs; `generated/` is the extraction (do not edit) |
| `run.sh` | the benchmark's entry point (see [In the benchmark](#in-the-benchmark)) |
| `h5i-app.toml` | what `h5i app` extracts, which theorems the gate requires, and a mutant the proofs must reject |

## The model

The kernel covers every route of the upstream server: registration, login,
the current user and its update, profiles with follow and unfollow, the
article listing with its tag, author and `favorited` filters, the feed, and
creating, editing, deleting, favoriting and commenting on articles. Upstream
keeps several of its rules inside SQL. `delete_article` and `delete_comment`
check the author in the `WHERE` clause of a CTE, a check constraint forbids
following oneself, unique constraints keep usernames, emails and slugs
distinct, and `on delete cascade` removes the favorites and comments of a
deleted article. In the kernel these are ordinary conditions and writes: the
delete command writes `DelTagsOf`, `DelFavoritesOf` and `DelCommentsOf`
before `DelArticle`, so the invariants below check that nothing is left
pointing at a deleted article. As upstream, only a comment's author may
delete it, not the author of the article.

The HTTP API follows the [RealWorld spec](https://github.com/realworld-apps/realworld)
and passes its Hurl suite (`spec/api/hurl` at `ebbcdeb`, as pinned by this
benchmark; `../scripts/test-all.sh rust-h5i-app`):
`201` for sign-up, new articles and comments, `204` for deletes, `409` for
a taken username or email, errors as `{"errors": {"<field>": ["..."]}}`
(`token` "is missing" or "is invalid", `credentials` "invalid", `<thing>`
"not found" or "forbidden", "can't be blank"), `articlesCount` the number of
matching articles before paging, listings without `body`, an empty bio or
image as `null`, and an article's tags replaced by `tagList` on edit.

A few things stay in the shell (`server/src/api.rs`):

- **Request validation**, with the decoding: required fields present and
  not blank, passwords of at least 8 characters (NIST 800-63B, as the
  suite asks), `limit` in 1..=100 and `offset` ≥ 0, `tagList` a list of
  strings (blanks dropped, each once, sorted).
- **Passwords**: bcrypt with cost 12. At sign-up and on a password change
  the shell sends the kernel a fresh hash. At login it reads the stored hash
  through the engine with the login's own read plan
  (`Engine::snapshot_for`), checks the password against it (against a dummy
  hash if the email is unknown, so both take as long), and sends the kernel
  the stored hash only if it matched; the kernel accepts a login only when
  the hash it is sent equals the one it stores, so it still decides.
- **Tokens**: HS256 JWTs whose `sub` is the user id, valid 60 days
  (`JWT_SECRET`). A request without a token is anonymous (user 0), and the
  kernel refuses it wherever an account is needed.
- **Slugs**: ASCII letters and digits lowercased, runs of spaces, `-` and
  `_` as one hyphen. While the kernel answers `SlugTaken`, the shell tries
  `-1`, `-2`, ...; duplicate titles therefore get distinct slugs.
- **Time**: the clock, in milliseconds.
- **`articlesCount`**: `ConduitStore::load_for` counts the read the kernel
  names (`article_count`) in the listing's own read-only transaction;
  `Frame.count_list` and `Frame.count_feed` prove it counts exactly the
  articles the listing or the feed pages.

Tags are a table keyed by article and tag, where upstream uses an array
column, and ids are numbers handed out by counters. Usernames and emails are
compared byte for byte (as the benchmark's shared schema's unique
constraints do), while upstream compares them without case. Listings are
newest first by id, which is creation order: `createdAt` descending, then
id descending, as the benchmark asks, as long as the server's clock does not
go back. Upstream's feed query does not order its result although the
RealWorld spec asks for it. `limit` and `offset` pick a page of
that order.

## Issue #16

[Issue #16](https://github.com/launchbadge/realworld-axum-sqlx/issues/16)
reports that favoriting one article makes every article show
`"favorited": true`. Every query that renders an article computes the flag
with `exists(select 1 from article_favorite where user_id = $1)`, which asks
whether the caller has favorited any article at all; the condition on
`article_id` is missing. The `?favorited=<name>` filter of the listing has
the same mistake: it keeps every article as soon as that user has favorited
one. The kernel therefore has two variants. `transition` computes both per
article, and `transition_upstream` computes them as upstream's SQL does.

For the fixed kernel, Lean proves that a reply's `favorited`,
`favoritesCount` and `following` fields are what the specification says for
the caller, and that a write replies with what a read would show right after
it. For upstream, it evaluates a state in which Bob has favorited article
"a": Bob sees "b" as favorited, which contradicts the statement proven for
the fixed kernel, and `?favorited=bob` lists both articles.

## Theorems

The specification is `proofs/Spec.lean`. Theorems about reachable states
hold in every state that successful commands can produce from an empty site;
the others hold for every caller, state and command.

| Theorem | Statement |
|---|---|
| `transition_total`, `transition_upstream_total` | The kernel never fails, in either variant. |
| `authorized` | Every write of a successful command is allowed by `Spec.allowed`, judged against the state before it. |
| `only_author_edits` | In a reachable state, only an article's author changes it, and the author stays the same. |
| `only_author_deletes` | In a reachable state, only an article's author deletes it or its tags, favorites and comments. |
| `only_comment_author_deletes` | In a reachable state, only a comment's author deletes it. |
| `own_rows` | Follow and favorite writes touch only the caller's own rows. |
| `anonymous_only_signs_up` | In a reachable state, a caller without an account can only sign up. |
| `inv_preserved`, `reachable_inv` | In every reachable state, user ids, usernames, emails and slugs are unique, follows and favorites are unique pairs, nobody follows themselves, ids are below their counters, and every follow, article, tag, favorite and comment points at an existing user and article. |
| `delete_cascades` | After an article is deleted, no tag, favorite or comment points at it. |
| `get_article_reply`, `list_reply`, `feed_reply`, `get_comments_reply`, `get_profile_reply`, `login_reply` | A read replies with exactly the specification's `view`, `listing`, `feedOf`, `commentsOf`, `profileOf` or account for the state and the caller. |
| `feed_only_followed` | The feed contains only articles by authors the caller follows. |
| `favorite_reply`, `unfavorite_reply`, `create_reply`, `update_reply`, `follow_reply`, `unfollow_reply`, `add_comment_reply` | A write replies with what the same read returns in the state after the write (for `unfavorite_reply` and `create_reply`, in a reachable state). |
| `apply_spec` | The kernel's `apply` computes `Spec.applyAll`. |
| `read_only_sound` | Every command `read_only` lists writes nothing when accepted (`H5iAppLib.ReadOnly.Sound`), so the engine may run it on a read-only snapshot. |
| `reads_abs`, `decode_load` | The extracted read plan `reads` is the plan `readsA` written in `H5iAppLib.Query` terms, and rows holding what each of its reads returns decode to `loadSnap plan s`. |
| `frame`, `load_for_sound`, `load_for_sound_inv` | For every command (each has a plan), `transition` on what the plan loads gives exactly its result on the whole site (with unique usernames, true in every reachable state). |
| `count_abs`, `count_list`, `count_list_unknown`, `count_feed` | The extracted `article_count` is `countA`, whose rows are exactly the articles the listing or the feed selects before paging (none if a user filter names nobody). |
| `upstream_violates_reply_spec` | With upstream's query, the statement of `get_article_reply` is false. |
| `favorited_filter` | `?favorited=bob` lists one article in the fixed kernel and two in upstream's. |
| `s1_reachable` | Six commands lead from an empty site to the scenario state, so the theorems about reachable states apply to it. |
| `author_edits`, `other_cannot_edit`, `author_deletes`, `article_author_cannot_delete_comment`, `bob_favorites_b`, ... | In the scenario state, the permitted user can act and the others are refused. |

All of them depend only on Lean's standard axioms (`propext`,
`Classical.choice` and `Quot.sound`). `apply_spec` assumes that no table
reaches `usize::MAX` rows. The theorems describe the kernel; the server
around it is trusted to decode requests, and `server/tests/postgres.rs`
checks that the PostgreSQL store agrees with `apply` on random command
sequences. The listing's order relies on the store loading rows in key
order, which is id order.

## Loading less than the site

Conduit has one tenant, so loading the whole site for every request costs
as much as the site is big. `reads` (in the kernel, extracted) gives most
commands a read plan: one declarative read (`h5i_app_sql::Read`) per table.
Getting, favoriting and unfavoriting an article read the article by slug,
its tags and favorites, its author and the caller's follows; profiles,
follows, account commands and comments read the rows their keys name; the
listing and the feed read only the newest `offset + limit` matching articles
(the filters by tag, author name and favoriting user are `IN` sub-reads)
and what their views need. Sign-up reads the users with that name or email
and the counters; login the user with that email; a new article the caller,
the caller's follows, the article with its slug and the counters; an edit
also the article's tags and favorites (and the article with the new slug);
a delete the caller and the article; the tag list the tags table.
`ConduitStore::load_for` runs the plan (`schema_load_plan`), and `ddl` adds
indexes for the reads.

`Frame.lean` proves the plans load enough: on what a plan loads,
`transition` returns what it returns on the whole site. What stays trusted
is that PostgreSQL returns, for each compiled read, the rows
`H5iAppLib.Query` says (differential-tested; see h5i's [TRUST.md](https://github.com/h5i-dev/h5i/blob/main/docs/app/TRUST.md)). The
random-command test in `server/tests/postgres.rs` runs the real engine,
partial loads included, against `MemoryEngine`.

Writes lock only what they change (`lock_for`): a slug (and the slug an
edit moves to), a follow pair, a user or the id counter.

## Requirements

- Rust (stable, edition 2024) and a PostgreSQL 14+ server for the tests and
  the server.
- For the proofs: the `h5i` CLI (or `cargo app` from an h5i checkout),
  [elan](https://github.com/leanprover/elan) (the toolchain is in
  `proofs/lean-toolchain`), and for `h5i app extract`, Charon and Aeneas at
  the pins h5i expects (`h5i app doctor .` checks all of them).

The h5i crates come from git (`kernel/Cargo.toml`, `server/Cargo.toml`) and
the Lean library `H5iAppLib` from the same repository (`proofs/lakefile.lean`,
`require h5i_app_lib from git ... / "crates/h5i-app-core/proofs"`), both on
h5i's `main`. `Cargo.lock` and `proofs/lake-manifest.json` pin the same
commit; to move both, run `cargo update` for the `h5i-app-*` crates and
`lake update h5i_app_lib` in `proofs/`, then `h5i app extract --check .` and
`h5i app check .`.

All commands below run from this directory, which is its own Cargo workspace
(outside the workspace of `../rust-h5i`).

## Building and testing

```
cargo build --release
H5I_APP_TEST_DATABASE_URL=postgres://h5i:h5i@127.0.0.1:5432/h5i cargo test --release
```

`server/tests/postgres.rs` runs 1,500 random commands from several users
through the real engine on PostgreSQL (read plans, per-key locks and
read-only transactions included) and through `MemoryEngine`, and checks
that every reply and the final state agree. It uses the schema `conduit` of
the given database. Without `H5I_APP_TEST_DATABASE_URL` it skips.

## Proving

```
h5i app extract --check .   # the committed Lean is what Aeneas extracts now
h5i app check .             # build the proofs, gate the theorems in h5i-app.toml
h5i app prove .             # extract, then check
h5i app mutate .            # the bug in h5i-app.toml must break a proof
```

The first `check` fetches Mathlib and Aeneas's Lean library (several GB;
`H5I_LAKE_CACHE` names where they are kept, shared between projects with the
same pins). The gate requires every theorem listed in `h5i-app.toml` and
every theorem of the hand-written modules to exist, to use only `propext`,
`Classical.choice` and `Quot.sound`, and to contain no `sorry`.

## Running the server

```
export DATABASE_URL=postgres://h5i:h5i@127.0.0.1:5432/h5i JWT_SECRET=dev-secret
cargo run --release -p conduit-server &

curl -s -H 'content-type: application/json' localhost:8080/api/users \
  -d '{"user":{"username":"alice","email":"alice@example.com","password":"password123"}}'
```

The reply carries a token for `Authorization: Token <token>`; the other
routes are those of the RealWorld spec. The tables live in the schema
`conduit` of that database. `PORT` (default 8080) or `LISTEN` set the
address, `DB_POOL` the connections (default 32), `WEB_CONCURRENCY` the
worker threads, and `GET /healthz` answers `ok`.

To run the RealWorld Hurl suite against it, use `../scripts/test-one.sh`
with `HOST=http://127.0.0.1:8080`, or `../scripts/test-all.sh rust-h5i-app`,
which starts it through `run.sh`.

## In the benchmark

`run.sh` builds into `/var/tmp/rw-target-h5i-app` (`H5I_APP_TARGET_DIR`)
and serves on 127.0.0.1:8005 with the same environment as the other servers
(`DATABASE_URL`, `JWT_SECRET`, `DB_POOL`, `WEB_CONCURRENCY`). The server
creates its tables in the schema `conduit` of the database at start; the
benchmark seeds them from the shared dataset with `../bench/seed_h5i_app.sql`
(see `../bench/README.md`). `../scripts/bench-parallel.sh rust-h5i-app`
runs it on rust-h5i's CPUs with its own database container.

## Load test

`server/examples/load.rs` seeds a RealWorld-sized site with plain SQL (50
users, 10,000 articles, 20,000 tag rows over 100 tag names, 5,000 favorites,
500 follows; it truncates Conduit's tables first, so point it at a scratch
database), serves the API in-process on a pool of 32 connections
(`POOL_SIZE`), and drives it over HTTP/1.1 keep-alive connections. It prints
one row per scenario and concurrency, with the engine's attempts, retries
and commits during the row (`EngineStats`).

```
DATABASE_URL=postgres://... cargo run --release -p conduit-server --example load -- \
  10 get-article,list,list-tag,feed,favorite 1,16,64   # seconds per row, scenarios, concurrencies
```

| Scenario | Request (random user token) |
|---|---|
| get-article | `GET /api/articles/article-<random>` |
| list | `GET /api/articles?limit=20&offset=0` |
| list-tag | `GET /api/articles?tag=tag<random>&limit=20` |
| feed | `GET /api/articles/feed?limit=20&offset=0` |
| favorite | `POST /api/articles/article-<random>/favorite` (favorites reset first) |

## Performance

Conduit is the benchmark for h5i-app's read path: all its users share one
tenant, the worst case for an engine that serializes per tenant. Requests
per second at concurrency 64, PostgreSQL 16 in Docker on the same host,
server, client and database on 64 shared cores (differences under ~20% are
noise). Method, every row and the discussion are in h5i's
[docs/app/PERFORMANCE.md](https://github.com/h5i-dev/h5i/blob/main/docs/app/PERFORMANCE.md).
These come from `examples/load.rs`, not from the RealWorld benchmark
(`../bench`).

| Engine | get-article | list | list-tag | feed | favorite | favorite retries / attempts |
|---|---:|---:|---:|---:|---:|---:|
| baseline: tenant lock, whole-site load | 13.0 | 12.4 | 5.1 | 13.0 | 12.5 | 0 / 188 |
| 1. read-only commands (`Kernel::read_only`) | 122.2 | 124.2 | 65.9 | 120.2 | 11.3 | 0 / 175 |
| 2. per-key advisory locks (`Store::lock_for`) | 113.1 | 108.7 | 72.0 | 108.6 | 7.6 | 1366 / 1448 |
| 3+5. declarative reads and read plans (`reads`, `Store::load_for`) | 1991.4 | 1557.1 | 1519.1 | 1573.4 | 991.2 | 320 / 10327 |
| same code, quieter host | 3831.4 | 3862.9 | 3894.2 | 3063.6 | 2440.1 | 533 / 25000 |
| 6. prepared statements, pipelined plan loads | 15246.7 | 8027.6 | 7519.7 | 5474.5 | 4371.1 | 624 / 44404 |
| 7. bounded statement cache (current) | 14657.0 | 8203.0 | 8071.1 | 5941.7 | 4705.9 | 641 / 47764 |

The current engine, all rows:

| scenario | conc | req/s | p50 ms | p99 ms | non-2xx | attempts | retries | commits |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| get-article | 1 | 709.5 | 1.41 | 1.72 | 0 | 7097 | 0 | 7097 |
| get-article | 16 | 7007.7 | 2.24 | 3.20 | 0 | 70112 | 0 | 70112 |
| get-article | 64 | 14657.0 | 4.31 | 5.50 | 0 | 146725 | 0 | 146725 |
| list | 1 | 221.2 | 4.50 | 5.85 | 0 | 2213 | 0 | 2213 |
| list | 16 | 3755.2 | 4.23 | 5.85 | 0 | 37573 | 0 | 37573 |
| list | 64 | 8203.0 | 7.73 | 10.18 | 0 | 82097 | 0 | 82097 |
| list-tag | 1 | 294.2 | 3.26 | 5.90 | 0 | 2943 | 0 | 2943 |
| list-tag | 16 | 3718.8 | 4.26 | 5.99 | 0 | 37203 | 0 | 37203 |
| list-tag | 64 | 8071.1 | 7.86 | 10.31 | 0 | 80802 | 0 | 80802 |
| feed | 1 | 201.6 | 5.00 | 6.68 | 0 | 2017 | 0 | 2017 |
| feed | 16 | 2704.6 | 5.90 | 8.27 | 0 | 27061 | 0 | 27061 |
| feed | 64 | 5941.7 | 10.61 | 14.79 | 0 | 59486 | 0 | 59486 |
| favorite | 1 | 232.0 | 4.22 | 7.58 | 0 | 2321 | 0 | 2321 |
| favorite | 16 | 2522.2 | 6.16 | 12.98 | 0 | 25604 | 367 | 25237 |
| favorite | 64 | 4705.9 | 13.27 | 26.90 | 0 | 47764 | 641 | 47123 |

A single get-article takes 1.4 ms instead of ~80 ms in the baseline. At
concurrency 1 single runs of the listings spread by 10-20%; six interleaved
runs per build put steps 6 and 7 within one standard deviation of each
other.

These numbers predate the RealWorld conformance changes above (JWTs,
bcrypt, `articlesCount`, read plans for every command). Since then every
command has a read plan; a listing also counts its articles, one more
statement sent with the plan's. Favorites retry about 1.5-2% of the time
under PostgreSQL's page-level SERIALIZABLE predicate locks.

## License

Apache-2.0, as h5i. The upstream application is
[launchbadge/realworld-axum-sqlx](https://github.com/launchbadge/realworld-axum-sqlx).
