# atuin: what the kernel covers and where it differs

Upstream: atuinsh/atuin @ `df152cd4d68b4dbc2a6f13732b31b0e013470c70` (2026-11-05,
"fix(octavo): leave subagents out of a user's peak threads"), crate `crates/atuin-server`,
SQLite backend, release build. The checkout is at `/mnt/scratch/oss-sec/upstream/atuin`; link it as
`prove/results/upstream/atuin` (gitignored) for the difftest. It is linked outside this project
directory because `h5i app lint` scans every route under the project, and upstream's axum routes
are not h5i-app routes.

## Threat model

The sync server stores each user's end-to-end encrypted shell history records and hands out
session tokens. The server cannot read record contents (encryption is client-side), so what it
must get right is who may do what:

1. Authentication: only `Authorization: Token <session-token>` of an existing session
   authenticates; anything else writes nothing.
2. Account actions: registration only when `open_registration`, with a valid, unused name; login
   discloses a session token only after the password verifies; deleting the account and changing
   the password need the current password.
3. Tenant isolation: a user can read, write or delete only their own records; nothing a request
   does depends on other users' data; deleting an account removes all of its data (an earlier
   upstream bug left orphaned records behind, fixed by migration
   `db/sqlite/migrations/20260828000000_purge-orphaned-store.sql`).
4. Integrity: stored records are append-only per `(user, host, tag, idx)`; the record size
   limit holds for every stored record.

Out of scope (trusted): Argon2 hashing/verification, the randomness of session tokens, TLS,
JSON and HTTP parsing, the SQL engine itself, the client-side encryption.

## Covered

| Kernel (`kernel/src/lib.rs`) | Upstream (`crates/atuin-server/src/`) |
|---|---|
| `parse_authorization`, `header_is_ascii`, `first_space`, `is_token_scheme` | `router.rs` `UserAuth::from_request_parts` (header checks; `HeaderValue::to_str`, `split_once(' ')`, `typ != "Token"`) |
| `session_user`, `find_session_by_token`, `find_user_by_id`, `authenticate` | `db/mod.rs` `GET_SESSION_USER` join, `UserAuth` error mapping (400/403) |
| `valid_username`, `is_name_char` | `db/models.rs` `NewUsername::from_str` |
| `register`, `user_conflict`, `token_taken`, `eq_lower`, `ascii_lower` | `handlers/user.rs` `register`; `add_user_with_session`; the `users`/`sessions` UNIQUE constraints and `LOWER(...)` indexes of the SQLite migrations |
| `login`, `find_user_by_name`, `find_session_by_user`, `verify` | `handlers/user.rs` `login`; `GET_USER`, `GET_USER_SESSION`; `HashedPassword::verify` (as a table) |
| `get_user` | `handlers/user.rs` `get` |
| `delete_account`, `change_password`, `hash_taken_by_other` | `handlers/user.rs` `delete`, `change_password`; `UPDATE_USER_PASSWORD` (`UNIQUE(password)`) |
| `post_records`, `records_fit`, `record_writes`, `to_row` | `handlers/v0/record.rs` `post`; `ADD_RECORDS` |
| `status`, `bump`, `find_point` | `handlers/v0/record.rs` `index`; `STATUS`; `RecordStatus::from_points` |
| `next_records`, `in_series`, `signed_key`, `insert_sorted`, `insert_pos`, `extend_rows`, `take` | `handlers/v0/record.rs` `next`; `NEXT_RECORDS` |
| `authed` (`Me`, `DeleteStore`) | `handlers/v0/me.rs` `get`, `handlers/v0/store.rs` `delete`; `DELETE_STORE_BY_USER` |
| `transition` | `router.rs` route table and the order of extractors |
| `apply`, `apply_write` and the table helpers | the SQL each `Database` method runs, on SQLite (`delete_user`'s four deletes; `ON CONFLICT DO NOTHING`; AUTOINCREMENT) |
| `client_ip::resolve_client_ip` and helpers (extracted, not yet proved or difftested) | `client_ip.rs` `resolve_client_ip`, `TrustedProxies::contains` |

## How it is checked

`difftest/src/main.rs` starts the real upstream server (`atuin_server::launch_with_tcp_listener`,
the full router with every middleware) on 127.0.0.1 with a fresh SQLite file, and sends seeded
random requests over HTTP: all ten routes, with valid and malformed `Authorization` headers
(missing, empty, `Bearer`, lowercase `token`, double space, trailing junk, non-ASCII, tab),
case-variant and invalid usernames and emails, four passwords, record batches with sizes around
the limit and indexes `{0..5, 7, 2^63 - 1, 2^63, 2^64 - 1}`, `next` queries with counts
`{0, 1, 2, 3, 100, 2^63, 2^64 - 1}`, and legacy `history` rows inserted by SQL. Three scenarios:
open registration with a 64-byte limit, open and unlimited, closed with three users seeded by SQL.

After every request it compares the HTTP status and JSON body with the kernel's reply or error,
and every table (`users`, `sessions`, `history`, `store` in rowid order, and `sqlite_sequence`)
with the kernel's own state after `apply`. The kernel state is never re-read from the database.
Values the handler generates itself (the Argon2 hash of a new password, the new session token)
are read back from the database and given to the kernel as inputs; the `Crypto` table is filled by
the real `HashedPassword::verify` on every stored hash and the request's password.

Runs so far (all agree): seeds 1-5, 1,500 requests per scenario (22,500 requests), after the
`insert_sorted`/`bump` refactor seeds 1-3 again. `cargo run --release -- --seed N --steps M`.
This is evidence, not a proof of equivalence: the domain is the generator's.

## Not covered (trusted input)

- Argon2 (`HashedPassword::new`, `verify`): hashes are inputs, verification is the `Crypto`
  table; theorems hold for every table.
- Session token generation (`crypto_random_string::<24>`): an input. Its unguessability is assumed.
- JSON body and query decoding (a malformed body gets axum's 400/422 before the handler; not
  modelled), percent-decoding of the path, HTTP header whitespace trimming (the difftest trims
  optional whitespace before handing the header to the kernel, as hyper does).
- The register webhook (`send_register_hook`), metrics, tracing, the `semver`/`clacks` headers,
  capability negotiation (`negotiate_capabilities` passes requests without its headers).
- `ClientIp` (only logged by `login`); `client_ip.rs` is ported but not yet verified.
- `DbSettings::connect_url`, settings loading, the operator `admin user` commands.
- PostgreSQL and MySQL backends. Their collations and `LIMIT` semantics differ (see FINDINGS F2).

## Differences in form

| Where | Upstream | Kernel | Why |
|---|---|---|---|
| everywhere | `String`, `&str` | `Vec<u8>`, `&[u8]` | Aeneas has no strings; all comparisons upstream are bytewise (SQLite BINARY collation) |
| `UserAuth` | async extractor, DB query | `authenticate` over the snapshot | the kernel shape |
| `GET_SESSION_USER` | SQL join, `fetch_one` | first session with the token, then its user | equal while tokens are unique (`sessions.token UNIQUE`) |
| `GET_USER_SESSION` | `fetch_one` without `ORDER BY` | first session in rowid order | SQLite scans the table in rowid order; every user has one session |
| `NewUsername` | `chars().all(..)` | bytes | equivalent on UTF-8: non-ASCII chars have only bytes >= 0x80 |
| `LOWER(...)` indexes | SQLite `LOWER` | `ascii_lower` | SQLite without ICU folds only ASCII |
| record `idx`, `start`, `count` | `i64::conv` then SQL | `signed_key(x) = x ^ 2^63` order; `count > i64::MAX` = no limit | release-build `easy-cast` wraps; see FINDINGS F2, F3 |
| `next_records` | `ORDER BY idx` | stable insertion sort (`insert_sorted`) | keys are unique per series (`record_uniq`), so any sort agrees |
| `status` | `GROUP BY host, tag`, `HashMap` | list of points in first-seen order | the difftest compares as maps |
| `bump` | (none; SQL `MAX`) | find the series point, replace if greater, else append | |
| record `id` column | `uuid_v7()` per insert | not stored | never read by any route |
| `history` table | `id, client_id, user_id, hostname, timestamp, data, ...` | `id, user_id` | only the owner matters since v0 sync was removed |
| errors | `ErrorResponse { reason }` + status | one `Error` variant per reason | the difftest maps them back |
| counters | AUTOINCREMENT (`sqlite_sequence`) | `next_user_id`, `next_session_id` | `Overflow` at `u64::MAX` is a kernel addition (SQLite fails at `i64::MAX`), unreachable in practice |
| `apply` | the SQL statements | `apply_write` per write | the kernel shape |

The first `insert_sorted` and `bump` were single loops with a `placed`/`found` flag; they were
rewritten as a position search plus copies, and a find-then-replace, to make the proofs simpler.
The rewrite was re-run through the difftest (seeds 1-3, 13,500 requests). `valid_username`'s
first form bound a boolean named `ok` and later `good`, which Aeneas extracts as a `Prop`-valued
`let` that Lean cannot decide; it was rewritten with a helper `is_name_char`.
