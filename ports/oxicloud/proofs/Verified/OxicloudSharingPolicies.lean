import Verified.Derived
import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.Spec
open H5iAppLib hiding lit

namespace oxicloud_kernel.Verified.OxicloudSharingPolicies


@[step] theorem find_folder_spec (db : model.Db) (id : U64) :
    acl.find_folder db id ⦃ result => result = db.folders.val.find? (·.id = id) ⦄ := by
  unfold acl.find_folder acl.find_folder_loop
  h5i_search_find db.folders.val (fun f => decide (f.id = id))

@[step] theorem find_file_spec (db : model.Db) (id : U64) :
    acl.find_file db id ⦃ result => result = db.files.val.find? (·.id = id) ⦄ := by
  unfold acl.find_file acl.find_file_loop
  h5i_search_find db.files.val (fun f => decide (f.id = id))

def default_policies : model.DrivePolicies := ⟨false, false, false, false, false⟩

@[step] theorem drive_policies_spec (db : model.Db) (id : U64) :
    acl.drive_policies db id ⦃ result =>
      result = ((driveRow db id).map (·.policies)).getD default_policies ⦄ := by
  unfold acl.drive_policies acl.drive_policies_loop
  apply WP.spec_mono (loop_search db.drives.val (fun d => decide (d.id = id))
    _root_.id (fun _ d => d.policies) default_policies _ ?_ 0#usize (by simp))
  · intro result hr
    simpa [driveRow, searchFrom_findD] using hr
  · intro i hi
    unfold acl.drive_policies_loop.body
    h5i_step [default_policies]

theorem drive_of_eq (db : model.Db) (r : model.Resource)
    (hs : isStorage r = true) : acl.drive_of db r = ok (driveOf db r) := by
  apply eq_ok_of_spec
  cases r <;> simp [isStorage] at hs
  all_goals
    unfold acl.drive_of driveOf
    step* <;> simp_all
  all_goals exact ⟨_, o_post.symm, rfl⟩

set_option maxHeartbeats 0

theorem policies_for_storage (db : model.Db) (r : model.Resource) (d : U64)
    (dr : model.Drive) (hs : isStorage r = true) (hd : driveOf db r = some d)
    (hr : driveRow db d = some dr) :
    grantapi.policies_for db r = ok (.Ok dr.policies) := by
  have hdo := drive_of_eq db r hs
  have hdp : acl.drive_policies db d = ok dr.policies := by
    simpa [hr] using eq_ok_of_spec (drive_policies_spec db d)
  cases r <;> simp [isStorage] at hs
  all_goals unfold grantapi.policies_for
  all_goals simp [hdo, hd, hdp]

theorem create_respects_sharing_policies (db db' : model.Db) (env : grantapi.Env) (caller : U64)
    (r : model.Resource) (s : model.Subject) (role : model.Role) (e : Option I64) (rep : grantapi.Reply)
    (d : U64) (dr : model.Drive) (hst : isStorage r = true) (hd : driveOf db r = some d)
    (hr : driveRow db d = some dr)
    (h : grantapi.transition db env caller (.CreateGrant r s role e) = ok (db', .Ok rep)) :
    dr.policies.forbid_sharing = false ∧ (∀ t, s = .Token t → dr.policies.forbid_public_links = false) := by
  unfold grantapi.transition grantapi.create_grant at h
  obtain ⟨decision, hdecision, h⟩ := bind_eq_ok.1 h
  cases decision with
  | Err err =>
    h5i_invert h
    all_goals simp_all
  | Ok unit =>
    obtain ⟨gate, hgate, h⟩ := bind_eq_ok.1 h
    cases gate with
    | Err err =>
      h5i_invert h
      all_goals simp_all
    | Ok unit =>
      unfold grantapi.create_gates at hgate
      rw [policies_for_storage db r d dr hst hd hr] at hgate
      cases r <;> simp [isStorage] at hst
      all_goals
        simp [grantapi.is_drive, core.result.Result.Insts.CoreOpsTry.branch] at hgate
        h5i_invert hgate
        all_goals simp_all
      all_goals
        intro t hs
        subst s
        simp at htoken

end oxicloud_kernel.Verified.OxicloudSharingPolicies

