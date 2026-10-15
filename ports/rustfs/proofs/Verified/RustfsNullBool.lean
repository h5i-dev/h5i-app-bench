import Verified.RustfsOperatorLookup
import Verified.RustfsScalarOperators
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsCondData (all_loop)
namespace rustfs_kernel.Verified.RustfsNullBool

theorem null_conditions_ok (funcs : Slice (condfuncs.Key × Bool))
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (b : Bool) (h : condfuncs.null_func funcs values = ok b) :
    b = true ↔ NullConditions funcs.val (RequestValueLists values.val) := by
  unfold condfuncs.null_func condfuncs.null_func_loop at h
  unfold NullConditions
  refine all_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold condfuncs.null_func_loop.body at hr
  h5i_invert hr
  · rcases x with ⟨key,want⟩
    obtain ⟨hlt,he⟩ := slice_index_ok hx
    change (do
      let count ← condfuncs.value_count values key
      let matched ← condfuncs.null_ok want count
      if matched then
        let next ← i + 1#usize
        ok (ControlFlow.cont next)
      else ok (ControlFlow.done false)) = ok r at hr
    h5i_invert hr
    · have hn := RustfsOperatorLookup.count_ok _ _ _ hcount
      have hc := (RustfsScalarOperators.null_ok _ _ _ hmatched).1 hc_1
      refine ⟨hlt, ?_, by have := add_ok_val hnext; scalar_tac⟩
      rw [he]
      simpa only [hn] using hc
    · have hn := RustfsOperatorLookup.count_ok _ _ _ hcount
      have hc := RustfsScalarOperators.null_ok _ _ _ hmatched
      refine .inl ⟨hlt, ?_, rfl⟩
      rw [he]
      intro hh
      exact hc_1 (hc.2 (by simpa only [hn] using hh))
  · exact .inr ⟨by scalar_tac, rfl⟩

/-- The byte spelling is case sensitive and only the first value is inspected. -/
theorem bool_conditions_ok (funcs : Slice (condfuncs.Key × Bool))
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (b : Bool) (h : condfuncs.bool_func funcs values = ok b) :
    b = true ↔ BoolConditions funcs.val (RequestValueLists values.val) := by
  unfold condfuncs.bool_func condfuncs.bool_func_loop at h
  unfold BoolConditions
  refine all_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold condfuncs.bool_func_loop.body at hr
  h5i_invert hr
  · rcases x with ⟨key,want⟩
    obtain ⟨hlt,he⟩ := slice_index_ok hx
    change (do
      let first ← condfuncs.first_value values key
      let matched ← match first with
        | none => ok false
        | some text =>
          if want then do
            let literal ← lift (Array.to_slice (Array.make 4#usize [116#u8,114#u8,117#u8,101#u8]))
            bytes.eq text.deref literal
          else do
            let literal ← lift (Array.to_slice (Array.make 5#usize [102#u8,97#u8,108#u8,115#u8,101#u8]))
            bytes.eq text.deref literal
      if matched then
        let next ← i + 1#usize
        ok (ControlFlow.cont next)
      else ok (ControlFlow.done false)) = ok r at hr
    h5i_invert hr
    all_goals
      have hf := RustfsOperatorLookup.first_ok _ _ _ hfirst
      have hm : matched = true ↔ first.map (fun text => nats text.val) =
          some (if want then lit "true" else lit "false") := by
        cases first with
        | none => simp only [Result.ok.injEq] at hmatched; subst matched; simp_all
        | some text =>
          cases want <;> simp only [Bool.false_eq_true, if_false, if_true] at hmatched <;>
            h5i_invert hmatched
          all_goals
            have hb := RustfsForceDelete.bytes_eq_ok _ _ _ hmatched
            simp only [RustfsForceDelete.deref_val] at hb
            have hl := RustfsForceDelete.lift_slice hliteral
            have hn : text.val = literal.val ↔ nats text.val = nats literal.val :=
              ⟨congrArg nats, RustfsForceDelete.nats_inj⟩
            have hh := hb.trans hn
            rw [hl] at hh
            have ht : lit "true" = [116,114,117,101] := by decide +kernel
            have hf : lit "false" = [102,97,108,115,101] := by decide +kernel
            simpa [ht,hf] using hh
    · refine ⟨hlt, ?_, by have := add_ok_val hnext; scalar_tac⟩
      simp only [he, Prod.fst, Prod.snd]
      rw [← hf]
      simp only [Option.map_map, Function.comp_def]
      exact hm.1 hc_1
    · refine .inl ⟨hlt, ?_, rfl⟩
      simp only [he, Prod.fst, Prod.snd]
      rw [← hf]
      simp only [Option.map_map, Function.comp_def]
      exact fun hh => hc_1 (hm.2 hh)
  · exact .inr ⟨by scalar_tac,rfl⟩
end rustfs_kernel.Verified.RustfsNullBool
