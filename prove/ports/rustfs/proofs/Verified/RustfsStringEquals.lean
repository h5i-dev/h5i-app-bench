import Verified.RustfsAsciiLower
import Verified.RustfsCondData
import SpecOperators
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit

namespace rustfs_kernel.Verified.RustfsStringEquals
set_option maxHeartbeats 2000000

theorem request_ok (requests : alloc.vec.Vec (alloc.vec.Vec U8)) (i : Usize)
    (ignoreCase : Bool) (r : alloc.vec.Vec U8)
    (h : (if ignoreCase then do
      let v ← alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice (alloc.vec.Vec U8)) requests i
      bytes.lower v.deref
    else do
      let v ← alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice (alloc.vec.Vec U8)) requests i
      alloc.vec.CloneVec.clone core.clone.CloneU8 v) = ok r) :
    ∃ v, requests.val[i.val]? = some v ∧
      nats r.val = if ignoreCase then (nats v.val).map asciiLower else nats v.val := by
  h5i_invert h
  · obtain ⟨hlt,he⟩ := vec_index_ok hv
    refine ⟨v,by simp [List.getElem?_eq_getElem hlt,he],?_⟩
    simpa only [hc,ite_true,RustfsForceDelete.deref_val] using RustfsAsciiLower.lower_ok _ _ h
  · obtain ⟨hlt,he⟩ := vec_index_ok hv
    rw [vec_clone_ok _ _ (fun _ => rfl)] at h
    have hh : v = r := by simpa only [Result.ok.injEq] using h
    exact ⟨v,by simp [List.getElem?_eq_getElem hlt,he],by simp [hc,← hh]⟩

theorem loop_ok (requests candidates : alloc.vec.Vec (alloc.vec.Vec U8))
    (q : condfuncs.Quantifier) (ignoreCase negate b : Bool)
    (h : condfuncs.str_eval_loop q ignoreCase negate requests candidates 0#usize = ok b) :
    b = EqualityDecision q ignoreCase negate (candidates.val.map (fun v => nats v.val))
      (requests.val.map (fun v => nats v.val)) := by
  unfold condfuncs.str_eval_loop at h
  let P := fun xs : List (alloc.vec.Vec U8) => EqualityDecision q ignoreCase negate
    (candidates.val.map (fun v => nats v.val)) (xs.map (fun v => nats v.val))
  change b = P requests.val
  refine H5iAppLib.loop_ok _ (fun s : condfuncs.Quantifier × Usize => s.1=q ∧
      s.2.val ≤ requests.val.length ∧ P (requests.val.drop s.2.val)=P requests.val)
    (fun b => b=P requests.val) (fun s => requests.val.length-s.2.val) ?_ _ b
    ⟨rfl,by simp,by simp⟩ h
  rintro ⟨q',i⟩ result ⟨hq,hi,he⟩ hr
  simp only [Prod.fst,Prod.snd] at hq hi he hr ⊢
  subst q'
  unfold condfuncs.str_eval_loop.body at hr
  h5i_invert hr
  all_goals
    try
      have hn : requests.val.length ≤ i.val := by scalar_tac
      rw [List.drop_of_length_le hn] at he
      cases q <;> simp_all [P,EqualityDecision,
        condfuncs.Quantifier.Insts.CoreCmpPartialEqQuantifier.eq,
        condfuncs.Quantifier.read_discriminant]
  all_goals
    obtain ⟨v,hv,hrv⟩ := request_ok requests i ignoreCase r hr_1
    have hlt : i.val < requests.val.length := by scalar_tac
    have hd : requests.val.drop i.val = v :: requests.val.drop (i.val+1) := by
      rw [List.drop_eq_getElem_cons hlt]
      obtain ⟨_,hv'⟩ := List.getElem_of_getElem? hv
      rw [hv']
    have hm := RustfsCondData.member_ok _ _ _ hhit
    simp only [RustfsForceDelete.deref_val] at hm
    have hm' : hit = decide (nats r.val ∈ candidates.val.map (fun v => nats v.val)) := by
      apply Bool.eq_iff_iff.mpr
      simp only [decide_eq_true_eq,List.mem_map]
      rw [hm]
      constructor
      · rintro ⟨v,hv,hv'⟩; exact ⟨v,hv,congrArg nats hv'⟩
      · rintro ⟨v,hv,hv'⟩; exact ⟨v,hv,RustfsForceDelete.nats_inj hv'⟩
    rw [hrv] at hm'
    dsimp only [P] at he
    rw [hd,List.map_cons] at he
    simp only [EqualityDecision,EqualityValue,List.any_cons,List.all_cons] at he
    rw [← hm'] at he
  all_goals
    try have hc' := Bool.eq_false_iff.mpr hc_1
        simp only [hc',Bool.false_or,Bool.false_and] at he
    try simp only [hc_1,Bool.true_or,Bool.true_and] at he
    try exact he
  all_goals
    simp only [Prod.fst,Prod.snd]
    have hadd : i2.val=i.val+1 := by have := add_ok_val hi2; scalar_tac
    refine ⟨⟨trivial,by omega,?_⟩,by omega⟩
    simpa only [hadd,P,EqualityDecision] using he
end rustfs_kernel.Verified.RustfsStringEquals
