import Verified.RustfsConditionEquality
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsCondData
open rustfs_kernel.Verified.RustfsConditionEquality
open rustfs_kernel.Verified.RustfsForceDelete (deref_val)
deriving instance DecidableEq for condfuncs.IpAddr

namespace rustfs_kernel.Verified.RustfsCompleteConditionEquality
 theorem ip_eq_law (a b : condfuncs.IpAddr) :
    condfuncs.IpAddr.Insts.CoreCmpPartialEqIpAddr.eq a b = ok (decide (a = b)) := by
  cases a <;> cases b <;> simp [condfuncs.IpAddr.Insts.CoreCmpPartialEqIpAddr.eq,
    condfuncs.IpAddr.read_discriminant, lift]

theorem zip_all_eq_iff {T : Type} [DecidableEq T] (l r : List T) (hl : l.length = r.length) :
    (∀ p ∈ l.zip r, p.1 = p.2) ↔ l = r := by
  have hh := zip_eq l r hl
  have hh' := congrArg (fun b => b = true) hh
  simpa using hh'

theorem addr_pairs_ok (l r : Slice (condfuncs.IpAddr × U8)) (b : Bool)
    (h : conddata.addr_pairs_eq l r = ok b) : (b = true ↔ l.val = r.val) := by
  unfold conddata.addr_pairs_eq at h
  by_cases hl : l.val.length = r.val.length
  · have hl' : l.len = r.len := by apply UScalar.eq_of_val_eq; simpa using hl
    simp only [hl', bne_self_eq_false, Bool.false_eq_true, ↓reduceIte] at h
    unfold conddata.addr_pairs_eq_loop at h
    rw [← zip_all_eq_iff l.val r.val hl]
    refine all_loop (l.val.zip r.val) (fun p => p.1 = p.2) _ (fun i out hi hr => ?_) b h
    have hlen : (l.val.zip r.val).length = l.val.length := by simp [hl]
    unfold conddata.addr_pairs_eq_loop.body at hr
    h5i_invert hr
    · rcases x with ⟨ip, width⟩
      change (do
        let pair ← Slice.index_usize r i
        let equal ← condfuncs.IpAddr.Insts.CoreCmpPartialEqIpAddr.eq ip pair.1
        if equal then
          if width != pair.2 then ok (.done false)
          else
            let next ← i + 1#usize
            ok (.cont next)
        else ok (.done false)) = ok out at hr
      h5i_invert hr
      all_goals
        obtain ⟨hlt, he⟩ := slice_index_ok hx
        obtain ⟨hrt, hg⟩ := slice_index_ok hpair
        have hz : (l.val.zip r.val)[i.val]'(by omega) = ((ip, width), pair) := by
          simp only [List.getElem_zip, he, hg]
        rw [ip_eq_law] at hequal
        simp only [Result.ok.injEq] at hequal
      · refine .inl ⟨by omega, ?_, rfl⟩
        rw [hz]; dsimp only
        intro hh
        have hw : width = pair.2 := congrArg Prod.snd hh
        simp [hw] at hc_2
      · refine ⟨by omega, ?_, by have := add_ok_val hnext; scalar_tac⟩
        rw [hz]; dsimp only
        apply Prod.ext
        · exact of_decide_eq_true (hequal.trans hc_1)
        · apply UScalar.eq_of_val_eq; simpa using hc_2
      · refine .inl ⟨by omega, ?_, rfl⟩
        rw [hz]; dsimp only
        intro hh
        have hip : ip = pair.1 := congrArg Prod.fst hh
        apply hc_1
        rw [← hequal]; simp [hip]
    · exact .inr ⟨by scalar_tac, rfl⟩
  · have hl' : l.len ≠ r.len := fun hh => hl (congrArg UScalar.val hh)
    simp [hl', bne_iff_ne] at h
    subst b
    simp only [Bool.false_eq_true, false_iff]
    intro hh; exact hl (congrArg List.length hh)
theorem bool_inner_ok (a b : conddata.InnerFunc Bool)
    (r : Bool) (h : conddata.bool_inner_eq a b = ok r) : (r = true ↔ SameBoolCondition a b) := by
  unfold conddata.bool_inner_eq at h
  by_cases hl : a.entries.val.length = b.entries.val.length
  · have hl' : a.entries.len = b.entries.len := by apply UScalar.eq_of_val_eq; simpa using hl
    simp only [hl', bne_self_eq_false, Bool.false_eq_true, ↓reduceIte] at h
    unfold conddata.bool_inner_eq_loop at h
    unfold SameBoolCondition
    simp only [hl, true_and]
    refine all_loop (a.entries.val.zip b.entries.val) SameBoolEntry _ (fun i r hi hr => ?_) r h
    have hlen : (a.entries.val.zip b.entries.val).length = a.entries.val.length := by simp [hl]
    unfold conddata.bool_inner_eq_loop.body at hr
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

    · refine ⟨by omega, ?_, by have := add_ok_val hi2; scalar_tac⟩
      rw [hzip]; refine ⟨hk.1 hc_1, ?_⟩
      simp_all [SameBoolEntry]
    · refine .inl ⟨by omega, ?_, rfl⟩
      rw [hzip]; intro hh
      simp_all [SameBoolEntry]
    · refine .inl ⟨by omega, ?_, rfl⟩
      rw [hzip]; intro hh
      simp_all [SameBoolEntry]
    · refine ⟨by omega, ?_, by have := add_ok_val hi2; scalar_tac⟩
      rw [hzip]; refine ⟨hk.1 hc_1, ?_⟩
      simp_all [SameBoolEntry]
    · refine .inl ⟨by omega, ?_, rfl⟩
      rw [hzip]; intro hh; exact hc_1 (hk.2 hh.1)
    · exact .inr ⟨by scalar_tac, rfl⟩
  · have hl' : a.entries.len ≠ b.entries.len := by intro hh; apply hl; exact congrArg UScalar.val hh
    simp [hl', bne_iff_ne] at h
    subst r; simp [SameBoolCondition, hl]

theorem addr_inner_ok (a b : conddata.InnerFunc (alloc.vec.Vec (condfuncs.IpAddr × U8)))
    (r : Bool) (h : conddata.addr_inner_eq a b = ok r) : (r = true ↔ SameAddrCondition a b) := by
  unfold conddata.addr_inner_eq at h
  by_cases hl : a.entries.val.length = b.entries.val.length
  · have hl' : a.entries.len = b.entries.len := by apply UScalar.eq_of_val_eq; simpa using hl
    simp only [hl', bne_self_eq_false, Bool.false_eq_true, ↓reduceIte] at h
    unfold conddata.addr_inner_eq_loop at h
    unfold SameAddrCondition
    simp only [hl, true_and]
    refine all_loop (a.entries.val.zip b.entries.val) SameAddrEntry _ (fun i r hi hr => ?_) r h
    have hlen : (a.entries.val.zip b.entries.val).length = a.entries.val.length := by simp [hl]
    unfold conddata.addr_inner_eq_loop.body at hr
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
      try have hs := addr_pairs_ok _ _ _ (by assumption : conddata.addr_pairs_eq _ _ = ok _)
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
    subst r; simp [SameAddrCondition, hl]
theorem op_eq_law (a b : conddata.Op) :
    conddata.Op.Insts.CoreCmpPartialEqOp.eq a b = ok (decide (a = b)) := by
  cases a <;> cases b <;> simp [conddata.Op.Insts.CoreCmpPartialEqOp.eq, conddata.Op.read_discriminant]

set_option maxHeartbeats 2000000 in
theorem condition_eq_ok (a b : conddata.Condition) (r : Bool)
    (h : conddata.condition_eq a b = ok r) : (r = true ↔ SameCondition a b) := by
  unfold conddata.condition_eq core.cmp.PartialEq.ne.trait_default core.cmp.PartialEq.ne.default at h
  simp only [conddata.Op.Insts.CoreCmpPartialEqOp, op_eq_law, bind_tc_ok, bind_ok] at h
  by_cases hop : a.op = b.op
  · by_cases hw : a.wrappers = b.wrappers
    · simp [hop, hw] at h
      unfold SameCondition
      simp only [hop, hw, true_and]
      cases ha : a.data <;> cases hb : b.data <;> simp only [ha, hb] at h ⊢
      all_goals first
        | (simpa only [SameConditionData] using string_inner_ok _ _ _ h)
        | (simpa only [SameConditionData] using addr_inner_ok _ _ _ h)
        | (simpa only [SameConditionData] using bool_inner_ok _ _ _ h)
        | (simpa only [SameConditionData] using num_inner_ok _ _ _ h)
        | (simpa only [SameConditionData] using date_inner_ok _ _ _ h)
        | (simpa only [SameConditionData] using binary_inner_ok _ _ _ h)
        | (simp only [Result.ok.injEq] at h; subst r; simp [SameConditionData])
    · simp [hop, hw] at h
      subst r; simp [SameCondition, hw]
  · simp [hop] at h
    subst r; simp [SameCondition, hop]
end rustfs_kernel.Verified.RustfsCompleteConditionEquality
