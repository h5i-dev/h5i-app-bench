import Verified.OxicloudUserRole
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.SpecKernel
open H5iAppLib hiding lit
open oxicloud_kernel.Verified.OxicloudBytes
namespace oxicloud_kernel.Verified.OxicloudAdmin

theorem visibility_bytes_ok (value : admin.AuthzDenialVisibility) (out : alloc.vec.Vec U8)
    (h : admin.visibility_bytes value = ok out) : out.val = AdminVisibilityWire value := by
  cases value <;> unfold admin.visibility_bytes at h <;> h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at hs
  all_goals subst s
  all_goals have hc := copy_ok _ _ h
  all_goals simpa [AdminVisibilityWire, Array.to_slice, Array.make] using hc

theorem denial_bytes_ok (value : admin.AdminDenial) (out : alloc.vec.Vec U8)
    (h : admin.denial_bytes value = ok out) : out.val = AdminDenialWire value := by
  cases value <;> unfold admin.denial_bytes at h <;> h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at hs
  all_goals subst s
  all_goals have hc := copy_ok _ _ h
  all_goals simpa [AdminDenialWire, Array.to_slice, Array.make] using hc

theorem reason_decision_ok (subject : admin.Principal) (role : userrole.UserRole)
    (is_external active : Bool) (r : Option admin.AdminDenial)
    (h : admin.system_admin_denial_reason subject role is_external active = ok r) :
    (r = none ↔ SystemAdminAllowed subject role is_external active) ∧
    (∀ reason, r = some reason → SystemAdminDenial subject role is_external active reason) := by
  cases subject <;> cases role <;> cases is_external <;> cases active <;>
    simp_all [admin.system_admin_denial_reason, userrole.at_least, userrole.rank,
      SystemAdminAllowed, SystemAdminDenial, RoleLevel]
  all_goals subst_vars
  all_goals simp_all [SystemAdminDenial]

theorem required_admin_ok (subject : admin.Principal) (role : userrole.UserRole)
    (is_external active : Bool) (r : admin.AdminDecision)
    (h : admin.require_system_admin subject role is_external active = ok r) :
    (r = .Allowed ↔ SystemAdminAllowed subject role is_external active) ∧
    (∀ reason, r = .Denied reason → SystemAdminDenial subject role is_external active reason) := by
  unfold admin.require_system_admin at h
  h5i_invert h
  all_goals have hr := reason_decision_ok subject role is_external active _ ho
  all_goals simp_all

end oxicloud_kernel.Verified.OxicloudAdmin
