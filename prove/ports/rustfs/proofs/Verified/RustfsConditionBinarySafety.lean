import Verified.RustfsBinaryEvaluation
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit

namespace rustfs_kernel.Verified.RustfsConditionBinarySafety

theorem condition_sound (c : conddata.Condition) (q : condfuncs.Quantifier)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (env : condfuncs.Env)
    (h : conddata.condition_evaluate c q values ctx env = ok true) :
    BinaryConditionSafe values c := by
  cases hd : c.data <;> try simp only [BinaryConditionSafe, hd]
  unfold conddata.condition_evaluate at h
  simp only [hd] at h
  h5i_invert h
  · exact Or.inr (rustfs_kernel.Verified.RustfsBinaryEvaluation.evaluate_sound _ _ true h rfl)
  · have hp := rustfs_kernel.Verified.RustfsConditionEval.has_any_key_ok c values b hb
    exact Or.inl ⟨by scalar_tac, fun hh => hc_1 (hp.2 hh)⟩
  · exact Or.inr (rustfs_kernel.Verified.RustfsBinaryEvaluation.evaluate_sound _ _ true h rfl)

theorem all_sound (cs : Slice conddata.Condition) (q : condfuncs.Quantifier)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (env : condfuncs.Env)
    (h : conddata.all_hold cs q values ctx env = ok true) :
    ∀ c ∈ cs.val, BinaryConditionSafe values c := by
  unfold conddata.all_hold conddata.all_hold_loop at h
  have hh : true = true → ∀ c ∈ cs.val, BinaryConditionSafe values c := by
    refine loop_ok _ (fun i : Usize => i.val ≤ cs.val.length ∧
        ∀ c ∈ cs.val.take i.val, BinaryConditionSafe values c)
      (fun r => r = true → ∀ c ∈ cs.val, BinaryConditionSafe values c)
      (fun i => cs.val.length - i.val) ?_ _ true ⟨by simp, by simp⟩ h
    rintro i r ⟨hi,hs⟩ hr
    unfold conddata.all_hold_loop.body at hr
    h5i_invert hr
    · obtain ⟨hlt,he⟩ := slice_index_ok hc_1
      have hp := condition_sound c q values ctx env (by simpa only [hc_2] using hb)
      have hadd := add_ok_val hi2
      refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
      intro x hx
      rw [show i2.val = i.val + 1 by scalar_tac, List.take_add_one,
        List.getElem?_eq_getElem hlt, he] at hx
      simp only [Option.toList_some, List.mem_append, List.mem_singleton] at hx
      rcases hx with hx | rfl
      · exact hs x hx
      · exact hp
    · intro hf; cases hf
    · intro _
      rw [List.take_of_length_le (by scalar_tac)] at hs
      exact hs
  exact hh rfl

theorem functions_sound (f : conddata.Functions)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (env : condfuncs.Env)
    (h : conddata.functions_evaluate f values ctx env = ok true) :
    (∀ c ∈ f.for_any_value.val, BinaryConditionSafe values c) ∧
    (∀ c ∈ f.for_all_values.val, BinaryConditionSafe values c) ∧
    (∀ c ∈ f.for_normal.val, BinaryConditionSafe values c) := by
  unfold conddata.functions_evaluate at h
  h5i_invert h
  refine ⟨?_, ?_, ?_⟩
  · simpa only [rustfs_kernel.Verified.RustfsForceDelete.deref_val] using
      all_sound f.for_any_value.deref .ForAnyValue values ctx env (by simpa only [hc] using hb)
  · simpa only [rustfs_kernel.Verified.RustfsForceDelete.deref_val] using
      all_sound f.for_all_values.deref .ForAllValues values ctx env (by simpa only [hc_1] using hb1)
  · simpa only [rustfs_kernel.Verified.RustfsForceDelete.deref_val] using
      all_sound f.for_normal.deref .None values ctx env h

end rustfs_kernel.Verified.RustfsConditionBinarySafety
