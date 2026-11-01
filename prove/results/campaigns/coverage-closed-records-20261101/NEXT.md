# Continue toward 100k

The baseline before this batch is 42,773 accepted lines / 1,174 properties.
The closed-record backend supplies complete field models rather than a field
subset. Keep all admission restrictions unless a new case gets a complete model,
unchanged-body reference validation, extraction and proof/axiom gates.

Potential extension: constructors with explicit primitive/String/Option/Vec
parameters and literal full record initializers can support universal projection
properties. The present backend admits closed constructors only. Do not count
parameterized constructors using finite fixtures as a substitute for proof over
all inputs. Nested defaults and floating-point fields remain unsupported.

The follow-up string-match survey finds 28 ArtifactKeeper candidates (1,328
inventory lines), eight OxiCloud (439), six Nora (439), two Kanidm (164), one
RustFS (38) and one Tuwunel (43). These are heuristic candidates, not available
coverage: many are XML writers, version parsers, regex scanners or page renderers.
Temporary complete sources are /tmp/h5i-string-match-APP.json; regenerate from the
pinned inventory and bare repos if absent. ArtifactKeeper core_handler_metadata
(formats/mod.rs, 61 inventory lines) is a direct total string lookup returning a
name, description and extension slice, with the original key as fallback. Its
unknown-key branch is observable and must be proved over arbitrary inputs.

Several apparent string lookups call Rust str::to_lowercase. Replacing that with
ASCII lowercase changes behavior: U+212A KELVIN SIGN lowercases to ASCII k.
A future parser backend must retain Unicode behavior (including contextual
lowercasing) or prove an exact preimage model for its complete ASCII key set;
ASCII-only fixtures cannot justify whole-function coverage. Nora registry type
parsing also has multiple aliases per variant; preserve all of them.

Nora directory/page rendering and Kanidm idx_diff/merge_state remain larger
candidates; previous campaign coverage-sidebar-20261101/NEXT.md records their
sorting, duplicate-key, iteration-order and assertion fidelity requirements.

## Parametric forwarding experiment completed during this checkpoint

A syn 2 parser in `/tmp/h5i-forward-ast` checked full named carrier fields,
matching source parameter/field types, exactly one occurrence of each parameter,
no other statements or calls, and inert declaration/context attributes. It
admitted 142 constructors: OxiCloud 87 (504 inventory lines), ArtifactKeeper 45
(173), Nora 4 (12), Kanidm 2 (20), Tuwunel 4 (6). These 715 inventory lines are
not accepted or dashboard totals; deduplication and executable accounting remain.

The isolated `/tmp/h5i-forward-large` Rust generic carriers and all 142 universal
Lean projection/termination proofs compile. Each opaque input becomes a separate
type variable; every source field is preserved, and every parameter is moved
exactly once. This avoids inventing behavior for database or Arc inputs because
the admitted source never inspects them. Original concrete field/parameter types
must match before generalization. Unknown attributes, conditionally compiled
contexts and incomplete carriers were rejected. This is still an experiment:
production integration, compiled retained-body reference comparisons, audited
reproducibility, current mapping exclusions and all production gates remain.

The parser and source snapshots are temporary; retain and test the parser in the
next campaign before relying on it. `/tmp/h5i-forward-admitted-APP.json` holds
source rows plus AST metadata. `/tmp/h5i-forward-ast-APP.jsonl` holds parser output.
Lean reserved identifiers such as `name` and `local` require escaping. A future
admission extension can add fully modeled literal fields alongside inputs; never
replace helpers or effectful initialization with opaque fixture constants.

The 142 experimental generic carriers also passed retained-body reference checks
with eight distinct-token fixtures each (all fields). Artifacts:
`/tmp/h5i-forward-large/reference.rs`, compiled `reference`,
`proofs/Forward.lean`, and `proofs/generated/ForwardKernel.lean`.
The reference retains each exact initializer body under a generalized signature;
the kernel replaces its record path Self with the matching carrier name. No
reference result or fixture substitutes for the universal Lean properties.

The closed-record integration now replaces only its own bounded namespace block,
preserving any theorem wrappers appended later. Its earlier truncation to EOF
would have removed new forwarding wrappers during a subsequent audit. The current
checkpoint audits confirm byte-identical regeneration of all existing blocks.

A follow-up AST survey of zero-argument Value-returning functions in files with
json! macros found only six additional ArtifactKeeper candidates (139 inventory
lines) and two OxiCloud (59). Most promising are artifacts_index_body (71) and
repositories_index_body (47); source purity and complete reference closure remain
to check. Files: `/tmp/h5i-json-roots-APP.json`. Other apps had none under this
strict signature. This is a heuristic survey, no accepted source credit.
