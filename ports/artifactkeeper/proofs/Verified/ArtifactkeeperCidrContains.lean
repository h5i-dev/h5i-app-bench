import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit

namespace artifactkeeper_kernel.Verified.ArtifactkeeperCidrContains

/-- The tail of `contains`: comparing under a mask of high bits compares the
addresses shifted right by the mask's zero count. -/
theorem masked_cmp {ty} (x y m : UScalar ty) (mr : Result (UScalar ty)) (k : Nat) (hr : mr = ok m)
    (hm : m.bv = BitVec.allOnes _ <<< k) :
    (do let mask ← mr; let i ← lift (x &&& mask); let i1 ← lift (y &&& mask); ok (decide (i = i1)) : Result Bool)
      = ok (x.val / 2 ^ k == y.val / 2 ^ k) := by
  subst hr
  simp only [lift]
  have := masked_eq_iff x y m k hm
  by_cases h : x &&& m = y &&& m
  · simp_all
  · simp_all

theorem shl_mask32_spec (p : U8) (h : p.val < 32) (h0 : p.val ≠ 0) :
    (do let i ← lift (UScalar.cast .U32 p); let i1 ← 32#u32 - i; core.num.U32.MAX <<< i1 : Result U32)
      ⦃ m => m.bv = BitVec.allOnes _ <<< (32 - p.val) ⦄ := by
  step*
  have : i1.val = 32 - p.val := by subst i_post; scalar_tac
  rw [m_post1, u32_max_bv, this]

theorem shl_mask128_spec (p : U8) (h : p.val < 128) (h0 : p.val ≠ 0) :
    (do let i ← lift (UScalar.cast .U32 p); let i1 ← 128#u32 - i; core.num.U128.MAX <<< i1 : Result U128)
      ⦃ m => m.bv = BitVec.allOnes _ <<< (128 - p.val) ⦄ := by
  step*
  have : i1.val = 128 - p.val := by subst i_post; scalar_tac
  rw [m_post1, u128_max_bv, this]

theorem cidr_contains_spec (c : net.CidrRange) (a : net.IpAddr) :
    c.contains a = ok (inCidr c a) := by
  rcases c with ⟨n, p⟩
  cases n <;> cases a <;> simp only [net.CidrRange.contains, inCidr]
  · by_cases h0 : p = 0#u8
    · rw [masked_cmp _ _ 0#u32 _ 32]
      · simp [h0]
      · simp [h0]
      · simp
    by_cases h32 : p >= 32#u8
    · rw [masked_cmp _ _ core.num.U32.MAX _ 0]
      · have : p.val ≥ 32 := by scalar_tac
        simp [Nat.min_eq_right this]
      · simp [h0, h32]
      · simpa using u32_max_bv
    · have h0' : p.val ≠ 0 := by scalar_tac
      have h32' : p.val < 32 := by scalar_tac
      obtain ⟨m, hr⟩ := ok_of (shl_mask32_spec p h32' h0')
      have hm := post_of_ok (shl_mask32_spec p h32' h0') hr
      rw [masked_cmp _ _ m _ (32 - p.val)]
      · simp [Nat.min_eq_left (Nat.le_of_lt h32')]
      · simp only [h0, h32, reduceIte]; exact hr
      · exact hm
  · by_cases h0 : p = 0#u8
    · rw [masked_cmp _ _ 0#u128 _ 128]
      · simp [h0]
      · simp [h0]
      · simp
    by_cases h128 : p >= 128#u8
    · rw [masked_cmp _ _ core.num.U128.MAX _ 0]
      · have : p.val ≥ 128 := by scalar_tac
        simp [Nat.min_eq_right this]
      · simp [h0, h128]
      · simpa using u128_max_bv
    · have h0' : p.val ≠ 0 := by scalar_tac
      have h128' : p.val < 128 := by scalar_tac
      obtain ⟨m, hr⟩ := ok_of (shl_mask128_spec p h128' h0')
      have hm := post_of_ok (shl_mask128_spec p h128' h0') hr
      rw [masked_cmp _ _ m _ (128 - p.val)]
      · simp [Nat.min_eq_left (Nat.le_of_lt h128')]
      · simp only [h0, h128, reduceIte]; exact hr
      · exact hm

end artifactkeeper_kernel.Verified.ArtifactkeeperCidrContains
