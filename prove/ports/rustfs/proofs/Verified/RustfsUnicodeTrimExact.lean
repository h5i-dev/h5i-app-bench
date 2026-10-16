import Verified.RustfsUnicodeCodec
import Verified.RustfsUnicodeWhitespace
import Verified.RustfsForceDelete
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsUnicodeTrimExact
set_option maxHeartbeats 2000000

theorem loop_bounds (s : Slice U8) (out : Usize × Usize)
    (h : unicode.trim_loop s s.len 0#usize 0#usize = ok out) :
    (out.1.val,out.2.val) = SpanBounds s.val.length (s.val.length,0)
      (ScalarSpans (nats s.val) 0) := by
  unfold unicode.trim_loop at h
  refine loop_ok _ (fun state : Usize × Usize × Usize =>
      state.2.2.val ≤ s.val.length ∧
      SpanBounds s.val.length (state.1.val,state.2.1.val)
        (ScalarSpans (nats s.val) state.2.2.val) =
      SpanBounds s.val.length (s.val.length,0) (ScalarSpans (nats s.val) 0))
    (fun out => (out.1.val,out.2.val) = SpanBounds s.val.length (s.val.length,0)
      (ScalarSpans (nats s.val) 0))
    (fun state => s.val.length-state.2.2.val) ?_ _ out ?_ h
  · rintro ⟨first,last,i⟩ result ⟨hi,he⟩ hr
    unfold unicode.trim_loop.body at hr
    h5i_invert hr
    all_goals
      try
        have hn : ¬i.val < (nats s.val).length := by simpa [nats] using (show ¬i.val<s.val.length by scalar_tac)
        rw [ScalarSpans, dif_neg hn] at he
        simpa only [SpanBounds,List.filter_nil,List.foldl_nil] using he
    all_goals
      rcases x with ⟨cp,next⟩
      first
      | change (do
          let b ← unicode.whitespace cp
          if b then ok (ControlFlow.cont (first,last,next))
          else ok (ControlFlow.cont (i,next,next))) = ok result at hr
      | change (do
          let b ← unicode.whitespace cp
          if b then ok (ControlFlow.cont (first,last,next))
          else ok (ControlFlow.cont (first,next,next))) = ok result at hr
      have hd := RustfsUnicodeCodec.decode_ok s i (cp,next) hx
      have ha := RustfsUnicodeDecode.scalar_advances s i (cp,next) hx
      have hlt : i.val < (nats s.val).length := by simpa [nats] using (lt_of_lt_of_le ha.1 ha.2.1)
      rw [ScalarSpans,dif_pos hlt, ← hd,spanBounds_cons] at he
      h5i_invert hr
      all_goals
        have hw := RustfsUnicodeWhitespace.whitespace_ok cp _ hb
        simp only [Prod.fst,Prod.snd] at *
        constructor
        · constructor
          · exact ha.2.1
          · first
            | have hf : first.val = s.val.length := by scalar_tac
              simpa only [← hw,hc_2,Bool.false_eq_true,↓reduceIte,ExtendBounds,Prod.fst,Prod.snd,hf] using he
            | have hf : first.val ≠ s.val.length := by scalar_tac
              simpa only [← hw,hc_2,Bool.false_eq_true,↓reduceIte,ExtendBounds,Prod.fst,Prod.snd,hf] using he
        · omega
  · simp

/-- Trimming removes precisely the leading and trailing whitespace scalars.
All bytes between the first and last retained scalar are unchanged. -/
theorem trim_ok (s : Slice U8) (out : alloc.vec.Vec U8)
    (h : unicode.trim s = ok out) : nats out.val = TrimBytes (nats s.val) := by
  unfold unicode.trim at h
  h5i_invert h
  rcases x with ⟨first,last⟩
  have hb := loop_bounds s (first,last) hx
  change (if first = s.len then ok (alloc.vec.Vec.new U8)
    else bytes.slice s first last) = ok out at h
  let retained := (ScalarSpans (nats s.val) 0).filter
    (fun span => span.2.1 ∉ UnicodeWhitespace)
  have ht : ∀ span ∈ retained, span.1 < s.val.length := by
    intro span hs
    have hh := (List.mem_filter.mp hs).1
    simpa [nats] using spans_start_lt (nats s.val) 0 span hh
  change (first.val,last.val) = retained.foldl (ExtendBounds s.val.length) (s.val.length,0) at hb
  rw [bounds_fold _ _ _ _ ht] at hb
  change nats out.val = match retained.head?,retained.getLast? with
    | some a,some b => ((nats s.val).take b.2.2).drop a.1
    | _,_ => []
  cases hr : retained with
  | nil =>
    simp only [hr,List.head?_nil,List.getLast?_nil] at hb ⊢
    have hf : first = s.len := by apply UScalar.eq_of_val_eq; exact congrArg Prod.fst hb
    simp only [hf,ite_true,Result.ok.injEq] at h
    subst out
    simp [alloc.vec.Vec.new,nats]
  | cons a rest =>
    simp only [hr,List.head?_cons,List.getLast?_cons] at hb ⊢
    have ha : a.1 < s.val.length := ht a (by simp [hr])
    have hf : first.val = a.1 := congrArg Prod.fst hb
    have hl : last.val = (rest.getLast?.getD a).2.2 := congrArg Prod.snd hb
    have hf' : first ≠ s.len := by scalar_tac
    rw [if_neg hf'] at h
    have hs := RustfsBytes.slice_ok s first last out h
    rw [hs]
    simpa only [nats,List.map_drop,List.map_take,hf,hl]

end rustfs_kernel.Verified.RustfsUnicodeTrimExact
