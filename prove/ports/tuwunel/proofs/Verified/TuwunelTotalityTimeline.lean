import Verified.TuwunelTotalitySupport
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

@[step] theorem svc_timeline.in_timeline_total (p : Pdu) (room : Std.U64)  :
    svc_timeline.in_timeline p room ⦃ r => True ⦄ := by
  unfold svc_timeline.in_timeline
  run

@[step] theorem svc_timeline.get_shortroomid_loop_total (s : Snapshot) (room : Std.U64) (i : Std.Usize) (hi : i.val ≤ s.rooms.length) :
    svc_timeline.get_shortroomid_loop s room i ⦃ r => True ⦄ := by
  unfold svc_timeline.get_shortroomid_loop
  apply loop_idx_spec _ (fun x => x) (s.rooms.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_timeline.get_shortroomid_loop.body
    run
  all_goals clean

@[step] theorem svc_timeline.get_shortroomid_total (s : Snapshot) (room : Std.U64)  :
    svc_timeline.get_shortroomid s room ⦃ r => True ⦄ := by
  unfold svc_timeline.get_shortroomid
  run

@[step] theorem svc_timeline.pdus_rev_loop_total (v : alloc.vec.Vec Pdu) (room : Std.U64) («until» : Std.I64) (out : alloc.vec.Vec Std.Usize) (i : Std.Usize) (h_out : Good (v.length) out) (hsize : out.length + i.val ≤ v.length) (hi : i.val ≤ v.length) :
    svc_timeline.pdus_rev_loop v room «until» out i ⦃ r => Good (v.length) r ∧ r.length ≤ v.length ⦄ := by
  unfold svc_timeline.pdus_rev_loop
  apply loop.spec_decr_nat (measure := fun x => (x.2).val) (inv := fun x => x.1.length + (x.2).val ≤ v.length ∧ Good (v.length) x.1 ∧ (x.2).val ≤ v.length)
  · intro x hin
    rcases x with ⟨out, i⟩
    try dsimp only at hin
    try simp only [Good, Indexed.valid] at hin
    unfold svc_timeline.pdus_rev_loop.body
    run
  all_goals clean

@[step] theorem svc_timeline.pdus_rev_total (s : Snapshot) (room : Std.U64) («until» : Std.I64)  :
    svc_timeline.pdus_rev s room «until» ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_timeline.pdus_rev
  run

@[step] theorem svc_timeline.pdus_loop_total (s : Snapshot) (room : Std.U64) («from» : Std.I64) (out : alloc.vec.Vec Std.Usize) (i : Std.Usize) (h_out : Good (s.pdus.length) out) (hsize : out.length ≤ i.val) (hi : i.val ≤ s.pdus.length) :
    svc_timeline.pdus_loop s room «from» out i ⦃ r => Good (s.pdus.length) r ∧ r.length ≤ s.pdus.length ⦄ := by
  unfold svc_timeline.pdus_loop
  apply loop_idx_spec _ (fun x => x.2) (s.pdus.length) (fun x => x.1.length ≤ (x.2).val ∧ Good (s.pdus.length) x.1) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨out, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_timeline.pdus_loop.body
    run
  all_goals clean

@[step] theorem svc_timeline.pdus_total (s : Snapshot) (room : Std.U64) («from» : Std.I64)  :
    svc_timeline.pdus s room «from» ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_timeline.pdus
  run

@[step] theorem svc_timeline.has_timeline_row_loop_total (s : Snapshot) (room : Std.U64) (i : Std.Usize) (hi : i.val ≤ s.pdus.length) :
    svc_timeline.has_timeline_row_loop s room i ⦃ r => True ⦄ := by
  unfold svc_timeline.has_timeline_row_loop
  apply loop_idx_spec _ (fun x => x) (s.pdus.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_timeline.has_timeline_row_loop.body
    run
  all_goals clean

@[step] theorem svc_timeline.has_timeline_row_total (s : Snapshot) (room : Std.U64)  :
    svc_timeline.has_timeline_row s room ⦃ r => True ⦄ := by
  unfold svc_timeline.has_timeline_row
  run

@[step] theorem svc_timeline.exists_total (s : Snapshot) (room : Std.U64)  :
    svc_timeline.exists s room ⦃ r => True ⦄ := by
  unfold svc_timeline.exists
  run

@[step] theorem api_message.event_ids_loop_total (s : Snapshot) (events : Slice (Std.I64 × Std.Usize)) (out : alloc.vec.Vec Std.U64) (i : Std.Usize) (h_events : Good (s.pdus.length) events) (hsize : out.length ≤ i.val) (hi : i.val ≤ events.length) :
    api_message.event_ids_loop s events out i ⦃ r => True ∧ r.length ≤ events.length ⦄ := by
  unfold api_message.event_ids_loop
  apply loop_idx_spec _ (fun x => x.2) (events.length) (fun x => x.1.length ≤ (x.2).val) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨out, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_message.event_ids_loop.body
    run
  all_goals clean

@[step] theorem api_message.event_ids_total (s : Snapshot) (events : Slice (Std.I64 × Std.Usize)) (h_events : Good (s.pdus.length) events) :
    api_message.event_ids s events ⦃ r => True ⦄ := by
  unfold api_message.event_ids
  run

@[step] theorem api_message.bounded_total (limit : Option Std.U64) (default : Std.U64) (max : Std.U64) (hd : default.val ≤ max.val) :
    api_message.bounded limit default max ⦃ r => r.val ≤ max.val ⦄ := by
  unfold api_message.bounded
  run

@[step] theorem svc_timeline.get_outlier_loop_total (s : Snapshot) (event_id : Std.U64) (i : Std.Usize) (hi : i.val ≤ s.pdus.length) :
    svc_timeline.get_outlier_loop s event_id i ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_timeline.get_outlier_loop
  apply loop_idx_spec _ (fun x => x) (s.pdus.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_timeline.get_outlier_loop.body
    run
  all_goals clean

@[step] theorem svc_timeline.get_outlier_total (s : Snapshot) (event_id : Std.U64)  :
    svc_timeline.get_outlier s event_id ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_timeline.get_outlier
  run

@[step] theorem svc_timeline.get_non_outlier_loop_total (s : Snapshot) (event_id : Std.U64) (i : Std.Usize) (hi : i.val ≤ s.pdus.length) :
    svc_timeline.get_non_outlier_loop s event_id i ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_timeline.get_non_outlier_loop
  apply loop_idx_spec _ (fun x => x) (s.pdus.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_timeline.get_non_outlier_loop.body
    run
  all_goals clean

@[step] theorem svc_timeline.get_non_outlier_total (s : Snapshot) (event_id : Std.U64)  :
    svc_timeline.get_non_outlier s event_id ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_timeline.get_non_outlier
  run

@[step] theorem svc_timeline.get_pdu_total (s : Snapshot) (event_id : Std.U64)  :
    svc_timeline.get_pdu s event_id ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_timeline.get_pdu
  run

@[step] theorem api_context.build_state_response_loop_total (s : Snapshot) (state_ids : Slice Std.U64) (out : alloc.vec.Vec Std.U64) (i : Std.Usize) (hsize : out.length ≤ i.val) (hi : i.val ≤ state_ids.length) :
    api_context.build_state_response_loop s state_ids out i ⦃ r => True ∧ r.length ≤ state_ids.length ⦄ := by
  unfold api_context.build_state_response_loop
  apply loop_idx_spec _ (fun x => x.2.2) (state_ids.length) (fun x => x.2.1.length ≤ (x.2.2).val) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨s, out, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_context.build_state_response_loop.body
    run
  all_goals clean

@[step] theorem api_context.build_state_response_total (s : Snapshot) (state_ids : Slice Std.U64)  :
    api_context.build_state_response s state_ids ⦃ r => True ⦄ := by
  unfold api_context.build_state_response
  run

@[step] theorem svc_timeline.state_of_total (p : Pdu)  :
    svc_timeline.state_of p ⦃ r => True ⦄ := by
  unfold svc_timeline.state_of
  run

@[step] theorem svc_timeline.pdu_shortstatehash_total (s : Snapshot) (event_id : Std.U64)  :
    svc_timeline.pdu_shortstatehash s event_id ⦃ r => True ⦄ := by
  unfold svc_timeline.pdu_shortstatehash
  run

@[step] theorem svc_timeline.get_room_shortstatehash_loop_total (s : Snapshot) (room : Std.U64) (i : Std.Usize) (hi : i.val ≤ s.rooms.length) :
    svc_timeline.get_room_shortstatehash_loop s room i ⦃ r => True ⦄ := by
  unfold svc_timeline.get_room_shortstatehash_loop
  apply loop_idx_spec _ (fun x => x) (s.rooms.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_timeline.get_room_shortstatehash_loop.body
    run
  all_goals clean

@[step] theorem svc_timeline.get_room_shortstatehash_total (s : Snapshot) (room : Std.U64)  :
    svc_timeline.get_room_shortstatehash s room ⦃ r => True ⦄ := by
  unfold svc_timeline.get_room_shortstatehash
  run

@[step] theorem svc_accessor.load_full_state_loop_total (s : Snapshot) (hash : Std.U64) (i : Std.Usize) (hi : i.val ≤ s.states.length) :
    svc_accessor.load_full_state_loop s hash i ⦃ r => Good (s.states.length) r ⦄ := by
  unfold svc_accessor.load_full_state_loop
  apply loop_idx_spec _ (fun x => x) (s.states.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_accessor.load_full_state_loop.body
    run
  all_goals clean

@[step] theorem svc_accessor.load_full_state_total (s : Snapshot) (hash : Std.U64)  :
    svc_accessor.load_full_state s hash ⦃ r => Good (s.states.length) r ⦄ := by
  unfold svc_accessor.load_full_state
  run

@[step] theorem svc_accessor.state_full_ids_loop_total (out : alloc.vec.Vec Std.U64) (entries : alloc.vec.Vec StateEntry) (i : Std.Usize) (hsize : out.length ≤ i.val) (hi : i.val ≤ entries.length) :
    svc_accessor.state_full_ids_loop out entries i ⦃ r => True ∧ r.length ≤ entries.length ⦄ := by
  unfold svc_accessor.state_full_ids_loop
  apply loop_idx_spec _ (fun x => x.2) (entries.length) (fun x => x.1.length ≤ (x.2).val) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨out, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_accessor.state_full_ids_loop.body
    run
  all_goals clean

@[step] theorem svc_accessor.state_full_ids_total (s : Snapshot) (hash : Std.U64)  :
    svc_accessor.state_full_ids s hash ⦃ r => True ⦄ := by
  unfold svc_accessor.state_full_ids
  run

@[step] theorem api_context.load_state_ids_total (s : Snapshot) (room : Std.U64) (state_at : Std.U64)  :
    api_context.load_state_ids s room state_at ⦃ r => True ⦄ := by
  unfold api_context.load_state_ids
  run

@[step] theorem filters.matches_url_total (p : Pdu) (filter : Filter)  :
    filters.matches_url p filter ⦃ r => True ⦄ := by
  unfold filters.matches_url
  run

@[step] theorem kind_eq_total (a : Kind) (b : Kind)  :
    kind_eq a b ⦃ r => True ⦄ := by
  unfold kind_eq
  run

@[step] theorem filters.any_kind_loop_total (v : Slice Kind) (k : Kind) (i : Std.Usize) (hi : i.val ≤ v.length) :
    filters.any_kind_loop v k i ⦃ r => True ⦄ := by
  unfold filters.any_kind_loop
  apply loop_idx_spec _ (fun x => x) (v.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold filters.any_kind_loop.body
    run
  all_goals clean

@[step] theorem filters.any_kind_total (v : Slice Kind) (k : Kind)  :
    filters.any_kind v k ⦃ r => True ⦄ := by
  unfold filters.any_kind
  run

@[step] theorem filters.matches_type_total (p : Pdu) (filter : Filter)  :
    filters.matches_type p filter ⦃ r => True ⦄ := by
  unfold filters.matches_type
  run

@[step] theorem contains_u64_loop_total (v : Slice Std.U64) (x : Std.U64) (i : Std.Usize) (hi : i.val ≤ v.length) :
    contains_u64_loop v x i ⦃ r => True ⦄ := by
  unfold contains_u64_loop
  apply loop_idx_spec _ (fun x => x) (v.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold contains_u64_loop.body
    run
  all_goals clean

@[step] theorem contains_u64_total (v : Slice Std.U64) (x : Std.U64)  :
    contains_u64 v x ⦃ r => True ⦄ := by
  unfold contains_u64
  run

@[step] theorem filters.matches_sender_total (p : Pdu) (filter : Filter)  :
    filters.matches_sender p filter ⦃ r => True ⦄ := by
  unfold filters.matches_sender
  run

@[step] theorem filters.matches_room_total (p : Pdu) (filter : Filter)  :
    filters.matches_room p filter ⦃ r => True ⦄ := by
  unfold filters.matches_room
  run

@[step] theorem filters.matches_total (filter : Filter) (p : Pdu)  :
    filters.matches filter p ⦃ r => True ⦄ := by
  unfold filters.matches
  run

@[step] theorem api_message.event_filter_total (s : Snapshot) (p : Std.Usize) (filter : Filter) (h_p : p.val < s.pdus.length) :
    api_message.event_filter s p filter ⦃ r => True ⦄ := by
  unfold api_message.event_filter
  run

@[step] theorem rel_type_eq_total (a : RelType) (b : RelType)  :
    rel_type_eq a b ⦃ r => True ⦄ := by
  unfold rel_type_eq
  run

@[step] theorem svc_relations.relation_type_equal_total (rel_type : RelType) (p : Pdu)  :
    svc_relations.relation_type_equal rel_type p ⦃ r => True ⦄ := by
  unfold svc_relations.relation_type_equal
  run

@[step] theorem svc_relations.any_rel_type_loop_total (rel_types : Slice RelType) (p : Pdu) (i : Std.Usize) (hi : i.val ≤ rel_types.length) :
    svc_relations.any_rel_type_loop rel_types p i ⦃ r => True ⦄ := by
  unfold svc_relations.any_rel_type_loop
  apply loop_idx_spec _ (fun x => x) (rel_types.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_relations.any_rel_type_loop.body
    run
  all_goals clean

@[step] theorem svc_relations.any_rel_type_total (rel_types : Slice RelType) (p : Pdu)  :
    svc_relations.any_rel_type rel_types p ⦃ r => True ⦄ := by
  unfold svc_relations.any_rel_type
  run

@[step] theorem svc_timeline.find_row_loop_total (s : Snapshot) (room : Std.U64) (count : Std.I64) (i : Std.Usize) (hi : i.val ≤ s.pdus.length) :
    svc_timeline.find_row_loop s room count i ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_timeline.find_row_loop
  apply loop_idx_spec _ (fun x => x) (s.pdus.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_timeline.find_row_loop.body
    run
  all_goals clean

@[step] theorem svc_timeline.find_row_total (s : Snapshot) (room : Std.U64) (count : Std.I64)  :
    svc_timeline.find_row s room count ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_timeline.find_row
  run

@[step] theorem svc_timeline.room_of_short_loop_total (s : Snapshot) (short : Std.U64) (i : Std.Usize) (hi : i.val ≤ s.rooms.length) :
    svc_timeline.room_of_short_loop s short i ⦃ r => True ⦄ := by
  unfold svc_timeline.room_of_short_loop
  apply loop_idx_spec _ (fun x => x) (s.rooms.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_timeline.room_of_short_loop.body
    run
  all_goals clean

@[step] theorem svc_timeline.room_of_short_total (s : Snapshot) (short : Std.U64)  :
    svc_timeline.room_of_short s short ⦃ r => True ⦄ := by
  unfold svc_timeline.room_of_short
  run

@[step] theorem svc_timeline.get_pdu_from_id_total (s : Snapshot) (short : Std.U64) (count : Std.I64)  :
    svc_timeline.get_pdu_from_id s short count ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_timeline.get_pdu_from_id
  run


end tuwunel_kernel.Verified.TuwunelTransitionTotal
