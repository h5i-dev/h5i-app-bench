import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit
namespace nora_kernel.Solution

theorem u32_max_bv : core.num.U32.MAX.bv = BitVec.allOnes 32 := by
  apply BitVec.toNat_inj.mp; rfl

theorem u128_max_bv : core.num.U128.MAX.bv = BitVec.allOnes 128 := by
  apply BitVec.toNat_inj.mp; rfl

theorem bitvec_and_allOnes_shiftLeft_eq_ushiftRight_eq {w : Nat} (x y : BitVec w) (k : Nat) (hk : k ≤ w) :
    (x &&& (BitVec.allOnes w <<< k) = y &&& (BitVec.allOnes w <<< k)) ↔ (x >>> k = y >>> k) := by
  constructor
  · intro h
    have h_shift : x >>> k <<< k = y >>> k <<< k := by
      rw [BitVec.shiftLeft_ushiftRight, BitVec.shiftLeft_ushiftRight, h]
    rw [BitVec.eq_of_getLsbD_eq_iff]
    intro i hi
    by_cases hik : i < w - k
    · have hki : k + i < w := by omega
      have h1 := congrArg (fun (b : BitVec w) => b.getLsbD (k + i)) h_shift
      simp only [BitVec.getLsbD_shiftLeft] at h1
      have hlt1 : decide (k + i < w) = true := by simp [hki]
      have hge1 : (!decide (k + i < k)) = true := by simp
      have hsub1 : k + i - k = i := by omega
      rw [hlt1, hge1, hsub1] at h1
      simp only [Bool.true_and] at h1
      exact h1
    · have hki : w ≤ k + i := by omega
      simp [hki]
  · intro h
    rw [← BitVec.shiftLeft_ushiftRight, ← BitVec.shiftLeft_ushiftRight, h]

theorem bitvec_and_mask_eq_div_pow_eq {w : Nat} (x y : BitVec w) (k : Nat) (hk : k ≤ w) :
    (x &&& (BitVec.allOnes w <<< k) = y &&& (BitVec.allOnes w <<< k)) ↔ (x.toNat / 2^k = y.toNat / 2^k) := by
  rw [bitvec_and_allOnes_shiftLeft_eq_ushiftRight_eq x y k hk]
  rw [BitVec.toNat_eq]
  simp [BitVec.toNat_ushiftRight, Nat.shiftRight_eq_div_pow]

theorem u32_and_mask_eq_iff (n addr : U32) (mask : U32) (i : Nat) (hi : i ≤ 32)
    (hmask : mask.bv = BitVec.allOnes 32 <<< i) :
    (n &&& mask = addr &&& mask) ↔ (n.val / 2^i = addr.val / 2^i) := by
  have heq : (n &&& mask = addr &&& mask) ↔ (n.bv &&& mask.bv = addr.bv &&& mask.bv) := by
    rw [UScalar.eq_equiv_bv_eq]; rfl
  rw [heq, hmask]
  exact bitvec_and_mask_eq_div_pow_eq n.bv addr.bv i hi

theorem u128_and_mask_eq_iff (n addr : U128) (mask : U128) (i : Nat) (hi : i ≤ 128)
    (hmask : mask.bv = BitVec.allOnes 128 <<< i) :
    (n &&& mask = addr &&& mask) ↔ (n.val / 2^i = addr.val / 2^i) := by
  have heq : (n &&& mask = addr &&& mask) ↔ (n.bv &&& mask.bv = addr.bv &&& mask.bv) := by
    rw [UScalar.eq_equiv_bv_eq]; rfl
  rw [heq, hmask]
  exact bitvec_and_mask_eq_div_pow_eq n.bv addr.bv i hi

@[step]
theorem entry_contains_spec (nw : net.IpAddr) (p : U8) (ip : net.IpAddr) :
    net.entry_contains nw p ip ⦃ b => b = entryContains (nw, p) ip ⦄ := by
  unfold net.entry_contains
  cases nw with
  | V4 n =>
    cases ip with
    | V4 addr =>
      simp only [entryContains, inPrefix]
      by_cases hp0 : p = 0#u8
      · simp [hp0]
      · have hp0_val : p.val ≠ 0 := by
          intro h; apply hp0; apply UScalar.eq_of_val_eq; exact h
        by_cases hp32 : p ≥ 32#u8
        · have hp32_val : 32 ≤ p.val := by scalar_tac
          rw [if_neg hp0, if_pos hp32]
          rw [if_neg hp0_val, if_pos hp32_val]
          step*
        · have hp32_val : ¬ (32 ≤ p.val) := by
            intro h; apply hp32; scalar_tac
          rw [if_neg hp0, if_neg hp32]
          rw [if_neg hp0_val, if_neg hp32_val]
          step*
          have hi_le : i.val ≤ 32 := by scalar_tac
          have hmask_bv : mask.bv = BitVec.allOnes 32 <<< i.val := by
            exact mask_post1.trans (by rw [u32_max_bv])
          have h_iff := u32_and_mask_eq_iff n addr mask i.val hi_le hmask_bv
          have hi12 : (i1 = i2) ↔ (n &&& mask = addr &&& mask) := by
            rw [UScalar.eq_equiv_bv_eq, i1_post1, i2_post1]
            rw [UScalar.eq_equiv_bv_eq]
            rfl
          have h_all : (i1 = i2) ↔ (n.val / 2 ^ (32 - p.val) = addr.val / 2 ^ (32 - p.val)) := by
            rw [hi12, h_iff, i_post]
          simp [h_all]
    | V6 _ =>
      simp only [entryContains]; step*
  | V6 n =>
    cases ip with
    | V4 _ =>
      simp only [entryContains]; step*
    | V6 addr =>
      simp only [entryContains, inPrefix]
      by_cases hp0 : p = 0#u8
      · simp [hp0]
      · have hp0_val : p.val ≠ 0 := by
          intro h; apply hp0; apply UScalar.eq_of_val_eq; exact h
        by_cases hp128 : p ≥ 128#u8
        · have hp128_val : 128 ≤ p.val := by scalar_tac
          rw [if_neg hp0, if_pos hp128]
          rw [if_neg hp0_val, if_pos hp128_val]
          step*
        · have hp128_val : ¬ (128 ≤ p.val) := by
            intro h; apply hp128; scalar_tac
          rw [if_neg hp0, if_neg hp128]
          rw [if_neg hp0_val, if_neg hp128_val]
          step*
          have hi_le : i.val ≤ 128 := by scalar_tac
          have hmask_bv : mask.bv = BitVec.allOnes 128 <<< i.val := by
            exact mask_post1.trans (by rw [u128_max_bv])
          have h_iff := u128_and_mask_eq_iff n addr mask i.val hi_le hmask_bv
          have hi12 : (i1 = i2) ↔ (n &&& mask = addr &&& mask) := by
            rw [UScalar.eq_equiv_bv_eq, i1_post1, i2_post1]
            rw [UScalar.eq_equiv_bv_eq]
            rfl
          have h_all : (i1 = i2) ↔ (n.val / 2 ^ (128 - p.val) = addr.val / 2 ^ (128 - p.val)) := by
            rw [hi12, h_iff, i_post]
          simp [h_all]

theorem contains_loop_spec (tp : net.TrustedProxies) (ip : net.IpAddr) :
    net.TrustedProxies.contains_loop tp ip 0#usize ⦃ b => b = cidrContains tp.entries.val ip ⦄ := by
  unfold net.TrustedProxies.contains_loop
  apply WP.spec_mono (loop_search tp.entries.val (entryContains · ip) id
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr
    simp only [id] at hr
    exact search_any tp.entries.val (entryContains · ip) r hr
  · intro j hj
    unfold net.TrustedProxies.contains_loop.body
    h5i_step

theorem trusted_proxies_contains_spec (tp : net.TrustedProxies) (ip : net.IpAddr) :
    net.TrustedProxies.contains tp ip = ok (cidrContains tp.entries.val ip) := by
  unfold net.TrustedProxies.contains
  exact eq_ok_of_spec (contains_loop_spec tp ip)

end nora_kernel.Solution
