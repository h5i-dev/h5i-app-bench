import SpecOperators
import Verified.RustfsConditionEval
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsForceDelete (bytes_eq_ok deref_val)
namespace rustfs_kernel.Verified.RustfsOperatorLookup

theorem lookup_ok
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (needle : Slice U8) (out : Option (alloc.vec.Vec (alloc.vec.Vec U8)))
    (h : condfuncs.get_value values needle = ok out) :
    out.map (fun vs => vs.val.map (·.val)) =
      ConditionValues (RequestValueLists values.val) needle.val := by
  unfold condfuncs.get_value condfuncs.get_value_loop at h
  refine loop_ok _ (fun i : Usize => i.val ≤ values.val.length ∧
      ConditionValues (RequestValueLists values.val) needle.val =
        ConditionValues (RequestValueLists (values.val.drop i.val)) needle.val)
    (fun o => o.map (fun vs => vs.val.map (·.val)) =
      ConditionValues (RequestValueLists values.val) needle.val)
    (fun i => values.val.length - i.val) ?_ _ out ⟨by simp, by simp⟩ h
  rintro i r ⟨hi,hm⟩ hr
  unfold condfuncs.get_value_loop.body at hr
  h5i_invert hr
  · rcases x with ⟨keyBytes,vs⟩
    change (do
      let equal ← bytes.eq keyBytes.deref needle
      if equal then
        let copied ← alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) vs
        ok (ControlFlow.done (some copied))
      else
        let next ← i + 1#usize
        ok (ControlFlow.cont next)) = ok r at hr
    obtain ⟨hlt,he⟩ := vec_index_ok hx
    h5i_invert hr
    · have hb := (bytes_eq_ok _ _ _ hequal).1 hc_1
      have hc := post_of_ok (CloneLaw.vec_clone_spec _ vs) hcopied
      rw [hm, List.drop_eq_getElem_cons hlt, he]
      simp only [deref_val] at hb
      simp [ConditionValues, RequestValueLists, hc, hb]
    · have hb : keyBytes.val ≠ needle.val := by
        intro hh; exact hc_1 ((bytes_eq_ok _ _ _ hequal).2 (by simpa [deref_val] using hh))
      have ha := add_ok_val hnext
      refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
      rw [hm, List.drop_eq_getElem_cons hlt, he]
      simp only [RequestValueLists, List.map_cons, ConditionValues, List.find?_cons,
        hb, decide_false, Bool.false_eq_true, ite_false]
      congr 4
      scalar_tac
  · rw [hm, List.drop_of_length_le (by scalar_tac)]
    rfl
end rustfs_kernel.Verified.RustfsOperatorLookup

namespace rustfs_kernel.Verified.RustfsOperatorLookup

theorem first_ok
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (key : condfuncs.Key) (out : Option (alloc.vec.Vec U8))
    (h : condfuncs.first_value values key = ok out) :
    out.map (·.val) = FirstConditionValue (RequestValueLists values.val) key := by
  unfold condfuncs.first_value at h
  h5i_invert h
  all_goals
    have hn := RustfsConditionEval.lookup_name_ok key v hv
    have hl := lookup_ok values _ _ ho
    simp only [deref_val, hn] at hl
    unfold FirstConditionValue
    rw [← hl]
  · rfl
  · have he := vec_index_slice_ok_get? hv2
    simp only [u8vec_clone, Result.ok.injEq] at hv3
    subst v3
    have hlt : 0 < l.val.length := by scalar_tac
    change l.val[0]? = some v2 at he
    rw [List.getElem?_eq_getElem hlt] at he
    simp only [Option.some.injEq] at he
    have hhead : l.val.head? = some v2 := by
      have hh : l.val.head? = l.val[0]? := by cases l.val <;> rfl
      rw [hh, List.getElem?_eq_getElem hlt, he]
    simp [hhead]
  · have he : l.val = [] := List.eq_nil_iff_length_eq_zero.2 (by scalar_tac)
    simp [he]

theorem count_ok
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (key : condfuncs.Key) (out : Usize)
    (h : condfuncs.value_count values key = ok out) :
    out.val = ((ConditionValues (RequestValueLists values.val) (LookupName key)).getD []).length := by
  unfold condfuncs.value_count at h
  h5i_invert h
  all_goals
    have hn := RustfsConditionEval.lookup_name_ok key v hv
    have hl := lookup_ok values _ _ ho
    simp only [deref_val, hn] at hl
    rw [← hl]
  · rfl
  · simp
end rustfs_kernel.Verified.RustfsOperatorLookup
