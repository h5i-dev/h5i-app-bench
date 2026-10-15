import Verified.RustfsAwsCollections
import SpecAwsResolution
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsAwsPasses
set_option maxHeartbeats 2000000
set_option linter.unusedSimpArgs false
def texts (xs : List (alloc.vec.Vec U8)) : List (List Nat) := xs.map (fun v => nats v.val)
theorem pass_all_ok (ctx : awsvars.VarContext) (depth : Usize)
    (pass : List Nat → List (List Nat))
    (hn : ∀ text, pass text ≠ [])
    (hs : ∀ (text : Slice U8) (out : alloc.vec.Vec (alloc.vec.Vec U8)),
      awsvars.resolve_single_pass ctx text depth = ok out → texts out.val=pass (nats text.val))
    (results : Slice (alloc.vec.Vec U8)) (k : Usize)
    (acc : alloc.vec.Vec (alloc.vec.Vec U8)) (changed : Bool)
    (out : alloc.vec.Vec (alloc.vec.Vec U8) × Bool)
    (h : awsvars.pass_all ctx results k acc changed depth=ok out) :
    texts out.1.val = texts acc.val ++ ((texts (results.val.drop k.val)).flatMap pass) ∧
      out.2 = (changed || (texts (results.val.drop k.val)).any (fun text => decide (pass text ≠ [text]))) := by
  induction hm : results.val.length+1-k.val using Nat.strong_induction_on generalizing k acc changed with
  | _ n ih =>
    rw [awsvars.pass_all] at h
    h5i_invert h
    · have hk : results.val.length ≤ k.val := by scalar_tac
      simp [List.drop_of_length_le hk,texts]
    · obtain ⟨hlt,he⟩ := slice_index_ok hv
      have hp := hs _ _ hresolved
      simp only [RustfsForceDelete.deref_val] at hp
      have hnon : texts resolved.val ≠ [] := by rw [hp]; exact hn _
      have hd : differs = decide (pass (nats v.val) ≠ [nats v.val]) := by
        rw [←hp]
        h5i_invert hdiffers
        · have hlen : 1 < resolved.val.length := by scalar_tac
          have hne : texts resolved.val ≠ [nats v.val] := by
            intro hh
            have hh' := congrArg List.length hh
            simp [texts] at hh'
            omega
          simp [hne]
        · obtain ⟨hiv,hve⟩ := vec_index_ok hv1
          have hlen : resolved.val.length=1 := by scalar_tac
          have hx : resolved.val=[v1] := by
            apply List.ext_getElem?
            intro j
            by_cases hj : j=0
            · subst j
              rw [List.getElem?_eq_getElem (show 0 < resolved.val.length by omega)]
              simpa using congrArg some hve
            · rw [List.getElem?_eq_none (by omega),List.getElem?_eq_none (by simp; omega)]
          have hb' := RustfsForceDelete.bytes_eq_ok _ _ _ hb
          simp only [RustfsForceDelete.deref_val] at hb'
          have hh : nats v1.val=nats v.val ↔ v1.val=v.val :=
            ⟨RustfsForceDelete.nats_inj,congrArg nats⟩
          apply Bool.eq_iff_iff.mpr
          simp [texts,hx,hh,←hb']
        · have hlen : resolved.val.length=0 := by scalar_tac
          have hx : resolved.val=[] := List.eq_nil_iff_length_eq_zero.mpr hlen
          simp [hx,texts] at hnon
      have ha := RustfsAwsCollections.extend_ok _ _ _ hacc1
      simp only [RustfsForceDelete.deref_val] at ha
      have hadd : i2.val=k.val+1 := by have := add_ok_val hi2; scalar_tac
      have hd1 : differs1 = (changed || differs) := by
        cases changed <;> simpa using (Result.ok.inj hdiffers1).symm
      have hi := ih (results.val.length+1-i2.val) (by omega) i2 acc1 differs1 h rfl
      have hdrop : results.val.drop k.val = v :: results.val.drop (k.val+1) := by
        rw [List.drop_eq_getElem_cons hlt]
        rw [he]
      simp only [hdrop,texts,List.map_cons,List.flatMap_cons,List.any_cons]
      rw [ha] at hi
      simp only [texts,List.map_append,hadd] at hi
      dsimp only [texts] at hp
      rw [hp] at hi
      rw [hd1,hd] at hi
      simpa only [List.append_assoc,Bool.or_assoc] using hi
theorem unique_nats (xs : List (List U8)) :
    (UniqueBytes xs).map nats=DistinctTexts (xs.map nats) := by
  unfold UniqueBytes DistinctTexts
  rw [List.foldl_map]
  symm
  apply List.foldl_hom (List.map nats) (init := ([] : List (List U8)))
    (g₁ := fun acc text => if text ∈ acc then acc else acc++[text])
    (g₂ := fun acc text => if nats text ∈ acc then acc else acc++[nats text])
  intro acc value
  have hm : nats value ∈ acc.map nats ↔ value ∈ acc := by
    constructor
    · intro h
      obtain ⟨other,ho,he⟩ := List.mem_map.mp h
      have he' := RustfsForceDelete.nats_inj he
      simpa only [he'] using ho
    · intro h; exact List.mem_map.mpr ⟨value,h,rfl⟩
  simp only [hm]
  split <;> simp_all
theorem fixpoint_ok (ctx : awsvars.VarContext) (depth : Usize)
    (pass : List Nat → List (List Nat))
    (hn : ∀ text, pass text ≠ [])
    (hs : ∀ (text : Slice U8) (out : alloc.vec.Vec (alloc.vec.Vec U8)),
      awsvars.resolve_single_pass ctx text depth=ok out → texts out.val=pass (nats text.val))
    (results : alloc.vec.Vec (alloc.vec.Vec U8)) (iteration : Usize)
    (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : awsvars.fixpoint ctx results iteration depth=ok out) :
    texts out.val=ExpansionRounds pass (10-iteration.val) (texts results.val) := by
  induction hm : 10-iteration.val using Nat.strong_induction_on generalizing iteration results with
  | _ n ih =>
    rw [awsvars.fixpoint] at h
    h5i_invert h
    · have hi : 10 ≤ iteration.val := by scalar_tac
      have hz : n=0 := by omega
      simp [hz,ExpansionRounds]
    · rcases x with ⟨new,changed⟩
      change (do
        let results1 ← awsvars.dedup (alloc.vec.Vec.deref new)
        if changed then do
          let i ← iteration + 1#usize
          awsvars.fixpoint ctx results1 i depth
        else ok results1) = ok out at h
      have hp := pass_all_ok ctx depth pass hn hs _ _ _ _ _ hx
      simp only [Prod.fst,Prod.snd,RustfsForceDelete.deref_val,
        UScalar.ofNatCore_val_eq,List.drop_zero,Bool.false_or] at hp
      have hempty : texts (alloc.vec.Vec.new (alloc.vec.Vec U8)).val=[] := rfl
      rw [hempty,List.nil_append] at hp
      have hlt : iteration.val < 10 := by scalar_tac
      have hnround : n= (10-(iteration.val+1))+1 := by omega
      rw [hnround,ExpansionRounds]
      rw [←hp.2]
      obtain ⟨next,hnext,h⟩ := bind_eq_ok.mp h
      have hd := RustfsAwsCollections.dedup_ok _ _ hnext
      simp only [RustfsForceDelete.deref_val] at hd
      have hd' : texts next.val = DistinctTexts ((texts results.val).flatMap pass) := by
        have hmap : texts next.val=(next.val.map (·.val)).map nats := by simp [texts,List.map_map]
        rw [hmap,hd,unique_nats]
        congr 1
        simpa only [texts,List.map_map,Function.comp_def] using hp.1
      cases changed with
      | false =>
        simp only [Bool.false_eq_true,ite_false] at h ⊢
        have he := Result.ok.inj h
        subst next
        exact hd'
      | true =>
        simp only [ite_true] at h ⊢
        obtain ⟨i,hi,h⟩ := bind_eq_ok.mp h
        have hv : i.val=iteration.val+1 := by have := add_ok_val hi; scalar_tac
        have hh := ih (10-i.val) (by omega) next i h rfl
        simpa only [hv,hd'] using hh
end rustfs_kernel.Verified.RustfsAwsPasses
