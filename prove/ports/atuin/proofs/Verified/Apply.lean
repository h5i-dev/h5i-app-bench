import Verified.Isolation
/-!
# What committing a write set does to the tables
-/
open Aeneas Aeneas.Std Result atuin_kernel atuin_kernel.Spec
open H5iAppLib hiding lit

namespace atuin_kernel.Verified

theorem without_user_store_spec (v : alloc.vec.Vec StoreRow) (id : U64) :
    without_user_store v id ⦃ r => r.val = v.val.filter (fun x => decide (x.user_id ≠ id)) ⦄ := by
  unfold without_user_store without_user_store_loop
  apply WP.spec_mono (H5iAppLib.loop_fold v.val (fun (o : alloc.vec.Vec StoreRow) => o.val)
    (fun acc x => if decide (x.user_id ≠ id) then acc ++ [x] else acc)
    (fun o i => o.val.length ≤ i) _ ?step (alloc.vec.Vec.new StoreRow) 0#usize (by simp) (by simp))
  · intro r hr; rw [hr, H5iAppLib.foldl_filter]; simp
  case step =>
    intro o j hj hinv; unfold without_user_store_loop.body; h5i_step

theorem without_user_sessions_spec (v : alloc.vec.Vec Session) (id : U64) :
    without_user_sessions v id ⦃ r => r.val = v.val.filter (fun x => decide (x.user_id ≠ id)) ⦄ := by
  unfold without_user_sessions without_user_sessions_loop
  apply WP.spec_mono (H5iAppLib.loop_fold v.val (fun (o : alloc.vec.Vec Session) => o.val)
    (fun acc x => if decide (x.user_id ≠ id) then acc ++ [x] else acc)
    (fun o i => o.val.length ≤ i) _ ?step (alloc.vec.Vec.new Session) 0#usize (by simp) (by simp))
  · intro r hr; rw [hr, H5iAppLib.foldl_filter]; simp
  case step =>
    intro o j hj hinv; unfold without_user_sessions_loop.body; h5i_step

theorem without_user_history_spec (v : alloc.vec.Vec HistoryRow) (id : U64) :
    without_user_history v id ⦃ r => r.val = v.val.filter (fun x => decide (x.user_id ≠ id)) ⦄ := by
  unfold without_user_history without_user_history_loop
  apply WP.spec_mono (H5iAppLib.loop_fold v.val (fun (o : alloc.vec.Vec HistoryRow) => o.val)
    (fun acc x => if decide (x.user_id ≠ id) then acc ++ [x] else acc)
    (fun o i => o.val.length ≤ i) _ ?step (alloc.vec.Vec.new HistoryRow) 0#usize (by simp) (by simp))
  · intro r hr; rw [hr, H5iAppLib.foldl_filter]; simp
  case step =>
    intro o j hj hinv; unfold without_user_history_loop.body; h5i_step

theorem without_user_spec (v : alloc.vec.Vec User) (id : U64) :
    without_user v id ⦃ r => r.val = v.val.filter (fun x => decide (x.id ≠ id)) ⦄ := by
  unfold without_user without_user_loop
  apply WP.spec_mono (H5iAppLib.loop_fold v.val (fun (o : alloc.vec.Vec User) => o.val)
    (fun acc x => if decide (x.id ≠ id) then acc ++ [x] else acc)
    (fun o i => o.val.length ≤ i) _ ?step (alloc.vec.Vec.new User) 0#usize (by simp) (by simp))
  · intro r hr; rw [hr, H5iAppLib.foldl_filter]; simp
  case step =>
    intro o j hj hinv; unfold without_user_loop.body; h5i_step

/-- The new password of user `id`. -/
def setPw (id : U64) (h : alloc.vec.Vec U8) (u : User) : User :=
  if u.id = id then { u with password := h } else u

theorem with_password_spec (v : alloc.vec.Vec User) (id : U64) (h : alloc.vec.Vec U8) :
    with_password v id h ⦃ r => r.val = v.val.map (setPw id h) ⦄ := by
  unfold with_password with_password_loop
  apply WP.spec_mono (H5iAppLib.loop_fold v.val (fun (o : alloc.vec.Vec User) => o.val)
    (fun acc x => acc ++ [setPw id h x])
    (fun o i => o.val.length ≤ i) _ ?step (alloc.vec.Vec.new User) 0#usize (by simp) (by simp))
  · intro r hr; rw [hr, H5iAppLib.foldl_map]; simp
  case step =>
    intro o j hj hinv; unfold with_password_loop.body; h5i_step [setPw]

/-- The `(user_id, host, tag, idx)` key of two rows is the same. -/
def sameKey (r x : StoreRow) : Bool :=
  decide (x.user_id = r.user_id) && decide (x.host = r.host) && decide (x.tag.val = r.tag.val) && decide (x.idx = r.idx)

theorem store_conflict_spec (v : alloc.vec.Vec StoreRow) (r : StoreRow) :
    store_conflict v r ⦃ b => b = v.val.any (sameKey r) ⦄ := by
  unfold store_conflict store_conflict_loop
  apply WP.spec_mono (H5iAppLib.loop_search v.val (sameKey r) id (fun _ _ => true) false _ ?step 0#usize (by simp))
  · intro b hb; simp only [id] at hb; rw [hb, H5iAppLib.searchFrom_const]; simp
  case step =>
    intro j hj; unfold store_conflict_loop.body; h5i_step [sameKey]
    all_goals (try scalar_tac)
    all_goals trace_state

theorem push_clone_ok {T : Type} (inst : core.clone.Clone T) (hc : ∀ x, inst.clone x = ok x)
    {v w : alloc.vec.Vec T} {x : T}
    (h : (do let res ← alloc.vec.CloneVec.clone inst v; let y ← inst.clone x; alloc.vec.Vec.push res y) = ok w) :
    w.val = v.val ++ [x] := by
  rw [H5iAppLib.vec_clone_ok inst v hc] at h
  simp only [bind_ok, bind_tc_ok, hc] at h
  exact push_ok_val h

/-- What one write does, table by table. -/
def Effect (s : Snapshot) : Write → Snapshot → Prop
  | .AddUser u, s' => s'.users.val = s.users.val ++ [u] ∧ s'.sessions = s.sessions ∧
      s'.history = s.history ∧ s'.store = s.store
  | .AddSession x, s' => s'.users = s.users ∧ s'.sessions.val = s.sessions.val ++ [x] ∧
      s'.history = s.history ∧ s'.store = s.store
  | .SetPassword id h, s' => s'.users.val = s.users.val.map (setPw id h) ∧ s'.sessions = s.sessions ∧
      s'.history = s.history ∧ s'.store = s.store
  | .DeleteUser id, s' => s'.users.val = s.users.val.filter (fun x => decide (x.id ≠ id)) ∧
      s'.sessions.val = s.sessions.val.filter (fun x => decide (x.user_id ≠ id)) ∧
      s'.history.val = s.history.val.filter (fun x => decide (x.user_id ≠ id)) ∧
      s'.store.val = s.store.val.filter (fun x => decide (x.user_id ≠ id))
  | .InsertRecord r, s' => s'.users = s.users ∧ s'.sessions = s.sessions ∧ s'.history = s.history ∧
      s'.store.val = (if s.store.val.any (sameKey r) then s.store.val else s.store.val ++ [r])
  | .DeleteStore id, s' => s'.users = s.users ∧ s'.sessions = s.sessions ∧ s'.history = s.history ∧
      s'.store.val = s.store.val.filter (fun x => decide (x.user_id ≠ id))

theorem apply_write_ok {s s' : Snapshot} {w : Write} (h : apply_write s w = ok s') : Effect s w s' := by
  unfold apply_write at h
  cases w with
  | AddUser u =>
    simp only [] at h
    h5i_invert h
    all_goals sorry
  | _ => sorry

end atuin_kernel.Verified
