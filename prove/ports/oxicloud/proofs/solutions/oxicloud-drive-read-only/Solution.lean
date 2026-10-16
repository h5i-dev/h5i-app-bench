import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.Spec
open H5iAppLib hiding lit

namespace oxicloud_kernel.Solution

h5i_derive_clone model.Folder model.Folder.Insts.CoreCloneClone.clone

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

theorem gate_true (p : model.Permission) (hp : p ≠ .Read) :
    acl.read_only_gate_applies p = ok true := by
  cases p <;> simp_all [acl.read_only_gate_applies,
    core.cmp.PartialEq.ne.trait_default, core.cmp.PartialEq.ne.default,
    model.Permission.Insts.CoreCmpPartialEqPermission.eq,
    model.Permission.read_discriminant]

theorem drive_read_only_blocks_mutations (db : model.Db) (ro : Bool) (now : I64) (s : model.Subject)
    (p : model.Permission) (r : model.Resource) (d : U64) (dr : model.Drive) (hp : p ≠ .Read)
    (hd : driveOf db r = some d) (hr : driveRow db d = some dr) (hro : dr.policies.read_only = true) :
    acl.check db ro now s p r ≠ ok true := by
  have hg := gate_true p hp
  have hdp : acl.drive_policies db d = ok dr.policies := by
    simpa [hr] using eq_ok_of_spec (drive_policies_spec db d)
  have hd_original := hd
  cases r <;> simp [driveOf] at hd
  all_goals
    unfold acl.check
    simp only [hg, bind_tc_ok]
    cases ro <;> simp only [Bool.false_eq_true, ite_true, ite_false, bind_tc_ok]
  all_goals first
    | (simp [hdp, hro, hd]; done)
    | (rw [drive_of_eq db _ (by rfl), hd_original]; simp [hdp, hro])

end oxicloud_kernel.Solution
