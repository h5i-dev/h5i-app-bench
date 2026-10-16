# tuwunel: what the kernel covers and where it differs

Upstream: matrix-construct/tuwunel @ 7801b8e. The kernel ports who may see
what in a room: the history-visibility checks, the state-cache, timeline,
relation and thread reads under them, and the client endpoints that apply
them. `transition(snapshot, request)` returns the reply (event ids and
pagination tokens) or the error kind. `difftest/count_loc.py`: 2492 lines of
ported upstream code, plus 1489 lines of copied stream and future
combinators that run but are counted apart.

## Covered

| Kernel | Upstream |
|---|---|
| `svc_accessor::user_can_see_event`, `user_shared_history`, `user_can_see_state_events`, `user_can_see_room` | `service/rooms/state_accessor/user_can.rs` |
| `svc_accessor::user_was_joined`, `user_was_invited`, `user_membership`, `state_get`, `state_get_id`, `history_visibility_at` (`state_get_content`), `state_full`, `state_full_pdus`, `state_full_pdus_strict`, `state_full_ids`, `load_full_state` | `state_accessor/state.rs` |
| `svc_accessor::room_state_get`, `room_state_full`, `room_state_full_pdus`, `room_history_visibility` (`room_state_get_content`) | `state_accessor/room_state.rs` |
| `svc_accessor::server_can_see_event` | `state_accessor/server_can.rs` |
| `svc_accessor::is_world_readable` | `state_accessor/mod.rs` |
| `svc_cache::*` | `state_cache/mod.rs` `is_joined`, `is_invited`, `is_knocked`, `is_left`, `once_joined`, `get_left_count`, `user_membership`, `room_members` |
| `svc_timeline::pdus`, `pdus_rev`, `get_pdu`, `get_non_outlier`, `get_outlier`, `get_pdu_id`, `get_pdu_count`, `get_pdu_from_id`, `next_timeline_count`, `shortstatehash_after`, `next_shortstatehash`, `last_timeline_count` | `timeline/{mod,pdus}.rs` (with `count_to_id`, `pdu_count_to_id`, `each_slice`, `each_pdu`) |
| `svc_timeline::exists`, `get_shortroomid`, `get_room_shortstatehash`, `pdu_shortstatehash` | `metadata::exists`, `short::get_shortroomid`, `state::{get_room_shortstatehash, pdu_shortstatehash, get_shortstatehash}` |
| `svc_relations::get_relations`, `has_incoming_relation`, `relation_type_equal` | `pdu_metadata/relations.rs`, `core/matrix/event/relation.rs` |
| `svc_threads::threads_until`, `live_thread`, `is_participant` | `threads/mod.rs` |
| `filters::matches` and its parts | `core/matrix/event/filter.rs` `Matches<&E> for RoomEventFilter` |
| `filters::is_forbidden_remote_server_name` | `core/config/net.rs` |
| `api_message::get_message_events_route`, `get_messages`, `event_filters`, `related_by_filter`, `ignored_filter`, `is_ignored_pdu`, `visibility_filter`, `event_filter` | `api/client/message.rs` |
| `api_context::get_context_route`, `event_context`, `resolve_base_event`, `collect_timeline_half`, `load_state_ids`, `build_state_response` | `api/client/context.rs` |
| `api_relations::paginate_relations_with_filter` (the three routes pass their optional relation and event type) | `api/client/relations.rs` |
| `api_threads::get_threads_route` | `api/client/threads.rs` |
| `api_state::get_state_events_route`, `get_state_events_for_key_route` | `api/client/state.rs` |
| `api_members::get_member_events_route`, `joined_members_route` | `api/client/membership/members.rs` |
| `api_room::room_initial_sync_route`, `departure_snapshot`, `get_room_event_route` | `api/client/room/{initial_sync,event}.rs` |

## How it is checked

`difftest/extract_upstream.py` copies these files and items verbatim from
the commit into crates laid out like upstream's (`difftest/upstream/`), so
`crate::` paths and `#[implement(..)]` resolve unchanged; `use` lines are
pruned to the names the copied items use. Hand-written stubs supply the
rest: ruma's ids, event types and request/response structs; the error type
and its macros; a `Pdu` with the `Event` accessors; the `implement` macro;
and an in-memory database whose columns are ordered byte maps with
upstream's key encoding (`RawPduId` bytes, `0xFF`-separated tuples,
big-endian counts), so the copied scans (`raw_stream_from`,
`rev_raw_keys_from`, ...) read the same rows in the same order as on
RocksDB. The `short` and `state_compressor` lookups are transcribed.

`tests.rs` builds random rooms by appending events the way the append path
does (state before each event, current state, the state cache as
`update_membership` leaves it, relation and thread indexes), perturbs some,
and compares the kernel's reply with the copied route's on 240,000
requests; it also asserts that ten subtle paths are taken (interleaved
`/relations` recursion, the backward `/messages` token at stream end, `to`
bounds, departed users in `initialSync`, ...). Seven kernel mutations (a
`<=` to `<` in `user_shared_history`, the `from` bound of `pdus`, the queue
order of the `/relations` recursion, `once_joined` to `is_left` in
`user_can_see_state_events`, the thread token bound, the backward `to`
bound, the server allow list) each fail it.

`props.rs` checks each statement of `proofs/Properties.lean` on random
inputs, with its premises holding at least 300 times.

## Not covered (trusted input)

- Parsing: tokens arrive as `Token::{Absent, At(count), Invalid}`; ids are
  numbers. The server of user `u` is `u / 1000`.
- Lazy loading of members is off (`/messages` returns no `state`, `/context`
  the full state). Presentation is not modeled: `unsigned` (age,
  transaction ids, MSC4115 `membership`), bundled aggregations, the MSC3856
  ignored-thread view, event formats.
- Federation is off: no backfill, no remote fetch of a missing `/context`
  event.
- Writes: upstream's `live_thread` deletes stale thread activity rows while
  reading; one request runs per snapshot, so the kernel ignores the delete.
- `/event` with `include_unredacted_content` (power levels) is not ported.
- Not ported: sync v3/v5, search, `/timestamp_to_event`, room summary,
  redaction and invite authorization (`user_can_redact`, `user_can_invite`),
  state resolution and the append path.

## Differences in form

| Where | Upstream | Kernel | Why |
|---|---|---|---|
| everywhere | async services over a key-value store | functions over `Snapshot` tables | Aeneas has no async; the scans become loops over tables kept in key order |
| `PduCount` | `Normal(u64)` or `Backfilled(i64)` | `i64` (`into_signed`) | the snapshot holds only normal (positive) counts; `saturating_inc` in `get_relations` is kept on the encoded bits (`inc_bits`) |
| `pdus`, `pdus_rev`, `threads_until` | a raw key range from `pdu_count_to_id(..)` | rows with count `> from` / `< until` | the same rows for normal counts, including tokens at or below zero (backfilled layout sorts before every normal row) |
| `state_get_id` | resolves the short state key, then loads the snapshot | loads the snapshot, then searches it | the error kinds differ only when the snapshot is missing; the append path always stores it |
| state entries | a `BTreeSet` of `(shortstatekey, shorteventid)` | entries in short-state-key order | the generator keeps them in that order |
| streams | `buffered`, `select_all`, `unfold`, `take(n)` | loops; `/relations` keeps a FIFO queue of streams, a yielding stream re-queued before its child | the copied `select_all` polls in that order; the test exercises it |
| `scanned` in `get_messages` | set by `inspect`, which may run ahead of `take` | the last row examined | it is read only when the stream ended before `limit`, when both agree |
| `joined_members` | a map keyed by user id | senders in state order | the test compares sorted sets |
| server name lists | regex sets | exact names | the test alphabet has no patterns |
| `Option::clone`, `Vec::is_empty`, `truncate`, `div_ceil` | library | written out | Aeneas axiomatizes them |
| modules | `message`, `context`, `state`, ... | `api_message`, `svc_accessor`, ... | a Lean module name must not equal a local variable name |
