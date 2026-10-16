import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit
namespace nora_kernel.Solution

theorem ushiftRight_shiftLeft_ushiftRight {w : Nat} (a : BitVec w) (n : Nat) :
    (a >>> n <<< n) >>> n = a >>> n := by
  ext i h
  simp only [BitVec.getElem_ushiftRight, BitVec.getLsbD_shiftLeft]
  have h1 : ¬ (n + i < n) := by omega
  have h2 : n + i - n = i := by omega
  by_cases h3 : n + i < w
  · simp [h1, h2, h3]
  · have h4 : a.getLsbD (n + i) = false := BitVec.getLsbD_of_ge a (n + i) (by omega)
    simp [h1, h2, h3, h4]

theorem bitvec_mask_eq_div_eq {w : Nat} (a b : BitVec w) (n : Nat) :
    (a &&& (BitVec.allOnes w <<< n) = b &&& (BitVec.allOnes w <<< n)) ↔ (a.toNat / 2^n = b.toNat / 2^n) := by
  rw [← BitVec.shiftLeft_ushiftRight, ← BitVec.shiftLeft_ushiftRight]
  rw [← Nat.shiftRight_eq_div_pow, ← Nat.shiftRight_eq_div_pow]
  rw [← BitVec.toNat_ushiftRight, ← BitVec.toNat_ushiftRight]
  constructor
  · intro h
    have h' := congrArg (fun (x : BitVec w) => x >>> n) h
    rw [ushiftRight_shiftLeft_ushiftRight, ushiftRight_shiftLeft_ushiftRight] at h'
    rw [h']
  · intro h
    have h' : a >>> n = b >>> n := BitVec.toNat_inj.mp h
    rw [h']

theorem u32_max_bv : core.num.U32.MAX.bv = BitVec.allOnes 32 := rfl
theorem u128_max_bv : core.num.U128.MAX.bv = BitVec.allOnes 128 := rfl

theorem uscalar_eq_iff_bv_eq {ty} (x y : UScalar ty) : (x = y) ↔ (x.bv = y.bv) := by
  cases x; cases y; simp

theorem u32_eq_iff_val_eq (x y : U32) : (x = y) ↔ (x.val = y.val) := by
  rw [uscalar_eq_iff_bv_eq, ← BitVec.toNat_inj]; rfl

theorem u128_eq_iff_val_eq (x y : U128) : (x = y) ↔ (x.val = y.val) := by
  rw [uscalar_eq_iff_bv_eq, ← BitVec.toNat_inj]; rfl

@[step]
theorem entry_contains_spec (nw : net.IpAddr) (p : Std.U8) (ip : net.IpAddr) :
    net.entry_contains nw p ip ⦃ b => b = entryContains (nw, p) ip ⦄ := by
  unfold net.entry_contains entryContains inPrefix
  cases nw <;> cases ip
  case V4.V4 n addr =>
    dsimp only
    split
    · step*
    · split
      · step*
        rename_i hp1 hp2
        have hge : 32 ≤ p.val := by scalar_tac
        have hne : p.val ≠ 0 := by
          intro h0; apply hp1; rw [u8_eq_iff]; exact h0
        simp only [hne, ↓reduceIte, hge]
        rw [decide_eq_decide]
        exact u32_eq_iff_val_eq _ _
      · rename_i hp1 hp2
        have hlt : p.val < 32 := by scalar_tac
        have hpos : 0 < p.val := by
          have : p.val ≠ 0 := by intro h0; apply hp1; rw [u8_eq_iff]; exact h0
          omega
        step*
        have hne : p.val ≠ 0 := by omega
        have hnlt : ¬ 32 ≤ p.val := by omega
        simp only [hne, hnlt, ↓reduceIte, decide_eq_decide]
        rw [uscalar_eq_iff_bv_eq]
        simp only [*, u32_max_bv]
        exact bitvec_mask_eq_div_eq n.bv addr.bv (32 - p.val)
  case V4.V6 => dsimp only; step*
  case V6.V4 => dsimp only; step*
  case V6.V6 n addr =>
    dsimp only
    split
    · step*
    · split
      · step*
        rename_i hp1 hp2
        have hge : 128 ≤ p.val := by scalar_tac
        have hne : p.val ≠ 0 := by
          intro h0; apply hp1; rw [u8_eq_iff]; exact h0
        simp only [hne, ↓reduceIte, hge]
        rw [decide_eq_decide]
        exact u128_eq_iff_val_eq _ _
      · rename_i hp1 hp2
        have hlt : p.val < 128 := by scalar_tac
        have hpos : 0 < p.val := by
          have : p.val ≠ 0 := by intro h0; apply hp1; rw [u8_eq_iff]; exact h0
          omega
        step*
        have hne : p.val ≠ 0 := by omega
        have hnlt : ¬ 128 ≤ p.val := by omega
        simp only [hne, hnlt, ↓reduceIte, decide_eq_decide]
        rw [uscalar_eq_iff_bv_eq]
        simp only [*, u128_max_bv]
        exact bitvec_mask_eq_div_eq n.bv addr.bv (128 - p.val)

@[step]
theorem contains_spec (tp : net.TrustedProxies) (ip : net.IpAddr) :
    net.TrustedProxies.contains tp ip ⦃ b => b = cidrContains tp.entries.val ip ⦄ := by
  unfold net.TrustedProxies.contains net.TrustedProxies.contains_loop
  apply WP.spec_mono (loop_search tp.entries.val (fun e => entryContains e ip) (fun b : Bool => b)
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr
    rw [hr, searchFrom_const]
    simp [cidrContains]
  · intro j hj; unfold net.TrustedProxies.contains_loop.body; h5i_step

theorem untrusted_peer_is_client (tp : net.TrustedProxies) (peer : net.IpAddr)
    (xff xri : Option net.IpAddr) (hc : cidrContains tp.entries.val peer = false) :
    net.resolve_client_ip peer xff xri tp = ok peer := by
  have hspec := contains_spec tp peer
  rw [hc] at hspec
  have hcontains : net.TrustedProxies.contains tp peer = ok false := eq_ok_of_spec hspec
  unfold net.resolve_client_ip
  rw [hcontains]
  simp only [bind_ok]; rfl

end nora_kernel.Solution
