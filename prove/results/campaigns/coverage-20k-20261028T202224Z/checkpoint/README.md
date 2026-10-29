# Coverage checkpoint

New expansion stopped at user request.

Reported upstream reach: **9,296 lines**, baseline 7,684 (+1,612). Target 20,000; gap 10,704.

| App | Lines | Evidence basis |
| --- | ---: | --- |
| artifactkeeper | 1,319 | historical_benchmark_snapshot |
| kanidm | 2,458 | historical_benchmark_snapshot |
| nora | 902 | historical_benchmark_snapshot |
| oxicloud | 751 | current_source_matched_project_gate |
| rustfs | 2,000 | current_source_matched_project_gate |
| tuwunel | 1,866 | historical_benchmark_snapshot |

Current source-matched gates account for **2,751** lines. Historical benchmark snapshots account for **6,545**. The 9,296 total must not be described as a fresh whole-project verification of the current modified trees.

RustFS 268 configured properties passed; added two missing exact method mappings (+14 lines), reached by 33 and 19 accepted properties respectively. RustFS remains short of its port-ledger count; remaining candidates are not credited without semantic review.

ArtifactKeeper token/TOTP historical expanded snapshot reached 1,504, but SQL source integration invalidated that current-input gate; only historical benchmark 1,319 is retained here. Nora, Kanidm and Tuwunel expansions remain incomplete and excluded. Differential checks and isolated proofs do not replace full fresh gates.

Seven accounting tests passed. Saved dashboard, mappings, gates and deduplicated source-line evidence accompany accounting.json. All unfinished source/proof edits are preserved in the working tree.

Both Codex TUIs are suspended in tmux; unfinished background checks were terminated and excluded. Remote context compaction prevented agent-authored final notes. See sessions-paused.json for process details. Source/proof files and terminal logs are preserved.
