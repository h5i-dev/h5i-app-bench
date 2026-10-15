import Verified.RustfsClaimLookup
import Verified.RustfsBytes
import Verified.RustfsCondData
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsBytes (push_ok)
namespace rustfs_kernel.Verified.RustfsClaimTokens


theorem push_nonempty (out out1 : alloc.vec.Vec (alloc.vec.Vec U8))
    (part : alloc.vec.Vec U8) (ho : NonemptyClaimTokens out.val)
    (h : (if part.len != 0#usize then alloc.vec.Vec.push out part else ok out) = ok out1) :
    NonemptyClaimTokens out1.val := by
  h5i_invert h
  · have hp := push_ok h
    intro p hm
    rw [hp] at hm
    simp only [List.mem_append,List.mem_singleton] at hm
    rcases hm with hm | rfl
    · exact ho p hm
    · intro hz
      have hzlen : p.val.length = 0 := by rw [hz]; rfl
      scalar_tac
  · exact ho

theorem split_nonempty (s : Slice U8) (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : claims.split_values s = ok out) : NonemptyClaimTokens out.val := by
  unfold claims.split_values claims.split_values_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec (alloc.vec.Vec U8) × Usize × Usize =>
      NonemptyClaimTokens x.1.val) (fun out => NonemptyClaimTokens out.val)
    (fun x => s.val.length + 1 - x.2.2.val) ?_ _ out (by simp [NonemptyClaimTokens]) h
  rintro ⟨out,start,i⟩ r ho hr
  unfold claims.split_values_loop.body at hr
  h5i_invert hr
  · rcases x with ⟨out1,start1⟩
    change (do
      let j ← i + 1#usize
      ok (ControlFlow.cont (out1,start1,j))) = ok r at hr
    h5i_invert hr
    have hadd := add_ok_val hj
    refine ⟨?_,by scalar_tac⟩
    h5i_invert hx
    all_goals
      rcases hx with ⟨rfl,rfl⟩
      dsimp only
    · exact push_nonempty out out2 part ho hout2
    · exact push_nonempty out out2 part ho hout2
    · exact ho
  · exact ho
end rustfs_kernel.Verified.RustfsClaimTokens
