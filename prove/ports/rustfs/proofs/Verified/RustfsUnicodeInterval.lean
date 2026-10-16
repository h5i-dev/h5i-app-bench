import Verified.RustfsUnicodeStructure
import Verified.RustfsUnicodeChunks
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
namespace rustfs_kernel.Verified.RustfsUnicodeInterval
set_option maxHeartbeats 2000000

theorem value_monotone (r : LowerRange) {a b : Nat} (h : a ≤ b) :
    LowerRangeValue a r ≤ LowerRangeValue b r := by
  unfold LowerRangeValue
  split <;> omega

theorem range_destination_valid (r : LowerRange) (cp : Nat)
    (hr : r ∈ LowerRangeEntries) (h : LowerRangeApplies cp r) :
    LowerRangeValue cp r < 0x110000 ∧
      (LowerRangeValue cp r < 0xD800 ∨ 0xDFFF < LowerRangeValue cp r) := by
  have hs := RustfsUnicodeStructure.range_entries_well_formed r hr
  have hlo := value_monotone r h.1
  have hhi := value_monotone r h.2.1
  omega

theorem lookup_witness (cp : Nat) (rs : List LowerRange) (a b n : Nat)
    (h : LookupLowerRanges cp rs = some (a,b,n)) :
    ∃ r ∈ rs, LowerRangeApplies cp r ∧ a = LowerRangeValue cp r ∧ b = 0 ∧ n = 1 := by
  induction rs with
  | nil => simp [LookupLowerRanges] at h
  | cons r rs ih =>
    simp only [LookupLowerRanges] at h
    split at h
    · cases h
      exact ⟨r, by simp, by assumption, rfl, rfl, rfl⟩
    · obtain ⟨r',hr',hc,ha,hb,hn⟩ := ih h
      exact ⟨r', by simp [hr'],hc,ha,hb,hn⟩
theorem chunk_row (i : Nat) (r : LowerRange)
    (hr : r ∈ ((RustfsUnicodeChunks.Chunks[i]?).getD [])) : r ∈ LowerRangeEntries := by
  cases he : RustfsUnicodeChunks.Chunks[i]? with
  | none => simp [he] at hr
  | some rs =>
    have hm : rs ∈ RustfsUnicodeChunks.Chunks := List.mem_of_getElem? he
    have hf : r ∈ RustfsUnicodeChunks.Chunks.flatten :=
      List.mem_flatten.mpr ⟨rs, hm, by simpa [he] using hr⟩
    simpa [RustfsUnicodeChunks.Chunks, LowerRangeEntries] using hf

theorem chunk_result_valid (cp : U32) (i : Usize) (out : U32 × U32 × Usize)
    (h : unicode.range_chunk cp i = ok (some out)) :
    out.2.1.val = 0 ∧ out.2.2.val = 1 ∧ out.1.val < 0x110000 ∧
      (out.1.val < 0xD800 ∨ 0xDFFF < out.1.val) := by
  have ht := RustfsUnicodeChunks.chunk_ok cp i (some out) h
  simp only [Option.map_some] at ht
  obtain ⟨r,hr,ha,hv,hb,hn⟩ := lookup_witness _ _ _ _ _ ht.symm
  have hs := range_destination_valid r cp.val (chunk_row i.val r hr) ha
  exact ⟨hb,hn,by simpa [hv] using hs.1,by simpa [hv] using hs.2⟩
end rustfs_kernel.Verified.RustfsUnicodeInterval
