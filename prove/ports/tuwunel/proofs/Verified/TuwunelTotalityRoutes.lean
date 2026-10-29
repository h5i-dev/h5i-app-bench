import Verified.TuwunelTotalityWalker
open Aeneas Aeneas.Std Result tuwunel_kernel tuwunel_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP
namespace tuwunel_kernel.Verified.TuwunelTransitionTotal
set_option maxHeartbeats 8000000
set_option maxRecDepth 4096
set_option linter.unusedSimpArgs false
set_option linter.unusedVariables false
set_option allowUnsafeReducibility true
attribute [local reducible] Aeneas.Std.WP.Post

-- Supply the index bound explicitly instead of leaving a Nat metavariable.
open Lean Elab Tactic Meta in
elab "step_route_bound" : tactic => withMainContext do
  for d in ← getLCtx do
    if d.isImplementationDetail then continue
    if d.type.isConstOf ``Snapshot then
      let truncate := mkIdent `tuwunel_kernel.Verified.TuwunelTransitionTotal.api_threads.truncate_total
      let reversed := mkIdent `tuwunel_kernel.Verified.TuwunelTransitionTotal.api_room.reversed_total
      evalTactic (← `(tactic| first
        | step with $truncate ($(mkIdent d.userName):ident).pdus.length
        | step with $reversed ($(mkIdent d.userName):ident).pdus.length))
      return
  throwError "no snapshot"

macro "run_routes" : tactic => `(tactic| (
  try simp only [core.num.I64.saturating_add, core.num.I64.saturating_sub, lift]
  repeat' (first
    | step_route_bound
    | step
    | (dsimp only)
    | (simp only [bind_tc_ok, bind_ok, WP.spec_ok, Bool.false_eq_true, Bool.true_eq_false, ↓reduceIte, ↓reduceDIte])
    | (simp only [bind_tc_ite, bind_ite]) | split | split_pair
    | (simp_all [Good, Indexed.valid, api_context.LIMIT_MAX, api_context.LIMIT_DEFAULT, api_room.LIMIT_MAX, COUNT_MAX])
    | (solve | clean))
  all_goals clean))

@[step] theorem api_relations.max_depth_of_loop_total (events : Slice (Std.U64 × Std.I64 × Std.Usize)) (m : Std.U64) (i : Std.Usize) (hi : i.val ≤ events.length) :
    api_relations.max_depth_of_loop events m i ⦃ r => True ⦄ := by
  unfold api_relations.max_depth_of_loop
  apply loop_idx_spec _ (fun x => x.2) (events.length) (fun x => True) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨m, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_relations.max_depth_of_loop.body
    run_routes
  all_goals clean

@[step] theorem api_relations.max_depth_of_total (events : Slice (Std.U64 × Std.I64 × Std.Usize)) :
    api_relations.max_depth_of events ⦃ r => True ⦄ := by
  unfold api_relations.max_depth_of
  run_routes

@[step] theorem api_relations.empty_total   :
    api_relations.empty  ⦃ r => True ⦄ := by
  unfold api_relations.empty
  run_routes

@[step] theorem api_relations.paginate_relations_with_filter_loop0_total (v : alloc.vec.Vec Pdu) (events : alloc.vec.Vec (Std.U64 × Std.I64 × Std.Usize)) (chunk : alloc.vec.Vec Std.U64) (i : Std.Usize) (h_events : Good (v.length) events) (hsize : chunk.length ≤ i.val) (hi : i.val ≤ events.length) :
    api_relations.paginate_relations_with_filter_loop0 v events chunk i ⦃ r => True ∧ r.length ≤ events.length ⦄ := by
  unfold api_relations.paginate_relations_with_filter_loop0
  apply loop_idx_spec _ (fun x => x.2) (events.length) (fun x => x.1.length ≤ (x.2).val) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨chunk, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_relations.paginate_relations_with_filter_loop0.body
    run_routes
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
    run_routes
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
    run_routes
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
    run_routes
  all_goals clean

@[step] theorem svc_cache.is_knocked_total (s : Snapshot) (user : Std.U64) (room : Std.U64)  :
    svc_cache.is_knocked s user room ⦃ r => True ⦄ := by
  unfold svc_cache.is_knocked
  run_routes

@[step] theorem svc_cache.user_membership_total (s : Snapshot) (user : Std.U64) (room : Std.U64)  :
    svc_cache.user_membership s user room ⦃ r => True ⦄ := by
  unfold svc_cache.user_membership
  run_routes

@[step] theorem svc_accessor.resolve_all_loop_total (s : Snapshot) (entries : Slice StateEntry) (out : alloc.vec.Vec Std.Usize) (i : Std.Usize) (h_out : Good (s.pdus.length) out) (hsize : out.length ≤ i.val) (hi : i.val ≤ entries.length) :
    svc_accessor.resolve_all_loop s entries out i ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_accessor.resolve_all_loop
  apply loop_idx_spec _ (fun x => x.2) (entries.length) (fun x => x.1.length ≤ (x.2).val ∧ Good (s.pdus.length) x.1) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨out, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_accessor.resolve_all_loop.body
    run_routes
  all_goals clean

@[step] theorem svc_accessor.resolve_all_total (s : Snapshot) (entries : Slice StateEntry)  :
    svc_accessor.resolve_all s entries ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_accessor.resolve_all
  run_routes

@[step] theorem svc_accessor.state_full_pdus_strict_total (s : Snapshot) (hash : Std.U64)  :
    svc_accessor.state_full_pdus_strict s hash ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_accessor.state_full_pdus_strict
  run_routes

@[step] theorem svc_timeline.last_timeline_count_total (s : Snapshot) (room : Std.U64)  :
    svc_timeline.last_timeline_count s room ⦃ r => True ⦄ := by
  unfold svc_timeline.last_timeline_count
  run_routes

@[step] theorem svc_timeline.next_shortstatehash_total (s : Snapshot) (room : Std.U64) (after : Std.I64)  :
    svc_timeline.next_shortstatehash s room after ⦃ r => True ⦄ := by
  unfold svc_timeline.next_shortstatehash
  run_routes

@[step] theorem api_room.departure_snapshot_total (s : Snapshot) (room : Std.U64) (pdu : Pdu) (current_shortstatehash : Std.U64)  :
    api_room.departure_snapshot s room pdu current_shortstatehash ⦃ r => True ⦄ := by
  unfold api_room.departure_snapshot
  run_routes

@[step] theorem api_room.reversed_loop_total (bound : Nat) (v : Slice (Std.I64 × Std.Usize)) (out : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_v : Good (bound) v) (h_out : Good (bound) out) (hsize : out.length + i.val ≤ v.length) (hi : i.val ≤ v.length) :
    api_room.reversed_loop v out i ⦃ r => Good (bound) r ∧ r.length ≤ v.length ⦄ := by
  unfold api_room.reversed_loop
  apply loop.spec_decr_nat (measure := fun x => (x.2).val) (inv := fun x => x.1.length + (x.2).val ≤ v.length ∧ Good (bound) x.1 ∧ (x.2).val ≤ v.length)
  · intro x hin
    rcases x with ⟨out, i⟩
    try dsimp only at hin
    try simp only [Good, Indexed.valid] at hin
    unfold api_room.reversed_loop.body
    run_routes
  all_goals clean

@[step] theorem api_room.reversed_total (bound : Nat) (v : Slice (Std.I64 × Std.Usize)) (h_v : Good (bound) v) :
    api_room.reversed v ⦃ r => Good (bound) r ⦄ := by
  unfold api_room.reversed
  run_routes

@[step] theorem api_room.room_initial_sync_route_loop0_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (timeline_end : Std.I64) (user : Std.U64) (limit : Std.U64) (it : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_it : Good (v1.length) it) (h_events : Good (v1.length) events) (hsize : events.length ≤ i.val) (hi : i.val ≤ it.length) :
    api_room.room_initial_sync_route_loop0 v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c timeline_end user limit it events i ⦃ r => Good (v1.length) r ∧ r.length ≤ it.length ⦄ := by
  unfold api_room.room_initial_sync_route_loop0
  apply loop_idx_spec _ (fun x => x.2) (it.length) (fun x => x.1.length ≤ (x.2).val ∧ Good (v1.length) x.1) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨events, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_room.room_initial_sync_route_loop0.body
    run_routes
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
    run_routes
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

@[step] theorem api_room.get_room_event_route_total (s : Snapshot) (user : Std.U64) (room : Std.U64) (event_id : Std.U64)  :
    api_room.get_room_event_route s user room event_id ⦃ r => True ⦄ := by
  unfold api_room.get_room_event_route
  run_routes

@[step] theorem svc_accessor.room_state_full_pdus_total (s : Snapshot) (room : Std.U64)  :
    svc_accessor.room_state_full_pdus s room ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_accessor.room_state_full_pdus
  run_routes

@[step] theorem api_state.get_state_events_route_loop_total (s : Snapshot) (v : alloc.vec.Vec Std.Usize) (events : alloc.vec.Vec Std.U64) (i : Std.Usize) (h_v : Good (s.pdus.length) v) (hsize : events.length ≤ i.val) (hi : i.val ≤ v.length) :
    api_state.get_state_events_route_loop s v events i ⦃ r => True ∧ r.length ≤ v.length ⦄ := by
  unfold api_state.get_state_events_route_loop
  apply loop_idx_spec _ (fun x => x.2) (v.length) (fun x => x.1.length ≤ (x.2).val) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨events, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_state.get_state_events_route_loop.body
    run_routes
  all_goals clean

@[step] theorem api_state.get_state_events_route_total (s : Snapshot) (user : Std.U64) (room : Std.U64)  :
    api_state.get_state_events_route s user room ⦃ r => True ⦄ := by
  unfold api_state.get_state_events_route
  run_routes

@[step] theorem api_state.get_state_events_for_key_route_total (s : Snapshot) (user : Std.U64) (room : Std.U64) (kind : Kind) (state_key : Std.U64)  :
    api_state.get_state_events_for_key_route s user room kind state_key ⦃ r => True ⦄ := by
  unfold api_state.get_state_events_for_key_route
  run_routes

@[step] theorem svc_threads.is_participant_loop_total (s : Snapshot) (short : Std.U64) (root : Std.U64) (user : Std.U64) (i : Std.Usize) (hi : i.val ≤ s.thread_participants.length) :
    svc_threads.is_participant_loop s short root user i ⦃ r => True ⦄ := by
  unfold svc_threads.is_participant_loop
  apply loop_idx_spec _ (fun x => x) (s.thread_participants.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_threads.is_participant_loop.body
    run_routes
  all_goals clean

@[step] theorem svc_threads.is_participant_total (s : Snapshot) (short : Std.U64) (root : Std.U64) (user : Std.U64)  :
    svc_threads.is_participant s short root user ⦃ r => True ⦄ := by
  unfold svc_threads.is_participant
  run_routes

@[step] theorem svc_threads.latest_count_loop_total (s : Snapshot) (short : Std.U64) (root : Std.U64) (i : Std.Usize) (hi : i.val ≤ s.thread_latest.length) :
    svc_threads.latest_count_loop s short root i ⦃ r => True ⦄ := by
  unfold svc_threads.latest_count_loop
  apply loop_idx_spec _ (fun x => x) (s.thread_latest.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_threads.latest_count_loop.body
    run_routes
  all_goals clean

@[step] theorem svc_threads.latest_count_total (s : Snapshot) (short : Std.U64) (root : Std.U64)  :
    svc_threads.latest_count s short root ⦃ r => True ⦄ := by
  unfold svc_threads.latest_count
  run_routes

@[step] theorem svc_threads.live_thread_total (s : Snapshot) (user : Std.U64) (participated : Bool) (short : Std.U64) (activity : Std.U64) (root : Std.U64)  :
    svc_threads.live_thread s user participated short activity root ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_threads.live_thread
  run_routes

@[step] theorem svc_threads.threads_until_loop_total (v : alloc.vec.Vec Room) (v1 : alloc.vec.Vec Pdu) (v2 : alloc.vec.Vec StateSet) (v3 : alloc.vec.Vec UserRoom) (v4 : alloc.vec.Vec UserRoom) (v5 : alloc.vec.Vec UserRoom) (v6 : alloc.vec.Vec LeftRow) (v7 : alloc.vec.Vec UserRoom) (v8 : alloc.vec.Vec Relation) (v9 : alloc.vec.Vec ThreadActivity) (v10 : alloc.vec.Vec ThreadLatest) (v11 : alloc.vec.Vec ThreadParticipants) (v12 : alloc.vec.Vec Ignore) (c : Config) (i : Std.I64) (user : Std.U64) (count : Std.I64) (participated : Bool) (short : Std.U64) (out : alloc.vec.Vec (Std.I64 × Std.Usize)) (i1 : Std.Usize) (h_out : Good (v1.length) out) (hsize : out.length + i1.val ≤ v9.length) (hi : i1.val ≤ v9.length) :
    svc_threads.threads_until_loop v v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 c i user count participated short out i1 ⦃ r => Good (v1.length) r ∧ r.length ≤ v9.length ⦄ := by
  unfold svc_threads.threads_until_loop
  apply loop.spec_decr_nat (measure := fun x => (x.2).val) (inv := fun x => x.1.length + (x.2).val ≤ v9.length ∧ Good (v1.length) x.1 ∧ (x.2).val ≤ v9.length)
  · intro x hin
    rcases x with ⟨out, i1⟩
    try dsimp only at hin
    try simp only [Good, Indexed.valid] at hin
    unfold svc_threads.threads_until_loop.body
    run_routes
  all_goals clean

@[step] theorem svc_threads.threads_until_total (s : Snapshot) (user : Std.U64) (room : Std.U64) (count : Std.I64) (participated : Bool)  :
    svc_threads.threads_until s user room count participated ⦃ r => Good (s.pdus.length) r ⦄ := by
  unfold svc_threads.threads_until
  run_routes

@[step] theorem api_threads.truncate_loop_total (bound : Nat) (v : Slice (Std.I64 × Std.Usize)) (n : Std.U64) (out : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_v : Good (bound) v) (h_out : Good (bound) out) (hsize : out.length ≤ i.val) (hi : i.val ≤ v.length) :
    api_threads.truncate_loop v n out i ⦃ r => Good (bound) r ∧ r.length ≤ v.length ⦄ := by
  unfold api_threads.truncate_loop
  apply loop_idx_spec _ (fun x => x.2) (v.length) (fun x => x.1.length ≤ (x.2).val ∧ Good (bound) x.1) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨out, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_threads.truncate_loop.body
    run_routes
  all_goals clean

@[step] theorem api_threads.truncate_total (bound : Nat) (v : Slice (Std.I64 × Std.Usize)) (n : Std.U64) (h_v : Good (bound) v) :
    api_threads.truncate v n ⦃ r => Good (bound) r ⦄ := by
  unfold api_threads.truncate
  run_routes

@[step] theorem api_threads.get_threads_route_loop0_total (s : Snapshot) (user : Std.U64) (room : Std.U64) (limit : Std.U64) (all : alloc.vec.Vec (Std.I64 × Std.Usize)) (threads : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_all : Good (s.pdus.length) all) (h_threads : Good (s.pdus.length) threads) (hl : limit.val < U64.max) (hsize : threads.length ≤ i.val) (hi : i.val ≤ all.length) :
    api_threads.get_threads_route_loop0 s user room limit all threads i ⦃ r => Good (s.pdus.length) r ∧ r.1 = s ∧ r.2.length ≤ all.length ⦄ := by
  unfold api_threads.get_threads_route_loop0
  apply loop_idx_spec _ (fun x => x.2) (all.length) (fun x => x.1.length ≤ (x.2).val ∧ Good (s.pdus.length) x.1) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨threads, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_threads.get_threads_route_loop0.body
    run_routes
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
    run_routes
  all_goals clean

@[step] theorem api_threads.get_threads_route_total (s : Snapshot) (user : Std.U64) (room : Std.U64) («from» : Token) (limit : Option Std.U64) (participated : Bool)  :
    api_threads.get_threads_route s user room «from» limit participated ⦃ r => True ⦄ := by
  unfold api_threads.get_threads_route
  run_routes

@[step] theorem svc_cache.room_members_loop_total (s : Snapshot) (room : Std.U64) (out : alloc.vec.Vec Std.U64) (i : Std.Usize) (hsize : out.length ≤ i.val) (hi : i.val ≤ s.joined.length) :
    svc_cache.room_members_loop s room out i ⦃ r => True ∧ r.length ≤ s.joined.length ⦄ := by
  unfold svc_cache.room_members_loop
  apply loop_idx_spec _ (fun x => x.2) (s.joined.length) (fun x => x.1.length ≤ (x.2).val) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨out, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_cache.room_members_loop.body
    run_routes
  all_goals clean

@[step] theorem svc_cache.room_members_total (s : Snapshot) (room : Std.U64)  :
    svc_cache.room_members s room ⦃ r => True ⦄ := by
  unfold svc_cache.room_members
  run_routes

@[step] theorem svc_accessor.any_member_was_loop_total (s : Snapshot) (hash : Std.U64) (origin : Std.U64) (members : Slice Std.U64) (joined : Bool) (i : Std.Usize) (hi : i.val ≤ members.length) :
    svc_accessor.any_member_was_loop s hash origin members joined i ⦃ r => True ⦄ := by
  unfold svc_accessor.any_member_was_loop
  apply loop_idx_spec _ (fun x => x) (members.length) (fun x => True) _ ?_ _ ?_ hi
  · intro i hin hx

    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold svc_accessor.any_member_was_loop.body
    run_routes
  all_goals clean

@[step] theorem svc_accessor.any_member_was_total (s : Snapshot) (hash : Std.U64) (origin : Std.U64) (members : Slice Std.U64) (joined : Bool)  :
    svc_accessor.any_member_was s hash origin members joined ⦃ r => True ⦄ := by
  unfold svc_accessor.any_member_was
  run_routes

@[step] theorem svc_accessor.server_can_see_event_total (s : Snapshot) (origin : Std.U64) (room : Std.U64) (event_id : Std.U64)  :
    svc_accessor.server_can_see_event s origin room event_id ⦃ r => True ⦄ := by
  unfold svc_accessor.server_can_see_event
  run_routes


end tuwunel_kernel.Verified.TuwunelTransitionTotal
