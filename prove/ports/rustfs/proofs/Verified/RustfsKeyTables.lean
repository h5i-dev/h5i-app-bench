import SpecKeyTables
import Verified.RustfsActionTables
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsForceDelete (lift_slice)
namespace rustfs_kernel.Verified.RustfsKeyTables
set_option maxRecDepth 4096
set_option maxHeartbeats 1000000

/-- Data-table characterization. -/
theorem s3_name_0_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : keytables.s3_name_0 i = ok v) :
    nats v.val = if 0 ≤ i.val ∧ i.val < 16 then (s3KeyNames[i.val]?).getD [] else [] := by
  unfold keytables.s3_name_0 at h
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

/-- Data-table characterization. -/
theorem s3_name_1_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : keytables.s3_name_1 i = ok v) :
    nats v.val = if 16 ≤ i.val ∧ i.val < 26 then (s3KeyNames[i.val]?).getD [] else [] := by
  unfold keytables.s3_name_1 at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (16 ≤ i.val ∧ i.val < 26) := by omega
    rw [if_neg hb]
    rfl

theorem s3_name_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : keytables.s3_name i = ok v) :
    nats v.val = (s3KeyNames[i.val]?).getD [] := by
  unfold keytables.s3_name at h
  h5i_invert h
  case h_1 =>
    have hd := div_ok_val hi_1
    rw [s3_name_0_ok i v h]
    by_cases hb : 0 ≤ i.val ∧ i.val < 16
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hlen : 26 ≤ i.val := by scalar_tac
      rw [List.getElem?_eq_none (by simpa only [s3KeyNames, List.length_cons, List.length_nil] using hlen)]
      rfl
  case h_2 =>
    have hd := div_ok_val hi_1
    rw [s3_name_1_ok i v h]
    by_cases hb : 16 ≤ i.val ∧ i.val < 26
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hlen : 26 ≤ i.val := by scalar_tac
      rw [List.getElem?_eq_none (by simpa only [s3KeyNames, List.length_cons, List.length_nil] using hlen)]
      rfl
  case h_3 =>
    simp only [imp_false] at *
    have hd := div_ok_val hi_1
    have hlen : 26 ≤ i.val := by scalar_tac
    rw [List.getElem?_eq_none (by simpa only [s3KeyNames, List.length_cons, List.length_nil] using hlen)]
    rfl

/-- Data-table characterization. -/
theorem jwt_name_0_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : keytables.jwt_name_0 i = ok v) :
    nats v.val = if 0 ≤ i.val ∧ i.val < 16 then (jwtKeyNames[i.val]?).getD [] else [] := by
  unfold keytables.jwt_name_0 at h
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

/-- Data-table characterization. -/
theorem jwt_name_1_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : keytables.jwt_name_1 i = ok v) :
    nats v.val = if 16 ≤ i.val ∧ i.val < 23 then (jwtKeyNames[i.val]?).getD [] else [] := by
  unfold keytables.jwt_name_1 at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (16 ≤ i.val ∧ i.val < 23) := by omega
    rw [if_neg hb]
    rfl

theorem jwt_name_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : keytables.jwt_name i = ok v) :
    nats v.val = (jwtKeyNames[i.val]?).getD [] := by
  unfold keytables.jwt_name at h
  h5i_invert h
  case h_1 =>
    have hd := div_ok_val hi_1
    rw [jwt_name_0_ok i v h]
    by_cases hb : 0 ≤ i.val ∧ i.val < 16
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hlen : 23 ≤ i.val := by scalar_tac
      rw [List.getElem?_eq_none (by simpa only [jwtKeyNames, List.length_cons, List.length_nil] using hlen)]
      rfl
  case h_2 =>
    have hd := div_ok_val hi_1
    rw [jwt_name_1_ok i v h]
    by_cases hb : 16 ≤ i.val ∧ i.val < 23
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hlen : 23 ≤ i.val := by scalar_tac
      rw [List.getElem?_eq_none (by simpa only [jwtKeyNames, List.length_cons, List.length_nil] using hlen)]
      rfl
  case h_3 =>
    simp only [imp_false] at *
    have hd := div_ok_val hi_1
    have hlen : 23 ≤ i.val := by scalar_tac
    rw [List.getElem?_eq_none (by simpa only [jwtKeyNames, List.length_cons, List.length_nil] using hlen)]
    rfl

/-- Data-table characterization. -/
theorem svc_name_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : keytables.svc_name i = ok v) :
    nats v.val = if 0 ≤ i.val ∧ i.val < 1 then (svcKeyNames[i.val]?).getD [] else [] := by
  unfold keytables.svc_name at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (0 ≤ i.val ∧ i.val < 1) := by omega
    rw [if_neg hb]
    rfl

/-- Data-table characterization. -/
theorem ldap_name_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : keytables.ldap_name i = ok v) :
    nats v.val = if 0 ≤ i.val ∧ i.val < 3 then (ldapKeyNames[i.val]?).getD [] else [] := by
  unfold keytables.ldap_name at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (0 ≤ i.val ∧ i.val < 3) := by omega
    rw [if_neg hb]
    rfl

/-- Data-table characterization. -/
theorem sts_name_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : keytables.sts_name i = ok v) :
    nats v.val = if 0 ≤ i.val ∧ i.val < 1 then (stsKeyNames[i.val]?).getD [] else [] := by
  unfold keytables.sts_name at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (0 ≤ i.val ∧ i.val < 1) := by omega
    rw [if_neg hb]
    rfl

/-- Data-table characterization. -/
theorem aws_name_ok (i : Usize) (v : alloc.vec.Vec U8)
    (h : keytables.aws_name i = ok v) :
    nats v.val = if 0 ≤ i.val ∧ i.val < 12 then (awsKeyNames[i.val]?).getD [] else [] := by
  unfold keytables.aws_name at h
  h5i_invert h
  all_goals try
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h]
    rw [lift_slice hs, hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hb : ¬ (0 ≤ i.val ∧ i.val < 12) := by omega
    rw [if_neg hb]
    rfl

theorem key_name_ok (f : keytables.KeyFamily) (i : Usize) (v : alloc.vec.Vec U8)
    (h : keytables.key_name f i = ok v) : nats v.val = ((keyNames f)[i.val]?).getD [] := by
  cases f with
  | S3 =>
    exact s3_name_ok i v h
  | Jwt =>
    exact jwt_name_ok i v h
  | Svc =>
    have hs := svc_name_ok i v h
    change nats v.val = (svcKeyNames[i.val]?).getD []
    rw [hs]
    by_cases hb : 0 ≤ i.val ∧ i.val < 1
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hi : 1 ≤ i.val := by omega
      rw [List.getElem?_eq_none (by simpa only [svcKeyNames, List.length_cons, List.length_nil] using hi)]
      rfl
  | Ldap =>
    have hs := ldap_name_ok i v h
    change nats v.val = (ldapKeyNames[i.val]?).getD []
    rw [hs]
    by_cases hb : 0 ≤ i.val ∧ i.val < 3
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hi : 3 ≤ i.val := by omega
      rw [List.getElem?_eq_none (by simpa only [ldapKeyNames, List.length_cons, List.length_nil] using hi)]
      rfl
  | Sts =>
    have hs := sts_name_ok i v h
    change nats v.val = (stsKeyNames[i.val]?).getD []
    rw [hs]
    by_cases hb : 0 ≤ i.val ∧ i.val < 1
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hi : 1 ≤ i.val := by omega
      rw [List.getElem?_eq_none (by simpa only [stsKeyNames, List.length_cons, List.length_nil] using hi)]
      rfl
  | Aws =>
    have hs := aws_name_ok i v h
    change nats v.val = (awsKeyNames[i.val]?).getD []
    rw [hs]
    by_cases hb : 0 ≤ i.val ∧ i.val < 12
    · rw [if_pos hb]
    · rw [if_neg hb]
      have hi : 12 ≤ i.val := by omega
      rw [List.getElem?_eq_none (by simpa only [awsKeyNames, List.length_cons, List.length_nil] using hi)]
      rfl

theorem count_ok (f : keytables.KeyFamily) (n : Usize) (h : keytables.key_count f = ok n) :
    n.val = (keyNames f).length := by
  cases f <;> simp only [keytables.key_count, Result.ok.injEq] at h <;> subst n <;> rfl

theorem table_distinct (f : keytables.KeyFamily) : (keyNames f).Nodup := by
  cases f <;> decide +kernel

theorem table_prefixes (f : keytables.KeyFamily) :
    ∀ n ∈ keyNames f, keyPrefix f <+: n ∧ n ≠ [] := by
  cases f <;> decide +kernel

theorem contains_name_ok (f : keytables.KeyFamily) (needle : Slice U8) (b : Bool)
    (h : keytables.contains_name f needle = ok b) :
    (b = true ↔ nats needle.val ∈ keyNames f) := by
  unfold keytables.contains_name keytables.contains_name_loop at h
  have hh : b = true ↔ ∃ n ∈ keyNames f, n = nats needle.val := by
    refine rustfs_kernel.Verified.RustfsValids.any_loop _ _ _ (fun i r _ hr => ?_) b h
    unfold keytables.contains_name_loop.body at hr
    h5i_invert hr
    · have hn := count_ok _ _ hi1
      have hlt : i.val < (keyNames f).length := by scalar_tac
      have ht := key_name_ok _ _ _ hv
      rw [List.getElem?_eq_getElem hlt] at ht
      simp only [Option.getD_some] at ht
      have hb := rustfs_kernel.Verified.RustfsForceDelete.bytes_eq_ok _ _ _ (by assumption)
      rw [rustfs_kernel.Verified.RustfsForceDelete.deref_val] at hb
      exact .inl ⟨hlt, by rw [← ht, hb.1 hc_1], rfl⟩
    · have hn := count_ok _ _ hi1
      have hlt : i.val < (keyNames f).length := by scalar_tac
      have ht := key_name_ok _ _ _ hv
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

theorem server_derived_ok (f : keytables.KeyFamily) (needle : Slice U8) (b : Bool)
    (h : keytables.is_server_derived f needle = ok b) :
    (b = true ↔ nats needle.val ∈ keyNames f ∧
      (f ≠ .S3 ∨ ¬ lit "s3:x-amz-" <+: nats needle.val)) := by
  unfold keytables.is_server_derived at h
  h5i_invert h
  · have hm := (contains_name_ok _ _ _ hb_1).1 hc
    have hn : f ≠ .S3 := by
      cases f <;> simp_all [core.cmp.PartialEq.ne.trait_default,core.cmp.PartialEq.ne.default,
        keytables.KeyFamily.Insts.CoreCmpPartialEqKeyFamily,
        keytables.KeyFamily.Insts.CoreCmpPartialEqKeyFamily.eq,keytables.KeyFamily.read_discriminant]
    simp [hm,hn]
  · have hm := (contains_name_ok _ _ _ hb_1).1 hc
    have hf : f = .S3 := by
      cases f <;> simp_all [core.cmp.PartialEq.ne.trait_default,core.cmp.PartialEq.ne.default,
        keytables.KeyFamily.Insts.CoreCmpPartialEqKeyFamily,
        keytables.KeyFamily.Insts.CoreCmpPartialEqKeyFamily.eq,keytables.KeyFamily.read_discriminant]
    have hp : nats s.val = lit "s3:x-amz-" := by rw [lift_slice hs]; decide +kernel
    have hb := rustfs_kernel.Verified.RustfsValids.starts_lit hp hb2
    subst f
    simpa [hm] using not_congr hb
  · have hm : nats needle.val ∉ keyNames f := fun hh => hc ((contains_name_ok _ _ _ hb_1).2 hh)
    simp [hm]
end rustfs_kernel.Verified.RustfsKeyTables
