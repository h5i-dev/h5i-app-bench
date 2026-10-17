# linkding (rust-h5i)

The [linkding](https://github.com/sissbruecker/linkding) 1.47.0 REST API as a
standard [h5i-app](https://github.com/h5i-dev/h5i) application. Every request
runs in the h5i-app engine (`h5i-app-pg`): the engine loads the rows the
kernel's read plan names, calls the kernel, and stores the writes the kernel
returns. The kernel, its read plans and its writes are proved in Lean. It
serves the same API as the other linkding implementations and passes the same
Hurl suite (`../tests`, 8 files, 189 requests).

`../rust-h5i-optimized` is the same API with a similar kernel and Lean proofs,
but with hand-written SQL through sqlx, which the proofs do not cover.

| Directory | Contents |
|---|---|
| `kernel/` | the kernel: `transition`, `apply`, the read plans (`reads`, `list_count`), `read_only`, the `schema!` tables; `search.rs` is the query language. Extracted to Lean by Charon and Aeneas |
| `kernel/tests/` | `paged_search.rs` (see [Paged listings](#paged-listings)) |
| `server/` | the HTTP API (axum) and the PostgreSQL store on `h5i-app-pg` |
| `proofs/` | the Lean specification and proofs; `generated/` is the extraction (do not edit) |
| `run.sh` | the benchmark's entry point |
| `h5i-app.toml` | what `h5i app` extracts and which theorems the gate requires |

## What runs where

**The kernel** (`kernel/src/lib.rs`) decides everything that depends on the
stored rows:

- who the caller is: the API token is the principal, and the kernel looks it
  up in the token table the plan loads (an empty token is a guest);
- ownership and visibility: a caller sees and changes only their own
  bookmarks, tags and bundles; the shared list shows shared bookmarks of
  users who share, and to guests only those of users who share publicly;
- bookmarks: the duplicate-URL rule (creating a bookmark of a saved URL
  updates it), tag creation with case-insensitive reuse of the caller's tags,
  archiving, deleting a bookmark with its tag links;
- tags and bundles, including a bundle's filters and the renumbering of the
  remaining bundles when one is deleted;
- listings: search (the query language and legacy search, both in the
  kernel), the unread, shared and date filters, bundles, sorting, paging, and
  the count when the listing reads its whole scope;
- the id counters for bookmarks, tags and bundles;
- the read plans (`reads`, `list_count`) and which commands are read-only.

**The shell** (`server/src/api.rs`, `logic.rs`) decodes requests and renders
linkding's JSON. Besides that it validates request bodies (Django REST
framework's field errors), normalizes URLs, splits tag strings, parses dates,
reads the clock, builds the `next` / `previous` links, and counts a paged
listing or the tag list with the read the kernel names (`list_count`), in the
listing's own transaction. It reads nothing else from the database.

**The engine** (`h5i-app-pg`) runs each command in a SERIALIZABLE
transaction (read-only commands in a `READ ONLY DEFERRABLE` one), loads the
plan's rows (`LinkdingStore::load_for`), calls the kernel, writes the write
set and retries on serialization failures. Writes take per-key advisory locks
on what they change (`lock_for`: a bookmark, a tag, a caller's bundles, the
id counters); these only reduce retries.

## Read plans

Every command has a plan: one declarative read per table it needs. Each plan
reads the caller's token row and user row. Besides those:

| Command | Reads |
|---|---|
| profile | nothing else |
| get, delete, archive a bookmark; get, delete a tag | the row with that id (get a bookmark: also its links and their tags) |
| check a URL, create a bookmark | the caller's bookmarks of that URL (normalized, or the raw URL for rows stored without one), with their links and tags (check), or the caller's tags with the request's names and the counters (create) |
| update a bookmark | the bookmark, the caller's bookmarks with the new URL, its links, its tags and the caller's tags with the request's names, the counters |
| tag list | the first `offset + limit` of the caller's tags by id |
| create a tag | the caller's tag with that name (any case), the counters |
| bundles | the caller's bundles (and the counters to create one) |
| paged listing | the newest `offset + limit` bookmarks its query selects, with their links and tags |
| any other listing | the caller's bookmarks of the scope (or every shared bookmark of a user who shares), their links and tags, and the bundle `?bundle=` names |

A bookmark's key is `(owner, added, id)`, so one owner's bookmarks load
newest first by key and a paged listing reads only its page.

### Paged listings

A listing is paged (`paged`) when it is the caller's own or archived list in
the default order, with no date filter and no bundle, and its query consists
only of `#tag` and `!unread` words (`simple_query`), which both search modes
read the same way. Its read selects, in SQL, the bookmarks with every tag
(any case of the name, through the tag's lowercased name) and, for
`!unread`, unread ones, together with the unread and shared filters; its
count is the same read without the page (`list_count`).

On a paged listing the kernel selects with that rule (`simple_selected`),
not with the search code, so that what it computes is what the read loads.
`kernel/tests/paged_search.rs` checks, on 600 generated states and queries in
both search modes and with lax search, that the same listing in ascending
order (which reads the whole scope and runs the search code) returns the same
bookmarks. That agreement is tested, not proved.

## What is proved

The specification is `proofs/Spec.lean`. Unless noted, each theorem holds
for every caller, state and command of the extracted code.

| Theorem | Statement |
|---|---|
| `Storage.stored` | The store holds what `apply` computes: every database the server produces from an empty site reads back the rows of the state `Spec.applyAll` gives for its commits, and loading it decodes to that state, up to row order. |
| `ReadOnly.read_only_sound` | Every command `read_only` lists writes nothing when accepted, so the engine may run it on a read-only snapshot. |
| `Theorems.guest_writes_nothing` | Without a token, no accepted command writes. |
| `Theorems.unknown_token_refused` | A token that no user holds is refused for every command. |
| `Owner.writes_own` | Every write of an accepted command is the caller's (`OwnWrite`): it creates or changes a bookmark, tag or bundle owned by the user the token names, deletes such a row of the state, links one of the caller's bookmarks written in the same write set to one of the caller's tags (existing or written in the same write set), or sets the counters. |
| `Owner.get_bookmark_owned`, `get_tag_owned`, `get_bundle_owned` | A lookup by id replies only with a row of the caller's. |
| `Plan.reads_abs`, `Plan.count_abs` | The extracted `reads` and `list_count` compute the plans `readsA` and `countA` written as `H5iAppLib.Query` reads. |
| `Frame.frame`, `Frame.load_for_sound` | For every command, `transition` on the rows its plan loads gives exactly its result on the whole site, assuming what the tables' primary keys guarantee (`Keys`: token keys, user ids and bundle ids are unique) and that no user has id 0 (user ids start at 1; 0 is the guest). |
| `Frame.count_tags`, `Frame.count_paged` | The tag list's count read counts the caller's tags, which `list_tags` pages through; a paged listing's count read counts exactly the bookmarks the listing selects and pages through. |

All of them depend only on Lean's standard axioms (`propext`,
`Classical.choice` and `Quot.sound`), and the gate (`h5i app check .`)
rejects `sorry`.

## What is trusted

- **The database's reads.** PostgreSQL returns, for each compiled read, the
  rows `H5iAppLib.Query` says, in key order (differential-tested in h5i; see
  its [TRUST.md](https://github.com/h5i-dev/h5i/blob/main/docs/app/TRUST.md)).
  Listings in the default order rely on key order.
- **The keys.** The frame theorem assumes unique token keys, user ids and
  bundle ids, which the tables' primary keys enforce, and no user with id 0.
- **The shell**: decoding, validation, URL normalization, date parsing,
  paging links, and rendering the replies.
- **The engine and PostgreSQL** run the transactions as `h5i-app-pg`
  documents; users and tokens are not written by the kernel (the benchmark
  copies them in, see below).
- **Paged listings** select by their tags and `!unread` (see above); that
  this matches the search code is tested.

## Differences from linkding

- Tag names and search terms are compared after lowercasing ASCII letters
  only; linkding folds Unicode case.
- A bookmark's key is `(owner, added, id)`. Changing a bookmark's date added
  deletes the row and writes it under the new key, with the same id. The
  default order is date added, newest first, then id.
- Ids come from counters the kernel keeps, not from database sequences.
- Text search, the other sort orders, date filters, `!untagged`, `not` and
  `or`, bundles and the shared list read the whole scope (the caller's
  bookmarks of the list, or all shared bookmarks of users who share) and
  filter in the kernel. Their cost grows with the scope; linkding and
  `rust-h5i-optimized` filter in SQL.

## Building, testing and proving

All commands run from this directory, its own Cargo workspace.

```
cargo build --release
cargo test -p linkding-kernel        # the schema check and paged_search.rs

h5i app extract --check .   # the committed Lean is what Aeneas extracts now
h5i app check .             # build the proofs, gate the theorems in h5i-app.toml
```

The h5i crates come from git (`kernel/Cargo.toml`, `server/Cargo.toml`) and
the Lean library `H5iAppLib` from the same repository
(`proofs/lakefile.lean`), both on h5i's `main`; `Cargo.lock` and
`proofs/lake-manifest.json` pin the same commit. The first `check` fetches
Mathlib and Aeneas's Lean library (several GB; `H5I_LAKE_CACHE` names where
they are kept).

## Running the server

```
export DATABASE_URL=postgres://linkding:linkding@127.0.0.1:5440/linkding
./run.sh        # 127.0.0.1:8106
```

The tables live in the schema `h5iapp` of that database; the server creates
them at start. `bench/seed_h5i_app.sql` copies the shared schema's users,
profiles, tokens, bookmarks, tags, links and bundles into them. `PORT`,
`DB_POOL` (default 32) and `WEB_CONCURRENCY` (Tokio worker threads, default
4) configure it, and `GET /healthz` answers `ok`.

```
../scripts/test-all.sh rust-h5i      # the Hurl suite (resets the database)
```

## In the benchmark

`run.sh` builds into `/var/tmp/ld-target-h5i-app` (`H5I_APP_TARGET_DIR`) and
serves on 127.0.0.1:8106. Each benchmark point seeds the shared tables with
`../bench/seed.sql` and copies them in with `../bench/seed_h5i_app.sql`.
`../scripts/bench-parallel.sh rust-h5i` runs it on rust-h5i-optimized's CPUs
with its own database container (`linkding-pg-rust-h5i`, port 5445).

## Performance

Requests per second at 64 clients, from `../bench/results/summary.md` (means
of 3 runs; server, database and k6 on 4 cores each):

| Scenario | rust-h5i | rust-h5i-optimized |
|---|---:|---:|
| list | 112 | 294 |
| search (`q=alpha`) | 6.9 | 19.8 |
| search_tag (`#tagN`) | 2324 | 1993 |
| get | 12833 | 3357 |
| create | 34 | 1552 |
| update | 3032 | 2013 |
| archive | 5123 | 2553 |
| tags | 5319 | 4346 |
| mixed | 32 | 83 |

Lookups by id, edits and the tag list load a few rows and are faster than
the hand-written SQL. Text search reads all of alice's 100,000 bookmarks and
filters in the kernel. Every create takes ids from the one counter row and
locks it (`lock_for`), so creates run one at a time; the server's CPU stays
under 10% in that scenario. A plain `list` at a rotating offset reads
`offset + limit` rows newest first. The engine's
peak memory is about 1.9 GB (2.7 GB during text search), against 24 MB for
`rust-h5i-optimized`.

## License

Apache-2.0, as h5i. The upstream application is
[sissbruecker/linkding](https://github.com/sissbruecker/linkding).
