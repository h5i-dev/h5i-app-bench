import Lemmas
/-! `apply` computes `Spec.applyAll`. Loops use `I5hLib`. -/
open Aeneas Aeneas.Std Result atuin_kernel atuin_kernel.Spec atuin_kernel.Lemmas I5hLib

namespace atuin_kernel.ApplyLemmas

theorem u64_val_inj {x y : U64} : x.val = y.val ↔ x = y :=
  ⟨fun h => UScalar.eq_of_val_eq h, fun h => h ▸ rfl⟩

/-- Total rows in a snapshot. -/
def total (s : Snapshot) : Nat := s.users.length + s.sessions.length + s.records.length

theorem session_clone (x : Session) : Session.Insts.CoreCloneClone.clone x = ok x := by
  simp [Session.Insts.CoreCloneClone.clone, u8vec_clone, lift]

theorem counter_clone (c : Counter) : Counter.Insts.CoreCloneClone.clone c = ok c := by
  simp [Counter.Insts.CoreCloneClone.clone, lift]

theorem settings_clone (c : Settings) : Settings.Insts.CoreCloneClone.clone c = ok c := by
  simp [Settings.Insts.CoreCloneClone.clone, lift]

theorem write_clone (w : Write) : Write.Insts.CoreCloneClone.clone w = ok w := by
  cases w <;> simp [Write.Insts.CoreCloneClone.clone, user_clone, session_clone, record_clone,
    counter_clone, lift]

theorem snapshot_clone (s : Snapshot) : Snapshot.Insts.CoreCloneClone.clone s = ok s := by
  simp [Snapshot.Insts.CoreCloneClone.clone, counter_clone, settings_clone,
    vec_clone_eq User.Insts.CoreCloneClone s.users user_clone,
    vec_clone_eq Session.Insts.CoreCloneClone s.sessions session_clone,
    vec_clone_eq Record.Insts.CoreCloneClone s.records record_clone]

@[step]
theorem session_clone_spec (x : Session) : Session.Insts.CoreCloneClone.clone x ⦃ y => y = x ⦄ := by
  rw [session_clone]; simp

@[step]
theorem put_user_loop_spec (v : alloc.vec.Vec User) (u : User) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (·.id) u v.val = v.val.take i.val ++ upsert (·.id) u (v.val.drop i.val)) :
    put_user_loop v u i ⦃ v' => v'.val = upsert (·.id) u v.val ⦄ := by
  unfold put_user_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide (q.id = u.id))
    (fun x : alloc.vec.Vec User => x.val) (fun j _ => v.val.set j u) (v.val ++ [u]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (·.id) u _ _ hi hpre
  · intro j hj; unfold put_user_loop.body; i5h_step

@[step]
theorem put_session_loop_spec (v : alloc.vec.Vec Session) (x : Session) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (·.user) x v.val = v.val.take i.val ++ upsert (·.user) x (v.val.drop i.val)) :
    put_session_loop v x i ⦃ v' => v'.val = upsert (·.user) x v.val ⦄ := by
  unfold put_session_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide (q.user = x.user))
    (fun y : alloc.vec.Vec Session => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (·.user) x _ _ hi hpre
  · intro j hj; unfold put_session_loop.body; i5h_step

@[step]
theorem put_record_loop_spec (v : alloc.vec.Vec Record) (x : Record) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert rkey x v.val = v.val.take i.val ++ upsert rkey x (v.val.drop i.val)) :
    put_record_loop v x i ⦃ v' => v'.val = upsert rkey x v.val ⦄ := by
  unfold put_record_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide (rkey q = rkey x))
    (fun y : alloc.vec.Vec Record => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result rkey x _ _ hi hpre
  · intro j hj; unfold put_record_loop.body; i5h_step
    all_goals (try left)
    all_goals (
      refine ⟨by scalar_tac, ?_⟩
      try simp only [u64_val_inj] at *
      simp_all [rkey])

@[step]
theorem del_user_loop_spec (v : alloc.vec.Vec User) (k : U64) (out : alloc.vec.Vec User)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun x => x.id ≠ k)) :
    del_user_loop v k out i ⦃ v' => v'.val = v.val.filter (fun x => x.id ≠ k) ⦄ := by
  unfold del_user_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec User => w.val)
    (fun acc x => if decide (x.id ≠ k) then acc ++ [x] else acc)
    (fun w j => w.length ≤ j) (fun x => del_user_loop.body v k x.1 x.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_user_loop.body; i5h_step

@[step]
theorem del_session_loop_spec (v : alloc.vec.Vec Session) (k : U64) (out : alloc.vec.Vec Session)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun x => x.user ≠ k)) :
    del_session_loop v k out i ⦃ v' => v'.val = v.val.filter (fun x => x.user ≠ k) ⦄ := by
  unfold del_session_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Session => w.val)
    (fun acc x => if decide (x.user ≠ k) then acc ++ [x] else acc)
    (fun w j => w.length ≤ j) (fun x => del_session_loop.body v k x.1 x.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_session_loop.body; i5h_step

@[step]
theorem del_records_of_loop_spec (v : alloc.vec.Vec Record) (k : U64) (out : alloc.vec.Vec Record)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun x => x.user ≠ k)) :
    del_records_of_loop v k out i ⦃ v' => v'.val = v.val.filter (fun x => x.user ≠ k) ⦄ := by
  unfold del_records_of_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Record => w.val)
    (fun acc x => if decide (x.user ≠ k) then acc ++ [x] else acc)
    (fun w j => w.length ≤ j) (fun x => del_records_of_loop.body v k x.1 x.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_records_of_loop.body; i5h_step

@[step]
theorem apply_write_spec (s : Snapshot) (w : Write) (h : total s < Usize.max) :
    apply_write s w ⦃ s' => Snapshot.toSt s' = applyWrite (Snapshot.toSt s) w ∧ total s' ≤ total s + 1 ⦄ := by
  unfold total at h
  unfold apply_write
  cases w <;> step*
  all_goals first
    | refine ⟨by simp [Snapshot.toSt, applyWrite, *], ?_⟩
      simp only [total, alloc.vec.Vec.length, *]
      first
        | omega
        | (have := upsert_length (·.id) ‹User› s.users.val; omega)
        | (have := upsert_length (·.user) ‹Session› s.sessions.val; omega)
        | (have := upsert_length rkey ‹Record› s.records.val; omega)
        | grind [List.length_filter_le]
    | simp

@[step]
theorem write_clone_spec (w : Write) : Write.Insts.CoreCloneClone.clone w ⦃ w' => w' = w ⦄ := by
  rw [write_clone]; simp

@[step]
theorem snapshot_clone_spec (s : Snapshot) : Snapshot.Insts.CoreCloneClone.clone s ⦃ s' => s' = s ⦄ := by
  rw [snapshot_clone]; simp

@[step]
theorem apply_loop_spec (ws : alloc.vec.Vec Write) (s₀ s : Snapshot) (i : Usize)
    (hi : i.val ≤ ws.length)
    (hs : Snapshot.toSt s = applyAll (Snapshot.toSt s₀) (ws.val.take i.val))
    (hroom : total s + (ws.length - i.val) < Usize.max) :
    apply_loop ws s i ⦃ s' => Snapshot.toSt s' = applyAll (Snapshot.toSt s₀) ws.val ⦄ := by
  unfold apply_loop
  apply WP.spec_mono (loop_fold ws.val Snapshot.toSt applyWrite
    (fun t k => total t + (ws.length - k) < Usize.max) (fun x => apply_loop.body ws x.1 x.2) ?_ s i hi hroom)
  · intro r hr
    rw [hr, hs, applyAll, applyAll, ← List.foldl_append, List.take_append_drop]
  · intro t j hj ht; unfold apply_loop.body; i5h_step

/-- No vector can overflow: each write adds at most one row. -/
def Room (s : Snapshot) (n : Nat) : Prop := total s + n < Usize.max

@[step]
theorem apply_spec (s : Snapshot) (ws : alloc.vec.Vec Write) (h : Room s ws.length) :
    apply s ws ⦃ s' => Snapshot.toSt s' = applyAll (Snapshot.toSt s) ws.val ⦄ := by
  unfold apply
  rw [snapshot_clone]
  simp only [bind_ok]
  exact apply_loop_spec ws s s 0#usize (by simp) (by simp [applyAll])
    (by simp only [Room] at h; scalar_tac)

end atuin_kernel.ApplyLemmas
