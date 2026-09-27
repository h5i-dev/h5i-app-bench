import Theorems
/-!
# Committing a write set

The theorems talk about `Spec.applyAll`, the list meaning of a write set.
Here we prove that the kernel's own `apply`, which the reference engine runs,
computes exactly that. `loop_search` covers the upsert and `loop_fold` the
delete and `apply` itself.
-/
open Aeneas Aeneas.Std Result wastebin_kernel wastebin_kernel.Spec wastebin_kernel.Commands I5hLib

namespace wastebin_kernel.ApplyProofs

theorem write_clone (w : Write) : Write.Insts.CoreCloneClone.clone w = ok w := by
  cases w <;> simp [Write.Insts.CoreCloneClone.clone, paste_clone, Counter.Insts.CoreCloneClone.clone, lift]

theorem snapshot_clone (s : Snapshot) : Snapshot.Insts.CoreCloneClone.clone s = ok s := by
  simp [Snapshot.Insts.CoreCloneClone.clone, Counter.Insts.CoreCloneClone.clone,
    vec_clone_eq Paste.Insts.CoreCloneClone s.pastes paste_clone]

@[step] theorem write_clone_spec (w : Write) : Write.Insts.CoreCloneClone.clone w ⦃ w' => w' = w ⦄ := by
  rw [write_clone]; simp

@[step]
theorem put_paste_loop_spec (v : alloc.vec.Vec Paste) (p : Paste) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (·.id) p v.val = v.val.take i.val ++ upsert (·.id) p (v.val.drop i.val)) :
    put_paste_loop v p i ⦃ v' => v'.val = upsert (·.id) p v.val ⦄ := by
  unfold put_paste_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide (q.id = p.id))
    (fun y : alloc.vec.Vec Paste => y.val) (fun j _ => v.val.set j p) (v.val ++ [p]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (·.id) p _ _ hi hpre
  · intro j hj; unfold put_paste_loop.body; i5h_step

@[step]
theorem del_paste_loop_spec (v : alloc.vec.Vec Paste) (k : U64) (out : alloc.vec.Vec Paste)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun x => x.id ≠ k)) :
    del_paste_loop v k out i ⦃ v' => v'.val = v.val.filter (fun x => x.id ≠ k) ⦄ := by
  unfold del_paste_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Paste => w.val)
    (fun acc x => if decide (x.id ≠ k) then acc ++ [x] else acc)
    (fun w j => w.length ≤ j) (fun x => del_paste_loop.body v k x.1 x.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_paste_loop.body; i5h_step

@[step]
theorem apply_write_spec (s : Snapshot) (w : Write) (h : s.pastes.length < Usize.max) :
    apply_write s w ⦃ s' => Snapshot.toSt s' = applyWrite (Snapshot.toSt s) w ∧
      s'.pastes.length ≤ s.pastes.length + 1 ⦄ := by
  unfold apply_write
  cases w <;> step*
  all_goals first
    | refine ⟨by simp [Snapshot.toSt, applyWrite, *], ?_⟩
      simp only [alloc.vec.Vec.length, *]
      first
        | omega
        | (have := upsert_length (·.id) ‹Paste› s.pastes.val; omega)
        | grind [List.length_filter_le]
    | simp

@[step]
theorem apply_loop_spec (ws : alloc.vec.Vec Write) (s₀ s : Snapshot) (i : Usize)
    (hi : i.val ≤ ws.length)
    (hs : Snapshot.toSt s = applyAll (Snapshot.toSt s₀) (ws.val.take i.val))
    (hroom : s.pastes.length + (ws.length - i.val) < Usize.max) :
    apply_loop ws s i ⦃ s' => Snapshot.toSt s' = applyAll (Snapshot.toSt s₀) ws.val ⦄ := by
  unfold apply_loop
  apply WP.spec_mono (loop_fold ws.val Snapshot.toSt applyWrite
    (fun t k => t.pastes.length + (ws.length - k) < Usize.max) (fun x => apply_loop.body ws x.1 x.2) ?_ s i hi hroom)
  · intro r hr
    rw [hr, hs, applyAll, applyAll, ← List.foldl_append, List.take_append_drop]
  · intro t j hj ht; unfold apply_loop.body; i5h_step

/-- The kernel's `apply` computes `Spec.applyAll`, as long as the paste
vector cannot overflow (each write adds at most one row). -/
theorem apply_spec (s : Snapshot) (ws : alloc.vec.Vec Write) (h : s.pastes.length + ws.length < Usize.max) :
    apply s ws ⦃ s' => Snapshot.toSt s' = applyAll (Snapshot.toSt s) ws.val ⦄ := by
  unfold apply
  rw [snapshot_clone]
  simp only [bind_ok]
  exact apply_loop_spec ws s s 0#usize (by simp) (by simp [applyAll]) (by scalar_tac)

end wastebin_kernel.ApplyProofs
