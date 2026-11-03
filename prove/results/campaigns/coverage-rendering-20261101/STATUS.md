# Nora complete rendering campaign

Baseline: `78b23b8`, 41,414 accepted deduplicated pinned executable lines and
1,133 canonical properties. Target: at least 100,000 accepted lines.

This candidate batch selects seven complete pinned Nora functions. Rust tests
compare whole output against unchanged upstream bodies. All prior canonical
statements must remain unchanged. Candidate output and test volume do not count
as accepted source coverage. Consult `accepted-checkpoint.json` only after all
proof, axiom, extraction and dashboard checks pass.

Reproduce from the repository root:

```sh
python3 prove/harness/nora_rendering.py audit
python3 prove/results/campaigns/coverage-rendering-20261101/prior-statements.py
cargo test --manifest-path prove/ports/nora/kernel/Cargo.toml
python3 prove/harness/project_checks.py check --app nora --timeout 3600
python3 prove/harness/project_checks.py extract-check --app nora --timeout 1800
python3 prove/harness/dashboard.py docs/prove/data --refresh-project-checks
python3 prove/results/campaigns/coverage-rendering-20261101/accept.py
```

The generator, complete-output models and primitive proof template are the
reproduction path. Capacity hypotheses bound full output length by `usize`.
HTML escaping matches five ordered replacements; percent encoding operates on
UTF-8 bytes. Returned JavaScript text does not establish browser behavior.

The initial full gate (`20261101T144810553252Z`) passed the other renderers but
exceeded the simplifier limit in the header proof. The revised header kernel
folds its literal substitutions for each of the three language choices. Its
independent Lean model still retains the template pieces. Exhaustive header
comparisons and 4,000 additional independently selected-field comparisons pass.
The first folded form used one large array per language; gate
`20261101T151214844182Z` exceeded the generated array proof's recursion limit.
The current form splits each folded output into bounded literal chunks.
Fresh extraction `20261101T152125749512Z` passed for the bounded form.
The subsequent gate `20261101T152125751204Z` passed the other new renderer
proofs, but the header theorem exceeded Lean's 10,000,000-heartbeat limit at
`whnf`. This batch remains unaccepted. A complete passing gate and fresh
extraction evidence for the final proof sources remain required.

The next revision gives each shared bounded header fragment its own complete
output lemma, then composes those lemmas and proves equality with the independent
template model. The model bridge passes in a disposable prototype. The revised
kernel's Rust suite passes; its complete project gate remains pending. Helpers
receive no separate upstream source credit.

Gate `20261101T160303278652Z` built every proof successfully and checked 984
theorems against the permitted axioms, then rejected an unused `MaybeUninit`
axiom emitted by extraction. A small isolated extraction identifies the encoder
`vec!` expressions as the cause. Equivalent array-to-vector expressions remove
the declaration in that probe; the complete candidate must be extracted and
gated again before acceptance.

The final array-to-vector encoder revision extracts without any axiom
declarations. Its Rust suite and isolated encoder proofs pass. Fresh extraction
`20261101T161852131573Z` passes; the matching full gate
`20261101T161850938594Z` is running. All 1,133 prior canonical statements remain
unchanged. No new coverage is accepted until the matching full gate passes.

Final gate `20261101T161850938594Z` PASSES: all proof modules build,
984 theorems in 34 modules use only `propext`, `Classical.choice`, and
`Quot.sound`, and the source axiom scan passes. The matching fresh extraction
`20261101T161852131573Z` also passes. Dashboard refresh and final accounting
checks are the remaining checkpoint steps.

ACCEPTED checkpoint: 41,603 deduplicated pinned executable source lines and
1,140 canonical properties, an increase of 189 lines and seven properties.
All six applications have fresh passing gates and extraction checks. All 19
source-reach/dashboard/project-check tests pass. All 1,133 baseline statements
are unchanged. `accepted-checkpoint.json` records the measured counts and
evidence paths. 58,397 accepted lines remain to reach 100,000. The local
dashboard is refreshed; it has not been deployed.
