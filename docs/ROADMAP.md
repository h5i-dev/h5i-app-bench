# Roadmap

Each phase must remove or shrink a trusted assumption. Proving more
properties is secondary.

## Assumption ledger

| # | Assumption | Today | Target |
|---|---|---|---|
| A1 | Authenticator returns the real sender | token parsing extracted and proven canonical (`crates/i5h-token/proofs`); HMAC from libcrux (HACL*-verified). Remaining: key management, encoder round trip proven only at spec level | key management stays trusted |
| A2 | JSON decoder is faithful | not needed for security: every theorem quantifies over all commands | still needed for functional correctness only |
| A3 | Reply encoder adds nothing | trusted | rendering extracted; proven to output only reply fields (Phase 1) |
| A4 | Postgres store matches `apply` | statement planning extracted and proven (`crates/i5h-sql`); row-to-column mapping and the SQL template trusted, covered by the differential test | prove the docs kernel's `applyAll` equals `readBack` of the planned rows, so the example's own write mapping is covered too |
| A5 | SERIALIZABLE commits equal a serial order | trusted | stays trusted (documented PostgreSQL guarantee) |
| A6 | Engine protocol (retry, idempotency, lock) is correct | Lean model in `lean/` proven: serializable commits, at most once per key, no stale decisions; exhaustive search on a small instance. Rust engine tested with fault injection; its match with the model is by review | tie the model to the Rust code (e.g. trace checking in the fault tests) |
| A7 | Charon, Aeneas, Lean are faithful and sound | trusted, with checks: `#print axioms` gate (standard axioms only) and a Rust-vs-Lean differential test (`scripts/difftest.sh`, 55k cases, no mismatch) | stays trusted |
| A8 | No handler bypasses the engine | enforced: `i5h_pg::lockdown` role separation (tested) and `cargo deny check bans`, both run in CI; remaining gap is the `tokio_postgres` re-export, and superuser logins | close the re-export gap |
| A9 | Running code is the extracted code | CI re-extracts with pinned Charon/Aeneas and fails on any diff (verified locally; first GitHub run pending) | same for `i5h-sql` and `i5h-token` |
| A10 | The spec says what we meant | human review of a 125-line spec; mutation suite catches 12/12 injected bugs (`scripts/mutants.py`) | concrete scenario theorems; more mutants |

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

- Write the write-set-to-SQL translation as a pure function in the kernel subset. Prove it equals `apply` under the standard meaning of `INSERT ... ON CONFLICT` and `DELETE` (A4).
- Model the engine protocol in Lean: attempts, conflicts, crashes between commit and reply, retries, idempotency keys. Prove committed history equals a serial run and each key runs at most once. Check small cases with `#eval` search. Add fault-injection tests to the Rust engine (A6).
- Move token parsing into the extracted subset and prove the encoding is unambiguous. Use a verified HMAC such as libcrux if its API fits (A1).
- Extract reply rendering and prove it emits only reply fields (A3).
- `install_schema` creates a DB role that alone can write i5h tables; `cargo-deny` bans DB crates outside the engine (A8).

## Phase 2: developer experience

- `schema!` macro, in the style of Yesod's Persistent: one declaration generates kernel types, table mappings, and a Lean spec skeleton.
- Proof automation: policies as data, generated obligations per command, custom tactics. Target: 0 hand-written Lean lines for a typical command, under 20 for a business invariant.
- LLM-written proofs; humans review the policy table and invariant list.
- `cargo i5h verify` runs extraction, proofs, and the mutation suite.

## Phase 3: remove MVP simplifications

- Partial snapshots: each command declares its reads, with a proven theorem that the decision depends only on them.
- Effects and an outbox: SSRF allowlist theorem; exactly-once external calls using the Phase 1 protocol model.
- Migrations as pure functions from old snapshot to new, with a proof that old invariants imply new ones.

## Phase 4: real applications

- Port 2 or 3 axum apps from the target survey.
- Where a target had a past vulnerability, show the proof fails on the vulnerable version and passes on the fix.
- Publish the numbers; run a pilot.

## Irreducible trust

Lean, Aeneas, rustc; PostgreSQL serializability and statement semantics; the
network stack; key management; the spec itself. The spec cannot be proven
away, only kept small, readable, and tested by the mutation suite.
