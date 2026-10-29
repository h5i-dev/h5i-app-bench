# Final existing-gate and source accounting audit

Whole-project verification is **incomplete**: three of six current configured gates pass; three remain concretely blocked. Accounting and the dashboard are finalized without crediting partial proofs or expanding scope. Starting checkpoint: `f0a078a328f952b6ebf2668890127f89e4116054`, branch `increase-cov`.

## Per-app outcome

| App | Configured targets | Current full gate | Exact current extraction | Current mapped lines | Historical benchmark lines |
| --- | ---: | --- | --- | ---: | ---: |
| ArtifactKeeper | 27 | PASS,763 theorems/22 modules | PASS | 1,504 | 1,319 |
| RustFS | 268 | retained PASS,1,827 theorems/164 modules | PASS | 2,000 | 404 |
| OxiCloud | 11 | retained PASS,418 theorems/14 modules | PASS | 751 | 735 |
| Nora | 31 | BLOCKED | PASS | 0 | 902 |
| Kanidm | 36 | BLOCKED | PASS | 0 | 2,458 |
| Tuwunel | 17 | BLOCKED | PASS | 0 | 1,866 |
| Total | 390 | 3/6 apps pass | 6/6 apps pass | **4,255** | **7,684** |

Every PASS above matches the complete current project input hash set; extraction alone establishes no formal property. Gates retain all configured targets and reject sorry/admit/custom axioms. Historical benchmark lines describe original task snapshots and do not certify changed trees. Current reach is a mapped property/dependency measure, not verification of every line in any application's whole source tree or a proof of complete behavioral equivalence.

### ArtifactKeeper

The first completed current27-target build and dependency axiom check were followed by a generated-source scan rejection of five opaque declarations introduced by SQL integration (array IntoIter/type/into_iter/next and Option map/equality). That run failed and received no credit. Replaced only the scanner's three fixed keyword-array loops with ordered bounded dispatch and its Option map/equality expression with explicit matching. Real `h5i app extract` regenerated Lean; generated code was never hand-edited. This removes the unsupported declarations while preserving keyword and output order. The existing pinned differential suite passed1,130,555 comparisons, including all227 pinned migration SQL files; this supports the representation change and is not a formal proof.

Final standard gate **passed** at [`20261029T034559711662Z`](../../project-checks/20261029T034559711662Z/summary.json):27 configured targets,763 checked theorems/22 modules, exit0, unchanged inputs. Final exact extraction **passed** at [`20261029T034559678470Z`](../../project-checks/20261029T034559678470Z/summary.json). Lean build582.80s, axiom gate69.86s; bound900s.

Optional existing SQL scanner proof remains WIP: all seven segment invariants and push_length compile, including against the final regenerated extraction (`checks/sql-segments-current-extraction.log`). The top-level scanner theorem is unfinished; MigrationSafety is not in the configured gate. No scanner property or SQL source reach was added. Extraction now has197 transparent functions (previous198 included the removed Option.map closure). Its configured27-target gate can pass while the optional scanner property remains incomplete.

### RustFS and OxiCloud

Retained RustFS gate [`20261028T205910702087Z`](../../project-checks/20261028T205910702087Z/summary.json) and OxiCloud gate [`20261029T023235707624Z`](../../project-checks/20261029T023235707624Z/summary.json) match every current input hash; no expensive proof rerun. Final exact extraction: RustFS [`20261029T033110397135Z`](../../project-checks/20261029T033110397135Z/summary.json), OxiCloud [`20261029T032544890817Z`](../../project-checks/20261029T032544890817Z/summary.json). Original Source-comment path root is `prove/`, reproduced using GIT_WORK_TREE pointing there. Actual regeneration reproduces original bytes; the earlier root-prefix mismatch and overlapping RustFS attempt remain failed diagnostics. See normalization JSON files and RUNS.md. Existing RustFS2,000 includes the already audited14 missed-method lines exactly once. Neither app has a remaining gate blocker.

### Nora

The isolated standard31-target check [`20261029T032546071484Z`](../../project-checks/20261029T032546071484Z/summary.json) reached Verified.NoraMiddlewareTotal and timed out600s. Existing helpers were split verbatim into NoraMiddlewareSupport and compiled. The original middleware_total theorem statement is preserved. Joining path-classification branches before the rest of the middleware still timed out180s after replacing an outer split that hit the simp step limit in10s. Exact blocker: the final middleware_total proof has not completed; helper compilation and the six PermissionImport isolated proofs/complete-report invariant do not discharge the full gate. Final extraction passed at [`20261029T034442127760Z`](../../project-checks/20261029T034442127760Z/summary.json). Candidate987 lines remain uncredited; historical902 retained. No unchanged monolithic rerun.

### Kanidm

All36 configured targets remain. Existing modular EffectivePermissionCheckTotal diagnostics fail at the protected literal helper (line20 kernel/whnf timeout at2M heartbeats; unknown constant consequence at26), then final apply_modify simplification/bind Post mismatch at149 and missing step theorem at152 ([saved modular diagnostic](../../kanidm-coverage/batch6-totality-modular.log)). Six MigrationBounds helper proofs and isolated SoftLock/SchemaTags/CredentialCommit/AccountPolicy successes are preserved; the original final theorem statement is unchanged. This campaign's bounded240s standard check timed out during lean_build; an unsuccessful narrow simp experiment was restored. Full gate remains unaccepted.

Staged EntryValidation's bounded build fails at line146: attributesModel loop success-branch induction goal remains unsolved (`checks/entry-validation.log`). No complete validate theorem or canonical integration; differential runners confer no formal credit. Final canonical extraction passed at [`20261029T033643509171Z`](../../project-checks/20261029T033643509171Z/summary.json). Integrated only the existing10 exact source mappings/420 mapped executable lines into harness/source-mappings/kanidm.json. These are a candidate, never a replacement for historical2,458 without a full current gate.

### Tuwunel

The17-target gate cannot pass: canonical Properties.transition_total still uses sorry at line189, preserving the original `(s.relations.length + 1)^4 < Usize.max` premise. Recovered property modules do not establish this totality target. This campaign's240s standard check timed out at package preparation (lock wait), independently of that static proof blocker. Proxy policy remains integrated but has no configured/accepted new formal property. Exact extraction passed at [`20261029T031744205585Z`](../../project-checks/20261029T031744205585Z/summary.json). No exact project source map, no new source credit; historical1,866 retained. No unchanged quartic proof retry.

## Counts and comparison with9,296

- Current source-matched gated reach: **4,255 =1,504 AK +2,000 RustFS +751 OxiCloud**, versus2,751 at checkpoint (+1,504).
- Full historical benchmark reach: **7,684**, unchanged. Historical task/model history remains **99/101** accepted; no new model benchmark runs or fabricated task results.
- Historical fallback used only for the three unresolved apps: **5,226 =2,458 Kanidm +902 Nora +1,866 Tuwunel**, versus6,545 at checkpoint (−1,319).
- Legacy mixed compatibility numerator: **9,481 =4,255 current +5,226 historical fallback**, versus9,296 (+185). This replaces AK's historical1,319 with current1,504; it is **not current whole-project coverage**. Full historical and current totals overlap and must not be added.

Reach is deduplicated by pinned repository/path/physical executable line. Candidate JSON files retain exact line sets, source-span hashes, generated dependencies and mapping hashes. Immutable pins: AK: 7c42891cd64f144df6197b8801c9cca4f0e0f5a7; Kanidm: f608c4fe14dfd8d5df8edeed470bf1fb92060abd; Nora: f864a9a95e8669b00202c18b0b774ab0fc2e56cc; RustFS: e870a6d25bbf02323b7841b0c5e2230a56551970; OxiCloud: 8c0dd334cf065ad11f60f9be24e2aafd5dda7550. Tuwunel: `7801b8ec6f7773d90b1bbfeeb352012d6e004e96` (historical benchmark snapshots; current extraction hash set in the audit). Port-ledger counts are not substituted for proven mapped reach.

## Reviewable validation

- `final-gate-audit.json`: six apps' complete current hashes, fresh gate/extraction records, configured counts and accepted/candidate reach. Standard run summaries contain immutable before/after checks; stdout/stderr retained beside them.
- `statement-and-generated-audit.json`: all390 configured public statement types match f0a078a; Nora middleware_total statement preserved; all generated Lean unchanged except AK's actual SQL re-extraction. Earlier pre-repair audit retained with its phase clearly named.
- `accounting-history-audit.json`: task/model and other benchmark history byte-value comparisons to f0a078a; per-app historical benchmark fields unchanged; dashboard totals asserted.
- Dashboard refreshed with `python3 prove/harness/dashboard.py docs/prove/data --refresh-project-checks`. Current coverage now requires both full gate and fresh exact extraction; UI distinguishes historical benchmark results and current gated source reach. `whole_project_verified=false`.
- Project runner/reach10 tests passed; dashboard accounting2 tests passed; statement test protects101 original benchmark statements; source-span4 tests passed; dashboard JavaScript syntax and git diff whitespace checks passed. Logs under checks/.
- Standard runner now bounds/stops only its own process group and records timeouts as failures. No target removal, weakened statements, custom axioms, fake extraction or partial-build promotion.

A provider capacity error interrupted progress; work resumed on the same configured model. No model substitution, extra agents, old sessions/helpers or unrelated tmux work were used. Unrelated performance edits and old root untracked trees are excluded from this follow-up commit.

Standard extraction logs are also normalized in place for durable review: ANSI and transient progress removed, completed counters preserved. Original raw hashes and normalized hashes are recorded in normalized-log-index.json; raw command output is retained locally and excluded from git. Commands, errors, outcomes and immutable source input snapshots are unchanged.
