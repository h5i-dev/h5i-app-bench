import Verified.RustfsVariableScalars
import Verified.RustfsValids
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsForceDelete (bytes_eq_ok deref_val)
namespace rustfs_kernel.Verified.RustfsVariableCustom
 theorem loop_spec (r : varctx.VariableResolver) (key : alloc.vec.Vec U8)
    (out : Option (alloc.vec.Vec U8))
    (h : varctx.resolve_custom_variable_loop r key 0#usize = ok out) :
    out = CustomValue r.context.custom_variables.val key.val := by
  unfold varctx.resolve_custom_variable_loop at h
  refine loop_ok _ (fun i : Usize => i.val ≤ r.context.custom_variables.val.length ∧
      ∀ e ∈ r.context.custom_variables.val.take i.val, e.1.val ≠ key.val)
    (fun out => out = CustomValue r.context.custom_variables.val key.val)
    (fun i => r.context.custom_variables.val.length - i.val) ?_ _ out ⟨by simp,by simp⟩ h
  rintro i res ⟨hi,hn⟩ hr
  unfold varctx.resolve_custom_variable_loop.body at hr
  h5i_invert hr
  · rcases x with ⟨candidate,value⟩
    change (do
      let b ← bytes.eq candidate.deref key.deref
      if b then do
        let v ← alloc.vec.CloneVec.clone core.clone.CloneU8 value
        ok (ControlFlow.done (some v))
      else do
        let j ← i + 1#usize
        ok (ControlFlow.cont j)) = ok res at hr
    h5i_invert hr
    · obtain ⟨hlt,he⟩ := vec_index_ok hx
      have hb := bytes_eq_ok _ _ _ (by assumption)
      rw [deref_val,deref_val] at hb
      have hkey : candidate.val = key.val := hb.mp hc_1
      have hf : r.context.custom_variables.val.find? (fun e => decide (e.1.val = key.val)) =
          some (candidate,value) := by
        apply List.find?_eq_some_iff_append.mpr
        refine ⟨by simpa using hkey,r.context.custom_variables.val.take i.val,
          r.context.custom_variables.val.drop (i.val+1),?_,?_⟩
        · rw [← he,← List.drop_eq_getElem_cons hlt]
          exact (List.take_append_drop _ _).symm
        · intro e hm
          simpa using hn e hm
      simp only [u8vec_clone] at hv
      have hvv := Result.ok.inj hv
      simp only [CustomValue,hf,Option.map_some]
      exact congrArg some hvv.symm
    · obtain ⟨hlt,he⟩ := vec_index_ok hx
      have hb := bytes_eq_ok _ _ _ (by assumption)
      rw [deref_val,deref_val] at hb
      have hjv := add_ok_val hj
      refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
      have hji : j.val = i.val+1 := by scalar_tac
      rw [hji,List.take_add_one,List.getElem?_eq_getElem hlt]
      intro e hm
      simp only [Option.toList_some,List.mem_append,List.mem_singleton] at hm
      rcases hm with hm | rfl
      · exact hn e hm
      · rw [he];exact fun hh => hc_1 (hb.mpr hh)
  · have hle : r.context.custom_variables.val.length ≤ i.val := by scalar_tac
    have hn1 : ∀ e ∈ r.context.custom_variables.val, e.1.val ≠ key.val := by
      simpa only [List.take_of_length_le hle] using hn
    have hf : r.context.custom_variables.val.find? (fun e => decide (e.1.val = key.val)) = none :=
      List.find?_eq_none.mpr (by intro e hm;simpa using hn1 e hm)
    simp only [CustomValue,hf,Option.map_none]
theorem custom_ok (r : varctx.VariableResolver) (needle : Slice U8)
    (out : Option (alloc.vec.Vec U8)) (h : varctx.resolve_custom_variable r needle = ok out) :
    out = VariableCustom r needle.val := by
  unfold varctx.resolve_custom_variable at h
  h5i_invert h
  all_goals
    have hp : nats s.val = lit "custom:" := by
      rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs]
      decide +kernel
    have hb := rustfs_kernel.Verified.RustfsValids.starts_lit hp hb
  case isTrue =>
    have hk := rustfs_kernel.Verified.RustfsBytes.slice_ok _ _ _ _ hkey
    have he : key.val = needle.val.drop 7 := by simpa using hk
    rw [loop_spec _ _ _ h,he]
    simp only [VariableCustom,if_pos (hb.mp hc)]
  case isFalse =>
    simp only [VariableCustom,if_neg (fun hh => hc (hb.mpr hh))]

end rustfs_kernel.Verified.RustfsVariableCustom
