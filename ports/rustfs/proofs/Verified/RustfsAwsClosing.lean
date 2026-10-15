import SpecAwsValues
import Verified.RustfsConditionCopies
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsAwsClosing
set_option maxHeartbeats 2000000
set_option linter.unusedSimpArgs false
theorem closing_zero (s : List Nat) (pos : Nat) : ClosingAt s pos 0 = (pos,0) := by
  cases h : s.drop pos <;> simp [ClosingAt,h,ClosingTail]
theorem closing_past (s : List Nat) (pos b : Nat) (h : s.length ≤ pos) :
    ClosingAt s pos b = (pos,b) := by
  by_cases hb : b=0 <;> simp [ClosingAt,List.drop_of_length_le h,ClosingTail,hb]
theorem closing_step (s : List Nat) (pos b x : Nat) (hp : pos < s.length)
    (hx : s[pos]=x) (hb : b≠0) :
    ClosingAt s pos b =
      let next := if x=123 then b+1 else if x=125 then b-1 else b
      if next=0 then (pos,0) else ClosingAt s (pos+1) next := by
  unfold ClosingAt
  rw [List.drop_eq_getElem_cons hp,hx]
  by_cases h123 : x=123 <;> by_cases h125 : x=125
  all_goals simp_all [ClosingTail,Nat.add_comm,Nat.add_left_comm,Nat.add_assoc]
  split <;> simp_all [Nat.add_comm,Nat.add_left_comm,Nat.add_assoc]

theorem closing_ok (s : Slice U8) (start : Usize) (out : Usize × Usize)
    (h : awsvars.closing s start = ok out) :
    (out.1.val,out.2.val) = ClosingAt (nats s.val) start.val 1 := by
  unfold awsvars.closing awsvars.closing_loop at h
  let target := ClosingAt (nats s.val) start.val 1
  change (out.1.val,out.2.val)=target
  refine loop_ok _ (fun x : Usize × Usize => ClosingAt (nats s.val) x.2.val x.1.val=target)
    (fun out => (out.1.val,out.2.val)=target)
    (fun x => (s.val.length-x.2.val)*2 + if x.1.val=0 then 0 else 1)
    ?_ _ out (by rfl) h
  rintro ⟨balance,pos⟩ r hi hr
  unfold awsvars.closing_loop.body at hr
  h5i_invert hr
  all_goals
    simp only [Prod.fst,Prod.snd] at hi ⊢
  case isTrue.isFalse =>
    have hb : balance.val=0 := by scalar_tac
    simpa only [hb,closing_zero] using hi
  case isFalse =>
    have hp : (nats s.val).length ≤ pos.val := by simp only [nats,List.length_map]; scalar_tac
    simpa only [closing_past _ _ _ hp] using hi
  all_goals
    obtain ⟨hlt,hx⟩ := slice_index_ok hi1
    have hpx : (nats s.val)[pos.val]'(by simp [nats]; exact hlt) = i1.val := by
      simp only [nats,List.getElem_map,hx]
    have hb : balance.val ≠ 0 := by scalar_tac
    have hs := closing_step (nats s.val) pos.val balance.val i1.val (by simpa [nats] using hlt) hpx hb
    have hn : brace1.val = if i1.val=123 then balance.val+1 else if i1.val=125 then balance.val-1 else balance.val := by
      simp only [u8_eq_iff,UScalar.ofNatCore_val_eq] at hbrace1
      split at hbrace1
      · rename_i he
        simpa [he,UScalar.ofNatCore_val_eq] using add_ok_val hbrace1
      · rename_i he
        split at hbrace1
        · rename_i he2
          simpa [he,he2,UScalar.ofNatCore_val_eq] using (sub_ok_val hbrace1).1
        · rename_i he2
          have heq := Result.ok.inj hbrace1
          subst brace1
          simp only [he,he2,ite_false]
    rw [← hn] at hs
    rw [hs] at hi
  case isTrue.isTrue.isTrue =>
    have hb1 : brace1.val≠0 := by scalar_tac
    simp only [hb1,ite_false] at hi
    have he := add_ok_val hend1
    refine ⟨?_,?_⟩
    · simpa only [show end1.val=pos.val+1 by scalar_tac] using hi
    · simp only [hb,hb1,ite_false]
      scalar_tac
  case isTrue.isTrue.isFalse =>
    have hb1 : brace1.val=0 := by scalar_tac
    simp only [hb1,ite_true] at hi
    refine ⟨?_,?_⟩
    · simpa only [hb1,closing_zero] using hi
    · simp only [hb,hb1,ite_true,ite_false]
      omega
end rustfs_kernel.Verified.RustfsAwsClosing
