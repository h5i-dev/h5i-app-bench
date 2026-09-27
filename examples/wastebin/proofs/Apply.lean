import Theorems
import Schema
/-!
# Committing a write set

The theorems talk about `Spec.applyAll`, the list meaning of a write set.
Here we prove that the kernel's own `apply`, which the reference engine runs,
computes exactly that. `schema!` generated `apply` and the table operations
with their lemmas, so only the dispatch over `Write` is left.
-/
open Aeneas Aeneas.Std Result wastebin_kernel wastebin_kernel.Spec wastebin_kernel.Schema I5hLib

namespace wastebin_kernel.ApplyProofs

theorem write_clone (w : Write) : Write.Insts.CoreCloneClone.clone w = ok w := by
  cases w <;> simp [Write.Insts.CoreCloneClone.clone, Paste.clone_eq, Counter.clone_eq, lift]

theorem apply_write_spec (s : Snapshot) (w : Write) (h : Snapshot.size s < Usize.max) :
    apply_write s w ⦃ s' => Snapshot.toSt s' = applyWrite (Snapshot.toSt s) w ∧
      Snapshot.size s' ≤ Snapshot.size s + 1 ⦄ := by
  unfold Snapshot.size at *
  unfold apply_write
  cases w <;> step* <;> simp_all [Snapshot.toSt, applyWrite, alloc.vec.Vec.length] <;>
    grind [upsert_length, List.length_filter_le]

/-- The kernel's `apply` computes `Spec.applyAll`, as long as the paste
vector cannot overflow (each write adds at most one row). -/
theorem apply_spec (s : Snapshot) (ws : alloc.vec.Vec Write) (h : s.pastes.length + ws.length < Usize.max) :
    apply s ws ⦃ s' => Snapshot.toSt s' = applyAll (Snapshot.toSt s) ws.val ⦄ :=
  apply_spec' Snapshot.toSt applyWrite apply_write_spec write_clone s ws h

end wastebin_kernel.ApplyProofs
