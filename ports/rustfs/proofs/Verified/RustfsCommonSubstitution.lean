import SpecCommonSubstitution
import Verified.RustfsReplace
import Verified.RustfsOperatorLookup
import Verified.RustfsCommonKeys
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsCommonSubstitution
set_option linter.unusedSimpArgs false
 theorem bytes_nats (xs : List U8) : BytesOfNats (nats xs) = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    simp only [nats,BytesOfNats,List.map_cons] at ih ⊢
    congr 1
    · apply UScalar.eq_of_val_eq
      simp only [ByteOfNat,UScalar.ofNatCore_val_eq]
      apply Nat.mod_eq_of_lt
      scalar_tac
 theorem common_bytes_ok (i : Usize) (out : alloc.vec.Vec U8 × alloc.vec.Vec U8)
    (h : keynames.common_key i = ok out) :
    (out.1.val,out.2.val) = (CommonByteEntries[i.val]?).getD ([],[]) := by
  have he := RustfsCommonKeys.common_ok i out h
  have he' := congrArg (fun e : List Nat × List Nat => (BytesOfNats e.1,BytesOfNats e.2)) he
  simp only [bytes_nats] at he'
  rw [he']
  simp only [CommonByteEntries,List.getElem?_map]
  cases commonKeyEntries[i.val]? <;> rfl
set_option maxHeartbeats 2000000
 theorem first_ok (pattern : Slice U8)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (out : alloc.vec.Vec U8) (h : condfuncs.replace_first_common pattern values = ok out) :
    out.val = SubstituteFirstCommon pattern.val (RequestValueLists values.val) := by
  unfold condfuncs.replace_first_common condfuncs.replace_first_common_loop at h
  let F := SubstituteFirstCommonFrom (RequestValueLists values.val) pattern.val
  change out.val = F CommonByteEntries
  refine loop_ok _ (fun k : Usize => k.val ≤ CommonByteEntries.length ∧
      F (CommonByteEntries.drop k.val) = F CommonByteEntries)
    (fun out => out.val=F CommonByteEntries) (fun k => CommonByteEntries.length-k.val)
    ?_ _ out ⟨by simp,by simp⟩ h
  intro k result ⟨hk,he⟩ hr
  unfold condfuncs.replace_first_common_loop.body at hr
  h5i_invert hr
  · rcases x with ⟨keyBytes,varBytes⟩
    change (do
      let o ← condfuncs.get_value values keyBytes.deref
      match o with
      | none => do
        let k1 ← k + 1#usize
        ok (ControlFlow.cont k1)
      | some vs => do
        if vs.len > 0#usize then
          let v ← alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice (alloc.vec.Vec U8)) vs 0#usize
          if v.len > 0#usize then
            let v1 ← bytes.replace pattern varBytes.deref v.deref
            ok (ControlFlow.done v1)
          else
            let k1 ← k + 1#usize
            ok (ControlFlow.cont k1)
        else
          let k1 ← k + 1#usize
          ok (ControlFlow.cont k1)) = ok result at hr
    have hlt : k.val < CommonByteEntries.length := by change k.val<42; unfold keynames.COMMON_KEYS_LEN at hc; scalar_tac
    have ht := common_bytes_ok _ _ hx
    rw [List.getElem?_eq_getElem hlt] at ht
    simp only [Option.getD_some] at ht
    dsimp only [F] at he
    rw [List.drop_eq_getElem_cons hlt,← ht,SubstituteFirstCommonFrom] at he
    h5i_invert hr
    all_goals
      have hl := RustfsOperatorLookup.lookup_ok values _ _ ho
      simp only [RustfsForceDelete.deref_val] at hl
      simp only [Prod.fst,Prod.snd] at he
    · simp [CommonReplacement,← hl] at he
      have ha : k1.val = k.val+1 := by have := add_ok_val hk1; scalar_tac
      refine ⟨⟨by omega,?_⟩,by omega⟩
      simpa only [ha,F] using he
    · obtain ⟨hiv,hve⟩ := vec_index_ok hv
      simp only [UScalar.ofNatCore_val_eq] at hiv hve
      have hh : (vs.val.map (·.val)).head? = some v.val := by
        rw [List.head?_eq_getElem?,List.getElem?_map,List.getElem?_eq_getElem hiv,hve]
        rfl
      have hn : v.val.isEmpty=false := by
        have hn : v.val≠[] := by intro hh; simp [hh] at hc_2
        simpa using hn
      simp [CommonReplacement,← hl,hh,hn,Option.filter] at he
      change v1.val=F CommonByteEntries
      rw [RustfsReplace.replace_ok _ _ _ _ hv1]
      simpa only [RustfsForceDelete.deref_val,F] using he
    · obtain ⟨hiv,hve⟩ := vec_index_ok hv
      simp only [UScalar.ofNatCore_val_eq] at hiv hve
      have hh : (vs.val.map (·.val)).head? = some v.val := by
        rw [List.head?_eq_getElem?,List.getElem?_map,List.getElem?_eq_getElem hiv,hve]
        rfl
      have hn : v.val=[] := List.eq_nil_iff_length_eq_zero.mpr (by scalar_tac)
      simp [CommonReplacement,← hl,hh,hn,Option.filter] at he
      have ha : k1.val = k.val+1 := by have := add_ok_val hk1; scalar_tac
      refine ⟨⟨by omega,?_⟩,by omega⟩
      simpa only [ha,F] using he
    · have hn : vs.val=[] := List.eq_nil_iff_length_eq_zero.mpr (by scalar_tac)
      simp [CommonReplacement,← hl,hn] at he
      have ha : k1.val = k.val+1 := by have := add_ok_val hk1; scalar_tac
      refine ⟨⟨by omega,?_⟩,by omega⟩
      simpa only [ha,F] using he
  · have hn : CommonByteEntries.length ≤ k.val := by change 42≤k.val; unfold keynames.COMMON_KEYS_LEN at hc; scalar_tac
    rw [List.drop_of_length_le hn] at he
    change v1.val = F CommonByteEntries
    rw [RustfsCleanCanonical.to_vec_ok _ _ hv1]
    exact he
 theorem all_ok (pattern : Slice U8)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (out : alloc.vec.Vec U8) (h : rsrc.substitute_common pattern values = ok out) :
    out.val = SubstituteCommon pattern.val (RequestValueLists values.val) := by
  unfold rsrc.substitute_common at h
  obtain ⟨initial,hi,h⟩ := bind_tc_eq_ok.mp h
  have hi' := RustfsCleanCanonical.to_vec_ok _ _ hi
  unfold rsrc.substitute_common_loop at h
  let F := ApplyCommonEntry (RequestValueLists values.val)
  let target := SubstituteCommon pattern.val (RequestValueLists values.val)
  change out.val=target
  refine loop_ok _ (fun s : alloc.vec.Vec U8 × Usize => s.2.val ≤ CommonByteEntries.length ∧
      (CommonByteEntries.drop s.2.val).foldl F s.1.val = target)
    (fun out => out.val=target) (fun s => CommonByteEntries.length-s.2.val)
    ?_ _ out ⟨by simp,by simpa [target,F,SubstituteCommon] using congrArg (CommonByteEntries.foldl F) hi'⟩ h
  rintro ⟨acc,k⟩ result ⟨hk,he⟩ hr
  unfold rsrc.substitute_common_loop.body at hr
  h5i_invert hr
  all_goals simp only [Prod.fst,Prod.snd] at hk he ⊢
  · rcases x with ⟨keyBytes,varBytes⟩
    change (do
      let o ← condfuncs.get_value values keyBytes.deref
      let out1 ← match o with
        | none => ok acc
        | some vs => do
          if vs.len > 0#usize then
            let v ← alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice (alloc.vec.Vec U8)) vs 0#usize
            if v.len > 0#usize then bytes.replace acc.deref varBytes.deref v.deref
            else ok acc
          else ok acc
      let k1 ← k+1#usize
      ok (ControlFlow.cont (out1,k1))) = ok result at hr
    have hlt : k.val < CommonByteEntries.length := by
      change k.val<42
      unfold keynames.COMMON_KEYS_LEN at hc
      scalar_tac
    have ht := common_bytes_ok _ _ hx
    rw [List.getElem?_eq_getElem hlt] at ht
    simp only [Option.getD_some] at ht
    rw [List.drop_eq_getElem_cons hlt,← ht,List.foldl_cons] at he
    h5i_invert hr
    have hl := RustfsOperatorLookup.lookup_ok values _ _ ho
    simp only [RustfsForceDelete.deref_val] at hl
    have hstep : out1.val=F acc.val (keyBytes.val,varBytes.val) := by
      cases o with
      | none =>
        have hb := Result.ok.inj hout1
        subst out1
        simp [F,ApplyCommonEntry,CommonReplacement,← hl]
      | some vs =>
        h5i_invert hout1
        · obtain ⟨hiv,hve⟩ := vec_index_ok hv
          simp only [UScalar.ofNatCore_val_eq] at hiv hve
          have hh : (vs.val.map (·.val)).head? = some v.val := by
            rw [List.head?_eq_getElem?,List.getElem?_map,List.getElem?_eq_getElem hiv,hve]
            rfl
          have hn : v.val.isEmpty=false := by
            have hn : v.val≠[] := by intro hh; simp [hh] at hc_2
            simpa using hn
          rw [RustfsReplace.replace_ok _ _ _ _ hout1]
          simp [F,ApplyCommonEntry,CommonReplacement,← hl,hh,hn,Option.filter,RustfsForceDelete.deref_val]
        · obtain ⟨hiv,hve⟩ := vec_index_ok hv
          simp only [UScalar.ofNatCore_val_eq] at hiv hve
          have hh : (vs.val.map (·.val)).head? = some v.val := by
            rw [List.head?_eq_getElem?,List.getElem?_map,List.getElem?_eq_getElem hiv,hve]
            rfl
          have hn : v.val=[] := List.eq_nil_iff_length_eq_zero.mpr (by scalar_tac)
          simp [F,ApplyCommonEntry,CommonReplacement,← hl,hh,hn,Option.filter]
        · have hn : vs.val=[] := List.eq_nil_iff_length_eq_zero.mpr (by scalar_tac)
          simp [F,ApplyCommonEntry,CommonReplacement,← hl,hn]
    have ha : k1.val=k.val+1 := by have := add_ok_val hk1; scalar_tac
    change (k1.val ≤ CommonByteEntries.length ∧
      (CommonByteEntries.drop k1.val).foldl F out1.val=target) ∧
      CommonByteEntries.length-k1.val < CommonByteEntries.length-k.val
    refine ⟨⟨by omega,?_⟩,by omega⟩
    simpa only [ha,← hstep] using he
  · have hn : CommonByteEntries.length ≤ k.val := by
      change 42≤k.val
      unfold keynames.COMMON_KEYS_LEN at hc
      scalar_tac
    rw [List.drop_of_length_le hn,List.foldl_nil] at he
    exact he
end rustfs_kernel.Verified.RustfsCommonSubstitution
