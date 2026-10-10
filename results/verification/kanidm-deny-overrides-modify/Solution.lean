import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit

namespace kanidm_kernel.Solution

@[step] theorem bytes_eq_total (a b : Slice U8) :
    bset.bytes_eq a b ⦃ _ => True ⦄ := by
  unfold bset.bytes_eq
  step*
  unfold bset.bytes_eq_loop
  h5i_total (fun i => i) a.val.length

@[step] theorem get_ava_set_total (e : Entry) (attr : Slice U8) :
    entry_impl.get_ava_set e attr ⦃ _ => True ⦄ := by
  unfold entry_impl.get_ava_set entry_impl.get_ava_set_loop
  h5i_total (fun i => i) e.attrs.val.length

@[step] theorem as_refer_set_total (vs : ValueSet) :
    valueset.as_refer_set vs ⦃ _ => True ⦄ := by
  cases vs <;> simp [valueset.as_refer_set]

@[step] theorem get_memberof_total (ident : Identity) :
    identity_impl.get_memberof ident ⦃ _ => True ⦄ := by
  unfold identity_impl.get_memberof entry_impl.get_ava_refer
  h5i_steps

@[step] theorem get_uuid_total (ident : Identity) :
    identity_impl.get_uuid ident ⦃ _ => True ⦄ := by
  unfold identity_impl.get_uuid identity_impl.role_get_uuid
  h5i_steps

@[step] theorem modify_ident_test_total (ident : Identity) :
    modify_acc.modify_ident_test ident ⦃ _ => True ⦄ := by
  unfold modify_acc.modify_ident_test identity_impl.access_scope
  split <;> h5i_steps

@[step] theorem contains_total (set : Slice (alloc.vec.Vec U8)) (x : Slice U8) :
    bset.contains set x ⦃ _ => True ⦄ := by
  unfold bset.contains bset.contains_loop
  h5i_total (fun i => i) set.val.length

@[step] theorem insert_bound (set : alloc.vec.Vec (alloc.vec.Vec U8)) (x : Slice U8)
    (hsize : set.val.length < Usize.max) :
    bset.insert set x ⦃ out => out.val.length ≤ set.val.length + 1 ⦄ := by
  unfold bset.insert
  h5i_steps
  all_goals simp_all

@[step] theorem as_iutf8_set_total (vs : ValueSet) :
    valueset.as_iutf8_set vs ⦃ _ => True ⦄ := by
  cases vs <;> simp [valueset.as_iutf8_set]

@[step] theorem get_ava_as_iutf8_total (e : Entry) (attr : Slice U8) :
    entry_impl.get_ava_as_iutf8 e attr ⦃ _ => True ⦄ := by
  unfold entry_impl.get_ava_as_iutf8
  h5i_steps

@[step] theorem migration_ignore_classes_total (c : Slice U8) :
    migration.migration_ignore_classes c ⦃ _ => True ⦄ := by
  unfold migration.migration_ignore_classes
  h5i_steps

@[step] theorem migration_entry_classes_total (c : Slice U8) :
    migration.migration_entry_classes c ⦃ _ => True ⦄ := by
  unfold migration.migration_entry_classes
  h5i_steps

@[step] theorem subset_migration_entry_total (classes : Slice (alloc.vec.Vec U8)) :
    migration.subset_migration_entry classes ⦃ _ => True ⦄ := by
  unfold migration.subset_migration_entry migration.subset_migration_entry_loop
  h5i_total (fun i => i) classes.val.length

@[step] theorem sub_migration_ignore_bound (classes : Slice (alloc.vec.Vec U8)) :
    migration.sub_migration_ignore classes ⦃ out => out.val.length ≤ classes.val.length ⦄ := by
  unfold migration.sub_migration_ignore migration.sub_migration_ignore_loop
  apply loop_idx_spec _ (fun x => x.2) classes.val.length
    (fun x => x.1.val.length ≤ x.2.val) _ ?_ _ (by simp) (by simp)
  rintro ⟨out, i⟩ hout hi
  unfold migration.sub_migration_ignore_loop.body
  h5i_steps

@[step] theorem extend_empty_total (xs : Slice (alloc.vec.Vec U8)) :
    bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) xs ⦃ _ => True ⦄ := by
  unfold bset.extend bset.extend_loop
  apply loop_idx_spec _ (fun x => x.2) xs.val.length
    (fun x => x.1.val.length ≤ x.2.val) _ ?_ _ (by simp) (by simp)
  rintro ⟨set, i⟩ hset hi
  unfold bset.extend_loop.body
  h5i_steps

@[step] theorem byte_sets_clone_spec (v : alloc.vec.Vec (alloc.vec.Vec U8)) :
    alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) v
      ⦃ out => out = v ⦄ := by
  have hc := vec_clone_ok (core.clone.CloneallocvecVec core.clone.CloneU8) v
    (fun x => u8vec_clone x)
  simp [hc]

set_option maxHeartbeats 0 in
set_option maxRecDepth 4096 in
@[step] theorem migration_entry_attrs_total (classes : Slice (alloc.vec.Vec U8)) :
    migration.migration_entry_attrs classes ⦃ _ => True ⦄ := by
  have hmax := usize_max_ge
  unfold migration.migration_entry_attrs migration.ins
  step*
  -- Summarize each conditional before checking the rest of the function.
  apply WP.spec_bind (Pₘ := fun out => out.val.length ≤ 6)
  · split <;> step*
  intro attrs hattrs
  step*
  apply WP.spec_bind (Pₘ := fun out => out.1.val.length ≤ 11 ∧ out.2.val.length ≤ 3)
  · split <;> step*
  rintro ⟨attrs, cls⟩ ⟨hattrs, hcls⟩
  dsimp only at hattrs hcls
  step*
  apply WP.spec_bind (Pₘ := fun out => out.1.val.length ≤ 19 ∧ out.2.val.length ≤ 3)
  · split <;> step*
    simp only [vec_new_val, List.length_nil] at *
    constructor <;> omega
  rintro ⟨attrs, cls⟩ ⟨hattrs, hcls⟩
  dsimp only at hattrs hcls
  step*
  apply WP.spec_bind (Pₘ := fun out => out.1.val.length ≤ 25 ∧ out.2.val.length ≤ 3)
  · split <;> step*
  rintro ⟨attrs, cls⟩ ⟨hattrs, hcls⟩
  dsimp only at hattrs hcls
  step*
  apply WP.spec_bind (Pₘ := fun out => out.val.length ≤ 33)
  · split <;> step*
  intro attrs hattrs
  h5i_steps

@[step] theorem modify_migration_attrs_total (ident : Identity) (entry : Entry) :
    modify_acc.modify_migration_attrs ident entry ⦃ _ => True ⦄ := by
  unfold modify_acc.modify_migration_attrs
  h5i_steps

theorem protected_deny_overrides_modify (ident : Identity)
    (related : Slice profiles.AccessControlModifyResolved) (sa : Slice SyncAgreement) (e : Entry)
    (h : modify_acc.modify_protected_attrs ident e = ok .Deny) :
    modify_acc.apply_modify_access ident related sa e = ok .Deny := by
  apply eq_ok_of_spec
  unfold modify_acc.apply_modify_access
  simp only [h]
  h5i_steps

end kanidm_kernel.Solution
