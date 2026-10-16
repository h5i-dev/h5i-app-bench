import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit

namespace artifactkeeper_kernel.Solution

lemma csrf_guard_not_admin_required (req : http.Request)
    (h : middleware.csrf_guard req = ok (some middleware.Response.AdminRequired)) : False := by
  unfold middleware.csrf_guard at h
  simp only [H5iAppLib.bind_tc_eq_ok] at h
  rcases h with ⟨b, _, hb⟩
  split at hb <;> simp at hb

lemma push_new_val {α : Type} (x : α) (w : alloc.vec.Vec α)
    (h : (alloc.vec.Vec.new α).push x = ok w) :
    w.val = [x] := by
  have hlen : (alloc.vec.Vec.new α).val.length < Usize.max := by
    simp; scalar_tac
  have hp := post_of_ok (alloc.vec.Vec.push_spec (alloc.vec.Vec.new α) x hlen) h
  simpa using hp

theorem admin_denial_audited (db : tables.Db) (o : trusted.Oracle) (req : http.Request)
    (ws : alloc.vec.Vec resolve.Write)
    (h : middleware.admin_middleware db o req = ok (ws, .Respond .AdminRequired)) :
    ∃ u, ws.val = [resolve.Write.AuditPermissionDenied u req.path req.method] := by
  unfold middleware.admin_middleware middleware.respond at h
  h5i_invert h
  all_goals first
    | (simp only [Prod.mk.injEq, middleware.Outcome.Respond.injEq,
         reduceCtorEq, and_false] at h; done)
    | (simp only [u8vec_clone, ok.injEq] at *
       subst_vars
       rcases h with ⟨rfl, _⟩
       have hw := push_new_val _ _ (by assumption)
       exact ⟨_, hw⟩)
    | (have heq : refusal = middleware.Response.AdminRequired :=
         middleware.Outcome.Respond.inj h.2
       exact False.elim (csrf_guard_not_admin_required req (by simpa [heq] using ho_1)))

end artifactkeeper_kernel.Solution
