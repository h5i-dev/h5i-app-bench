import SpecKeyTables
import Verified.RustfsActionTables
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsForceDelete (lift_slice)
namespace rustfs_kernel.Verified.RustfsCommonKeys
set_option maxRecDepth 4096
set_option maxHeartbeats 1000000

theorem common_ok (i : Usize) (out : alloc.vec.Vec U8 × alloc.vec.Vec U8)
    (h : keynames.common_key i = ok out) :
    (nats out.1.val,nats out.2.val) = (commonKeyEntries[i.val]?).getD ([],[]) := by
  unfold keynames.common_key at h
  h5i_invert h
  all_goals try
    change (nats v.val,nats v1.val) = (commonKeyEntries[i.val]?).getD ([],[])
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ hv,
      rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ hv1,
      lift_slice hs,lift_slice hs1,hc]
    decide +kernel
  all_goals
    simp only [imp_false] at *
    have hi : commonKeyEntries.length ≤ i.val := by change 42 ≤ i.val; omega
    rw [List.getElem?_eq_none hi]
    rfl

end rustfs_kernel.Verified.RustfsCommonKeys
