import Aeneas
/-! Facts about Aeneas scalars and clones used by every kernel. -/
open Aeneas Aeneas.Std Result

namespace I5hLib

theorem usize_max_le : Usize.max ≤ U64.max := by
  rw [Usize.max_def, U64.max_def]
  cases System.Platform.numBits_eq <;> simp_all [Usize.numBits, U64.numBits]

/-- Cloning a vector whose element clone is the identity returns the vector. -/
theorem vec_clone_eq {T : Type} (inst : core.clone.Clone T) (v : alloc.vec.Vec T)
    (h : ∀ x, inst.clone x = ok x) : alloc.vec.CloneVec.clone inst v = ok v := by
  have := Slice.clone_spec (clone := inst.clone) (s := v.slice) (fun x _ => h x)
  rw [WP.spec_equiv_exists] at this
  obtain ⟨s', hs, heq⟩ := this
  simp [alloc.vec.CloneVec.clone, hs, ← heq]

/-- Lift a property of a successful `Ok (writes, reply)` to a postcondition. -/
def OnOk {α β ε} (P : α → β → Prop) : core.result.Result (α × β) ε → Prop
  | .Ok (ws, r) => P ws r
  | .Err _ => True

theorem of_spec {α β ε} {m : Result (core.result.Result (α × β) ε)} {P : α → β → Prop}
    (hs : m ⦃ OnOk P ⦄) {ws : α} {r : β} (h : m = .ok (.Ok (ws, r))) : P ws r := by
  obtain ⟨o, ho, hp⟩ := (WP.spec_equiv_exists _ _).1 hs
  rw [h, Result.ok.injEq] at ho
  subst ho
  exact hp

theorem eq_ok_of_spec {α} {m : Result α} {v : α} (h : m ⦃ x => x = v ⦄) : m = ok v := by
  obtain ⟨y, hy, rfl⟩ := (WP.spec_equiv_exists _ _).1 h
  exact hy

end I5hLib
