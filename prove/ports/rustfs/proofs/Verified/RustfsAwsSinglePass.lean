import Verified.RustfsAwsScanMeaning
import Verified.RustfsAwsPassMeaning
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsAwsPassMeaning
open RustfsAwsMeaning RustfsResolutionTerminates
set_option maxHeartbeats 2000000
 theorem pass_from_ok (ctx : awsvars.VarContext) (depth : Usize)
    (inner : List Nat → List (List Nat))
    (hs : ∀ (text : Slice U8) (d : Usize) (out : alloc.vec.Vec (alloc.vec.Vec U8)),
      d.val=depth.val+1 → awsvars.resolve_aws_variables_with_depth ctx text d=ok out →
        out.val.map (fun value => nats value.val)=inner (nats text.val))
    (results : alloc.vec.Vec awsvars.Pending) (i : Usize) (out : alloc.vec.Vec awsvars.Pending)
    (h : awsvars.pass_from ctx results i depth=ok out) :
    pendingTexts out.val=passMeaning inner (RustfsAwsValues.context ctx) results.val i.val := by
  induction hn : score (results.val.drop i.val) using Nat.strong_induction_on generalizing results i with
  | _ n ih =>
    rw [awsvars.pass_from] at h
    by_cases hi : i ≥ results.len
    · simp only [hi,↓reduceIte] at h
      have heq := (Result.ok.inj h).symm
      subst out
      have hb : results.val.length ≤ i.val := by scalar_tac
      simp [passMeaning,List.take_of_length_le hb,List.drop_of_length_le hb]
    · simp only [hi,↓reduceIte] at h
      obtain ⟨p,hp,h⟩ := bind_tc_eq_ok.mp h
      have hpi := vec_index_slice_ok_get? hp
      obtain ⟨scanned,hscan,h⟩ := bind_tc_eq_ok.mp h
      rcases scanned with ⟨updated,modified⟩
      have hmeaning := scan_ok ctx depth inner hs results i p hpi p.resume (updated,modified) hscan
      have hscore := scan_post_ok ctx depth results i p hpi p.resume (by omega) (updated,modified) hscan
      cases modified with
      | true =>
        change awsvars.pass_from ctx updated i depth=ok out at h
        have hless : score (updated.val.drop i.val)<n := by
          simpa only [ScanPost,Prod.fst,Prod.snd,Bool.true_eq,ite_true,hn] using hscore
        have hout := ih _ hless updated i h rfl
        rw [hout]
        apply pass_meaning_replace
        · exact hmeaning.1
        · have hh := hmeaning.2
          change (updated.val.drop i.val).flatMap (pendingMeaning inner (RustfsAwsValues.context ctx))=
            pendingMeaning inner (RustfsAwsValues.context ctx) p ++
              (results.val.drop (i.val+1)).flatMap (pendingMeaning inner (RustfsAwsValues.context ctx)) at hh
          have hib := List.getElem?_eq_some_iff.mp hpi |>.1
          have hpe : results.val[i.val]=p := by simpa [List.getElem?_eq_getElem hib] using hpi
          rw [List.drop_eq_getElem_cons hib,hpe,List.flatMap_cons]
          exact hh
      | false =>
        have hh := hmeaning.2
        change updated=results ∧ pendingMeaning inner (RustfsAwsValues.context ctx) p=[nats p.text.val] at hh
        rcases hh with ⟨heq,hm⟩
        subst updated
        change (do let next ← i+1#usize; awsvars.pass_from ctx results next depth)=ok out at h
        obtain ⟨next,hnext,h⟩ := bind_tc_eq_ok.mp h
        have hnxt : next.val=i.val+1 := by have := add_ok_val hnext; scalar_tac
        have hless : score (results.val.drop next.val)<n := by
          rw [hnxt,←hn]
          exact score_skip results i p hpi
        have hout := ih _ hless results next h rfl
        rw [hout,hnxt]
        exact pass_meaning_advance inner (RustfsAwsValues.context ctx) results.val i.val p hpi hm
/-- One pass expands placeholders in order, resuming after inserted bytes. -/
theorem single_pass_ok (ctx : awsvars.VarContext) (depth : Usize)
    (inner : List Nat → List (List Nat))
    (hs : ∀ (text : Slice U8) (d : Usize) (out : alloc.vec.Vec (alloc.vec.Vec U8)),
      d.val=depth.val+1 → awsvars.resolve_aws_variables_with_depth ctx text d=ok out →
        out.val.map (fun value => nats value.val)=inner (nats text.val))
    (text : Slice U8) (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : awsvars.resolve_single_pass ctx text depth=ok out) :
    out.val.map (fun v => nats v.val)=ExpansionPass inner (RustfsAwsValues.context ctx) (nats text.val) := by
  rw [awsvars.resolve_single_pass] at h
  obtain ⟨copied,hcopied,h⟩ := bind_tc_eq_ok.mp h
  have ht := RustfsCleanCanonical.to_vec_ok text copied hcopied
  obtain ⟨pending,hpending,h⟩ := bind_tc_eq_ok.mp h
  have hp := RustfsBytes.push_ok hpending
  change pending.val=[{text:=copied,resume:=0#usize}] at hp
  obtain ⟨resolved,hresolved,h⟩ := bind_tc_eq_ok.mp h
  have hr := pass_from_ok ctx depth inner hs pending 0#usize resolved hresolved
  have ho := RustfsAwsCollections.texts_ok _ _ h
  simp only [RustfsForceDelete.deref_val] at ho
  rw [ho,List.map_map]
  change pendingTexts resolved.val=_
  rw [hr]
  simp [passMeaning,pendingTexts,hp,pendingMeaning,ResumeAlternatives,ht]

end rustfs_kernel.Verified.RustfsAwsPassMeaning
