# Tuwunel unconditional totality: relation queue capacity obstruction

The original `transition_total` statement quantifies over every `Snapshot` and
`Request`, without a size or well-formedness precondition. It has not been proved.
The following capacity obstruction is a mathematical construction, not a
completed machine-checked counterexample or an executable allocation test.

## Exact path

- `ports/tuwunel/kernel/src/api_relations.rs:136`: the walk loop bounds the
  number of accepted outputs, not the number of processed relations.
- `api_relations.rs:143`: every nonempty fetch position appends a continuation
  to `queue`, even when the later event-type filter rejects the event.
- `ports/tuwunel/proofs/generated/TuwunelKernel.lean:3884`: the extracted
  `api_relations.walk_loop.body` performs the corresponding `queue.push`.
- Pinned Aeneas `Aeneas/Std/Vec.lean:156`: `Vec.push` returns
  `fail maximumSizeExceeded` when the new length exceeds both `U32.max` and
  `Usize.max`. Existing vectors may have length exactly `Usize.max`.

## Construction

Let `N = Usize.max`. Use a valid room and two non-outlier PDUs in that room,
with positive counts 1 and 2. Give the target count 1 and the related PDU count
2. Let the relations vector contain `N` copies of `{ to := 1, from := 2 }`.
Duplicate relation rows are permitted by the unconditional theorem.

Request forward relations for the target, with absent pagination tokens,
`recurse = false`, positive limit, and an event-type filter different from the
related PDU's kind. Arrange room membership/visibility so the route enters
the walker and the target is not ignored.

`svc_relations.get_relations_loop0` pushes the same valid related PDU once per
row. Its output has length `N`, never greater than `N`. The `fetch_loop` keeps
all these entries because their counts are positive; its output also has
length `N`.

The walk starts with one queue item. With recursion disabled, every processed
entry appends exactly one continuation. The kind filter rejects every entry,
so the output vector stays empty and the positive result limit does not end
the walk. After `j` successful processing steps, the queue has length `j+1`,
and its next live item has position `j`. At `j = N-1`, both `qi+1` and `pos+1`
are representable (equal to `N`), but appending the last continuation attempts
to create a queue of length `N+1`, causing `maximumSizeExceeded`.

The failure propagates through `walk`, the relations route, and `transition`;
it is not wrapped as an application-level `.Err`. Thus a blanket totality
proof needs this obstruction resolved. This input is far too large to
allocate as a practical Rust test; that does not remove it from the Lean
statement's quantification.

No theorem statement, Rust implementation, generated code, or library was
changed. Potential remedies (requiring separate authorization) include a
bounded-size precondition or a queue representation which discards processed
continuations. A proof of the exact full counterexample remains future work.
