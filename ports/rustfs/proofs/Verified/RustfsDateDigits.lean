import Verified.RustfsDateMeaning
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsDateDigits
set_option maxHeartbeats 2000000
open RustfsDateMeaning
lemma window_step (s : List Nat) (start count : Nat) (hc : 0<count) (hs : start<s.length) :
    (s.drop start).take count=s[start]::(s.drop (start+1)).take (count-1) := by
  cases count with
  | zero => omega
  | succ count =>
    simpa only [List.take_succ_cons,Nat.add_sub_cancel] using congrArg (List.take (count+1)) (List.drop_eq_getElem_cons hs)
lemma add_ok (a b r : I64) (h : a+b=ok r) : r.val=a.val+b.val := by
  have hs := IScalar.add_equiv a b
  rw [h] at hs
  exact hs.2.1
lemma mul_ok (a b r : I64) (h : a*b=ok r) : r.val=a.val*b.val := by
  have hs := IScalar.mul_equiv a b
  change IScalar.mul a b=ok r at h
  rw [h] at hs
  exact hs.2.2.1
lemma digit_cast (a : U8) (r : I64) (h : lift (UScalar.hcast .I64 a)=ok r) : r.val=a.val :=
  H5iAppLib.post_of_ok (x:=r) (P:=fun z : I64 => z.val=a.val)
    (UScalar.hcast_inBounds_spec .I64 a (by scalar_tac)) h
lemma loop_meaning (s : Slice U8) (start count : Usize) (n : I64) (i : Usize)
    (bound : start.val+count.val≤s.val.length) (hi : i.val≤count.val) (r : Option I64)
    (h : dates.digits_loop s start count n i=ok r) :
    r.map (·.val)=DecimalAcc (((nats s.val).drop (start.val+i.val)).take (count.val-i.val)) n.val := by
  let target := DecimalAcc (((nats s.val).drop (start.val+i.val)).take (count.val-i.val)) n.val
  unfold dates.digits_loop at h
  apply loop_ok _
    (fun p : I64 × Usize => p.2.val≤count.val ∧
      DecimalAcc (((nats s.val).drop (start.val+p.2.val)).take (count.val-p.2.val)) p.1.val=target)
    (fun out : Option I64 => out.map (·.val)=target) (fun p=>count.val-p.2.val)
    ?_ (n,i) r ⟨hi,rfl⟩ h
  intro p out hinv hb
  rcases p with ⟨acc,j⟩
  rcases hinv with ⟨hj,ht⟩
  dsimp only at *
  unfold dates.digits_loop.body at hb
  h5i_invert hb
  all_goals first
    | (have hlt : j<count := by assumption; skip)
    | (have hend : j.val=count.val := by scalar_tac
       change (some acc.val : Option Int)=target
       have hz : count.val-j.val=0 := by omega
       simpa only [hz,List.take_zero,DecimalAcc] using ht)

  all_goals have ha := add_ok_val (by assumption : start+j=ok _)
  all_goals obtain ⟨hx,hget⟩ := slice_index_ok (by assumption : Slice.index_usize s _=ok _)
  all_goals have hbound : start.val+j.val<s.val.length := by omega
  all_goals have hstep := window_step (nats s.val) (start.val+j.val) (count.val-j.val) (by scalar_tac) (by simpa only [nats,List.length_map] using hbound)
  all_goals have hbyte : (nats s.val)[start.val+j.val]'(by simpa only [nats,List.length_map] using hbound)=b.val := by simp only [nats,List.getElem_map]; simpa only [ha] using congrArg UScalar.val hget
  all_goals rw [hstep,hbyte] at ht
  all_goals first
    | (have hgood : 48≤b.val ∧ b.val≤57 := by scalar_tac; skip)
    | (have hbad : ¬(48≤b.val ∧ b.val≤57) := by scalar_tac
       change (none : Option Int)=target
       simpa only [DecimalAcc,if_neg hbad] using ht)
  have hm := mul_ok _ _ _ (by assumption : _ * _=ok _)
  have hsub := sub_ok_val (by assumption : _ - 48#u8=ok _)
  have hc := digit_cast _ _ (by assumption : lift (UScalar.hcast .I64 _)=ok _)
  have hn := add_ok _ _ _ (by assumption : _ + _=ok _)
  have hj' := add_ok_val (by assumption : j+1#usize=ok _)
  simp only [IScalar.ofInt_val_eq,UScalar.ofNatCore_val_eq] at *
  have hd : 48≤b.val ∧ b.val≤57 := by scalar_tac
  simp only [DecimalAcc,if_pos hd] at ht
  refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
  rw [hj',hn,hm,hc]
  have hnval : acc.val*10+(i3.val:Int)=10*acc.val+(b.val:Int)-48 := by omega
  rw [hnval]
  convert ht using 1 <;> congr 2 <;> omega
theorem digits_ok (s : Slice U8) (start count : Usize) (r : Option I64)
    (h : dates.digits s start count=ok r) :
    r.map (·.val)=DateDigits (nats s.val) start.val count.val := by
  unfold dates.digits at h
  h5i_invert h
  · have hn : ¬start.val+count.val≤(nats s.val).length := by simp only [nats,List.length_map]; scalar_tac
    simp only [DateDigits,if_neg hn,Option.map_none]
  · have hv := sub_ok_val (by assumption : _ - start=ok _)
    have hn : ¬start.val+count.val≤(nats s.val).length := by simp only [nats,List.length_map]; scalar_tac
    simp only [DateDigits,if_neg hn,Option.map_none]
  · have hv := sub_ok_val (by assumption : _ - start=ok _)
    have hb : start.val+count.val≤s.val.length := by scalar_tac
    have hm := loop_meaning s start count 0#i64 0#usize hb (by scalar_tac) r h
    simpa only [DateDigits,nats,List.length_map,show start.val+count.val≤s.val.length from hb,ite_true,UScalar.ofNatCore_val_eq,IScalar.ofInt_val_eq,Nat.add_zero,Nat.sub_zero] using hm
end rustfs_kernel.Verified.RustfsDateDigits
