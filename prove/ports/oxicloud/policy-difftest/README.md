# Pinned policy comparison

Run from the repository root:

```sh
cargo test --manifest-path prove/ports/oxicloud/policy-difftest/Cargo.toml
```

Requires the benchmark's bare repository `prove/results/upstream/oxicloud.git`
containing revision `8c0dd334cf065ad11f60f9be24e2aafd5dda7550`. `build.rs`
uses `git show` to compile the complete upstream `src/domain/entities/drive.rs`
unchanged. This avoids the unrelated application/database dependency tree.

The harness adapts only `Subject` and unsupported-operation error construction
and display. Actual policy decisions, JSON/serde types and tracing calls are
upstream code. Formal statements concern typed policy inputs and decision
results, not JSON parsing, audit output or message equivalence.

Two deterministic 10,000-case differential tests cover override precedence,
expiry boundaries, five guards, both drive kinds, every known knob, an unknown
knob, ordered drift findings, and true/false/smaller strictness directions.
Upstream unit tests are also compiled and run (16 tests total).
