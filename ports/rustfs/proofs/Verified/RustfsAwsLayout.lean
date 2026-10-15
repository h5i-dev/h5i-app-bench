import Verified.RustfsAwsClosing
import Verified.RustfsExpansionModel
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
namespace rustfs_kernel.Verified.RustfsAwsLayout
set_option maxHeartbeats 1000000
 theorem balanced_layout (text : Slice U8) (pos start ending balance next : Usize)
    (body pre post : alloc.vec.Vec U8)
    (ha : start.val=pos.val+2) (hb : balance.val=0)
    (hc : awsvars.closing text start=ok (ending,balance))
    (hv : bytes.slice text start ending=ok body)
    (hp : bytes.slice text 0#usize pos=ok pre)
    (hn : next.val=ending.val+1)
    (hs : bytes.slice text next text.len=ok post)
    (hpos : pos.val+2 ≤ text.val.length) :
    ∃ closing,
      ClosingTail (nats (text.val.drop (pos.val+2))) 1=(closing,0) ∧
      ending.val=pos.val+2+closing ∧
      nats body.val=(nats (text.val.drop (pos.val+2))).take closing ∧
      pre.val=text.val.take pos.val ∧
      post.val=text.val.drop (pos.val+closing+3) ∧
      ending.val<text.val.length := by
  have he := RustfsAwsClosing.closing_ok text start (ending,balance) hc
  rw [ha,hb] at he
  simp only [ClosingAt,nats] at he
  rw [←List.map_drop] at he
  cases ht : ClosingTail (List.map (fun x : U8 => x.val) (text.val.drop (pos.val+2))) 1 with
  | mk closing bal =>
    rw [ht] at he
    have he' := Prod.mk.inj he
    have hbal : bal=0 := he'.2.symm
    subst bal
    have hend : ending.val=pos.val+2+closing := he'.1
    have hbnd := (closing_tail_bound (nats (text.val.drop (pos.val+2))) 1).2 (by omega)
    change ClosingTail (nats (text.val.drop (pos.val+2))) 1=(closing,0) at ht
    rw [ht] at hbnd
    have hcl : closing<(text.val.drop (pos.val+2)).length := by
      simpa only [nats,List.length_map] using hbnd rfl
    have hending : ending.val<text.val.length := by simp only [List.length_drop] at hcl; omega
    refine ⟨closing,ht,hend,?_,?_,?_,hending⟩
    · have hv' := RustfsBytes.slice_ok text start ending body hv
      rw [hv',ha,hend]
      simp only [nats,List.map_drop,List.map_take]
      rw [List.drop_take]
      congr 1
      omega
    · have hp' := RustfsBytes.slice_ok text 0#usize pos pre hp
      simpa using hp'
    · have hs' := RustfsBytes.slice_ok text next text.len post hs
      rw [Slice.len_val,Slice.length,List.take_length,hn,hend] at hs'
      have heq : pos.val+2+closing+1=pos.val+closing+3 := by omega
      simpa only [heq] using hs'
end rustfs_kernel.Verified.RustfsAwsLayout
