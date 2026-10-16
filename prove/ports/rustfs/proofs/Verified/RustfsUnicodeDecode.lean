import Verified.RustfsBytes
import Verified.RustfsValids
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsUnicodeDecode
set_option maxRecDepth 8192
set_option maxHeartbeats 2000000

theorem scalar_advances (s : Slice U8) (i : Usize) (out : U32 × Usize)
    (h : unicode.scalar_at s i = ok out) :
    i.val < out.2.val ∧ out.2.val ≤ s.val.length ∧ out.2.val ≤ i.val + 4 := by
  unfold unicode.scalar_at at h
  h5i_invert h
  · have hb := (slice_index_ok hi1).1
    have ha := add_ok_val hi2
    scalar_tac
  · have hb := (slice_index_ok hi5).1
    have ha := add_ok_val hi4
    have hn := add_ok_val hi9
    scalar_tac
  · have hb := (slice_index_ok hi11).1
    have ha := add_ok_val hi10
    have hn := add_ok_val hi15
    scalar_tac
  · have hb := (slice_index_ok hi17).1
    have ha := add_ok_val hi16
    have hn := add_ok_val hi21
    scalar_tac
end rustfs_kernel.Verified.RustfsUnicodeDecode
