import Verified.RustfsDateMeaning
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsDateLeap
open RustfsDateMeaning
set_option maxHeartbeats 4000000
set_option maxRecDepth 5000
theorem leap_ok (utc localDay year month day : I64) (r : Bool)
    (h : dates.leap_valid utc localDay year month day=ok r) :
    r=true ↔ LeapSecondValid utc.val localDay.val year.val month.val day.val := by
  unfold dates.leap_valid at h
  h5i_invert h
  all_goals have hr0 := rem_ok utc 86400#i64 _ (by decide +kernel) hi
  all_goals have hr1 := rem_ok i1 86400#i64 _ (by decide +kernel) hrem
  all_goals have hm := month_ok _ _ _ (by assumption)
  all_goals repeat' first
    | have hh := rem_ok _ _ _ (by decide +kernel) (by assumption); clear ‹_ % _ = ok _›
    | have hh := add_ok _ _ _ (by assumption); clear ‹_ + _ = ok _›
    | have hh := sub_ok _ _ _ (by assumption); clear ‹_ - _ = ok _›
    | have hh := div_ok _ _ _ (by assumption) (by decide +kernel) (by decide +kernel); clear ‹_ / _ = ok _›
  all_goals simp only [scalar_eq,IScalar.ofInt_val_eq,decide_eq_true_eq,ne_eq] at *
  all_goals simp_all [LeapSecondValid]
end rustfs_kernel.Verified.RustfsDateLeap
