import Verified.TuwunelTotalityTimeline
open Aeneas Aeneas.Std Result tuwunel_kernel tuwunel_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP
namespace tuwunel_kernel.Verified.TuwunelTransitionTotal
set_option maxHeartbeats 2000000
set_option maxRecDepth 4096
set_option linter.unusedSimpArgs false
set_option linter.unusedVariables false
set_option allowUnsafeReducibility true
attribute [local reducible] Aeneas.Std.WP.Post

@[step] theorem svc_relations.push_relation_total (s : Snapshot) (shortroomid : Std.U64) («from» : Std.U64) (out : alloc.vec.Vec (Std.I64 × Std.Usize)) (h_out : Good (s.pdus.length) out) (hcap : out.length < Usize.max) :
    svc_relations.push_relation s shortroomid «from» out ⦃ r => Good (s.pdus.length) r ∧ r.length ≤ out.length + 1 ⦄ := by
  unfold svc_relations.push_relation
  run

@[step] theorem svc_relations.inc_bits_total (c : Std.I64) (dir : Dir)  :
    svc_relations.inc_bits c dir ⦃ r => True ⦄ := by
  unfold svc_relations.inc_bits
  run

@[step] theorem svc_relations.get_relations_loop0_total (s : Snapshot) (shortroomid : Std.U64) (target_bits : Std.U64) (start : Std.U64) (out : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_out : Good (s.pdus.length) out) (hsize : out.length ≤ i.val) (hi : i.val ≤ s.relations.length) :
    svc_relations.get_relations_loop0 s shortroomid target_bits start out i ⦃ r => Good (s.pdus.length) r ∧ r.length ≤ s.relations.length ⦄ := by
  unfold svc_relations.get_relations_loop0
  apply loop_idx_spec _ (fun x => x.2) (s.relations.length) (fun x => x.1.length ≤ (x.2).val ∧ Good (s.pdus.length) x.1) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨out, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_relations.get_relations_loop0.body
    run
  all_goals clean

@[step] theorem svc_relations.get_relations_loop1_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (i : Std.I64) (shortroomid : Std.U64) (target_bits : Std.U64) (start : Std.U64) (out : alloc.vec.Vec (Std.I64 × Std.Usize)) (i1 : Std.Usize) (h_out : Good (v1.length) out) (hsize : out.length + i1.val ≤ v8.length) (hi : i1.val ≤ v8.length) :
    svc_relations.get_relations_loop1 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c i shortroomid target_bits start out i1 ⦃ r => Good (v1.length) r ∧ r.length ≤ v8.length ⦄ := by
  unfold svc_relations.get_relations_loop1
  apply loop.spec_decr_nat (measure := fun x => (x.2).val) (inv := fun x => x.1.length + (x.2).val ≤ v8.length ∧ Good (v1.length) x.1 ∧ (x.2).val ≤ v8.length)
  · intro x hin
    rcases x with ⟨out, i1⟩
    try dsimp only at hin
    try simp only [Good, Indexed.valid] at hin
    unfold svc_relations.get_relations_loop1.body
    run
  all_goals clean

@[step] theorem svc_relations.get_relations_total (s : Snapshot) (shortroomid : Std.U64) (target : Std.I64) («from» : Option Std.I64) (dir : Dir)  :
    svc_relations.get_relations s shortroomid target «from» dir ⦃ r => Good (s.pdus.length) r ∧ r.length ≤ s.relations.length ⦄ := by
  unfold svc_relations.get_relations
  run

@[step] theorem svc_relations.has_incoming_relation_loop_total (s : Snapshot) (senders : Slice Std.U64) (rel_types : Slice RelType) (rels : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_rels : Good (s.pdus.length) rels) (hi : i.val ≤ rels.length) :
    svc_relations.has_incoming_relation_loop s senders rel_types rels i ⦃ r => True ⦄ := by
  unfold svc_relations.has_incoming_relation_loop
  apply loop_idx_spec _ (fun x => x) (rels.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_relations.has_incoming_relation_loop.body
    run
  all_goals clean

@[step] theorem svc_relations.has_incoming_relation_total (s : Snapshot) (shortroomid : Std.U64) (count : Std.I64) (senders : Slice Std.U64) (rel_types : Slice RelType)  :
    svc_relations.has_incoming_relation s shortroomid count senders rel_types ⦃ r => True ⦄ := by
  unfold svc_relations.has_incoming_relation
  run

@[step] theorem api_message.related_by_filter_total (s : Snapshot) (shortroomid : Std.U64) (filter : Filter) (count : Std.I64)  :
    api_message.related_by_filter s shortroomid filter count ⦃ r => True ⦄ := by
  unfold api_message.related_by_filter
  run

@[step] theorem svc_timeline.get_pdu_id_total (s : Snapshot) (event_id : Std.U64)  :
    svc_timeline.get_pdu_id s event_id ⦃ r => True ⦄ := by
  unfold svc_timeline.get_pdu_id
  run

@[step] theorem svc_timeline.get_pdu_count_total (s : Snapshot) (event_id : Std.U64)  :
    svc_timeline.get_pdu_count s event_id ⦃ r => True ⦄ := by
  unfold svc_timeline.get_pdu_count
  run

@[step] theorem svc_cache.get_left_count_loop_total (s : Snapshot) (room : Std.U64) (user : Std.U64) (i : Std.Usize) (hi : i.val ≤ s.left.length) :
    svc_cache.get_left_count_loop s room user i ⦃ r => True ⦄ := by
  unfold svc_cache.get_left_count_loop
  apply loop_idx_spec _ (fun x => x) (s.left.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_cache.get_left_count_loop.body
    run
  all_goals clean

@[step] theorem svc_cache.get_left_count_total (s : Snapshot) (room : Std.U64) (user : Std.U64)  :
    svc_cache.get_left_count s room user ⦃ r => True ⦄ := by
  unfold svc_cache.get_left_count
  run

@[step] theorem svc_cache.has_row_loop_total (rows : Slice UserRoom) (user : Std.U64) (room : Std.U64) (i : Std.Usize) (hi : i.val ≤ rows.length) :
    svc_cache.has_row_loop rows user room i ⦃ r => True ⦄ := by
  unfold svc_cache.has_row_loop
  apply loop_idx_spec _ (fun x => x) (rows.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_cache.has_row_loop.body
    run
  all_goals clean

@[step] theorem svc_cache.has_row_total (rows : Slice UserRoom) (user : Std.U64) (room : Std.U64)  :
    svc_cache.has_row rows user room ⦃ r => True ⦄ := by
  unfold svc_cache.has_row
  run

@[step] theorem svc_cache.is_joined_total (s : Snapshot) (user : Std.U64) (room : Std.U64)  :
    svc_cache.is_joined s user room ⦃ r => True ⦄ := by
  unfold svc_cache.is_joined
  run

@[step] theorem svc_cache.once_joined_total (s : Snapshot) (user : Std.U64) (room : Std.U64)  :
    svc_cache.once_joined s user room ⦃ r => True ⦄ := by
  unfold svc_cache.once_joined
  run

@[step] theorem svc_accessor.find_entry_loop_total (entries : Slice StateEntry) (kind : Kind) (state_key : Std.U64) (i : Std.Usize) (hi : i.val ≤ entries.length) :
    svc_accessor.find_entry_loop entries kind state_key i ⦃ r => True ⦄ := by
  unfold svc_accessor.find_entry_loop
  apply loop_idx_spec _ (fun x => x) (entries.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_accessor.find_entry_loop.body
    run
  all_goals clean

@[step] theorem svc_accessor.find_entry_total (entries : Slice StateEntry) (kind : Kind) (state_key : Std.U64)  :
    svc_accessor.find_entry entries kind state_key ⦃ r => True ⦄ := by
  unfold svc_accessor.find_entry
  run

@[step] theorem svc_accessor.state_get_id_total (s : Snapshot) (hash : Std.U64) (kind : Kind) (state_key : Std.U64)  :
    svc_accessor.state_get_id s hash kind state_key ⦃ r => True ⦄ := by
  unfold svc_accessor.state_get_id
  run

@[step] theorem svc_accessor.state_get_total (s : Snapshot) (hash : Std.U64) (kind : Kind) (state_key : Std.U64)  :
    svc_accessor.state_get s hash kind state_key ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_accessor.state_get
  run

@[step] theorem svc_accessor.user_membership_total (s : Snapshot) (hash : Std.U64) (user : Std.U64)  :
    svc_accessor.user_membership s hash user ⦃ r => True ⦄ := by
  unfold svc_accessor.user_membership
  run

@[step] theorem svc_accessor.user_was_joined_total (s : Snapshot) (hash : Std.U64) (user : Std.U64)  :
    svc_accessor.user_was_joined s hash user ⦃ r => True ⦄ := by
  unfold svc_accessor.user_was_joined
  run

@[step] theorem svc_accessor.user_shared_history_total (s : Snapshot) (hash : Std.U64) (room : Std.U64) (event_id : Std.U64) (user : Std.U64)  :
    svc_accessor.user_shared_history s hash room event_id user ⦃ r => True ⦄ := by
  unfold svc_accessor.user_shared_history
  run

@[step] theorem svc_accessor.user_was_invited_total (s : Snapshot) (hash : Std.U64) (user : Std.U64)  :
    svc_accessor.user_was_invited s hash user ⦃ r => True ⦄ := by
  unfold svc_accessor.user_was_invited
  run

@[step] theorem svc_accessor.history_visibility_at_total (s : Snapshot) (hash : Std.U64)  :
    svc_accessor.history_visibility_at s hash ⦃ r => True ⦄ := by
  unfold svc_accessor.history_visibility_at
  run

@[step] theorem svc_accessor.user_can_see_event_total (s : Snapshot) (user : Std.U64) (room : Std.U64) (event_id : Std.U64)  :
    svc_accessor.user_can_see_event s user room event_id ⦃ r => True ⦄ := by
  unfold svc_accessor.user_can_see_event
  run

@[step] theorem api_message.visibility_filter_total (s : Snapshot) (p : Std.Usize) (user : Std.U64) (h_p : p.val < s.pdus.length) :
    api_message.visibility_filter s p user ⦃ r => True ⦄ := by
  unfold api_message.visibility_filter
  run

@[step] theorem server_name_total (user : Std.U64)  :
    server_name user ⦃ r => True ⦄ := by
  unfold server_name
  run

@[step] theorem filters.is_forbidden_remote_server_name_total (c : Config) (server : Std.U64)  :
    filters.is_forbidden_remote_server_name c server ⦃ r => True ⦄ := by
  unfold filters.is_forbidden_remote_server_name
  run

@[step] theorem api_message.user_is_ignored_loop_total (s : Snapshot) (sender : Std.U64) (user : Std.U64) (i : Std.Usize) (hi : i.val ≤ s.ignored.length) :
    api_message.user_is_ignored_loop s sender user i ⦃ r => True ⦄ := by
  unfold api_message.user_is_ignored_loop
  apply loop_idx_spec _ (fun x => x) (s.ignored.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_message.user_is_ignored_loop.body
    run
  all_goals clean

@[step] theorem api_message.user_is_ignored_total (s : Snapshot) (sender : Std.U64) (user : Std.U64)  :
    api_message.user_is_ignored s sender user ⦃ r => True ⦄ := by
  unfold api_message.user_is_ignored
  run

@[step] theorem api_message.is_ignored_message_type_total (k : Kind)  :
    api_message.is_ignored_message_type k ⦃ r => True ⦄ := by
  unfold api_message.is_ignored_message_type
  run

@[step] theorem api_message.is_ignored_pdu_total (s : Snapshot) (p : Pdu) (user : Std.U64)  :
    api_message.is_ignored_pdu s p user ⦃ r => True ⦄ := by
  unfold api_message.is_ignored_pdu api_message.is_ignored_message_type
  run

@[step] theorem api_message.ignored_filter_total (s : Snapshot) (p : Std.Usize) (user : Std.U64) (h_p : p.val < s.pdus.length) :
    api_message.ignored_filter s p user ⦃ r => True ⦄ := by
  unfold api_message.ignored_filter
  run

@[step] theorem api_message.event_filters_total (s : Snapshot) (user : Std.U64) (p : Std.Usize) (bypass_visibility : Bool) (h_p : p.val < s.pdus.length) :
    api_message.event_filters s user p bypass_visibility ⦃ r => True ⦄ := by
  unfold api_message.event_filters
  run

@[step] theorem api_message.passes_total (s : Snapshot) (user : Std.U64) (filter : Filter) (shortroomid : Std.U64) (count : Std.I64) (p : Std.Usize) (bypass_visibility : Bool) (h_p : p.val < s.pdus.length) :
    api_message.passes s user filter shortroomid count p bypass_visibility ⦃ r => True ⦄ := by
  unfold api_message.passes
  run

@[step] theorem api_context.collect_timeline_half_loop_total (s : Snapshot) (user : Std.U64) (filter : Filter) (shortroomid : Std.U64) (bypass_visibility : Bool) (it : Slice Std.Usize) (take : Std.U64) (out : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (s.pdus.length) it) (h_out : Good (s.pdus.length) out) (hsize : out.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_context.collect_timeline_half_loop s user filter shortroomid bypass_visibility it take out i ⦃ r => Good (s.pdus.length) r ∧ r.length ≤ it.length ⦄ := by
  unfold api_context.collect_timeline_half_loop
  apply loop_idx_spec _ (fun x => x.2) (it.length) (fun x => x.1.length ≤ (x.2).val ∧ Good (s.pdus.length) x.1) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨out, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_context.collect_timeline_half_loop.body
    run
  all_goals clean

@[step] theorem api_context.collect_timeline_half_total (s : Snapshot) (user : Std.U64) (filter : Filter) (shortroomid : Std.U64) (bypass_visibility : Bool) (it : Slice Std.Usize) (take : Std.U64) (h_it : Good (s.pdus.length) it) :
    api_context.collect_timeline_half s user filter shortroomid bypass_visibility it take ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold api_context.collect_timeline_half
  run

@[step] theorem api_context.resolve_base_event_total (s : Snapshot) (room : Std.U64) (event_id : Std.U64) (user : Std.U64) (bypass_visibility : Bool)  :
    api_context.resolve_base_event s room event_id user bypass_visibility ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold api_context.resolve_base_event
  run

@[step] theorem api_context.event_context_total (s : Snapshot) (user : Std.U64) (room : Std.U64) (event_id : Std.U64) (limit : Option Std.U64) (filter : Filter) (bypass_visibility : Bool)  :
    api_context.event_context s user room event_id limit filter bypass_visibility ⦃ r => True ⦄ := by
  unfold api_context.event_context
  run

@[step] theorem api_context.get_context_route_total (s : Snapshot) (user : Std.U64) (room : Std.U64) (event : Std.U64) (limit : Std.U64) (filter : Filter)  :
    api_context.get_context_route s user room event limit filter ⦃ r => True ⦄ := by
  unfold api_context.get_context_route
  run

@[step] theorem membership_eq_total (a : Membership) (b : Membership)  :
    membership_eq a b ⦃ r => True ⦄ := by
  unfold membership_eq
  run

@[step] theorem api_members.membership_filter_total (m : Membership) (membership : Option Membership) (not_membership : Option Membership)  :
    api_members.membership_filter m membership not_membership ⦃ r => True ⦄ := by
  unfold api_members.membership_filter
  run

@[step] theorem svc_timeline.shortstatehash_at_total (s : Snapshot) (short : Std.U64) (count : Std.I64)  :
    svc_timeline.shortstatehash_at s short count ⦃ r => True ⦄ := by
  unfold svc_timeline.shortstatehash_at
  run

@[step] theorem svc_timeline.next_timeline_count_loop_total (s : Snapshot) (room : Std.U64) (after : Std.I64) (i : Std.Usize) (hi : i.val ≤ s.pdus.length) :
    svc_timeline.next_timeline_count_loop s room after i ⦃ r => True ⦄ := by
  unfold svc_timeline.next_timeline_count_loop
  apply loop_idx_spec _ (fun x => x) (s.pdus.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_timeline.next_timeline_count_loop.body
    run
  all_goals clean

@[step] theorem svc_timeline.next_timeline_count_total (s : Snapshot) (room : Std.U64) (after : Std.I64)  :
    svc_timeline.next_timeline_count s room after ⦃ r => True ⦄ := by
  unfold svc_timeline.next_timeline_count
  run

@[step] theorem svc_timeline.shortstatehash_after_total (s : Snapshot) (room : Std.U64) (count : Std.I64)  :
    svc_timeline.shortstatehash_after s room count ⦃ r => True ⦄ := by
  unfold svc_timeline.shortstatehash_after
  run

@[step] theorem svc_cache.is_invited_total (s : Snapshot) (user : Std.U64) (room : Std.U64)  :
    svc_cache.is_invited s user room ⦃ r => True ⦄ := by
  unfold svc_cache.is_invited
  run

@[step] theorem svc_accessor.room_state_get_total (s : Snapshot) (room : Std.U64) (kind : Kind) (state_key : Std.U64)  :
    svc_accessor.room_state_get s room kind state_key ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_accessor.room_state_get
  run

@[step] theorem svc_accessor.room_history_visibility_total (s : Snapshot) (room : Std.U64)  :
    svc_accessor.room_history_visibility s room ⦃ r => True ⦄ := by
  unfold svc_accessor.room_history_visibility
  run

@[step] theorem svc_accessor.user_can_see_state_events_total (s : Snapshot) (user : Std.U64) (room : Std.U64)  :
    svc_accessor.user_can_see_state_events s user room ⦃ r => True ⦄ := by
  unfold svc_accessor.user_can_see_state_events
  run

@[step] theorem svc_accessor.state_full_pdus_loop_total (s : Snapshot) (ids : alloc.vec.Vec Std.U64) (out : alloc.vec.Vec Std.Usize) (i : Std.Usize) (h_out : Good (s.pdus.length) out) (hsize : out.length ≤ i.val) (hi : i.val ≤ ids.length) :
    svc_accessor.state_full_pdus_loop s ids out i ⦃ r => Good (s.pdus.length) r ∧ r.length ≤ ids.length ⦄ := by
  unfold svc_accessor.state_full_pdus_loop
  apply loop_idx_spec _ (fun x => x.2) (ids.length) (fun x => x.1.length ≤ (x.2).val ∧ Good (s.pdus.length) x.1) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨out, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_accessor.state_full_pdus_loop.body
    run
  all_goals clean

@[step] theorem svc_accessor.state_full_pdus_total (s : Snapshot) (hash : Std.U64)  :
    svc_accessor.state_full_pdus s hash ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_accessor.state_full_pdus
  run

@[step] theorem svc_accessor.state_full_loop_total (s : Snapshot) (all : alloc.vec.Vec Std.Usize) (out : alloc.vec.Vec Std.Usize) (i : Std.Usize) (h_all : Good (s.pdus.length) all) (h_out : Good (s.pdus.length) out) (hsize : out.length ≤ i.val) (hi : i.val ≤ all.length) :
    svc_accessor.state_full_loop s all out i ⦃ r => Good (s.pdus.length) r ∧ r.length ≤ all.length ⦄ := by
  unfold svc_accessor.state_full_loop
  apply loop_idx_spec _ (fun x => x.2) (all.length) (fun x => x.1.length ≤ (x.2).val ∧ Good (s.pdus.length) x.1) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨out, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_accessor.state_full_loop.body
    run
  all_goals clean

@[step] theorem svc_accessor.state_full_total (s : Snapshot) (hash : Std.U64)  :
    svc_accessor.state_full s hash ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_accessor.state_full
  run

@[step] theorem api_members.get_member_events_route_loop0_total (s : Snapshot) (membership : Option Membership) (not_membership : Option Membership) (v : alloc.vec.Vec Std.Usize) (chunk : alloc.vec.Vec Std.U64) (i : Std.Usize) (h_v : Good (s.pdus.length) v) (hsize : chunk.length ≤ i.val) (hi : i.val ≤ v.length) :
    api_members.get_member_events_route_loop0 s membership not_membership v chunk i ⦃ r => True ∧ r.length ≤ v.length ⦄ := by
  unfold api_members.get_member_events_route_loop0
  apply loop_idx_spec _ (fun x => x.2) (v.length) (fun x => x.1.length ≤ (x.2).val) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨chunk, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_members.get_member_events_route_loop0.body
    run
  all_goals clean

@[step] theorem api_members.get_member_events_route_loop1_total (s : Snapshot) (membership : Option Membership) (not_membership : Option Membership) (v : alloc.vec.Vec Std.Usize) (chunk : alloc.vec.Vec Std.U64) (i : Std.Usize) (h_v : Good (s.pdus.length) v) (hsize : chunk.length ≤ i.val) (hi : i.val ≤ v.length) :
    api_members.get_member_events_route_loop1 s membership not_membership v chunk i ⦃ r => True ∧ r.length ≤ v.length ⦄ := by
  unfold api_members.get_member_events_route_loop1
  apply loop_idx_spec _ (fun x => x.2) (v.length) (fun x => x.1.length ≤ (x.2).val) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨chunk, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_members.get_member_events_route_loop1.body
    run
  all_goals clean

@[step] theorem api_members.get_member_events_route_total (s : Snapshot) (user : Std.U64) (room : Std.U64) («at» : Token) (membership : Option Membership) (not_membership : Option Membership)  :
    api_members.get_member_events_route s user room «at» membership not_membership ⦃ r => True ⦄ := by
  unfold api_members.get_member_events_route
  run

@[step] theorem svc_accessor.room_state_full_total (s : Snapshot) (room : Std.U64)  :
    svc_accessor.room_state_full s room ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_accessor.room_state_full
  run

@[step] theorem api_members.joined_members_route_loop0_total (s : Snapshot) (v : alloc.vec.Vec Std.Usize) (joined : alloc.vec.Vec Std.U64) (i : Std.Usize) (h_v : Good (s.pdus.length) v) (hsize : joined.length ≤ i.val) (hi : i.val ≤ v.length) :
    api_members.joined_members_route_loop0 s v joined i ⦃ r => True ∧ r.length ≤ v.length ⦄ := by
  unfold api_members.joined_members_route_loop0
  apply loop_idx_spec _ (fun x => x.2) (v.length) (fun x => x.1.length ≤ (x.2).val) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨joined, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_members.joined_members_route_loop0.body
    run
  all_goals clean

@[step] theorem api_members.joined_members_route_loop1_total (s : Snapshot) (v : alloc.vec.Vec Std.Usize) (joined : alloc.vec.Vec Std.U64) (i : Std.Usize) (h_v : Good (s.pdus.length) v) (hsize : joined.length ≤ i.val) (hi : i.val ≤ v.length) :
    api_members.joined_members_route_loop1 s v joined i ⦃ r => True ∧ r.length ≤ v.length ⦄ := by
  unfold api_members.joined_members_route_loop1
  apply loop_idx_spec _ (fun x => x.2) (v.length) (fun x => x.1.length ≤ (x.2).val) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨joined, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_members.joined_members_route_loop1.body
    run
  all_goals clean

@[step] theorem api_members.joined_members_route_total (s : Snapshot) (user : Std.U64) (room : Std.U64)  :
    api_members.joined_members_route s user room ⦃ r => True ⦄ := by
  unfold api_members.joined_members_route
  run

@[step] theorem svc_cache.is_left_loop_total (s : Snapshot) (user : Std.U64) (room : Std.U64) (i : Std.Usize) (hi : i.val ≤ s.left.length) :
    svc_cache.is_left_loop s user room i ⦃ r => True ⦄ := by
  unfold svc_cache.is_left_loop
  apply loop_idx_spec _ (fun x => x) (s.left.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_cache.is_left_loop.body
    run
  all_goals clean

@[step] theorem svc_cache.is_left_total (s : Snapshot) (user : Std.U64) (room : Std.U64)  :
    svc_cache.is_left s user room ⦃ r => True ⦄ := by
  unfold svc_cache.is_left
  run

@[step] theorem svc_accessor.is_world_readable_total (s : Snapshot) (room : Std.U64)  :
    svc_accessor.is_world_readable s room ⦃ r => True ⦄ := by
  unfold svc_accessor.is_world_readable
  run

@[step] theorem svc_accessor.user_can_see_room_total (s : Snapshot) (user : Std.U64) (room : Std.U64)  :
    svc_accessor.user_can_see_room s user room ⦃ r => True ⦄ := by
  unfold svc_accessor.user_can_see_room
  run

@[step] theorem api_message.last_count_total (events : Slice (Std.I64 × Std.Usize)) :
    api_message.last_count events ⦃ r => True ⦄ := by
  unfold api_message.last_count
  run

@[step] theorem api_message.reached_to_total («to» : Option Std.I64) (dir : Dir) (count : Std.I64)  :
    api_message.reached_to «to» dir count ⦃ r => True ⦄ := by
  unfold api_message.reached_to
  run

@[step] theorem api_message.scan_loop_total (s : Snapshot) (user : Std.U64) (it : Slice Std.Usize) («to» : Option Std.I64) (dir : Dir) (limit : Std.U64) (filter : Filter) (shortroomid : Std.U64) (bypass_visibility : Bool) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (scanned : Option Std.I64) (done1 : Bool) (i : Std.Usize) (h_it : Good (s.pdus.length) it) (h_events : Good (s.pdus.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_message.scan_loop s user it «to» dir limit filter shortroomid bypass_visibility events scanned done1 i ⦃ r => Good (s.pdus.length) r ∧ r.1.length ≤ it.length ⦄ := by
  unfold api_message.scan_loop
  apply loop.spec_decr_nat (measure := fun x => 2 * (it.length - (x.2.2.2).val) + if x.2.2.1 then 0 else 1) (inv := fun x => x.1.length ≤ (x.2.2.2).val ∧ Good (s.pdus.length) x.1 ∧ x.2.2.2.val ≤ it.length)
  · intro x hin
    rcases x with ⟨events, scanned, done1, i⟩
    try dsimp only at hin
    try simp only [Good, Indexed.valid] at hin
    unfold api_message.scan_loop.body
    run
  all_goals clean

@[step] theorem api_message.scan_total (s : Snapshot) (user : Std.U64) (it : Slice Std.Usize) («to» : Option Std.I64) (dir : Dir) (limit : Std.U64) (filter : Filter) (shortroomid : Std.U64) (bypass_visibility : Bool) (h_it : Good (s.pdus.length) it) :
    api_message.scan s user it «to» dir limit filter shortroomid bypass_visibility ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold api_message.scan
  run


end tuwunel_kernel.Verified.TuwunelTransitionTotal
