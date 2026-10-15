import SpecClaims
import Verified.RustfsForceDelete
import Verified.RustfsCleanCanonical
import H5iAppLib
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsForceDelete (bytes_eq_ok deref_val)

namespace rustfs_kernel.Verified.RustfsClaimLookup

theorem find_ok (table : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value))
    (needle : Slice U8) (o : Option Usize) (h : claims.find table needle = ok o) :
    ClaimLookupResult table.val needle.val o := by
  unfold claims.find claims.find_loop at h
  refine loop_ok _ (fun i : Usize => i.val ≤ table.val.length ∧
      ∀ e ∈ table.val.take i.val, e.1.val ≠ needle.val)
    (ClaimLookupResult table.val needle.val) (fun i => table.val.length - i.val)
    ?_ _ o ⟨by simp, by simp⟩ h
  rintro i r ⟨hi,hn⟩ hr
  unfold claims.find_loop.body at hr
  h5i_invert hr
  · rcases x with ⟨v,value⟩
    change (do
      let b ← bytes.eq v.deref needle
      if b then ok (ControlFlow.done (some i))
      else
        let j ← i + 1#usize
        ok (ControlFlow.cont j)) = ok r at hr
    h5i_invert hr
    · obtain ⟨hlt,he⟩ := vec_index_ok hx
      have hb := bytes_eq_ok _ _ _ (by assumption)
      rw [deref_val] at hb
      change FirstNamedClaim table.val needle.val i.val
      refine ⟨hlt, ?_, ?_⟩
      · rw [he]; exact hb.1 hc_1
      · intro j hj
        exact hn _ (List.mem_take_iff_getElem.mpr ⟨j,by omega,rfl⟩)
    · obtain ⟨hlt,he⟩ := vec_index_ok hx
      have hb := bytes_eq_ok _ _ _ (by assumption)
      rw [deref_val] at hb
      have hjv := add_ok_val hj
      refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
      have hji : j.val = i.val + 1 := by scalar_tac
      rw [hji, List.take_add_one, List.getElem?_eq_getElem hlt]
      intro e helem
      simp only [Option.toList_some, List.mem_append, List.mem_singleton] at helem
      rcases helem with hh | rfl
      · exact hn e hh
      · rw [he]; exact fun hh => hc_1 (hb.2 hh)
  · change ∀ e ∈ table.val, e.1.val ≠ needle.val
    have hle : table.val.length ≤ i.val := by scalar_tac
    simpa only [List.take_of_length_le hle] using hn
theorem role_arn_sound (table : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value))
    (v : alloc.vec.Vec U8) (h : claims.get_role_arn table = ok (some v)) :
    ∃ i : Usize, ∃ hi : i.val < table.val.length,
      FirstNamedClaim table.val table.val[i.val].1.val i.val ∧
      nats table.val[i.val].1.val = lit "roleArn" ∧
      table.val[i.val].2 = claims.Value.String v := by
  unfold claims.get_role_arn at h
  h5i_invert h
  have hsl : nats s.val = lit "roleArn" :=
    by rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs]; decide +kernel
  clear hs
  rcases x with ⟨key,value⟩
  change (match (generalizing := false) value with
    | .Null => ok none
    | .Bool _ => ok none
    | .Number _ => ok none
    | .String s1 => do
      let v1 ← alloc.vec.CloneVec.clone core.clone.CloneU8 s1
      ok (some v1)
    | .Array _ => ok none
    | .Object _ => ok none) = ok (some v) at h
  cases value
  all_goals h5i_invert h
  have hc := post_of_ok (CloneLaw.vec_clone_spec core.clone.CloneU8 _) hv1
  have hclone : _ = v := hc.symm.trans (Option.some.inj h)
  obtain ⟨hlt,he⟩ := vec_index_ok hx
  have hf := find_ok table s (some val) ho
  change FirstNamedClaim table.val s.val val.val at hf
  rcases hf with ⟨_,hkey,hfirst⟩
  refine ⟨val,hlt,?_,?_,?_⟩
  · exact ⟨hlt,rfl,by simpa only [hkey] using hfirst⟩
  · rw [hkey]; exact hsl
  · rw [he]; simpa only using congrArg claims.Value.String hclone
theorem service_policy_name_ok (v : alloc.vec.Vec U8)
    (h : claims.iam_policy_claim_name_sa = ok v) : nats v.val = lit "sa-policy" := by
  unfold claims.iam_policy_claim_name_sa at h
  h5i_invert h
  rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
  rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs]
  decide +kernel

end rustfs_kernel.Verified.RustfsClaimLookup
