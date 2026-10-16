import SpecActionTables
import Verified.RustfsCleanCanonical
import Verified.RustfsForceDelete
import Verified.RustfsValids
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsForceDelete (lift_slice)


namespace rustfs_kernel.Verified.RustfsActionTables
set_option maxRecDepth 4096
set_option maxHeartbeats 1000000

/-- Data-table characterization of the s3_name_0 chunk. -/
theorem s3_name_0_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.s3_name_0 i = ok v) :
    nats v.val = if 0 ≤ i.val ∧ i.val < 16 then (s3ActionNames[i.val]?).getD [] else [] := by
  unfold actsets.s3_name_0 at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (0 ≤ i.val ∧ i.val < 16) := by omega
    rw [if_neg hb]
    rfl

/-- Data-table characterization of the s3_name_1 chunk. -/
theorem s3_name_1_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.s3_name_1 i = ok v) :
    nats v.val = if 16 ≤ i.val ∧ i.val < 32 then (s3ActionNames[i.val]?).getD [] else [] := by
  unfold actsets.s3_name_1 at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (16 ≤ i.val ∧ i.val < 32) := by omega
    rw [if_neg hb]
    rfl

/-- Data-table characterization of the s3_name_2 chunk. -/
theorem s3_name_2_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.s3_name_2 i = ok v) :
    nats v.val = if 32 ≤ i.val ∧ i.val < 48 then (s3ActionNames[i.val]?).getD [] else [] := by
  unfold actsets.s3_name_2 at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (32 ≤ i.val ∧ i.val < 48) := by omega
    rw [if_neg hb]
    rfl

/-- Data-table characterization of the s3_name_3 chunk. -/
theorem s3_name_3_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.s3_name_3 i = ok v) :
    nats v.val = if 48 ≤ i.val ∧ i.val < 64 then (s3ActionNames[i.val]?).getD [] else [] := by
  unfold actsets.s3_name_3 at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (48 ≤ i.val ∧ i.val < 64) := by omega
    rw [if_neg hb]
    rfl

/-- Data-table characterization of the s3_name_4 chunk. -/
theorem s3_name_4_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.s3_name_4 i = ok v) :
    nats v.val = if 64 ≤ i.val ∧ i.val < 71 then (s3ActionNames[i.val]?).getD [] else [] := by
  unfold actsets.s3_name_4 at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (64 ≤ i.val ∧ i.val < 71) := by omega
    rw [if_neg hb]
    rfl

/-- Data-table characterization of the admin_name_0 chunk. -/
theorem admin_name_0_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.admin_name_0 i = ok v) :
    nats v.val = if 0 ≤ i.val ∧ i.val < 16 then (adminActionNames[i.val]?).getD [] else [] := by
  unfold actsets.admin_name_0 at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (0 ≤ i.val ∧ i.val < 16) := by omega
    rw [if_neg hb]
    rfl

/-- Data-table characterization of the admin_name_1 chunk. -/
theorem admin_name_1_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.admin_name_1 i = ok v) :
    nats v.val = if 16 ≤ i.val ∧ i.val < 32 then (adminActionNames[i.val]?).getD [] else [] := by
  unfold actsets.admin_name_1 at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (16 ≤ i.val ∧ i.val < 32) := by omega
    rw [if_neg hb]
    rfl

/-- Data-table characterization of the admin_name_2 chunk. -/
theorem admin_name_2_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.admin_name_2 i = ok v) :
    nats v.val = if 32 ≤ i.val ∧ i.val < 48 then (adminActionNames[i.val]?).getD [] else [] := by
  unfold actsets.admin_name_2 at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (32 ≤ i.val ∧ i.val < 48) := by omega
    rw [if_neg hb]
    rfl

/-- Data-table characterization of the admin_name_3 chunk. -/
theorem admin_name_3_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.admin_name_3 i = ok v) :
    nats v.val = if 48 ≤ i.val ∧ i.val < 64 then (adminActionNames[i.val]?).getD [] else [] := by
  unfold actsets.admin_name_3 at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (48 ≤ i.val ∧ i.val < 64) := by omega
    rw [if_neg hb]
    rfl

/-- Data-table characterization of the admin_name_4 chunk. -/
theorem admin_name_4_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.admin_name_4 i = ok v) :
    nats v.val = if 64 ≤ i.val ∧ i.val < 80 then (adminActionNames[i.val]?).getD [] else [] := by
  unfold actsets.admin_name_4 at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (64 ≤ i.val ∧ i.val < 80) := by omega
    rw [if_neg hb]
    rfl

/-- Data-table characterization of the admin_name_5 chunk. -/
theorem admin_name_5_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.admin_name_5 i = ok v) :
    nats v.val = if 80 ≤ i.val ∧ i.val < 91 then (adminActionNames[i.val]?).getD [] else [] := by
  unfold actsets.admin_name_5 at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (80 ≤ i.val ∧ i.val < 91) := by omega
    rw [if_neg hb]
    rfl

/-- Data-table characterization of the sts_name chunk. -/
theorem sts_name_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.sts_name i = ok v) :
    nats v.val = if 0 ≤ i.val ∧ i.val < 2 then (stsActionNames[i.val]?).getD [] else [] := by
  unfold actsets.sts_name at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (0 ≤ i.val ∧ i.val < 2) := by omega
    rw [if_neg hb]
    rfl

/-- Data-table characterization of the kms_name_0 chunk. -/
theorem kms_name_0_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.kms_name_0 i = ok v) :
    nats v.val = if 0 ≤ i.val ∧ i.val < 16 then (kmsActionNames[i.val]?).getD [] else [] := by
  unfold actsets.kms_name_0 at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (0 ≤ i.val ∧ i.val < 16) := by omega
    rw [if_neg hb]
    rfl

/-- Data-table characterization of the kms_name_1 chunk. -/
theorem kms_name_1_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.kms_name_1 i = ok v) :
    nats v.val = if 16 ≤ i.val ∧ i.val < 18 then (kmsActionNames[i.val]?).getD [] else [] := by
  unfold actsets.kms_name_1 at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (16 ≤ i.val ∧ i.val < 18) := by omega
    rw [if_neg hb]
    rfl

theorem s3_name_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.s3_name i = ok v) :
    nats v.val = (s3ActionNames[i.val]?).getD [] := by
  unfold actsets.s3_name at h
  h5i_invert h
  case h_1 =>
    have hd := div_ok_val hi_1
    rw [s3_name_0_ok i v h]
    by_cases hb : 0 ≤ i.val ∧ i.val < 16
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hlen : 71 ≤ i.val := by scalar_tac
      rw [List.getElem?_eq_none (by simpa only [s3ActionNames, List.length_cons, List.length_nil] using hlen)]
      rfl
  case h_2 =>
    have hd := div_ok_val hi_1
    rw [s3_name_1_ok i v h]
    by_cases hb : 16 ≤ i.val ∧ i.val < 32
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hlen : 71 ≤ i.val := by scalar_tac
      rw [List.getElem?_eq_none (by simpa only [s3ActionNames, List.length_cons, List.length_nil] using hlen)]
      rfl
  case h_3 =>
    have hd := div_ok_val hi_1
    rw [s3_name_2_ok i v h]
    by_cases hb : 32 ≤ i.val ∧ i.val < 48
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hlen : 71 ≤ i.val := by scalar_tac
      rw [List.getElem?_eq_none (by simpa only [s3ActionNames, List.length_cons, List.length_nil] using hlen)]
      rfl
  case h_4 =>
    have hd := div_ok_val hi_1
    rw [s3_name_3_ok i v h]
    by_cases hb : 48 ≤ i.val ∧ i.val < 64
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hlen : 71 ≤ i.val := by scalar_tac
      rw [List.getElem?_eq_none (by simpa only [s3ActionNames, List.length_cons, List.length_nil] using hlen)]
      rfl
  case h_5 =>
    have hd := div_ok_val hi_1
    rw [s3_name_4_ok i v h]
    by_cases hb : 64 ≤ i.val ∧ i.val < 71
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hlen : 71 ≤ i.val := by scalar_tac
      rw [List.getElem?_eq_none (by simpa only [s3ActionNames, List.length_cons, List.length_nil] using hlen)]
      rfl
  case h_6 =>
    simp only [imp_false] at *
    have hd := div_ok_val hi_1
    have hlen : 71 ≤ i.val := by scalar_tac
    rw [List.getElem?_eq_none (by simpa only [s3ActionNames, List.length_cons, List.length_nil] using hlen)]
    rfl

theorem admin_name_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.admin_name i = ok v) :
    nats v.val = (adminActionNames[i.val]?).getD [] := by
  unfold actsets.admin_name at h
  h5i_invert h
  case h_1 =>
    have hd := div_ok_val hi_1
    rw [admin_name_0_ok i v h]
    by_cases hb : 0 ≤ i.val ∧ i.val < 16
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hlen : 91 ≤ i.val := by scalar_tac
      rw [List.getElem?_eq_none (by simpa only [adminActionNames, List.length_cons, List.length_nil] using hlen)]
      rfl
  case h_2 =>
    have hd := div_ok_val hi_1
    rw [admin_name_1_ok i v h]
    by_cases hb : 16 ≤ i.val ∧ i.val < 32
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hlen : 91 ≤ i.val := by scalar_tac
      rw [List.getElem?_eq_none (by simpa only [adminActionNames, List.length_cons, List.length_nil] using hlen)]
      rfl
  case h_3 =>
    have hd := div_ok_val hi_1
    rw [admin_name_2_ok i v h]
    by_cases hb : 32 ≤ i.val ∧ i.val < 48
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hlen : 91 ≤ i.val := by scalar_tac
      rw [List.getElem?_eq_none (by simpa only [adminActionNames, List.length_cons, List.length_nil] using hlen)]
      rfl
  case h_4 =>
    have hd := div_ok_val hi_1
    rw [admin_name_3_ok i v h]
    by_cases hb : 48 ≤ i.val ∧ i.val < 64
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hlen : 91 ≤ i.val := by scalar_tac
      rw [List.getElem?_eq_none (by simpa only [adminActionNames, List.length_cons, List.length_nil] using hlen)]
      rfl
  case h_5 =>
    have hd := div_ok_val hi_1
    rw [admin_name_4_ok i v h]
    by_cases hb : 64 ≤ i.val ∧ i.val < 80
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hlen : 91 ≤ i.val := by scalar_tac
      rw [List.getElem?_eq_none (by simpa only [adminActionNames, List.length_cons, List.length_nil] using hlen)]
      rfl
  case h_6 =>
    have hd := div_ok_val hi_1
    rw [admin_name_5_ok i v h]
    by_cases hb : 80 ≤ i.val ∧ i.val < 91
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hlen : 91 ≤ i.val := by scalar_tac
      rw [List.getElem?_eq_none (by simpa only [adminActionNames, List.length_cons, List.length_nil] using hlen)]
      rfl
  case h_7 =>
    simp only [imp_false] at *
    have hd := div_ok_val hi_1
    have hlen : 91 ≤ i.val := by scalar_tac
    rw [List.getElem?_eq_none (by simpa only [adminActionNames, List.length_cons, List.length_nil] using hlen)]
    rfl

theorem kms_name_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.kms_name i = ok v) :
    nats v.val = (kmsActionNames[i.val]?).getD [] := by
  unfold actsets.kms_name at h
  h5i_invert h
  case h_1 =>
    have hd := div_ok_val hi_1
    rw [kms_name_0_ok i v h]
    by_cases hb : 0 ≤ i.val ∧ i.val < 16
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hlen : 18 ≤ i.val := by scalar_tac
      rw [List.getElem?_eq_none (by simpa only [kmsActionNames, List.length_cons, List.length_nil] using hlen)]
      rfl
  case h_2 =>
    have hd := div_ok_val hi_1
    rw [kms_name_1_ok i v h]
    by_cases hb : 16 ≤ i.val ∧ i.val < 18
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hlen : 18 ≤ i.val := by scalar_tac
      rw [List.getElem?_eq_none (by simpa only [kmsActionNames, List.length_cons, List.length_nil] using hlen)]
      rfl
  case h_3 =>
    simp only [imp_false] at *
    have hd := div_ok_val hi_1
    have hlen : 18 ≤ i.val := by scalar_tac
    rw [List.getElem?_eq_none (by simpa only [kmsActionNames, List.length_cons, List.length_nil] using hlen)]
    rfl

theorem action_name_ok (f : acts.Family) (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.action_name f i = ok v) :
    nats v.val = ((actionNames f)[i.val]?).getD [] := by
  cases f with
  | S3 => exact s3_name_ok i v h
  | Admin => exact admin_name_ok i v h
  | Kms => exact kms_name_ok i v h
  | Sts =>
    have hs := sts_name_ok i v h
    change nats v.val = (stsActionNames[i.val]?).getD []
    rw [hs]
    by_cases hb : 0 ≤ i.val ∧ i.val < 2
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hi : 2 ≤ i.val := by omega
      rw [List.getElem?_eq_none (by simpa only [stsActionNames, List.length_cons, List.length_nil] using hi)]
      rfl
  | None =>
    simp only [actsets.action_name, Result.ok.injEq] at h
    subst v
    rfl

theorem count_ok (f : acts.Family) (n : Usize) (h : actsets.action_count f = ok n) :
    n.val = (actionNames f).length := by
  cases f <;> simp only [actsets.action_count, Result.ok.injEq] at h <;> subst n <;> rfl

theorem table_counts :
    (s3ActionNames.length = 71 ∧ adminActionNames.length = 91 ∧
      stsActionNames.length = 2 ∧ kmsActionNames.length = 18) := by decide +kernel

theorem table_distinct (f : acts.Family) : (actionNames f).Nodup := by
  cases f <;> decide +kernel

theorem table_prefixes (f : acts.Family) :
    ∀ n ∈ actionNames f, familyPrefix f <+: n ∧ n ≠ [] := by
  cases f <;> decide +kernel

theorem contains_name_ok (f : acts.Family) (needle : Slice U8) (b : Bool)
    (h : actsets.contains_name f needle = ok b) :
    (b = true ↔ nats needle.val ∈ actionNames f) := by
  unfold actsets.contains_name actsets.contains_name_loop at h
  have hh : b = true ↔ ∃ n ∈ actionNames f, n = nats needle.val := by
    refine rustfs_kernel.Verified.RustfsValids.any_loop _ _ _ (fun i r _ hr => ?_) b h
    unfold actsets.contains_name_loop.body at hr
    h5i_invert hr
    · have hn := count_ok _ _ hi1
      have hlt : i.val < (actionNames f).length := by scalar_tac
      have ht := action_name_ok _ _ _ hv
      rw [List.getElem?_eq_getElem hlt] at ht
      simp only [Option.getD_some] at ht
      have hb := rustfs_kernel.Verified.RustfsForceDelete.bytes_eq_ok _ _ _ (by assumption)
      rw [rustfs_kernel.Verified.RustfsForceDelete.deref_val] at hb
      exact .inl ⟨hlt, by rw [← ht, hb.1 hc_1], rfl⟩
    · have hn := count_ok _ _ hi1
      have hlt : i.val < (actionNames f).length := by scalar_tac
      have ht := action_name_ok _ _ _ hv
      rw [List.getElem?_eq_getElem hlt] at ht
      simp only [Option.getD_some] at ht
      have hb := rustfs_kernel.Verified.RustfsForceDelete.bytes_eq_ok _ _ _ (by assumption)
      rw [rustfs_kernel.Verified.RustfsForceDelete.deref_val] at hb
      refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
      intro hh
      apply hc_1
      apply hb.2
      apply rustfs_kernel.Verified.RustfsForceDelete.nats_inj
      rw [ht, hh]
    · have hn := count_ok _ _ hi1
      exact .inr ⟨by scalar_tac, rfl⟩
  simpa using hh

theorem admin_valid_ok (needle : Slice U8) (b : Bool)
    (h : actsets.admin_is_valid needle = ok b) :
    (b = true ↔ nats needle.val ∈ adminActionNames) :=
  contains_name_ok .Admin needle b h

end rustfs_kernel.Verified.RustfsActionTables
