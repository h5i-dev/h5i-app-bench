# Roadmap

Each phase must remove or shrink a trusted assumption. Proving more
properties is secondary.

## Assumption ledger

| # | Assumption | Today | Target |
|---|---|---|---|
| A1 | Authenticator returns the real sender | token parsing extracted and proven canonical (`crates/i5h-token/proofs`); HMAC from libcrux (HACL*-verified). Encoder proven too, with an end-to-end round trip on the extracted code (`TokenEncode.lean`). Remaining: key management | key management stays trusted |
| A2 | JSON decoder is faithful | not needed for security: every theorem quantifies over all commands | still needed for functional correctness only |
| A3 | Reply encoder adds nothing | JSON writer extracted and proven (`crates/i5h-json/proofs`): output equals the spec printer, and a string's bytes cannot end its JSON string early; every response goes through it. Mapping kernel replies to JSON values stays trusted (small, per app) | full parser round trip for whole documents |
| A4 | Postgres store matches `apply` | statement planning extracted and proven (`crates/i5h-sql`). The docs app's writes are covered end to end: the kernel encodes its rows (`schema!` generates `to_row`; `sql_writes` is extracted), and `Storage.sql_writes_stored` proves the planned statements leave exactly the rows of `applyAll`. Trusted: the SQL template, and decoding rows on load | prove the decoder too (kernel-side `from_row`, proven left inverse of `to_row`) |
| A5 | SERIALIZABLE commits equal a serial order | trusted | stays trusted (documented PostgreSQL guarantee) |
| A6 | Engine protocol (retry, idempotency, lock) is correct | Lean model in `lean/` proven: serializable commits, at most once per key, no stale decisions. Traces from the Rust engine (`Engine::with_trace`) in the fault and concurrency tests are checked against it by `tracecheck`, proven sound (`check_sound`); about 3,800 events per run, all accepted. The trace check found that idempotency keys were scoped by tenant only (another user could be replayed a reply); keys are now scoped per user (`ReplyCodec::scope`) and a regression test covers it. The tenant lock is now a session lock taken before `BEGIN` | model per-user scopes and the lock explicitly |
| A7 | Charon, Aeneas, Lean are faithful and sound | trusted, with checks: `#print axioms` gate (standard axioms only) and a Rust-vs-Lean differential test (`scripts/difftest.sh`, 55k cases, no mismatch) | stays trusted |
| A8 | No handler bypasses the engine | enforced: stores see only an opaque `Tx` and the pool is opaque, so app code cannot reach the driver; `cargo deny check bans` rejects database crates outside `i5h-pg`; `i5h_pg::lockdown` role separation at runtime. All run in CI | superuser logins stay out of scope |
| A9 | Running code is the extracted code | CI re-extracts every kernel (docs, Kellnr) and extracted crate (`i5h-sql`, `i5h-token`, `i5h-json`) with pinned Charon/Aeneas and fails on any diff | done |
| A10 | The spec says what we meant | human review of a 139-line spec; mutation suite catches 19/19 injected bugs (`scripts/mutants.py`); the Kellnr port proves the pre-#1243 bug is caught | concrete scenario theorems; more mutants |

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

- Write the write-set-to-SQL translation as a pure function in the kernel subset. Prove it equals `apply` under the standard meaning of `INSERT ... ON CONFLICT` and `DELETE` (A4). Done for writes: `i5h_sql::plan` in general, and the docs app's row encoding (`sql_writes`, `Storage.lean`). Open: the load decoder.
- Model the engine protocol in Lean: attempts, conflicts, crashes between commit and reply, retries, idempotency keys. Prove committed history equals a serial run and each key runs at most once. Check small cases with `#eval` search. Add fault-injection tests to the Rust engine (A6).
- Move token parsing into the extracted subset and prove the encoding is unambiguous. Use a verified HMAC such as libcrux if its API fits (A1).
- Extract reply rendering and prove it emits only reply fields (A3).
- `install_schema` creates a DB role that alone can write i5h tables; `cargo-deny` bans DB crates outside the engine (A8).

## Phase 2: developer experience

- `schema!` macro, in the style of Yesod's Persistent: one declaration generates kernel types, table mappings, and a Lean spec skeleton. Done for types and mappings (`crates/i5h-schema`, used by the docs kernel): keys and columns are listed once, and the server gets its `table!` impls, DDL and table list from `docs_kernel::docs_tables!`. Open: the Lean spec skeleton.
- Proof automation: policies as data, generated obligations per command, custom tactics. Target: 0 hand-written Lean lines for a typical command, under 20 for a business invariant. Started: `I5hLib` (`crates/i5h/proofs`) proves Aeneas search and fold loops once (`loop_search`, `loop_fold`), defines table writes, and provides `walk` and `i5h_step`; a kernel loop now needs about 8 lines instead of 20 to 50, and the example's proofs went from 1312 to 1006 lines.
- LLM-written proofs; humans review the policy table and invariant list.
- `cargo i5h-verify` runs the CI checks locally: tests, bans, extraction drift, every proof project with the sorry/axiom gates; `--full` adds the mutation suite, the differential test and the trace check. Done (`xtask/`).

## Phase 3: remove MVP simplifications

- Partial snapshots: each command declares its reads, with a proven theorem that the decision depends only on them. Done for the docs example: `read_scope` (extracted) names the counter plus one project's rows, `transition_frame` proves the result equals the whole-tenant result, and `DocsStore::load_for` loads just that slice (checked against the Lean `slice` in `tests/postgres.rs`).
- Effects and an outbox: SSRF allowlist theorem; exactly-once external calls using the Phase 1 protocol model. Done for the docs example: `authorized` proves an effect goes only to the destination its project registered, and only when a writer publishes an approved document; `i5h_pg::outbox` stores effects in the request's transaction and delivers them at least once with a stable key, only to ids in the operator's registry (`tests/outbox.rs`). Open: model the dispatcher in `lean/`.
- Migrations as pure functions from old snapshot to new, with a proof that old invariants imply new ones. Done differently, and cheaper: migrations are checked, not proven. `Engine::migrate` runs pending SQL in one transaction and then runs the app's checker on every tenant, rolling back on any failure. The docs checker `check_inv` is extracted and proven exact (`check_inv_spec`: true iff `Inv`), so a committed migration leaves every tenant satisfying the invariants (`tests/migrations.rs`).

## Phase 4: real applications

- Port 2 or 3 axum apps from the target survey.
- Where a target had a past vulnerability, show the proof fails on the vulnerable version and passes on the fix.
  Done for Kellnr (`examples/kellnr`): the read-only theorem is proven for the code after PR #1243 and disproven, with a concrete session login that adds an owner, for the code before it. Done for Atuin (`examples/atuin`): user isolation, reply confinement, no orphaned rows after account deletion, and the size cap are proven; for issue #3297 (delete without password, still open), the requested behavior is proven for a fixed kernel and Atuin's current behavior is proven to allow it. See `docs/TARGETS.md`.
- Publish the numbers; run a pilot.

## Irreducible trust

Lean, Aeneas, rustc; PostgreSQL serializability and statement semantics; the
network stack; key management; the spec itself. The spec cannot be proven
away, only kept small, readable, and tested by the mutation suite.
