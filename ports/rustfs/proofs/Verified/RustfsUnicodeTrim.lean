import Verified.RustfsBytes
import Verified.RustfsValids
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsUnicodeTrim
set_option maxRecDepth 8192
set_option maxHeartbeats 2000000
/-- Trimming retains a contiguous segment of the original bytes. -/
theorem trim_segment (s : Slice U8) (out : alloc.vec.Vec U8)
    (h : unicode.trim s = ok out) :
    ∃ a b : Nat, out.val = (s.val.take b).drop a := by
  unfold unicode.trim at h
  h5i_invert h
  rcases x with ⟨first,last⟩
  change (if first = s.len then ok (alloc.vec.Vec.new U8) else bytes.slice s first last) = ok out at h
  h5i_invert h
  · exact ⟨0,0,by simp [alloc.vec.Vec.new]⟩
  · exact ⟨_,_,RustfsBytes.slice_ok _ _ _ _ h⟩
end rustfs_kernel.Verified.RustfsUnicodeTrim
