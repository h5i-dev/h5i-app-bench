import SpecPath
import Verified.RustfsCleanCanonical
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsPathMeaning
set_option maxHeartbeats 2000000
open RustfsCleanCanonical
lemma previous_stop (text : List Nat) (floor w : Nat)
    (h : w ≤ floor ∨ text[w]?=some 47) : PreviousSlash text floor w=w := by
  cases w with
  | zero => rfl
  | succ n => simp only [PreviousSlash, h,↓reduceIte]
lemma previous_step (text : List Nat) (floor w : Nat)
    (hf : floor < w) (hn : text[w]? ≠ some 47) :
    PreviousSlash text floor w=PreviousSlash text floor (w-1) := by
  cases w with
  | zero => omega
  | succ n => simp only [PreviousSlash, show ¬ n+1 ≤ floor from by omega, hn, false_or,↓reduceIte,Nat.add_sub_cancel]
theorem back_ok (text : Slice U8) (w floor out : Usize)
    (h : pathclean.back_to_slash text w floor=ok out) :
    out.val=PreviousSlash (nats text.val) floor.val w.val := by
  unfold pathclean.back_to_slash pathclean.back_to_slash_loop at h
  refine loop_ok _ (fun k : Usize => PreviousSlash (nats text.val) floor.val k.val=
    PreviousSlash (nats text.val) floor.val w.val)
    (fun r => r.val=PreviousSlash (nats text.val) floor.val w.val)
    (fun k => k.val) ?_ w out rfl h
  intro k r hk hr
  unfold pathclean.back_to_slash_loop.body at hr
  h5i_invert hr
  · have hd := sub_ok_val hw1
    have hn := index_ne hi (by scalar_tac : i ≠ 47#u8)
    have hs := previous_step (nats text.val) floor.val k.val (by scalar_tac) hn
    simp only [UScalar.ofNatCore_val_eq] at hd
    refine ⟨?_,by scalar_tac⟩
    rw [hd.1,←hs,hk]
  · have hv := index_nat hi
    have he : i=47#u8 := by scalar_tac
    have hv' : (nats text.val)[k.val]?=some 47 := by simpa only [he,UScalar.ofNatCore_val_eq] using hv
    have hs := previous_stop (nats text.val) floor.val k.val (Or.inr hv')
    exact hs.symm.trans hk
  · have hs := previous_stop (nats text.val) floor.val k.val (Or.inl (by scalar_tac))
    exact hs.symm.trans hk
lemma previous_take (text : List Nat) (floor start count : Nat) (h : start < count) :
    PreviousSlash text floor start=PreviousSlash (text.take count) floor start := by
  induction start with
  | zero => rfl
  | succ n ih =>
    have hg : (text.take count)[n+1]?=text[n+1]? := by simp only [List.getElem?_take,h,↓reduceIte]
    simp only [PreviousSlash,hg]
    split
    · rfl
    · exact ih (by omega)
theorem copy_ok (b : alloc.vec.Vec U8) (w : Usize) (p : Slice U8) (start : Usize)
    (out : alloc.vec.Vec U8 × Usize × Usize) (hw : w.val ≤ b.val.length)
    (hstart : start.val ≤ p.val.length)
    (h : pathclean.copy_element b w p start=ok out) :
    out.2.2.val ≤ p.val.length ∧ start.val ≤ out.2.2.val ∧
    pref out.1 out.2.1=pref b w ++ ((nats p.val).drop start.val).take (out.2.2.val-start.val) ∧
    out.2.1.val=w.val+(out.2.2.val-start.val) ∧
    out.2.1.val ≤ out.1.val.length ∧
    (out.2.2.val=p.val.length ∨ (nats p.val)[out.2.2.val]?=some 47) := by
  let I := fun x : alloc.vec.Vec U8 × Usize × Usize =>
    x.2.2.val ≤ p.val.length ∧ start.val ≤ x.2.2.val ∧
    pref x.1 x.2.1=pref b w ++ ((nats p.val).drop start.val).take (x.2.2.val-start.val) ∧
    x.2.1.val=w.val+(x.2.2.val-start.val) ∧ x.2.1.val ≤ x.1.val.length
  unfold pathclean.copy_element pathclean.copy_element_loop at h
  suffices hh : I out ∧ (out.2.2.val=p.val.length ∨ (nats p.val)[out.2.2.val]?=some 47) by
    rcases hh with ⟨⟨ha,hb,hc,hd,he⟩,hf⟩
    exact ⟨ha,hb,hc,hd,he,hf⟩
  refine loop_ok _ I (fun x => I x ∧ (x.2.2.val=p.val.length ∨
    (nats p.val)[x.2.2.val]?=some 47)) (fun x => p.val.length-x.2.2.val) ?_
    (b,w,start) out ⟨hstart,by simp,by simp,by simp,hw⟩ h
  · rintro ⟨bb,ww,rr⟩ res ⟨hrb,hsr,he,hww,hwb⟩ hr
    dsimp only at hrb hsr he hww hwb ⊢
    unfold pathclean.copy_element_loop.body at hr
    h5i_invert hr
    · rcases x with ⟨x,f⟩
      obtain ⟨hb,rfl⟩ := mut_ok hx
      change (do
        let w1 ← ww + 1#usize
        let r1 ← rr + 1#usize
        ok (ControlFlow.cont (bb.set ww i1,w1,r1)))=ok res at hr
      h5i_invert hr
      have hwv := add_ok_val hw1
      have hrv := add_ok_val hr1
      simp only [UScalar.ofNatCore_val_eq] at hwv hrv
      have hidx := (slice_index_ok hi1).1
      have hnats := index_nat hi1
      have hlt : rr.val-start.val < ((nats p.val).drop start.val).length := by simp only [List.length_drop,nats,List.length_map]; omega
      have ht : ((nats p.val).drop start.val).take (r1.val-start.val)=
        ((nats p.val).drop start.val).take (rr.val-start.val) ++ [i1.val] := by
        have hd : r1.val-start.val=(rr.val-start.val)+1 := by omega
        rw [hd,List.take_succ_eq_append_getElem hlt]
        congr 1
        have hx : ((nats p.val).drop start.val)[rr.val-start.val]=i1.val := by
          simp only [List.getElem_drop]
          have hsum : start.val+(rr.val-start.val)=rr.val := by omega
          simp only [hsum]
          exact Option.some.inj ((List.getElem?_eq_getElem (by simpa [nats] using hidx)).symm.trans hnats)
        simp only [hx]
      dsimp only [I]
      refine ⟨⟨by omega,by omega,?_,by omega,?_⟩,by omega⟩
      · rw [pref_write bb ww w1 i1 hb hwv,he,ht,List.append_assoc]
      · simp only [alloc.vec.Vec.set_val_eq,List.length_set]; omega
    · have hi : i1=47#u8 := by scalar_tac
      exact ⟨⟨hrb,hsr,he,hww,hwb⟩,Or.inr (by simpa [hi] using index_nat hi1)⟩
    · exact ⟨⟨hrb,hsr,he,hww,hwb⟩,Or.inl (by scalar_tac)⟩
lemma segment_takeWhile (segment rest : List Nat) (hn : 47 ∉ segment)
    (hr : rest=[] ∨ rest.head?=some 47) :
    (segment++rest).takeWhile (fun c => c != 47)=segment := by
  rw [List.takeWhile_append_of_pos (by intro c hc; simp only [bne_iff_ne]; intro he; subst c; exact hn hc)]
  rcases hr with rfl | hr
  · simp
  · cases rest with
    | nil => simp
    | cons c cs => simp only [List.head?_cons,Option.some.injEq] at hr; subst c; simp

theorem copy_segment_ok (b : alloc.vec.Vec U8) (w : Usize) (p : Slice U8) (start : Usize)
    (out : alloc.vec.Vec U8 × Usize × Usize) (hw : w.val ≤ b.val.length)
    (hstart : start.val < p.val.length) (hchar : (nats p.val)[start.val]? ≠ some 47)
    (h : pathclean.copy_element b w p start=ok out) :
    let segment := ((nats p.val).drop start.val).takeWhile (fun c => c != 47)
    pref out.1 out.2.1=pref b w ++ segment ∧ out.2.2.val=start.val+segment.length := by
  obtain ⟨hrb,hsr,he,hwlen,hwb,hend⟩ := copy_ok b w p start out hw (Nat.le_of_lt hstart) h
  obtain ⟨segment,hs,_,_,_,hn,_,_⟩ := RustfsCleanCanonical.copy_ok b w p start out hw hstart hchar h
  have hseg : segment=((nats p.val).drop start.val).take (out.2.2.val-start.val) := by
    exact List.append_cancel_left (hs.symm.trans he)
  have hsplit : (nats p.val).drop start.val=segment++(nats p.val).drop out.2.2.val := by
    rw [hseg]
    have ht := (List.take_append_drop (out.2.2.val-start.val) ((nats p.val).drop start.val)).symm
    simpa only [List.drop_drop,show start.val+(out.2.2.val-start.val)=out.2.2.val from by omega] using ht
  have hrest : (nats p.val).drop out.2.2.val=[] ∨
      ((nats p.val).drop out.2.2.val).head?=some 47 := by
    rcases hend with hend | hend
    · left; simp only [nats,List.drop_eq_nil_iff,List.length_map]; omega
    · right; simpa only [List.head?_drop] using hend
  have htw : ((nats p.val).drop start.val).takeWhile (fun c => c != 47)=segment := by
    rw [hsplit]; exact segment_takeWhile segment _ hn hrest
  dsimp only
  rw [htw]
  refine ⟨hs,?_⟩
  have hl : segment.length=out.2.2.val-start.val := by
    rw [hseg,List.length_take,List.length_drop]
    simp only [nats,List.length_map]
    omega
  omega
theorem parent_meaning (root : Bool) (b : alloc.vec.Vec U8) (w next d : Usize) (res)
    (hw : w.val ≤ b.val.length)
    (h : parent root b w next d=ok res) :
    ∃ b' w' d', res=ControlFlow.cont (root,b',w',next,d') ∧
      (pref b' w',d'.val)=ParentPath root d.val (pref b w) := by
  unfold parent at h
  simp only [←relativeSep.eq_def,←dots.eq_def] at h
  h5i_invert h
  · refine ⟨b,w2,d,rfl,?_⟩
    have hv := sub_ok_val hw1
    simp only [UScalar.ofNatCore_val_eq] at hv
    have hb := back_ok _ _ _ _ hw2
    have ht := previous_take (nats b.val) d.val w1.val w.val (by scalar_tac)
    have hp : (nats b.val).take w.val=pref b w := by simp only [pref,nats,List.map_take]
    simp only [alloc.vec.Vec.deref,Slice.from_val] at hb
    change w2.val=PreviousSlash (nats b.val) d.val w1.val at hb
    rw [hp] at ht
    have he : w2.val=PreviousSlash (pref b w) d.val (w.val-1) := by rw [hb,ht,hv.1]
    have hle : w2.val ≤ w.val := by
      have hh := RustfsCleanCanonical.back_ok _ _ _ _ (by scalar_tac : d.val ≤ w1.val) hw2
      scalar_tac
    simp only [ParentPath,pref_length b w hw,show w.val>d.val from by scalar_tac,↓reduceIte]
    congr 1
    rw [←he,pref_take b w w2.val hle]
    rfl
  · have hroot : root=true := hc_1
    subst root
    refine ⟨b,w,d,rfl,?_⟩
    simp only [ParentPath,pref_length b w hw,show ¬w.val>d.val from by scalar_tac,↓reduceIte]
  · rcases x with ⟨b1,w1⟩
    change dots b1 w1 next=ok res at h
    have hroot : root=false := by cases root <;> simp_all
    subst root
    obtain ⟨b2,w2,he,hb2,hpref⟩ := dots_ok b1 w1 next res h
    refine ⟨b2,w2,w2,he,?_⟩
    rw [relativeSep_eq] at hx
    obtain ⟨hb1,hp1⟩ := separator_ok false b w (b1,w1) hw hx
    dsimp only at hb1 hp1
    have hz : pref b w=[] ↔ w.val=0 := by
      constructor
      · intro hh; have hh:=congrArg List.length hh; rw [pref_length b w hw] at hh; exact hh
      · intro hh; simp only [pref,hh,List.take_zero,nats,List.map_nil]
    have hn : ¬ w.val>d.val := by scalar_tac
    simp only [ParentPath,pref_length b w hw,hn,↓reduceIte,Bool.false_eq_true,↓reduceIte]
    have heq : pref b2 w2=pref b w ++ (if pref b w=[] then [] else [47]) ++ [46,46] := by
      rw [hpref,hp1]; simp only [Bool.false_eq_true,↓reduceIte,hz]
    refine Prod.ext heq ?_
    have hl:=congrArg List.length heq
    rw [pref_length b2 w2 hb2] at hl
    exact hl
theorem ordinary_meaning (root : Bool) (b : alloc.vec.Vec U8) (w r d : Usize) (p : Slice U8) (res)
    (hw : w.val ≤ b.val.length) (hr : r.val < p.val.length)
    (hc : (nats p.val)[r.val]? ≠ some 47)
    (h : ordinary root b w r d p=ok res) :
    ∃ b' w' r', res=ControlFlow.cont (root,b',w',r',d) ∧
      pref b' w'=pref b w ++ (if w.val=(if root then 1 else 0) then [] else [47]) ++
        ((nats p.val).drop r.val).takeWhile (fun c => c != 47) ∧
      (nats p.val).drop r'.val=((nats p.val).drop r.val).dropWhile (fun c => c != 47) := by
  unfold ordinary at h
  rw [←separator] at h
  obtain ⟨⟨b1,w1⟩,hsep,h⟩ := bind_tc_eq_ok.mp h
  obtain ⟨⟨b2,w2,r2⟩,hcopy,h⟩ := bind_tc_eq_ok.mp h
  change ok (ControlFlow.cont (root,b2,w2,r2,d))=ok res at h
  refine ⟨b2,w2,r2,(result_ok_inj h).symm,?_,?_⟩
  · obtain ⟨hb,hp⟩ := separator_ok root b w (b1,w1) hw hsep
    obtain ⟨he,_⟩ := copy_segment_ok b1 w1 p r (b2,w2,r2) hb hr hc hcopy
    rw [he,hp]
  · obtain ⟨hb,_⟩ := separator_ok root b w (b1,w1) hw hsep
    obtain ⟨_,he⟩ := copy_segment_ok b1 w1 p r (b2,w2,r2) hb hr hc hcopy
    have ht := List.takeWhile_append_dropWhile (p := fun c : Nat => c != 47) (l := (nats p.val).drop r.val)
    have hd := congrArg (List.drop (((nats p.val).drop r.val).takeWhile (fun c => c != 47)).length) ht
    simp only [List.drop_left] at hd
    rw [hd,List.drop_drop,he]
end rustfs_kernel.Verified.RustfsPathMeaning
