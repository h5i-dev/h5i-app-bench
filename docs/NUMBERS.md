# Numbers

Measured 2026-09-27. Lines exclude blanks and comments. Hand-written Lean
includes the spec and excludes generated files (extracted kernels,
`Schema.lean`). Rust kernel sizes exclude tests.

## Proof effort per app

| App | Kernel (Rust) | Spec (Lean) | Hand-written Lean | Lean per kernel line |
|---|---|---|---|---|
| `examples/docs` | 936 | 108 | 2,538 | 2.7 |
| `examples/kellnr` | 374 | 71 | 820 | 2.2 |
| `examples/atuin` | 459 | 51 | 527 | 1.1 |
| `examples/wastebin` | 275 | 51 | 720 | 2.6 |
| `examples/conduit` | 1,063 | 127 | 1,682 | 1.6 |
| `examples/cratesio` | 1,030 | 142 | 1,497 | 1.5 |
| tutorial 1, calculator | 114 | 11 | 218 | 1.9 |
| tutorial 2, board | 221 | 45 | 441 | 2.0 |
| tutorial 3, ledger | 180 | 29 | 461 | 2.6 |
| tutorial 4, inbox | 239 | 41 | 580 | 2.4 |
| tutorial 5, booking | 268 | 61 | 644 | 2.4 |
| `examples/filters` | 251 | 55 | 474 | 1.9 |
| `examples/keys` | 204 | 41 | 353 | 1.7 |

Counts include scenarios and upstream-bug counterexamples. Kellnr grew
after 2026-09-26 when its `apply` was extracted and its owner invariant
proven. Upstream Conduit has 1,077 handler lines with inline SQL, about 1.6
Lean lines per handler line.

`examples/filters` and `examples/keys` (2026-09-30) use `for` loops and
the `I5hLib.Iter` specs: each loop proof there is one `i5h_iter` call. The
library grew by 285 lines for them (`Iter`, `Bytes`, `Runs`).

Moving 37 repeated lemmas into `I5hLib` cut app Lean by 486 lines and grew
the library by 258.

Docs also proves noninterference, partial snapshots, migration checks, row
codecs and scoped loads. Its spec, authorization, replies and invariants
alone take 865 Lean lines, about 1.3 per line of the matching kernel code.

Docs features added after the shared library:

| Feature | Kernel | Spec | Proofs |
|---|---|---|---|
| Webhooks and effects | 82 | 17 | 101 |
| Partial snapshots (`read_scope`, `Frame.lean`) | 32 | 0 | 160 |
| Invariant checker (`check_inv`, `Check.lean`) | 167 | 0 | 292 |
| Row encoding (`sql_writes`, `Storage.lean`) | 58 | 40 | 239 |
| Row decoding (`decode`, `Load.lean`) | 61 | 26 | 411 |
| Scoped loads (`scoped_project`, `Scoped.lean`) | 17 | 20 | 211 |

Docs' generated `Schema.lean` (474 lines) includes table operations and
proofs; the app writes 31 lines of `Columns.lean` for two enums.

Shared code:

| Piece | Rust | Lean |
|---|---|---|
| `I5hLib` (loops, tables, lists, scalars, SQL and store semantics, tactics) | none | 1,310 |
| `i5h-sql` (planner) | 141 | 118 |
| `i5h-token` (token parser and encoder) | 197 | 963 |
| `i5h-json` (reply writer) | 207 | 427 |
| `Schema.lean`, generated for docs | none | 474 |

## Checks

| Check | Result |
|---|---|
| `scripts/mutants.py` | 22 of 22 kernel bugs break a proof |
| `scripts/mutants-apps.py` | 12 of 12 compiling kernel bugs break a proof |
| `scripts/difftest.sh` (Rust vs Lean) | 5,000 random cases per run agree (55,000 in one longer run); every outcome kind hit |
| Axioms | only `propext`, `Classical.choice`, `Quot.sound` |
| Extraction drift (CI) | every kernel and extracted crate re-extracted and compared |

## Time

On a 128-core machine:

| Step | Time |
|---|---|
| Clean `lake build` of docs proofs (Mathlib cached) | 87 s |
| `cargo i5h-verify`, incremental | about 5 min |
| Docs mutation suite, 3 jobs | 13 min |

## Bugs found

| Where | What | How |
|---|---|---|
| i5h engine | idempotency keys per tenant only; one user could get another's reply | PostgreSQL test; keys now per app-defined scope |
| i5h engine | stale snapshot under the tenant lock | fault and concurrency tests; lock now taken before `BEGIN` |
| Kellnr (before PR #1243) | read-only session could add crate owners | read-only theorem fails; Lean gives the counterexample |
| Atuin (issue #3297, open) | a session alone can delete the account | proven for current rules; fix proven to need the password |
| i5h engine | apps sharing a database shared tables, keys and outbox; one dispatcher killed another's effects | example tests; one PostgreSQL schema per app |
| Wastebin (before 632ddf2, issue #190) | link preview GET burned a burn-after-reading paste | `preview_broken` counterexample; `preview_fixed` for current code |
| Wastebin (current) | `/raw`, `/dl`, `/md` still burn a paste on GET | `raw_link_burns` |
| Conduit (issue #16, open) | `favorited` means "favorited any article" | `upstream_violates_reply_spec` |
| Conduit (unreported) | `?favorited=` lists every article once the user favorited one | `favorited_filter` |
| crates.io (before PR #14760) | a locked account could sign in | `pre14760_violates_lock` |
| crates.io (current) | the emailed invitation link skips the lock check; a locked user can become owner | porting; `examples/cratesio/README.md` |
