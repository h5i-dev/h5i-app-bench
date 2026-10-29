# Existing totality proofs (2026-10-29)

This follow-up completes the existing Nora, Kanidm and Tuwunel property sets.
The configured theorem lists (31, 36 and 17 targets) and their statements are
unchanged. In particular, Tuwunel retains its existing quartic relation-count
precondition; this work does not assert unconditional totality.

## Proof changes

Nora composes middleware branches through intermediate postconditions and
reduces only the current computation head, avoiding expansion of large shared
continuations.

Kanidm shares derived instances across proof modules, proves bounds for
migration/protected attribute construction, and reuses these bounds in effective
permission and deny-override proofs. The extraction roots retain every public
function of softlock, schema tags, credential commit and account policy, plus
the existing access root. This excludes unused derived formatting/equality
implementations that generated three opaque axioms. Regeneration removes 95
trait declarations; all 345 retained declaration bodies are unchanged. The
Rust implementation and configured proof targets are unchanged.

Tuwunel composes checked timeline, visibility, message, relation-walker and
route lemmas. Its invariants track valid PDU indices through vectors and
preserve queue-capacity bounds. Pagination tokens are joined before checking
continuations, avoiding repeated expansion of entire routes. The existing proxy
empty-include check uses the equivalent `len() == 0` expression so extraction
uses the defined vector-length model instead of an opaque `is_empty` axiom.
Both proxy extraction roots are retained. A differential check against pinned
upstream methods passes all [300,511 decisions](../results/project-checks/20261029T061611259345Z/proxy-policy.log).

## Verification evidence

| Application | Targets | Checked theorems / modules | Gate | Extraction |
| --- | ---: | ---: | --- | --- |
| Nora | 31 | 763 / 30 | [pass](../results/project-checks/20261029T044045192059Z/summary.json) | [pass](../results/project-checks/20261029T044055035115Z/summary.json) |
| Kanidm | 36 | 1,318 / 29 | [pass](../results/project-checks/20261029T052424830577Z/summary.json) | [pass](../results/project-checks/20261029T052426438787Z/summary.json) |
| Tuwunel | 17 | 1,614 / 27 | [pass](../results/project-checks/20261029T061611259345Z/summary.json) | [pass](../results/project-checks/20261029T061611362186Z/summary.json) |

All six passing records above have unchanged source inputs. All three full
builds and axiom gates pass; no additional axioms, admitted proofs, or relaxed
gate settings are used. The permitted kernel axioms are `propext`,
`Classical.choice` and `Quot.sound`.

## Source coverage accounting

The historical benchmark snapshot is separate from source-matched project
verification. Passing project gates replace overlapping historical counts;
their line counts are never added together. Kanidm currently has a partial
source mapping, and Tuwunel has no project source mapping, so completing these
proofs alone does not establish a 10,000-line source-matched total. The current
exact mapped total is **5,662 lines**, up **1,407** from 4,255. This includes
Nora at 987 and Kanidm at 420 (partial mapping); Tuwunel currently adds no
source-matched project lines. The separate historical benchmark remains
7,684 lines (99/101 tasks). The compatibility total of 7,528 mixes current
project evidence with historical evidence and must not be labeled a current
whole-project verified count.

## Additional checks

Statement preservation: `test_statements.py` (1 test). Exact reach accounting:
`test_project_reach.py` (8 tests), `test_dashboard_accounting.py` (2 tests).
All pass. The configured theorem lists match the previous commit exactly.
Every public function in Kanidm's four added extraction modules remains an
extraction root.
