# Source coverage recount (2026-10-29)

Current source-matched dependency reach is **9,902 upstream executable lines**,
with **390/390 configured property targets passing**. The previous 5,662 figure
was incomplete: Kanidm mapped only the four added modules; Tuwunel had no current
project mapping. This recount adds 4,240 lines of accounting without changing
Rust kernels, generated Lean, proof statements, extraction roots or proof bodies.

| Application | Configured targets passing | Before: current mapped lines | Recount |
| --- | ---: | ---: | ---: |
| ArtifactKeeper | 27 | 1,504 | 1,504 |
| Kanidm | 36 | 420 | 2,705 |
| Nora | 31 | 987 | 987 |
| OxiCloud | 11 | 751 | 751 |
| RustFS | 268 | 2,000 | 2,000 |
| Tuwunel | 17 | 0 | 1,955 |
| Total | 390 | 5,662 | 9,902 |

Historical fallback is zero. The historical benchmark snapshot still has
7,684 lines with 99/101 accepted task/model results; it overlaps current project
coverage and must never be added to it. The 20,000-line objective remains open;
the current mapped count is 98 lines short of 10,000.

## Reproducible evidence

Run `python3 prove/harness/dashboard.py docs/prove/data --refresh-project-checks`
from the repository root. This requires each app's latest full gate and extraction
to pass and match the complete current proof/kernel input fingerprint before
crediting the corresponding current source mapping.

The [Kanidm mapping](../harness/source-mappings/kanidm.json) names 87 generated
definitions at upstream revision `f608c4fe14dfd8d5df8edeed470bf1fb92060abd`.
It preserves the added softlock/schema/credential/account-policy mappings and
adds access decisions, entry/filter/identity methods, protected/migration sets,
and the seven modeled value-set implementations. Existing `fold_from` item-kind
metadata is corrected to `method`; its source span and credited lines are unchanged.
The [Tuwunel mapping](../harness/source-mappings/tuwunel.json) names 83 generated
definitions at revision `7801b8ec6f7773d90b1bbfeeb352012d6e004e96`, covering
modeled routes, visibility/state/cache/timeline/relations/thread reads and filters.
Explicit generic timeline forwarding and count/relation methods are included;
unrelated methods with the same name are excluded.

Each new mapping key was checked against generated Lean definitions. Every
Kanidm and Tuwunel source item's file/type/name/start/end/kind was checked against
the pinned Rust item inventory; span SHA-256 checks pass in the production
measurement. Multiple generated definitions can share an upstream method, and
an enum dispatch can map several concrete implementations. The numerator always
unions physical executable line identities per pinned file, across all targets.
It excludes comments, attributes and blank lines. Only declarations reachable
from theorem **types**, followed through generated definition bodies, earn credit;
proof-body references, unmapped helpers and extraction roots alone earn none.

Exact per-property dependencies, source spans, hashes and deduplicated line sets
are saved in [Kanidm evidence](../results/source-coverage/kanidm-project-reach.json)
and [Tuwunel evidence](../results/source-coverage/tuwunel-project-reach.json).
All six application totals are reflected in [dashboard data](../../docs/prove/data/index.json).
Passing proof and extraction records remain those listed in
[totality completion](TOTALITY_COMPLETION.md); no expensive Lean rebuild was
needed because none of their fingerprinted inputs changed. Accounting tests
(`test_project_reach.py`, eight; `test_dashboard_accounting.py`, two) pass.

## Interpretation and exclusions

This is source-item dependency reach for formally checked modeled operations,
not a proof that every counted upstream line has equivalent behavior or that
all upstream application code is verified. Item spans can contain upstream
plumbing represented abstractly in the kernel. The documented trusted-input and
modeling restrictions in each port's `DEVIATIONS.md` continue to apply, including
Kanidm's ASCII/Unicode difference and omitted transaction/index/cache machinery,
and Tuwunel's parsed identifiers, snapshot storage, I/O and presentation seams.
The existing Tuwunel relation-size precondition remains unchanged.

The Tuwunel proxy roots and their differential test decisions do not contribute:
none of the configured theorem types reaches them. Copied stream/future support
libraries and whole-file port inventory are not credited. `live_thread` is left
unmapped because its upstream stale-row deletion and presentation changes are
not modeled; modeled callers do not implicitly credit this omitted method.
Kanidm's unmapped filter `resolve` wrapper does not credit omitted optimization
or cache code. Extraction of another root does not automatically prove it.
The dashboard's `whole_project_verified` flag is true because each configured
project gate has current source-matched evidence; it has this narrower meaning.
