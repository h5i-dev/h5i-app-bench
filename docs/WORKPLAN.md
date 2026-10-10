# Real-world Rust verification campaign

This campaign uses one standard h5i-app project per application: `kernel/`,
`proofs/`, and `h5i-app.toml`. The release criterion is `h5i app prove`, not a
historical agent score or a candidate proof in an isolated task workspace.

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
