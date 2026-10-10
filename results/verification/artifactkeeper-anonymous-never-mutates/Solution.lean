import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit

namespace artifactkeeper_kernel.Solution

set_option backward.split false in
theorem anonymous_never_mutates (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (auth : Option AuthExtension) (t : Bool)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, .Next auth t))
    (hm : isMutation req.method) :
    auth.isSome ∧ t = false := by
  have hpost : Method.Insts.CoreCmpPartialEqMethod.eq req.method .Post = ok false := by
    rcases hm with hm | hm | hm <;>
      simp [hm, Method.Insts.CoreCmpPartialEqMethod.eq, Method.read_discriminant]
  have hwrite : paths.is_write_method req.method = ok true := by
    rcases hm with hm | hm | hm <;> simp [hm, paths.is_write_method]
  unfold middleware.repo_visibility_middleware at h
  simp only [hpost, hwrite, middleware.respond] at h
  -- Unfold tuple bindings and keep only paths that reach the next layer.
  all_goals repeat' (fail_if_no_progress (
    h5i_invert h
    all_goals try simp only [uncurry, and_false, not_false_eq_true, decide_true] at h))
  all_goals simp_all [core.option.Option.is_some, core.option.Option.is_none]
  all_goals simp only [← h.2.1, Option.isSome_some]

end artifactkeeper_kernel.Solution
