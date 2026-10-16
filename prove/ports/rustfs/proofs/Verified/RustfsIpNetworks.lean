import Verified.RustfsScalarOperators
import Verified.RustfsCondData
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsValids (any_loop)
namespace rustfs_kernel.Verified.RustfsIpNetworks
/-- An address belongs to the union of the supplied CIDR networks. -/
theorem any_net_ok (networks : Slice (condfuncs.IpAddr × U8)) (address : condfuncs.IpAddr)
    (b : Bool) (h : condfuncs.any_net networks address = ok b) :
    b = true ↔ AnyNetwork networks.val address := by
  unfold condfuncs.any_net condfuncs.any_net_loop at h
  unfold AnyNetwork
  refine any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold condfuncs.any_net_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok hx
    rcases x with ⟨net,pref⟩
    change (do
      let matched ← condfuncs.net_contains net pref address
      if matched = true then ok (ControlFlow.done true)
      else do
        let next ← i + 1#usize
        ok (ControlFlow.cont next)) = ok r at hr
    h5i_invert hr
    · exact .inl ⟨hlt, by simpa [he] using (RustfsScalarOperators.prefix_ok _ _ _ _ hmatched).1 hc_1, rfl⟩
    · exact ⟨hlt, by simpa [he] using (fun hp => hc_1 ((RustfsScalarOperators.prefix_ok _ _ _ _ hmatched).2 hp)), by have := add_ok_val hnext; scalar_tac⟩
  · exact .inr ⟨by scalar_tac,rfl⟩
end rustfs_kernel.Verified.RustfsIpNetworks
