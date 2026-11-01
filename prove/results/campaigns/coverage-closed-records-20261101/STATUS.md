# Accepted checkpoint: complete closed record constructors

Accepted source: **42,975 lines / 1,197 canonical properties**.

This adds 202 deduplicated pinned executable source lines and 23 properties to
2731f10 (42,773 lines / 1,174 properties). Every previous canonical theorem
statement is unchanged. The 100,000-line goal remains active; 57,025 lines remain.

| Application | Accepted source lines | Canonical properties |
| --- | ---: | ---: |
| artifactkeeper | 2,122 | 99 |
| kanidm | 31,103 | 545 |
| nora | 1,959 | 61 |
| oxicloud | 3,794 | 198 |
| rustfs | 2,000 | 270 |
| tuwunel | 1,997 | 24 |

The new batch covers 16 OxiCloud constructors (+149 lines), five ArtifactKeeper
constructors (+42), and two Nora constructors (+11). All 110 returned fields and
successful termination are stated. Carrier and enum definitions receive no
independent source credit. These properties describe constructor outputs, with
no claim about runtime configuration loading or enforcement by callers.

Validation:

- Full proof and axiom gates passed for all changed applications: OxiCloud
  2,914 theorems / 36 modules; ArtifactKeeper 1,578 / 25; Nora 1,564 / 36.
- Extraction reproducibility passed for all three changed applications.
- All six applications retain fresh successful gates and extraction evidence.
- All 23 retained pinned constructor bodies compiled and every field matched.
- Byte-identical regeneration passed for each application.
- The retained syn attribute audit checked enclosing scopes and local method
  attributes: only documentation and lint settings occur for these 23 roots.
- All 23 harness tests passed, including preservation of later canonical
  theorem blocks during constructor regeneration.
- All 1,174 baseline canonical property statement types are unchanged.

The dashboard is refreshed locally. Benchmark accounting remains 101 tasks /
99 accepted. Nothing was deployed.

The next experiment has 142 complete forwarding constructors (715 inventory
lines, not accepted coverage), universal Lean proofs and eight retained-body
reference fixtures each. Production integration and gates remain. See NEXT.md.
