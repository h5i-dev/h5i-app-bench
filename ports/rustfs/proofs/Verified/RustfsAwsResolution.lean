import Verified.RustfsAwsCollections
import SpecAwsResolution
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsAwsResolution
set_option maxHeartbeats 1000000
theorem depth_cap_ok (ctx : awsvars.VarContext) (text : Slice U8) (depth : Usize)
    (out : alloc.vec.Vec (alloc.vec.Vec U8)) (hd : 10 ≤ depth.val)
    (h : awsvars.resolve_aws_variables_with_depth ctx text depth = ok out) :
    out.val.map (fun v => nats v.val) = ExpandVariables (RustfsAwsValues.context ctx) depth.val (nats text.val) := by
  rw [awsvars.resolve_aws_variables_with_depth] at h
  h5i_invert h
  · have hp := RustfsBytes.push_ok h
    simp only [alloc.vec.Vec.new, alloc.vec.Vec.val] at hp
    have ht : alloc.slice.Slice.to_vec core.clone.CloneU8 text ⦃ fun v => v.val=text.val ⦄ := by
      step*
      simp_all [alloc.vec.Vec.val]
    have hc := post_of_ok ht hv
    change out.val = [v] at hp
    rw [hp]
    simp only [List.map_append,List.map_cons,List.map_nil]
    simp [ExpandVariables,hd,hc]
  · exfalso; apply hc; scalar_tac
end rustfs_kernel.Verified.RustfsAwsResolution
