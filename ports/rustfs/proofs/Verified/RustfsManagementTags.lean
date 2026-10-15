import SpecManagement
import Verified.RustfsConditionNames
import Verified.RustfsCondData
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsManagementTags
open rustfs_kernel.Verified.RustfsForceDelete (lift_slice deref_val nats_inj)
theorem condition_tag_ok (c : conddata.Condition) (b : Bool)
    (h : manage.condition_uses_tag c = ok b) : (b = true ↔ ConditionUsesExistingTag c) := by
  unfold manage.condition_uses_tag at h
  cases hd : c.data <;> rw [hd] at h <;> h5i_invert h
  all_goals
    have hm := rustfs_kernel.Verified.RustfsCondData.contains_key_name_ok _ _ _ h
    have hs' : nats s.val = lit "s3:ExistingObjectTag" := (lift_slice hs).trans (by decide +kernel)
    rw [hm]
    simp only [ConditionUsesExistingTag,hd,InnerUsesExistingTag]
    apply exists_congr
    intro e
    apply and_congr_right
    intro _
    constructor
    · intro he; rw [he,hs']
    · intro he; apply nats_inj; rw [hs']; exact he
theorem overwritten_suffix_ok (cs : Slice conddata.Condition) (nm : alloc.vec.Vec U8)
    (start : Usize) (b : Bool) (h : manage.overwritten_loop cs nm start = ok b) :
    (b = true ↔ ∃ j, start.val ≤ j ∧ ∃ hj : j < cs.val.length,
      nats nm.val = ConditionKeyName cs.val[j]) := by
  unfold manage.overwritten_loop at h
  refine loop_ok _ (fun i : Usize => start.val ≤ i.val ∧
      ∀ j, start.val ≤ j → j < i.val → ∀ hj : j < cs.val.length,
        nats nm.val ≠ ConditionKeyName cs.val[j])
    (fun b => b = true ↔ ∃ j, start.val ≤ j ∧ ∃ hj : j < cs.val.length,
      nats nm.val = ConditionKeyName cs.val[j])
    (fun i : Usize => cs.val.length - i.val) ?_ _ b ⟨by omega,by omega⟩ h
  intro i r hi hr
  unfold manage.overwritten_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok hc_1
    have hn := rustfs_kernel.Verified.RustfsConditionNames.suffixed_key_ok _ _ hv
    have hb := (rustfs_kernel.Verified.RustfsForceDelete.bytes_eq_ok _ _ _ hb_1).1 hc_2
    simp only [deref_val] at hb
    simp only [true_iff]
    refine ⟨i.val,hi.1,hlt,?_⟩
    rw [he,←hn,hb]
  · obtain ⟨hlt,he⟩ := slice_index_ok hc_1
    have hn := rustfs_kernel.Verified.RustfsConditionNames.suffixed_key_ok _ _ hv
    have hb := rustfs_kernel.Verified.RustfsForceDelete.bytes_eq_ok _ _ _ hb_1
    have hadd := add_ok_val hj1
    refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
    intro j hstart hji hj
    by_cases hji' : j < i.val
    · exact hi.2 j hstart hji' hj
    · have hje : j = i.val := by scalar_tac
      subst j
      rw [he,←hn]
      intro hh
      apply hc_2
      apply hb.2
      simp only [deref_val]
      exact nats_inj hh
  · simp only [Bool.false_eq_true,false_iff]
    rintro ⟨j,hstart,hj,he⟩
    exact hi.2 j hstart (by scalar_tac) hj he
theorem overwritten_ok (cs : Slice conddata.Condition) (i : Usize)
    (hi : i.val < cs.val.length) (b : Bool) (h : manage.overwritten cs i = ok b) :
    (b = true ↔ ∃ j, i.val < j ∧ ∃ hj : j < cs.val.length,
      ConditionKeyName cs.val[i.val] = ConditionKeyName cs.val[j]) := by
  unfold manage.overwritten at h
  h5i_invert h
  obtain ⟨hlt,he⟩ := slice_index_ok hc
  have hn := rustfs_kernel.Verified.RustfsConditionNames.suffixed_key_ok _ _ hname
  have hadd := add_ok_val hj
  rw [overwritten_suffix_ok _ _ _ _ h,hn,←he]
  have hj' : j.val = i.val + 1 := by scalar_tac
  simp only [hj',Nat.add_one_le_iff]
theorem list_tag_ok (cs : Slice conddata.Condition) (b : Bool)
    (h : manage.list_uses_tag cs = ok b) : (b = true ↔ ActiveTagConditions cs.val) := by
  unfold manage.list_uses_tag manage.list_uses_tag_loop at h
  have hm : (b = true ↔ ∃ j ∈ List.range cs.val.length,
      ∃ hj : j < cs.val.length, ConditionUsesExistingTag cs.val[j] ∧
        ∀ k, j < k → ∀ hk : k < cs.val.length,
          ConditionKeyName cs.val[j] ≠ ConditionKeyName cs.val[k]) := by
    refine rustfs_kernel.Verified.RustfsValids.any_loop _ _ _ (fun i r _ hr => ?_) b h
    unfold manage.list_uses_tag_loop.body at hr
    h5i_invert hr
    · have hlt : i.val < cs.val.length := by scalar_tac
      have ho := (overwritten_ok cs i hlt _ hb_1).1 hc_1
      refine ⟨by simpa using hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
      simp only [List.getElem_range]
      rintro ⟨hi,_,hlast⟩
      obtain ⟨j,hj,hj',he⟩ := ho
      exact hlast j hj hj' he
    · obtain ⟨hlt,he⟩ := slice_index_ok hc_2
      have ho := overwritten_ok cs i hlt _ hb_1
      have ht := (condition_tag_ok c _ hb1).1 hc_3
      refine .inl ⟨by simpa using hlt, ?_, rfl⟩
      simp only [List.getElem_range]
      refine ⟨hlt,by rw [he]; exact ht,?_⟩
      intro j hj hj' hh
      exact hc_1 (ho.2 ⟨j,hj,hj',hh⟩)
    · obtain ⟨hlt,he⟩ := slice_index_ok hc_2
      have ht := condition_tag_ok c _ hb1
      refine ⟨by simpa using hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
      simp only [List.getElem_range]
      rintro ⟨hi,htag,_⟩
      apply hc_3; apply ht.2
      rwa [he] at htag
    · exact .inr ⟨by simpa using (show cs.val.length ≤ i.val by scalar_tac),rfl⟩
  rw [hm]
  constructor
  · rintro ⟨j,_,hj,hp⟩; exact ⟨j,hj,hp⟩
  · rintro ⟨j,hj,hp⟩; exact ⟨j,List.mem_range.2 hj,hj,hp⟩
theorem functions_tag_ok (f : conddata.Functions) (b : Bool)
    (h : manage.functions_use_existing_object_tag f = ok b) :
    (b = true ↔ FunctionsUseExistingTag f) := by
  unfold manage.functions_use_existing_object_tag at h
  h5i_invert h
  all_goals
    try have ha := list_tag_ok _ _ hb_1
    try have hb' := list_tag_ok _ _ hb1
    try have hn := list_tag_ok _ _ h
    simp_all [FunctionsUseExistingTag,deref_val]

theorem policy_tag_ok (p : manage.Policy) (b : Bool)
    (h : manage.policy_uses_existing_object_tag_conditions p = ok b) :
    (b = true ↔ ∃ st ∈ p.statements.val, FunctionsUseExistingTag st.conditions) := by
  unfold manage.policy_uses_existing_object_tag_conditions manage.policy_uses_existing_object_tag_conditions_loop at h
  refine rustfs_kernel.Verified.RustfsValids.any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold manage.policy_uses_existing_object_tag_conditions_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := vec_index_ok hs
    have ht := (functions_tag_ok _ _ hb_1).1 hc_1
    exact .inl ⟨hlt,by rw [he]; exact ht,rfl⟩
  · obtain ⟨hlt,he⟩ := vec_index_ok hs
    have ht := functions_tag_ok _ _ hb_1
    refine ⟨hlt,?_,by have := add_ok_val hi2; scalar_tac⟩
    rw [he]; exact fun hh => hc_1 (ht.2 hh)
  · exact .inr ⟨by scalar_tac,rfl⟩

theorem bucket_tag_ok (p : manage.BucketPolicy) (b : Bool)
    (h : manage.bucket_policy_uses_existing_object_tag_conditions p = ok b) :
    (b = true ↔ ∃ st ∈ p.statements.val, FunctionsUseExistingTag st.conditions) := by
  unfold manage.bucket_policy_uses_existing_object_tag_conditions manage.bucket_policy_uses_existing_object_tag_conditions_loop at h
  refine rustfs_kernel.Verified.RustfsValids.any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold manage.bucket_policy_uses_existing_object_tag_conditions_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := vec_index_ok hb_1
    have ht := (functions_tag_ok _ _ hb1).1 hc_1
    exact .inl ⟨hlt,by rw [he]; exact ht,rfl⟩
  · obtain ⟨hlt,he⟩ := vec_index_ok hb_1
    have ht := functions_tag_ok _ _ hb1
    refine ⟨hlt,?_,by have := add_ok_val hi2; scalar_tac⟩
    rw [he]; exact fun hh => hc_1 (ht.2 hh)
  · exact .inr ⟨by scalar_tac,rfl⟩
end rustfs_kernel.Verified.RustfsManagementTags
