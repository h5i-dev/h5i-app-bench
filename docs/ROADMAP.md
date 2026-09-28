# Roadmap

Each phase must remove or shrink a trusted assumption. Proving more
properties is secondary.

## Assumption ledger

| # | Assumption | Today | Target |
|---|---|---|---|
| A1 | Authenticator returns the real sender | token parsing extracted and proven canonical (`crates/i5h-token/proofs`); HMAC from libcrux (HACL*-verified). Encoder proven too, with an end-to-end round trip on the extracted code (`TokenEncode.lean`). Remaining: key management | key management stays trusted |
| A2 | JSON decoder is faithful | not needed for security: every theorem quantifies over all commands | still needed for functional correctness only |
| A3 | Reply encoder adds nothing | JSON writer extracted and proven (`crates/i5h-json/proofs`): output equals the spec printer, and a string's or key's bytes cannot end its JSON string early (`write_str_at`, on the extracted output); every response goes through it. Mapping kernel replies to JSON values stays trusted (small, per app) | full parser round trip for whole documents |
| A4 | Postgres store matches `apply` | Statement planning is extracted and proven (`crates/i5h-sql`). `schema!` generates table operations, `apply`, `sql_writes`, `decode`, and their Lean specs. `I5hLib.Store` proves once for any schema that planned writes leave the rows of `applyAll` and that loading those rows decodes the state up to row order. The eight server apps outside docs instantiate it in `Storage.lean`; docs retains its specialized full and scoped-load invariant proofs. Trusted: SQL statement and `SELECT` semantics, including column-name mapping for filtered reads and deletes. | Keep the SQL boundary small and check it against PostgreSQL. |
| A5 | SERIALIZABLE commits equal a serial order | trusted | stays trusted (documented PostgreSQL guarantee) |
| A6 | Engine protocol (retry, idempotency, lock, clock and outbox) is correct | Explicitly trusted contract in `TRUST.md`; PostgreSQL integration and fault tests cover the production path. The former hand-written Lean model was removed because it had no refinement proof from `i5h-pg` and did not reduce this assumption. | Keep the engine small; expand production-path tests when the contract changes. |
| A7 | Charon, Aeneas, Lean are faithful and sound | trusted, with checks: `#print axioms` gate (standard axioms only) and a Rust-vs-Lean differential test (`scripts/difftest.sh`, 55k cases, no mismatch) | stays trusted |
| A8 | No handler bypasses the engine | enforced: stores see only an opaque `Tx` and the pool is opaque, so app code cannot reach the driver; `cargo deny check bans` rejects database crates outside `i5h-pg`; `i5h_pg::lockdown` role separation at runtime. All run in CI | superuser logins stay out of scope |
| A9 | Running code is the extracted code | CI re-extracts every kernel (docs, the ports, the tutorials) and extracted crate (`i5h-sql`, `i5h-token`, `i5h-json`) with pinned Charon/Aeneas and fails on any diff | done |
| A10 | The spec says what we meant | Human review of the compact spec; the docs mutation suite (`scripts/mutants.py`) and one Rust-compiling, re-extracted mutant for each of the other ten kernels (`scripts/mutants-apps.py`) test that their proofs reject plausible bugs. Every app has concrete scenario theorems; `i5h_eval` uses the registered loop specs to make booking's scenarios one-line proofs. Each port also gives a counterexample for a real upstream bug. | Expand mutation cases as new failure modes appear. |

## Phase 0: proofs on the example app

- Extract the kernel in CI and fail on a diff with the committed Lean (A9).
- Prove on the extracted code:
  - authorization soundness,
  - invariants over all command sequences,
  - replies contain only data the actor may read,
  - noninterference, including error codes,
  - no input makes the kernel fail.
- State every theorem for all commands, so a buggy decoder gives nothing an attacker could not send anyway (A2).
- `#print axioms` shows only Lean's standard axioms. Run the extracted Lean (`#eval`) and the Rust kernel on the same random inputs (A7).
- Mutation suite: known bugs injected into the kernel must each break a proof (A10).
- Exit: Lean lines per Rust line, share of obligations closed automatically, mutation score.

## Phase 1: shrink the shell

- Write the write-set-to-SQL translation as a pure function in the kernel subset. Prove it equals `apply` under the standard meaning of `INSERT ... ON CONFLICT` and `DELETE` (A4). Done: `i5h_sql::plan`, generated table operations and codecs from `schema!`, and the generic `I5hLib.Store` theorem instantiated by the eight server apps outside docs. Docs has its specialized storage and scoped-load proofs (`Storage.lean`, `Load.lean`, `Scoped.lean`).
- State the engine protocol as a short trusted contract and test retries, concurrency, uncertain commits, idempotency, locks, clocks and outbox delivery against PostgreSQL (A6).
- Move token parsing into the extracted subset and prove the encoding is unambiguous. Use a verified HMAC such as libcrux if its API fits (A1).
- Extract reply rendering and prove it emits only reply fields (A3).
- `install_schema` creates a DB role that alone can write i5h tables; `cargo-deny` bans DB crates outside the engine (A8).

## Phase 2: developer experience

- `schema!` generates kernel types, table mappings, row codecs, table operations, `apply`, `sql_writes`, and `decode`, together with Lean specs for their storage behavior. Keys and columns are declared once; generated Lean stays current through a test. Server apps outside docs supply their state encoding and write-to-table mapping in `Storage.lean` to instantiate `I5hLib.Store`. Docs retains its specialized storage proof for scoped reads.
- Proof automation: policies as data, generated obligations per command, custom tactics. Target: 0 hand-written Lean lines for a typical command, under 20 for a business invariant. `I5hLib` proves Aeneas search and fold loops once (`loop_search`, `loop_fold`), defines table writes, and provides `walk`, `i5h_step`, and `i5h_eval`. The last tactic executes concrete extracted scenarios using registered `@[step]` loop specs; booking's scenario proofs use it in one line each.
- LLM-written proofs; humans review the policy table and invariant list.
- `cargo i5h-verify` runs the repository checks locally: tests, bans, extraction drift, every proof project with the sorry/axiom gates; `--full` adds the mutation suite and the differential test. Done (`xtask/`).

## Phase 3: remove MVP simplifications

- Partial snapshots: each command declares its reads, with a proven theorem that the decision depends only on them. Done for the docs example: `read_scope` (extracted) names the counter plus one project's rows, `transition_frame` proves the result equals the whole-tenant result, and `DocsStore::load_for` loads just that slice (proven in `Scoped.lean` given the trusted `SELECT`s, and checked against the Lean `slice` in `tests/postgres.rs`).
- Effects and an outbox. Done for the docs example: `authorized` proves an effect goes only to the destination its project registered, and only when a writer publishes an approved document; `i5h_pg::outbox` stores effects in the request's transaction and delivers them at least once with a stable key, only to ids in the operator's registry. The dispatcher and registry are trusted and tested in `tests/outbox.rs`; receivers must deduplicate by the stable key.
- Migrations as pure functions from old snapshot to new, with a proof that old invariants imply new ones. Done differently, and cheaper: migrations are checked, not proven. `Engine::migrate` runs pending SQL in one transaction and then runs the app's checker on every tenant, rolling back on any failure. The docs checker `check_inv` is extracted and proven exact (`check_inv_spec`: true iff `Inv`), so a committed migration leaves every tenant satisfying the invariants (`tests/migrations.rs`).

## Phase 4: real applications

- Port 2 or 3 axum apps from the target survey.
- Where a target had a past vulnerability, show the proof fails on the vulnerable version and passes on the fix.
  Done for Kellnr (`examples/kellnr`): the read-only theorem is proven for the code after PR #1243 and disproven, with a concrete session login that adds an owner, for the code before it. Done for Atuin (`examples/atuin`): user isolation, reply confinement, no orphaned rows after account deletion, and the size cap are proven; for issue #3297 (delete without password, still open), the requested behavior is proven for a fixed kernel and Atuin's current behavior is proven to allow it. See `docs/TARGETS.md`.
  Done for Wastebin (`examples/wastebin`, issue #190, link previews burned pastes), Conduit (`examples/conduit`, issue #16, wrong `favorited` flag) and crates.io (`examples/cratesio`, PR #14760, locked accounts signed in), each with a PostgreSQL server.
- Publish the numbers; run a pilot.

## Found while porting

The ports needed things the framework did not have. Done:

- Apps sharing a database shared tables, idempotency keys and the outbox. `with_schema` gives each app a PostgreSQL schema.
- Cascading deletes by a non-key column: `delete_where`.
- Routes whose reply becomes a credential (a session cookie, an API token): `I5h::run` returns the reply unrendered.
- `HmacAuth` takes closures, so the principal can carry configuration; `verify` is public, the scheme is configurable (`Token` for RealWorld), and a missing header can map to an anonymous principal.
- A clock. The engine reads a `Clock` (system, database or test) per attempt and passes it to `Kernel::stamp`; the trusted `monotonic` contract says time never goes back in commit order per tenant. `MemoryEngine::execute_at` does the same in memory, and `I5hLib.ReachableT` lets apps prove properties under that assumption. Booking, Wastebin and crates.io use the database's clock; Conduit still puts the time in its commands.
- `MemoryEngine::with_snapshot` starts a reference run from a database's state.
- The outbox sends each claimed batch in row-id order; global delivery order is not guaranteed.

Open:

- Per-actor loads. The engine loads the whole tenant, so a user's command costs O(tenant) and its latency depends on other users' data. `Store::load_for` takes the command; an actor-aware version needs a frame theorem per app, as the document service has.
- Idempotency scopes for anonymous callers. All callers without an identity share one scope; `ReplyCodec::scope` should be able to refuse keys.
- A `u64` column is `BIGINT`, so values of 2^63 or more fail at runtime.

## Irreducible trust

Lean, Aeneas, rustc; PostgreSQL serializability and statement semantics; the
network stack; key management; the spec itself. The spec cannot be proven
away, only kept small, readable, and tested by the mutation suite.
