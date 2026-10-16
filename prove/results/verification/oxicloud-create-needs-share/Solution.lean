import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.Spec
open H5iAppLib hiding lit

namespace oxicloud_kernel.Solution

theorem create_needs_share (db db' : model.Db) (env : grantapi.Env) (caller : U64) (r : model.Resource)
    (s : model.Subject) (role : model.Role) (e : Option I64) (rep : grantapi.Reply)
    (h : grantapi.transition db env caller (.CreateGrant r s role e) = ok (db', .Ok rep)) :
    acl.check db env.migration_readonly env.now (.User caller) .Share r = ok true := by
  unfold grantapi.transition grantapi.create_grant at h
  obtain ⟨decision, hd, h⟩ := bind_eq_ok.1 h
  cases decision with
  | Ok unit =>
      unfold grantapi.require at hd
      h5i_invert hd
      all_goals simp_all
  | Err err =>
      simp only [] at h
      h5i_invert h
      all_goals simp_all

end oxicloud_kernel.Solution
