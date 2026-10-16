import Verified.RustfsVariableIdentity
import Verified.RustfsVariablePrincipal
import Verified.RustfsVariableCustom
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsVariableResolve
theorem equal_nats (s p : Slice U8) (b : Bool) (h : bytes.eq s p = ok b) :
    (b = true ↔ nats s.val = nats p.val) := by
  rw [rustfs_kernel.Verified.RustfsForceDelete.bytes_eq_ok _ _ _ h]
  exact ⟨congrArg nats,rustfs_kernel.Verified.RustfsForceDelete.nats_inj⟩
 theorem resolve_ok (r : varctx.VariableResolver) (needle : Slice U8) (env : condfuncs.Env)
    (out : Option (alloc.vec.Vec U8)) (h : varctx.resolve r needle env = ok out) :
    out.map (fun v => nats v.val) = VariableResolution r needle.val env := by
  unfold varctx.resolve at h
  h5i_invert h
  all_goals
    try
      have hname0 : b = true ↔ nats needle.val = lit "aws:username" := by
        have he := equal_nats _ _ _ hb
        have hl : nats s.val = lit "aws:username" := by
          rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs]
          decide +kernel
        simpa only [hl] using he
    try
      have hname1 : b1 = true ↔ nats needle.val = lit "aws:userid" := by
        have he := equal_nats _ _ _ hb1
        have hl : nats s1.val = lit "aws:userid" := by
          rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs1]
          decide +kernel
        simpa only [hl] using he
    try
      have hname2 : b2 = true ↔ nats needle.val = lit "aws:PrincipalType" := by
        have he := equal_nats _ _ _ hb2
        have hl : nats s2.val = lit "aws:PrincipalType" := by
          rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs2]
          decide +kernel
        simpa only [hl] using he
    try
      have hname3 : b3 = true ↔ nats needle.val = lit "aws:SecureTransport" := by
        have he := equal_nats _ _ _ hb3
        have hl : nats s3.val = lit "aws:SecureTransport" := by
          rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs3]
          decide +kernel
        simpa only [hl] using he
    try
      have hname4 : b4 = true ↔ nats needle.val = lit "aws:CurrentTime" := by
        have he := equal_nats _ _ _ hb4
        have hl : nats s4.val = lit "aws:CurrentTime" := by
          rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs4]
          decide +kernel
        simpa only [hl] using he
    try
      have hname5 : b5 = true ↔ nats needle.val = lit "aws:EpochTime" := by
        have he := equal_nats _ _ _ hb5
        have hl : nats s5.val = lit "aws:EpochTime" := by
          rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs5]
          decide +kernel
        simpa only [hl] using he
    try
      have hname6 : b6 = true ↔ nats needle.val = lit "aws:AccountId" := by
        have he := equal_nats _ _ _ hb6
        have hl : nats s6.val = lit "aws:AccountId" := by
          rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs6]
          decide +kernel
        simpa only [hl] using he
    try
      have hname7 : b7 = true ↔ nats needle.val = lit "aws:Region" := by
        have he := equal_nats _ _ _ hb7
        have hl : nats s7.val = lit "aws:Region" := by
          rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs7]
          decide +kernel
        simpa only [hl] using he
    try
      have hname8 : b8 = true ↔ nats needle.val = lit "aws:SourceIp" := by
        have he := equal_nats _ _ _ hb8
        have hl : nats s8.val = lit "aws:SourceIp" := by
          rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs8]
          decide +kernel
        simpa only [hl] using he
    simp_all [VariableResolution,u8vec_clone]
  all_goals first
    | exact congrArg (Option.map (fun v => nats v.val)) (Verified.RustfsVariableScalars.username_ok _ _ h)
    | exact Verified.RustfsVariableIdentity.userid_ok _ _ h
    | exact Verified.RustfsVariablePrincipal.principal_ok _ _ hv
    | exact Verified.RustfsVariableScalars.secure_ok _ _ hv
    | exact congrArg (Option.map (fun v => nats v.val)) (Verified.RustfsVariableScalars.account_ok _ _ h)
    | exact congrArg (Option.map (fun v => nats v.val)) (Verified.RustfsVariableScalars.region_ok _ _ h)
    | exact congrArg (Option.map (fun v => nats v.val)) (Verified.RustfsVariableScalars.source_ok _ _ h)
    | exact congrArg (Option.map (fun v => nats v.val)) (Verified.RustfsVariableCustom.custom_ok _ _ _ h)
end rustfs_kernel.Verified.RustfsVariableResolve
namespace rustfs_kernel.Verified.RustfsVariableResolve
 theorem multiple_ok (r : varctx.VariableResolver) (needle : Slice U8) (env : condfuncs.Env)
    (out : Option (alloc.vec.Vec (alloc.vec.Vec U8)))
    (h : varctx.resolve_multiple r needle env = ok out) :
    out.map (fun vs => vs.val.map (fun v => nats v.val)) = VariableMultiple r needle.val env := by
  unfold varctx.resolve_multiple at h
  h5i_invert h
  all_goals
    have hn0 : b = true ↔ nats needle.val = lit "aws:username" := by
      have he := equal_nats _ _ _ hb
      have hl : nats s.val = lit "aws:username" := by
        rw [Verified.RustfsForceDelete.lift_slice hs]
        decide +kernel
      simpa only [hl] using he
    try
      have hn1 : b1 = true ↔ nats needle.val = lit "aws:userid" := by
        have he := equal_nats _ _ _ hb1
        have hl : nats s1.val = lit "aws:userid" := by
          rw [Verified.RustfsForceDelete.lift_slice hs1]
          decide +kernel
        simpa only [hl] using he
    try have hu := Verified.RustfsVariableScalars.username_ok _ _ ho
    try have hr := resolve_ok _ _ _ _ ho
    try have hp := Verified.RustfsBytes.push_ok h__v
    try
      have hsub := Verified.RustfsVariableScalars.claim_strings_ok _ _ _ ho
      have hl : nats s2.val = lit "sub" := by
        rw [Verified.RustfsForceDelete.lift_slice hs2]
        decide +kernel
      rw [hl] at hsub
    try
      have hparent := Verified.RustfsVariableScalars.claim_strings_ok _ _ _ h
      have hl : nats s3.val = lit "parent" := by
        rw [Verified.RustfsForceDelete.lift_slice hs3]
        decide +kernel
      rw [hl] at hparent
    have hdiff : lit "aws:username" ≠ lit "aws:userid" := by decide +kernel
    simp_all [VariableMultiple,VariableResolution]
  all_goals first
    | exact ⟨p,hu.symm,rfl⟩
    | rw [← hsub];rfl

end rustfs_kernel.Verified.RustfsVariableResolve
