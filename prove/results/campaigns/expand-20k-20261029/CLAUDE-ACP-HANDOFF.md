# Finish the pending ACP batch

The user explicitly requested ONE Claude Code TUI in tmux, robust to SSH disconnects, to finish the pending ACP batch. This supersedes the old Codex-only/paused instructions. Do not spawn subagents, other AI sessions or restart Codex. Work in /home/ht2673/Dev/h5i-app-bench, branch prove-20k-expansion, preserving the existing uncommitted ACP work.

Read STATUS.md and HANDOFF.md in this directory for the history, evidence and acceptance pipeline. Scope for this session: finish ACP, fully verify and account it, commit/push the accepted result, then stop with a clear status. Do not begin unrelated expansion or merge main.

Last accepted and pushed checkpoint: 16,512 pinned upstream executable lines / 589 properties, commit 6bf9a99. Pending Kanidm ACP: 66 original initializers across six versions, 20 distinct complete owned records. All 66 pinned full-field differential comparisons passed; extraction succeeded. Diagnostic reach was 20,765 lines but is NOT accepted until complete proofs, full project gates and exact extraction plus dashboard accounting pass. No padded, guessed or stale numbers.

Work already present:
- prove/ports/kanidm/kernel/src/acp_defaults.rs
- prove/ports/kanidm/kernel/tests/acp_defaults.rs
- prove/ports/kanidm/difftest/acp_defaults/ (extract_upstream.py and harness)
- prove/ports/kanidm/proofs/Verified/AcpDefaultsData.lean and AcpDefaults0.lean through AcpDefaults19.lean
- manifest, Properties.lean, generated kernel, deviations and exact upstream source mappings.
Previous logs /tmp/prove-kanidm-acp-{extract,proof1}.log. Inspect current files and any already running local builds before starting duplicates. Lean version 4.31.0; preserve shared cache. Resolve proof errors without sorry, added axioms, vacuous preconditions, dropped targets or hand-edited extraction. Prove all complete record fields with meaningful TYPE-seeded dependencies.

Acceptance:
1. Finish full-record proofs and all 20 manifest properties. Rerun the pinned ACP differential as appropriate.
2. From repo root: python3 prove/harness/project_checks.py check --app kanidm --timeout 1800
3. python3 prove/harness/project_checks.py extract-check --app kanidm --timeout 900
4. Keep proof/port/manifest inputs stable throughout recorded checks. All SIX apps need matching fresh gates/extraction for accounting.
5. From prove/: python3 harness/dashboard.py ../docs/prove/data --refresh-project-checks
6. Run existing test_project_reach.py, test_dashboard_accounting.py and test_project_details.py (13 tests), inspect official totals and current proof/source-comparison assets.
7. Update STATUS.md, accepted-checkpoint.json and differential-evidence.json with exact evidence, verified totals, blockers if any. Do not claim entire upstream applications equivalent; definition is extracted dependency reach to pinned executable source.
8. Stage only task files and passing evidence, commit and push origin prove-20k-expansion, then report completion and stop. No main merge in this session.

Preserve unrelated tracked performance/django-cart/comparison/summarize.py, performance/django-cart/comparison/test_summarize.py and performance/site.py; preserve root untracked env/, harness/, ports/, results/, scripts/, tasks/. Never git add -A or force-add broad ignored directories. Do not alter other tmux projects/sessions. Old prove-finalize is idle; leave it idle. Update STATUS.md regularly. If blocked, record exact blocker and leave work recoverable.
