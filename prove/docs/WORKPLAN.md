# Real-world Rust verification campaign

This campaign uses one standard h5i-app project per application: `kernel/`,
`proofs/`, and `h5i-app.toml`. The release criterion is `h5i app check`, not a
historical agent score or a candidate proof in an isolated task workspace.

## Current stopping point — paused by request (2026-11-01)

Coverage expansion is paused at **42,975 accepted deduplicated pinned executable
source lines and 1,197 canonical project properties**, committed and pushed as
`1bb4102` on `prove-20k-expansion`. The 100,000-line objective remains unfinished;
**57,025 lines remain**. Resume expansion only on a new user request.

| Application | Accepted source lines | Canonical properties |
| --- | ---: | ---: |
| ArtifactKeeper | 2,122 | 99 |
| Kanidm | 31,103 | 545 |
| Nora | 1,959 | 61 |
| OxiCloud | 3,794 | 198 |
| RustFS | 2,000 | 270 |
| Tuwunel | 1,997 | 24 |
| **Total** | **42,975** | **1,197** |

The final batch adds 202 lines and 23 complete record-constructor properties.
Every returned field and successful termination are stated. All 1,174 prior
canonical property statements remain unchanged. All six applications have fresh
successful proof/axiom gates and extraction evidence. Pinned-body comparisons,
byte-identical regeneration, the source attribute audit and all 23 harness tests
pass. Constructor proofs do not establish runtime configuration enforcement or
whole-application equivalence.

The dashboard data is refreshed locally; it has not been deployed. Historical
benchmark accounting remains 101 tasks / 99 accepted, separate from canonical
project properties. Runtime measurements were not refreshed in this batch.

Durable evidence: [checkpoint report](../results/campaigns/coverage-closed-records-20261101/STATUS.md)
and [acceptance record](../results/campaigns/coverage-closed-records-20261101/accepted-checkpoint.json).
The [handoff](../results/campaigns/coverage-closed-records-20261101/NEXT.md) records
142 experimental forwarding constructors with universal Lean proofs and retained
source-body comparisons. Their 715 inventory lines are **not accepted coverage**;
production integration, deduplication and gates remain. Experimental files under
`/tmp` are disposable and must be reconstructed from pinned sources if absent.

Earlier checkpoints and work-queue states below are historical; this stopping
point supersedes their statements that expansion is active or gates are pending.

## Scope and completion criteria

The selected corpus contains 101 specifications across six local ports. The
three historical framework-example tasks are excluded. No application source
is taken from an h5i checkout. Proof dependencies are Git-pinned libraries.

- Every selected statement is proved without changing its meaning; the final
  standard gate rejects `sorry`, added axioms, and `native_decide`.
- Extraction is reproducible against the checked-in generated Lean.
- Each rewritten kernel has deterministic differential tests against pinned
  upstream source. Testing is evidence, not an equivalence proof.
- Each application has paired release-mode Rust measurements, raw samples,
  source identities, input seeds, and an explicit timing boundary.
- The report separates selected-spec completion, selected upstream source
  coverage, and whole-repository coverage. Unknown coverage stays unknown.

## Work queue

| Work item | State | Acceptance evidence |
| --- | --- | --- |
| Standard manifests and Git-pinned Lake projects | Implemented | Six port manifests; standard gate invoked |
| Differential tests | Passed | Fresh six-application run: `results/equivalence/20261009T203325205679Z/summary.json` |
| Recover and independently check historical proofs | Running | Per-task certificates in `results/verification/` |
| Consolidate accepted proofs into canonical projects | In progress | Properties imports maintained proof modules; standard gate passes |
| Prove missing selected statements | In progress | All 101 selected theorems pass the gate |
| Reproducible extraction | Passed | Six standard extraction checks in `results/project-checks/20261009T200256748196Z/summary.json` |
| Paired Rust performance measurements | In progress | Per-application raw samples and declared timing boundaries |
| Upstream source-span coverage accounting | In progress | Six pinned scope denominators and six deduplicated ported-item mappings inventoried; proof attribution under review |
| Final reproducibility and limitations report | Pending | Full proof, extraction, test, and measurement evidence |

## Current cautions

The Nora standard gate correctly fails on its remaining placeholder proofs.
All six ports pass standard extraction reproducibility checks. The initial Nora
drift was confined to generated source-location comments. Historical certificates are not
the final canonical gate. Wrapper-inclusive timing is not whole-application
performance. OxiCloud tests use only the explicitly named disposable database
`h5i_bench_disposable`; existing application databases are not used.

## Working commands

```sh
h5i app doctor ports/nora
h5i app extract --check ports/nora
h5i app check ports/nora
python3 harness/coverage.py --check-all
python3 harness/source_inventory.py
python3 harness/source_spans.py
python3 harness/equivalence.py --help
python3 harness/performance.py --help
```

Record failures and pending work honestly; do not remove selected theorems from
the manifest to make the gate pass.

## Source inventory checkpoint

`results/source-coverage/ported-spans.json` maps the original port inventories
onto immutable upstream Git objects. These are item-span inventories, not
verified-code numerators. Nonblank physical lines include comments and attributes;
they are not comparable to the historical logical-LOC counts.

| Application | Item spans | Deduplicated nonblank lines |
| --- | ---: | ---: |
| Nora | 36 | 1,332 |
| Artifact Keeper | 30 | 4,532 |
| Kanidm | 104 | 3,037 |
| RustFS | 50 | 1,199 |
| Tuwunel | 104 | 3,331 |
| OxiCloud | 39 | 1,866 |

In particular, OxiCloud spans still include its unported email/message-bus
branches. No upstream verification percentage is asserted at this checkpoint.
The OxiCloud drive-read-only, sharing-policy, and personal-drive candidates
compile locally; independent certificates and canonical gates remain required.
The self-contained Nora revoke-all candidate passed its independent check in
certificate-only mode after the full audit passed Nora's task position, without
replacing that audit's shared coverage ledger. Canonical integration and its
standard project gate remain pending. The no-credentials proof is still under
development; unsuccessful local attempts are not counted as verification.

Nora's reference-shape proof and the repaired Tuwunel context-base/event proof
also passed independent certificate checks. These new certificates remain
outside the running audit's shared ledger until its complete inventory is
refreshed. The OxiCloud audit has accepted migration read-only, drive read-only,
expired-grant, token-grant, and share-needs-owner properties so far; its final
endpoint checks are still running.

OxiCloud's `pure-only` runtime profile provides matched role/permission queries
without database I/O or async execution. Other adapter-inclusive profiles retain
their unequal-boundary warnings. The timing harness records before/after source
hashes and rejects results whose sources changed during the run.
Artifact Keeper's additional `pure-only` profile compares scope queries with
the same allocation and adapter boundaries. Two source-stable paired pilots
are recorded in `docs/VERIFICATION.md`; all application-level gaps remain
unresolved until matched shell/application workloads are measured.

## Resumed integration checkpoint

The completed independent audit plus five subsequent certificates accepted
43 of 103 selected specifications (41.75%) before canonical integration.
All 43 accepted candidates are now integrated into their respective standard
app projects as `Verified` modules, with the original theorem statements
preserved. Eleven harness tests pass. The six standard project checks are
running; remaining placeholders are still expected to prevent full-project
acceptance. Certificates retain their original input hashes: integration
changes `Properties.lean`, so they must not be presented as fresh certificates
for the changed project without another check.

Tuwunel joined-members and room-event visibility both passed independent
certification. Nora no-credentials still has unresolved proof goals and is
not counted. The workspace freshness check now also compares the pinned
Lake manifest before reusing a grading workspace.

The resumed canonical build found duplicate globally generated derivation
helpers in separately certified modules. Integration now emits one shared
`Verified/Derived.lean` per affected project. Nora, RustFS and OxiCloud's
`lake build Verified` pass after this correction. Nora's subsequent standard
gate compiles the canonical project and rejects only its remaining `sorryAx`
dependencies. Independent certification now hashes the target statement
rather than unrelated `Properties.lean` proof bodies, with regression tests
for both integration issues; older certificates receive a one-time recheck.

RustFS `not_action_never_grants_force_delete` subsequently passed independent
certification and canonical `lake build Verified`, bringing the accepted
candidate count to 44/103. Fourteen harness regression tests now pass. The
full application gates still reject remaining unproved declarations; this
count is specification completion, not an upstream code coverage percentage.

RustFS `get_object_version_covers_get_object` also passed independent
certification (45/103 accepted candidates). At the user's request, one parallel
proof agent is developing Tuwunel candidates in a separate solutions directory;
canonical integration and independent certification remain centrally managed.

## Coverage expansion campaign (2026-10-28)

The 20,000-line objective is active. The historical task set remains 101 tasks
(99 accepted); project properties and their source reach are measured separately.
An initial audit found 268 source-matched RustFS project properties reaching
1,986 deduplicated pinned source code lines, replacing the old 404-line task-only
numerator. That preliminary aggregate was 9,266; stricter gate snapshots now
also include Cargo build configuration, so these project results require new
standard gates before the next dashboard refresh.

New Artifact Keeper token-expiry and TOTP policy ports have ten isolated Lean
proofs and passing pinned-body differential tests (694,688 token cases;279
exhaustive TOTP comparisons). Its complete 27-property project gate is running.
Nora's permission-import mapper has passed 200,512 complete-report differential
comparisons; extraction and report invariants are in progress. Kanidm's separate
worker owns additional softlock/schema/credential/account-policy batches.
Candidate reach and isolated proofs are not counted as passing project gates.

Durable coordination and validation evidence are under
`results/campaigns/coverage-20k-20261028T202224Z/`. The checked aggregate has not
established the 20,000-line milestone.


## Accepted 40k source reach milestone (2026-10-31 local / 2026-11-01 UTC)

The next campaign started from an accepted 20,765 pinned executable source lines
and 609 project properties. It now reaches **40,317 lines with 1,010 accepted
properties**, adding 19,552 deduplicated lines and 401 complete Kanidm catalog
and ordered-selection properties. All 142 earlier Kanidm property types remain
unchanged. The gain covers ACP, schema, group and entry construction, and twenty
complete migration record selections; it does not certify database migrations or
whole-application equivalence.

The standard Kanidm gate checked 3,514 theorems across 470 modules using only
the three permitted axioms. Its inputs were unchanged throughout the run. The
matching official extraction passed, as did all 43 Rust tests and all 13 source
reach, dashboard accounting and detail tests. All six projects retain fresh gate
and extraction evidence. The local dashboard assets are refreshed; deployment
has not been performed.

Evidence and the 100k+ candidate plan are in
`results/campaigns/coverage-40k-20261101/accepted-checkpoint.json` and `NEXT.md`.
Reaching 100k+ will require further executable validation, parsing and policy
logic as well as complete data construction. Candidate estimates are not counted
as accepted source reach.


## Accepted finite enum checkpoint toward 100k (2026-11-01)

The accepted source reach is now **41,133 deduplicated pinned executable lines
and 1,130 canonical project properties**, up 816 lines and 120 properties from
`c793a05`. The 100,000-line target has not been reached; 58,867 lines remain.

The reusable finite catalog importer covers 88 closed unit enums across all six
apps. It preserves pinned method bodies and enum discriminants, compares every
valid input against independent Rust reference execution (712 comparisons), and
proves complete outputs for those finite domains. Enum declarations, tests and
generated code receive no upstream line credit. All 1,010 earlier canonical
property statements are unchanged. These results do not establish complete
application behavior or external-effect equivalence.

All six standard project/axiom gates and matching extraction checks pass with
unchanged inputs. All 133 Rust tests, isolated byte-for-byte artifact regeneration,
pinned-reference audits and 13 dashboard/accounting/detail tests pass. Nora's
first gate timed out after waiting approximately 24 minutes for the shared
package lock; the longer rerun passed without changing its proof inputs.
The dashboard snapshot is refreshed while preserving historical benchmark runs;
deployment has not been performed.

Exact acceptance evidence, reproducible checks and the next substantive candidates
are in `results/campaigns/coverage-100k-20261101/{accepted-checkpoint.json,STATUS.md,NEXT.md}`.
Finite enum methods supply only a small part of the remaining target; broader
value-set, parsing, policy and exact-output transformations are still needed.

## Accepted arbitrary string checkpoint toward 100k (2026-11-01)

The accepted total is **41,414 pinned executable source lines and 1,133
canonical properties**, up 281 lines and three properties from `1827206`.
The 100,000-line objective remains active, with 58,586 lines left.

OxiCloud's complete MIME/extension display decisions now have arbitrary-byte
output and termination proofs, including bounded substring search and exact
54-string output interning. The pinned Rust reference passed 201,750 complete
string comparisons. All 1,130 prior statements remain unchanged. Synthetic
chunks, enum declarations, tests and generated source receive no line credit.

The complete OxiCloud gate checked 1,728 theorems across 34 modules, with only
the permitted axioms. Matching extraction, byte-for-byte regeneration, pinned
reference audits, all OxiCloud Rust tests, and 19 source/accounting/dashboard/
runner tests pass. All six apps retain fresh gate and extraction evidence.
The local dashboard is refreshed; historical benchmark accounting remains
101 tasks / 99 accepted, and deployment has not been performed.

Evidence and the continuing work queue are in
`results/campaigns/coverage-strings-20261101/{accepted-checkpoint.json,STATUS.md,NEXT.md}`.
This establishes reusable string-decision proofs; larger collection, parsing
and transformation ports are still required to reach the target.
