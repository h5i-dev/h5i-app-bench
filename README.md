# i5h (icefish)

A Rust web framework where the part that decides who may do what is proven
correct in Lean 4.

An i5h app has two halves:

- a **kernel**: one pure function `transition(actor, snapshot, command) ->
  (writes, reply)`, written in plain Rust that [Aeneas](https://github.com/AeneasVerif/aeneas)
  translates to Lean. Permission checks and business rules live here, and the
  theorems are about this translated code.
- a **shell**: axum routes, authentication, PostgreSQL. The shell loads the
  caller's tenant snapshot, runs the kernel, and commits the writes in one
  SERIALIZABLE transaction. App code never gets a database handle.

```
HTTP (axum) ──► Actor<K> ──► I5h::respond ──► Engine: BEGIN, load, transition, write, COMMIT
                                                              │
                                                  kernel (Rust) ══ Aeneas ══► Lean proofs
```

## What is proven

For the example app in `examples/docs` (projects, members, documents with a
review workflow), for every actor, state and command:

- every committed write is allowed by the policy table, including the
  four-eyes rule and the status workflow;
- replies contain only documents the caller may read;
- every reachable state keeps its invariants (an owner per project, valid
  references, unique keys, approver rules);
- noninterference: a user's result, including error codes, depends only on
  what that user may see;
- effects (webhooks) go only to the destination the project registered,
  and only when a writer publishes an approved document;
- the kernel never panics.

The shell is proven where it can be: the SQL statement planner
(`crates/i5h-sql`), the token parser and encoder (`crates/i5h-token`), the JSON
reply writer (`crates/i5h-json`), and a model of the engine's retry and
idempotency protocol (`lean/`), which engine traces are checked against.
[`docs/TRUST.md`](docs/TRUST.md) lists what is proven, what is enforced by
structure, and what is still trusted.

`examples/kellnr` applies this to a real bug: Kellnr's authorization before and
after PR #1243. Lean proves the fixed code keeps read-only users from changing
anything, and proves the old code wrong with a concrete counterexample.

## Layout

| Path | Contents |
|---|---|
| `crates/i5h` | `Kernel` trait, in-memory reference engine, proof library `I5hLib` |
| `crates/i5h-pg` | PostgreSQL engine: tenant-scoped snapshots, retries, idempotency, role lockdown |
| `crates/i5h-http` | axum integration: `Actor` extractor, `I5h::respond`, `rpc_router` |
| `crates/i5h-sql`, `i5h-token`, `i5h-json` | extracted and proven shell pieces |
| `examples/docs` | example kernel, server, and proofs |
| `examples/kellnr` | Kellnr authorization port |
| `lean/` | engine protocol model and trace checker |
| `docs/` | [`ROADMAP.md`](docs/ROADMAP.md), [`TRUST.md`](docs/TRUST.md), [`TARGETS.md`](docs/TARGETS.md) |

## Running the example

```
docker run -d -p 127.0.0.1:55432:5432 -e POSTGRES_USER=i5h -e POSTGRES_PASSWORD=i5h postgres:17
export DATABASE_URL=postgres://i5h:i5h@127.0.0.1:55432/i5h I5H_SECRET=dev-secret
I5H_ISSUE=1:1 cargo run -p docs-server        # prints a token for org 1, user 1
cargo run -p docs-server                      # serves on 127.0.0.1:8080
curl -H "Authorization: Bearer <token>" -d '{"cmd":"create_project","name":"p"}' localhost:8080/rpc
```

## Verifying

`cargo i5h-verify` runs the same checks as CI:

- Rust tests (set `I5H_TEST_DATABASE_URL`),
- `cargo deny check bans` (only `i5h-pg` may use a database driver),
- re-extraction of every kernel with Charon and Aeneas, failing on drift,
- `lake build` of every proof project, rejecting `sorry`, `native_decide`
  and `axiom`, and checking that the main theorems use only Lean's standard
  axioms.

`cargo i5h-verify --full` adds:

- the mutation suite (injected kernel bugs must break a proof),
- the Rust-vs-Lean differential test,
- the engine trace check.

Toolchain: Rust stable, [elan](https://github.com/leanprover/elan) (Lean
v4.31.0), and for extraction Charon and Aeneas at the commit pinned in the
proof lakefiles. Tools that are missing are reported as skipped, not passed.
