import Verified.Derived
import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.Spec
open H5iAppLib hiding lit


namespace oxicloud_kernel.Verified.OxicloudPersonalDrive

set_option maxHeartbeats 0

@[step] theorem find_drive_spec (db : model.Db) (id : U64) :
    grantapi.find_drive db id ⦃ result => result = driveRow db id ⦄ := by
  unfold grantapi.find_drive grantapi.find_drive_loop driveRow
  h5i_search_find db.drives.val (fun d => decide (d.id = id))

theorem personal_refused (db : model.Db) (d : U64) (dr : model.Drive)
    (hr : driveRow db d = some dr) (hk : dr.kind = .Personal) :
    grantapi.refuse_if_personal db d = ok (.Err .OperationNotSupported) := by
  unfold grantapi.refuse_if_personal
  rw [eq_ok_of_spec (find_drive_spec db d)]
  simp [hr, hk, model.DriveKind.Insts.CoreCmpPartialEqDriveKind.eq,
    model.DriveKind.read_discriminant]

theorem member_personal_refused (db db' : model.Db) (env : grantapi.Env) (caller d : U64)
    (s : model.Subject) (role : model.Role) (e : Option I64) (dr : model.Drive)
    (hr : driveRow db d = some dr) (hk : dr.kind = .Personal)
    (out : core.result.Result grantapi.Reply model.ErrorKind)
    (h : grantapi.set_member_role db env caller d s role e = ok (db', out)) :
    db' = db ∧ ∃ err, out = .Err err := by
  unfold grantapi.set_member_role at h
  obtain ⟨decision, hd, h⟩ := bind_eq_ok.1 h
  cases decision <;> simp [personal_refused db d dr hr hk] at h
  all_goals h5i_invert h
  all_goals simp_all
  all_goals exact ⟨_, h.2.symm⟩

theorem personal_drive_members_fixed (db db' : model.Db) (env : grantapi.Env) (caller d : U64)
    (s : model.Subject) (role : model.Role) (e : Option I64) (req : grantapi.Request)
    (dr : model.Drive) (hr : driveRow db d = some dr) (hk : dr.kind = .Personal)
    (hq : req = .CreateGrant (.Drive d) s role e ∨ req = .SetRole (.Drive d) s role e)
    (out : core.result.Result grantapi.Reply model.ErrorKind)
    (h : grantapi.transition db env caller req = ok (db', out)) :
    db' = db ∧ ∃ err, out = .Err err := by
  rcases hq with rfl | rfl
  · unfold grantapi.transition grantapi.create_grant at h
    h5i_invert h
    all_goals first
      | exact member_personal_refused db db' env caller d s role e dr hr hk out h
      | (simp_all; exact ⟨_, h.2.symm⟩)
  · unfold grantapi.transition grantapi.set_role_handler at h
    h5i_invert h
    all_goals first
      | exact member_personal_refused db db' env caller d s role e dr hr hk out h
      | (simp_all; exact ⟨_, h.2.symm⟩)

end oxicloud_kernel.Verified.OxicloudPersonalDrive
