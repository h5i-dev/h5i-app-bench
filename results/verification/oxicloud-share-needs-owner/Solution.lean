import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.Spec
open H5iAppLib hiding lit

namespace oxicloud_kernel.Solution

theorem live_ok (g : model.Grant) (now : I64) (h : acl.live g now = ok true) : Live g now := by
  unfold acl.live at h
  unfold Live Spec.live
  cases he : g.expires_at with
  | none => simp
  | some t => simp_all

theorem implies_share (r : model.Role) (h : acl.role_implies r .Share = ok true) : r = .Owner := by
  cases r <;> simp_all [acl.role_implies, model.Role.Insts.CoreCmpPartialEqRole.eq, model.Role.read_discriminant]

theorem grants_share (r : model.Role) (h : acl.role_grants r .Share = ok true) : r = .Owner := by
  cases r <;> simp_all [acl.role_grants, model.Permission.Insts.CoreCmpPartialEqPermission.eq, model.Permission.read_discriminant]

theorem direct_true (db : model.Db) types ids p r now
    (h : acl.direct_grant_exists db types ids p r now = ok true) :
    ∃ g ∈ db.grants.val, acl.role_implies g.role p = ok true ∧ acl.live g now = ok true := by
  unfold acl.direct_grant_exists acl.direct_grant_exists_loop at h
  refine loop_idx_ok _ id db.grants.length (fun _ => True) (fun b => b = true → _) ?_ _ _ trivial (by simp) h rfl
  intro i res _ hle hb
  unfold acl.direct_grant_exists_loop.body at hb
  h5i_invert hb
  all_goals first
    | (intro _; exact ⟨g, vec_index_slice_ok_mem hg, by simp_all, by simp_all⟩)
    | (simp only [id]; h5i_ok_facts; refine ⟨trivial, ?_, ?_⟩ <;> scalar_tac)
    | simp

theorem cascade_true (db : model.Db) types ids p fid now
    (h : acl.folder_cascade_grant_exists db types ids p fid now = ok true) :
    ∃ g ∈ db.grants.val, acl.role_implies g.role p = ok true ∧ acl.live g now = ok true := by
  unfold acl.folder_cascade_grant_exists at h
  h5i_invert h
  unfold acl.folder_cascade_grant_exists_loop at h
  refine loop_idx_ok _ id db.grants.length (fun _ => True) (fun b => b = true → _) ?_ _ _ trivial (by simp) h rfl
  intro i res _ hle hb
  unfold acl.folder_cascade_grant_exists_loop.body at hb
  h5i_invert hb
  all_goals first
    | (intro _; exact ⟨g, vec_index_slice_ok_mem hg, by simp_all, by simp_all⟩)
    | (simp only [id]; h5i_ok_facts; refine ⟨trivial, ?_, ?_⟩ <;> scalar_tac)
    | simp

theorem stronger_ok (best : Option model.Role) r o (h : acl.stronger best r = ok o) : o = some r ∨ o = best := by
  unfold acl.stronger at h
  h5i_invert h <;> simp

/-- Every role the drive scan has picked so far comes from a live grant. -/
def RoleOk (db : model.Db) (now : I64) (o : Option model.Role) : Prop :=
  ∀ ro, o = some ro → ∃ g ∈ db.grants.val, g.role = ro ∧ acl.live g now = ok true

theorem caller_role_ok (db : model.Db) s d now o
    (h : acl.caller_role_on_drive db s d now = ok o) : RoleOk db now o := by
  unfold acl.caller_role_on_drive at h
  h5i_invert h
  unfold acl.caller_role_on_drive_loop at h
  refine loop_idx_ok _ (fun x => x.2) db.grants.length (fun x => RoleOk db now x.1) (RoleOk db now) ?_ _ _
    (by simp [RoleOk]) (by simp) h
  rintro ⟨best, i⟩ res hinv hle hb
  unfold acl.caller_role_on_drive_loop.body at hb
  h5i_invert hb
  · simp only
    h5i_ok_facts
    refine ⟨?_, by scalar_tac, by scalar_tac⟩
    simp only at hinv; show RoleOk db now best1
    split at hbest1
    · h5i_invert hbest1
      · rcases stronger_ok _ _ _ hbest1 with rfl | rfl
        · intro ro hro; cases hro; exact ⟨g, vec_index_slice_ok_mem hg, rfl, by simp_all⟩
        · exact hinv
      all_goals simp_all
    · simp_all
  · simpa using hinv

abbrev Goal (db : model.Db) (now : I64) : Prop := ∃ g ∈ db.grants.val, g.role = .Owner ∧ Live g now

theorem of_grant (db : model.Db) now
    (h : ∃ g ∈ db.grants.val, acl.role_implies g.role .Share = ok true ∧ acl.live g now = ok true) :
    Goal db now := by
  obtain ⟨g, hg, h1, h2⟩ := h
  exact ⟨g, hg, implies_share _ h1, live_ok _ _ h2⟩

theorem of_role_has (db : model.Db) now s d o (ho : acl.caller_role_on_drive db s d now = ok o)
    (h : acl.role_has o .Share = ok true) : Goal db now := by
  have hr := caller_role_ok _ _ _ _ _ ho
  unfold acl.role_has at h
  cases o with
  | none => simp at h
  | some ro =>
    obtain ⟨g, hg, rfl, hl⟩ := hr ro rfl
    exact ⟨g, hg, grants_share _ h, live_ok _ _ hl⟩

theorem of_cascade (db : model.Db) now s r (h : acl.cascade_grant db s r .Share now = ok true) :
    Goal db now := by
  unfold acl.cascade_grant at h
  h5i_invert h
  · obtain ⟨t, i⟩ := x_1
    exact of_grant _ _ (cascade_true _ _ _ _ _ _ h)
  · subst hc
    cases o with
    | none => simp at hfolder_allowed
    | some pf =>
      simp only at hfolder_allowed
      h5i_invert hfolder_allowed
      obtain ⟨t, i⟩ := x_1
      exact of_grant _ _ (cascade_true _ _ _ _ _ _ hfolder_allowed)
  · obtain ⟨t, i⟩ := x_1
    exact of_grant _ _ (direct_true _ _ _ _ _ _ h)

theorem share_needs_owner (db : model.Db) (ro : Bool) (now : I64) (s : model.Subject) (r : model.Resource)
    (h : acl.check db ro now s .Share r = ok true) :
    ∃ g ∈ db.grants.val, g.role = .Owner ∧ Live g now := by
  unfold acl.check at h
  h5i_invert h
  all_goals first
    | exact of_cascade _ _ _ _ h
    | (obtain ⟨t, i⟩ := ‹alloc.vec.Vec U8 × alloc.vec.Vec U64›
       exact of_grant _ _ (direct_true _ _ _ _ _ _ h))
    | (subst_vars
       exact of_role_has db now s _ _ ‹acl.caller_role_on_drive _ _ _ _ = ok _› ‹acl.role_has _ _ = ok true›)

end oxicloud_kernel.Solution
