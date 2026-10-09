# h5i-app-bench

A benchmark of how well language models prove properties of real web
applications with [h5i-app](https://github.com/h5i-dev/h5i).

Each task asks a model to prove, in Lean 4, one property of an application
whose Rust logic has been ported to an h5i-app kernel. Models run as coding agents
in a sandbox without network access. See [docs/DESIGN.md](docs/DESIGN.md) for
how tasks are built, graded and measured. The dashboard is in
[docs](docs) and is served at <https://benchmark.h5i.dev>.

This repository was the home of the framework itself, then called i5h. The
framework now lives in the [h5i](https://github.com/h5i-dev/h5i) repository as
`h5i-app` (`crates/h5i-app*`, examples in `examples/app`); the last state of
the framework here is tagged `framework-final`. Model solutions recorded in
`docs/data` were written against the library under its old names
and are shown with the current ones (`H5iAppLib`, `h5i_step`, …).

The ports require the h5i-app Lean library from a sibling checkout of h5i
(`../h5i/crates/h5i-app-core/proofs`), and the harness reads the tasks taken
from h5i's own examples from `~/Dev/h5i` (`CHECKOUTS` in `harness/bench.py`).

## Usage

```sh
scripts/snapshot-h5i-app-lib.sh              # the h5i-app library the sandbox mounts
docker build -t h5i-app-bench:0 env
python3 harness/bench.py build          # tasks/<id>/, validated against the reference proofs
python3 harness/run.py nora-lifetime gpt-5.5
python3 harness/run.py nora-lifetime claude-sonnet-5-5 --agent claude
scripts/run-batch.sh claude-opus-5-5 claude 3   # dataset/subset20.txt, detached; log in results/campaigns/
python3 harness/dashboard.py docs/data         # publish results to the dashboard
```

The rustfs and OxiCloud differential tests build against the upstream crates;
link their checkouts with `RUSTFS_SRC=… OXICLOUD_SRC=… scripts/link-upstream.sh`.
The `gemini` agent needs `BENCH_NODE` (a Node install) and `BENCH_GEMINI_CLI`
(an npm prefix with `@google/gemini-cli`).

`run.py` needs two host-side modules. Copy `harness/proxy.example.py` to
`harness/proxy.py` and `harness/billing.example.py` to `harness/billing.py`,
then set `BENCH_UPSTREAM` (the base URL of an upstream that serves the
Responses, Messages and Gemini APIs) and `BENCH_API_KEY`, and fill in the
prices in `billing.py`.

## Applications

| Application | Upstream | Upstream lines | Tasks | Ported code |
|---|---|---|---|---|
| [nora](ports/nora) | getnora-io/nora @ f864a9a | 977 | 25 | authentication middleware, API tokens and their cache, OIDC claims, role rules and namespace scopes, brute-force lockout, trusted proxies; validators for digests, Docker names and references, and storage keys; glob matching |
| [artifact-keeper](ports/artifactkeeper) | Artifact-Keeper @ 7c42891 | ~2,150 | 17 | repository permission service, auth, admin and visibility middleware, guest access, token scopes, download tickets, anonymous-rule validation, CIDR matching |
| [kanidm](ports/kanidm) | kanidm/kanidm @ f608c4f | 2,553 | 18 | access control profiles: search, create, modify and delete checks, protected entries, sync agreements, the effective-permission report; filter matching |
| [rustfs](ports/rustfs) | rustfs/rustfs @ e870a6d | 1,141 | 14 | IAM and bucket policy evaluation: actions, resources, conditions; policy-variable resolution, wildcard matching, path cleaning, condition value parsing |
| [tuwunel](ports/tuwunel) | matrix-construct/tuwunel @ 7801b8e | 2,492 | 17 | Matrix event and state visibility and pagination: `/messages`, `/context`, `/relations`, `/threads`, `/event`, `/state`, `/members`, `initialSync`; visibility over federation |
| [OxiCloud](ports/oxicloud) | AtalayaLabs/OxiCloud @ 8c0dd33 | 1,257 | 12 | access control engine (grants, nested groups, folder inheritance, drive roles and policies, link tokens, read-only modes) and the grant endpoints |

## License

Apache-2.0. Ported code keeps its upstream license (nora: MIT).
