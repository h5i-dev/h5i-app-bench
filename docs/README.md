# Benchmark website

This directory contains the static assets for `benchmark.h5i.dev`: the landing
page, verification dashboard (`prove/`) and performance dashboard (`performance/`).
Committing or pushing these assets does not confirm a hosting deployment.

## Verification checkpoint

Coverage expansion is paused by user request as of 2026-11-01 at **42,975
accepted deduplicated pinned executable source lines and 1,197 canonical project
properties**, across six applications. The 100,000-line objective is unfinished;
57,025 lines remain. The accepted checkpoint is commit `1bb4102`; merge commit
`0c322a6` preserves it while incorporating `main`.

All six applications have passing proof/axiom gates and extraction records
matching their source inputs. Source reach follows theorem types and extracted
dependencies; it does not establish whole-application equivalence. Historical
benchmark results remain separate at 101 tasks / 99 accepted. Runtime performance
was not remeasured at this checkpoint. Experimental forwarding constructors
remain uncounted.

See the [checkpoint report](../prove/results/campaigns/coverage-closed-records-20261101/STATUS.md),
[acceptance record](../prove/results/campaigns/coverage-closed-records-20261101/accepted-checkpoint.json),
[measurement method](../prove/docs/VERIFICATION.md) and
[paused work plan](../prove/docs/WORKPLAN.md).

## Refresh the data

Run from the repository root to retain historical task/model results while
refreshing source-matched project counts, proof modules and source pairs:

```sh
python3 prove/harness/dashboard.py docs/prove/data --refresh-project-checks
python3 -m unittest discover -s prove/harness -p 'test_*.py'
```

This requires the pinned upstream repositories under `prove/results/upstream/`
and matching project-check and extraction evidence. The export checks freshness;
it does not run new Lean proofs or extraction checks. Review the resulting
`stats`, per-application gates and project details before committing the JSON.

Performance data is generated separately from aggregate benchmark summaries:

```sh
python3 performance/site.py
```

Follow each benchmark's result policy when selecting data to commit. In
particular, django-cart raw samples, logs, environment dumps and conformance
output remain local; only allowed aggregate summaries and placement reports
may be tracked.
