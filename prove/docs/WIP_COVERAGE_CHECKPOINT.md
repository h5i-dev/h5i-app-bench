# WIP: upstream coverage expansion checkpoint

Expansion stopped on 2026-10-28 at the user's request. This commit preserves both sessions' code, extracted Lean, partial proofs, differential runners, and verification evidence. It is not a claim that the current whole tree passes formal verification.

Reported pinned-upstream dependency reach: **9,296 lines**, versus baseline **7,684** (+1,612). Of these, **2,751** have a full gate matching the current project inputs (RustFS 2,000; OxiCloud 751). The remaining **6,545** retain historical benchmark evidence (ArtifactKeeper 1,319; Kanidm 2,458; Nora 902; Tuwunel 1,866), which does not certify the changed working trees.

ArtifactKeeper's earlier 27-property gate passed and reached 1,504 lines, but subsequent SQL integration invalidated that gate for current inputs. Nora permission-import and Kanidm new modules have isolated proof successes; their complete project gates remain incomplete. Tuwunel proxy logic has differential evidence but no accepted new formal properties. No unfinished expansion is credited.

Both sessions used this same branch, so their changes are combined in this checkpoint. Background checks were stopped; their incomplete logs do not constitute passing evidence.

Accounting verification: seven project-reach unit tests and the statement check passed. Full project verification remains WIP.

The saved [checkpoint](../results/campaigns/coverage-20k-20261028T202224Z/checkpoint/README.md) contains the per-app accounting, fresh gates, source-line sets, mappings, and source hashes. [Main status](../results/campaigns/coverage-20k-20261028T202224Z/MAIN_STATUS.md) and [Kanidm status](../results/campaigns/coverage-20k-20261028T202224Z/KANIDM_STATUS.md) preserve detailed work notes; earlier counts there are historical snapshots.

## Existing-gate finalization follow-up (2026-10-29)

ArtifactKeeper's current27-target gate now passes after the existing SQL scanner's unsupported library calls were represented explicitly and Lean was regenerated. Current source-matched mapped reach is **4,255** (AK1,504; RustFS2,000; OxiCloud751). Historical fallback for unresolved Kanidm/Nora/Tuwunel is **5,226**; the mixed compatibility total is **9,481**, up185 from9,296. Full historical benchmark reach remains7,684 with99/101 accepted task/model results. Current and full historical totals overlap and must not be added.

Whole-project verification remains incomplete. Nora middleware_total, Kanidm EffectivePermissionCheckTotal/staged EntryValidation, and Tuwunel quartic transition_total have concrete unresolved proof blockers. Optional SQL scanner top-level proof remains WIP despite compiled segment lemmas. All six current extractions pass; extraction alone is not proof coverage. See the [final audit](../results/campaigns/finalize-gates-20261029T031353Z/FINAL.md) for exact hashes, pinned line sets, gate evidence, diagnostics and remaining work.

## Root totality follow-up (2026-10-29)

Nora's 31-target and Kanidm's 36-target full gates and extraction checks now
pass for the current inputs. Current source-matched mapped reach is **5,662**
(RustFS 2,000; ArtifactKeeper 1,504; Nora 987; OxiCloud 751; Kanidm 420), up
1,407 from 4,255. Kanidm's mapping covers only part of its verified code;
Tuwunel still has no project source mapping. Historical benchmark reach remains
7,684. The mixed compatibility total is 7,528, including Tuwunel's historical
1,866; its decrease reflects replacement of Kanidm's historical fallback with
a smaller exact mapping, not a loss of proven properties. These overlapping
counts must not be added. See [proof completion evidence](TOTALITY_COMPLETION.md).

Tuwunel’s existing 17-target gate and extraction check also now pass, completing
all three totality follow-ups without changing their statements. All six current
configured project gates pass (390/390 targets). The dashboard’s
`whole_project_verified` coverage flag still requires source mappings for every
project; Tuwunel’s missing mapping keeps that flag false. This does not indicate
a remaining failure in the configured proof gates. Optional expansion proofs
outside these target lists remain WIP.
