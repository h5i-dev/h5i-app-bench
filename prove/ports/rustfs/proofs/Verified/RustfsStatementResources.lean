import Verified.RustfsCleanCanonical
import Verified.RustfsConditionEval
import SpecStatements
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsForceDelete

namespace rustfs_kernel.Verified.RustfsStatementResources
set_option maxHeartbeats 2000000

theorem lit_lb1 : lit "s3:ListBucket" = [115, 51, 58, 76, 105, 115, 116, 66, 117, 99, 107, 101, 116] := by decide +kernel
theorem lit_lb2 : lit "s3:ListBucketVersions" = [115, 51, 58, 76, 105, 115, 116, 66, 117, 99, 107, 101, 116, 86, 101, 114, 115, 105, 111, 110, 115] := by decide +kernel
theorem lit_lb3 : lit "s3:ListBucketMultipartUploads" = [115, 51, 58, 76, 105, 115, 116, 66, 117, 99, 107, 101, 116, 77, 117, 108, 116, 105, 112, 97, 114, 116, 85, 112, 108, 111, 97, 100, 115] := by decide +kernel

theorem list_bucket_ok (a : acts.Action) (b : Bool)
    (h : stmts.is_list_bucket a = ok b) : b=true ↔ ListBucketAction a := by
  unfold stmts.is_list_bucket at h
  simp only [family_eq_ok] at h
  h5i_invert h
  all_goals
    try
      have l1 : nats s1.val = lit "s3:ListBucket" := by simpa [lit_lb1] using lift_slice hs1
      have e1 := bytes_eq_ok _ _ _ hb1
      simp only [deref_val] at e1
      have e1' := e1.trans (show a.name.val=s1.val ↔ nats a.name.val=nats s1.val from
        ⟨congrArg nats, nats_inj⟩)
      rw [l1] at e1'
    try
      have l2 : nats s3.val = lit "s3:ListBucketVersions" := by simpa [lit_lb2] using lift_slice hs3
      have e2 := bytes_eq_ok _ _ _ hb2
      simp only [deref_val] at e2
      have e2' := e2.trans (show a.name.val=s3.val ↔ nats a.name.val=nats s3.val from
        ⟨congrArg nats, nats_inj⟩)
      rw [l2] at e2'
    try
      have l3 : nats s5.val = lit "s3:ListBucketMultipartUploads" := by simpa [lit_lb3] using lift_slice hs5
      have e3 := bytes_eq_ok _ _ _ h
      simp only [deref_val] at e3
      have e3' := e3.trans (show a.name.val=s5.val ↔ nats a.name.val=nats s5.val from
        ⟨congrArg nats, nats_inj⟩)
      rw [l3] at e3'
    simp_all only [ListBucketAction,List.mem_cons,List.not_mem_nil,or_false,
      decide_eq_true_eq,Bool.false_eq_true,true_iff,false_iff]
    tauto
theorem build_ok (a : acts.Action) (bucket object : Slice U8) (bucketOnly : Bool)
    (out : alloc.vec.Vec U8)
    (h : stmts.build_resource a bucket object bucketOnly = ok out) :
    out.val = RequestResource a bucket.val object.val bucketOnly := by
  unfold stmts.build_resource at h
  h5i_invert h
  all_goals
    have hm := list_bucket_ok a b hb
    have hbo : bucket_only=true ↔ ListBucketAction a ∧ bucketOnly=true := by
      cases b <;> simp_all [Result.ok.injEq]
    have hr := RustfsCleanCanonical.to_vec_ok _ _ hresource
  · rw [RustfsBytes.push_ok h,hr]
    simp [RequestResource,hbo.mp hc]
  · have he : object.val=[] := by
      have hh := congrArg UScalar.val hc_1
      simpa using hh
    rw [RustfsBytes.push_ok h,hr]
    simp [RequestResource,he]
  · have hn : ¬(ListBucketAction a ∧ bucketOnly=true) := fun hh => hc (hbo.mpr hh)
    obtain ⟨hlt,hv⟩ := slice_index_ok hi1
    simp only [UScalar.ofNatCore_val_eq] at hlt hv
    have he : object.val≠[] := by intro hh; simpa [hh] using hlt
    have hh : object.val.head?=some i1 := by
      rw [List.head?_eq_getElem?,List.getElem?_eq_getElem hlt,hv]
    have hr1 : resource1.val = resource.val ++ (if i1=47#u8 then [] else [47#u8]) := by
      split at hresource1
      · have hx := Result.ok.inj hresource1; subst resource1; simp_all
      · rw [RustfsBytes.push_ok hresource1]; simp_all
    rw [RustfsConditionEval.concat_ok _ _ _ h]
    simp only [deref_val]
    rw [hr1,hr]
    simp [RequestResource,hn,he,hh]

end rustfs_kernel.Verified.RustfsStatementResources
