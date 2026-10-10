import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result tuwunel_kernel tuwunel_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP

namespace tuwunel_kernel.Solution
set_option maxHeartbeats 2000000
set_option maxRecDepth 4096
set_option linter.unusedVariables false

class Indexed (α : Type) where
  valid : Nat → α → Prop
instance (priority := low) (α : Type) : Indexed α := ⟨fun _ _ => True⟩
instance : Indexed Usize := ⟨fun n i => i.val < n⟩
instance [Indexed α] [Indexed β] : Indexed (α × β) :=
  ⟨fun n p => Indexed.valid n p.1 ∧ Indexed.valid n p.2⟩
instance [Indexed α] : Indexed (alloc.vec.Vec α) :=
  ⟨fun n v => ∀ x ∈ v.val, Indexed.valid n x⟩
instance [Indexed α] : Indexed (Slice α) :=
  ⟨fun n v => ∀ x ∈ v.val, Indexed.valid n x⟩
instance [Indexed α] : Indexed (Option α) :=
  ⟨fun n o => ∀ x, o = some x → Indexed.valid n x⟩
instance [Indexed α] : Indexed (core.result.Result α ε) :=
  ⟨fun n r => ∀ x, r = .Ok x → Indexed.valid n x⟩
abbrev Good [Indexed α] (n : Nat) (x : α) := Indexed.valid n x

macro "clean" : tactic => `(tactic| (
  simp_all -failIfUnchanged [Good, Indexed.valid, List.mem_append, List.mem_singleton, api_context.LIMIT_MAX, api_context.LIMIT_DEFAULT, api_room.LIMIT_MAX, COUNT_MAX]
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

macro "run" : tactic => `(tactic| (
  try simp only [core.num.I64.saturating_add, core.num.I64.saturating_sub, lift]
  repeat' (first | step | (dsimp only) | (simp only [bind_tc_ok, bind_ok, WP.spec_ok, Bool.false_eq_true, Bool.true_eq_false, ↓reduceIte, ↓reduceDIte]) | (simp only [bind_tc_ite, bind_ite]) | split | split_pair | (simp_all [Good, Indexed.valid, api_context.LIMIT_MAX, api_context.LIMIT_DEFAULT, api_room.LIMIT_MAX, COUNT_MAX]) | (solve | clean))
  all_goals clean))

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
  · clean

@[step] theorem svc_timeline.get_shortroomid_total (s : Snapshot) (room : Std.U64)  :
    svc_timeline.get_shortroomid s room ⦃ r => True ⦄ := by
  unfold svc_timeline.get_shortroomid
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
  · clean

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
  · clean

@[step] theorem svc_timeline.get_non_outlier_total (s : Snapshot) (event_id : Std.U64)  :
    svc_timeline.get_non_outlier s event_id ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_timeline.get_non_outlier
  run

@[step] theorem svc_timeline.get_pdu_total (s : Snapshot) (event_id : Std.U64)  :
    svc_timeline.get_pdu s event_id ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_timeline.get_pdu
  run

@[step] theorem svc_timeline.state_of_total (p : Pdu)  :
    svc_timeline.state_of p ⦃ r => True ⦄ := by
  unfold svc_timeline.state_of
  run

@[step] theorem svc_timeline.pdu_shortstatehash_total (s : Snapshot) (event_id : Std.U64)  :
    svc_timeline.pdu_shortstatehash s event_id ⦃ r => True ⦄ := by
  unfold svc_timeline.pdu_shortstatehash
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
  · clean

@[step] theorem svc_accessor.load_full_state_total (s : Snapshot) (hash : Std.U64)  :
    svc_accessor.load_full_state s hash ⦃ r => Good (s.states.length) r ⦄ := by
  unfold svc_accessor.load_full_state
  run

@[step] theorem kind_eq_total (a : Kind) (b : Kind)  :
    kind_eq a b ⦃ r => True ⦄ := by
  unfold kind_eq
  run

@[step] theorem rel_type_eq_total (a : RelType) (b : RelType)  :
    rel_type_eq a b ⦃ r => True ⦄ := by
  unfold rel_type_eq
  run

@[step] theorem svc_relations.relation_type_equal_total (rel_type : RelType) (p : Pdu)  :
    svc_relations.relation_type_equal rel_type p ⦃ r => True ⦄ := by
  unfold svc_relations.relation_type_equal
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
  · clean

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
  · clean

@[step] theorem svc_timeline.room_of_short_total (s : Snapshot) (short : Std.U64)  :
    svc_timeline.room_of_short s short ⦃ r => True ⦄ := by
  unfold svc_timeline.room_of_short
  run

@[step] theorem svc_timeline.get_pdu_from_id_total (s : Snapshot) (short : Std.U64) (count : Std.I64)  :
    svc_timeline.get_pdu_from_id s short count ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_timeline.get_pdu_from_id
  run

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
  · clean

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
  · clean

@[step] theorem svc_relations.get_relations_total (s : Snapshot) (shortroomid : Std.U64) (target : Std.I64) («from» : Option Std.I64) (dir : Dir)  :
    svc_relations.get_relations s shortroomid target «from» dir ⦃ r => Good (s.pdus.length) r ∧ r.length ≤ s.relations.length ⦄ := by
  unfold svc_relations.get_relations
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
  · clean

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
  · clean

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
  · clean

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

@[step] theorem api_relations.keep_total (s : Snapshot) (user : Std.U64) (p : Pdu) (filter_event_type : Option Kind) (filter_rel_type : Option RelType)  :
    api_relations.keep s user p filter_event_type filter_rel_type ⦃ r => True ⦄ := by
  unfold api_relations.keep
  run

@[step] theorem api_relations.fetch_loop_total (bound : Nat) (rels : alloc.vec.Vec (Std.I64 × Std.Usize)) (out : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_rels : Good (bound) rels) (h_out : Good (bound) out) (hsize : out.length ≤ i.val) (hi : i.val ≤ rels.length) :
    api_relations.fetch_loop rels out i ⦃ r => Good (bound) r ∧ r.length ≤ rels.length ⦄ := by
  unfold api_relations.fetch_loop
  apply loop_idx_spec _ (fun x => x.2) (rels.length) (fun x => x.1.length ≤ (x.2).val ∧ Good (bound) x.1) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨out, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_relations.fetch_loop.body
    run
  · clean

@[step] theorem api_relations.fetch_total (s : Snapshot) (shortroomid : Std.U64) (count : Std.I64) («from» : Option Std.I64) (dir : Dir)  :
    api_relations.fetch s shortroomid count «from» dir ⦃ r => Good (s.pdus.length) r ∧ r.length ≤ s.relations.length ⦄ := by
  unfold api_relations.fetch
  run

end tuwunel_kernel.Solution
