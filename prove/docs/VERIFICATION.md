# Verification coverage and runtime cost

The study asks how much real-world Rust we can verify with h5i-app and what
runtime cost its Aeneas-compatible ports introduce. Begin with the 101 selected
specifications in the six local ports. Three historical tasks in
`dataset/tasks.toml` refer to external examples and are reported separately;
experimental tasks in `extra.toml` also stay outside this denominator.
Keep unsuccessful ports and proofs in the ledger.

## Coverage

Track these quantities separately:

- Selected-spec completion: accepted target theorems / all selected specs.
- Port coverage: unique upstream executable source spans ported / upstream
  executable source spans in a declared, pinned scope.
- Verified code coverage: upstream spans mapped to kernel behavior covered by
  accepted theorems / the same upstream scope.

A security property about a function is not a proof of its complete behavior.
Record the property, preconditions, totality evidence and trusted boundary.
Do not count an entire kernel as verified when one property passes. Deduplicate
shared upstream functions and spans across tasks. Report both the selected
subsystem scope and, eventually, the whole-repository scope to expose selection
bias. The existing ported-line counts alone cannot establish either coverage
percentage; the ledger leaves code coverage unknown until this mapping exists.

`harness/coverage.py` discovers saved successful solutions and archived proof
code, then optionally rechecks them against the current task statement and
axiom allowlist. Historical grades are candidates, not current certification.
Accepted solutions and grader evidence are saved per task under
`results/verification/`. The invocation checkpoints `coverage.json` and records
how many tasks have been inventoried, so interruptions cannot look complete.
Proof recovery is the first pass; missing tasks require new proofs or an
explicitly documented specification correction. Never silently weaken a spec.
New proof candidates live in `ports/<app>/proofs/solutions/<task>/Solution.lean` and use
the same checker. Certificates record source hashes; a later inventory counts
a saved certificate only if its inputs and accepted solution still match.
The independent certificate boundary hashes the selected statement, generated
code, specification, kernel, pinned dependencies, library and grader. It does
not hash unrelated canonical proof bodies, which the isolated grader never
imports. Canonical integration still requires the separate standard project
gate. Earlier whole-`Properties.lean` certificates require a one-time recheck
under this narrower boundary; their evidence is not silently restamped.
Each port uses the standard `h5i-app.toml` project manifest. `h5i app check`
is the final project-wide, sorry-free gate; per-task certification is partial
progress, not a substitute for that gate. Build dependencies are pinned git
dependencies, not application sources borrowed from another checkout.

## Rewrites and equivalence

Preserve the upstream revision, source mapping and `DEVIATIONS.md` for each
port. Differential tests compare the upstream code and rewritten Rust on
identical inputs, including successful and rejected cases. Record seeds,
case counts, domain restrictions and mutation checks. Randomized testing is
empirical evidence, not a formal equivalence theorem. A Lean proof certifies
the extracted kernel under its stated assumptions; it does not by itself
certify the adapter, external services or upstream code.

## Runtime performance

Compare compiled upstream Rust with compiled port Rust, not Lean execution or
proof duration. Build both with the same release settings, compiler and host.
Record the upstream revision, source hashes, dependency lockfile, compiler,
CPU, workload, sample counts and raw timings. Run timing measurements with
other intensive work stopped. Use identical inputs, consume outputs through
`black_box`, warm up both implementations and alternate measurement order.

Report `kernel time / upstream time` per workload. Preserve the samples and
avoid a single aggregate across incomparable workloads. Include input lengths,
valid/invalid mix and scaling studies as the benchmark grows. No slowdown is
assumed: byte-based representations can also improve performance.

The first executable benchmark is Nora's four string validators. It includes
allocations inside each validator and excludes input creation and shell
conversion. Its fixed corpus checks acceptance parity; the existing
`validation_agrees` randomized test checks normalized error results as well.
These are microbenchmarks, not end-to-end application measurements.

Pilot runners now cover all six ports. Nora and Rustfs cover selected pure
functions; Kanidm covers search filtering. Tuwunel and Artifactkeeper include
adapter and fresh service setup on the upstream side. OxiCloud compares a warm
PostgreSQL-backed engine with an already loaded pure snapshot. Those unequal
boundaries are diagnostic only, not evidence of a whole-application speedup.
Current timings were collected during proof work and are explicitly pilots;
publication runs must use a quiet host and longer, scaling workloads.

OxiCloud also has a matched function-only profile:
`python3 harness/performance.py --app oxicloud --profile pure-only --rounds 100000`.
It compares upstream static-slice role/permission queries with the translated
kernel's Boolean queries over all five roles and seven permissions. Both sides
exclude database access, async execution, input conversion, and allocation.
The source-stability-checked pilot in
`results/performance/20261009T204818824656Z-oxicloud.json` reports
kernel/upstream median paired ratios of 0.802 for role grants and 0.974 for role
implication. These are function-level, contended-host pilot results, not an
application-level performance claim.
A longer repeat with 1,000,000 rounds per sample is recorded in
`results/performance/20261009T205528002070Z-oxicloud.json`: the corresponding
ratios are 0.819 and 0.983, with matching replies and stable source identities.
The short role-grants samples show an alternating-order effect, so neither
repeat establishes a publication-grade speed difference.

Artifact Keeper now also has a matched `pure-only` profile for
`scopes_grant_access`, comparing the unchanged pinned upstream helper with the
byte-based kernel on 63 preconverted scope queries. Both sides include their
internal allocations and exclude adapters, database access, async execution,
and input construction. Source-stable pilots at 100,000 and 1,000,000 rounds
per sample report median paired kernel/upstream ratios of 1.220 and 1.253:
`results/performance/20261009T210454886955Z-artifactkeeper.json` and
`results/performance/20261009T210607326256Z-artifactkeeper.json`. This is a
function-level slowdown in these pilot workloads, not an application-wide
performance result. The longer profile uses the same inputs, not a scaling
study over scope counts or string lengths.

Next add matched shell and application benchmarks using `servers/` patches,
including conversion, scans replacing indexed queries, caches and async work.
Record upstream fallback frequency separately: a request handled by fallback
must not be counted as kernel execution or verified coverage.
