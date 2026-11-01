# Continue toward 100k

Continue from 42,773 accepted lines / 1,174 properties toward 100,000 with stateful entry/index and
metadata/scanner kernels. Schema descriptions and constructor text provide no
claim about server enforcement. No module helper or icon gets separate credit.

## Stateful candidate review

Pinned Kanidm Entry::idx_diff (entry.rs:1627–1887, inventory 228 executable
lines) compares optional pre/post entries over HashMap index metadata. Equality,
substring and ordering use generated key vectors; presence uses the literal
underscore key. The both-entry branch asserts identical state IDs. When both
attribute values exist, it sorts each key vector and merges their iterators,
returning removals and additions. Any adapter must retain metadata iteration
order, sorting order, duplicate-key semantics, output order, and the ID assertion;
a set-only model would erase observable behavior. Generated-key tables can be
explicit inputs only with exact, documented caller projections and no helper
coverage credit. Full branch/output/termination and pinned-body reference tests
are necessary before considering source mapping. See /tmp/h5i-kanidm-idx_diff.rs
for the temporary body; regenerate from the pinned bare repository if missing.

Entry::merge_state (entry.rs:850–1083, 172 executable lines) also needs schema
multivalue decisions, timestamp/UUID assertions, tombstone/live cases and
value-set replication merge behavior. This is a separate, larger proof task;
its heuristic lack of exclusion reasons is not evidence that it is pure.
