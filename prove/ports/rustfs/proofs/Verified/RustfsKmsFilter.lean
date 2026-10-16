import SpecStatements
import Verified.RustfsValids
import Verified.RustfsCondData
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsKmsFilter
set_option maxHeartbeats 2000000
theorem clone_ok (r : rsrc.Resource) : rsrc.Resource.Insts.CoreCloneClone.clone r = ok r := by
  cases r <;> simp [rsrc.Resource.Insts.CoreCloneClone.clone,u8vec_clone]
theorem kms_ok (r : rsrc.Resource) : rsrc.is_kms r = ok (KmsTag r) := by
  cases r <;> rfl
theorem filter_ok (rs : Slice rsrc.Resource) (out : alloc.vec.Vec rsrc.Resource)
    (h : stmts.kms_only rs = ok out) : out.val=rs.val.filter KmsTag := by
  unfold stmts.kms_only stmts.kms_only_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec rsrc.Resource × Usize =>
      x.2.val ≤ rs.val.length ∧ x.1.val=(rs.val.take x.2.val).filter KmsTag)
    (fun out => out.val=rs.val.filter KmsTag) (fun x => rs.val.length-x.2.val)
    ?_ _ out (by simp) h
  rintro ⟨buf,i⟩ res ⟨hi,ha⟩ hr
  unfold stmts.kms_only_loop.body at hr
  simp only [clone_ok,kms_ok,bind_tc_ok] at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok (by assumption : rs.index_usize i = ok _)
    have hadd := add_ok_val (by assumption : i + 1#usize = ok _)
    have hp : out1.val=buf.val++(if KmsTag r1 then [r1] else []) := by
      by_cases ht : KmsTag r1 = true
      · simp only [ht,ite_true] at hout1
        simpa only [ht,ite_true] using RustfsBytes.push_ok hout1
      · simp only [ht,ite_false] at hout1
        have hh := Result.ok.inj hout1
        simp [←hh,ht]
    refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
    rw [hp,ha,show i2.val=i.val+1 by scalar_tac,List.take_add_one,
      List.getElem?_eq_getElem hlt,he,List.filter_append]
    simp only [Option.toList_some,List.filter_cons,List.filter_nil]
  · simpa only [List.take_of_length_le (by scalar_tac : rs.val.length ≤ i.val)] using ha
end rustfs_kernel.Verified.RustfsKmsFilter
