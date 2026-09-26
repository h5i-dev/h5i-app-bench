# Proofs for the document service

These are Lean 4 proofs about the Rust kernel in `../kernel`, as translated by
Charon and Aeneas. The files in `generated/` are produced by tools and never
edited: `DocsKernel.lean` comes from `scripts/extract.sh` and `Schema.lean`
from `schema!`. Everything else is written by hand.

## Files

| File | Contents |
|---|---|
| `Spec.lean` | The specification to review: the policy table, the meaning of a write set on lists, the invariants, authorization of effects, and what each user may see. |
| `Columns.lean` | The SQL encoding of the application's own column types, `Role` and `Status`. |
| `Lemmas.lean`, `Transition.lean`, `Apply.lean` | Specifications of the kernel's helpers and of `apply`, mostly by way of the loop lemmas in `I5hLib`. |
| `Theorems.lean` | Totality, authorization and reply confinement. |
| `Invariants.lean` | The invariants hold in every reachable state. |
| `Noninterference.lean` | A user's result depends only on what that user may see. |
| `Frame.lean` | A command's result depends only on the rows its scope names. |
| `Check.lean` | The invariant checker used by migrations is exact. |
| `Storage.lean`, `Load.lean`, `Scoped.lean` | The rows the server writes and reads back. |

## Theorems

The following hold for every actor, snapshot and command.

| Theorem | Statement |
|---|---|
| `allows_eq` | The kernel's permission table is the one in the specification. |
| `transition_total` | The kernel never fails, so it never panics, overflows or indexes out of bounds. |
| `apply_eq` | `apply` computes the meaning of a write set that the database must implement. |
| `authorized` | Every write of a successful command is allowed by the policy, judged against the state before the command, including the four-eyes rule and the status workflow. An effect goes only to the destination its project registered, and only when a writer publishes an approved document. |
| `reply_confined` | Replies contain only documents the caller may read. |
| `inv_preserved`, `reachable_inv` | Every reachable state has an owner for each project, valid references, unique keys and fresh ids, and it satisfies the four-eyes rule; a document names an approver exactly when it is approved or published. |
| `noninterference` | Two states that look the same to a user give that user the same result, including error codes. The id counter is a declared exception. |
| `transition_frame` | A command's result depends only on the counter and one project's rows, which is why the server loads only those. |
| `check_inv_spec` | `check_inv` returns true exactly when the invariants hold, so migrations can refuse changes that break one. |
| `sql_writes_stored` | When the tenant's rows hold a valid state, running the statements the server plans for a write set leaves exactly the rows of the new state, under the PostgreSQL meaning of upsert and delete. |
| `fresh`, `load_sound`, `store_sound` | An empty tenant holds a valid state, loading rows in any order decodes to a valid state that the rows hold, and storing the writes of any successful command keeps it that way. As a result, the invariants hold for the database itself. |
| `scoped_sound`, `scoped_command` | The server's scoped loads decode to exactly the slice that `transition_frame` talks about, so storing the resulting writes keeps the database valid as well. This assumes that each table has at most `usize::MAX` rows. |

Every theorem depends only on Lean's standard axioms (`propext`,
`Classical.choice` and `Quot.sound`), which `scripts/ci-lean-gate.sh` checks.

## Building the proofs

```
lake exe cache get
lake build
../../../scripts/ci-lean-gate.sh      # rejects sorry and non-standard axioms
../../../scripts/mutants.py           # injected bugs must break a proof
```

The generic lemmas come from `I5hLib` in `crates/i5h/proofs`. `loop_search`
and `loop_fold` turn a fact about one step of an extracted loop into a fact
about the whole loop, and `walk` and `i5h_step` step through extracted code.
