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
| `examples/kellnr`, `examples/atuin` | ports of real authorization code |
| `lean/` | the engine protocol model and the trace checker |

Each proof project (`*/proofs`) keeps generated Lean in `generated/`, which
holds the extracted Rust and the `schema!` output, and keeps the hand-written
specifications and proofs at the top level. The generated files are a separate
Lean library with its own `srcDir`, so module names do not change.

## Proofs in this repository

The document service in `examples/docs` has projects, members and a review
workflow. For every actor, reachable state and command, Lean checks that each committed
write is allowed by the policy table (including the four-eyes rule), that
replies contain only documents the caller may read, and that every reachable
state keeps its invariants. It also checks that a user's result, including
error codes, depends only on what that user may see, that webhooks go only to
the destination a project registered, that a command's result depends only on
one project's rows (so the server loads only those), and that the kernel never
panics. The proofs extend to the SQL rows the server writes and reads back, so
the invariants hold for the database and not only for kernel states.

The framework is proven where it can be. The SQL statement planner, the token
parser and encoder, and the JSON writer are extracted and proven. The engine's
retry, idempotency and locking protocol and the outbox dispatcher are modeled
in `lean/`, and traces recorded from the Rust engine are checked against the
model.

Two ports test the approach on real code. `examples/kellnr` models Kellnr's
authorization before and after PR #1243; Lean proves that the fixed code keeps
read-only users from changing anything, and it produces a concrete
counterexample for the old code. `examples/atuin` ports the account and record
rules of the Atuin sync server, proves user isolation and clean account
deletion, and shows that the current code lets a session delete an account
without the password (issue #3297).

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
