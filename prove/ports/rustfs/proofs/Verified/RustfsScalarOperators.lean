import SpecOperators
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsScalarOperators

theorem unsigned_eq {ty} (a b : UScalar ty) : a = b ↔ a.val = b.val :=
  ⟨UScalar.val_eq_of_eq, UScalar.eq_of_val_eq⟩
theorem signed_eq {ty} (a b : IScalar ty) : a = b ↔ a.val = b.val :=
  ⟨IScalar.val_eq_of_eq, IScalar.eq_of_val_eq⟩

theorem numeric_ok (op : condfuncs.NumOp) (a b : I64) (r : Bool)
    (h : condfuncs.num_op op a b = ok r) :
    r = true ↔ NumericComparison op a.val b.val := by
  cases op <;> simp only [condfuncs.num_op, Result.ok.injEq] at h <;>
    subst r <;> simp [NumericComparison, signed_eq]

theorem null_ok (want : Bool) (count : Usize) (r : Bool)
    (h : condfuncs.null_ok want count = ok r) :
    r = true ↔ NullComparison want count.val := by
  cases want <;> simp [condfuncs.null_ok] at h <;>
    subst r <;> simp [NullComparison, unsigned_eq]
end rustfs_kernel.Verified.RustfsScalarOperators

namespace rustfs_kernel.Verified.RustfsScalarOperators
/-- The numeric address prefix, including width-clamped prefixes. -/
theorem prefix_ok (net ip : condfuncs.IpAddr) (pref : U8) (r : Bool)
    (h : condfuncs.net_contains net pref ip = ok r) :
    r = true ↔ IpPrefix net pref.val ip := by
  cases net with
  | V4 n =>
    cases ip with
    | V6 a =>
      simp only [condfuncs.net_contains, Result.ok.injEq] at h
      subst r
      simp [IpPrefix]
    | V4 a =>
      unfold condfuncs.net_contains at h
      h5i_invert h
      · simp [IpPrefix, NumericPrefix, hc]
        rw [Nat.div_eq_of_lt (by scalar_tac), Nat.div_eq_of_lt (by scalar_tac)]
      · have hp : 32 ≤ pref.val := by scalar_tac
        simp [IpPrefix, NumericPrefix, Nat.min_eq_right hp, unsigned_eq]
      · have hs := sub_ok_val hi
        have hn := post_of_ok (UScalar.ShiftRight_spec n i (by scalar_tac)) hi1
        have ha := post_of_ok (UScalar.ShiftRight_spec a i (by scalar_tac)) hi2
        have hp : pref.val ≤ 32 := by scalar_tac
        simp only [IpPrefix, NumericPrefix, Nat.min_eq_left hp]
        have hv : i.val = 32 - pref.val := by scalar_tac
        simp only [unsigned_eq, decide_eq_true_eq, hn.1, ha.1, hv, Nat.shiftRight_eq_div_pow]
  | V6 n =>
    cases ip with
    | V4 a =>
      simp only [condfuncs.net_contains, Result.ok.injEq] at h
      subst r
      simp [IpPrefix]
    | V6 a =>
      unfold condfuncs.net_contains at h
      h5i_invert h
      · simp [IpPrefix, NumericPrefix, hc]
        rw [Nat.div_eq_of_lt (by scalar_tac), Nat.div_eq_of_lt (by scalar_tac)]
      · have hp : 128 ≤ pref.val := by scalar_tac
        simp [IpPrefix, NumericPrefix, Nat.min_eq_right hp, unsigned_eq]
      · have hs := sub_ok_val hi
        have hn := post_of_ok (UScalar.ShiftRight_spec n i (by scalar_tac)) hi1
        have ha := post_of_ok (UScalar.ShiftRight_spec a i (by scalar_tac)) hi2
        have hp : pref.val ≤ 128 := by scalar_tac
        simp only [IpPrefix, NumericPrefix, Nat.min_eq_left hp]
        have hv : i.val = 128 - pref.val := by scalar_tac
        simp only [unsigned_eq, decide_eq_true_eq, hn.1, ha.1, hv, Nat.shiftRight_eq_div_pow]
end rustfs_kernel.Verified.RustfsScalarOperators

namespace rustfs_kernel.Verified.RustfsScalarOperators
/-- Date operators compare mathematical instants independently of source offsets. -/
theorem date_comparison_ok (op : conddata.Op) (a b : I128) (r : Bool)
    (h : dates.compare op a b = ok r) :
    r = true ↔ DateComparison op a.val b.val := by
  cases op <;> simp only [dates.compare, Result.ok.injEq] at h <;>
    subst r <;> simp [DateComparison, signed_eq]
end rustfs_kernel.Verified.RustfsScalarOperators
