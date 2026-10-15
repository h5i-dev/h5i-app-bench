import Verified.RustfsAwsClosing
import Verified.RustfsExpansionModel
import Verified.RustfsFindExact
import Verified.RustfsAwsCollections
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsAwsScan
set_option maxHeartbeats 1000000
 theorem no_marker_occurrence (text : List U8) (h : HasPlaceholder (nats text)=false)
    (k : Nat) : ¬ ByteOccurrence text [36#u8,123#u8] k := by
  intro ho
  apply (placeholder_false_iff _).mp h k
  constructor
  · have he := ho.2 0 (by simp)
    have hm := congrArg (Option.map (fun x : U8 => x.val)) he
    simpa [nats,List.getElem?_map] using hm
  · have he := ho.2 1 (by simp)
    have hm := congrArg (Option.map (fun x : U8 => x.val)) he
    simpa [nats,List.getElem?_map] using hm

 theorem scan_literal_ok (ctx : awsvars.VarContext) (results : alloc.vec.Vec awsvars.Pending)
    (i start depth : Usize) (p : awsvars.Pending)
    (hp : results.val[i.val]?=some p) (hm : HasPlaceholder (nats p.text.val)=false)
    (out : alloc.vec.Vec awsvars.Pending × Bool)
    (h : awsvars.scan ctx results i start depth = ok out) : out=(results,false) := by
  rw [awsvars.scan] at h
  obtain ⟨entry,he,h⟩ := bind_tc_eq_ok.mp h
  have hi := vec_index_slice_ok_get? he
  rw [hp] at hi
  have heq : entry=p := (Option.some.inj hi).symm
  subst entry
  simp only [u8vec_clone,bind_ok] at h
  obtain ⟨marker,hmarker,h⟩ := bind_tc_eq_ok.mp h
  have hmarkerVal : marker.val=[36#u8,123#u8] := by
    simp only [lift,Result.ok.injEq] at hmarker
    subst marker
    rfl
  obtain ⟨position,hposition,h⟩ := bind_tc_eq_ok.mp h
  have hf := RustfsFindExact.find_ok _ _ _ _ hposition
  simp only [RustfsForceDelete.deref_val,hmarkerVal] at hf
  cases position with
  | none => exact (Result.ok.inj h).symm
  | some pos =>
    exact False.elim (no_marker_occurrence _ hm pos.val hf.2.1)
theorem pass_from_literal_ok (ctx : awsvars.VarContext) (results : alloc.vec.Vec awsvars.Pending)
    (i depth : Usize)
    (hm : ∀ p ∈ results.val, HasPlaceholder (nats p.text.val)=false)
    (out : alloc.vec.Vec awsvars.Pending)
    (h : awsvars.pass_from ctx results i depth = ok out) : out=results := by
  induction hn : results.val.length+1-i.val using Nat.strong_induction_on generalizing i with
  | _ n ih =>
    rw [awsvars.pass_from] at h
    split at h
    · exact (Result.ok.inj h).symm
    · obtain ⟨entry,he,h⟩ := bind_tc_eq_ok.mp h
      have hp := vec_index_slice_ok_get? he
      have hmem : entry ∈ results.val := List.mem_of_getElem? hp
      obtain ⟨scanned,hs,h⟩ := bind_tc_eq_ok.mp h
      have hscan := scan_literal_ok ctx results i entry.resume depth entry hp (hm entry hmem) scanned hs
      subst scanned
      change (do
        let next ← i + 1#usize
        awsvars.pass_from ctx results next depth) = ok out at h
      obtain ⟨next,hnxt,h⟩ := bind_tc_eq_ok.mp h
      have hadd := add_ok_val hnxt
      have hlt : i.val < results.val.length := (List.getElem?_eq_some_iff.mp hp).1
      exact ih (results.val.length+1-next.val) (by scalar_tac) next h rfl

 theorem single_pass_literal_ok (ctx : awsvars.VarContext) (text : Slice U8) (depth : Usize)
    (hm : HasPlaceholder (nats text.val)=false)
    (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : awsvars.resolve_single_pass ctx text depth = ok out) :
    out.val.map (fun v => nats v.val)=[nats text.val] := by
  rw [awsvars.resolve_single_pass] at h
  obtain ⟨copied,hcopied,h⟩ := bind_tc_eq_ok.mp h
  have ht : copied.val=text.val := by
    have hw : alloc.slice.Slice.to_vec core.clone.CloneU8 text ⦃ fun v => v.val=text.val ⦄ := by
      step*
      simp_all [alloc.vec.Vec.val]
    have hc := post_of_ok hw hcopied
    exact hc
  obtain ⟨pending,hpending,h⟩ := bind_tc_eq_ok.mp h
  have hp := RustfsBytes.push_ok hpending
  change pending.val=[{text:=copied,resume:=0#usize}] at hp
  obtain ⟨resolved,hresolved,h⟩ := bind_tc_eq_ok.mp h
  have hr := pass_from_literal_ok ctx pending 0#usize depth (by
    intro p hmem
    rw [hp] at hmem
    simp only [List.mem_singleton] at hmem
    subst p
    simpa only [ht] using hm) resolved hresolved
  subst resolved
  have ho := RustfsAwsCollections.texts_ok _ _ h
  simp only [RustfsForceDelete.deref_val,hp,List.map_cons,List.map_nil] at ho
  rw [ho]
  simp [ht]
theorem marker_occurrence_iff (text : List U8) (k : Nat) :
    ByteOccurrence text [36#u8,123#u8] k ↔
      (nats text)[k]?=some 36 ∧ (nats text)[k+1]?=some 123 := by
  constructor
  · intro ho
    constructor
    · have hm := congrArg (Option.map (fun x : U8 => x.val)) (ho.2 0 (by simp))
      simpa [nats,List.getElem?_map] using hm
    · have hm := congrArg (Option.map (fun x : U8 => x.val)) (ho.2 1 (by simp))
      simpa [nats,List.getElem?_map] using hm
  · rintro ⟨ha,hb⟩
    have hex : ∀ (j v : Nat) (byte : U8), byte.val=v →
        (nats text)[j]?=some v → text[j]?=some byte := by
      intro j v byte hv he
      simp only [nats,List.getElem?_map] at he
      cases hx : text[j]? with
      | none => simp [hx] at he
      | some x =>
        simp only [hx,Option.map_some,Option.some.injEq] at he
        have hxv : x=byte := (u8_eq_iff x byte).mpr (he.trans hv.symm)
        simpa only [hxv]
    have hxa := hex k 36 36#u8 rfl ha
    have hxb := hex (k+1) 123 123#u8 rfl hb
    refine ⟨?_,?_⟩
    · have hlt := (List.getElem?_eq_some_iff.mp hxb).1
      simp only [List.length_cons,List.length_nil]
      omega
    · intro j hj
      simp only [List.length_cons,List.length_nil] at hj
      have hj : j=0 ∨ j=1 := by omega
      rcases hj with rfl | rfl
      · simpa using hxa
      · simpa using hxb
theorem first_marker_prefix (text : List U8) (pos : Nat)
    (hf : FirstOccurrence text [36#u8,123#u8] 0 (some pos)) :
    HasPlaceholder (nats (text.take pos))=false := by
  apply (placeholder_false_iff _).mpr
  intro k hk
  have hka : k < (text.take pos).length := by
    have ht := (List.getElem?_eq_some_iff.mp hk.1).1
    simpa [nats] using ht
  have hkb : k+1 < (text.take pos).length := by
    have ht := (List.getElem?_eq_some_iff.mp hk.2).1
    simpa [nats] using ht
  simp only [List.length_take] at hka hkb
  have hkp : k < pos := lt_of_lt_of_le hka (Nat.min_le_left _ _)
  have hkbp : k+1 < pos := lt_of_lt_of_le hkb (Nat.min_le_left _ _)
  apply hf.2.2 k (by omega) hkp
  apply (marker_occurrence_iff text k).mpr
  simpa [nats,List.getElem?_map,List.getElem?_take,hkp,hkbp] using hk

 theorem first_marker_split (text : List U8) (pos : Nat)
    (hf : FirstOccurrence text [36#u8,123#u8] 0 (some pos)) :
    nats text = nats (text.take pos) ++ 36::123::nats (text.drop (pos+2)) := by
  have hp : pos+2 ≤ text.length := by simpa using hf.2.1.1
  have ha := (marker_occurrence_iff text pos).mp hf.2.1
  have hlt : pos < (nats text).length := by simpa [nats] using (show pos<text.length by omega)
  have hlt1 : pos+1 < (nats text).length := by simpa [nats] using (show pos+1<text.length by omega)
  have hxa : (nats text)[pos]=36 := by simpa [List.getElem?_eq_getElem hlt] using ha.1
  have hxb : (nats text)[pos+1]=123 := by simpa [List.getElem?_eq_getElem hlt1] using ha.2
  have hd : (nats text).drop pos=36::123::(nats text).drop (pos+2) := by
    rw [List.drop_eq_getElem_cons hlt,hxa,List.drop_eq_getElem_cons hlt1,hxb]
  conv_lhs => rw [←List.take_append_drop pos (nats text),hd]
  simp [nats,List.map_take,List.map_drop]
theorem marker_drop_iff (text : List U8) (offset k : Nat) :
    ByteOccurrence (text.drop offset) [36#u8,123#u8] k ↔
      ByteOccurrence text [36#u8,123#u8] (offset+k) := by
  unfold ByteOccurrence
  simp only [List.length_drop,List.length_cons,List.length_nil,List.getElem?_drop]
  constructor
  · rintro ⟨hb,hv⟩
    refine ⟨by omega,?_⟩
    intro j hj
    simpa only [Nat.add_assoc,Nat.add_comm,Nat.add_left_comm] using hv j hj
  · rintro ⟨hb,hv⟩
    refine ⟨by omega,?_⟩
    intro j hj
    simpa only [Nat.add_assoc,Nat.add_comm,Nat.add_left_comm] using hv j hj

 theorem first_marker_drop (text : List U8) (offset pos : Nat)
    (hf : FirstOccurrence text [36#u8,123#u8] offset (some pos)) :
    FirstOccurrence (text.drop offset) [36#u8,123#u8] 0 (some (pos-offset)) := by
  refine ⟨by omega,?_,?_⟩
  · apply (marker_drop_iff text offset (pos-offset)).mpr
    simpa only [Nat.add_sub_of_le hf.1] using hf.2.1
  · intro k hk hp ho
    apply hf.2.2 (offset+k) (by omega) (by omega)
    exact (marker_drop_iff text offset k).mp ho

 theorem no_marker_drop (text : List U8) (offset : Nat)
    (hf : FirstOccurrence text [36#u8,123#u8] offset none) :
    HasPlaceholder (nats (text.drop offset))=false := by
  apply (placeholder_false_iff _).mpr
  intro k hk
  apply hf (offset+k) (by omega)
  apply (marker_drop_iff text offset k).mp
  exact (marker_occurrence_iff (text.drop offset) k).mpr hk
 theorem scan_suffix_literal_ok (ctx : awsvars.VarContext) (results : alloc.vec.Vec awsvars.Pending)
    (i start depth : Usize) (p : awsvars.Pending)
    (hp : results.val[i.val]?=some p) (hm : HasPlaceholder (nats (p.text.val.drop start.val))=false)
    (out : alloc.vec.Vec awsvars.Pending × Bool)
    (h : awsvars.scan ctx results i start depth = ok out) : out=(results,false) := by
  rw [awsvars.scan] at h
  obtain ⟨entry,he,h⟩ := bind_tc_eq_ok.mp h
  have hi := vec_index_slice_ok_get? he
  rw [hp] at hi
  have heq : entry=p := (Option.some.inj hi).symm
  subst entry
  simp only [u8vec_clone,bind_ok] at h
  obtain ⟨marker,hmarker,h⟩ := bind_tc_eq_ok.mp h
  have hmarkerVal : marker.val=[36#u8,123#u8] := by
    simp only [lift,Result.ok.injEq] at hmarker
    subst marker
    rfl
  obtain ⟨position,hposition,h⟩ := bind_tc_eq_ok.mp h
  have hf := RustfsFindExact.find_ok _ _ _ _ hposition
  simp only [RustfsForceDelete.deref_val,hmarkerVal] at hf
  cases position with
  | none => exact (Result.ok.inj h).symm
  | some pos =>
    have hd := first_marker_drop _ _ _ hf
    exact False.elim (no_marker_occurrence _ hm _ hd.2.1)
 theorem resume_first_marker (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (text : List U8) (offset pos : Nat)
    (hf : FirstOccurrence text [36#u8,123#u8] offset (some pos)) :
    ResumeAlternatives inner c (nats text) offset =
      (ExpansionPass inner c (36::123::nats (text.drop (pos+2)))).map
        (fun suffix => nats (text.take pos) ++ suffix) := by
  have hd := first_marker_drop text offset pos hf
  have hs := first_marker_split (text.drop offset) (pos-offset) hd
  have hn := first_marker_prefix (text.drop offset) (pos-offset) hd
  have hoffset : offset ≤ pos := hf.1
  have he : offset+(pos-offset)=pos := by omega
  have he2 : offset+(pos-offset+2)=pos+2 := by omega
  have hs' : (nats text).drop offset = nats ((text.drop offset).take (pos-offset)) ++
      36::123::nats (text.drop (pos+2)) := by
    simpa only [nats,List.map_drop,List.drop_drop,he2] using hs
  unfold ResumeAlternatives
  rw [hs',expansion_pre inner c _ _ hn]
  simp only [List.map_map,Function.comp_def]
  apply List.map_congr_left
  intro suffix _
  have hp : text.take offset ++ (text.drop offset).take (pos-offset)=text.take pos := by
    rw [←List.take_add,he]
  have hpn : (nats text).take offset ++ nats ((text.drop offset).take (pos-offset)) =
      nats (text.take pos) := by
    simpa only [nats,List.map_append,List.map_take] using congrArg nats hp
  simpa only [←List.append_assoc,hpn]
 theorem scan_unbalanced_ok (ctx : awsvars.VarContext) (results : alloc.vec.Vec awsvars.Pending)
    (i start depth : Usize) (p : awsvars.Pending) (pos : Nat)
    (hp : results.val[i.val]?=some p)
    (hf : FirstOccurrence p.text.val [36#u8,123#u8] start.val (some pos))
    (hb : (ClosingAt (nats p.text.val) (pos+2) 1).2 ≠ 0)
    (out : alloc.vec.Vec awsvars.Pending × Bool)
    (h : awsvars.scan ctx results i start depth = ok out) : out=(results,false) := by
  rw [awsvars.scan] at h
  obtain ⟨entry,he,h⟩ := bind_tc_eq_ok.mp h
  have hi := vec_index_slice_ok_get? he
  rw [hp] at hi
  have heq : entry=p := (Option.some.inj hi).symm
  subst entry
  simp only [u8vec_clone,bind_ok] at h
  obtain ⟨marker,hmarker,h⟩ := bind_tc_eq_ok.mp h
  have hmarkerVal : marker.val=[36#u8,123#u8] := by
    simp only [lift,Result.ok.injEq] at hmarker
    subst marker
    rfl
  obtain ⟨position,hposition,h⟩ := bind_tc_eq_ok.mp h
  have hfound := RustfsFindExact.find_ok _ _ _ _ hposition
  simp only [RustfsForceDelete.deref_val,hmarkerVal] at hfound
  cases position with
  | none => exact False.elim (hfound pos hf.1 hf.2.1)
  | some found =>
    have hpos : found.val=pos := by
      have he := RustfsFindExact.first_unique _ _ _ _ _ hfound hf
      exact Option.some.inj he
    obtain ⟨bodyStart,hbodyStart,h⟩ := bind_tc_eq_ok.mp h
    have hs := add_ok_val hbodyStart
    obtain ⟨closing,hclosing,h⟩ := bind_tc_eq_ok.mp h
    rcases closing with ⟨ending,balance⟩
    have hc := RustfsAwsClosing.closing_ok _ _ _ hclosing
    simp only [RustfsForceDelete.deref_val] at hc
    have hsval : bodyStart.val=pos+2 := by scalar_tac
    rw [hsval] at hc
    have hbalance : balance.val ≠ 0 := by
      have he := congrArg Prod.snd hc
      change balance.val=(ClosingAt (nats p.text.val) (pos+2) 1).2 at he
      rw [he]
      exact hb
    have htest : (balance != 0#usize) = true := by scalar_tac
    change (if balance != 0#usize then ok (results,false) else _) = ok out at h
    simp only [htest,↓reduceIte,Result.ok.injEq] at h
    exact h.symm
 theorem marker_split (text : List U8) (pos : Nat)
    (ho : ByteOccurrence text [36#u8,123#u8] pos) :
    nats text = nats (text.take pos) ++ 36::123::nats (text.drop (pos+2)) := by
  have hp : pos+2 ≤ text.length := by simpa using ho.1
  have ha := (marker_occurrence_iff text pos).mp ho
  have hlt : pos < (nats text).length := by simpa [nats] using (show pos<text.length by omega)
  have hlt1 : pos+1 < (nats text).length := by simpa [nats] using (show pos+1<text.length by omega)
  have hxa : (nats text)[pos]=36 := by simpa [List.getElem?_eq_getElem hlt] using ha.1
  have hxb : (nats text)[pos+1]=123 := by simpa [List.getElem?_eq_getElem hlt1] using ha.2
  have hd : (nats text).drop pos=36::123::(nats text).drop (pos+2) := by
    rw [List.drop_eq_getElem_cons hlt,hxa,List.drop_eq_getElem_cons hlt1,hxb]
  conv_lhs => rw [←List.take_append_drop pos (nats text),hd]
  simp [nats,List.map_take,List.map_drop]
theorem resume_unbalanced (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (text : List U8) (offset pos : Nat)
    (hf : FirstOccurrence text [36#u8,123#u8] offset (some pos))
    (hb : (ClosingAt (nats text) (pos+2) 1).2 ≠ 0) :
    ResumeAlternatives inner c (nats text) offset=[nats text] := by
  rw [resume_first_marker inner c text offset pos hf]
  cases hc : ClosingTail (nats (text.drop (pos+2))) 1 with
  | mk closing balance =>
    have hbalance : balance ≠ 0 := by
      have hc' := hc
      simp only [nats,List.map_drop] at hc'
      simpa only [ClosingAt,nats,List.map_drop,hc',Prod.snd] using hb
    simp only [ExpansionPass,hc,hbalance,ne_eq,not_false_eq_true,ite_true,List.map_cons,List.map_nil]
    rw [←marker_split text pos hf.2.1]
 theorem resume_skip_literal_prefix (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (text : List U8) (offset pos : Nat)
    (hf : FirstOccurrence text [36#u8,123#u8] offset (some pos)) :
    ResumeAlternatives inner c (nats text) offset=ResumeAlternatives inner c (nats text) pos := by
  have hs : FirstOccurrence text [36#u8,123#u8] pos (some pos) :=
    ⟨Nat.le_refl _,hf.2.1,fun k hk hp _ => by omega⟩
  rw [resume_first_marker inner c text offset pos hf,resume_first_marker inner c text pos pos hs]
theorem resume_skip_placeholder (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (text : List U8) (offset pos closing : Nat)
    (hf : FirstOccurrence text [36#u8,123#u8] offset (some pos))
    (hc : ClosingTail (nats (text.drop (pos+2))) 1=(closing,0))
    (hr : PlaceholderAlternatives inner c ((nats (text.drop (pos+2))).take closing)
      ((36::123::nats (text.drop (pos+2))).take (closing+3))=
      [(36::123::nats (text.drop (pos+2))).take (closing+3)]) :
    ResumeAlternatives inner c (nats text) offset =
      ResumeAlternatives inner c (nats text) (pos+closing+3) := by
  rw [resume_skip_literal_prefix inner c text offset pos hf]
  have hp : (nats (text.take pos)).length=pos := by
    have hb := hf.2.1.1
    simp only [List.length_cons,List.length_nil] at hb
    simp only [nats,List.length_map,List.length_take]
    omega
  have hs := marker_split text pos hf.2.1
  have he := resume_keep_placeholder inner c (nats (text.take pos))
    (nats (text.drop (pos+2))) closing hc hr
  rw [←hs,hp] at he
  exact he
 theorem resume_balanced (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (text : List U8) (offset pos closing : Nat)
    (hf : FirstOccurrence text [36#u8,123#u8] offset (some pos))
    (hc : ClosingTail (nats (text.drop (pos+2))) 1=(closing,0)) :
    ResumeAlternatives inner c (nats text) offset =
      (PlaceholderAlternatives inner c ((nats (text.drop (pos+2))).take closing)
        ((36::123::nats (text.drop (pos+2))).take (closing+3))).flatMap
          (fun replacement => (ExpansionPass inner c (nats (text.drop (pos+closing+3)))).map
            (fun suffix => nats (text.take pos) ++ replacement ++ suffix)) := by
  rw [resume_first_marker inner c text offset pos hf,expansion_marker inner c _ closing hc]
  simp only [List.map_flatMap,List.map_map,Function.comp_def,List.append_assoc]
  have he : (nats (text.drop (pos+2))).drop (closing+1)=nats (text.drop (pos+closing+3)) := by
    simp only [nats,List.map_drop,List.drop_drop]
    have hn : pos+2+(closing+1)=pos+closing+3 := by omega
    rw [hn]
  rw [he]
end rustfs_kernel.Verified.RustfsAwsScan
