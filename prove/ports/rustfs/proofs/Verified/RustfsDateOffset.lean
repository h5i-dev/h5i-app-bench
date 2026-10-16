import Verified.RustfsDateDigits
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsDateOffset
open RustfsDateMeaning
set_option maxHeartbeats 5000000
set_option maxRecDepth 5000
lemma byte_at (s : Slice U8) (i : Usize) (b : U8) (h : Slice.index_usize s i=ok b) :
    (nats s.val)[i.val]?=some b.val := by
  obtain ⟨hb,hv⟩ := slice_index_ok h
  simp only [nats,List.getElem?_map,List.getElem?_eq_getElem hb,hv,Option.map_some]
lemma neg_ok (a r : I64) (h : -. a=ok r) : r.val= -a.val := by
  have hs := IScalar.tryMk_eq .I64 (-a.val)
  change IScalar.tryMk .I64 (-a.val)=ok r at h
  rw [h] at hs
  exact hs.1
theorem offset_ok (s : Slice U8) (i : Usize) (r : Option I64)
    (h : dates.offset s i=ok r) :
    r.map (·.val)=DateOffset (nats s.val) i.val := by
  unfold dates.offset at h
  h5i_invert h
  all_goals try have hb := byte_at _ _ _ (by assumption : Slice.index_usize s i=ok _)
  all_goals repeat' first
    | have hh := add_ok_val (by assumption : (_ : Usize) + _=ok _); clear ‹(_ : Usize) + _ = ok _›
    | have hh := add_ok _ _ _ (by assumption); clear ‹(_ : I64) + _ = ok _›
    | have hh := mul_ok _ _ _ (by assumption); clear ‹_ * _ = ok _›
  all_goals try have hneg := neg_ok _ _ (by assumption)
  all_goals try have hcolon := byte_at _ _ _ (by assumption : Slice.index_usize s i5=ok _)
  all_goals try have h0 := RustfsDateDigits.digits_ok _ _ _ _ (by assumption : dates.digits s i7 2#usize=ok _)
  all_goals try have h1 := RustfsDateDigits.digits_ok _ _ _ _ (by assumption : dates.digits s i8 2#usize=ok _)
  all_goals simp only [Option.map_none,Option.map_some,IScalar.ofInt_val_eq,UScalar.ofNatCore_val_eq,UScalar.le_equiv,UScalar.lt_equiv,RustfsScalarOperators.unsigned_eq,IScalar.lt_equiv,scalar_eq,ne_eq,Slice.len_val] at *
  all_goals simp_all [DateOffset,nats,List.length_map]
  all_goals try (intro x hx hxv; obtain ⟨a,ha,hav⟩ := hcolon; have he : x=a := Option.some.inj (hx.symm.trans ha); subst x; omega)
  all_goals try simp only [←h0,Option.bind]
  all_goals try simp only [←h1,Option.bind]
  all_goals try rfl
  all_goals split_ifs <;> (try simp_all) <;> omega
end rustfs_kernel.Verified.RustfsDateOffset
