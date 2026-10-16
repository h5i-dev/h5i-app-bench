import Verified.RustfsVariableScalars
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsVariableScalars
namespace rustfs_kernel.Verified.RustfsVariablePrincipal
 theorem find_presence (table : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value))
    (needle : Slice U8) (o : Option Usize) (h : claims.find table needle = ok o) :
    (o.isSome = true ↔ ∃ e ∈ table.val, nats e.1.val = nats needle.val) := by
  have hf := rustfs_kernel.Verified.RustfsClaimLookup.find_ok table needle o h
  cases o with
  | none =>
    change ∀ e ∈ table.val, e.1.val ≠ needle.val at hf
    simp only [Option.isSome_none,Bool.false_eq_true,false_iff,not_exists,not_and]
    intro e he hn
    exact hf e he (rustfs_kernel.Verified.RustfsForceDelete.nats_inj hn)
  | some i =>
    change FirstNamedClaim table.val needle.val i.val at hf
    simp only [Option.isSome_some,true_iff]
    exact ⟨table.val[i.val]'hf.1,List.getElem_mem hf.1,congrArg nats hf.2.1⟩
 theorem principal_ok (r : varctx.VariableResolver) (out : alloc.vec.Vec U8)
    (h : varctx.resolve_principal_type r = ok out) : nats out.val = VariablePrincipalType r := by
  unfold varctx.resolve_principal_type at h
  h5i_invert h
  case h_1 =>
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h,
      rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs]
    simp only [VariablePrincipalType,VariableClaimPresent,hc]
    decide +kernel
  all_goals
    have hrole : VariableClaimPresent r (lit "roleArn") ↔ o.isSome = true := by
      have hf := find_presence c s o ho
      have hl : nats s.val = lit "roleArn" := by
        rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs]
        decide +kernel
      simpa [VariableClaimPresent,hc,hl] using hf.symm
    first | change o.isSome = true at hc_1 | change ¬ o.isSome = true at hc_1
    try
      have hparent : VariableClaimPresent r (lit "parent") ↔ o1.isSome = true := by
        have hf := find_presence c s1 o1 ho1
        have hl : nats s1.val = lit "parent" := by
          rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs1]
          decide +kernel
        simpa [VariableClaimPresent,hc,hl] using hf.symm
      first | change o1.isSome = true at hc_2 | change ¬ o1.isSome = true at hc_2
    try
      have hsa : VariableClaimPresent r (lit "sa-policy") ↔ o2.isSome = true := by
        have hf := find_presence c s2 o2 ho2
        have hl : nats s2.val = lit "sa-policy" := by
          rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs2]
          decide +kernel
        simpa [VariableClaimPresent,hc,hl] using hf.symm
      first | change o2.isSome = true at hc_3 | change ¬ o2.isSome = true at hc_3
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    first
    | rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs_1]
    | rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs3]
    simp_all [VariablePrincipalType]
    decide +kernel

end rustfs_kernel.Verified.RustfsVariablePrincipal
