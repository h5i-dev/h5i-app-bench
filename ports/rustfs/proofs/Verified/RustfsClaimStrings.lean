import Verified.RustfsClaimUnique
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsBytes (push_ok)
open rustfs_kernel.Verified.RustfsForceDelete (deref_val)
namespace rustfs_kernel.Verified.RustfsClaimStrings

theorem append_ok (out : alloc.vec.Vec (alloc.vec.Vec U8)) (v : claims.Value)
    (result : alloc.vec.Vec (alloc.vec.Vec U8)) (ho : NonemptyClaimTokens out.val)
    (h : claims.append_string_values out v = ok result) : NonemptyClaimTokens result.val := by
  unfold claims.append_string_values at h
  cases v <;> h5i_invert h
  all_goals try exact ho
  have hp := rustfs_kernel.Verified.RustfsClaimTokens.split_nonempty _ _ hparts
  unfold claims.append_string_values_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec (alloc.vec.Vec U8) × Usize =>
    NonemptyClaimTokens x.1.val) (fun out => NonemptyClaimTokens out.val)
    (fun x => parts.val.length-x.2.val) ?_ _ result ho h
  rintro ⟨out,i⟩ r ho hr
  unfold claims.append_string_values_loop.body at hr
  simp only [u8vec_clone] at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := vec_index_ok hv1
    have hh := hp v1 (he ▸ List.getElem_mem hlt)
    have hadd := add_ok_val hi2
    refine ⟨?_,by scalar_tac⟩
    have hp := push_ok hout1
    intro x hx
    rw [hp,List.mem_append,List.mem_singleton] at hx
    rcases hx with hx | rfl
    · exact ho x hx
    · exact hh
  · exact ho
theorem array_ok (array : alloc.vec.Vec claims.Value)
    (out result : alloc.vec.Vec (alloc.vec.Vec U8)) (i : Usize)
    (ho : NonemptyClaimTokens out.val)
    (h : claims.value_strings_loop array out i = ok result) : NonemptyClaimTokens result.val := by
  unfold claims.value_strings_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec (alloc.vec.Vec U8) × Usize =>
    NonemptyClaimTokens x.1.val) (fun out => NonemptyClaimTokens out.val)
    (fun x => array.val.length-x.2.val) ?_ _ result ho h
  rintro ⟨out,i⟩ r ho hr
  unfold claims.value_strings_loop.body at hr
  h5i_invert hr
  · have hadd := add_ok_val hi2
    exact ⟨append_ok _ _ _ ho hout1,by scalar_tac⟩
  · exact ho

theorem value_ok (v : claims.Value) (out : alloc.vec.Vec (alloc.vec.Vec U8)) (b : Bool)
    (h : claims.value_strings v = ok (out,b)) :
    NonemptyClaimTokens out.val ∧ (b = true ↔ ClaimStringContainer v) := by
  unfold claims.value_strings at h
  cases v <;> h5i_invert h
  all_goals rcases h with ⟨rfl,rfl⟩
  case Null | Bool | Number | Object =>
    exact ⟨by simp [NonemptyClaimTokens,alloc.vec.Vec.new,alloc.vec.Vec.from_val],by simp [ClaimStringContainer]⟩
  case String =>
    exact ⟨append_ok _ _ _ (by simp [NonemptyClaimTokens]) hout_1,by simp [ClaimStringContainer]⟩
  case Array =>
    exact ⟨array_ok _ _ _ _ (by simp [NonemptyClaimTokens]) hout_1,by simp [ClaimStringContainer]⟩

theorem lookup_nonempty (table : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value))
    (needle : Slice U8) (out : alloc.vec.Vec (alloc.vec.Vec U8)) (b : Bool)
    (h : claims.lookup_strings table needle = ok (out,b)) : NonemptyClaimTokens out.val := by
  unfold claims.lookup_strings at h
  h5i_invert h
  · rcases h with ⟨rfl,rfl⟩
    simp [NonemptyClaimTokens,alloc.vec.Vec.new,alloc.vec.Vec.from_val]
  · rcases x_1 with ⟨key,value⟩
    exact (value_ok value out b h).1
  · rcases h with ⟨rfl,rfl⟩
    simp [NonemptyClaimTokens,alloc.vec.Vec.new,alloc.vec.Vec.from_val]
theorem get_values_ok (table : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value))
    (needle : Slice U8) (out : alloc.vec.Vec (alloc.vec.Vec U8)) (b : Bool)
    (h : claims.get_values_from_claims table needle = ok (out,b)) :
    NonemptyClaimTokens out.val ∧ out.val.Nodup := by
  unfold claims.get_values_from_claims at h
  h5i_invert h
  rcases x with ⟨values,present⟩
  change (do
    let v ← claims.unique_values values.deref
    ok (v,present)) = ok (out,b) at h
  h5i_invert h
  rcases h with ⟨rfl,rfl⟩
  have hn := lookup_nonempty table needle values present hx
  have hu := rustfs_kernel.Verified.RustfsClaimUnique.unique_ok _ _ hv
  rw [deref_val] at hu
  exact ⟨fun x hx => hn x ((hu.2 x).1 hx),hu.1⟩
theorem policies_ok (table : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value))
    (needle : Slice U8) (out : alloc.vec.Vec (alloc.vec.Vec U8)) (b : Bool)
    (h : claims.get_policies_from_claims table needle = ok (out,b)) :
    NonemptyClaimTokens out.val ∧ out.val.Nodup := get_values_ok table needle out b h

theorem args_ok (table : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value))
    (needle : Slice U8) (out : alloc.vec.Vec (alloc.vec.Vec U8)) (b : Bool)
    (h : claims.args_get_policies table needle = ok (out,b)) :
    NonemptyClaimTokens out.val ∧ out.val.Nodup := policies_ok table needle out b h

theorem exact_nonempty (table : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value))
    (needle : Slice U8) (out : alloc.vec.Vec (alloc.vec.Vec U8)) (b : Bool)
    (h : claims.values_from_claims table needle = ok (out,b)) : NonemptyClaimTokens out.val := by
  unfold claims.values_from_claims at h
  h5i_invert h
  · rcases h with ⟨rfl,rfl⟩
    simp [NonemptyClaimTokens,alloc.vec.Vec.new,alloc.vec.Vec.from_val]
  · rcases x with ⟨key,value⟩
    exact (value_ok value out b h).1
end rustfs_kernel.Verified.RustfsClaimStrings
