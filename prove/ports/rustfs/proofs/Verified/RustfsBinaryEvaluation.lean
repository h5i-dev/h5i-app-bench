import Verified.RustfsBinaryMatch
import Verified.RustfsConditionLookupContents
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit

namespace rustfs_kernel.Verified.RustfsBinaryEvaluation

theorem evaluate_sound (inner : conddata.InnerFunc conddata.BinaryFuncValue)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (b : Bool) (h : conddata.binary_evaluate inner values = ok b) :
    b = true → ∀ e ∈ inner.entries.val, BinaryEntrySatisfied values e := by
  unfold conddata.binary_evaluate conddata.binary_evaluate_loop at h
  refine loop_ok _ (fun i : Usize => i.val ≤ inner.entries.val.length ∧
      ∀ e ∈ inner.entries.val.take i.val, BinaryEntrySatisfied values e)
    (fun r => r = true → ∀ e ∈ inner.entries.val, BinaryEntrySatisfied values e)
    (fun i => inner.entries.val.length - i.val) ?_ _ b ⟨by simp, by simp⟩ h
  rintro i r ⟨hi,hsat⟩ hr
  unfold conddata.binary_evaluate_loop.body at hr
  h5i_invert hr
  · intro hf; cases hf
  · have he := vec_index_slice_ok_get? hentry
    have hlt : i.val < inner.entries.val.length := by scalar_tac
    rw [List.getElem?_eq_getElem hlt] at he
    simp only [Option.some.injEq] at he
    have hk := rustfs_kernel.Verified.RustfsConditionEval.lookup_name_ok _ _ hv
    obtain ⟨kv, hkv, hname, hpayload⟩ :=
      rustfs_kernel.Verified.RustfsConditionLookupContents.get_contents_ok _ _ _ ho
    simp only [rustfs_kernel.Verified.RustfsForceDelete.deref_val] at hname
    have hm := rustfs_kernel.Verified.RustfsBinaryMatch.match_sound _ _ _ hb_1 hc_1
    simp only [rustfs_kernel.Verified.RustfsForceDelete.deref_val] at hm
    have hentryok : BinaryEntrySatisfied values entry := by
      refine ⟨kv, hkv, hname.trans hk, ?_, ?_⟩
      · rw [hpayload]; exact hm.1
      · rw [hpayload]; exact hm.2
    have hadd := add_ok_val hi2
    refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
    intro e hem
    rw [show i2.val = i.val + 1 by scalar_tac, List.take_add_one,
      List.getElem?_eq_getElem hlt, he] at hem
    simp only [Option.toList_some, List.mem_append, List.mem_singleton] at hem
    rcases hem with hem | rfl
    · exact hsat e hem
    · exact hentryok
  · intro hf; cases hf
  · intro _
    rw [List.take_of_length_le (by scalar_tac)] at hsat
    exact hsat
end rustfs_kernel.Verified.RustfsBinaryEvaluation
