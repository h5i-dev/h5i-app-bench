import Theorems
/-!
# Committing a write set

The theorems talk about `Spec.applyAll`, the list meaning of a write set.
Here we prove that the kernel's own `apply`, which the reference engine
runs, computes exactly that, as in the second tutorial.
-/
open Aeneas Aeneas.Std Result inbox_kernel inbox_kernel.Spec inbox_kernel.Commands I5hLib

namespace inbox_kernel.ApplyProofs

/-- Rows in a snapshot; each write adds at most one. -/
def total (s : Snapshot) : Nat := s.messages.length + s.blocks.length

theorem block_clone (b : Block) : Block.Insts.CoreCloneClone.clone b = ok b := by
  simp [Block.Insts.CoreCloneClone.clone]

theorem write_clone (w : Write) : Write.Insts.CoreCloneClone.clone w = ok w := by
  cases w <;> simp [Write.Insts.CoreCloneClone.clone, message_clone, block_clone]

theorem snapshot_clone (s : Snapshot) : Snapshot.Insts.CoreCloneClone.clone s = ok s := by
  simp [Snapshot.Insts.CoreCloneClone.clone,
    vec_clone_eq Message.Insts.CoreCloneClone s.messages message_clone,
    vec_clone_eq Block.Insts.CoreCloneClone s.blocks block_clone]

@[step] theorem write_clone_spec (w : Write) : Write.Insts.CoreCloneClone.clone w ⦃ w' => w' = w ⦄ := by
  rw [write_clone]; simp

/-! ## The three table loops -/

@[step]
theorem put_message_loop_spec (v : alloc.vec.Vec Message) (m : Message) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert msgKey m v.val = v.val.take i.val ++ upsert msgKey m (v.val.drop i.val)) :
    put_message_loop v m i ⦃ v' => v'.val = upsert msgKey m v.val ⦄ := by
  unfold put_message_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide (msgKey q = msgKey m))
    (fun y : alloc.vec.Vec Message => y.val) (fun j _ => v.val.set j m) (v.val ++ [m]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result msgKey m _ _ hi hpre
  · intro j hj; unfold put_message_loop.body; i5h_step <;> simp_all [msgKey] <;> scalar_tac

@[step]
theorem put_block_loop_spec (v : alloc.vec.Vec Block) (b : Block) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert blockKey b v.val = v.val.take i.val ++ upsert blockKey b (v.val.drop i.val)) :
    put_block_loop v b i ⦃ v' => v'.val = upsert blockKey b v.val ⦄ := by
  unfold put_block_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide (blockKey q = blockKey b))
    (fun y : alloc.vec.Vec Block => y.val) (fun j _ => v.val.set j b) (v.val ++ [b]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result blockKey b _ _ hi hpre
  · intro j hj; unfold put_block_loop.body; i5h_step <;> simp_all [blockKey] <;> scalar_tac

@[step]
theorem del_block_loop_spec (v : alloc.vec.Vec Block) (b : Block) (out : alloc.vec.Vec Block)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun x => blockKey x ≠ blockKey b)) :
    del_block_loop v b out i ⦃ v' => v'.val = v.val.filter (fun x => blockKey x ≠ blockKey b) ⦄ := by
  unfold del_block_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Block => w.val)
    (fun acc x => if decide (blockKey x ≠ blockKey b) then acc ++ [x] else acc)
    (fun w j => w.length ≤ j) (fun x => del_block_loop.body v b x.1 x.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_block_loop.body; i5h_step <;> simp_all [blockKey] <;> scalar_tac

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
        | (have := upsert_length msgKey ‹Message› s.messages.val; omega)
        | (have := upsert_length blockKey ‹Block› s.blocks.val; omega)
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

end inbox_kernel.ApplyProofs
