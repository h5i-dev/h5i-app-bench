import Verified.RustfsCondData
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsCondData
open rustfs_kernel.Verified.RustfsValids (any_loop)
open rustfs_kernel.Verified.RustfsBytes (slice_ok push_ok)
open rustfs_kernel.Verified.RustfsForceDelete (bytes_eq_ok deref_val lift_slice)

namespace rustfs_kernel.Verified.RustfsConditionEval

theorem concat_ok (a b : Slice U8) (v : alloc.vec.Vec U8) (h : bytes.concat a b = ok v) :
    v.val = a.val ++ b.val := by
  unfold bytes.concat at h
  obtain ⟨out, hout, h⟩ := bind_tc_eq_ok.1 h
  have hout' := slice_ok _ _ _ _ hout
  simp only [Slice.len_val, UScalar.ofNatCore_val_eq, List.take_length, List.drop_zero] at hout'
  unfold bytes.concat_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec U8 × Usize => x.2.val ≤ b.val.length ∧
      x.1.val = a.val ++ b.val.take x.2.val)
    (fun v => v.val = a.val ++ b.val) (fun x => b.val.length - x.2.val) ?_ _ v
    ⟨by simp, by simpa using hout'⟩ h
  rintro ⟨out, i⟩ r ⟨hi, ho⟩ hr
  unfold bytes.concat_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt, he⟩ := slice_index_ok hi2
    have hp := push_ok hout1
    have hadd := add_ok_val hi3
    refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
    rw [hp, ho, show i3.val = i.val + 1 by scalar_tac,
      List.take_add_one, List.getElem?_eq_getElem hlt, he]
    simp [List.append_assoc]
  · rw [List.take_of_length_le (by scalar_tac)] at ho
    exact ho

theorem lookup_name_ok (k : condfuncs.Key) (v : alloc.vec.Vec U8)
    (h : condfuncs.key_lookup_name k = ok v) : v.val = LookupName k := by
  unfold condfuncs.key_lookup_name at h
  cases hv : k.variable with
  | none =>
    simp only [hv, u8vec_clone, Result.ok.injEq] at h
    subst v; simp [LookupName, hv]
  | some suffix =>
    simp only [hv] at h
    h5i_invert h
    have hs : s1.val = [47#u8] := by
      simp only [lift, Result.ok.injEq] at hs1
      subst s1; rfl
    have h1 := concat_ok _ _ _ hv1
    have h2 := concat_ok _ _ _ h
    simp only [deref_val] at h1 h2
    rw [h2, h1, hs]
    simp [LookupName, hv]

theorem get_value_present_ok
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (needle : Slice U8) (o : Option (alloc.vec.Vec (alloc.vec.Vec U8)))
    (h : condfuncs.get_value values needle = ok o) :
    (o.isSome = true ↔ ∃ e ∈ values.val, e.1.val = needle.val) := by
  unfold condfuncs.get_value condfuncs.get_value_loop at h
  refine loop_ok _ (fun i : Usize => i.val ≤ values.val.length ∧
      ∀ e ∈ values.val.take i.val, e.1.val ≠ needle.val)
    (fun o => o.isSome = true ↔ ∃ e ∈ values.val, e.1.val = needle.val)
    (fun i => values.val.length - i.val) ?_ _ o ⟨by simp, by simp⟩ h
  rintro i r ⟨hi, hx⟩ hr
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
    have he := vec_index_slice_ok_get? hx_1
    have hlt : i.val < values.val.length := by scalar_tac
    rw [List.getElem?_eq_getElem hlt] at he
    simp only [Option.some.injEq] at he
    h5i_invert hr
    · have hb := bytes_eq_ok _ _ _ (by assumption : bytes.eq _ _ = ok _)
      simp only [deref_val] at hb
      simp only [Option.isSome_some, true_iff]
      refine ⟨values.val[i.val], List.getElem_mem hlt, ?_⟩
      rw [he]; exact hb.1 (by assumption)
    · have hb := bytes_eq_ok _ _ _ (by assumption : bytes.eq _ _ = ok _)
      simp only [deref_val] at hb
      have hadd := add_ok_val hnext
      refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
      intro e hh
      rw [show next.val = i.val + 1 by scalar_tac, List.take_add_one,
        List.getElem?_eq_getElem hlt] at hh
      simp only [Option.toList_some, List.mem_append, List.mem_singleton] at hh
      rcases hh with hh | rfl
      · exact hx e hh
      · rw [he]; intro hh; exact hc_1 (hb.2 hh)
  · simp only [Option.isSome_none, Bool.false_eq_true, false_iff]
    rw [List.take_of_length_le (by scalar_tac)] at hx
    rintro ⟨e, he, hh⟩; exact hx e he hh

theorem inner_has_value_ok {T : Type} (f : conddata.InnerFunc T)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (b : Bool) (h : conddata.inner_has_value f values = ok b) :
    (b = true ↔ ∃ e ∈ f.entries.val, ∃ v ∈ values.val, v.1.val = LookupName e.key) := by
  unfold conddata.inner_has_value conddata.inner_has_value_loop at h
  refine any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold conddata.inner_has_value_loop.body at hr
  h5i_invert hr
  · have he := vec_index_slice_ok_get? hfkv
    have hlt : i.val < f.entries.val.length := by scalar_tac
    rw [List.getElem?_eq_getElem hlt] at he
    simp only [Option.some.injEq] at he
    have hn := lookup_name_ok _ _ hv
    have hp := get_value_present_ok _ _ _ ho
    simp only [deref_val] at hp
    refine .inl ⟨hlt, ?_, rfl⟩
    rw [he]; dsimp only; rw [← hn]; exact hp.1 hc_1
  · have he := vec_index_slice_ok_get? hfkv
    have hlt : i.val < f.entries.val.length := by scalar_tac
    rw [List.getElem?_eq_getElem hlt] at he
    simp only [Option.some.injEq] at he
    have hn := lookup_name_ok _ _ hv
    have hp := get_value_present_ok _ _ _ ho
    simp only [deref_val] at hp
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]; dsimp only; rw [← hn]; intro hh; exact hc_1 (hp.2 hh)
  · exact .inr ⟨by scalar_tac, rfl⟩

theorem has_any_key_ok (c : conddata.Condition)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (b : Bool) (h : conddata.has_any_key_in c values = ok b) :
    (b = true ↔ RequestHasConditionKey c values) := by
  unfold conddata.has_any_key_in at h
  unfold RequestHasConditionKey ConditionLookupNames
  cases hd : c.data <;> simp only [hd] at h ⊢ <;>
    rw [inner_has_value_ok _ _ _ h]
  all_goals
    simp only [List.mem_map]
    constructor
    · rintro ⟨e, he, entry, hv, hsame⟩
      exact ⟨LookupName e.key, ⟨e, he, rfl⟩, entry, hv, hsame⟩
    · rintro ⟨needle, ⟨e, he, rfl⟩, entry, hv, hsame⟩
      exact ⟨e, he, entry, hv, hsame⟩

/-- An IfExists condition accepts a request with none of its named keys. -/
theorem missing_wrapped_key_ok (c : conddata.Condition) (q : condfuncs.Quantifier)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (env : condfuncs.Env) (b : Bool)
    (hw : 0 < c.wrappers.val) (hm : ¬ RequestHasConditionKey c values)
    (h : conddata.condition_evaluate c q values ctx env = ok b) : b = true := by
  unfold conddata.condition_evaluate at h
  have hw' : c.wrappers > 0#usize := by scalar_tac
  simp only [hw', ↓reduceIte] at h
  obtain ⟨present, hp, h⟩ := bind_tc_eq_ok.1 h
  have hn := has_any_key_ok c values present hp
  have hfalse : present = false := by
    cases present with
    | false => rfl
    | true => exact False.elim (hm (hn.1 rfl))
  simp only [hfalse, Bool.false_eq_true, ↓reduceIte, Result.ok.injEq] at h
  exact h.symm

theorem key_names_ok {T : Type} (f : conddata.InnerFunc T)
    (names : alloc.vec.Vec (alloc.vec.Vec U8)) (h : conddata.key_names f = ok names) :
    names.val.map (·.val) = f.entries.val.map (fun e => LookupName e.key) := by
  unfold conddata.key_names conddata.key_names_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec (alloc.vec.Vec U8) × Usize =>
      x.2.val ≤ f.entries.val.length ∧ x.1.val.map (·.val) =
        (f.entries.val.take x.2.val).map (fun e => LookupName e.key))
    (fun names => names.val.map (·.val) = f.entries.val.map (fun e => LookupName e.key))
    (fun x => f.entries.val.length - x.2.val) ?_ _ names ⟨by simp, by simp⟩ h
  rintro ⟨names, i⟩ r ⟨hi, hn⟩ hr
  unfold conddata.key_names_loop.body at hr
  h5i_invert hr
  · have he := vec_index_slice_ok_get? hfkv
    have hlt : i.val < f.entries.val.length := by scalar_tac
    rw [List.getElem?_eq_getElem hlt] at he
    simp only [Option.some.injEq] at he
    have hk := lookup_name_ok _ _ hv
    have hp := push_ok hnames1
    have hadd := add_ok_val hi2
    refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
    rw [hp, List.map_append, hn, show i2.val = i.val + 1 by scalar_tac,
      List.take_add_one, List.getElem?_eq_getElem hlt, List.map_append]
    simp only [Option.toList_some, List.map_cons, List.map_nil, he, hk]
  · rw [List.take_of_length_le (by scalar_tac)] at hn
    exact hn

end rustfs_kernel.Verified.RustfsConditionEval
