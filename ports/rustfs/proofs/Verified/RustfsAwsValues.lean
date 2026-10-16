import SpecAwsValues
import Verified.RustfsConditionCopies
import Verified.RustfsVariableResolve
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified
namespace rustfs_kernel.Verified.RustfsAwsValues
set_option maxHeartbeats 2000000
theorem clone_list_ok (v : Slice (alloc.vec.Vec U8)) (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : awsvars.clone_list v = ok out) : out.val = v.val := by
  unfold awsvars.clone_list awsvars.clone_list_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec (alloc.vec.Vec U8) × Usize =>
      x.2.val ≤ v.val.length ∧ x.1.val = v.val.take x.2.val)
    (fun out => out.val = v.val) (fun x => v.val.length-x.2.val)
    ?_ _ out ⟨by simp,by simp⟩ h
  rintro ⟨acc,i⟩ r ⟨hi,ha⟩ hr
  unfold awsvars.clone_list_loop.body at hr
  simp only [u8vec_clone,bind_tc_ok] at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok hv2
    have hp := RustfsBytes.push_ok hout1
    have hadd := add_ok_val hi2
    refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
    rw [hp,ha,show i2.val=i.val+1 by scalar_tac,List.take_add_one,
      List.getElem?_eq_getElem hlt]
    simp only [← he,List.append_assoc]
    rfl
  · rw [List.take_of_length_le (by scalar_tac)] at ha
    exact ha
theorem userid_ok (c : awsvars.ClaimStrings)
    (o : Option (alloc.vec.Vec (alloc.vec.Vec U8)))
    (h : awsvars.userid_strings c = ok o) : o = c.sub.orElse (fun _ => c.parent) := by
  unfold awsvars.userid_strings at h
  h5i_invert h
  · simp_all
  all_goals
    have he := clone_list_ok _ _ hv1
    have hv : v1 = l := by apply alloc.vec.Vec.ext; simpa only [RustfsForceDelete.deref_val] using he
    subst v1
    simp_all

def context (c : awsvars.VarContext) : AwsValueContext :=
  ⟨nats c.username.val,nats c.account.val,
    c.claims.sub.map (fun v => v.val.map (fun s => nats s.val)),
    c.claims.parent.map (fun v => v.val.map (fun s => nats s.val)),
    c.claims.has_parent,c.claims.has_role_arn,c.claims.has_sa_policy,
    nats c.now_rfc3339.val,nats c.now_epoch.val⟩

theorem ids_context (c : awsvars.VarContext) : AwsUserIds (context c) =
    (c.claims.sub.orElse (fun _ => c.claims.parent)).map (fun v => v.val.map (fun s => nats s.val)) := by
  cases hs : c.claims.sub <;> simp [AwsUserIds,context,hs]

theorem resolve_ok (c : awsvars.VarContext) (needle : Slice U8)
    (out : Option (alloc.vec.Vec U8)) (h : awsvars.resolve c needle = ok out) :
    out.map (fun v => nats v.val) = AwsValue (context c) (nats needle.val) := by
  unfold awsvars.resolve at h
  simp only [u8vec_clone,bind_tc_ok] at h
  h5i_invert h
  all_goals
    try
      have hname0 : b = true ↔ nats needle.val = lit "aws:username" := by
        have he := RustfsVariableResolve.equal_nats _ _ _ hb
        have hl : nats s.val = lit "aws:username" := by
          rw [RustfsForceDelete.lift_slice hs]
          decide +kernel
        simpa only [hl] using he
    try
      have hname1 : b1 = true ↔ nats needle.val = lit "aws:userid" := by
        have he := RustfsVariableResolve.equal_nats _ _ _ hb1
        have hl : nats s1.val = lit "aws:userid" := by
          rw [RustfsForceDelete.lift_slice hs1]
          decide +kernel
        simpa only [hl] using he
    try
      have hname2 : b2 = true ↔ nats needle.val = lit "aws:PrincipalType" := by
        have he := RustfsVariableResolve.equal_nats _ _ _ hb2
        have hl : nats s2.val = lit "aws:PrincipalType" := by
          rw [RustfsForceDelete.lift_slice hs2]
          decide +kernel
        simpa only [hl] using he
    try
      have hname3 : b3 = true ↔ nats needle.val = lit "aws:SecureTransport" := by
        have he := RustfsVariableResolve.equal_nats _ _ _ hb3
        have hl : nats s3.val = lit "aws:SecureTransport" := by
          rw [RustfsForceDelete.lift_slice hs3]
          decide +kernel
        simpa only [hl] using he
    try
      have hname4 : b4 = true ↔ nats needle.val = lit "aws:CurrentTime" := by
        have he := RustfsVariableResolve.equal_nats _ _ _ hb4
        have hl : nats s4.val = lit "aws:CurrentTime" := by
          rw [RustfsForceDelete.lift_slice hs4]
          decide +kernel
        simpa only [hl] using he
    try
      have hname5 : b5 = true ↔ nats needle.val = lit "aws:EpochTime" := by
        have he := RustfsVariableResolve.equal_nats _ _ _ hb5
        have hl : nats s5.val = lit "aws:EpochTime" := by
          rw [RustfsForceDelete.lift_slice hs5]
          decide +kernel
        simpa only [hl] using he
    try
      have hname6 : b6 = true ↔ nats needle.val = lit "aws:AccountId" := by
        have he := RustfsVariableResolve.equal_nats _ _ _ hb6
        have hl : nats s6.val = lit "aws:AccountId" := by
          rw [RustfsForceDelete.lift_slice hs6]
          decide +kernel
        simpa only [hl] using he
  all_goals
    try have hu := userid_ok _ _ ho
    try
      have ht := ids_context c
      rw [← hu] at ht
    try simp_all [AwsValue,context]
    try
      rw [RustfsCleanCanonical.to_vec_ok _ _ hv]
      rw [RustfsForceDelete.lift_slice hs3]
      simp_all only [AwsPrincipalType,↓reduceIte,Bool.false_and,Bool.true_and]
      decide +kernel
    try simp_all only [ht,Option.map_none,Option.map_some,Option.bind_none,Option.bind_some]
  all_goals
    try simp only [← hu,Option.map_none,Option.map_some,Option.bind_none,Option.bind_some]
    try simp_all only [List.map_nil,List.getLast?_nil]
    try
      have hempty : l.val=[] := List.eq_nil_iff_length_eq_zero.mpr (by scalar_tac)
      simp only [hempty,List.map_nil,List.getLast?_nil]
    try
      rw [RustfsCleanCanonical.to_vec_ok _ _ hv,RustfsForceDelete.lift_slice hs3_1]
      decide +kernel
    try
      have hb := sub_ok_val hi2
      obtain ⟨hlt,he⟩ := vec_index_ok hv_1
      have hh : i2.val = l.val.length-1 := by scalar_tac
      rw [List.getLast?_map,List.getLast?_eq_getElem?,← hh,List.getElem?_eq_getElem hlt,he]
      rfl
theorem multiple_ok (c : awsvars.VarContext) (needle : Slice U8)
    (out : Option (alloc.vec.Vec (alloc.vec.Vec U8)))
    (h : awsvars.resolve_multiple c needle = ok out) :
    out.map (fun v => v.val.map (fun s => nats s.val)) = AwsValues (context c) (nats needle.val) := by
  unfold awsvars.resolve_multiple at h
  simp only [u8vec_clone,bind_tc_ok] at h
  h5i_invert h
  all_goals
    try
      have hn0 : b = true ↔ nats needle.val = lit "aws:username" := by
        have he := RustfsVariableResolve.equal_nats _ _ _ hb
        have hl : nats s.val = lit "aws:username" := by
          rw [RustfsForceDelete.lift_slice hs]
          decide +kernel
        simpa only [hl] using he
    try
      have hn1 : b1 = true ↔ nats needle.val = lit "aws:userid" := by
        have he := RustfsVariableResolve.equal_nats _ _ _ hb1
        have hl : nats s1.val = lit "aws:userid" := by
          rw [RustfsForceDelete.lift_slice hs1]
          decide +kernel
        simpa only [hl] using he
    try have hr := resolve_ok _ _ _ ho
    try have hu := userid_ok _ _ h
    try have hp := RustfsBytes.push_ok hv1
    try have hp := RustfsBytes.push_ok hv
    have hd : lit "aws:username" ≠ lit "aws:userid" := by decide +kernel
  case isTrue =>
    have he := hn0.mp hc
    simp [AwsValues,AwsValue,he,hp,context,hd]
  case isFalse.isTrue =>
    have he := hn1.mp hc_1
    simp only [AwsValues,he,ite_true]
    rw [hu,ids_context]
  case h_1 =>
    have he : nats needle.val ≠ lit "aws:userid" := fun he => hc_1 (hn1.mpr he)
    simp only [AwsValues,if_neg he,← hr,Option.map_none]
  case h_2 =>
    have he : nats needle.val ≠ lit "aws:userid" := fun he => hc_1 (hn1.mpr he)
    simp [AwsValues,he,← hr,hp]
end rustfs_kernel.Verified.RustfsAwsValues
