# What i5h proves, and what it assumes

## Proven in Lean (about the extracted kernel)

The kernel's `transition` and `apply` are translated from Rust to Lean by
Charon and Aeneas. For the example app, the spec is
`examples/docs/proofs/Spec.lean` and the theorems are in `Theorems.lean` next to it.

## Enforced by structure (no proof needed)

| Property | How |
|---|---|
| Handlers go through the kernel | App code gets `I5h::respond` / `Engine::execute`, never a DB handle. `cargo deny check bans` (`deny.toml`) rejects database crates in any workspace crate but `i5h-pg`. `i5h_pg::lockdown` makes a NOLOGIN role own the i5h tables and grants row access only to the engine's role (see Deployment below). |
| Tenant isolation | Generated table operations require a tenant and include it in every query and primary key. Kernel rows carry no tenant id, so the kernel cannot name another tenant. The engine and each trusted `Store` implementation must pass `K::tenant(actor)` consistently. |
| Every column is persisted | `table!` must list every field or it does not compile. |

## Assumed (trusted, not verified)

| Component | Assumption | Mitigation |
|---|---|---|
| `Authenticator` | Returns the principal that sent the request. | Token parsing is extracted and proven: an accepted token's signed payload is exactly `enc(tenant, user, exp)`, so a signature covers one identity. HMAC-SHA256 from libcrux 0.0.8 (HACL*-verified, pre-1.0). Still trusted: the secret key and its storage, the clock for expiry, constant-time tag comparison (`ct_eq`). |
| JSON codec | Decodes the body into the command the client meant. | `deny_unknown_fields`; tagged enum. |
| Shell inputs | Values the shell puts in the principal are true: random slugs (Wastebin), GitHub team membership and download counts (crates.io), password checks (Atuin, Wastebin, Conduit), and the time in Conduit's commands. | Theorems hold for every value, so a wrong input cannot break an invariant or a permission rule; it can only make the kernel decide on wrong facts. Each app's README lists its inputs. |
| Clock | The engine's `Clock` reads the right time: the process's system clock (`Clock::System`, the default) or PostgreSQL's `transaction_timestamp()` (`Clock::Database`, used by booking, Wastebin and crates.io). Token expiry in `HmacAuth` uses the system clock. | Theorems hold for every time, so a wrong clock can only make the kernel decide on a wrong time, for example accept a booking that has already started. `Clock::Database` gives every server of a database one clock. With `monotonic`, the trusted engine contract says that the `i5h_clock` row prevents committed times from decreasing within a tenant. Proofs over `I5hLib.ReachableT` apply to database executions only under that assumption. |
| Reply rendering | Shows the reply the kernel returned. | Bytes come from the extracted `i5h-json` writer, proven to print the token stream exactly and to escape strings so their contents cannot inject JSON. Trusted: the app's reply-to-`Value` mapping, and the `Value` to tokens flattening (tested against serde_json). |
| `i5h-pg` table mapping (A4) | The SQL template in `table.rs::run_stmt` does what `I5hLib.Sql.exec` says: `INSERT ... ON CONFLICT (pk) DO UPDATE` stores `key ++ rest` at `key`, and keyed `DELETE` removes it. Tenant-filtered `SELECT`s return each row once (`Lists`); null-safe `SELECT ... WHERE column IS NOT DISTINCT FROM value` returns each match once (`Sel`), including the select used before cascade deletes. `Value`/`Val` conversion is lossless. The SQL renderer and `schema!` generator remain trusted. | `schema!` generates extracted table operations, `apply`, `sql_writes`, and `decode` and Lean specs for them. It also emits each encoded column index into Rust and Lean; production filtered loads and `ColIs` proofs use those generated definitions instead of separately maintained column names and numbers. `I5hLib.Store` proves for any schema that planned statements leave exactly the encoded rows of `applyAll` and that loading them in any order decodes that state up to row order. The eight server apps outside docs instantiate this theorem in `Storage.lean`; docs retains its specialized `Load.fresh`/`load_sound`/`store_sound` and `Scoped.served_inv` proofs across full and scoped load paths. `i5h_sql::plan` is proved separately. Kellnr and Atuin have no server. |
| PostgreSQL | SERIALIZABLE commits are equivalent to some serial order. | Documented PostgreSQL guarantee. Retries restart from the snapshot read. |
| Engine protocol | The Rust engine satisfies the contract listed below. | The implementation is kept in `crates/i5h-pg`, application code cannot obtain its pool or raw transaction, and PostgreSQL integration tests cover concurrency, retries, idempotency, connection loss, scoped reads and outbox behavior. This component is trusted, not proven in Lean. |
| Deployment | The engine does not log in as a superuser, and no other service gets its credentials. | Superusers bypass table grants; nothing in i5h can stop that. |
| Charon / Aeneas / Lean | The translation is faithful and the checker is sound. | Upstream tools. |
| axum, hyper, tokio | Deliver requests and responses intact. | Widely used. |

## Deployment

1. As an admin, create the engine's login role: `CREATE ROLE app_engine LOGIN PASSWORD '...'`. Not a superuser, not the table owner.
2. As the admin, run `Engine::install_schema`, then `i5h_pg::lockdown::<App, Store>(admin_url, "i5h_owner", "app_engine")`. It is idempotent; rerun after adding tables. If the app has its own schema (`i5h_pg::with_schema`), use it in both URLs.
3. Run the server with `DATABASE_URL` for `app_engine`. Other roles get `permission denied` on i5h tables (`tests/lockdown.rs`).

`Store` impls get an opaque `i5h_pg::Tx` that offers only `load`, `upsert` and `delete`, and `i5h_pg::Pool` is opaque too, so app code has no path to the driver; `cargo deny check bans` rejects the driver in any non-dev dependency. The role lockdown still backs this at runtime, and a superuser login bypasses both.

## Connection loss

A connection lost before COMMIT is retried from BEGIN. A connection lost during
COMMIT may or may not have committed: under an idempotency key the engine
retries (the key makes it safe); without one it returns `DbError::CommitUnknown`
and the caller must not assume either outcome.

## Trusted engine contract

The application proofs rely on the following contract of `i5h-pg`:

- one attempt loads one tenant, calls `transition`, writes its result and commits in one SERIALIZABLE transaction;
- every retry starts a new transaction, reloads the snapshot, reads a new attempt time and reruns `transition`;
- a refused transition rolls back and writes neither application rows nor framework rows;
- application writes, the idempotency reply, `i5h_clock` and outbox rows are atomic because they use the same transaction;
- a key is stored per `(tenant, ReplyCodec::scope(actor), key)`, and reuse with a different fingerprint is rejected;
- a lost connection before COMMIT aborts or is retried, while an uncertain unkeyed COMMIT returns `CommitUnknown`;
- session advisory locks are acquired before BEGIN and released before a connection returns to the pool; and
- outbox deliveries may repeat, keep a stable delivery key, and are sent only through the configured destination registry.

The `ReplyCodec` fingerprint and scope, clock source, destination registry,
connection-pool cancellation behavior, and the code implementing this contract
are part of the trusted computing base.

## Consequence

If the PostgreSQL, SQL mapping, Store and engine assumptions hold, every normal
committed application state of a tenant is represented by a serial sequence of
successful kernel transitions. Therefore an invariant proven to be preserved
by `transition` + `apply` can be transferred to the database once the
application's storage theorem connects those writes and loaded rows. Migrations
need their own invariant check and do not establish kernel reachability. With
`monotonic`, properties over `I5hLib.ReachableT` additionally rely on the
trusted clock contract above.

## Not covered yet

- Scoped reads: `Scoped.scoped_sound` proves `DocsStore::load_for` decodes to
  `Frame.slice` of a state the rows hold, given `Scoped.Sel` for each query.
  Rust and Lean use the column indices generated by `schema!`; the remaining
  assumption is that PostgreSQL executes the rendered null-safe filtered
  `SELECT` as `Scoped.Sel` states. `tests/postgres.rs` compares the scoped load
  with the Lean slice. `transition_frame` proves the kernel's result on the
  slice equals its result on the whole tenant.
- Refusals are not stored under idempotency keys. A retried refused command
  is evaluated again against the new state.
- Migrations are checked, not proven: `Engine::migrate` commits only if every
  tenant passes the proven-exact checker afterwards. Checking cost grows with
  the data; very large tenants need the check batched.
- Effects are delivered at least once, not exactly once: the receiver must drop duplicates by the delivery key. The Rust dispatcher is integration-tested but trusted. Its registry (id to endpoint) and the `Deliver` implementation are trusted; checking the endpoint's address (no private ranges, no redirects) belongs there.
