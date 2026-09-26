# i5h (icefish)

## CI

`.github/workflows/ci.yml` runs three jobs:

- `rust`: build, workspace tests against Postgres 17 (a skipped database test
  fails the job), and `cargo deny check bans` (only `i5h-pg` may use a DB driver).
- `lean`: `lake build` in `examples/docs/proofs`, then
  `scripts/ci-lean-gate.sh`: no `sorry` or `native_decide`, and the main
  theorems use only `propext`, `Classical.choice`, `Quot.sound`.
- `extract`: builds Charon and Aeneas at the pinned commit with Nix, re-runs
  `scripts/extract.sh`, and fails if `DocsKernel.lean` changes.

Run the gate locally after `lake build`: `scripts/ci-lean-gate.sh`.
