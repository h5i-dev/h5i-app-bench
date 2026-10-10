import HelpersScratch
open Aeneas Aeneas.Std Result tuwunel_kernel tuwunel_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP
namespace tuwunel_kernel.Solution
set_option maxHeartbeats 1000000
set_option maxRecDepth 4096
set_option linter.unusedVariables false
@[simp] theorem deref_val (v : alloc.vec.Vec α) :
    (alloc.vec.Vec.deref v).val = v.val := by simp [alloc.vec.Vec.deref]

open Lean Elab Tactic Meta in
elab "copy_good" : tactic => withMainContext do
  let decls ← getLCtx
  for d in decls do
    if d.isImplementationDetail then continue
    if d.type.isAppOfArity ``Good 4 then
      evalTactic (← `(tactic| (
        have h_good := $(mkIdent d.userName):ident
        dsimp only [Good, Indexed.valid] at h_good)))

macro "clean" : tactic => `(tactic| (
  copy_good
  try dsimp only [Good, Indexed.valid] at *
  all_goals (simp_all -failIfUnchanged [Good, Indexed.valid, List.mem_append, List.mem_singleton, api_context.LIMIT_MAX, api_context.LIMIT_DEFAULT, api_room.LIMIT_MAX, COUNT_MAX])
  all_goals try scalar_tac
  all_goals try grind))
open Lean Elab Tactic Meta in
elab "split_pair" : tactic => withMainContext do
  for d in ← getLCtx do
    if d.isImplementationDetail then continue
    if (← whnf d.type).isAppOfArity ``Prod 2 then
      evalTactic (← `(tactic| cases $(mkIdent d.userName):ident))
      return
  throwError "no pair"

open Lean Elab Tactic Meta in
elab "step_bounded" : tactic => withMainContext do
  let ds ← getLCtx
  for d in ds do
    if d.isImplementationDetail then continue
    if d.type.isConstOf ``Snapshot then
      evalTactic (← `(tactic| first
        | step with api_threads.truncate_total ($(mkIdent d.userName):ident).pdus.length
        | step with api_room.reversed_total ($(mkIdent d.userName):ident).pdus.length))
      return
  throwError "no snapshot"

macro "run" : tactic => `(tactic| (
  try simp only [core.num.I64.saturating_add, core.num.I64.saturating_sub, lift]
  repeat' (first | step_bounded | step | (dsimp only) | (simp only [bind_tc_ok, bind_ok, WP.spec_ok, Bool.false_eq_true, Bool.true_eq_false, ↓reduceIte, ↓reduceDIte]) | (simp only [bind_tc_ite, bind_ite]) | split | split_pair | (simp_all [Good, Indexed.valid, api_context.LIMIT_MAX, api_context.LIMIT_DEFAULT, api_room.LIMIT_MAX, COUNT_MAX]) | (solve | clean))
  all_goals clean))

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

@[step] theorem api_message.get_messages_total (s : Snapshot) (user : Std.U64) (room : Std.U64) («from» : Token) («to» : Token) (dir : Dir) (limit : Option Std.U64) (filter : Filter) (bypass_visibility : Bool)  :
    api_message.get_messages s user room «from» «to» dir limit filter bypass_visibility ⦃ r => True ⦄ := by
  unfold api_message.get_messages
  run

@[step] theorem api_message.get_message_events_route_total (s : Snapshot) (user : Std.U64) (room : Std.U64) («from» : Token) («to» : Token) (dir : Dir) (limit : Std.U64) (filter : Filter)  :
    api_message.get_message_events_route s user room «from» «to» dir limit filter ⦃ r => True ⦄ := by
  unfold api_message.get_message_events_route
  run
def cost (R d : Nat) : Nat :=
  match d with
  | 0 => R^3 + 2*R^2 + 2*R + 2
  | 1 => R^2 + 2*R + 2
  | 2 => R + 2
  | _ => 1

theorem cost_pos (R d : Nat) : 0 < cost R d := by
  unfold cost
  split <;> omega

theorem cost_next (R d : Nat) (hd : d < 3) :
    cost R d = 2 + R * cost R (d+1) := by
  have h : d = 0 ∨ d = 1 ∨ d = 2 := by omega
  rcases h with rfl | rfl | rfl <;> simp [cost] <;> ring

def weight (R : Nat) (f : api_relations.Fetch) : Nat :=
  1 + (R - f.pos.val) * cost R f.depth.val

theorem weight_pos (R : Nat) (f : api_relations.Fetch) : 0 < weight R f := by
  unfold weight; omega

theorem weight_succ (R : Nat) (f : api_relations.Fetch) (p : Usize)
    (hp : p.val = f.pos.val + 1) (hpos : f.pos.val < R) :
    weight R { f with pos := p } + cost R f.depth.val = weight R f := by
  simp only [weight]
  rw [hp]
  have he : R - f.pos.val = (R - (f.pos.val + 1)) + 1 := by omega
  rw [he]; ring

theorem weight_child (R : Nat) (d : U64) (l : Usize) :
    weight R { depth := d, list := l, pos := 0#usize } =
      1 + R * cost R d.val := by
  simp [weight]

theorem initial_weight (R : Nat) :
    1 + R * cost R 0 ≤ (R+1)^4 := by
  simp only [cost]
  nlinarith [Nat.zero_le (R^3), Nat.zero_le (R^2)]

def debt (R : Nat) (q : List api_relations.Fetch) : Nat :=
  (q.map (weight R)).sum

@[simp] theorem debt_nil (R : Nat) : debt R [] = 0 := rfl
@[simp] theorem debt_cons (R : Nat) (f : api_relations.Fetch) (q : List api_relations.Fetch) :
    debt R (f::q) = weight R f + debt R q := rfl
@[simp] theorem debt_append (R : Nat) (q q' : List api_relations.Fetch) :
    debt R (q++q') = debt R q + debt R q' := by
  simp [debt]

theorem debt_length (R : Nat) (q : List api_relations.Fetch) :
    q.length ≤ debt R q := by
  induction q with
  | nil => simp
  | cons f q ih => simp only [List.length_cons, debt_cons]; have := weight_pos R f; omega

theorem debt_drop (R : Nat) (q : List api_relations.Fetch) (i : Nat)
    (hi : i < q.length) :
    debt R (q.drop i) = weight R q[i] + debt R (q.drop (i+1)) := by
  rw [List.drop_eq_getElem_cons hi, debt_cons]

theorem queue_capacity (R : Nat) (q : List api_relations.Fetch) (i B : Nat)
    (hi : i ≤ q.length) (hb : i + debt R (q.drop i) ≤ B) : q.length ≤ B := by
  have := debt_length R (q.drop i)
  simp only [List.length_drop] at this
  omega


abbrev RelList := alloc.vec.Vec (I64 × Usize)
abbrev RelLists := alloc.vec.Vec RelList
abbrev FetchQueue := alloc.vec.Vec api_relations.Fetch

structure WalkCore (R N D : Nat) (lists : RelLists) (queue : FetchQueue) (qi : Usize) : Prop where
  listsGood : ∀ l ∈ lists.val, Good N l ∧ l.length ≤ R
  tasksGood : ∀ f ∈ queue.val, f.list.val < lists.length ∧ f.depth.val ≤ D ∧ f.pos.val ≤ R
  listsSize : lists.length ≤ queue.length
  cursor : qi.val ≤ queue.length
  fuel : qi.val + debt R (queue.val.drop qi.val) ≤ (R+1)^4

theorem WalkCore.capacity (h : WalkCore R N D lists queue qi) :
    queue.length ≤ (R+1)^4 :=
  queue_capacity R queue.val qi.val ((R+1)^4) h.cursor h.fuel

theorem WalkCore.advance (h : WalkCore R N D lists queue qi)
    (hi : qi.val < queue.length) (qi' : Usize) (hqi : qi'.val = qi.val+1) :
    WalkCore R N D lists queue qi' := by
  refine ⟨h.listsGood, h.tasksGood, h.listsSize, by omega, ?_⟩
  have hw := weight_pos R queue.val[qi.val]
  have he := debt_drop R queue.val qi.val hi
  have hf := h.fuel
  rw [he] at hf
  rw [hqi]
  omega

theorem WalkCore.next (h : WalkCore R N D lists queue qi)
    (hi : qi.val < queue.length) (f : api_relations.Fetch)
    (hf : f = queue.val[qi.val]) (p qi' : Usize)
    (hp : p.val = f.pos.val+1) (hpos : f.pos.val < R)
    (hqi : qi'.val = qi.val+1)
    (queue' : FetchQueue) (hq : queue'.val = queue.val ++ [{f with pos := p}]) :
    WalkCore R N D lists queue' qi' := by
  have hfm : f ∈ queue.val := hf ▸ List.getElem_mem hi
  obtain ⟨hl, hd, hb⟩ := h.tasksGood f hfm
  have hw := weight_succ R f p hp hpos
  have hc := cost_pos R f.depth.val
  have he := debt_drop R queue.val qi.val hi
  rw [← hf] at he
  have hfuel := h.fuel
  rw [he] at hfuel
  have hcursor : qi.val+1 ≤ queue.length := by omega
  refine ⟨h.listsGood, ?_, ?_, ?_, ?_⟩
  · intro a ha
    rw [hq] at ha
    simp only [List.mem_append, List.mem_singleton] at ha
    rcases ha with ha | rfl
    · exact h.tasksGood a ha
    · dsimp
      exact ⟨hl, hd, by omega⟩
  · have := h.listsSize
    simp only [alloc.vec.Vec.length, hq, List.length_append, List.length_singleton]
    simp only [alloc.vec.Vec.length] at *
    omega
  · simp only [alloc.vec.Vec.length, hq, List.length_append, List.length_singleton]
    simp only [alloc.vec.Vec.length] at *
    omega
  · simp only [hq, hqi, List.drop_append, Nat.sub_eq_zero_of_le hcursor,
      List.drop_zero, debt_append, debt_cons, debt_nil]
    omega

theorem WalkCore.child (h : WalkCore R N D lists queue qi)
    (hi : qi.val < queue.length) (f : api_relations.Fetch)
    (hf : f = queue.val[qi.val]) (p qi' : Usize)
    (hp : p.val = f.pos.val+1) (hpos : f.pos.val < R)
    (hqi : qi'.val = qi.val+1) (hD : D ≤ 3) (hd : f.depth.val < D)
    (child : RelList) (hc : Good N child ∧ child.length ≤ R)
    (lists' : RelLists) (hlists : lists'.val = lists.val ++ [child])
    (d' : U64) (hdepth : d'.val = f.depth.val+1)
    (li : Usize) (hli : li.val = lists.length)
    (queue' : FetchQueue)
    (hq : queue'.val = queue.val ++ [{f with pos := p},
      {depth := d', list := li, pos := 0#usize}]) :
    WalkCore R N D lists' queue' qi' := by
  have hfm : f ∈ queue.val := hf ▸ List.getElem_mem hi
  obtain ⟨hl, hdf, hb⟩ := h.tasksGood f hfm
  have hw := weight_succ R f p hp hpos
  have hnext := cost_next R f.depth.val (by omega)
  have hchild := weight_child R d' li
  rw [hdepth] at hchild
  have he := debt_drop R queue.val qi.val hi
  rw [← hf] at he
  have hfuel := h.fuel
  rw [he] at hfuel
  have hcursor : qi.val+1 ≤ queue.length := by omega
  have hlen : lists'.length = lists.length+1 := by
    simp [alloc.vec.Vec.length, hlists]
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · intro l hm
    rw [hlists] at hm
    simp only [List.mem_append, List.mem_singleton] at hm
    rcases hm with hm | rfl
    · exact h.listsGood l hm
    · exact hc
  · intro a ha
    rw [hq] at ha
    simp only [List.mem_append, List.mem_cons, List.not_mem_nil, or_false] at ha
    rcases ha with ha | rfl | rfl
    · obtain ⟨hal, had, hap⟩ := h.tasksGood a ha
      exact ⟨by scalar_tac, had, hap⟩
    · dsimp; exact ⟨by scalar_tac, hdf, by omega⟩
    · dsimp; exact ⟨by scalar_tac, by omega, by simp⟩
  · have := h.listsSize
    simp only [alloc.vec.Vec.length, hq, List.length_append, List.length_cons, List.length_nil]
    simp only [alloc.vec.Vec.length] at *
    omega
  · simp only [alloc.vec.Vec.length, hq, List.length_append, List.length_cons, List.length_nil]
    simp only [alloc.vec.Vec.length] at *
    omega
  · simp only [hq, hqi, List.drop_append, Nat.sub_eq_zero_of_le hcursor,
      List.drop_zero, debt_append, debt_cons, debt_nil]
    omega

@[step] theorem api_relations.walk_total (s : Snapshot) (user : Std.U64) (shortroomid : Std.U64) (target_count : Std.I64) («from» : Option Std.I64) (dir : Dir) (max_depth : Std.U64) («to» : Option Std.I64) (filter_event_type : Option Kind) (filter_rel_type : Option RelType) (limit : Std.U64) (hr : (s.relations.length + 1)^4 < Usize.max) (hd : max_depth.val ≤ 3) :
    api_relations.walk s user shortroomid target_count «from» dir max_depth «to» filter_event_type filter_rel_type limit ⦃ r => Good (s.pdus.length) r ⦄ := by
  sorry

@[step] theorem api_relations.max_depth_of_loop_total (events : Slice (Std.U64 × Std.I64 × Std.Usize)) (m : Std.U64) (i : Std.Usize) (hi : i.val ≤ events.length) :
    api_relations.max_depth_of_loop events m i ⦃ r => True ⦄ := by
  unfold api_relations.max_depth_of_loop
  apply loop_idx_spec _ (fun x => x.2) (events.length) (fun x => True) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨m, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_relations.max_depth_of_loop.body
    run
  all_goals clean

@[step] theorem api_relations.max_depth_of_total (events : Slice (Std.U64 × Std.I64 × Std.Usize)) :
    api_relations.max_depth_of events ⦃ r => True ⦄ := by
  unfold api_relations.max_depth_of
  run

@[step] theorem api_relations.empty_total   :
    api_relations.empty  ⦃ r => True ⦄ := by
  unfold api_relations.empty
  run

@[step] theorem api_relations.paginate_relations_with_filter_loop0_total (v : alloc.vec.Vec Pdu) (events : alloc.vec.Vec (Std.U64 × Std.I64 × Std.Usize)) (chunk : alloc.vec.Vec Std.U64) (i : Std.Usize) (h_events : Good (v.length) events) (hsize : chunk.length ≤ i.val) (hi : i.val ≤ events.length) :
    api_relations.paginate_relations_with_filter_loop0 v events chunk i ⦃ r => True ∧ r.length ≤ events.length ⦄ := by
  unfold api_relations.paginate_relations_with_filter_loop0
  apply loop_idx_spec _ (fun x => x.2) (events.length) (fun x => x.1.length ≤ (x.2).val) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨chunk, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_relations.paginate_relations_with_filter_loop0.body
    run
  all_goals clean

@[step] theorem api_relations.paginate_relations_with_filter_loop1_total (s : Snapshot) (events : alloc.vec.Vec (Std.U64 × Std.I64 × Std.Usize)) (chunk : alloc.vec.Vec Std.U64) (i : Std.Usize) (h_events : Good (s.pdus.length) events) (hsize : chunk.length ≤ i.val) (hi : i.val ≤ events.length) :
    api_relations.paginate_relations_with_filter_loop1 s events chunk i ⦃ r => True ∧ r.length ≤ events.length ⦄ := by
  unfold api_relations.paginate_relations_with_filter_loop1
  apply loop_idx_spec _ (fun x => x.2) (events.length) (fun x => x.1.length ≤ (x.2).val) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨chunk, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_relations.paginate_relations_with_filter_loop1.body
    run
  all_goals clean

@[step] theorem api_relations.paginate_relations_with_filter_loop2_total (v : alloc.vec.Vec Pdu) (events : alloc.vec.Vec (Std.U64 × Std.I64 × Std.Usize)) (chunk : alloc.vec.Vec Std.U64) (i : Std.Usize) (h_events : Good (v.length) events) (hsize : chunk.length ≤ i.val) (hi : i.val ≤ events.length) :
    api_relations.paginate_relations_with_filter_loop2 v events chunk i ⦃ r => True ∧ r.length ≤ events.length ⦄ := by
  unfold api_relations.paginate_relations_with_filter_loop2
  apply loop_idx_spec _ (fun x => x.2) (events.length) (fun x => x.1.length ≤ (x.2).val) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨chunk, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_relations.paginate_relations_with_filter_loop2.body
    run
  all_goals clean

@[step] theorem api_relations.paginate_relations_with_filter_loop3_total (s : Snapshot) (events : alloc.vec.Vec (Std.U64 × Std.I64 × Std.Usize)) (chunk : alloc.vec.Vec Std.U64) (i : Std.Usize) (h_events : Good (s.pdus.length) events) (hsize : chunk.length ≤ i.val) (hi : i.val ≤ events.length) :
    api_relations.paginate_relations_with_filter_loop3 s events chunk i ⦃ r => True ∧ r.length ≤ events.length ⦄ := by
  unfold api_relations.paginate_relations_with_filter_loop3
  apply loop_idx_spec _ (fun x => x.2) (events.length) (fun x => x.1.length ≤ (x.2).val) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨chunk, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_relations.paginate_relations_with_filter_loop3.body
    run
  all_goals clean

@[step] theorem api_relations.paginate_relations_with_filter_total (s : Snapshot) (user : Std.U64) (room : Std.U64) (target : Std.U64) (filter_event_type : Option Kind) (filter_rel_type : Option RelType) («from» : Token) («to» : Token) (limit : Option Std.U64) (recurse : Bool) (dir : Dir) (hr : (s.relations.length + 1)^4 < Usize.max) :
    api_relations.paginate_relations_with_filter s user room target filter_event_type filter_rel_type «from» «to» limit recurse dir ⦃ r => True ⦄ := by
  unfold api_relations.paginate_relations_with_filter
  run

@[step] theorem svc_cache.is_knocked_total (s : Snapshot) (user : Std.U64) (room : Std.U64)  :
    svc_cache.is_knocked s user room ⦃ r => True ⦄ := by
  unfold svc_cache.is_knocked
  run

@[step] theorem svc_cache.user_membership_total (s : Snapshot) (user : Std.U64) (room : Std.U64)  :
    svc_cache.user_membership s user room ⦃ r => True ⦄ := by
  unfold svc_cache.user_membership
  run

@[step] theorem svc_accessor.resolve_all_loop_total (s : Snapshot) (entries : Slice StateEntry) (out : alloc.vec.Vec Std.Usize) (i : Std.Usize) (h_out : Good (s.pdus.length) out) (hsize : out.length ≤ i.val) (hi : i.val ≤ entries.length) :
    svc_accessor.resolve_all_loop s entries out i ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_accessor.resolve_all_loop
  apply loop_idx_spec _ (fun x => x.2) (entries.length) (fun x => x.1.length ≤ (x.2).val ∧ Good (s.pdus.length) x.1) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨out, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_accessor.resolve_all_loop.body
    run
  all_goals clean

@[step] theorem svc_accessor.resolve_all_total (s : Snapshot) (entries : Slice StateEntry)  :
    svc_accessor.resolve_all s entries ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_accessor.resolve_all
  run

@[step] theorem svc_accessor.state_full_pdus_strict_total (s : Snapshot) (hash : Std.U64)  :
    svc_accessor.state_full_pdus_strict s hash ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_accessor.state_full_pdus_strict
  run

@[step] theorem svc_timeline.last_timeline_count_total (s : Snapshot) (room : Std.U64)  :
    svc_timeline.last_timeline_count s room ⦃ r => True ⦄ := by
  unfold svc_timeline.last_timeline_count
  run

@[step] theorem svc_timeline.next_shortstatehash_total (s : Snapshot) (room : Std.U64) (after : Std.I64)  :
    svc_timeline.next_shortstatehash s room after ⦃ r => True ⦄ := by
  unfold svc_timeline.next_shortstatehash
  run

@[step] theorem api_room.departure_snapshot_total (s : Snapshot) (room : Std.U64) (pdu : Pdu) (current_shortstatehash : Std.U64)  :
    api_room.departure_snapshot s room pdu current_shortstatehash ⦃ r => True ⦄ := by
  unfold api_room.departure_snapshot
  run

@[step] theorem api_room.reversed_loop_total (bound : Nat) (v : Slice (Std.I64 × Std.Usize)) (out : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_v : Good (bound) v) (h_out : Good (bound) out) (hsize : out.length + i.val ≤ v.length) (hi : i.val ≤ v.length) :
    api_room.reversed_loop v out i ⦃ r => Good (bound) r ∧ r.length ≤ v.length ⦄ := by
  unfold api_room.reversed_loop
  apply loop.spec_decr_nat (measure := fun x => (x.2).val) (inv := fun x => x.1.length + (x.2).val ≤ v.length ∧ Good (bound) x.1 ∧ (x.2).val ≤ v.length)
  · intro x hin
    rcases x with ⟨out, i⟩
    try dsimp only at hin
    try simp only [Good, Indexed.valid] at hin
    unfold api_room.reversed_loop.body
    run
  all_goals clean

@[step] theorem api_room.reversed_total (bound : Nat) (v : Slice (Std.I64 × Std.Usize)) (h_v : Good (bound) v) :
    api_room.reversed v ⦃ r => Good (bound) r ⦄ := by
  unfold api_room.reversed
  run

@[step] theorem api_room.room_initial_sync_route_loop0_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop0 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  unfold api_room.room_initial_sync_route_loop0
  apply loop_idx_spec _ (fun x => x.2) (it.length) (fun x => x.1.length ≤ (x.2).val ∧ Good (v1.length) x.1) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨events, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_room.room_initial_sync_route_loop0.body
    run
  all_goals clean

@[step] theorem api_room.room_initial_sync_route_loop1_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop1 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  unfold api_room.room_initial_sync_route_loop1
  apply loop_idx_spec _ (fun x => x.2) (state.length) (fun x => x.1.length ≤ (x.2).val) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨state_ids, j⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_room.room_initial_sync_route_loop1.body
    run
  all_goals clean

@[step] theorem api_room.room_initial_sync_route_loop2_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop2 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  exact api_room.room_initial_sync_route_loop0_total v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i h_it h_events hsize hi

@[step] theorem api_room.room_initial_sync_route_loop3_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop3 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  exact api_room.room_initial_sync_route_loop1_total v state state_ids j h_state hsize hi

@[step] theorem api_room.room_initial_sync_route_loop4_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop4 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  exact api_room.room_initial_sync_route_loop0_total v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i h_it h_events hsize hi

@[step] theorem api_room.room_initial_sync_route_loop5_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop5 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  exact api_room.room_initial_sync_route_loop1_total v state state_ids j h_state hsize hi

@[step] theorem api_room.room_initial_sync_route_loop6_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop6 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  exact api_room.room_initial_sync_route_loop0_total v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i h_it h_events hsize hi

@[step] theorem api_room.room_initial_sync_route_loop7_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop7 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  exact api_room.room_initial_sync_route_loop1_total v state state_ids j h_state hsize hi

@[step] theorem api_room.room_initial_sync_route_loop8_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop8 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  exact api_room.room_initial_sync_route_loop0_total v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i h_it h_events hsize hi

@[step] theorem api_room.room_initial_sync_route_loop9_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop9 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  exact api_room.room_initial_sync_route_loop1_total v state state_ids j h_state hsize hi

@[step] theorem api_room.room_initial_sync_route_loop10_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop10 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  exact api_room.room_initial_sync_route_loop0_total v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i h_it h_events hsize hi

@[step] theorem api_room.room_initial_sync_route_loop11_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop11 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  exact api_room.room_initial_sync_route_loop1_total v state state_ids j h_state hsize hi

@[step] theorem api_room.room_initial_sync_route_loop12_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop12 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  exact api_room.room_initial_sync_route_loop0_total v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i h_it h_events hsize hi

@[step] theorem api_room.room_initial_sync_route_loop13_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop13 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  exact api_room.room_initial_sync_route_loop1_total v state state_ids j h_state hsize hi

@[step] theorem api_room.room_initial_sync_route_loop14_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop14 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  exact api_room.room_initial_sync_route_loop0_total v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i h_it h_events hsize hi

@[step] theorem api_room.room_initial_sync_route_loop15_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop15 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  exact api_room.room_initial_sync_route_loop1_total v state state_ids j h_state hsize hi

@[step] theorem api_room.room_initial_sync_route_loop16_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop16 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  exact api_room.room_initial_sync_route_loop0_total v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i h_it h_events hsize hi

@[step] theorem api_room.room_initial_sync_route_loop17_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop17 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  exact api_room.room_initial_sync_route_loop1_total v state state_ids j h_state hsize hi

@[step] theorem api_room.room_initial_sync_route_loop18_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop18 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  exact api_room.room_initial_sync_route_loop0_total v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i h_it h_events hsize hi

@[step] theorem api_room.room_initial_sync_route_loop19_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop19 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  exact api_room.room_initial_sync_route_loop1_total v state state_ids j h_state hsize hi

@[step] theorem api_room.room_initial_sync_route_loop20_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop20 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  exact api_room.room_initial_sync_route_loop0_total v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i h_it h_events hsize hi

@[step] theorem api_room.room_initial_sync_route_loop21_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop21 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  exact api_room.room_initial_sync_route_loop1_total v state state_ids j h_state hsize hi

@[step] theorem api_room.room_initial_sync_route_loop22_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop22 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  exact api_room.room_initial_sync_route_loop0_total v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i h_it h_events hsize hi

@[step] theorem api_room.room_initial_sync_route_loop23_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop23 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  exact api_room.room_initial_sync_route_loop1_total v state state_ids j h_state hsize hi

@[step] theorem api_room.room_initial_sync_route_loop24_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop24 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  exact api_room.room_initial_sync_route_loop0_total v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i h_it h_events hsize hi

@[step] theorem api_room.room_initial_sync_route_loop25_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop25 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  exact api_room.room_initial_sync_route_loop1_total v state state_ids j h_state hsize hi

@[step] theorem api_room.room_initial_sync_route_loop26_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop26 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  exact api_room.room_initial_sync_route_loop0_total v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i h_it h_events hsize hi

@[step] theorem api_room.room_initial_sync_route_loop27_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop27 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  exact api_room.room_initial_sync_route_loop1_total v state state_ids j h_state hsize hi

@[step] theorem api_room.room_initial_sync_route_loop28_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop28 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  exact api_room.room_initial_sync_route_loop0_total v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i h_it h_events hsize hi

@[step] theorem api_room.room_initial_sync_route_loop29_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop29 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  exact api_room.room_initial_sync_route_loop1_total v state state_ids j h_state hsize hi

@[step] theorem api_room.room_initial_sync_route_loop30_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop30 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  exact api_room.room_initial_sync_route_loop0_total v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i h_it h_events hsize hi

@[step] theorem api_room.room_initial_sync_route_loop31_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop31 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  exact api_room.room_initial_sync_route_loop1_total v state state_ids j h_state hsize hi

@[step] theorem api_room.room_initial_sync_route_loop32_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop32 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  exact api_room.room_initial_sync_route_loop0_total v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i h_it h_events hsize hi

@[step] theorem api_room.room_initial_sync_route_loop33_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop33 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  exact api_room.room_initial_sync_route_loop1_total v state state_ids j h_state hsize hi

@[step] theorem api_room.room_initial_sync_route_loop34_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop34 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  exact api_room.room_initial_sync_route_loop0_total v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i h_it h_events hsize hi

@[step] theorem api_room.room_initial_sync_route_loop35_total (v : alloc.vec.Vec Pdu) (state : alloc.vec.Vec Std.Usize) (state_ids : alloc.vec.Vec Std.U64) (j : Std.Usize) (h_state : Good (v.length) state) (hsize : state_ids.length ≤ j.val) (hi : j.val ≤ state.length) :
    api_room.room_initial_sync_route_loop35 v state state_ids j ⦃ r => True ∧ r.length ≤ state.length ⦄ := by
  exact api_room.room_initial_sync_route_loop1_total v state state_ids j h_state hsize hi

@[step] theorem api_room.room_initial_sync_route_total (s : Snapshot) (user : Std.U64) (room : Std.U64) (limit : Option Std.U64)  :
    api_room.room_initial_sync_route s user room limit ⦃ r => True ⦄ := by
  unfold api_room.room_initial_sync_route
  run

@[step] theorem api_room.get_room_event_route_total (s : Snapshot) (user : Std.U64) (room : Std.U64) (event_id : Std.U64)  :
    api_room.get_room_event_route s user room event_id ⦃ r => True ⦄ := by
  unfold api_room.get_room_event_route
  run

@[step] theorem svc_accessor.room_state_full_pdus_total (s : Snapshot) (room : Std.U64)  :
    svc_accessor.room_state_full_pdus s room ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_accessor.room_state_full_pdus
  run

@[step] theorem api_state.get_state_events_route_loop_total (s : Snapshot) (v : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec Std.U64) (i : Std.Usize) (h_v : Good (s.pdus.length) v) (hsize : events.length ≤ i.val) (hi : i.val ≤ v.length) :
    api_state.get_state_events_route_loop s v events i ⦃ r => True ∧ r.length ≤ v.length ⦄ := by
  unfold api_state.get_state_events_route_loop
  apply loop_idx_spec _ (fun x => x.2) (v.length) (fun x => x.1.length ≤ (x.2).val) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨events, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_state.get_state_events_route_loop.body
    run
  all_goals clean

@[step] theorem api_state.get_state_events_route_total (s : Snapshot) (user : Std.U64) (room : Std.U64)  :
    api_state.get_state_events_route s user room ⦃ r => True ⦄ := by
  unfold api_state.get_state_events_route
  run

@[step] theorem api_state.get_state_events_for_key_route_total (s : Snapshot) (user : Std.U64) (room : Std.U64) (kind : Kind) (state_key : Std.U64)  :
    api_state.get_state_events_for_key_route s user room kind state_key ⦃ r => True ⦄ := by
  unfold api_state.get_state_events_for_key_route
  run

@[step] theorem svc_threads.is_participant_loop_total (s : Snapshot) (short : Std.U64) (root : Std.U64) (user : Std.U64) (i : Std.Usize) (hi : i.val ≤ s.thread_participants.length) :
    svc_threads.is_participant_loop s short root user i ⦃ r => True ⦄ := by
  unfold svc_threads.is_participant_loop
  apply loop_idx_spec _ (fun x => x) (s.thread_participants.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx
    
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_threads.is_participant_loop.body
    run
  all_goals clean

@[step] theorem svc_threads.is_participant_total (s : Snapshot) (short : Std.U64) (root : Std.U64) (user : Std.U64)  :
    svc_threads.is_participant s short root user ⦃ r => True ⦄ := by
  unfold svc_threads.is_participant
  run

@[step] theorem svc_threads.latest_count_loop_total (s : Snapshot) (short : Std.U64) (root : Std.U64) (i : Std.Usize) (hi : i.val ≤ s.thread_latest.length) :
    svc_threads.latest_count_loop s short root i ⦃ r => True ⦄ := by
  unfold svc_threads.latest_count_loop
  apply loop_idx_spec _ (fun x => x) (s.thread_latest.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx
    
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_threads.latest_count_loop.body
    run
  all_goals clean

@[step] theorem svc_threads.latest_count_total (s : Snapshot) (short : Std.U64) (root : Std.U64)  :
    svc_threads.latest_count s short root ⦃ r => True ⦄ := by
  unfold svc_threads.latest_count
  run

@[step] theorem svc_threads.live_thread_total (s : Snapshot) (user : Std.U64) (participated : Bool) (short : Std.U64) (activity : Std.U64) (root : Std.U64)  :
    svc_threads.live_thread s user participated short activity root ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_threads.live_thread
  run

@[step] theorem svc_threads.threads_until_loop_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (i : Std.I64) (user : Std.U64) (count : Std.I64) (participated : Bool) (short : Std.U64) (out : alloc.vec.Vec (Std.I64 × Std.Usize)) (i1 : Std.Usize) (h_out : Good (v1.length) out) (hsize : out.length + i1.val ≤ v9.length) (hi : i1.val ≤ v9.length) :
    svc_threads.threads_until_loop v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c i user count participated short out i1 ⦃ r => Good (v1.length) r ∧ r.length ≤ v9.length ⦄ := by
  unfold svc_threads.threads_until_loop
  apply loop.spec_decr_nat (measure := fun x => (x.2).val) (inv := fun x => x.1.length + (x.2).val ≤ v9.length ∧ Good (v1.length) x.1 ∧ (x.2).val ≤ v9.length)
  · intro x hin
    rcases x with ⟨out, i1⟩
    try dsimp only at hin
    try simp only [Good, Indexed.valid] at hin
    unfold svc_threads.threads_until_loop.body
    run
  all_goals clean

@[step] theorem svc_threads.threads_until_total (s : Snapshot) (user : Std.U64) (room : Std.U64) (count : Std.I64) (participated : Bool)  :
    svc_threads.threads_until s user room count participated ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_threads.threads_until
  run

@[step] theorem api_threads.truncate_loop_total (bound : Nat) (v : Slice (Std.I64 × Std.Usize)) (n : Std.U64) (out : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_v : Good (bound) v) (h_out : Good (bound) out) (hsize : out.length ≤ i.val) (hi : i.val ≤ v.length) :
    api_threads.truncate_loop v n out i ⦃ r => Good (bound) r ∧ r.length ≤ v.length ⦄ := by
  unfold api_threads.truncate_loop
  apply loop_idx_spec _ (fun x => x.2) (v.length) (fun x => x.1.length ≤ (x.2).val ∧ Good (bound) x.1) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨out, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_threads.truncate_loop.body
    run
  all_goals clean

@[step] theorem api_threads.truncate_total (bound : Nat) (v : Slice (Std.I64 × Std.Usize)) (n : Std.U64) (h_v : Good (bound) v) :
    api_threads.truncate v n ⦃ r => Good (bound) r ⦄ := by
  unfold api_threads.truncate
  run

@[step] theorem api_threads.get_threads_route_loop0_total (s : Snapshot) (user : Std.U64) (room : Std.U64) (limit : Std.U64) (all : alloc.vec.Vec (Std.I64 × Std.Usize)) (threads : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_all : Good (s.pdus.length) all) (h_threads : Good (s.pdus.length) threads) (hl : limit.val < U64.max) (hsize : threads.length ≤ i.val) (hi : i.val ≤ all.length) :
    api_threads.get_threads_route_loop0 s user room limit all threads i ⦃ r => Good (s.pdus.length) r ∧ r.1 = s ∧ r.2.length ≤ all.length ⦄ := by
  unfold api_threads.get_threads_route_loop0
  apply loop_idx_spec _ (fun x => x.2) (all.length) (fun x => x.1.length ≤ (x.2).val ∧ Good (s.pdus.length) x.1) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨threads, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_threads.get_threads_route_loop0.body
    run
  all_goals clean

@[step] theorem api_threads.get_threads_route_loop1_total (s : Snapshot) (user : Std.U64) (room : Std.U64) (limit : Std.U64) (all : alloc.vec.Vec (Std.I64 × Std.Usize)) (threads : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_all : Good (s.pdus.length) all) (h_threads : Good (s.pdus.length) threads) (hl : limit.val < U64.max) (hsize : threads.length ≤ i.val) (hi : i.val ≤ all.length) :
    api_threads.get_threads_route_loop1 s user room limit all threads i ⦃ r => Good (s.pdus.length) r ∧ r.1 = s ∧ r.2.length ≤ all.length ⦄ := by
  unfold api_threads.get_threads_route_loop1
  apply loop_idx_spec _ (fun x => x.2) (all.length) (fun x => x.1.length ≤ (x.2).val ∧ Good (s.pdus.length) x.1) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨threads, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_threads.get_threads_route_loop1.body
    run
  all_goals clean

@[step] theorem api_threads.get_threads_route_total (s : Snapshot) (user : Std.U64) (room : Std.U64) («from» : Token) (limit : Option Std.U64) (participated : Bool)  :
    api_threads.get_threads_route s user room «from» limit participated ⦃ r => True ⦄ := by
  unfold api_threads.get_threads_route
  run

@[step] theorem svc_cache.room_members_loop_total (s : Snapshot) (room : Std.U64) (out : alloc.vec.Vec Std.U64) (i : Std.Usize) (hsize : out.length ≤ i.val) (hi : i.val ≤ s.joined.length) :
    svc_cache.room_members_loop s room out i ⦃ r => True ∧ r.length ≤ s.joined.length ⦄ := by
  unfold svc_cache.room_members_loop
  apply loop_idx_spec _ (fun x => x.2) (s.joined.length) (fun x => x.1.length ≤ (x.2).val) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨out, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_cache.room_members_loop.body
    run
  all_goals clean

@[step] theorem svc_cache.room_members_total (s : Snapshot) (room : Std.U64)  :
    svc_cache.room_members s room ⦃ r => True ⦄ := by
  unfold svc_cache.room_members
  run

@[step] theorem svc_accessor.any_member_was_loop_total (s : Snapshot) (hash : Std.U64) (origin : Std.U64) (members : Slice Std.U64) (joined : Bool) (i : Std.Usize) (hi : i.val ≤ members.length) :
    svc_accessor.any_member_was_loop s hash origin members joined i ⦃ r => True ⦄ := by
  unfold svc_accessor.any_member_was_loop
  apply loop_idx_spec _ (fun x => x) (members.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx
    
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_accessor.any_member_was_loop.body
    run
  all_goals clean

@[step] theorem svc_accessor.any_member_was_total (s : Snapshot) (hash : Std.U64) (origin : Std.U64) (members : Slice Std.U64) (joined : Bool)  :
    svc_accessor.any_member_was s hash origin members joined ⦃ r => True ⦄ := by
  unfold svc_accessor.any_member_was
  run

@[step] theorem svc_accessor.server_can_see_event_total (s : Snapshot) (origin : Std.U64) (room : Std.U64) (event_id : Std.U64)  :
    svc_accessor.server_can_see_event s origin room event_id ⦃ r => True ⦄ := by
  unfold svc_accessor.server_can_see_event
  run

theorem transition_total (s : Snapshot) (req : Request) (hr : (s.relations.length + 1) ^ 4 < Usize.max) :
    ∃ r, transition s req = ok r := by
  sorry

end tuwunel_kernel.Solution
