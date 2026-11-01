# Complete Nora sidebar accepted: 42,773 lines

Baseline: 563c532, 42,502 accepted deduplicated pinned executable source lines
and 1,173 canonical properties. This checkpoint adds 271 measured lines and
one property, reaching 42,773 lines and 1,174 properties. The 100,000-line goal
remains active with 57,227 lines remaining. The dashboard is refreshed locally;
this checkpoint does not publish or deploy it.

## Scope

The complete pinned Nora sidebar function is mapped at
nora-registry/src/ui/components.rs:127–417, revision
f864a9a95e8669b00202c18b0b774ab0fc2e56cc. The property proves pure kernel
termination and every decoded output byte against an independent four-template
model, for arbitrary active-page bytes, translation fields, registry membership,
authentication choice and version bytes. Navigation order, active classes,
fill/stroke/icon bytes, whitespace, section suppression and caller text are
retained. See the production DEVIATIONS.md for exact caller adapters, version
1.3.2 binding, fragment output representation and allocation-model limits.
No helper, carrier definition or icon constant receives independent line credit.
Nora now contributes 1,948 deduplicated source lines and 59 canonical properties.

## Validation

- Production canonical proof and axiom gate PASS, inputs unchanged:
  results/project-checks/20261101T171422827047Z/nora.log.
  1,556 theorems in 35 modules, only propext, Classical.choice and Quot.sound.
- Fresh extraction reproducibility PASS, inputs unchanged:
  results/project-checks/20261101T171422827386Z/nora.log.
- All six applications retain fresh passing canonical and extraction records.
- Deterministic regeneration of all five source artifacts PASS. The unchanged
  pinned body and all icon constants compile as the reference; complete output
  agrees on 135,160 cases, including all 65,536 registry subsets with both
  authentication states, None/empty selections over 22 active IDs, and 4,000
  arbitrary Unicode/control-character cases. Rerun by invoking
  `python3 prove/harness/nora_sidebar.py audit --port prove/ports/nora`.
- All eight existing kernel Rust tests PASS; all 19 harness tests PASS.
- All 1,173 prior canonical theorem statements remain unchanged.
- Source accounting, project details and the local dashboard agree. Benchmark
  accounting remains 99 accepted tasks out of 101; benchmark credit is unchanged.
- accept.py rechecks fresh evidence and source/reference regeneration before
  writing accepted-checkpoint.json. See acceptance.log for the successful run.

The preliminary probe and staged proof logs are retained as preparation evidence;
only the production gate and measured dashboard reach establish acceptance.
