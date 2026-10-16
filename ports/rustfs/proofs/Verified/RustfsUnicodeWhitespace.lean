import SpecUnicode
import Verified.RustfsValids
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsUnicodeWhitespace
set_option maxRecDepth 8192
set_option maxHeartbeats 0

theorem scalar_eq {ty} (x y : UScalar ty) : (x = y ↔ x.val = y.val) :=
  ⟨congrArg UScalar.val, UScalar.eq_of_val_eq⟩
theorem whitespace_ok (cp : U32) (b : Bool) (h : unicode.whitespace cp = ok b) :
    (b = true ↔ cp.val ∈ UnicodeWhitespace) := by
  unfold unicode.whitespace at h
  cases b <;>
    simp only [ite_eq_iff, Result.ok.injEq, Bool.true_eq_false, Bool.false_eq_true] at h
  all_goals simp_all [UnicodeWhitespace]
  all_goals scalar_tac
end rustfs_kernel.Verified.RustfsUnicodeWhitespace
