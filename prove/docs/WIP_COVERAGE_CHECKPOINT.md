# WIP: upstream coverage expansion checkpoint

Expansion stopped on 2026-10-28 at the user's request. This commit preserves both sessions' code, extracted Lean, partial proofs, differential runners, and verification evidence. It is not a claim that the current whole tree passes formal verification.

Reported pinned-upstream dependency reach: **9,296 lines**, versus baseline **7,684** (+1,612). Of these, **2,751** have a full gate matching the current project inputs (RustFS 2,000; OxiCloud 751). The remaining **6,545** retain historical benchmark evidence (ArtifactKeeper 1,319; Kanidm 2,458; Nora 902; Tuwunel 1,866), which does not certify the changed working trees.

ArtifactKeeper's earlier 27-property gate passed and reached 1,504 lines, but subsequent SQL integration invalidated that gate for current inputs. Nora permission-import and Kanidm new modules have isolated proof successes; their complete project gates remain incomplete. Tuwunel proxy logic has differential evidence but no accepted new formal properties. No unfinished expansion is credited.

Both sessions used this same branch, so their changes are combined in this checkpoint. Background checks were stopped; their incomplete logs do not constitute passing evidence.

Accounting verification: seven project-reach unit tests and the statement check passed. Full project verification remains WIP.

The saved [checkpoint](../results/campaigns/coverage-20k-20261028T202224Z/checkpoint/README.md) contains the per-app accounting, fresh gates, source-line sets, mappings, and source hashes. [Main status](../results/campaigns/coverage-20k-20261028T202224Z/MAIN_STATUS.md) and [Kanidm status](../results/campaigns/coverage-20k-20261028T202224Z/KANIDM_STATUS.md) preserve detailed work notes; earlier counts there are historical snapshots.
