import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit

namespace artifactkeeper_kernel.Verified.ArtifactkeeperOnlyAdminRules

lemma duplicate_admin (a b : AuthExtension) (h : AuthExtension.duplicate a = ok b) :
    b.is_admin = a.is_admin := by
  unfold AuthExtension.duplicate at h
  h5i_invert h
  all_goals simp_all

lemma require_auth_admin (auth : Option AuthExtension) (a : AuthExtension)
    (h : handlers.require_auth auth = ok (.Ok a)) :
    ∃ e, auth = some e ∧ a.is_admin = e.is_admin := by
  unfold handlers.require_auth at h
  h5i_invert h
  exact ⟨_, rfl, duplicate_admin _ _ (by assumption)⟩

lemma require_admin_true (a : AuthExtension)
    (h : token_scope.AuthExtension.require_admin a = ok (.Ok ())) :
    a.is_admin = true := by
  unfold token_scope.AuthExtension.require_admin at h
  h5i_invert h
  all_goals assumption

lemma gates_admin (db : tables.Db) (o : trusted.Oracle) (auth : Option AuthExtension)
    (p : handlers.CreatePermissionRequest)
    (h : handlers.create_permission_gates db o auth p = ok (.Ok ())) :
    ∃ e, auth = some e ∧ e.is_admin = true := by
  unfold handlers.create_permission_gates at h
  h5i_invert h
  all_goals
    obtain ⟨e, he, ha⟩ := require_auth_admin _ _ (by assumption)
    refine ⟨e, he, ?_⟩
    rw [← ha]
    exact require_admin_true _ (by assumption)

theorem only_admin_creates_rules (db : tables.Db) (o : trusted.Oracle) (auth : Option AuthExtension)
    (p : handlers.CreatePermissionRequest) (ws : alloc.vec.Vec resolve.Write) (r : core.result.Result Unit AppError)
    (h : handlers.create_permission db o auth p = ok (ws, r)) (hw : ws.val ≠ []) :
    ∃ e, auth = some e ∧ e.is_admin = true := by
  unfold handlers.create_permission at h
  obtain ⟨decision, hd, h⟩ := bind_eq_ok.1 h
  cases decision with
  | Ok value =>
      cases value
      exact gates_admin _ _ _ _ hd
  | Err err =>
      simp only [ok.injEq, Prod.mk.injEq] at h
      rcases h with ⟨hws, _⟩
      subst ws
      exact False.elim (hw (by simp))

end artifactkeeper_kernel.Verified.ArtifactkeeperOnlyAdminRules
