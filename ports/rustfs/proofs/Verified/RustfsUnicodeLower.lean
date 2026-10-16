import Verified.RustfsUnicodeChunks
import Verified.RustfsUnicodeSingleton
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsUnicodeLower
set_option maxHeartbeats 2000000

theorem lookup_append (cp : Nat) (xs ys : List LowerRange) :
    LookupLowerRanges cp (xs ++ ys) =
      (LookupLowerRanges cp xs).orElse (fun _ => LookupLowerRanges cp ys) := by
  induction xs with
  | nil => rfl
  | cons r rs ih =>
    simp only [List.cons_append, LookupLowerRanges]
    split <;> simp_all

theorem chunks_flatten : RustfsUnicodeChunks.Chunks.flatten = LowerRangeEntries := by
  simp [RustfsUnicodeChunks.Chunks, LowerRangeEntries, List.append_assoc]

/-- Lowercase dispatch chooses the first applicable range in table order,
then the singleton exception table, with identity for an unlisted scalar. -/
theorem scalar_ok (cp : U32) (out : U32 × U32 × Usize)
    (h : unicode.lowercase_scalar cp = ok out) :
    (out.1.val,out.2.1.val,out.2.2.val) = LowercaseScalar cp.val := by
  unfold unicode.lowercase_scalar unicode.lowercase_scalar_loop at h
  refine loop_ok _ (fun i : Usize => i.val ≤ 9 ∧
      LookupLowerRanges cp.val LowerRangeEntries =
        LookupLowerRanges cp.val (RustfsUnicodeChunks.Chunks.drop i.val).flatten)
    (fun out : U32 × U32 × Usize =>
      (out.1.val,out.2.1.val,out.2.2.val) = LowercaseScalar cp.val)
    (fun i => 9 - i.val) ?_ _ out ⟨by simp, by simp [chunks_flatten]⟩ h
  intro i r ⟨hi, he⟩ hr
  unfold unicode.lowercase_scalar_loop.body at hr
  h5i_invert hr
  · have ht := RustfsUnicodeChunks.chunk_ok cp i none ho
    simp only [Option.map_none] at ht
    have hadd := add_ok_val hi1
    have hlt : i.val < RustfsUnicodeChunks.Chunks.length := by
      simpa [RustfsUnicodeChunks.Chunks] using (show i.val < 9 by scalar_tac)
    refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
    rw [he, List.drop_eq_getElem_cons hlt, List.flatten_cons, lookup_append]
    rw [List.getElem?_eq_getElem hlt] at ht
    simp only [Option.getD_some] at ht
    rw [← ht]
    simp only [Option.orElse_none]
    congr 3
    scalar_tac
  · rcases v with ⟨a,b,c⟩
    change ok (ControlFlow.done (a,b,c)) = ok r at hr
    cases Result.ok.inj hr
    have ht := RustfsUnicodeChunks.chunk_ok cp i (some (a,b,c)) ho
    simp only [Option.map_some] at ht
    have hlt : i.val < RustfsUnicodeChunks.Chunks.length := by
      simpa [RustfsUnicodeChunks.Chunks] using (show i.val < 9 by scalar_tac)
    unfold LowercaseScalar
    rw [he, List.drop_eq_getElem_cons hlt, List.flatten_cons, lookup_append]
    rw [List.getElem?_eq_getElem hlt] at ht
    simp only [Option.getD_some] at ht
    rw [← ht]
    rfl
  · rcases v with ⟨a,b,c⟩
    change ok (ControlFlow.done (a,b,c)) = ok r at hr
    cases Result.ok.inj hr
    have ht := RustfsUnicodeSingleton.singleton_ok cp (a,b,c) hv
    unfold LowercaseScalar
    rw [he, List.drop_of_length_le (by simpa [RustfsUnicodeChunks.Chunks] using (show 9 ≤ i.val by scalar_tac))]
    exact ht
end rustfs_kernel.Verified.RustfsUnicodeLower
