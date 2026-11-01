# Remaining work toward 100k

This campaign adds dependency-closed finite enum decisions. It does not close the
100k target. The accepted checkpoint records the actual remaining gap.

The finite importer handles receiver-only methods on closed unit enums returning
strings, integers or booleans. Every accepted variant is evaluated against the
unchanged pinned method body, and every result has a complete Lean output proof.
This is a useful reproducible batch, but this method family is too small to
supply the remaining tens of thousands of lines.

`remaining-candidates.json` lists unmapped function/method inventory estimates and
large individual candidates by app. These are heuristic estimates, not accepted
reach or proof of dependency closure. In particular, an empty heuristic rejection
list does not imply that database, network, time or macro dependencies are pure.

The next substantive batches should preserve complete outputs and errors:

1. Kanidm value-set conversions and entry differences/merge logic. Inventory
   examples include `Entry::idx_diff` and `Entry::merge_state`; model actual set,
   ordering, change-state and error semantics before claiming their callers.
2. Artifactkeeper deterministic input scanners and repository metadata writers.
   Examples include `mask_message_args` and `generate_primary_xml_with`; isolate
   external callbacks and compare exact byte outputs, including malformed input.
3. OxiCloud and Tuwunel parsing, policy and configuration transformations. Keep
   schema decoding, filesystem/network effects and current-time reads explicit.
4. Nora rendering/parsing can add broader pure behavior, but macros and callback
   data must be accounted for rather than mapping templates to placeholder text.

Each checkpoint still requires unchanged prior property statements, exact pinned
source spans, differential validation, complete new properties, full project and
axiom gates, extraction reproducibility, refreshed dashboard detail checks, then
commit and push. Neither enum declarations nor test/generated files add upstream
line credit. Do not count dependency bodies that have not actually been ported.
