import Verified.RustfsPathMeaning
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsPathLoop
set_option maxHeartbeats 2000000
open RustfsCleanCanonical RustfsPathMeaning
lemma drop_index (text : List Nat) (r c : Nat) (h : text[r]?=some c) :
    text.drop r=c::text.drop (r+1) := by
  have hr : r<text.length := by exact (List.getElem?_eq_some_iff.mp h).1
  rw [List.drop_eq_getElem_cons hr]
  congr 1
  exact Option.some.inj ((List.getElem?_eq_getElem hr).symm.trans h)
lemma norm_slash root d out rest :
    NormalizeTail root d out (47::rest)=NormalizeTail root d out rest := by
  simp only [NormalizeTail]
lemma norm_dot root d out rest (hr : rest=[] ∨ rest.head?=some 47) :
    NormalizeTail root d out (46::rest)=NormalizeTail root d out rest := by
  rcases hr with rfl | hr
  · rw [NormalizeTail,NormalizeTail]
  · cases rest with
    | nil => simp at hr
    | cons c cs =>
      simp only [List.head?_cons,Option.some.injEq] at hr
      subst c
      simp only [NormalizeTail]
lemma norm_parent root d out rest (hr : rest=[] ∨ rest.head?=some 47) :
    NormalizeTail root d out (46::46::rest)=
      NormalizeTail root (ParentPath root d out).2 (ParentPath root d out).1 rest := by
  rcases hr with rfl | hr
  · rw [NormalizeTail,NormalizeTail]
  · cases rest with
    | nil => simp at hr
    | cons c cs =>
      simp only [List.head?_cons,Option.some.injEq] at hr
      subst c
      simp only [NormalizeTail]
lemma norm_ordinary root d out (input : List Nat)
    (hn : input≠[]) (hs : input.head?≠some 47)
    (hd : input≠[46] ∧ (∀ rest, input≠46::47::rest) ∧ input≠[46,46] ∧
      (∀ rest,input≠46::46::47::rest)) :
    NormalizeTail root d out input=
      NormalizeTail root d
        (out ++ (if out.length=(if root then 1 else 0) then [] else [47]) ++
           input.takeWhile (fun c => c != 47))
        (input.dropWhile (fun c => c != 47)) := by
  fun_cases NormalizeTail root d out input <;> simp_all
lemma next_drop (p : Slice U8) (r next : Usize) (c : U8)
    (hi : p.index_usize r=ok c) (hv : next.val=r.val+1) :
    (nats p.val).drop r.val=c.val::(nats p.val).drop next.val := by
  rw [drop_index _ _ _ (index_nat hi),hv]
lemma end_drop (p : Slice U8) (r : Usize) (h : r.val≥p.val.length) :
    (nats p.val).drop r.val=[] := by
  simp only [List.drop_eq_nil_iff,nats,List.length_map]
  exact h
def Meaning (p : Slice U8) (root : Bool) (b : alloc.vec.Vec U8) (w r d : Usize) : List Nat :=
  NormalizeTail root d.val (pref b w) ((nats p.val).drop r.val)
def StepMeaning (p : Slice U8) (expected : List Nat) :
    ControlFlow (Bool × alloc.vec.Vec U8 × Usize × Usize × Usize) (alloc.vec.Vec U8 × Usize) → Prop
  | .cont (root,b,w,r,d) => Meaning p root b w r d=expected
  | .done (b,w) => pref b w=expected
lemma parent_step (p : Slice U8) (root : Bool) (b : alloc.vec.Vec U8) (w r next d : Usize) (res)
    (hw : w.val≤b.val.length)
    (ht : (nats p.val).drop r.val=46::46::(nats p.val).drop next.val)
    (hr : (nats p.val).drop next.val=[] ∨ ((nats p.val).drop next.val).head?=some 47)
    (h : parent root b w next d=ok res) : StepMeaning p (Meaning p root b w r d) res := by
  obtain ⟨b',w',d',he,hpair⟩ := parent_meaning root b w next d res hw h
  rw [he]
  dsimp only [StepMeaning,Meaning]
  have hp := congrArg Prod.fst hpair
  have hd := congrArg Prod.snd hpair
  dsimp only at hp hd
  rw [hp,hd,ht]
  exact (norm_parent root d.val (pref b w) _ hr).symm
lemma ordinary_step (p : Slice U8) (root : Bool) (b : alloc.vec.Vec U8) (w r d : Usize) (res)
    (hw : w.val≤b.val.length) (hr : r.val<p.val.length)
    (hs : (nats p.val)[r.val]?≠some 47)
    (hd : (nats p.val).drop r.val≠[46] ∧
      (∀ rest, (nats p.val).drop r.val≠46::47::rest) ∧
      (nats p.val).drop r.val≠[46,46] ∧
      (∀ rest,(nats p.val).drop r.val≠46::46::47::rest))
    (h : ordinary root b w r d p=ok res) : StepMeaning p (Meaning p root b w r d) res := by
  obtain ⟨b',w',r',he,hp,ht⟩ := ordinary_meaning root b w r d p res hw hr hs h
  rw [he]
  dsimp only [StepMeaning,Meaning]
  rw [hp,ht]
  have hl := pref_length b w hw
  rw [←hl]
  apply (norm_ordinary root d.val (pref b w) _ ?_ ?_ hd).symm
  · intro he
    have hl := congrArg List.length he
    simp only [List.length_drop,nats,List.length_map,List.length_nil] at hl
    omega
  · simpa only [List.head?_drop] using hs
theorem step_meaning (p : Slice U8) (n : Usize) (root : Bool) (b : alloc.vec.Vec U8)
    (w r d : Usize) (res) (hn : n.val=p.val.length) (hi : Inv root b w d)
    (hs : pathclean.clean_loop0.body p n root b w r d=ok res) :
    StepMeaning p (Meaning p root b w r d) res := by
  unfold pathclean.clean_loop0.body at hs
  simp only [←ordinary.eq_def,←parent.eq_def] at hs
  h5i_invert hs
  · dsimp only [StepMeaning,Meaning]
    have hv := add_ok_val hr1
    simp only [UScalar.ofNatCore_val_eq] at hv
    have ht := next_drop p r r1 i hi_1 hv
    have hc : i=47#u8 := by assumption
    rw [ht,hc]
    simp only [UScalar.ofNatCore_val_eq,norm_slash]
  · dsimp only [StepMeaning,Meaning]
    have hv := add_ok_val hi1
    simp only [UScalar.ofNatCore_val_eq] at hv
    have ht := next_drop p r i1 i hi_1 hv
    have hc : i=46#u8 := by assumption
    have he := end_drop p i1 (by scalar_tac)
    rw [ht,hc]
    simp only [UScalar.ofNatCore_val_eq]
    exact (norm_dot root d.val (pref b w) _ (Or.inl he)).symm
  · dsimp only [StepMeaning,Meaning]
    have hv := add_ok_val hi1
    simp only [UScalar.ofNatCore_val_eq] at hv
    have ht := next_drop p r i1 i hi_1 hv
    have hc : i=46#u8 := by assumption
    have hc2 : i2=47#u8 := by assumption
    have hh : ((nats p.val).drop i1.val).head?=some 47 := by
      simpa only [List.head?_drop,hc2,UScalar.ofNatCore_val_eq] using index_nat hi2
    rw [ht,hc]
    simp only [UScalar.ofNatCore_val_eq]
    exact (norm_dot root d.val (pref b w) _ (Or.inr hh)).symm
  · apply parent_step p root b w r i4 d res hi.1 ?_ (Or.inl (end_drop p i4 (by scalar_tac))) hs
    have hv1 := add_ok_val hi1
    have hv4 := add_ok_val hi4
    simp only [UScalar.ofNatCore_val_eq] at hv1 hv4
    have ht0 := next_drop p r i1 i hi_1 hv1
    have ht1 := next_drop p i1 i4 i3 hi3 (by omega)
    simpa only [ht0,ht1,hc_2,hc_5,UScalar.ofNatCore_val_eq]
  · apply parent_step p root b w r i4 d res hi.1 ?_ ?_ hs
    · have hv1 := add_ok_val hi1
      have hv4 := add_ok_val hi4
      simp only [UScalar.ofNatCore_val_eq] at hv1 hv4
      have ht0 := next_drop p r i1 i hi_1 hv1
      have ht1 := next_drop p i1 i4 i3 hi3 (by omega)
      simpa only [ht0,ht1,hc_2,hc_5,UScalar.ofNatCore_val_eq]
    · right
      simpa only [List.head?_drop,hc_7,UScalar.ofNatCore_val_eq] using index_nat hi5
  · apply ordinary_step p root b w r d res hi.1 (by scalar_tac) (index_ne hi_1 hc_1) ?_ hs
    have hv1 := add_ok_val hi1
    have hv4 := add_ok_val hi4
    simp only [UScalar.ofNatCore_val_eq] at hv1 hv4
    have ht0 := next_drop p r i1 i hi_1 hv1
    have ht1 := next_drop p i1 i4 i3 hi3 (by omega)
    have ht2 := drop_index _ _ _ (index_nat hi5)
    have hn5 : i5.val≠47 := by scalar_tac
    simp only [ht0,ht1,hc_2,hc_5,UScalar.ofNatCore_val_eq,ht2]
    simp_all
  · apply ordinary_step p root b w r d res hi.1 (by scalar_tac) (index_ne hi_1 hc_1) ?_ hs
    have hv1 := add_ok_val hi1
    simp only [UScalar.ofNatCore_val_eq] at hv1
    have ht0 := next_drop p r i1 i hi_1 hv1
    have ht1 := drop_index _ _ _ (index_nat hi3)
    have hi23 : i2=i3 := result_ok_inj (hi2.symm.trans hi3)
    have hn3 : i3.val≠46 ∧ i3.val≠47 := by constructor <;> scalar_tac
    simp only [ht0,hc_2,UScalar.ofNatCore_val_eq,ht1]
    simp_all
  · apply ordinary_step p root b w r d res hi.1 (by scalar_tac) (index_ne hi_1 hc_1) ?_ hs
    have ht := drop_index _ _ _ (index_nat hi_1)
    have hn : i.val≠46 := by scalar_tac
    simp only [ht]
    simp_all
  · dsimp only [StepMeaning,Meaning]
    rw [end_drop p r (by scalar_tac)]
    simp only [NormalizeTail]
theorem step_progress (p : Slice U8) (n : Usize) (root : Bool) (b : alloc.vec.Vec U8)
    (w r d : Usize) (res) (hn : n.val=p.val.length) (hi : Inv root b w d)
    (hs : pathclean.clean_loop0.body p n root b w r d=ok res) : Measured r res := by
  unfold pathclean.clean_loop0.body at hs
  simp only [← ordinary.eq_def, ← parent.eq_def] at hs
  h5i_invert hs
  · exact ⟨hi, by h5i_arith⟩
  · exact ⟨hi, by h5i_arith⟩
  · exact ⟨hi, by h5i_arith⟩
  · have hp := parent_ok root b w r i4 d res hi (by h5i_arith) hs
    cases res <;> exact progress_measure r _ hp
  · have hp := parent_ok root b w r i4 d res hi (by h5i_arith) hs
    cases res <;> exact progress_measure r _ hp
  · suffices hp : Progress r res by cases res <;> exact progress_measure r _ hp
    apply ordinary_ok root b w r d p res hi (by scalar_tac)
      (index_ne hi_1 hc_1)
    · right
      refine ⟨?_, by h5i_arith⟩
      have hnxt := index_ne hi2 hc_4
      have hv := add_ok_val hi1
      simp only [UScalar.ofNatCore_val_eq] at hv
      simpa only [hv, UScalar.ofNatCore_val_eq] using hnxt
    · exact hs
  · suffices hp : Progress r res by cases res <;> exact progress_measure r _ hp
    apply ordinary_ok root b w r d p res hi (by scalar_tac)
      (index_ne hi_1 hc_1)
    · right
      refine ⟨?_, by h5i_arith⟩
      have hnxt := index_ne hi2 hc_4
      have hv := add_ok_val hi1
      simp only [UScalar.ofNatCore_val_eq] at hv
      simpa only [hv, UScalar.ofNatCore_val_eq] using hnxt
    · exact hs
  · have hp := ordinary_ok root b w r d p res hi (by scalar_tac)
      (index_ne hi_1 hc_1) (Or.inl (index_ne hi_1 hc_2)) hs
    cases res <;> exact progress_measure r _ hp
  · exact ⟨root,hi.1,hi.2.2.1⟩
theorem main_meaning (p : Slice U8) (n : Usize) (root : Bool) (b : alloc.vec.Vec U8)
    (w r d : Usize) (out : alloc.vec.Vec U8 × Usize) (hn : n.val=p.val.length)
    (hi : Inv root b w d) (h : pathclean.clean_loop0 p n root b w r d=ok out) :
    pref out.1 out.2=Meaning p root b w r d := by
  unfold pathclean.clean_loop0 at h
  apply loop_ok _ (fun (root',b',w',r',d') => Inv root' b' w' d' ∧
      Meaning p root' b' w' r' d'=Meaning p root b w r d)
    (fun out => pref out.1 out.2=Meaning p root b w r d)
    (fun (_,_,_,r',_) => Usize.max-r'.val) ?_ (root,b,w,r,d) out ⟨hi,rfl⟩ h
  rintro ⟨root',b',w',r',d'⟩ res ⟨hinv,he⟩ hs
  have hm := step_meaning p n root' b' w' r' d' res hn hinv hs
  have hp := step_progress p n root' b' w' r' d' res hn hinv hs
  cases res with
  | done out => exact hm.trans he
  | cont x => exact ⟨⟨hp.1,hm.trans he⟩,hp.2⟩
end rustfs_kernel.Verified.RustfsPathLoop
