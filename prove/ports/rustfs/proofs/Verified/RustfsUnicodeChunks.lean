import Verified.RustfsUnicodeTables
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsUnicodeChunks
set_option maxRecDepth 8192
set_option maxHeartbeats 2000000

def Chunks : List (List LowerRange) :=
  [LowerRanges0,LowerRanges1,LowerRanges2,LowerRanges3,LowerRanges4,
   LowerRanges5,LowerRanges6,LowerRanges7,LowerRanges8]

theorem chunk_ok (cp : U32) (i : Usize) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_chunk cp i = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) =
      LookupLowerRanges cp.val ((Chunks[i.val]?).getD []) := by
  unfold unicode.range_chunk at h
  split at h
  all_goals try first
    | (have he := RustfsUnicodeTables.range0_ok cp out h; simpa [Chunks, (show i.val = 0 by assumption)] using he)
    | (have he := RustfsUnicodeTables.range1_ok cp out h; simpa [Chunks, (show i.val = 1 by assumption)] using he)
    | (have he := RustfsUnicodeTables.range2_ok cp out h; simpa [Chunks, (show i.val = 2 by assumption)] using he)
    | (have he := RustfsUnicodeTables.range3_ok cp out h; simpa [Chunks, (show i.val = 3 by assumption)] using he)
    | (have he := RustfsUnicodeTables.range4_ok cp out h; simpa [Chunks, (show i.val = 4 by assumption)] using he)
    | (have he := RustfsUnicodeTables.range5_ok cp out h; simpa [Chunks, (show i.val = 5 by assumption)] using he)
    | (have he := RustfsUnicodeTables.range6_ok cp out h; simpa [Chunks, (show i.val = 6 by assumption)] using he)
    | (have he := RustfsUnicodeTables.range7_ok cp out h; simpa [Chunks, (show i.val = 7 by assumption)] using he)
    | (have he := RustfsUnicodeTables.range8_ok cp out h; simpa [Chunks, (show i.val = 8 by assumption)] using he)
  all_goals
    rename_i x h0 h1 h2 h3 h4 h5 h6 h7 h8
    have hi : 9 ≤ i.val := by scalar_tac
    have hout : out = none := by simpa using h.symm
    rw [hout]
    have he : Chunks[i.val]? = none := List.getElem?_eq_none (by simpa [Chunks] using hi)
    rw [he]
    rfl
end rustfs_kernel.Verified.RustfsUnicodeChunks
