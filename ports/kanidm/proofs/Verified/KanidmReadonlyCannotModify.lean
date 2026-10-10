import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit

namespace kanidm_kernel.Verified.KanidmReadonlyCannotModify

theorem ident_test_deny (i : Identity) (hu : IsUser i) (hs : i.scope ≠ .ReadWrite) :
    modify_acc.modify_ident_test i = ok .Deny := by
  obtain ⟨u, hu⟩ := hu
  unfold modify_acc.modify_ident_test identity_impl.access_scope
  rw [hu]
  cases h : i.scope <;> simp_all

theorem apply_deny (i : Identity) (ra : Slice profiles.AccessControlModifyResolved)
    (sa : Slice SyncAgreement) (e : Entry) (r : modify_acc.ModifyResult)
    (hu : IsUser i) (hs : i.scope ≠ .ReadWrite)
    (h : modify_acc.apply_modify_access i ra sa e = ok r) : r = .Deny := by
  unfold modify_acc.apply_modify_access at h
  simp only [ident_test_deny i hu hs] at h
  obtain ⟨_, _, h⟩ := bind_eq_ok.1 h
  obtain ⟨_, _, h⟩ := bind_eq_ok.1 h
  obtain ⟨abr, habr, h⟩ := bind_eq_ok.1 h
  simp only [Result.ok.injEq] at habr
  subst habr
  obtain ⟨dg, hdg, h⟩ := bind_eq_ok.1 h
  simp only [Result.ok.injEq] at hdg
  subst hdg
  try simp only at h
  obtain ⟨amr, _, h⟩ := bind_eq_ok.1 h
  obtain ⟨t, ht, h⟩ := bind_eq_ok.1 h
  have h1 : t.1 = true := by
    cases amr <;> simp only at ht
    all_goals first
      | (simp only [Result.ok.injEq] at ht; subst ht; rfl)
      | (h5i_invert ht; rfl)
  obtain ⟨d1, a1, a2, a3, a4⟩ := t
  simp only at h1
  subst h1
  try simp only at h
  obtain ⟨amr1, _, h⟩ := bind_eq_ok.1 h
  obtain ⟨t, ht, h⟩ := bind_eq_ok.1 h
  have h2 : t.1 = true := by
    cases amr1 <;> simp only at ht
    all_goals first
      | (simp only [Result.ok.injEq] at ht; subst ht; rfl)
      | (h5i_invert ht; rfl)
  obtain ⟨d2, t⟩ := t
  simp only at h2
  subst h2
  try simp only at h
  obtain ⟨c1, c2, c3, c4⟩ := t
  simp at h
  exact h.symm

theorem per_entry_false (ctl : AccessControlsInner) (i : Identity)
    (ra : Slice profiles.AccessControlModifyResolved) (e : Entry) (ml : Slice Modify) (b : Bool)
    (hu : IsUser i) (hs : i.scope ≠ .ReadWrite)
    (h : access.modify_allow_operation_per_entry ctl i ra e ml = ok b) : b = false := by
  unfold access.modify_allow_operation_per_entry at h
  h5i_invert h
  all_goals first
    | rfl
    | (obtain ⟨p1, p2⟩ := p
       try simp only at h
       first
         | (simp at h; subst h; rfl)
         | (obtain ⟨mr, hmr, h⟩ := bind_eq_ok.1 h
            have := apply_deny _ _ _ _ _ hu hs hmr
            subst this
            simp at h
            subst h; rfl))

theorem readonly_cannot_modify (ctl : AccessControlsInner) (me : ModifyEvent) (es : Slice Entry) (b : Bool)
    (hu : IsUser me.ident) (hs : me.ident.scope ≠ .ReadWrite) (hne : es.val ≠ [])
    (h : access.modify_allow_operation ctl me es = ok (.Ok b)) :
    b = false := by
  unfold access.modify_allow_operation at h
  obtain ⟨ra, _, h⟩ := bind_eq_ok.1 h
  obtain ⟨b', hb, h⟩ := bind_eq_ok.1 h
  simp only [Result.ok.injEq, core.result.Result.Ok.injEq] at h
  subst h
  unfold access.modify_all_entries access.modify_all_entries_loop at hb
  refine H5iAppLib.loop_ok _ (fun x : Usize => x.val = 0) (fun y => y = false) (fun _ => 0) ?_ _ _ rfl hb
  intro x r hx hr
  unfold access.modify_all_entries_loop.body at hr
  h5i_invert hr
  · exact absurd (per_entry_false _ _ _ _ _ _ hu hs hb_1) (by simp [hc_1])
  · rfl
  · exfalso
    have : es.val.length = 0 := by scalar_tac
    simp_all

end kanidm_kernel.Verified.KanidmReadonlyCannotModify
