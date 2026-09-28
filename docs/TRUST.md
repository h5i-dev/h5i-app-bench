# What i5h proves, and what it assumes

## Proven in Lean (about the extracted code)

The kernel's `transition` and `apply` are translated from Rust to Lean by
Charon and Aeneas. For the example app, the spec is
`examples/docs/proofs/Spec.lean` and the theorems are in `Theorems.lean` next to it.
So are the storage path (`sql_writes`, `decode`, `i5h_sql::plan`), the SQL
compiler and printer (`i5h_pgsql`), the token parser and encoder, and the JSON
writer. Each server's `db_inv` carries the kernel's invariant through the SQL
to the rows later loaded (see A4 below).

## Enforced by structure (no proof needed)

| Property | How |
|---|---|
| Handlers go through the kernel | App code gets `I5h::respond` / `Engine::execute`, never a DB handle. `cargo deny check bans` (`deny.toml`) rejects database crates in any workspace crate but `i5h-pg`. `i5h_pg::lockdown` makes a NOLOGIN role own the i5h tables and grants row access only to the engine's role (see Deployment below). |
| Tenant isolation | Every compiled statement and `SELECT` filters on or writes the tenant it is compiled for, and `tenant_id` is part of every primary key; `Pg.compile_sound` proves a compiled statement leaves other tenants' rows as they were. Kernel rows carry no tenant id, so the kernel cannot name another tenant. The engine and each `Store` must pass `K::tenant(actor)` consistently. |
| Every column is persisted | `table!` must list every field or it does not compile. |

## Assumed (trusted, not verified)

| Component | Assumption | Mitigation |
|---|---|---|
| `Authenticator` | Returns the principal that sent the request. | Token parsing is extracted and proven: an accepted token's signed payload is exactly `enc(tenant, user, exp)`, so a signature covers one identity. HMAC-SHA256 from libcrux 0.0.8 (HACL*-verified, pre-1.0). Still trusted: the secret key and its storage, the clock for expiry, constant-time tag comparison (`ct_eq`). |
| JSON codec | Decodes the body into the command the client meant. | `deny_unknown_fields`; tagged enum. |
| Shell inputs | Values the shell puts in the principal are true: random slugs (Wastebin), GitHub team membership and download counts (crates.io), password checks (Atuin, Wastebin, Conduit), and the time in Conduit's commands. | Theorems hold for every value, so a wrong input cannot break an invariant or a permission rule; it can only make the kernel decide on wrong facts. Each app's README lists its inputs. |
| Clock | The engine's `Clock` reads the right time: the process's system clock (`Clock::System`, the default) or PostgreSQL's `transaction_timestamp()` (`Clock::Database`, used by booking, Wastebin and crates.io). Token expiry in `HmacAuth` uses the system clock. | Theorems hold for every time, so a wrong clock can only make the kernel decide on a wrong time, for example accept a booking that has already started. `Clock::Database` gives every server of a database one clock. With `monotonic`, the trusted engine contract says that the `i5h_clock` row prevents committed times from decreasing within a tenant. Proofs over `I5hLib.ReachableT` apply to database executions only under that assumption. |
| Reply rendering | Shows the reply the kernel returned. | Bytes come from the extracted `i5h-json` writer, proven to print the token stream exactly and to escape strings so their contents cannot inject JSON. Trusted: the app's reply-to-`Value` mapping, and the `Value` to tokens flattening (tested against serde_json). |
| PostgreSQL statement semantics (A4) | PostgreSQL runs the SQL subset that `i5h_pgsql` renders as `I5hLib.Pg` says: `CREATE TABLE IF NOT EXISTS`, `INSERT ... ON CONFLICT (key) DO UPDATE SET` / `DO NOTHING`, `DELETE ... WHERE` and `SELECT ... WHERE`, with `=` true only of equal non-`NULL` values and `IS NOT DISTINCT FROM` true of equal values including `NULL`. A statement either fails or has the modeled effect; a `SELECT` returns the modeled rows in some order. Text compares byte by byte (a deterministic collation). The driver converts `Val` losslessly and types each value as `valKind` says. Existing tables were created from the same schema (`CREATE TABLE IF NOT EXISTS` keeps an older table as it is). | Everything between the kernel and this model is extracted and proven. `i5h_sql::plan` computes `planA`; `i5h_pgsql::valid`, `create`, `select` and `compile` compute `Pg.createA`, `Pg.selectA` and `Pg.compileA`, and `render` prints `Pg.render`, in which a quoted name reads back as itself whatever its bytes (`Pg.lexName_quote`). Under the model, a compiled statement does to the tenant's rows what `I5hLib.Sql.exec` says and changes no other tenant's rows and no table outside the schema (`Pg.compile_sound`), and a compiled `SELECT` returns the tenant's matching rows once each (`Pg.select_sound`, which gives `Lists` and `Sel`). Every server application's `db_inv` composes this with its extracted `transition`, `sql_writes` and `decode`. `tests/postgres.rs` in each server runs the production path against PostgreSQL. |
| Schema description | `schema_spec()`, generated by `schema!`'s mapping macro, lists each table's name and each column's name, kind and nullability, in `TABLE` order, from the `table!` mappings. | Every compile and load checks `i5h_pgsql::valid` on it; the generated `schema_is_valid` test checks the numbering and key lengths against the kernel's `TABLE` and `KEY_LEN`. Names come from the `schema!` declaration. |
| PostgreSQL | SERIALIZABLE commits are equivalent to some serial order. | Documented PostgreSQL guarantee. Retries restart from the snapshot read. |
| Engine protocol | The Rust engine satisfies the contract listed below. | The implementation is kept in `crates/i5h-pg`, application code cannot obtain its pool or raw transaction, and PostgreSQL integration tests cover concurrency, retries, idempotency, connection loss, scoped reads and outbox behavior. This component is trusted, not proven in Lean. |
| Deployment | The engine does not log in as a superuser, and no other service gets its credentials. | Superusers bypass table grants; nothing in i5h can stop that. |
| Charon / Aeneas / Lean | The translation is faithful and the checker is sound. | Upstream tools. |
| axum, hyper, tokio | Deliver requests and responses intact. | Widely used. |

## Deployment

1. As an admin, create the engine's login role: `CREATE ROLE app_engine LOGIN PASSWORD '...'`. Not a superuser, not the table owner.
2. As the admin, run `Engine::install_schema`, then `i5h_pg::lockdown::<App, Store>(admin_url, "i5h_owner", "app_engine")`. It is idempotent; rerun after adding tables. If the app has its own schema (`i5h_pg::with_schema`), use it in both URLs.
3. Run the server with `DATABASE_URL` for `app_engine`. Other roles get `permission denied` on i5h tables (`tests/lockdown.rs`).

`Store` impls get an opaque `i5h_pg::Tx` that offers only `load_table` and `store_writes`, whose SQL comes from `i5h_pgsql`, and `i5h_pg::Pool` is opaque too, so app code has no path to the driver; `cargo deny check bans` rejects the driver in any non-dev dependency. The role lockdown still backs this at runtime, and a superuser login bypasses both.

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

If the PostgreSQL, Store and engine assumptions hold, every normal committed
application state of a tenant is represented by a serial sequence of
successful kernel transitions, and each server's `db_inv` says what that
gives: every database its requests produce, loading with the compiled
`SELECT`s (docs: also the scoped ones), running a successful extracted
`transition` and storing the compiled statements of its writes, among any
other tenants' statements, holds a state satisfying the application's
invariant, and every later load decodes to a snapshot satisfying it.
Migrations need their own invariant check and do not establish kernel
reachability. With `monotonic`, properties over `I5hLib.ReachableT`
additionally rely on the trusted clock contract above.

## Not covered yet

- Refusals are not stored under idempotency keys. A retried refused command
  is evaluated again against the new state.
- Migrations are checked, not proven: `Engine::migrate` commits only if every
  tenant passes the proven-exact checker afterwards. Checking cost grows with
  the data; very large tenants need the check batched.
- Effects are delivered at least once, not exactly once: the receiver must drop duplicates by the delivery key. The Rust dispatcher is integration-tested but trusted. Its registry (id to endpoint) and the `Deliver` implementation are trusted; checking the endpoint's address (no private ranges, no redirects) belongs there.
