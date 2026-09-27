# What i5h proves, and what it assumes

## Proven in Lean (about the extracted kernel)

The kernel's `transition` and `apply` are translated from Rust to Lean by
Charon and Aeneas. For the example app, the spec is
`examples/docs/proofs/Spec.lean` and the theorems are in `Theorems.lean` next to it.

## Enforced by structure (no proof needed)

| Property | How |
|---|---|
| Handlers go through the kernel | App code gets `I5h::respond` / `Engine::execute`, never a DB handle. `cargo deny check bans` (`deny.toml`) rejects database crates in any workspace crate but `i5h-pg`. `i5h_pg::lockdown` makes a NOLOGIN role own the i5h tables and grants row access only to the engine's role (see Deployment below). |
| Tenant isolation | The engine loads and writes only rows with `tenant_id = K::tenant(actor)`. Kernel rows carry no tenant id, so the kernel cannot name another tenant. A Lean theorem about this would be trivial, so it is not claimed as proven. |
| Every column is persisted | `table!` must list every field or it does not compile. |

## Assumed (trusted, not verified)

| Component | Assumption | Mitigation |
|---|---|---|
| `Authenticator` | Returns the principal that sent the request. | Token parsing is extracted and proven: an accepted token's signed payload is exactly `enc(tenant, user, exp)`, so a signature covers one identity. HMAC-SHA256 from libcrux 0.0.8 (HACL*-verified, pre-1.0). Still trusted: the secret key and its storage, the clock for expiry, constant-time tag comparison (`ct_eq`). |
| JSON codec | Decodes the body into the command the client meant. | `deny_unknown_fields`; tagged enum. |
| Shell inputs | Values the shell puts in the principal are true: random slugs (Wastebin), GitHub team membership and download counts (crates.io), password checks (Atuin, Wastebin, Conduit), and the time in Conduit's commands. | Theorems hold for every value, so a wrong input cannot break an invariant or a permission rule; it can only make the kernel decide on wrong facts. Each app's README lists its inputs. |
| Clock | The engine's `Clock` reads the right time: the process's system clock (`Clock::System`, the default) or PostgreSQL's `transaction_timestamp()` (`Clock::Database`, used by booking, Wastebin and crates.io). Token expiry in `HmacAuth` uses the system clock. | Theorems hold for every time, so a wrong clock can only make the kernel decide on a wrong time, for example accept a booking that has already started. `Clock::Database` gives every server of a database one clock. With `monotonic`, time never goes back in commit order within a tenant, whatever the clock reads: proven for the model (`Engine.times_monotone`, with `clock_back` showing a run without it) and checked on the Rust engine's traces, whose events carry each attempt's time. So proofs over `I5hLib.ReachableT` hold for the database: a clock that is behind cannot take a tenant back in time, while one that is ahead moves every later request forward until the real time catches up. |
| Reply rendering | Shows the reply the kernel returned. | Bytes come from the extracted `i5h-json` writer, proven to print the token stream exactly and to escape strings so their contents cannot inject JSON. Trusted: the app's reply-to-`Value` mapping, and the `Value` to tokens flattening (tested against serde_json). |
| `i5h-pg` table mapping (A4) | The SQL template in `table.rs::run_stmt` does what `I5hLib.Sql.exec` says: `INSERT ... ON CONFLICT (pk) DO UPDATE` stores `key ++ rest` at `key`, `DELETE ... WHERE pk = key` removes it. A tenant-filtered `SELECT` returns each stored row once (`Load.Lists`), a `WHERE column = value` query each matching row once (`Scoped.Sel`), and `Value`/`Val` conversion is lossless. `load_for` names the filter columns (`"id"`, `"project"`) as strings; `Scoped.lean` models them by column index. | The docs kernel encodes and decodes its own rows (`schema!`'s `to_row`/`from_row`, `sql_writes`, `decode`), all extracted. `Storage.sql_writes_stored`: the planned statements leave exactly the rows of `applyAll` (`Load.sql_writes_storedC` also for a fresh tenant with no counter row). `Load.load_sound`/`store_sound`/`fresh`: the rows always hold a state satisfying `Inv`, whatever order they load in; `Scoped.served_inv` states this for every database the server produces from an empty tenant, over both load paths. Which statements run is decided by `i5h_sql::plan`, proven in `crates/i5h-sql/proofs`. Scoped loads: the kernel picks the project (`scoped_project`), and `Scoped.scoped_command` proves the scoped path keeps the same guarantee. Kellnr and Atuin have no server. |
| PostgreSQL | SERIALIZABLE commits are equivalent to some serial order. | Documented PostgreSQL guarantee. Retries restart from the snapshot read. |
| Engine protocol | Retries never reuse a stale decision; a lost connection never half-applies a request. | Lean model `lean/Engine` proves the protocol serializable, at most once per idempotency key, and free of stale decisions, for any kernel, and with `monotonic`, committed times that never decrease (`Engine.times_monotone`). Traces recorded from the Rust engine in the fault and concurrency tests, on the database clock with `monotonic`, are checked against the model (`scripts/tracecheck.sh`; the checker is proven sound: an accepted trace is a model run whose steps its events explain in order, `check_sound`; the reordering of events from concurrent connections is not proven). Traced runs add a per-tenant commit counter, so the engine checked is the traced one. Idempotency keys are stored per `(tenant, scope, key)`, where the app's `ReplyCodec::scope` names the user; `Engine.replay_in_scope` and `rust_keys_scoped` prove one user cannot be replayed another's reply, and `tenant_keys_leak` shows the leak without scopes. Trusted: the app's `scope` is injective on the tenant's principals (`replay_same_actor`). `Engine.Lock` models the tenant lock. |
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

## Consequence

If the assumptions hold, every committed state of a tenant is reachable from
the empty state by a sequence of kernel transitions. So every invariant proven
to be preserved by `transition` + `apply` holds in the database. With `monotonic`, the times of that sequence never
decrease, so properties proven over `I5hLib.ReachableT` hold there too.

## Not covered yet

- Scoped reads: `Scoped.scoped_sound` proves `DocsStore::load_for` decodes to
  `Frame.slice` of a state the rows hold, given `Scoped.Sel` for each query.
  The mapping from the column names in `load_for` to column indices is
  trusted and tested (`tests/postgres.rs`). `transition_frame` proves the
  kernel's result on the slice equals its result on the whole tenant.
- Refusals are not stored under idempotency keys. A retried refused command
  is evaluated again against the new state.
- Migrations are checked, not proven: `Engine::migrate` commits only if every
  tenant passes the proven-exact checker afterwards. Checking cost grows with
  the data; very large tenants need the check batched.
- Effects are delivered at least once, not exactly once: the receiver must drop duplicates by the delivery key. `Outbox.key_fixes_content` proves that is enough: sends with one key always carry the same endpoint and committed payload (in the model; the Rust dispatcher is tested, not traced). The dispatcher's registry (id to endpoint) and the `Deliver` implementation are trusted, and the model assumes every dispatcher uses the same registry; checking the endpoint's address (no private ranges, no redirects) belongs there.
