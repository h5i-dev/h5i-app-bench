import Theorems
/-!
# Committing a write set

The theorems talk about `Spec.applyAll`. Here we prove that the kernel's own
`apply`, which the reference engine runs, computes exactly that, using
`loop_search` for the upsert and `loop_fold` for the loop over the writes.
-/
open Aeneas Aeneas.Std Result ledger_kernel ledger_kernel.Spec ledger_kernel.Commands I5hLib

namespace ledger_kernel.ApplyProofs

theorem snapshot_clone (s : Snapshot) : Snapshot.Insts.CoreCloneClone.clone s = ok s := by
  simp [Snapshot.Insts.CoreCloneClone.clone, Ledger.Insts.CoreCloneClone.clone,
    vec_clone_eq Account.Insts.CoreCloneClone s.accounts (fun _ => rfl)]

@[step]
theorem put_account_loop_spec (v : alloc.vec.Vec Account) (a : Account) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (·.id) a v.val = v.val.take i.val ++ upsert (·.id) a (v.val.drop i.val)) :
    put_account_loop v a i ⦃ v' => v'.val = upsert (·.id) a v.val ⦄ := by
  unfold put_account_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide (q.id = a.id))
    (fun y : alloc.vec.Vec Account => y.val) (fun j _ => v.val.set j a) (v.val ++ [a]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (·.id) a _ _ hi hpre
  · intro j hj; unfold put_account_loop.body; i5h_step

@[step]
theorem apply_write_spec (s : Snapshot) (w : Write) (h : s.accounts.length < Usize.max) :
    apply_write s w ⦃ s' => Snapshot.toSt s' = applyWrite (Snapshot.toSt s) w ∧
      s'.accounts.length ≤ s.accounts.length + 1 ⦄ := by
  unfold apply_write
  cases w <;> step*
  · simp
  · refine ⟨by simp [Snapshot.toSt, applyWrite, *], ?_⟩
    simp only [alloc.vec.Vec.length, v_post]
    exact upsert_length (fun b : Account => b.id) _ _
  · exact ⟨rfl, by omega⟩

@[step]
theorem apply_loop_spec (ws : alloc.vec.Vec Write) (s₀ s : Snapshot) (i : Usize)
    (hi : i.val ≤ ws.length)
    (hs : Snapshot.toSt s = applyAll (Snapshot.toSt s₀) (ws.val.take i.val))
    (hroom : s.accounts.length + (ws.length - i.val) < Usize.max) :
    apply_loop ws s i ⦃ s' => Snapshot.toSt s' = applyAll (Snapshot.toSt s₀) ws.val ⦄ := by
  unfold apply_loop
  apply WP.spec_mono (loop_fold ws.val Snapshot.toSt applyWrite
    (fun t k => t.accounts.length + (ws.length - k) < Usize.max) (fun x => apply_loop.body ws x.1 x.2) ?_ s i hi hroom)
  · intro r hr
    rw [hr, hs, applyAll, applyAll, ← List.foldl_append, List.take_append_drop]
  · intro t j hj ht; unfold apply_loop.body; i5h_step

/-- The kernel's `apply` computes `Spec.applyAll`, as long as the accounts
vector cannot overflow (each write adds at most one row). -/
theorem apply_spec (s : Snapshot) (ws : alloc.vec.Vec Write) (h : s.accounts.length + ws.length < Usize.max) :
    apply s ws ⦃ s' => Snapshot.toSt s' = applyAll (Snapshot.toSt s) ws.val ⦄ := by
  unfold apply
  rw [snapshot_clone]
  simp only [bind_ok]
  exact apply_loop_spec ws s s 0#usize (by simp) (by simp [applyAll]) (by scalar_tac)

end ledger_kernel.ApplyProofs
