import Verified.RustfsDateDigits
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsDateFields
set_option maxHeartbeats 4000000
set_option maxRecDepth 5000
theorem time_ok (s : Slice U8) (r : Option (I64 × I64 × I64))
    (h : dates.time_fields s=ok r) :
    r.map (fun (a,b,c)=>(a.val,b.val,c.val))=DateTimeFields (nats s.val) := by
  unfold dates.time_fields at h
  h5i_invert h
  all_goals have h0 := RustfsDateDigits.digits_ok _ _ _ _ (by assumption : dates.digits s 11#usize 2#usize=ok _)
  all_goals try have h1 := RustfsDateDigits.digits_ok _ _ _ _ (by assumption : dates.digits s 14#usize 2#usize=ok _)
  all_goals try have h2 := RustfsDateDigits.digits_ok _ _ _ _ (by assumption : dates.digits s 17#usize 2#usize=ok _)
  all_goals simp only [Option.map_none,Option.map_some,UScalar.ofNatCore_val_eq,IScalar.ofInt_val_eq,IScalar.lt_equiv,gt_iff_lt] at *
  all_goals simp only [DateTimeFields,Bind.bind,Option.bind]
  all_goals rw [←h0]
  all_goals simp only [Option.bind]
  all_goals try rw [←h1]
  all_goals simp only [Option.bind]
  all_goals try rw [←h2]
  all_goals simp only [Option.bind]
  all_goals try rfl
  all_goals split_ifs <;> (try simp_all) <;> omega
theorem calendar_ok (s : Slice U8) (r : Option (I64 × I64 × I64))
    (h : dates.calendar_fields s=ok r) :
    r.map (fun (a,b,c)=>(a.val,b.val,c.val))=DateCalendar (nats s.val) := by
  unfold dates.calendar_fields at h
  h5i_invert h
  all_goals have h0 := RustfsDateDigits.digits_ok _ _ _ _ (by assumption : dates.digits s 0#usize 4#usize=ok _)
  all_goals try have h1 := RustfsDateDigits.digits_ok _ _ _ _ (by assumption : dates.digits s 5#usize 2#usize=ok _)
  all_goals try have h2 := RustfsDateDigits.digits_ok _ _ _ _ (by assumption : dates.digits s 8#usize 2#usize=ok _)
  all_goals try have hm := RustfsDateMeaning.month_ok _ _ _ (by assumption)
  all_goals simp only [Option.map_none,Option.map_some,UScalar.ofNatCore_val_eq,IScalar.ofInt_val_eq,IScalar.lt_equiv,gt_iff_lt] at *
  all_goals simp only [DateCalendar,Bind.bind,Option.bind]
  all_goals rw [←h0]
  all_goals simp only [Option.bind]
  all_goals try rw [←h1]
  all_goals simp only [Option.bind]
  all_goals try rw [←h2]
  all_goals simp only [Option.bind]
  all_goals try rfl
  all_goals split_ifs <;> (try simp_all) <;> omega
end rustfs_kernel.Verified.RustfsDateFields
