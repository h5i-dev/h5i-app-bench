# Roadmap

Each phase must remove or shrink a trusted assumption. New properties come
second.

## Assumption ledger

| # | Assumption | Today | Target |
|---|---|---|---|
| A1 | Authenticator returns the real sender | Token parser and encoder extracted and proven, with a round trip (`crates/i5h-token/proofs`, `TokenEncode.lean`). HMAC from libcrux (HACL*). | Key management stays trusted |
| A2 | JSON decoder is faithful | Not needed for security: theorems cover all commands | Needed for correctness only |
| A3 | Reply encoder adds nothing | JSON writer proven (`crates/i5h-json/proofs`): output equals the spec printer; string bytes cannot close a string early (`write_str_at`). Mapping replies to JSON is trusted, per app. | Parser round trip |
| A4 | Postgres store matches `apply` | Proven up to PostgreSQL: planner (`crates/i5h-sql`), SQL compiler and printer (`crates/i5h-pgsql`) against the model `I5hLib.Pg` (`exec`, `Lists`/`Sel`). `schema!` generates table code, `apply`, `sql_writes`, `decode`, their specs, and `PgServed`/`pg_loaded_inv`. Each server app proves `db_inv` from its extracted `transition` to every later load. Trusted: PostgreSQL matches `I5hLib.Pg`, driver value conversion, schema description. | Test `I5hLib.Pg` against PostgreSQL with generated statements |
| A5 | SERIALIZABLE equals a serial order | Trusted; theorems over `I5hLib.Run` (every interleaving of requests) rest on it | Stays trusted (PostgreSQL guarantee) |
| A6 | Engine protocol (retry, idempotency, lock, clock, outbox) is correct | Trusted contract in `TRUST.md`; integration and fault tests. The Lean engine model was removed: no refinement proof from `i5h-pg`. | Keep the engine small; extend tests with the contract |
| A7 | Charon, Aeneas, Lean are sound | Trusted. Axiom gate; Rust-vs-Lean differential test (`scripts/difftest.sh`, 55k cases, no mismatch) | Stays trusted |
| A8 | No handler bypasses the engine | Opaque `Tx` and pool; `cargo deny check bans` keeps DB crates in `i5h-pg`; `i5h_pg::lockdown` role separation. In CI. | Superusers out of scope |
| A9 | Running code is the extracted code | CI re-extracts every kernel and extracted crate (`i5h-sql`, `i5h-token`, `i5h-json`) with pinned tools and fails on diff | Done |
| A10 | The spec says what we meant | Human review; mutation suites (`scripts/mutants.py` for docs, `scripts/mutants-apps.py` for the other ten kernels); scenario theorems in every app; one upstream-bug counterexample per port | Add mutants for new failure modes |

## Phase 0: proofs on the example app

Done: extraction check (A9); proofs on the extracted kernel of
authorization, invariants, reply confinement, noninterference with error
codes and totality, for every command (A2); axiom gate and differential test
(A7); mutation suite (A10). Metrics in `NUMBERS.md`.

## Phase 1: shrink the shell

Done:

- SQL translation proven equal to `apply` (A4): `i5h_sql::plan`, `schema!`,
  `I5hLib.Store`, `i5h_pgsql` with `I5hLib.Pg`, `db_inv` per server app.
  Docs keeps its own proofs (`Storage.lean`, `Load.lean`, `Scoped.lean`,
  `Database.lean`).
- Engine protocol as a trusted contract with PostgreSQL tests (A6).
- Token parsing extracted and proven unambiguous; libcrux HMAC (A1).
- Reply rendering extracted and proven (A3).
- `install_schema` creates the only role that writes i5h tables; `cargo-deny`
  bans DB crates outside the engine (A8).

## Phase 2: developer experience

- Done: `schema!` generates kernel types, table code, `apply`,
  `sql_writes`, `decode` and Lean specs, with column indices shared by Rust
  and Lean. Other server apps map their state in `Storage.lean` to use
  `I5hLib.Store`.
- Proof automation. Target: no hand-written Lean for a typical command,
  under 20 lines for a business invariant. `I5hLib` has `loop_search`,
  `loop_fold`, table writes, `walk`, `i5h_step` and `i5h_eval`, which runs
  concrete scenarios with `@[step]` loop specs. For `for` loops over slices,
  `iter_loop`, `iter_fold`, `iter_search` and their list forms, closed by
  `i5h_iter`, or `i5h_for` for a whole one-loop function; `i5h_derive_eq`
  and `i5h_derive_clone` for derived `==` and `clone`; `i5h_steps` through binds on
  `if`; `i5h_simp`.
- LLM-written proofs; humans review the policy table and invariants.
- Done: `cargo i5h-verify` (`xtask/`) runs tests, bans, extraction drift and
  all proofs with sorry/axiom gates. `--full` adds mutants and the
  differential test.

## Phase 3: remove MVP simplifications

Done for docs:

- Partial snapshots. `read_scope` names the counter and one project;
  `transition_frame` proves that slice gives the whole-tenant result;
  `DocsStore::load_for` loads it (`Scoped.lean`, `Database.lean`,
  `tests/postgres.rs`).
- Effects and outbox. `authorized` proves an effect goes only to its
  project's registered destination when a writer publishes an approved
  document. `i5h_pg::outbox` stores effects in the request's transaction and
  delivers at least once with a stable key to registered ids. Dispatcher and
  registry are trusted (`tests/outbox.rs`); receivers must deduplicate.
- Migrations, checked rather than proven. `Engine::migrate` runs pending SQL
  and the app's checker on every tenant in one transaction, rolling back on
  failure. `check_inv_spec` proves `check_inv` exact (`tests/migrations.rs`).

## Phase 4: real applications

Done: Kellnr (PR #1243), Atuin (issue #3297), Wastebin (issue #190), Conduit
(issue #16), crates.io (PR #14760), each under `examples/`. See `TARGETS.md`.
Open: publish the numbers; run a pilot.

## Found from user feedback

Done:

- Text handling: byte-string specs (`I5hLib.Bytes`) and parser loops
  (`iter_loop`); `examples/filters` proves a substitute/parse round trip for
  every name and refutes an escaping mismatch.
- Collections: `for` loop specs state properties of the whole list, not of
  one element.
- Multi-request properties: `I5hLib.Run`; `examples/keys` proves revocation
  against every interleaving and refutes a check-then-use kernel.
- Automation: `i5h_for`, `i5h_derive_eq`, `i5h_derive_clone`, `i5h_steps`,
  `i5h_simp`.

## Found while porting

Done:

- `with_schema`: one PostgreSQL schema per app, so apps sharing a database
  no longer share tables, idempotency keys or the outbox.
- `DelWhere`: cascading delete by a non-key column, one null-safe `DELETE`.
- `I5h::run` returns the reply unrendered, for cookies and API tokens.
- `HmacAuth` takes closures; `verify` is public; the scheme is configurable;
  a missing header can mean an anonymous principal.
- Clock: the engine passes a `Clock` (system, database or test) to
  `Kernel::stamp` per attempt. The trusted `monotonic` contract says time
  never goes back in commit order per tenant. `MemoryEngine::execute_at` and
  `I5hLib.ReachableT` support it. Conduit still puts time in its commands.
- `MemoryEngine::with_snapshot` starts a reference run from database state.
- The outbox sends each batch in row-id order; global order is not
  guaranteed.

Open:

- Iterator adapters and closures (`.iter().any(..)`, `.filter().collect()`)
  extract to opaque functions in the pinned Aeneas; kernels use `for` loops.
  `String` has no model; kernels use `Vec<u8>`.
- Liveness ("eventually") has no statement form; `I5hLib.Run` covers
  safety properties over every finite run.
- Per-actor loads. A command loads the whole tenant, O(tenant). An
  actor-aware `Store::load_for` needs a frame theorem per app.
- Anonymous callers share one idempotency scope; `ReplyCodec::scope` should
  refuse keys.
- `u64` columns are `BIGINT`; values of 2^63 or more fail at runtime.

## Irreducible trust

Lean, Aeneas, rustc; PostgreSQL serializability and statement semantics; the
network stack; key management; the spec, which can only be kept small and
tested by mutation.
