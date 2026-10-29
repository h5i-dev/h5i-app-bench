# OxiCloud policy coverage expansion (2026-10-29)

The expansion adds 15 canonical property targets while preserving all previous
390 targets and their statements. OxiCloud now selects 26 properties. All six current gates and extractions match
their source fingerprints: **405/405 selected properties**, **10,098 current
source-matched executable upstream lines**, and zero historical fallback.
OxiCloud increases from **751 to 947 lines (+196)**; the other applications stay
at ArtifactKeeper 1,504, Kanidm 2,705, Nora 987, RustFS 2,000 and Tuwunel 1,955.
The 20,000-line objective remains open.

## Scope

Two small Rust modules model typed policy resolution, five allow/refuse guards,
canonical knob order, applicability to drive kinds, typed values, strictness
comparison, and ordered detection of policies weaker than defaults. In
particular, index opt-in flags are false-stricter, and a finite expiry cap is
stricter than no cap. The comparison specification also proves transitivity.

The modules and checked proofs are adapted from the existing `oxicloud-verify`
branch at `61cd60e`; unrelated work there is excluded. Lean is regenerated using
the official extraction command. Every new public root is named explicitly in
both the manifest and extraction script. Existing roots and targets remain.

The [source mapping](../harness/source-mappings/oxicloud.json) adds 14 exact
qualified declarations mapped to immutable source items at upstream revision
`8c0dd334cf065ad11f60f9be24e2aafd5dda7550`. Coverage unions physical executable
line numbers across all properties, including shared dependencies. Existing
external-sharing coverage is therefore counted once. Extraction roots and proof
body references alone receive no credit.

## Validation

The [full gate](../results/project-checks/20261029T112130702994Z/summary.json)
passes all 26 selected targets and audits 543 theorems in 17 modules against
only `propext`, `Classical.choice` and `Quot.sound`. The independent
[extraction check](../results/project-checks/20261029T112130706319Z/summary.json)
passes with unchanged inputs. [Per-target reach](../results/source-coverage/oxicloud-project-reach.json)
and [dashboard data](../../docs/prove/data/index.json) record the exact totals.

The standalone [differential harness](../ports/oxicloud/policy-difftest/README.md)
compiles the entire pinned upstream `drive.rs` unchanged. Two deterministic
10,000-case comparisons and the upstream unit tests pass: [16 tests total](../results/project-checks/20261029T112130702994Z/policy-difftest.log). The
harness preserves upstream serde and tracing calls; only subject representation
and unsupported-operation error construction/display are adapted.

Accounting and original-statement preservation tests pass (8 + 2 + 1 tests).
The formal kernel does not model JSON/string decoding, audit output, error
messages or UUID representation. Vector-returning specifications retain their
successful-execution hypotheses. See [deviations](../ports/oxicloud/DEVIATIONS.md).
This metric is source dependency reach for proved modeled operations, not a
proof of equivalence of every upstream line or the complete application.
