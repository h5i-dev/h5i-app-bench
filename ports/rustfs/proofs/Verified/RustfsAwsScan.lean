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
end rustfs_kernel.Verified.RustfsAwsScan
