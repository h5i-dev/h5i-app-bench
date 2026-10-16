import SpecKeyTables
import Verified.RustfsAsciiLower
import Verified.RustfsCommonKeys
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsForceDelete (lift_slice)
namespace rustfs_kernel.Verified.RustfsDerivedKeys
open rustfs_kernel.Verified.RustfsCommonKeys
theorem derived_names_ok (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : keytables.server_derived_key_names = ok out) :
    out.val.map (fun v => nats v.val) = serverDerivedNames := by
  unfold keytables.server_derived_key_names keytables.server_derived_key_names_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec (alloc.vec.Vec U8) × Usize =>
      x.2.val ≤ commonKeyEntries.length ∧ x.1.val.map (fun v => nats v.val) =
      ((commonKeyEntries.take x.2.val).map Prod.fst).filter (fun n => ! decide (lit "x-amz-" <+: n)))
    (fun out => out.val.map (fun v => nats v.val) = serverDerivedNames)
    (fun x => commonKeyEntries.length - x.2.val) ?_ _ out
    ⟨by simp,by simp [alloc.vec.Vec.new,alloc.vec.Vec.from_val]⟩ h
  rintro ⟨out,i⟩ r ⟨hi,ho⟩ hr
  unfold keytables.server_derived_key_names_loop.body at hr
  h5i_invert hr
  · rcases x with ⟨nm,varname⟩
    change (do
      let s1 ← lift (Array.to_slice (Array.make 6#usize [120#u8,45#u8,97#u8,109#u8,122#u8,45#u8]))
      let bb ← bytes.starts_with nm.deref s1
      let out1 ← if bb then ok out else out.push nm
      let i1 ← i + 1#usize
      ok (ControlFlow.cont (out1,i1))) = ok r at hr
    h5i_invert hr
    have hlt : i.val < commonKeyEntries.length := by
      change i.val < 42
      simpa [keynames.COMMON_KEYS_LEN] using hc
    have ht := common_ok i (nm,varname) hx
    rw [List.getElem?_eq_getElem hlt] at ht
    have hnm : nats nm.val = (commonKeyEntries[i.val]).1 := congrArg Prod.fst ht
    have hadd := add_ok_val hi1
    have hij : i1.val = i.val+1 := by scalar_tac
    have htake : (commonKeyEntries.take i1.val).map Prod.fst =
        (commonKeyEntries.take i.val).map Prod.fst ++ [nats nm.val] := by
      rw [hij,List.take_add_one,List.getElem?_eq_getElem hlt]
      simp only [List.map_append,Option.toList_some,List.map_cons,List.map_nil,hnm]
    have hp : nats s1.val = lit "x-amz-" := by rw [lift_slice hs1]; decide +kernel
    have hb := rustfs_kernel.Verified.RustfsValids.starts_lit hp hbb
    rw [rustfs_kernel.Verified.RustfsForceDelete.deref_val] at hb
    h5i_invert hout1
    · have hh := hb.1 hc_1
      refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
      change out1.val.map (fun v => nats v.val) = _
      rw [htake,List.filter_append]
      simpa [hh] using ho
    · have hh : ¬ lit "x-amz-" <+: nats nm.val := fun h => hc_1 (hb.2 h)
      have hout := rustfs_kernel.Verified.RustfsBytes.push_ok hout1
      refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
      change out1.val.map (fun v => nats v.val) = _
      rw [hout,List.map_append,htake,List.filter_append,ho]
      simp [hh]
  · have hle : commonKeyEntries.length ≤ i.val := by
      change 42 ≤ i.val
      have hc' : ¬ i.val < 42 := by simpa [keynames.COMMON_KEYS_LEN] using hc
      omega
    simpa only [serverDerivedNames,List.take_of_length_le hle] using ho
end rustfs_kernel.Verified.RustfsDerivedKeys
