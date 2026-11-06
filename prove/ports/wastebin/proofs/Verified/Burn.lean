import Verified.Get
/-!
# Burn after reading under concurrent readers

`burnReaders` runs the burning `DELETE`s of readers who all passed `fetch`.
Exactly the first one to commit receives the content, if the paste is still
there; every later one gets `NotFound`.
-/
open Aeneas Aeneas.Std Result wastebin_kernel wastebin_kernel.Spec
open H5iAppLib
open Aeneas.Std.WP
open wastebin_kernel.Verified.Store wastebin_kernel.Verified.Get

namespace wastebin_kernel.Verified.Burn

theorem without_of_absent {rows : List Row} {id : I64} (h : present rows id = false) :
    without rows id = rows := by
  simp only [present, List.any_eq_false, decide_eq_true_eq] at h
  simp only [without, List.filter_eq_self, decide_eq_true_eq]
  exact h

theorem burn_readers_spec (id : I64) (rs : List (store.Data × Bool)) (v : alloc.vec.Vec Row) :
    burnReaders id rs v ⦃ bs => bs.length = rs.length ∧
      bs.count true = if present v.val id = true ∧ rs ≠ [] then 1 else 0 ⦄ := by
  induction rs generalizing v with
  | nil => simp [burnReaders]
  | cons x rs ih =>
    obtain ⟨d, enc⟩ := x
    unfold burnReaders
    step as ⟨v', res, h1, h2⟩
    apply WP.spec_bind (ih v')
    rintro bs ⟨hl, hc⟩
    have hv' : present v'.val id = false := by simp only [h1, if_true]; exact present_without _ _
    simp only [hv', Bool.false_eq_true, false_and, if_false] at hc
    simp only [WP.spec_ok, List.length_cons, hl, List.count_cons, hc, true_and, ne_eq,
      reduceCtorEq, not_false_eq_true, and_true]
    rw [h2]
    cases hp : present v.val id <;> cases enc <;> simp [finishM]

end wastebin_kernel.Verified.Burn
