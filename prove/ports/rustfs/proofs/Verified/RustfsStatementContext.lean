import SpecStatementContext
import Verified.RustfsAwsValues
import Verified.RustfsAwsResolution
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsStatementContext
open RustfsForceDelete
lemma opt_clone (v out : Option (alloc.vec.Vec (alloc.vec.Vec U8)))
    (h : awsvars.clone_opt_list v=ok out) : out=v := by
  unfold awsvars.clone_opt_list at h
  h5i_invert h
  · rfl
  · have hh := RustfsAwsValues.clone_list_ok _ _ hv1
    have he : v1=l := by apply alloc.vec.Vec.ext; simpa only [deref_val] using hh
    simp_all
lemma claims_clone (c out : awsvars.ClaimStrings)
    (h : awsvars.ClaimStrings.Insts.CoreCloneClone.clone c=ok out) : out=c := by
  unfold awsvars.ClaimStrings.Insts.CoreCloneClone.clone at h
  simp only [u8vec_clone,bind_ok] at h
  h5i_invert h
  all_goals have hs := opt_clone _ _ ho
  all_goals have hp := opt_clone _ _ ho1
  all_goals cases c <;> simp_all
 theorem resolver_ok (args : stmts.Args) (env : condfuncs.Env) (out : awsvars.VarContext)
    (h : stmts.resolver_for args env=ok out) : RustfsAwsValues.context out=PolicyContext args env := by
  unfold stmts.resolver_for at h
  simp only [u8vec_clone,bind_ok] at h
  h5i_invert h
  have hc := claims_clone _ _ hcs
  have hu : username=args.claims.parent_str.getD args.account := by
    cases he : args.claims.parent_str <;> simp_all only [he,Option.getD_none,Option.getD_some,Result.ok.injEq]
  simp_all [RustfsAwsValues.context,PolicyContext]
end rustfs_kernel.Verified.RustfsStatementContext
