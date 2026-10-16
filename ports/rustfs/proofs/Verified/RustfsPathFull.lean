import Verified.RustfsPathLoop
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsPathFull
set_option maxHeartbeats 2000000
open RustfsCleanCanonical RustfsPathMeaning RustfsPathLoop
lemma init_meaning (p : Slice U8) (b : alloc.vec.Vec U8) (first : U8) (out)
    (hp : p.index_usize 0#usize=ok first) (h : initState b first=ok out) :
    Meaning p out.1 out.2.1 out.2.2.1 out.2.2.2.1 out.2.2.2.2=NormalizedPath (nats p.val) := by
  have hh : (nats p.val).head?=some first.val := by
    simpa only [List.head?_eq_getElem?,UScalar.ofNatCore_val_eq] using index_nat hp
  unfold initState at h
  h5i_invert h
  · rcases x with ⟨x,f⟩
    obtain ⟨hb,rfl⟩ := mut_ok hx
    change (do
      let w ← 0#usize + 1#usize
      ok (true,b.set 0#usize 47#u8,w,1#usize,1#usize))=ok out at h
    h5i_invert h
    have hv := add_ok_val hw
    have he : w=1#usize := by scalar_tac
    subst w
    have hf : first=47#u8 := by assumption
    have hwrite := pref_write b 0#usize 1#usize 47#u8 hb (by scalar_tac)
    simp only [pref,UScalar.ofNatCore_val_eq,List.take_zero,nats,List.map_nil,List.nil_append] at hwrite
    dsimp only [Meaning]
    have hpref : pref (b.set 0#usize 47#u8) 1#usize=[47] := by
      simpa only [pref,nats,UScalar.ofNatCore_val_eq] using hwrite
    rw [hpref]
    simp only [NormalizedPath,hh,hf,UScalar.ofNatCore_val_eq,decide_true,↓reduceIte]
  · have hf : first.val≠47 := by scalar_tac
    dsimp only [Meaning]
    simp only [NormalizedPath,hh,Option.some.injEq,hf,decide_false,Bool.false_eq_true,↓reduceIte]
    simp only [pref,UScalar.ofNatCore_val_eq,List.take_zero,nats,List.map_nil,List.drop_zero]
theorem clean_meaning (p : Slice U8) (c : alloc.vec.Vec U8) (h : pathclean.clean p=ok c) :
    nats c.val=CleanPath (nats p.val) := by
  unfold pathclean.clean at h
  simp only [←initState.eq_def,lift] at h
  h5i_invert h
  · have hp : p.val=[] := List.eq_nil_iff_length_eq_zero.mpr (by scalar_tac)
    rw [to_vec_ok _ c h]
    simp only [Array.to_slice,Slice.from_val,Array.make_val,nats,List.map_cons,List.map_nil,
      UScalar.ofNatCore_val_eq,hp,CleanPath,NormalizedPath,List.head?_nil,
      reduceCtorEq,decide_false,↓reduceIte,NormalizeTail]
  · rcases x with ⟨root,b1,w,r,d⟩
    have hinv := initState_ok buf i1 (root,b1,w,r,d) hx
    have hm := init_meaning p buf i1 (root,b1,w,r,d) (by assumption) hx
    dsimp only at hinv hm
    obtain ⟨⟨b2,w2⟩,hloop,h⟩ := bind_tc_eq_ok.mp h
    have hl := main_meaning p p.len root b1 w r d (b2,w2) (by simp) hinv hloop
    dsimp only at hl
    rw [hm] at hl
    change (if w2=0#usize then _ else pathclean.clean_loop1 b2 w2 (alloc.vec.Vec.new U8) 0#usize)=ok c at h
    h5i_invert h
    · have hz : NormalizedPath (nats p.val)=[] := by
        rw [←hl,hc_1]
        simp only [pref,UScalar.ofNatCore_val_eq,List.take_zero,nats,List.map_nil]
      simp only [CleanPath,hz,↓reduceIte]
      rw [to_vec_ok _ c h]
      simp only [Array.to_slice,Slice.from_val,Array.make_val,nats,List.map_cons,List.map_nil,
        UScalar.ofNatCore_val_eq]
    · obtain ⟨_,hb,_⟩ := main_loop_ok p p.len root b1 w r d (b2,w2) (by simp) hinv hloop
      dsimp only at hb
      have hn : NormalizedPath (nats p.val)≠[] := by
        intro he
        have he := congrArg List.length (hl.trans he)
        rw [pref_length b2 w2 hb] at he
        scalar_tac
      rw [output_ok b2 w2 c h]
      change pref b2 w2=CleanPath (nats p.val)
      simp only [CleanPath,hn,↓reduceIte]
      exact hl
end rustfs_kernel.Verified.RustfsPathFull
