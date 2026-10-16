import Verified.RustfsAwsSinglePass
import Verified.RustfsAwsPasses
import Verified.RustfsAwsResolution
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsAwsResolution
set_option maxHeartbeats 2000000
theorem depth_ok (ctx : awsvars.VarContext) (text : Slice U8) (depth : Usize)
    (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : awsvars.resolve_aws_variables_with_depth ctx text depth=ok out) :
    out.val.map (fun v => nats v.val)=ExpandVariables (RustfsAwsValues.context ctx) depth.val (nats text.val) := by
  induction hn : 10-depth.val using Nat.strong_induction_on generalizing depth text out with
  | _ n ih =>
    by_cases hd : 10≤depth.val
    · exact depth_cap_ok ctx text depth out hd h
    · have hlt : depth.val<10 := by omega
      let inner := ExpandVariables (RustfsAwsValues.context ctx) (depth.val+1)
      have hs : ∀ (text : Slice U8) (d : Usize) (out : alloc.vec.Vec (alloc.vec.Vec U8)),
          d.val=depth.val+1 → awsvars.resolve_aws_variables_with_depth ctx text d=ok out →
            out.val.map (fun v => nats v.val)=inner (nats text.val) := by
        intro txt d result he hr
        have hh := ih (10-d.val) (by omega) txt d result hr rfl
        simpa only [he] using hh
      rw [awsvars.resolve_aws_variables_with_depth] at h
      have hcap : ¬depth≥10#usize := by scalar_tac
      simp only [hcap,↓reduceIte] at h
      obtain ⟨copied,hcopied,h⟩ := bind_tc_eq_ok.mp h
      have ht := RustfsCleanCanonical.to_vec_ok text copied hcopied
      obtain ⟨pending,hpending,h⟩ := bind_tc_eq_ok.mp h
      have hp := RustfsBytes.push_ok hpending
      change pending.val=[copied] at hp
      have hh := RustfsAwsPasses.fixpoint_ok ctx depth
        (ExpansionPass inner (RustfsAwsValues.context ctx))
        (fun txt => expansion_pass_nonempty inner (RustfsAwsValues.context ctx) txt)
        (fun txt result hr => RustfsAwsPassMeaning.single_pass_ok ctx depth inner hs txt result hr)
        pending 0#usize out h
      simpa [RustfsAwsPasses.texts,hp,ht,ExpandVariables,hd,inner] using hh
end rustfs_kernel.Verified.RustfsAwsResolution
