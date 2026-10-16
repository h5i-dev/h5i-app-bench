import Verified.RustfsUnicodeCodec
import Verified.RustfsUnicodeLower
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsUnicodeLowerBytes
set_option maxHeartbeats 2000000
/-- Whole-string lowercasing concatenates the table image of every decoded scalar. -/
theorem lower_ok (s : Slice U8) (out : alloc.vec.Vec U8)
    (h : unicode.lower s = ok out) : nats out.val = LowerBytes (nats s.val) := by
  unfold unicode.lower unicode.lower_loop at h
  refine loop_ok _ (fun state : alloc.vec.Vec U8 × Usize =>
      state.2.val ≤ s.val.length ∧
      nats state.1.val ++ LowerSuffix (nats s.val) state.2.val = LowerBytes (nats s.val))
    (fun out => nats out.val = LowerBytes (nats s.val))
    (fun state => s.val.length - state.2.val) ?_ _ out ?_ h
  · rintro ⟨initial,i⟩ result ⟨hi,he⟩ hr
    unfold unicode.lower_loop.body at hr
    h5i_invert hr
    · rcases x with ⟨cp,next⟩
      change (do
        let (a,b,count) ← unicode.lowercase_scalar cp
        let encoded ← unicode.append_scalar initial a
        if count = 2#usize then do
          let encoded2 ← unicode.append_scalar encoded b
          ok (ControlFlow.cont (encoded2,next))
        else ok (ControlFlow.cont (encoded,next))) = ok result at hr
      h5i_invert hr
      rcases x with ⟨a,b,count⟩
      change (do
        let encoded ← unicode.append_scalar initial a
        if count = 2#usize then do
          let encoded2 ← unicode.append_scalar encoded b
          ok (ControlFlow.cont (encoded2,next))
        else ok (ControlFlow.cont (encoded,next))) = ok result at hr
      have hd := RustfsUnicodeCodec.decode_ok s i (cp,next) hx
      have ha := RustfsUnicodeDecode.scalar_advances s i (cp,next) hx
      have hl := RustfsUnicodeLower.scalar_ok cp (a,b,count) hx_1
      have hlt : i.val < (nats s.val).length := by simpa [nats] using (lt_of_lt_of_le ha.1 ha.2.1)
      have heq : LowerSuffix (nats s.val) i.val =
          (EncodeScalar a.val ++ if count.val = 2 then EncodeScalar b.val else []) ++
          LowerSuffix (nats s.val) next.val := by
        rw [LowerSuffix, dif_pos hlt, ← hd]
        simp only [LowerScalarBytes, ← hl]
      h5i_invert hr
      all_goals
        have happ := RustfsUnicodeCodec.append_ok initial _ a hencoded
        try have happ2 := RustfsUnicodeCodec.append_ok _ _ b hencoded2
        simp only [Prod.fst,Prod.snd] at *
        constructor
        · constructor
          · exact ha.2.1
          · rw [heq] at he
            simp only [happ] at *
            try rw [happ2]
            have hcount : (count.val = 2 ↔ count = 2#usize) := by scalar_tac
            simpa only [show (2#usize).val = 2 by decide, hcount, hc_1, ↓reduceIte, List.append_assoc,
              List.append_nil] using he
        · omega
    · have hn : ¬ i.val < (nats s.val).length := by simpa [nats] using (show ¬ i.val < s.val.length by scalar_tac)
      simpa [LowerSuffix,hn] using he
  · simp [alloc.vec.Vec.new,nats,LowerBytes]
end rustfs_kernel.Verified.RustfsUnicodeLowerBytes
