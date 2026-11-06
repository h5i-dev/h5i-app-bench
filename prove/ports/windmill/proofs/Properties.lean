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

theorem not_traversal_of (p : Slice U8) (parts : alloc.vec.Vec (alloc.vec.Vec U8))
    (hs : parts.val.map (·.val) = segments 47#u8 p.val)
    (hhead : ∀ h : 0 < p.val.length, p.val[0] ≠ 47#u8)
    (hd : ∀ q ∈ parts.val, q.val ≠ dotdot)
    (hn : ∀ c ∈ p.val, c.val ≠ 0) : ¬ traversal p.val := by
  rintro (h1 | h2 | h3)
  · cases hp : p.val with
    | nil => simp [hp] at h1
    | cons x xs =>
      have := hhead (by simp [hp])
      simp only [hp, List.head?_cons, Option.some.injEq] at h1
      simp [hp, h1, slashB] at this
  · change dotdot ∈ segments 47#u8 p.val at h2
    rw [← hs, List.mem_map] at h2
    obtain ⟨q, hq, hqe⟩ := h2
    exact hd q hq hqe
  · exact hn _ h3 rfl

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
  all_goals
    intro _
    refine ⟨not_traversal_of p parts parts_post (by intro h0; simp_all) (by simp_all [vec_deref_val])
      (by simp_all), ?_⟩
  all_goals first
    | exact Or.inl ‹_›
    | (right; left
       have h0 := ‹p.len = 0#usize›
       have : p.val.length = 0 := by simpa using congrArg (·.val) h0
       exact List.eq_nil_of_length_eq_zero this)
    | (right; right
       have hpl : 2 ≤ parts.val.length := by scalar_tac
       have hl : 2 ≤ (segments slashB p.val).length := by
         change 2 ≤ (segments 47#u8 p.val).length
         rw [← parts_post]; simp only [List.length_map]; exact hpl
       refine ⟨_, rfl, hl, ?_⟩
       have e0 : (segments slashB p.val)[0]! = (parts.val[0]'(by omega)).val := by
         change (segments 47#u8 p.val)[0]! = _
         rw [← parts_post]; simp [List.getElem!_eq_getElem?_getD, show 0 < parts.val.length by omega]
       have e1 : (segments slashB p.val)[1]! = (parts.val[1]'(by omega)).val := by
         change (segments 47#u8 p.val)[1]! = _
         rw [← parts_post]; simp [List.getElem!_eq_getElem?_getD, show 1 < parts.val.length by omega]
       rw [e0, e1]
       simp_all [vec_deref_val, U_val, F_val, readsFolder, authz.HUB, array_to_slice_val])

/-- A preview job's path never escapes its directory: no leading `/`, no `..`
segment, no NUL byte, whoever asks (the check runs before the admin bypass). -/
theorem preview_never_traverses (a : authz.Authed) (p : Slice U8) (hp : p.length < Usize.max)
    (h : authz.require_path_read_access_for_preview a p = ok (.Ok ())) : ¬ traversal p.val :=
  (post_of_ok (preview_spec a p hp) h rfl).1

/-- A non-admin previews only in their own user namespace, a folder they can read,
or the hub. -/
theorem preview_requires_namespace (a : authz.Authed) (p : Slice U8) (hp : p.length < Usize.max)
    (h : authz.require_path_read_access_for_preview a p = ok (.Ok ())) (hna : a.is_admin = false)
    (hne : p.val ≠ []) :
    ∃ segs, segments slashB p.val = segs ∧ 2 ≤ segs.length ∧
      ((segs[0]! = uB ∧ segs[1]! = a.username.val) ∨ (segs[0]! = fB ∧ readsFolder a segs[1]!) ∨
        segs[0]! = [104#u8, 117#u8, 98#u8]) := by
  have := (post_of_ok (preview_spec a p hp) h rfl).2
  rcases this with h1 | h2 | h3
  · simp [hna] at h1
  · exact absurd h2 hne
  · exact h3

/-- `is_owner` grants only admins and owners of the folder. -/
theorem is_owner_sound (a : authz.Authed) (n : Slice U8) (h : authz.is_owner a n = ok true) :
    ownsFolder a n.val :=
  (post_of_ok (is_owner_spec a n) h).1 rfl

/-- Instance-global admin actions are never allowed to a job token (`WM_TOKEN`) and
always require admin. -/
theorem instance_admin_never_job_token (a : authz.Authed)
    (h : authz.require_instance_admin a = ok (.Ok ())) : a.has_job_id = false ∧ a.is_admin = true := by
  unfold authz.require_instance_admin at h
  split_ifs at h <;> simp_all

theorem covers_spec (c r : Slice U8) :
    scopes.resource_covers c r ⦃ b => b = true → coversSem c.val r.val ⦄ := by
  unfold scopes.resource_covers
  step*
  all_goals trace_state
  all_goals sorry

end windmill_kernel.Properties
