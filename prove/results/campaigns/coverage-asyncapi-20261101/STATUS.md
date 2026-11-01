# OxiCloud complete closed AsyncAPI schemas

Baseline: `b4a88b8`, 41,603 accepted deduplicated pinned executable lines and
1,140 canonical properties. Target: at least 100,000 accepted lines.

This candidate selects 33 complete zero-argument schema builders from pinned
OxiCloud revision `8c0dd334cf065ad11f60f9be24e2aafd5dda7550`. It retains 37
unchanged function bodies and the unchanged error-code constant module for
reference evaluation. Four parameterized helpers receive no separate source
mapping or input-domain claim. `main` and `build_asyncapi` are excluded because
they depend on filesystem or build-environment inputs.

The executable representation is complete compact UTF-8 JSON with sorted object
keys, serialized by serde_json 1.0.154. Each returned fixed-size array contains
bounded byte fragments; flattening it gives the entire JSON output. Independent
Lean reference models use different fragment boundaries. Models do not establish
that a browser/client/server implements the behaviors described by schema text.

The disposable importer passes all 33 closed-domain byte comparisons, exact
source/hash checks, deterministic regeneration, extraction and generated Lean
compilation. Its complete proof module is running. A smaller prototype already
passes the largest value's complete output proof. These are preparation only.
Production source coverage remains unaccepted until all canonical gates pass.

Reproduce from the repository root:

```sh
python3 prove/harness/oxicloud_schemas.py audit --port prove/ports/oxicloud
python3 prove/results/campaigns/coverage-asyncapi-20261101/prior-statements.py
python3 prove/harness/project_checks.py check --app oxicloud --timeout 3600
python3 prove/harness/project_checks.py extract-check --app oxicloud --timeout 1800
python3 prove/harness/dashboard.py docs/prove/data --refresh-project-checks
python3 prove/results/campaigns/coverage-asyncapi-20261101/accept.py
```

The complete disposable 33-root Lean proof module PASSES (all shared
fragment lemmas, independent model bridges and complete output theorems).
Production integration and deterministic reference audit pass; all 1,140
baseline theorem statements remain unchanged. Production extraction is running
before the first complete project gate. No source coverage is accepted yet.

Production extraction and its independent fresh reproduction pass. All 27
kernel Rust tests pass. The full project build compiles the complete new proof
module; the gate is now scanning theorem dependencies and elaborated catalog
entries. The initial harness run predates dashboard refresh and reports the
expected missing 33 new property details; retain that log and rerun after the
matching gate and dashboard refresh. Coverage remains unaccepted meanwhile.

Final production gate `20261101T163334659561Z` PASSES: 2,861 theorems
in 35 modules use only propext, Classical.choice and Quot.sound; the source
axiom scan passes. Fresh extraction `20261101T163335853573Z` also passes.
Dashboard regeneration and final measured accounting are in progress.

ACCEPTED checkpoint: 42,502 deduplicated pinned executable source lines and
1,173 canonical properties, an increase of 899 lines and 33 properties.
All six applications have fresh passing gates and extraction checks. The final
19 harness checks pass after dashboard regeneration. All 1,140 baseline
canonical statements are unchanged. The final acceptance script reruns the
pinned-source, deterministic-generation and exhaustive closed-domain byte audit.
The OxiCloud kernel Rust suite passes all 27 tests. No generated/helper lines
or parameterized helper source bodies receive independent coverage credit.

`accepted-checkpoint.json` records actual measured totals and evidence paths.
57,498 accepted lines remain to reach 100,000. The target remains active. The
local dashboard is refreshed; it has not been deployed.
