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

The [coverage recount](COVERAGE_RECOUNT.md) completes the missing core Kanidm
and Tuwunel source mappings. All six current gates and extractions match their
source inputs: **405/405 configured targets**, with **10,098 deduplicated pinned
upstream executable lines** reached through theorem types and generated
implementation dependencies. Kanidm contributes 2,705 and Tuwunel 1,955.
The [OxiCloud policy expansion](OXICLOUD_POLICY_EXPANSION.md) subsequently adds
15 targets and 196 lines (751 → 947); the pre-expansion recount was 9,902 lines.
The previous 5,662 total omitted Kanidm's core mapping and all Tuwunel mapping;
the increase of 4,240 is an accounting correction, not new proof expansion.

Historical fallback is now zero. The historical benchmark remains separate at
7,684 lines and 99/101 task/model results. It overlaps the project coverage and
must not be added. The dashboard's `whole_project_verified` flag now means all
configured project gates have current source-matched mapping evidence; neither
that flag nor the line count asserts complete upstream behavioral equivalence.

## Additional checks

Statement preservation: `test_statements.py` (1 test). Exact reach accounting:
`test_project_reach.py` (8 tests), `test_dashboard_accounting.py` (2 tests).
All pass. The Nora, Kanidm and Tuwunel theorem lists remain unchanged.
OxiCloud retains its previous 11 and adds 15 policy targets.
Every public function in Kanidm's four added extraction modules remains an
extraction root.
