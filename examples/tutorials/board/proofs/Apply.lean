import Theorems
/-!
# Committing a write set

The theorems in `Theorems.lean` talk about `Spec.applyAll`, the list meaning of
a write set. Here we prove that the kernel's own `apply`, which the reference
engine runs, computes exactly that. Each loop is covered by a lemma from
`I5hLib`: `loop_search` for the upserts and `loop_fold` for the deletes and
for `apply` itself.
-/
open Aeneas Aeneas.Std Result board_kernel board_kernel.Spec board_kernel.Commands I5hLib

namespace board_kernel.ApplyProofs

/-- Rows in a snapshot; each write adds at most one. -/
def total (s : Snapshot) : Nat := s.posts.length + s.moderators.length

theorem moderator_clone (m : Moderator) : Moderator.Insts.CoreCloneClone.clone m = ok m := by
  simp [Moderator.Insts.CoreCloneClone.clone, lift]

theorem write_clone (w : Write) : Write.Insts.CoreCloneClone.clone w = ok w := by
  cases w <;> simp [Write.Insts.CoreCloneClone.clone, post_clone, moderator_clone,
    Counter.Insts.CoreCloneClone.clone, lift]

theorem snapshot_clone (s : Snapshot) : Snapshot.Insts.CoreCloneClone.clone s = ok s := by
  simp [Snapshot.Insts.CoreCloneClone.clone, Counter.Insts.CoreCloneClone.clone, lift,
    vec_clone_eq Post.Insts.CoreCloneClone s.posts post_clone,
    vec_clone_eq Moderator.Insts.CoreCloneClone s.moderators moderator_clone]

@[step] theorem write_clone_spec (w : Write) : Write.Insts.CoreCloneClone.clone w ⦃ w' => w' = w ⦄ := by
  rw [write_clone]; simp

@[step] theorem moderator_clone_spec (m : Moderator) : Moderator.Insts.CoreCloneClone.clone m ⦃ m' => m' = m ⦄ := by
  rw [moderator_clone]; simp

/-! ## The four table loops -/

@[step]
theorem put_post_loop_spec (v : alloc.vec.Vec Post) (p : Post) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (·.id) p v.val = v.val.take i.val ++ upsert (·.id) p (v.val.drop i.val)) :
    put_post_loop v p i ⦃ v' => v'.val = upsert (·.id) p v.val ⦄ := by
  unfold put_post_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide (q.id = p.id))
    (fun y : alloc.vec.Vec Post => y.val) (fun j _ => v.val.set j p) (v.val ++ [p]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (·.id) p _ _ hi hpre
  · intro j hj; unfold put_post_loop.body; i5h_step

@[step]
theorem put_moderator_loop_spec (v : alloc.vec.Vec Moderator) (m : Moderator) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (·.user) m v.val = v.val.take i.val ++ upsert (·.user) m (v.val.drop i.val)) :
    put_moderator_loop v m i ⦃ v' => v'.val = upsert (·.user) m v.val ⦄ := by
  unfold put_moderator_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide (q.user = m.user))
    (fun y : alloc.vec.Vec Moderator => y.val) (fun j _ => v.val.set j m) (v.val ++ [m]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (·.user) m _ _ hi hpre
  · intro j hj; unfold put_moderator_loop.body; i5h_step

@[step]
theorem del_post_loop_spec (v : alloc.vec.Vec Post) (k : U64) (out : alloc.vec.Vec Post)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun x => x.id ≠ k)) :
    del_post_loop v k out i ⦃ v' => v'.val = v.val.filter (fun x => x.id ≠ k) ⦄ := by
  unfold del_post_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Post => w.val)
    (fun acc x => if decide (x.id ≠ k) then acc ++ [x] else acc)
    (fun w j => w.length ≤ j) (fun x => del_post_loop.body v k x.1 x.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_post_loop.body; i5h_step

@[step]
theorem del_moderator_loop_spec (v : alloc.vec.Vec Moderator) (k : U64) (out : alloc.vec.Vec Moderator)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun x => x.user ≠ k)) :
    del_moderator_loop v k out i ⦃ v' => v'.val = v.val.filter (fun x => x.user ≠ k) ⦄ := by
  unfold del_moderator_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Moderator => w.val)
    (fun acc x => if decide (x.user ≠ k) then acc ++ [x] else acc)
    (fun w j => w.length ≤ j) (fun x => del_moderator_loop.body v k x.1 x.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_moderator_loop.body; i5h_step

/-! ## One write, then the whole set -/

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
        | (have := upsert_length (·.id) ‹Post› s.posts.val; omega)
        | (have := upsert_length (·.user) ‹Moderator› s.moderators.val; omega)
        | grind [List.length_filter_le]
    | simp

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

/-- The kernel's `apply` computes `Spec.applyAll`, as long as no vector can
overflow (each write adds at most one row). -/
theorem apply_spec (s : Snapshot) (ws : alloc.vec.Vec Write) (h : total s + ws.length < Usize.max) :
    apply s ws ⦃ s' => Snapshot.toSt s' = applyAll (Snapshot.toSt s) ws.val ⦄ := by
  unfold apply
  rw [snapshot_clone]
  simp only [bind_ok]
  exact apply_loop_spec ws s s 0#usize (by simp) (by simp [applyAll]) (by scalar_tac)

end board_kernel.ApplyProofs
