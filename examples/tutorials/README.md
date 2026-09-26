# Tutorials

Each tutorial builds a complete web application with i5h and then proves it
correct in Lean 4, one step at a time. The tutorials build on each other, so
start with the first one.

| Tutorial | Application | Topics |
|---|---|---|
| [1. Calculator](calculator/TUTORIAL.md) | a calculator with one memory per user | the kernel and the shell, extraction, specifications, proofs about loops |
| 2. Bulletin board | posts, edits and moderation | permissions, invariants and reachable states |

Every tutorial runs with one PostgreSQL container and `cargo run`, and its
proofs are checked by `cargo i5h-verify` and CI in the same way as the rest of
the repository.
