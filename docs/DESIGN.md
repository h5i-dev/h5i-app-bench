# Design

See also the [roadmap](ROADMAP.md), [what is proven and trusted](TRUST.md)
and [proof sizes and build times](NUMBERS.md).

## Architecture

The kernel, `transition(actor, snapshot, command) -> (writes, reply)`, holds
every permission check and business rule, in the Rust subset Aeneas
translates to Lean. The shell (axum routes, authentication, PostgreSQL) loads
the caller's tenant, calls the kernel and commits the writes in one
SERIALIZABLE transaction. App code gets no database
connection. That alone does not prove the server refines the kernel; that
also needs the assumptions in [TRUST.md](TRUST.md).

```
HTTP (axum) ──► Actor<K> ──► I5h::respond ──► Engine: BEGIN, load, transition, write, COMMIT
                                                              │
                                                  kernel (Rust) ══ Aeneas ══► Lean proofs
```

## Repository layout

| Path | Contents |
|---|---|
| `crates/i5h` | the `Kernel` trait, an in-memory reference engine, and the Lean library `I5hLib` |
| `crates/i5h-pg` | the PostgreSQL engine: tenant snapshots, retries, idempotency and role lockdown |
| `crates/i5h-http` | axum integration: the `Actor` extractor, `I5h::respond` and `rpc_router` |
| `crates/i5h-schema` | `schema!`, which declares kernel rows once |
| `crates/i5h-sql`, `i5h-pgsql`, `i5h-token`, `i5h-json` | extracted and proven shell parts: statement planner, SQL compiler and printer, bearer tokens, JSON output |
| `examples/tutorials` | step-by-step tutorials |
| `examples/docs` | the document service, the largest example |
| `examples/kellnr`, `examples/atuin` | ports of real authorization code, kernels and proofs only |
| `examples/wastebin`, `examples/conduit`, `examples/cratesio` | ports of real applications, with servers |
| `xtask` | `cargo i5h-verify`, which runs CI's checks locally |

The root Cargo workspace holds `crates/*` and `xtask`. `examples/` is a second
workspace whose crates depend on `crates/*` by path, as an application would.

In each proof project (`*/proofs`), `generated/` holds extracted Rust and
`schema!` output as a separate Lean library with its own `srcDir`;
hand-written specs and proofs sit at the top level.

## What the examples prove

The document service (`examples/docs`) has projects, members and a review
workflow. For every actor, reachable state and command, Lean checks that:
committed writes fit the policy table (four-eyes rule included); replies show
only documents the caller may read; invariants hold; results and error codes
depend only on what the user may see; webhooks go only to the project's
registered destination; a result depends only on one project's rows, so the
server loads only those; the kernel never panics.

Each port's property fails with a counterexample on the code before a known
fix and holds after it.

| Port | Bug shown |
|---|---|
| `examples/kellnr` | read-only users could change owners (PR #1243) |
| `examples/atuin` | a session alone can delete an account (issue #3297) |
| `examples/wastebin` | link previews burned pastes before commit 632ddf2 (issue #190) |
| `examples/conduit` | upstream's `favorited` flag is wrong (issue #16); every reply of realworld-axum-sqlx is proven equal to a spec |
| `examples/cratesio` | locked accounts could still sign in before PR #14760 |

Porting the three servers found three more upstream problems, listed in
[NUMBERS.md](NUMBERS.md). The [tutorials](../examples/tutorials) each teach
one kind of property: functional correctness, permissions and invariants,
conservation of a sum, noninterference, and interval invariants with effects.

## From transition to stored rows

```
Rust transition --Aeneas--> Lean: Inv(s) and Accept(ws) give Inv(apply s ws)
      |
      v
write set --sql_writes--> table writes --plan--> statements
      --i5h_pgsql::compile--> SQL subset + parameters --render--> text
      --PostgreSQL model (I5hLib.Pg)--> rows
      --i5h_pgsql::select, decode--> next snapshot
```

Every arrow except the PostgreSQL model is Rust extracted by Aeneas. Each
server app proves `db_inv`: the invariant holds in every database its
requests produce and in every snapshot loaded from it. [TRUST.md](TRUST.md)
gives the exact statement, the theorem behind each arrow and what stays
trusted.

## PostgreSQL boundary

i5h assumes PostgreSQL follows its documented semantics. Its own use of
PostgreSQL it must prove or test: the SQL matches the Lean model, table, key
and column mappings agree across Rust, Lean and PostgreSQL, and nulls,
integers and filtered deletes mean the same on each side. Retries, atomic
commits and connection cleanup belong to the tested engine contract in
[TRUST.md](TRUST.md).

A review found one mismatch: `DelWhere` treats `Val.Null` as equal to
`Val.Null`, but the SQL used `=`, which is unknown for `NULL`. The model
gives `=` and `IS NOT DISTINCT FROM` different meanings, so the soundness
proof fails on the old SQL. Filters now use `IS NOT DISTINCT FROM`; `=` is
used only for non-`NULL` key values.

The compiler resolves names through the schema: filters by the zero-based
column index `schema!` emits (a Rust constant and a Lean `col_*`), statements
by table number. `i5h_pgsql::valid`
rejects names PostgreSQL could read differently (empty, over 63 bytes,
containing NUL, duplicated, a column named `tenant_id`, a table named
`i5h_...`), and every compile checks it.

## Next steps

Proofs aim at one claim: the app later reads back the state change of the
decision the extracted kernel made. PostgreSQL, the async runtime and the
engine stay trusted. With `db_inv` done, next:

1. Test `I5hLib.Pg` against real PostgreSQL: nulls, numeric encodings,
   conflicts, scoped reads.
2. Generate stores from `schema!` and bind the tenant into the transaction
   API, so a `Store` cannot touch another tenant.
3. Test retries, unknown commits, cancellation, advisory-lock cleanup,
   idempotency and outbox delivery on the production path in CI, not in a
   separate model checker. CI rejects a run that skipped them.

## Inputs from the shell

`transition` is pure, so outside facts (time, a random slug, another
service's answer) come in from the shell. Put them in the principal, not the
client-chosen command: a client that picks the time can book the past.
Theorems hold for any value but cannot say it is true, so each app's README
lists these inputs as trusted. The authenticator draws a slug once per
request, so a retry sees the same one.

Each attempt reads the engine's `Clock` in its transaction, and
`Kernel::stamp` copies it into the principal before `transition`.
`Timestamp` counts microseconds since the Unix epoch (`secs()` for seconds).
A retry reads the clock again, so the committing attempt's time decides.
Idempotent replay matches on the command's fingerprint, which omits the time.
With `EngineConfig::monotonic`, the engine never uses a time earlier than the
tenant's last commit (kept in `i5h_clock`). `I5hLib.ReachableT` proves
properties under that trusted assumption, such as `started_stays` in the
booking tutorial.

## One schema per app

The engine's tables (idempotency keys, outbox) have fixed names. Two apps in
one database would share them, and one app's dispatcher would claim the
other's effects. `i5h_pg::with_schema(url, "app")` gives an app its
own PostgreSQL schema, created by `install_schema`. Every example except the
document service uses one.

## Proof patterns

The examples prove their theorems in this order:

1. Specify each table loop with lists (`find?`, `any`, `filter`, `upsert`),
   proven with `loop_search` or `loop_fold` from `I5hLib`.
2. Give each command one lemma: what a successful run writes and why it
   succeeded. Only these touch extracted code.
3. Combine them into the few write-set shapes a successful command produces:
   a disjunction (board, ledger) or an inductive `Effect` relation with
   `cases` (larger ports; scales better).
4. Prove each theorem by cases on that: permissions against a per-write-kind
   policy, one invariant lemma per state change, induction over `Reachable`.
   Theorems needing the invariant assume reachability, never the invariant.
5. `Apply.lean`: the kernel's `apply` computes the spec's `applyAll`, one
   loop lemma per table.
6. Scenario theorems run the extracted kernel on small states, showing the
   guarded behavior happens (not a kernel that refuses everything) and that
   reachable-state hypotheses can hold.

A past bug is a second transition function differing in one command, refuted
by a scenario theorem. Confidentiality is noninterference over
a `view` of the state (`examples/tutorials/inbox`, `examples/docs`). Reply
correctness is equality with a spec function (`examples/conduit`).

## Checks

`cargo i5h-verify` runs the Rust tests (and the PostgreSQL tests when
`I5H_TEST_DATABASE_URL` is set), checks with `cargo deny` that only `i5h-pg`
uses a database driver, re-extracts every kernel with Charon and Aeneas and
fails on any diff, and builds every proof project, rejecting `sorry`,
`native_decide`, `axiom` and non-standard axioms in the main theorems.
`--full` adds the mutation suite and the Rust/Lean differential test. Missing
tools are reported as skipped, not passed.

Toolchain: stable Rust, elan with Lean v4.31.0, and Charon and Aeneas at the
commit pinned in the proof lakefiles.
