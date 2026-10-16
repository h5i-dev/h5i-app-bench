import SpecKeyTables
import Verified.RustfsBytes
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsAsciiLower
open rustfs_kernel.Verified.RustfsBytes (push_ok)
theorem lower_ok (s : Slice U8) (out : alloc.vec.Vec U8)
    (h : bytes.lower s = ok out) : nats out.val = (nats s.val).map asciiLower := by
  unfold bytes.lower bytes.lower_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec U8 × Usize =>
      x.2.val ≤ s.val.length ∧ nats x.1.val = (nats (s.val.take x.2.val)).map asciiLower)
    (fun out => nats out.val = (nats s.val).map asciiLower)
    (fun x => s.val.length - x.2.val) ?_ _ out
    ⟨by simp,by simp [alloc.vec.Vec.new,alloc.vec.Vec.from_val,nats]⟩ h
  rintro ⟨out,i⟩ r ⟨hi,ho⟩ hr
  unfold bytes.lower_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok hc_1
    have hadd := add_ok_val hi2
    have hij : i2.val = i.val+1 := by scalar_tac
    have hout : nats out1.val = nats out.val ++ [asciiLower c.val] := by
      h5i_invert hout1
      · have hcc := add_ok_val hi2_1
        have hl : 65 ≤ c.val := by scalar_tac
        have hu : c.val ≤ 90 := by scalar_tac
        rw [push_ok hout1]
        simp [nats,asciiLower,hl,hu]
        scalar_tac
      · have hu : ¬ c.val ≤ 90 := by scalar_tac
        rw [push_ok hout1]
        simp [nats,asciiLower,hu]
      · have hl : ¬ 65 ≤ c.val := by scalar_tac
        rw [push_ok hout1]
        simp [nats,asciiLower,hl]
    refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
    change nats out1.val = _
    rw [hout,ho,hij,List.take_add_one,List.getElem?_eq_getElem hlt,he]
    simp [nats]
  · have hle : s.val.length ≤ i.val := by scalar_tac
    simpa only [List.take_of_length_le hle] using ho
end rustfs_kernel.Verified.RustfsAsciiLower
