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
kernel and commits its writes in one SERIALIZABLE transaction, and because
application code never receives a database connection, the theorems about the
kernel describe what the running server does.

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
| `crates/i5h-sql`, `i5h-token`, `i5h-json` | shell components that are extracted and proven |
| `examples/tutorials` | step-by-step tutorials |
| `examples/docs` | the document service, the largest example |
| `examples/kellnr`, `examples/atuin` | ports of real authorization code, kernels and proofs only |
| `examples/wastebin`, `examples/conduit`, `examples/cratesio` | ports of real applications, with servers |
| `lean/` | the engine protocol model and the trace checker |

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
panics. The proofs extend to the SQL rows the server writes and reads back, so
the invariants hold for the database and not only for kernel states.

The framework is proven where it can be. The SQL statement planner, the token
parser and encoder, and the JSON writer are extracted and proven. The engine's
retry, idempotency, locking and clock protocol and the outbox dispatcher are
modeled in `lean/`, and traces recorded from the Rust engine are checked
against the model.

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
out. With `EngineConfig::monotonic`, the engine keeps each tenant's latest
commit time in `i5h_clock` and never uses an earlier one, so time never goes
back in commit order within a tenant. The Lean model proves this
(`Engine.times_monotone`), traces record each attempt's time, and
`I5hLib.ReachableT` lets an app prove properties that need it, such as
`started_stays` in the booking tutorial. Other inputs, such as a random slug,
are drawn once per request by the authenticator, so a retry sees the same
value.

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

`cargo i5h-verify` runs the same checks as CI. It runs the Rust tests (with
`I5H_TEST_DATABASE_URL` set, the PostgreSQL tests too), checks with
`cargo deny` that only `i5h-pg` uses a database driver, re-extracts every
kernel with Charon and Aeneas and fails on any difference, and builds every
proof project while rejecting `sorry`, `native_decide`, `axiom` and any
non-standard axiom in the main theorems. With `--full` it also runs the
mutation suite, the differential test between Rust and Lean, and the engine
trace check. Missing tools are reported as skipped rather than passed.

The toolchain is stable Rust, elan with Lean v4.31.0, and, for extraction,
Charon and Aeneas at the commit pinned in the proof lakefiles.
