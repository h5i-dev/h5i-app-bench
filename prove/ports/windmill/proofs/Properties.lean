import Lemmas
/-!
# Security properties of windmill's path and scope checks
-/
open Aeneas Aeneas.Std Result windmill_kernel windmill_kernel.Spec windmill_kernel.Lemmas H5iAppLib

namespace windmill_kernel.Properties

/-- Path ownership: a non-admin passes `require_owner_of_path` only for a path in their
own user namespace `u/<username>/...` or in a folder they own `f/<folder>/...`. -/
theorem owner_of_path_sound (a : authz.Authed) (p : Slice U8) (hp : p.length < Usize.max)
    (h : authz.require_owner_of_path a p = ok (.Ok ())) : ownerOfPath a p.val := by
  unfold authz.require_owner_of_path at h
  h5i_invert h
  · exact Or.inl hc
  all_goals
    have hs := post_of_ok (split_spec p 47#u8 hp) hparts
    change parts.val.map (·.val) = segments slashB p.val at hs
    have hl : 2 ≤ (segments slashB p.val).length := by
      rw [← hs]; simp only [List.length_map]; scalar_tac
    refine Or.inr ⟨_, rfl, hl, ?_⟩
    have e0 := seg_of hs hv
    have e1 := seg_of hs hv1
    simp only [UScalar.ofNatCore_val_eq, Usize.ofNatCore_val_eq] at e0 e1
    rw [e0, e1]
  · left
    exact ⟨by simpa [vec_deref_val, U_val] using eq_true hb hc_3, by simpa [vec_deref_val] using eq_true hb1 hc_4⟩
  · right
    exact ⟨by simpa [vec_deref_val, F_val] using eq_true hb1 hc_4, by simpa [vec_deref_val] using require_is_owner_ok h⟩

/-- What a successful preview access check establishes. -/
def previewOk (a : authz.Authed) (path : Bytes) : Prop :=
  ¬ traversal path ∧
  (a.is_admin = true ∨ path = [] ∨
    ∃ segs, segments slashB path = segs ∧ 2 ≤ segs.length ∧
      ((segs[0]! = uB ∧ segs[1]! = a.username.val) ∨ (segs[0]! = fB ∧ readsFolder a segs[1]!) ∨
        segs[0]! = [104#u8, 117#u8, 98#u8]))

theorem preview_spec (a : authz.Authed) (p : Slice U8) (hp : p.length < Usize.max) :
    authz.require_path_read_access_for_preview a p ⦃ r => r = .Ok () → previewOk a p.val ⦄ := by
  unfold authz.require_path_read_access_for_preview
  step*
  all_goals sorry

end windmill_kernel.Properties
