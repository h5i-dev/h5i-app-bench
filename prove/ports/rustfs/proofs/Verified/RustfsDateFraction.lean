import Verified.RustfsDateDigits
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsDateFraction
set_option maxHeartbeats 4000000
set_option maxRecDepth 5000
theorem loop_meaning (s : Slice U8) (i : Usize) (nano weight : I64)
    (bound : i.val≤s.val.length) (r : Usize × I64)
    (h : dates.fraction_loop s i nano weight=ok r) :
    let f := FractionAcc ((nats s.val).drop i.val) nano.val weight.val
    r.2.val=f.1 ∧ r.1.val=i.val+f.2 := by
  let f := FractionAcc ((nats s.val).drop i.val) nano.val weight.val
  let target := (f.1,i.val+f.2)
  unfold dates.fraction_loop at h
  apply loop_ok _
    (fun p : Usize × I64 × I64 => p.1.val≤s.val.length ∧
      let g := FractionAcc ((nats s.val).drop p.1.val) p.2.1.val p.2.2.val
      g.1=target.1 ∧ p.1.val+g.2=target.2)
    (fun out : Usize × I64 => out.2.val=target.1 ∧ out.1.val=target.2)
    (fun p=>s.val.length-p.1.val) ?_ (i,nano,weight) r ⟨bound,rfl,rfl⟩ h
  intro p out hinv hb
  rcases p with ⟨j,acc,w⟩
  rcases hinv with ⟨hj,htn,hti⟩
  dsimp only at *
  unfold dates.fraction_loop.body at hb
  h5i_invert hb
  all_goals first
    | (have hlt : j<Slice.len s := by assumption; skip)
    | (have hend : j.val=s.val.length := by scalar_tac
       have hdrop : (nats s.val).drop j.val=[] := by simp [hend,nats]
       simp only [hdrop,FractionAcc,Nat.add_zero] at htn hti
       exact ⟨htn,hti⟩)
  all_goals obtain ⟨hx,hget⟩ := slice_index_ok (by assumption : Slice.index_usize s j=ok _)
  all_goals have hbound : j.val<(nats s.val).length := by simp only [nats,List.length_map]; scalar_tac
  all_goals have hdrop := List.drop_eq_getElem_cons hbound
  all_goals have hbyte : (nats s.val)[j.val]'hbound=i2.val := by simp only [nats,List.getElem_map]; exact congrArg UScalar.val hget
  all_goals rw [hdrop,hbyte] at htn hti
  all_goals first
    | (have hgood : 48 ≤ i2.val ∧ i2.val ≤ 57 := by scalar_tac; skip)
    | (have hbad : ¬(48 ≤ i2.val ∧ i2.val ≤ 57) := by scalar_tac
       simp only [FractionAcc,if_neg hbad,Nat.add_zero] at htn hti
       exact ⟨htn,hti⟩)
  have hsub := sub_ok_val (by assumption : _ - 48#u8=ok _)
  have hc := RustfsDateDigits.digit_cast _ _ (by assumption)
  have hm := RustfsDateMeaning.mul_ok _ _ _ (by assumption)
  have hn := RustfsDateMeaning.add_ok _ _ _ (by assumption)
  have hw := RustfsDateMeaning.div_ok _ _ _ (by assumption) (by decide +kernel) (by decide +kernel)
  have hj' := add_ok_val (by assumption : j+1#usize=ok _)
  have hgood : 48 ≤ i2.val ∧ i2.val ≤ 57 := by scalar_tac
  simp only [FractionAcc,if_pos hgood] at htn hti
  simp only [IScalar.ofInt_val_eq,UScalar.ofNatCore_val_eq] at *
  have hc' : (i3.val:Int)=(i2.val:Int)-48 := by omega
  refine ⟨⟨by scalar_tac,?_,?_⟩,by scalar_tac⟩
  · simpa only [hn,hm,hc,hc',hw,hj'] using htn
  · simpa only [hn,hm,hc,hc',hw,hj',Nat.add_assoc,Nat.add_comm,Nat.add_left_comm] using hti
theorem fraction_ok (s : Slice U8) (r : Option (I64 × Usize))
    (bound : 20≤s.val.length) (h : dates.fraction s=ok r) :
    r.map (fun p=>(p.1.val,p.2.val))=DateFraction (nats s.val) := by
  unfold dates.fraction at h
  h5i_invert h
  all_goals try rcases x with ⟨j,n⟩
  all_goals try h5i_invert h
  all_goals obtain ⟨hb,hget⟩ := slice_index_ok (by assumption : Slice.index_usize s 19#usize=ok _)
  all_goals have hbyte : (nats s.val)[19]?=some i.val := by simpa only [nats,List.getElem?_map,List.getElem?_eq_getElem (show 19<s.val.length by omega),UScalar.ofNatCore_val_eq,Option.map_some] using congrArg (fun z : U8 => some z.val) hget
  all_goals try have ha := add_ok_val (by assumption : 19#usize+1#usize=ok _)
  all_goals try have hl := loop_meaning s i1 0#i64 100000000#i64 (by scalar_tac) (j,n) hx
  all_goals simp only [UScalar.ofNatCore_val_eq,IScalar.ofInt_val_eq,RustfsScalarOperators.unsigned_eq,Option.map_none,Option.map_some] at *
  all_goals simp only [DateFraction,hbyte,Option.some.injEq]
  all_goals simp_all
  all_goals split_ifs at h ⊢ <;> simp_all [Result.ok.injEq]
  exact ⟨n,j,h.symm,hl⟩
end rustfs_kernel.Verified.RustfsDateFraction
