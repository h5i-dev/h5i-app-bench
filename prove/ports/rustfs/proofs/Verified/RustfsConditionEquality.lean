import Verified.RustfsConditionEval
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsCondData
open rustfs_kernel.Verified.RustfsForceDelete (deref_val)

namespace rustfs_kernel.Verified.RustfsConditionEquality

theorem allM_eq {T : Type} [DecidableEq T] (inst : core.cmp.PartialEq T T) [EqLaw inst]
    (l : List (T × T)) :
    List.allM (fun p => inst.eq p.1 p.2) l = ok (l.all (fun p => decide (p.1 = p.2))) := by
  induction l with
  | nil => rfl
  | cons p ps ih =>
    simp only [List.allM] 
    rw [EqLaw.eq_ok, ih]
    by_cases hh : p.1 = p.2 <;> simp [hh] <;> rfl

theorem zip_eq {T : Type} [DecidableEq T] (a b : List T) (hl : a.length = b.length) :
    (a.zip b).all (fun p => decide (p.1 = p.2)) = decide (a = b) := by
  induction a generalizing b with
  | nil => cases b <;> simp_all
  | cons x xs ih =>
    cases b with
    | nil => simp at hl
    | cons y ys =>
      simp only [List.length_cons, Nat.add_right_cancel_iff] at hl
      simp [List.zip_cons_cons, ih ys hl]

theorem vec_eq_law {T : Type} [DecidableEq T] (inst : core.cmp.PartialEq T T) [EqLaw inst]
    (a b : alloc.vec.Vec T) :
    alloc.vec.partial_eq.PartialEqVec.eq inst a b = ok (decide (a.val = b.val)) := by
  unfold alloc.vec.partial_eq.PartialEqVec.eq
  split
  · rename_i hl
    change List.allM (fun p => inst.eq p.1 p.2) (a.val.zip b.val) = _
    rw [allM_eq, zip_eq _ _ hl]
  · rename_i hl
    have hn : a.val ≠ b.val := fun hh => hl (congrArg List.length hh)
    simp [hn]

theorem binary_eq_ok (a b : conddata.BinaryFuncValue) (r : Bool)
    (h : conddata.binary_eq a b = ok r) : (r = true ↔ a.decoded.val = b.decoded.val) := by
  unfold conddata.binary_eq at h
  rw [vec_eq_law] at h
  simp only [Result.ok.injEq] at h
  subst r; simp

theorem string_inner_ok (a b : conddata.InnerFunc (alloc.vec.Vec (alloc.vec.Vec U8)))
    (r : Bool) (h : conddata.string_inner_eq a b = ok r) : (r = true ↔ SameStringCondition a b) := by
  unfold conddata.string_inner_eq at h
  by_cases hl : a.entries.val.length = b.entries.val.length
  · have hl' : a.entries.len = b.entries.len := by apply UScalar.eq_of_val_eq; simpa using hl
    simp only [hl', bne_self_eq_false, Bool.false_eq_true, ↓reduceIte] at h
    unfold conddata.string_inner_eq_loop at h
    unfold SameStringCondition
    simp only [hl, true_and]
    refine all_loop (a.entries.val.zip b.entries.val) SameStringEntry _ (fun i r hi hr => ?_) r h
    have hlen : (a.entries.val.zip b.entries.val).length = a.entries.val.length := by simp [hl]
    unfold conddata.string_inner_eq_loop.body at hr
    h5i_invert hr
    all_goals try
      have hlt : i.val < a.entries.val.length := by scalar_tac
      have hrt : i.val < b.entries.val.length := by omega
      have hf := vec_index_slice_ok_get? hfkv
      have hg := vec_index_slice_ok_get? hfkv1
      rw [List.getElem?_eq_getElem hlt] at hf
      rw [List.getElem?_eq_getElem hrt] at hg
      simp only [Option.some.injEq] at hf hg
      have hzip : (a.entries.val.zip b.entries.val)[i.val]'(by omega) = (fkv, fkv1) := by
        simp only [List.getElem_zip, hf, hg]
      have hk := key_eq_ok _ _ _ (by assumption : conddata.key_eq _ _ = ok _)
      try have hs := string_set_eq_ok _ _ _ (by assumption : conddata.string_set_eq _ _ = ok _)
      try simp only [deref_val] at hs
    · refine ⟨by omega, ?_, by have := add_ok_val hi2; scalar_tac⟩
      rw [hzip]; exact ⟨hk.1 hc_1, hs.1 hc_2⟩
    · refine .inl ⟨by omega, ?_, rfl⟩
      rw [hzip]; intro hh; exact hc_2 (hs.2 hh.2)
    · refine .inl ⟨by omega, ?_, rfl⟩
      rw [hzip]; intro hh; exact hc_1 (hk.2 hh.1)
    · exact .inr ⟨by scalar_tac, rfl⟩
  · have hl' : a.entries.len ≠ b.entries.len := by intro hh; apply hl; exact congrArg UScalar.val hh
    simp [hl', bne_iff_ne] at h
    subst r; simp [SameStringCondition, hl]
theorem num_inner_ok (a b : conddata.InnerFunc I64)
    (r : Bool) (h : conddata.num_inner_eq a b = ok r) : (r = true ↔ SameNumberCondition a b) := by
  unfold conddata.num_inner_eq at h
  by_cases hl : a.entries.val.length = b.entries.val.length
  · have hl' : a.entries.len = b.entries.len := by apply UScalar.eq_of_val_eq; simpa using hl
    simp only [hl', bne_self_eq_false, Bool.false_eq_true, ↓reduceIte] at h
    unfold conddata.num_inner_eq_loop at h
    unfold SameNumberCondition
    simp only [hl, true_and]
    refine all_loop (a.entries.val.zip b.entries.val) SameNumberEntry _ (fun i r hi hr => ?_) r h
    have hlen : (a.entries.val.zip b.entries.val).length = a.entries.val.length := by simp [hl]
    unfold conddata.num_inner_eq_loop.body at hr
    h5i_invert hr
    all_goals try
      have hlt : i.val < a.entries.val.length := by scalar_tac
      have hrt : i.val < b.entries.val.length := by omega
      have hf := vec_index_slice_ok_get? hfkv
      have hg := vec_index_slice_ok_get? hfkv1
      rw [List.getElem?_eq_getElem hlt] at hf
      rw [List.getElem?_eq_getElem hrt] at hg
      simp only [Option.some.injEq] at hf hg
      have hzip : (a.entries.val.zip b.entries.val)[i.val]'(by omega) = (fkv, fkv1) := by
        simp only [List.getElem_zip, hf, hg]
      have hk := key_eq_ok _ _ _ (by assumption : conddata.key_eq _ _ = ok _)

    · refine .inl ⟨by omega, ?_, rfl⟩
      rw [hzip]; intro hh
      have hh' : fkv.values = fkv1.values := hh.2
      simp [hh'] at hc_2
    · refine ⟨by omega, ?_, by have := add_ok_val hi2; scalar_tac⟩
      rw [hzip]; refine ⟨hk.1 hc_1, ?_⟩
      apply IScalar.eq_of_val_eq; simpa using hc_2
    · refine .inl ⟨by omega, ?_, rfl⟩
      rw [hzip]; intro hh; exact hc_1 (hk.2 hh.1)
    · exact .inr ⟨by scalar_tac, rfl⟩
  · have hl' : a.entries.len ≠ b.entries.len := by intro hh; apply hl; exact congrArg UScalar.val hh
    simp [hl', bne_iff_ne] at h
    subst r; simp [SameNumberCondition, hl]
theorem date_inner_ok (a b : conddata.InnerFunc conddata.DateFuncValue)
    (r : Bool) (h : conddata.date_inner_eq a b = ok r) : (r = true ↔ SameDateCondition a b) := by
  unfold conddata.date_inner_eq at h
  by_cases hl : a.entries.val.length = b.entries.val.length
  · have hl' : a.entries.len = b.entries.len := by apply UScalar.eq_of_val_eq; simpa using hl
    simp only [hl', bne_self_eq_false, Bool.false_eq_true, ↓reduceIte] at h
    unfold conddata.date_inner_eq_loop at h
    unfold SameDateCondition
    simp only [hl, true_and]
    refine all_loop (a.entries.val.zip b.entries.val) SameDateEntry _ (fun i r hi hr => ?_) r h
    have hlen : (a.entries.val.zip b.entries.val).length = a.entries.val.length := by simp [hl]
    unfold conddata.date_inner_eq_loop.body at hr
    h5i_invert hr
    all_goals try
      have hlt : i.val < a.entries.val.length := by scalar_tac
      have hrt : i.val < b.entries.val.length := by omega
      have hf := vec_index_slice_ok_get? hfkv
      have hg := vec_index_slice_ok_get? hfkv1
      rw [List.getElem?_eq_getElem hlt] at hf
      rw [List.getElem?_eq_getElem hrt] at hg
      simp only [Option.some.injEq] at hf hg
      have hzip : (a.entries.val.zip b.entries.val)[i.val]'(by omega) = (fkv, fkv1) := by
        simp only [List.getElem_zip, hf, hg]
      have hk := key_eq_ok _ _ _ (by assumption : conddata.key_eq _ _ = ok _)

    · refine .inl ⟨by omega, ?_, rfl⟩
      rw [hzip]; intro hh
      have hh' : fkv.values.unix_nanos = fkv1.values.unix_nanos := hh.2
      simp [hh'] at hc_2
    · refine ⟨by omega, ?_, by have := add_ok_val hi2; scalar_tac⟩
      rw [hzip]; refine ⟨hk.1 hc_1, ?_⟩
      apply IScalar.eq_of_val_eq; simpa using hc_2
    · refine .inl ⟨by omega, ?_, rfl⟩
      rw [hzip]; intro hh; exact hc_1 (hk.2 hh.1)
    · exact .inr ⟨by scalar_tac, rfl⟩
  · have hl' : a.entries.len ≠ b.entries.len := by intro hh; apply hl; exact congrArg UScalar.val hh
    simp [hl', bne_iff_ne] at h
    subst r; simp [SameDateCondition, hl]

theorem binary_inner_ok (a b : conddata.InnerFunc conddata.BinaryFuncValue)
    (r : Bool) (h : conddata.binary_inner_eq a b = ok r) : (r = true ↔ SameBinaryCondition a b) := by
  unfold conddata.binary_inner_eq at h
  by_cases hl : a.entries.val.length = b.entries.val.length
  · have hl' : a.entries.len = b.entries.len := by apply UScalar.eq_of_val_eq; simpa using hl
    simp only [hl', bne_self_eq_false, Bool.false_eq_true, ↓reduceIte] at h
    unfold conddata.binary_inner_eq_loop at h
    unfold SameBinaryCondition
    simp only [hl, true_and]
    refine all_loop (a.entries.val.zip b.entries.val) SameBinaryEntry _ (fun i r hi hr => ?_) r h
    have hlen : (a.entries.val.zip b.entries.val).length = a.entries.val.length := by simp [hl]
    unfold conddata.binary_inner_eq_loop.body at hr
    h5i_invert hr
    all_goals try
      have hlt : i.val < a.entries.val.length := by scalar_tac
      have hrt : i.val < b.entries.val.length := by omega
      have hf := vec_index_slice_ok_get? hfkv
      have hg := vec_index_slice_ok_get? hfkv1
      rw [List.getElem?_eq_getElem hlt] at hf
      rw [List.getElem?_eq_getElem hrt] at hg
      simp only [Option.some.injEq] at hf hg
      have hzip : (a.entries.val.zip b.entries.val)[i.val]'(by omega) = (fkv, fkv1) := by
        simp only [List.getElem_zip, hf, hg]
      have hk := key_eq_ok _ _ _ (by assumption : conddata.key_eq _ _ = ok _)
      try have hs := binary_eq_ok _ _ _ (by assumption : conddata.binary_eq _ _ = ok _)
      try simp only [deref_val] at hs
    · refine ⟨by omega, ?_, by have := add_ok_val hi2; scalar_tac⟩
      rw [hzip]; exact ⟨hk.1 hc_1, hs.1 hc_2⟩
    · refine .inl ⟨by omega, ?_, rfl⟩
      rw [hzip]; intro hh; exact hc_2 (hs.2 hh.2)
    · refine .inl ⟨by omega, ?_, rfl⟩
      rw [hzip]; intro hh; exact hc_1 (hk.2 hh.1)
    · exact .inr ⟨by scalar_tac, rfl⟩
  · have hl' : a.entries.len ≠ b.entries.len := by intro hh; apply hl; exact congrArg UScalar.val hh
    simp [hl', bne_iff_ne] at h
    subst r; simp [SameBinaryCondition, hl]

end rustfs_kernel.Verified.RustfsConditionEquality
