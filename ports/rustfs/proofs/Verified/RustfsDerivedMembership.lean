import Verified.RustfsDerivedKeys
import Verified.RustfsAsciiLower
import Verified.RustfsKeyTables
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsForceDelete (deref_val)
namespace rustfs_kernel.Verified.RustfsDerivedMembership

theorem membership_loop (names : alloc.vec.Vec (alloc.vec.Vec U8)) (lower : alloc.vec.Vec U8)
    (b : Bool) (h : keytables.is_server_derived_condition_key_loop names lower 0#usize = ok b) :
    (b = true ↔ ∃ v ∈ names.val, (nats v.val).map asciiLower = nats lower.val) := by
  unfold keytables.is_server_derived_condition_key_loop at h
  refine rustfs_kernel.Verified.RustfsValids.any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold keytables.is_server_derived_condition_key_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := vec_index_ok hv
    have hl := rustfs_kernel.Verified.RustfsAsciiLower.lower_ok _ _ hv1
    rw [deref_val] at hl
    have hb := rustfs_kernel.Verified.RustfsForceDelete.bytes_eq_ok _ _ _ hb_1
    simp only [deref_val] at hb
    refine .inl ⟨hlt,?_,rfl⟩
    rw [he]
    change (nats v.val).map asciiLower = nats lower.val
    rw [← hl,hb.1 hc_1]
  · obtain ⟨hlt,he⟩ := vec_index_ok hv
    have hl := rustfs_kernel.Verified.RustfsAsciiLower.lower_ok _ _ hv1
    rw [deref_val] at hl
    have hb := rustfs_kernel.Verified.RustfsForceDelete.bytes_eq_ok _ _ _ hb_1
    simp only [deref_val] at hb
    refine ⟨hlt,?_,by have := add_ok_val hi2; scalar_tac⟩
    intro hh
    apply hc_1
    apply hb.2
    apply rustfs_kernel.Verified.RustfsForceDelete.nats_inj
    simpa only [he,hl] using hh
  · exact .inr ⟨by scalar_tac,rfl⟩

theorem condition_key_ok (needle : Slice U8) (b : Bool)
    (h : keytables.is_server_derived_condition_key needle = ok b) :
    (b = true ↔ ∃ n ∈ serverDerivedNames, n.map asciiLower = (nats needle.val).map asciiLower) := by
  unfold keytables.is_server_derived_condition_key at h
  obtain ⟨names,hnames,h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨lower,hlower,h⟩ := bind_tc_eq_ok.1 h
  have hn := rustfs_kernel.Verified.RustfsDerivedKeys.derived_names_ok names hnames
  have hl := rustfs_kernel.Verified.RustfsAsciiLower.lower_ok _ _ hlower
  rw [membership_loop _ _ _ h,hl]
  constructor
  · rintro ⟨v,hv,he⟩
    refine ⟨nats v.val,?_,he⟩
    rw [← hn]
    exact List.mem_map.2 ⟨v,hv,rfl⟩
  · rintro ⟨n,hm,he⟩
    rw [← hn] at hm
    obtain ⟨v,hv,rfl⟩ := List.mem_map.1 hm
    exact ⟨v,hv,he⟩
end rustfs_kernel.Verified.RustfsDerivedMembership
