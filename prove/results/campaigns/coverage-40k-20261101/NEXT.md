# Toward 100,000+ source lines

The 40k batch primarily proves complete configuration construction and ordered
record selection. It does not establish correctness of whole migrations, entry
conversion, schema validation, persistence, or upstream application equivalence.
Future gains should extend executable decision logic as well as data catalogs.

The existing eligibility inventory is heuristic, not an accepted coverage claim.
Its estimates suggest sufficient remaining pure code, especially Artifactkeeper,
Kanidm, Tuwunel and OxiCloud. Security-only candidates remaining after this batch
sum to roughly 34.6k function lines; reaching 100k will also require broader pure
validation, parsing and policy logic. Resolve dependencies before selecting a batch.

Candidate order:

1. Kanidm value-set/session/credential conversions and validation: precise tagged
   representations, complete success/error results, boundary and exhaustive
   differential cases. Include schema/entry conversion only with its actual checks.
2. Artifactkeeper identity, repository policy and proxy input handling; isolate
   deterministic decisions from network/database effects. Its estimated eligible
   function inventory is largest, but async wrappers cannot count as verified I/O.
3. Tuwunel configuration, protocol validation and pure state transformations;
   Nora parsing and permission decisions; OxiCloud path/ACL validation.
4. Reassess remaining broad pure kernels after accepted security batches. Do not
   inflate reach by mapping wrappers to unimplemented callees or projecting away
   the decisions under verification.

For each small batch: pin and hash exact source spans, port actual branch order,
write independently stated complete properties, compare against pinned upstream,
retain all prior statements, pass the standard full gate and matching extraction,
refresh the dashboard and exact-source detail tests, then save an accepted
checkpoint. Only accepted deduplicated executable lines advance the running total.
