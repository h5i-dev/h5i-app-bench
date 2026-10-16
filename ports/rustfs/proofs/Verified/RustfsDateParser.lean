import Verified.RustfsDateFields
import Verified.RustfsDateFraction
import Verified.RustfsDateLeap
import Verified.RustfsDateOffset
import Verified.RustfsDateNanos
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsDateParser
set_option maxHeartbeats 6000000
set_option maxRecDepth 10000
theorem parse_ok (s : Slice U8) (r : Option I128)
    (h : dates.parse_rfc3339 s=ok r) : r.map (·.val)=ParseInstant (nats s.val) := by
  unfold dates.parse_rfc3339 at h
  h5i_invert h
  all_goals try (rcases v with ⟨year,month,day⟩; obtain ⟨o1,ho1,hrest⟩ := H5iAppLib.bind_eq_ok.1 h; clear h; h5i_invert hrest)
  all_goals try (rcases v with ⟨hour,minute,second⟩; obtain ⟨o2,ho2,hrest2⟩ := H5iAppLib.bind_eq_ok.1 hrest; clear hrest; h5i_invert hrest2)
  all_goals try (rcases v2 with ⟨nano,i5⟩; obtain ⟨o3,ho3,hrest3⟩ := H5iAppLib.bind_eq_ok.1 hrest2; clear hrest2; h5i_invert hrest3)
  all_goals try have h4 := RustfsDateOffset.byte_at _ _ _ (by assumption : Slice.index_usize s 4#usize=ok _)
  all_goals try have h7 := RustfsDateOffset.byte_at _ _ _ (by assumption : Slice.index_usize s 7#usize=ok _)
  all_goals try have h13 := RustfsDateOffset.byte_at _ _ _ (by assumption : Slice.index_usize s 13#usize=ok _)
  all_goals try have h16 := RustfsDateOffset.byte_at _ _ _ (by assumption : Slice.index_usize s 16#usize=ok _)
  all_goals try have hcal := RustfsDateFields.calendar_ok _ _ (by assumption)
  all_goals try have htime := RustfsDateFields.time_ok _ _ (by assumption)
  all_goals try have hfrac := RustfsDateFraction.fraction_ok s _ (by scalar_tac) (by assumption)
  all_goals try have hoff := RustfsDateOffset.offset_ok s i5 _ (by assumption)
  all_goals try have hcivil := RustfsDateMeaning.civil_ok _ _ _ _ (by assumption)
  all_goals try have hleap := RustfsDateLeap.leap_ok _ _ _ _ _ _ (by assumption)
  all_goals try have hnanos := RustfsDateNanos.nanos_ok _ _ _ (by assumption)
  all_goals repeat' first
    | have hh := RustfsDateMeaning.add_ok _ _ _ (by assumption); clear ‹(_ : I64) + _ = ok _›
    | have hh := RustfsDateMeaning.sub_ok _ _ _ (by assumption); clear ‹(_ : I64) - _ = ok _›
    | have hh := RustfsDateMeaning.mul_ok _ _ _ (by assumption); clear ‹(_ : I64) * _ = ok _›
  all_goals simp only [Slice.len_val,UScalar.lt_equiv,UScalar.ofNatCore_val_eq,IScalar.ofInt_val_eq,RustfsScalarOperators.unsigned_eq,RustfsDateMeaning.scalar_eq,Option.map_none,Option.map_some] at *
  all_goals simp only [ParseInstant]
  all_goals try (simp_all [nats,List.length_map]; done)
  all_goals try simp only [Bind.bind,Option.bind]
  all_goals try rw [←hcal]
  all_goals try simp only [Option.bind]
  all_goals try rw [←htime]
  all_goals try simp only [Option.bind]
  all_goals try rw [←hfrac]
  all_goals try simp only [Option.bind]
  all_goals try rw [←hoff]
  all_goals try simp only [Option.bind]
  all_goals simp_all [nats,List.length_map]
  all_goals first
    | (obtain ⟨a,ha,hav⟩ := h4; intro x hx hxv; have he : x=a := Option.some.inj (hx.symm.trans ha); subst x; omega)
    | (obtain ⟨a,ha,hav⟩ := h7; intro x hx hxv; have he : x=a := Option.some.inj (hx.symm.trans ha); subst x; omega)
    | (obtain ⟨a,ha,hav⟩ := h13; intro x hx hxv; have he : x=a := Option.some.inj (hx.symm.trans ha); subst x; omega)
    | (obtain ⟨a,ha,hav⟩ := h16; intro x hx hxv; have he : x=a := Option.some.inj (hx.symm.trans ha); subst x; omega)
end rustfs_kernel.Verified.RustfsDateParser
