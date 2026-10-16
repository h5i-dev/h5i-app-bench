import SpecDate
import Verified.RustfsScalarOperators
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsDateMeaning
set_option maxHeartbeats 4000000
set_option maxRecDepth 5000
lemma scalar_eq {ty} (a b : IScalar ty) : a=b ↔ a.val=b.val := ⟨congrArg IScalar.val,IScalar.eq_of_val_eq⟩
lemma rem_ok (a b r : I64) (hz : b.val≠0) (h : a%b=ok r) : r.val=a.val.tmod b.val :=
  H5iAppLib.post_of_ok (x := r) (P := fun z : I64 => z.val=a.val.tmod b.val) (IScalar.rem_spec a hz) h
lemma add_ok (a b r : I64) (h : a+b=ok r) : r.val=a.val+b.val := by
  have hs := IScalar.add_equiv a b
  rw [h] at hs
  exact hs.2.1
lemma sub_ok (a b r : I64) (h : a-b=ok r) : r.val=a.val-b.val := by
  have hs := IScalar.sub_equiv a b
  rw [h] at hs
  exact hs.2.1
lemma mul_ok (a b r : I64) (h : a*b=ok r) : r.val=a.val*b.val := by
  have hs := IScalar.mul_equiv a b
  change IScalar.mul a b=ok r at h
  rw [h] at hs
  exact hs.2.2.1
lemma div_ok (a b r : I64) (h : a/b=ok r) (hz : b.val≠0) (hpos : b.val≠ -1) : r.val=a.val.tdiv b.val := by
  obtain ⟨z,hz',hv⟩ := IScalar.div_spec (x:=a) (y:=b) hz (by tauto)
  rw [h] at hz'
  have he := Result.ok.inj hz'
  subst z
  exact hv
theorem month_ok (year month out : I64) (h : dates.month_days year month=ok out) :
    out.val=MonthDays year.val month.val := by
  unfold dates.month_days at h
  h5i_invert h
  all_goals try have h4 := rem_ok year 4#i64 _ (by decide +kernel) (by assumption)
  all_goals try have h100 := rem_ok year 100#i64 _ (by decide +kernel) (by assumption)
  all_goals try have h400 := rem_ok year 400#i64 _ (by decide +kernel) (by assumption)
  all_goals simp only [scalar_eq,IScalar.ofInt_val_eq,ne_eq,decide_eq_true_eq] at *
  all_goals simp_all [MonthDays]
theorem civil_ok (year month day out : I64) (h : dates.civil_days year month day=ok out) :
    out.val=CivilDays year.val month.val day.val := by
  unfold dates.civil_days at h
  h5i_invert h
  have hyval : y.val=(if month.val≤2 then year.val-1 else year.val) := by
    by_cases hc : month≤2#i64
    · simp only [hc,ite_true] at hy
      have hv := sub_ok _ _ _ hy
      have hp : month.val≤2 := by simpa only [IScalar.le_equiv,IScalar.ofInt_val_eq] using hc
      simpa only [hp,ite_true,IScalar.ofInt_val_eq] using hv
    · simp only [hc,ite_false,Result.ok.injEq] at hy
      subst y
      have hn : ¬month.val≤2 := by simpa only [IScalar.le_equiv,IScalar.ofInt_val_eq] using hc
      simp only [hn,ite_false]
  have hmv : m.val=(if 2<month.val then month.val-3 else month.val+9) := by
    by_cases hc : month>2#i64
    · simp only [hc,ite_true] at hm
      have hv := sub_ok _ _ _ hm
      have hp : 2<month.val := by simpa only [IScalar.lt_equiv,IScalar.ofInt_val_eq] using hc
      simpa only [hp,ite_true,IScalar.ofInt_val_eq] using hv
    · simp only [hc,ite_false] at hm
      have hv := add_ok _ _ _ hm
      have hn : ¬2<month.val := by simpa only [IScalar.lt_equiv,IScalar.ofInt_val_eq] using hc
      simpa only [hn,ite_false,IScalar.ofInt_val_eq] using hv
  have hev : era.val=(if 0≤y.val then y.val else y.val-399).tdiv 400 := by
    by_cases hc : y≥0#i64
    · simp only [hc,ite_true] at hera
      have hv := div_ok _ _ _ hera (by decide +kernel) (by decide +kernel)
      have hp : 0≤y.val := by simpa only [IScalar.le_equiv,IScalar.ofInt_val_eq] using hc
      simpa only [hp,ite_true,IScalar.ofInt_val_eq] using hv
    · simp only [hc,ite_false] at hera
      obtain ⟨z,hz,hdiv⟩ := bind_tc_eq_ok.mp hera
      have hzv := sub_ok _ _ _ hz
      have hv := div_ok _ _ _ hdiv (by decide +kernel) (by decide +kernel)
      have hn : ¬0≤y.val := by simpa only [IScalar.le_equiv,IScalar.ofInt_val_eq] using hc
      simpa only [hn,ite_false,hzv,IScalar.ofInt_val_eq] using hv
  clear hy hm hera
  all_goals repeat' first
    | have hh := add_ok _ _ _ (by assumption); clear ‹_ + _ = ok _›
    | have hh := sub_ok _ _ _ (by assumption); clear ‹_ - _ = ok _›
    | have hh := mul_ok _ _ _ (by assumption); clear ‹_ * _ = ok _›
    | have hh := div_ok _ _ _ (by assumption) (by decide +kernel) (by decide +kernel); clear ‹_ / _ = ok _›
  all_goals simp only [IScalar.ofInt_val_eq,IScalar.le_equiv,IScalar.lt_equiv,ge_iff_le,gt_iff_lt] at *
  all_goals simp_all [CivilDays]
  all_goals split_ifs at * <;> omega
end rustfs_kernel.Verified.RustfsDateMeaning
