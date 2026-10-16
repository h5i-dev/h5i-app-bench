import Verified.RustfsConditionEval
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsConditionLookupContents

theorem get_contents_ok
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (needle : Slice U8) (v : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : condfuncs.get_value values needle = ok (some v)) :
    ∃ e ∈ values.val, e.1.val = needle.val ∧ e.2 = v := by
  unfold condfuncs.get_value condfuncs.get_value_loop at h
  have hh : ∀ w, (some v : Option (alloc.vec.Vec (alloc.vec.Vec U8))) = some w →
      ∃ e ∈ values.val, e.1.val = needle.val ∧ e.2 = w := by
    refine loop_ok _ (fun i : Usize => i.val ≤ values.val.length)
      (fun o => ∀ w, o = some w → ∃ e ∈ values.val, e.1.val = needle.val ∧ e.2 = w)
      (fun i => values.val.length - i.val) ?_ _ (some v) (by simp) h
    intro i r hi hr
    unfold condfuncs.get_value_loop.body at hr
    h5i_invert hr
    · rcases x with ⟨v, vs⟩
      change (do
        let equal ← bytes.eq v.deref needle
        if equal then
          let copied ← alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) vs
          ok (ControlFlow.done (some copied))
        else
          let next ← i + 1#usize
          ok (ControlFlow.cont next)) = ok r at hr
      have he := vec_index_slice_ok_get? (by assumption : alloc.vec.Vec.index _ values i = ok (v,vs))
      have hlt : i.val < values.val.length := by scalar_tac
      rw [List.getElem?_eq_getElem hlt] at he
      simp only [Option.some.injEq] at he
      h5i_invert hr
      · intro w hw
        have hb := rustfs_kernel.Verified.RustfsForceDelete.bytes_eq_ok _ _ _ hequal
        simp only [rustfs_kernel.Verified.RustfsForceDelete.deref_val] at hb
        have hc := post_of_ok (CloneLaw.vec_clone_spec _ vs) hcopied
        refine ⟨(v, vs), ?_, hb.1 hc_1, hc.symm.trans (Option.some.inj hw)⟩
        rw [← he]
        exact List.getElem_mem hlt
      · have hadd := add_ok_val hnext
        exact ⟨by scalar_tac, by scalar_tac⟩
    · intro w hw; cases hw
  exact hh v rfl
end rustfs_kernel.Verified.RustfsConditionLookupContents
