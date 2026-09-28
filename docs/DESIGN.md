# Design

This document describes how i5h is structured, what the proofs in this
repository cover, and how the checks are run. The [roadmap](ROADMAP.md)
tracks what is left to do, [TRUST.md](TRUST.md) lists the trusted parts, and
[NUMBERS.md](NUMBERS.md) records proof sizes and build times.

## Architecture

An i5h application has two parts. The kernel is a function
`transition(actor, snapshot, command) -> (writes, reply)` that holds every
permission check and business rule, and it is written in the subset of Rust
that Aeneas can translate to Lean. The shell is everything else: axum routes,
authentication and PostgreSQL. The shell loads the caller's tenant, calls the
kernel and commits its writes in one SERIALIZABLE transaction. Application
code normally receives no database connection, which keeps the trusted shell
small, but this structure alone does not prove that the running server refines
the kernel model. That conclusion also needs the store mapping, transaction
wrapper, authentication and rendering assumptions described below.

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
| `crates/i5h-sql`, `i5h-pgsql`, `i5h-token`, `i5h-json` | shell components that are extracted and proven: the statement planner, the SQL compiler and printer, bearer tokens, JSON output |
| `examples/tutorials` | step-by-step tutorials |
| `examples/docs` | the document service, the largest example |
| `examples/kellnr`, `examples/atuin` | ports of real authorization code, kernels and proofs only |
| `examples/wastebin`, `examples/conduit`, `examples/cratesio` | ports of real applications, with servers |

Each proof project (`*/proofs`) keeps generated Lean in `generated/`, which
holds the extracted Rust and the `schema!` output, and keeps the hand-written
specifications and proofs at the top level. The generated files are a separate
Lean library with its own `srcDir`, so module names do not change.

## Proofs in this repository

The document service in `examples/docs` has projects, members and a review
workflow. For every actor, reachable state and command, Lean checks that each
committed write is allowed by the policy table (including the four-eyes rule), that
replies contain only documents the caller may read, and that every reachable
state keeps its invariants. It also checks that a user's result, including
error codes, depends only on what that user may see, that webhooks go only to
the destination a project registered, that a command's result depends only on
one project's rows (so the server loads only those), and that the kernel never
panics. Storage theorems connect the kernel's writes with the SQL the server
sends and with the rows a later request loads: every server application has a
`db_inv` theorem saying that the invariant holds for every database its
requests produce and for every snapshot loaded from it, under the PostgreSQL
model and engine contract below.

The SQL statement planner, the SQL compiler and printer, the token parser and
encoder, and the JSON writer are extracted and proven. The PostgreSQL engine,
its retry and idempotency protocol, and the outbox dispatcher are trusted
implementation. Their contract is stated in [TRUST.md](TRUST.md) and checked
with integration and fault tests.

Five ports test the approach on real code, and each one reproduces a known
bug: the property fails, with a concrete counterexample, on the code before
the fix, and holds after it. `examples/kellnr` models Kellnr's authorization
around PR #1243, where read-only users could change owners. `examples/atuin`
ports the account and record rules of the Atuin sync server and shows that a
session alone can delete an account (issue #3297). `examples/wastebin` ports
Wastebin's paste rules, including expiry and burn after reading, and shows
that link previews burned pastes before commit 632ddf2 (issue #190).
`examples/conduit` ports every route of the RealWorld backend
realworld-axum-sqlx, proves every reply equal to a specification of the state
and the caller, and shows that upstream's `favorited` flag is wrong (issue
#16). `examples/cratesio` ports crates.io's ownership, token scope and
deletion rules and shows that locked accounts could still sign in before PR
#14760. The last three have PostgreSQL servers, and porting them found three
more problems upstream, listed in [NUMBERS.md](NUMBERS.md).

The [tutorials](../examples/tutorials) teach one kind of property each:
functional correctness, permissions and invariants, conservation of a sum,
noninterference, and interval invariants with effects.

## Proof boundary and design assessment

The most valuable proof path in i5h is the one that starts with code that
actually runs and stays close to application data:

```
Rust transition --Aeneas--> Lean: Inv(s) and Accept(ws) give Inv(apply s ws)
      |
      v
write set --sql_writes--> table writes --plan--> statements
      --i5h_pgsql::compile--> SQL subset + parameters --render--> text
      --PostgreSQL model (I5hLib.Pg)--> rows
      --i5h_pgsql::select, decode--> next snapshot
```

Every arrow except the PostgreSQL model is Rust code extracted by Aeneas, and
the Lean theorems are about the extracted functions:

- `sql_writes` and the generated table operations store what `apply`
  computes (`Storage.lean`, `I5hLib.Store`);
- `i5h_sql::plan` computes `planA` (`crates/i5h-sql/proofs`);
- `i5h_pgsql::valid`, `create`, `select` and `compile` compute
  `Pg.createA`, `Pg.selectA` and `Pg.compileA`, and `render` prints
  `Pg.render` (`crates/i5h-pgsql/proofs`);
- under `I5hLib.Pg`'s meaning of the SQL subset, a compiled statement does to
  the tenant's rows what `I5hLib.Sql.exec` says and leaves other tenants'
  rows and other tables alone (`Pg.compile_sound`), and a compiled `SELECT`
  returns the tenant's matching rows once each (`Pg.select_sound`); a quoted
  name reads back as itself (`Pg.lexName_quote`);
- the generated `PgServed` relation describes one tenant's history on a
  database that holds every tenant, and `pg_loaded_inv` turns an invariant
  preserved by accepted write sets into an invariant of every state the
  database holds and of every snapshot loaded from it. Each server
  application instantiates it with its extracted `transition` as `db_inv`
  (docs: `Database.db_inv`, which also covers the scoped loads).

The theorem each server has therefore has this shape:

> For the schema the server passes to `i5h_pgsql` and any tenant, every
> database produced by loading with the compiled `SELECT`s, running a
> successful extracted `transition` and storing the compiled statements of its
> writes, among any other tenants' compiled statements, holds a state
> satisfying `Inv`, and every later load decodes to a snapshot satisfying
> `Inv`.

What remains trusted is listed in [TRUST.md](TRUST.md): that PostgreSQL runs
the rendered subset as `I5hLib.Pg` says, the driver's value conversion, the
few lines that build the schema description from the table mappings, and the
engine contract.

### PostgreSQL as a trust boundary

i5h should not attempt to prove PostgreSQL correct. It should explicitly
assume that PostgreSQL implements its documented statement, transaction,
isolation and failure semantics. In particular, i5h relies on atomic
transactions and on successful SERIALIZABLE transactions being equivalent to
some serial execution.

That assumption does not cover mistakes in i5h's use of PostgreSQL. The
framework remains responsible for showing or testing that:

- generated SQL denotes the same table operation as the Lean model;
- table, key and column mappings agree across Rust, Lean and PostgreSQL;
- nullable values, integer representations and filtered deletes have the same
  meaning on both sides;
- every retry reloads state and reruns the kernel inside a new transaction;
- application writes, idempotency records, monotonic-clock updates and outbox
  inserts are committed atomically; and
- connection loss, cancellation and pooled connections do not leave protocol
  state such as session advisory locks behind.

This boundary is preferable to an informal claim that the database is
verified. It identifies PostgreSQL as a large trusted component while keeping
i5h's much smaller translation and integration layer reviewable.

A review found a concrete semantic mismatch at this boundary: the abstract
`DelWhere` operation treats `Val.Null` as equal to `Val.Null`, while the SQL
used ordinary equality, for which comparison with `NULL` is unknown rather
than true. The PostgreSQL model gives `=` and `IS NOT DISTINCT FROM` their
different meanings, so the proof that compiled statements do what `exec` says
fails for the old text. The compiler uses `IS NOT DISTINCT FROM` for filters
and `=` only for non-`NULL` key values.

The compiler resolves every name through the schema: filters take the
zero-based encoded column index that `schema!` emits both as a Rust constant
and as a Lean `col_*` definition, and statements take the table's number.
`i5h_pgsql::valid` rejects schemas whose names PostgreSQL could read
differently (empty, over 63 bytes, containing NUL, duplicated, a column named
`tenant_id`, a table named `i5h_...`), and every compile checks it.

### Trusted engine contract

The engine is deliberately a small trusted component. Its contract is that a
successful request loads and writes one tenant in one SERIALIZABLE transaction,
runs `transition` after every retry's fresh load, commits the kernel writes
atomically with idempotency, clock and outbox rows, and handles an uncertain
COMMIT outcome as documented in [TRUST.md](TRUST.md). Idempotency scopes,
reply codecs, advisory-lock cleanup and dispatcher behavior are also part of
this trusted contract. Tests exercise these claims against PostgreSQL; they are
not Lean theorems.

### Practical direction

Formalization effort should be prioritized as follows:

1. Done: an end-to-end theorem for each server application, from a successful
   extracted transition to the invariant of the rows subsequently loaded from
   the database, over the SQL the server sends.
2. Test the PostgreSQL model (`I5hLib.Pg`) against real PostgreSQL: null
   semantics, numeric encodings, conflicts and scoped reads.
3. Generate ordinary stores from `schema!` and bind the tenant into the
   transaction API, so application `Store` implementations cannot accidentally
   select or write another tenant.
4. Keep PostgreSQL integration and fault tests on the production path in CI;
   do not replace them with a separate model checker. The CI wrapper rejects a
   run in which PostgreSQL tests were skipped.
5. Test retries, unknown commits, cancellation, advisory-lock cleanup,
   idempotency and outbox delivery through the production execution path.

This direction deliberately accepts PostgreSQL, the async runtime and a small
engine wrapper as trusted implementation. It concentrates proof effort on the
project's distinctive claim: the authorization and business decision computed
by the extracted Rust kernel is the decision whose state change is represented
by the rows the application later reads.

## Inputs from the shell

`transition` is pure, so anything it needs from outside, such as the current
time, a random slug or a fact from another service, arrives as an input that
the shell fills in. Put such inputs in the principal rather than in the
command, which the client chooses: a client that picks the time can book the
past. Since theorems quantify over every principal, they hold for any value
the shell supplies. What they cannot say is that the value is true, so each
app's README names these inputs as trusted.

The time comes from the engine. Each attempt reads the configured `Clock`
inside its transaction (the process's clock, PostgreSQL's
`transaction_timestamp()`, or a test clock) and passes it to
`Kernel::stamp`, which copies it into the principal right before
`transition`. Time is a `Timestamp` in microseconds since the Unix epoch;
kernels that count seconds take `secs()`. A retry reads the clock again, so
a decision is made at the time of the attempt that commits it, and an
idempotent replay matches on the command's fingerprint, which leaves the time
out. With `EngineConfig::monotonic`, the trusted engine contract says that the
engine keeps each tenant's latest commit time in `i5h_clock` and never uses an
earlier one, so time never goes back in commit order within a tenant.
`I5hLib.ReachableT` lets an app prove properties under that assumption, such
as `started_stays` in the booking tutorial. Other inputs, such as a random
slug, are drawn once per request by the authenticator, so a retry sees the
same value.

## One schema per app

Tables are plain PostgreSQL tables named by `schema!`, and the engine's own
tables (idempotency keys, the outbox) have fixed names. Two apps that share a
database would therefore share tables, and one app's outbox dispatcher would
claim the other's effects. `i5h_pg::with_schema(url, "app")` gives an app a
PostgreSQL schema of its own, which `install_schema` creates. Every example
except the document service uses one.

## Proof patterns

The examples prove their theorems in the same order, and the order has held
up across all of them.

1. Each helper that loops over a table gets a specification in terms of lists
   (`find?`, `any`, `filter`, `upsert`), proven once with `loop_search` or
   `loop_fold` from `I5hLib`.
2. Each command gets one lemma that says what a successful run writes and
   which facts about the state made it succeed. These are the only proofs that
   look at the extracted code.
3. The command lemmas are summed up as one statement: a successful command
   writes one of a few shapes of write set. Board and ledger use a
   disjunction; the larger ports use an inductive `Effect` relation and
   `cases` on it, which scales better.
4. Every theorem is then a case analysis over that summary: the permission
   theorem against a policy stated per kind of write, one lemma per kind of
   state change for the invariant, and an induction over `Reachable` to show
   the invariant holds in every state the app can reach. Theorems that need
   the invariant are stated for reachable states, so it is never a free
   hypothesis.
5. `Apply.lean` proves that the kernel's `apply` computes the specification's
   `applyAll`, one loop lemma per table.
6. Scenario theorems run the extracted kernel on small concrete states. They
   show that the guarded behavior actually happens, which rules out a kernel
   that satisfies the theorems by refusing everything, and they build a
   reachable state, which shows the hypotheses of the reachable-state
   theorems can hold.

A past bug is modeled as a second transition function that differs from the
fixed one in one command, and the counterexample is a scenario theorem for
the old function. Confidentiality is stated as noninterference over a `view`
of the state (`examples/tutorials/inbox`, `examples/docs`), and reply
correctness as equality with a specification function
(`examples/conduit`).

## Checks

`cargo i5h-verify` runs the repository's verification checks. It runs the Rust
tests (with `I5H_TEST_DATABASE_URL` set, the PostgreSQL tests too), checks with
`cargo deny` that only `i5h-pg` uses a database driver, re-extracts every
kernel with Charon and Aeneas and fails on any difference, and builds every
proof project while rejecting `sorry`, `native_decide`, `axiom` and any
non-standard axiom in the main theorems. With `--full` it also runs the
mutation suite and the differential test between Rust and Lean. Missing tools
are reported as skipped rather than passed.

The toolchain is stable Rust, elan with Lean v4.31.0, and, for extraction,
Charon and Aeneas at the commit pinned in the proof lakefiles.
