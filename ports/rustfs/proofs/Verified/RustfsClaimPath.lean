import Verified.RustfsClaimTokens
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsBytes
namespace rustfs_kernel.Verified.RustfsClaimPath

theorem path_preserved (path : Slice U8) (second : Bool) (left right : alloc.vec.Vec U8)
    (h : claims.split_path path second = ok (left,right)) :
    left.val ++ right.val = path.val := by
  unfold claims.split_path at h
  h5i_invert h
  all_goals rcases h with ⟨rfl,rfl⟩
  · rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ hv]
    simp [alloc.vec.Vec.new,alloc.vec.Vec.from_val]
  · rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ hv]
    simp [alloc.vec.Vec.new,alloc.vec.Vec.from_val]
  all_goals
    rw [slice_ok _ _ _ _ hv,slice_ok _ _ _ _ hv1]
    have hz : (0#usize).val = 0 := by decide +kernel
    simp only [hz,List.drop_zero,Slice.len_val,List.take_length,List.take_append_drop]
end rustfs_kernel.Verified.RustfsClaimPath
