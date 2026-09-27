import Theorems
import Schema
/-!
# Committing a write set

The theorems talk about `Spec.applyAll`, the list meaning of a write set.
Here we prove that the kernel's own `apply`, which the reference engine runs,
computes exactly that. `schema!` generated `apply` and the table operations
with their lemmas (`Schema.lean`), so only the dispatch over `Write` is left.
Deleting a crate deletes its rows in the child tables by the encoded value of
their first column.
-/
open Aeneas Aeneas.Std Result cratesio_kernel cratesio_kernel.Spec cratesio_kernel.Schema I5hLib

namespace cratesio_kernel.ApplyProofs

/-- Rows in a snapshot; each write adds at most one. -/
def total (s : Snapshot) : Nat :=
  s.users.length + s.sessions.length + s.tokens.length + s.crates.length + s.versions.length +
    s.owners.length + s.invites.length + s.deps.length

theorem write_clone (w : Write) : Write.Insts.CoreCloneClone.clone w = ok w := by
  cases w <;> rfl

set_option maxHeartbeats 1000000 in
theorem apply_write_spec (s : Snapshot) (w : Write) (h : Snapshot.size s < Usize.max) :
    apply_write s w ⦃ s' => Snapshot.toSt s' = applyWrite (Snapshot.toSt s) w ∧
      Snapshot.size s' ≤ Snapshot.size s + 1 ⦄ := by
  unfold Snapshot.size at *
  unfold apply_write
  cases w <;> step* <;> simp_all [Snapshot.toSt, applyWrite, alloc.vec.Vec.length, KRATE, Version.row,
    Owner.row, Invite.row, Dep.row] <;>
    grind [upsert_length, List.length_filter_le]

/-- The kernel's `apply` computes `Spec.applyAll`, as long as no vector can
overflow (each write adds at most one row). -/
theorem apply_spec (s : Snapshot) (ws : alloc.vec.Vec Write) (h : total s + ws.length < Usize.max) :
    apply s ws ⦃ s' => Snapshot.toSt s' = applyAll (Snapshot.toSt s) ws.val ⦄ :=
  apply_spec' Snapshot.toSt applyWrite apply_write_spec write_clone s ws h

end cratesio_kernel.ApplyProofs
