import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.Spec
open H5iAppLib hiding lit

h5i_derive_all

namespace oxicloud_kernel.Solution

macro "inv " h:ident : tactic => `(tactic| (
  repeat' (first
    | (simp only [H5iAppLib.bind_tc_eq_ok, H5iAppLib.bind_eq_ok, ok.injEq,
        core.result.Result.Ok.injEq, core.result.Result.Err.injEq,
        Prod.mk.injEq, reduceCtorEq, false_and, and_false, exists_false,
        exists_and_left, exists_and_right, exists_eq_left, exists_eq_right,
        Aeneas.Std.uncurry] at $h:ident)
    | (obtain ⟨(⟨_, _⟩ : _ × _), _, $h:ident⟩ := $h)
    | (obtain ⟨_, _, $h:ident⟩ := $h)
    | (split at $h:ident))))

theorem member_refused (db db' : model.Db) (env : grantapi.Env) (caller drive : U64)
    (s : model.Subject) (role : model.Role) (e : Option I64) (err : model.ErrorKind)
    (h : grantapi.set_member_role db env caller drive s role e = ok (db', .Err err)) :
    db' = db := by
  unfold grantapi.set_member_role at h
  obtain ⟨r, hr, h⟩ := bind_eq_ok.1 h
  obtain ⟨gates, hg, h⟩ := bind_eq_ok.1 h
  cases gates <;> inv h <;> simp_all

theorem refused_create_or_set_writes_nothing (db db' : model.Db) (env : grantapi.Env) (caller : U64)
    (r : model.Resource) (s : model.Subject) (role : model.Role) (e : Option I64) (req : grantapi.Request)
    (err : model.ErrorKind) (hq : req = .CreateGrant r s role e ∨ req = .SetRole r s role e)
    (h : grantapi.transition db env caller req = ok (db', .Err err)) :
    db' = db := by
  rcases hq with rfl | rfl
  · unfold grantapi.transition grantapi.create_grant at h
    inv h
    all_goals first | (simp_all; done) | exact member_refused _ _ _ _ _ _ _ _ _ h
  · unfold grantapi.transition grantapi.set_role_handler at h
    inv h
    all_goals first | (simp_all; done) | exact member_refused _ _ _ _ _ _ _ _ _ h

end oxicloud_kernel.Solution
