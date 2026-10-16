import Verified.RustfsConditionNames
import Verified.RustfsConditionCopies
import Verified.RustfsCompleteConditionEquality
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsConditionCopies
open rustfs_kernel.Verified.RustfsCompleteConditionEquality

namespace rustfs_kernel.Verified.RustfsConditionViews
 theorem str_op_ok (op : conddata.Op) : conddata.str_op op = ok (StringOpProjection op) := by
  cases op <;> rfl
 theorem num_op_ok (op : conddata.Op) : conddata.num_op op = ok (NumberOpProjection op) := by
  cases op <;> rfl

 theorem condition_view_ok (c : conddata.Condition) (v : condfuncs.Condition)
    (h : conddata.condition_view c = ok v) : MatchingView c v := by
  unfold conddata.condition_view at h
  simp only [str_op_ok, num_op_ok, op_eq_law, bind_tc_ok, bind_ok] at h
  cases hd : c.data <;> simp only [hd] at h
  all_goals h5i_invert h
  all_goals h5i_invert hcond
  all_goals try have hp := legacy_pairs_ok _ _ _ (by assumption : conddata.legacy_pairs _ _ = ok _)
  all_goals try have hp := key_presence_ok _ _ (by assumption : conddata.key_presence _ = ok _)
  all_goals simp_all [MatchingView, MatchingViewContents]

theorem forall₂_snoc {A B : Type} {R : A → B → Prop} {xs : List A} {ys : List B}
    (h : List.Forall₂ R xs ys) {x : A} {y : B} (hr : R x y) :
    List.Forall₂ R (xs ++ [x]) (ys ++ [y]) := by
  induction h with
  | nil => exact .cons hr .nil
  | cons h ht ih => exact .cons h ih

theorem views_ok (cs : Slice conddata.Condition) (vs : alloc.vec.Vec condfuncs.Condition)
    (h : conddata.views cs = ok vs) : MatchingViews cs.val vs.val := by
  unfold conddata.views conddata.views_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec condfuncs.Condition × Usize =>
      x.2.val ≤ cs.val.length ∧ MatchingViews (cs.val.take x.2.val) x.1.val)
    (fun v => MatchingViews cs.val v.val) (fun x => cs.val.length - x.2.val)
    ?_ _ vs ⟨by simp, by constructor⟩ h
  rintro ⟨out, i⟩ r ⟨hi, ho⟩ hr
  unfold conddata.views_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt, he⟩ := slice_index_ok (by assumption : Slice.index_usize _ _ = ok _)
    have hv := condition_view_ok _ _ (by assumption : conddata.condition_view _ = ok _)
    have hp := rustfs_kernel.Verified.RustfsBytes.push_ok hout1
    have hadd := add_ok_val hi2
    refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
    rw [hp, show i2.val = i.val + 1 by scalar_tac, List.take_add_one,
      List.getElem?_eq_getElem hlt, he]
    exact forall₂_snoc ho hv
  · rw [List.take_of_length_le (by scalar_tac)] at ho
    exact ho

theorem matching_view_ok (f : conddata.Functions) (v : condfuncs.Functions)
    (h : conddata.matching_view f = ok v) :
    MatchingViews f.for_any_value.val v.for_any_value.val ∧
    MatchingViews f.for_all_values.val v.for_all_values.val ∧
    MatchingViews f.for_normal.val v.for_normal.val := by
  unfold conddata.matching_view at h
  h5i_invert h
  refine ⟨?_, ?_, ?_⟩
  · simpa only [rustfs_kernel.Verified.RustfsForceDelete.deref_val] using views_ok _ _ hv_1
  · simpa only [rustfs_kernel.Verified.RustfsForceDelete.deref_val] using views_ok _ _ hv1
  · simpa only [rustfs_kernel.Verified.RustfsForceDelete.deref_val] using views_ok _ _ hv2

theorem base_key_ok (c : conddata.Condition) (v : alloc.vec.Vec U8)
    (h : conddata.to_key c = ok v) : nats v.val = ConditionBaseKeyName c := by
  unfold conddata.to_key at h
  by_cases hw : 0 < c.wrappers.val
  · have hw' : c.wrappers > 0#usize := by scalar_tac
    simp only [hw', ↓reduceIte] at h
    h5i_invert h
    rw [rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok _ _ h,
      rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs]
    simp only [ConditionBaseKeyName, hw, ↓reduceIte]
    decide +kernel
  · have hw' : ¬ c.wrappers > 0#usize := by scalar_tac
    simp only [hw', ↓reduceIte] at h
    simpa [ConditionBaseKeyName, hw] using
      rustfs_kernel.Verified.RustfsConditionNames.op_name_ok c.op v h
end rustfs_kernel.Verified.RustfsConditionViews
