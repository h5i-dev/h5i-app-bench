import Verified.RustfsAwsMeaning
import Verified.RustfsAwsLayout
import Verified.RustfsResolutionTerminates
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsAwsMeaning
@[simp] theorem slice_val {α : Type} (v : alloc.vec.Vec α) : v.slice.val=v.val := by
  rw [←RustfsResolutionTerminates.deref_eq]
  exact RustfsForceDelete.deref_val v
set_option maxHeartbeats 2000000
 theorem wrap_length_ok (pre post : Slice U8) (values : Slice (alloc.vec.Vec U8))
    (offset : Usize) (out : alloc.vec.Vec awsvars.Pending)
    (h : awsvars.wrap_all pre values post offset=ok out) :
    out.val.length=values.val.length := by
  have hw := RustfsAwsCollections.wrap_ok pre post values offset out h
  have hl := congrArg List.length hw
  simpa only [List.length_map,WrappedValues] using hl
def ScanMeaning (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (results : alloc.vec.Vec awsvars.Pending) (i : Usize) (p : awsvars.Pending) (start : Usize)
    (out : alloc.vec.Vec awsvars.Pending × Bool) : Prop :=
  out.1.val.take i.val=results.val.take i.val ∧
    if out.2 then
      (out.1.val.drop i.val).flatMap (pendingMeaning inner c)=
        ResumeAlternatives inner c (nats p.text.val) start.val ++
          (results.val.drop (i.val+1)).flatMap (pendingMeaning inner c)
    else out.1=results ∧ ResumeAlternatives inner c (nats p.text.val) start.val=[nats p.text.val]
 theorem scan_ok (ctx : awsvars.VarContext) (depth : Usize)
    (inner : List Nat → List (List Nat))
    (hs : ∀ (text : Slice U8) (d : Usize) (out : alloc.vec.Vec (alloc.vec.Vec U8)),
      d.val=depth.val+1 → awsvars.resolve_aws_variables_with_depth ctx text d=ok out →
        out.val.map (fun value => nats value.val)=inner (nats text.val))
    (results : alloc.vec.Vec awsvars.Pending) (i : Usize) (p : awsvars.Pending)
    (hp : results.val[i.val]?=some p) (start : Usize)
    (out : alloc.vec.Vec awsvars.Pending × Bool)
    (h : awsvars.scan ctx results i start depth=ok out) :
    ScanMeaning inner (RustfsAwsValues.context ctx) results i p start out := by
  induction hn : p.text.val.length+1-start.val using Nat.strong_induction_on generalizing start with
  | _ n ih =>
    rw [awsvars.scan] at h
    simp only [RustfsResolutionTerminates.deref_eq] at h
    obtain ⟨entry,he,h⟩ := bind_tc_eq_ok.mp h
    have hi := vec_index_slice_ok_get? he
    rw [hp] at hi
    have heq : entry=p := (Option.some.inj hi).symm
    subst entry
    simp only [u8vec_clone,bind_ok,RustfsResolutionTerminates.deref_eq] at h
    obtain ⟨marker,hmarker,h⟩ := bind_tc_eq_ok.mp h
    have hmarkerVal : marker.val=[36#u8,123#u8] := by
      simp only [lift,Result.ok.injEq] at hmarker
      subst marker
      rfl
    obtain ⟨position,hposition,h⟩ := bind_tc_eq_ok.mp h
    have hf := RustfsFindExact.find_ok _ _ _ _ hposition
    simp only [RustfsForceDelete.deref_val,slice_val,hmarkerVal] at hf
    cases position with
    | none =>
      have heq := (Result.ok.inj h).symm
      subst out
      simp only [ScanMeaning,Prod.fst,Prod.snd,Bool.false_eq_true,ite_false,true_and]
      apply resume_literal
      simpa only [nats,List.map_drop] using RustfsAwsScan.no_marker_drop p.text.val start.val hf
    | some pos =>
      obtain ⟨bodyStart,hbodyStart,h⟩ := bind_tc_eq_ok.mp h
      have ha : bodyStart.val=pos.val+2 := by have := add_ok_val hbodyStart; scalar_tac
      obtain ⟨closing,hclosing,h⟩ := bind_tc_eq_ok.mp h
      rcases closing with ⟨ending,balance⟩
      change (if balance != 0#usize then ok (results,false) else _) = ok out at h
      by_cases hb : (balance != 0#usize)=true
      · simp only [hb,↓reduceIte] at h
        have heq := (Result.ok.inj h).symm
        subst out
        simp only [ScanMeaning,Prod.fst,Prod.snd,Bool.false_eq_true,ite_false,true_and]
        apply RustfsAwsScan.resume_unbalanced inner _ p.text.val start.val pos.val hf
        have hc := RustfsAwsClosing.closing_ok _ _ _ hclosing
        simp only [RustfsForceDelete.deref_val,ha] at hc
        have hc' := congrArg Prod.snd hc
        change balance.val=(ClosingAt (nats p.text.val) (pos.val+2) 1).2 at hc'
        rw [←hc']
        scalar_tac
      · simp only [hb,↓reduceIte] at h
        have hb0 : balance.val=0 := by scalar_tac
        obtain ⟨body,hbody,h⟩ := bind_tc_eq_ok.mp h
        obtain ⟨pre,hpre,h⟩ := bind_tc_eq_ok.mp h
        obtain ⟨next,hnext,h⟩ := bind_tc_eq_ok.mp h
        have hnxt : next.val=ending.val+1 := by have := add_ok_val hnext; scalar_tac
        obtain ⟨post,hpost,h⟩ := bind_tc_eq_ok.mp h
        have hbound : pos.val+2≤p.text.val.length := by simpa using hf.2.1.1
        obtain ⟨closing,hclose,hend,hbodyval,hpreval,hpostval,hendbound⟩ :=
          RustfsAwsLayout.balanced_layout p.text.slice pos bodyStart ending balance next
            body pre post ha hb0 hclosing hbody hpre hnxt hpost (by simpa using hbound)
        simp only [slice_val] at hclose hend hbodyval hpreval hpostval hendbound
        obtain ⟨marker2,hmarker2,h⟩ := bind_tc_eq_ok.mp h
        obtain ⟨nested,hnested,h⟩ := bind_tc_eq_ok.mp h
        have hmarker2Val : marker2.val=[36#u8,123#u8] := by
          simp only [lift,Result.ok.injEq] at hmarker2
          subst marker2
          rfl
        have hnestedVal := RustfsAwsScan.contains_marker_ok body.slice marker2 nested hmarker2Val hnested
        simp only [slice_val] at hnestedVal
        have hskip
            (hr : PlaceholderAlternatives inner (RustfsAwsValues.context ctx)
              ((nats (p.text.val.drop (pos.val+2))).take closing)
              ((36::123::nats (p.text.val.drop (pos.val+2))).take (closing+3))=
                [(36::123::nats (p.text.val.drop (pos.val+2))).take (closing+3)])
            (hscan : awsvars.scan ctx results i next depth=ok out) :
            ScanMeaning inner (RustfsAwsValues.context ctx) results i p start out := by
          have hdecrease : p.text.val.length+1-next.val<n := by
            have hstart : start.val ≤ pos.val := hf.1
            have hnextBound : next.val ≤ p.text.val.length := by omega
            have hnextGt : start.val < next.val := by omega
            omega
          have hrec := ih _ hdecrease next hscan rfl
          have hresume := RustfsAwsScan.resume_skip_placeholder inner (RustfsAwsValues.context ctx)
            p.text.val start.val pos.val closing hf hclose hr
          have hnextval : next.val=pos.val+closing+3 := by omega
          simpa only [ScanMeaning,hnextval,←hresume] using hrec
        have hfinish (values : alloc.vec.Vec (alloc.vec.Vec U8))
            (new final : alloc.vec.Vec awsvars.Pending)
            (hr : PlaceholderAlternatives inner (RustfsAwsValues.context ctx)
              ((nats (p.text.val.drop (pos.val+2))).take closing)
              ((36::123::nats (p.text.val.drop (pos.val+2))).take (closing+3))=
                values.val.map (fun value => nats value.val))
            (hw : awsvars.wrap_all pre.slice values.slice post.slice pos=ok new)
            (hsplice : awsvars.splice results.slice i new.slice=ok final) :
            ScanMeaning inner (RustfsAwsValues.context ctx) results i p start (final,true) := by
          have hi : i.val≤results.val.length := by
            have := List.getElem?_eq_some_iff.mp hp |>.1
            omega
          exact wrapped_scan_ok inner (RustfsAwsValues.context ctx) p.text.val start.val pos.val closing
            hf hclose pre.slice post.slice values.slice pos hpreval hpostval rfl hr
            results.slice i new final hi hw hsplice
        h5i_invert h
        all_goals
          try
            have hdepth : i4.val=depth.val+1 := by
              have hd := add_ok_val hi4
              scalar_tac
            have hinner := hs body.slice i4 inner_1 hdepth hinner_1
            simp only [slice_val] at hinner
            have hnest : HasPlaceholder (nats body.val)=true := hnestedVal.symm.trans hc
          try
            have hlength : inner_1.val.length=1 := by scalar_tac
            have hvget := vec_index_slice_ok_get? hv
            have hsingle : inner_1.val=[v] := by
              obtain ⟨q,hq⟩ := List.length_eq_one_iff.mp hlength
              simpa [hq] using hvget
            have heq := RustfsVariableResolve.equal_nats _ _ _ hb1
            simp only [slice_val] at heq
        case isTrue.isTrue.isTrue =>
          have hlength : inner_1.val.length=1 := by
            have hl := congrArg UScalar.val hc_1
            simpa only [alloc.vec.Vec.len,Slice.len_val,Slice.length,slice_val,UScalar.ofNatCore_val_eq,Usize.ofNatCore_val_eq] using hl
          have hvget := vec_index_slice_ok_get? hv
          have hsingle : inner_1.val=[v] := by
            obtain ⟨q,hq⟩ := List.length_eq_one_iff.mp hlength
            simpa [hq] using hvget
          have heq := RustfsVariableResolve.equal_nats _ _ _ hb1
          simp only [slice_val] at heq
          apply hskip ?_ h
          have hsame := heq.mp hc_2
          rw [hsingle] at hinner
          simp only [List.map_cons,List.map_nil,hsame] at hinner
          rw [←hbodyval]
          simp [PlaceholderAlternatives,hnest,←hinner]
        all_goals
          try
            have hwraplen := wrap_length_ok pre.slice post.slice _ pos new hnew
            simp only [slice_val] at hwraplen
        case isTrue.isTrue.isFalse.isTrue =>
          apply hfinish inner_1 new v1 ?_ hnew hv1
          rw [←hbodyval]
          have hnonnil : inner (nats body.val)≠[] := by rw [←hinner,hsingle]; simp
          have hneq : inner (nats body.val)≠[nats body.val] := by
            rw [←hinner,hsingle]
            intro he
            simp only [List.map_cons,List.map_nil,List.cons.injEq,and_true] at he
            exact hc_2 (heq.mpr he)
          simp only [PlaceholderAlternatives,hnest,ite_true,hnonnil,hneq,or_self,ite_false]
          exact hinner.symm
        case isTrue.isTrue.isFalse.isFalse =>
          have hz : new.val.length=0 := by scalar_tac
          rw [hsingle] at hwraplen
          simp only [List.length_cons,List.length_nil] at hwraplen
          omega
        case isTrue.isFalse.isTrue =>
          apply hfinish inner_1 new v1 ?_ hnew hv1
          rw [←hbodyval]
          have hnonnil : inner (nats body.val)≠[] := by
            intro he
            have hnil := List.map_eq_nil_iff.mp (hinner.trans he)
            rw [hnil] at hwraplen
            simp only [List.length_nil] at hwraplen
            scalar_tac
          have hneq : inner (nats body.val)≠[nats body.val] := by
            intro he
            have hl := congrArg List.length (hinner.trans he)
            simp only [List.length_map,List.length_cons,List.length_nil] at hl
            apply hc_1
            scalar_tac
          simp only [PlaceholderAlternatives,hnest,ite_true,hnonnil,hneq,or_self,ite_false]
          exact hinner.symm
        case isTrue.isFalse.isFalse =>
          have hz : new.val.length=0 := by scalar_tac
          have hnil : inner_1.val=[] := List.length_eq_zero_iff.mp (by omega)
          have hinnernil : inner (nats body.val)=[] := by rw [←hinner,hnil]; rfl
          apply hskip ?_ h
          rw [←hbodyval]
          simp [PlaceholderAlternatives,hnest,hinnernil]
        case h_1 =>
          apply hskip ?_ h
          have hm := RustfsAwsValues.multiple_ok ctx body.slice none ho1
          simp only [slice_val,Option.map_none] at hm
          have hnot : HasPlaceholder (nats body.val)=false := hnestedVal.symm.trans (Bool.eq_false_iff.mpr hc)
          rw [←hbodyval]
          simp [PlaceholderAlternatives,hnot,←hm]
        case h_2.isTrue =>
          apply hfinish l new v1 ?_ hnew hv1
          have hm := RustfsAwsValues.multiple_ok ctx body.slice (some l) ho1
          simp only [slice_val,Option.map_some] at hm
          have hnot : HasPlaceholder (nats body.val)=false := hnestedVal.symm.trans (Bool.eq_false_iff.mpr hc)
          rw [←hbodyval]
          cases hl : l.val with
          | nil =>
            have hz : l.val.length=0 := by rw [hl]; rfl
            scalar_tac
          | cons value rest =>
            simp only [hl,List.map_cons] at hm ⊢
            simp [PlaceholderAlternatives,hnot,←hm]
        case h_2.isFalse =>
          have hz : l.val.length=0 := by scalar_tac
          have hnil := List.length_eq_zero_iff.mp hz
          have hm := RustfsAwsValues.multiple_ok ctx body.slice (some l) ho1
          simp only [slice_val,Option.map_some,hnil,List.map_nil] at hm
          have hnot : HasPlaceholder (nats body.val)=false := hnestedVal.symm.trans (Bool.eq_false_iff.mpr hc)
          have hr : PlaceholderAlternatives inner (RustfsAwsValues.context ctx)
              ((nats (p.text.val.drop (pos.val+2))).take closing)
              ((36::123::nats (p.text.val.drop (pos.val+2))).take (closing+3))=[[]] := by
            rw [←hbodyval]
            simp [PlaceholderAlternatives,hnot,←hm]
          have hii : i.val≤results.val.length := by
            have := List.getElem?_eq_some_iff.mp hp |>.1
            omega
          exact empty_scan_ok inner (RustfsAwsValues.context ctx) p.text.val start.val pos.val closing
            hf hclose pre.slice post.slice pos hpreval hpostval rfl hr
            results.slice i v_1 new v1 hii hv_1 hnew hv1

end rustfs_kernel.Verified.RustfsAwsMeaning
