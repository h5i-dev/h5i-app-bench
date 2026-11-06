import Verified.Tables
import Verified.Delegation
/-! Specs for the route-scope functions of `kernel/src/delegation.rs`. -/
open Aeneas Aeneas.Std Result openobserve_kernel openobserve_kernel.Spec openobserve_kernel.Verified
open H5iAppLib hiding lit
open openobserve_kernel.delegation

namespace openobserve_kernel.Verified

set_option linter.deprecated false in
@[step] theorem method_eq_spec (a b : Method) :
    Method.Insts.CoreCmpPartialEqMethod.eq a b ⦃ r => r = decide (a = b) ⦄ := by
  cases a <;> cases b <;> simp [Method.Insts.CoreCmpPartialEqMethod.eq, Method.read_discriminant]

@[step] theorem method_in_spec (ms : Slice Method) (m : Method) :
    method_in ms m ⦃ b => b = decide (m ∈ ms.val) ⦄ := by
  unfold method_in method_in_loop
  apply WP.spec_mono (loop_search ms.val (fun x => decide (x = m)) id
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro b hb
    rw [id, searchFrom_const] at hb
    simp only [UScalar.ofNatCore_val_eq, List.drop_zero] at hb
    rw [hb]
    by_cases h : m ∈ ms.val
    · simp [h, List.any_eq_true]
    · simp only [h, decide_false]
      have : ms.val.any (fun x => decide (x = m)) = false := by
        simp only [List.any_eq_false, decide_eq_true_eq]; intro x hx he; exact h (he ▸ hx)
      rw [this]; rfl
  · intro i hi
    unfold method_in_loop.body; simp only []
    step*
    · left; exact ⟨by scalar_tac, by simp_all, rfl⟩
    · exact ⟨by scalar_tac, by simp_all, by scalar_tac⟩
    · right; exact ⟨by scalar_tac, rfl⟩

theorem lit_slice {n : Usize} {l : List U8} {h} (s : Slice U8) (hs : s = (Array.make n l h).to_slice) :
    s.val = l := by subst hs; simp [Array.to_slice, Array.make]

@[step] theorem scope_routes_spec (scope : Slice U8) :
    scope_routes scope ⦃ o => o.map (fun v => v.val.map toSRoute) = scopeRoutes (nats scope.val) ⦄ := by
  unfold scope_routes scopeRoutes
  step*
  all_goals (subst_vars; simp_all [Array.to_slice, Array.make, nats])


theorem relativePath_eq (l : List Nat) :
    relativePath l = if [47] <+: l then l.drop 1 else l := by
  rcases l with _ | ⟨a, t⟩
  · rfl
  · by_cases h : a = 47
    · subst h; simp [relativePath]
    · simp [relativePath, h]

@[step] theorem relative_path_spec (path : Slice U8) :
    relative_path path ⦃ v => nats v.val = relativePath (nats path.val) ⦄ := by
  unfold relative_path
  step*
  all_goals (subst_vars; simp_all [Array.to_slice, Array.make, nats, relativePath_eq])


theorem splitAcc_ne_nil (cur l : List Nat) : splitAcc cur l ≠ [] := by
  induction l generalizing cur with
  | nil => simp [splitAcc]
  | cons c cs ih => unfold splitAcc; split <;> simp_all

theorem splitSlash_ne_nil (l : List Nat) : splitSlash l ≠ [] := splitAcc_ne_nil _ _

@[step] theorem path_org_spec (rel : Slice U8) (hs : rel.length < Usize.max) :
    path_org rel ⦃ o => o.map (fun v => nats v.val) = pathOrg (nats rel.val) ⦄ := by
  unfold path_org
  step*
  unfold pathOrg
  rw [← cols_post]
  have hlen : cols.len.val = cols.val.length := by simp
  rcases hc : cols.val with _ | ⟨a, _ | ⟨b, r⟩⟩
  · rw [hc] at cols_post; exact absurd cols_post.symm (splitSlash_ne_nil _)
  · rw [if_neg (by scalar_tac)]
    clear cols_post
    step*
    all_goals simp_all
  · rw [if_pos (by scalar_tac)]
    clear cols_post
    have ha : cols.val[0]'(by simp [hc]) = a := by simp [hc]
    have hv2 : ∀ h, ((Array.make 2#usize [118#u8, 50#u8] h).to_slice : Slice U8).val = [118#u8, 50#u8] := by
      intro h; simp [Array.to_slice, Array.make]
    by_cases hv : nats a.val = [118, 50]
    · step*
      have hx : x = true := by
        subst_vars; simp only [alloc.vec.Vec.deref, hv2, ha]; simpa [nats] using hv
      rw [hx, if_pos rfl]
      step*
      all_goals simp_all [List.length_cons, nats]
      all_goals (first | (constructor <;> rintro rfl <;> simp_all) | (rintro rfl; simp_all) | (intro _ h; simp_all) | grind)
    · step*
      have hx : x = false := by
        subst_vars; simp only [alloc.vec.Vec.deref, hv2, ha]; simpa [nats] using hv
      rw [hx]; simp only [Bool.false_eq_true, if_false]
      step*
      all_goals simp_all [List.length_cons, nats]
      all_goals (first | (constructor <;> rintro rfl <;> simp_all) | (rintro rfl; simp_all) | (intro _ h; simp_all) | grind)


end openobserve_kernel.Verified
