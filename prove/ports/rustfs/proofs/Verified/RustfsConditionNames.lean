import Verified.RustfsConditionEval
import Verified.RustfsCleanCanonical
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsConditionEval
open rustfs_kernel.Verified.RustfsForceDelete (lift_slice deref_val)
namespace rustfs_kernel.Verified.RustfsConditionNames
 theorem op_name_ok (op : conddata.Op) (v : alloc.vec.Vec U8)
    (h : conddata.op_name op = ok v) : nats v.val = lit (OpSpelling op) := by
  cases op <;> simp only [conddata.op_name, conddata.op_name_late] at h <;> h5i_invert h
  all_goals
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok s v h, lift_slice hs]
    simp only [List.map_cons, List.map_nil, UScalar.ofNatCore_val_eq, OpSpelling]
    decide +kernel
theorem suffixed_key_ok (c : conddata.Condition) (v : alloc.vec.Vec U8)
    (h : conddata.to_key_with_suffix c = ok v) : nats v.val = ConditionKeyName c := by
  unfold conddata.to_key_with_suffix at h
  obtain ⟨base, hb, h⟩ := bind_tc_eq_ok.1 h
  have hb' := op_name_ok c.op base hb
  unfold conddata.to_key_with_suffix_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec U8 × Usize => x.2.val ≤ c.wrappers.val ∧
      nats x.1.val = lit (OpSpelling c.op) ++ (List.replicate x.2.val (lit "IfExists")).flatten)
    (fun v => nats v.val = ConditionKeyName c) (fun x => c.wrappers.val - x.2.val)
    ?_ _ v ⟨by simp, by simpa using hb'⟩ h
  rintro ⟨nm, i⟩ r ⟨hi, hn⟩ hr
  unfold conddata.to_key_with_suffix_loop.body at hr
  h5i_invert hr
  · have hcat := concat_ok _ _ _ hname1
    have hs := lift_slice hs1
    have hadd := add_ok_val hi2
    refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
    simp only [deref_val] at hcat
    rw [hcat]
    simp only [nats, List.map_append] at hn ⊢
    rw [hn, show i2.val = i.val + 1 by scalar_tac]
    have hspell : nats s1.val = lit "IfExists" := by
      rw [hs]; decide +kernel
    rw [show s1.val.map (·.val) = lit "IfExists" from hspell,
      List.replicate_add, List.flatten_append]
    simp [List.append_assoc]
  · have hi' : i.val = c.wrappers.val := by scalar_tac
    simpa [ConditionKeyName, hi'] using hn

end rustfs_kernel.Verified.RustfsConditionNames
