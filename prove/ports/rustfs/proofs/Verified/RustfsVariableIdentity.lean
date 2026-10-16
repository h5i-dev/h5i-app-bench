import Verified.RustfsVariableScalars
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsVariableScalars
namespace rustfs_kernel.Verified.RustfsVariableIdentity

theorem userid_ok (r : varctx.VariableResolver) (o : Option (alloc.vec.Vec U8))
    (h : varctx.resolve_userid r = ok o) : o.map (fun v => nats v.val) = VariableUserID r := by
  unfold varctx.resolve_userid at h
  h5i_invert h
  all_goals
    have hsub := claim_strings_ok r s o_1 ho_1
    have hsl : nats s.val = lit "sub" := by
      rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs]
      decide +kernel
    rw [hsl] at hsub
    have fallback (values : Option (alloc.vec.Vec (alloc.vec.Vec U8)))
        (hh : (match (generalizing := false) o_1 with
          | none => do
            let s1 ← lift (Array.make 6#usize
              [112#u8,97#u8,114#u8,101#u8,110#u8,116#u8]
              varctx.resolve_userid._proof_1).to_slice
            varctx.get_claim_as_strings r s1
          | some _ => ok o_1) = ok values) :
        values.map (fun vs => vs.val.map (fun v => nats v.val)) =
          (ResolverStrings r (lit "sub")).orElse (fun _ => ResolverStrings r (lit "parent")) := by
      cases he : o_1 with
      | none =>
        simp only [he] at hh hsub
        h5i_invert hh
        have hp := claim_strings_ok r s1 values hh
        have hpl : nats s1.val = lit "parent" := by
          rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs1]
          decide +kernel
        rw [hpl] at hp
        rw [← hsub]
        exact hp
      | some vs =>
        simp only [he] at hh hsub
        h5i_invert hh
        rw [← hsub]
        rfl
    have hf := fallback _ hvalues
    unfold VariableUserID
    rw [← hf]
  case h_1 => rfl
  case h_2.isTrue =>
    have he : l.val = [] := List.eq_nil_of_length_eq_zero (by scalar_tac)
    simp [he]
  case h_2.isFalse =>
    obtain ⟨hlt,he⟩ := vec_index_ok hv1
    have hi := sub_ok_val hi2
    have hie : i2.val = l.val.length - 1 := by scalar_tac
    simp only [Option.map_some,Option.bind_some,u8vec_clone] at *
    have he2 : v1 = v2 := Result.ok.inj hv2
    rw [← he2,← he,List.getLast?_map,List.getLast?_eq_getElem?,← hie,
      List.getElem?_eq_getElem hlt]
    rfl

end rustfs_kernel.Verified.RustfsVariableIdentity
