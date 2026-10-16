import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP

namespace kanidm_kernel.Solution
set_option maxHeartbeats 2000000
set_option maxRecDepth 4096
set_option linter.unusedVariables false
set_option linter.unusedTactic false
set_option linter.unusedSimpArgs false
set_option linter.unreachableTactic false

h5i_derive_all

@[simp, step_pre_simps, step_post_simps, scalar_tac_simps]
theorem deref_val {α : Type} (v : alloc.vec.Vec α) : v.deref.val = v.val := by
  simp [alloc.vec.Vec.deref]

macro "total_steps" : tactic => `(tactic| (
  have hmax := H5iAppLib.usize_max_ge
  h5i_steps
  all_goals (try simp_all)
  all_goals (try casesm* _ × _)
  all_goals h5i_steps
  all_goals (try simp_all)
  all_goals (try scalar_tac)))

@[step] theorem identity_impl_role_get_uuid_total
  (role : InternalRole)  :
  identity_impl.role_get_uuid role ⦃ r => True ⦄ := by
  unfold identity_impl.role_get_uuid
  total_steps

@[step] theorem identity_impl_get_uuid_total
  (ident : Identity)  :
  identity_impl.get_uuid ident ⦃ r => True ⦄ := by
  unfold identity_impl.get_uuid
  total_steps

@[step] theorem valueset_as_refer_set_total
  (vs : ValueSet)  :
  valueset.as_refer_set vs ⦃ r => True ⦄ := by
  unfold valueset.as_refer_set
  total_steps

@[step] theorem bset_contains_uuid_loop_total
  (set : Slice Std.U128) (u : Std.U128) (i : Std.Usize)  (hi : i.val ≤ set.length) :
  bset.contains_uuid_loop set u i ⦃ r => True ⦄ := by
  unfold bset.contains_uuid_loop
  h5i_total (fun i => i) set.length
  all_goals total_steps

@[step] theorem bset_contains_uuid_total
  (set : Slice Std.U128) (u : Std.U128)  :
  bset.contains_uuid set u ⦃ r => True ⦄ := by
  unfold bset.contains_uuid
  total_steps

@[step] theorem bset_intersects_uuid_loop_total
  (a : Slice Std.U128) (b : Slice Std.U128) (i : Std.Usize)  (hi : i.val ≤ a.length) :
  bset.intersects_uuid_loop a b i ⦃ r => True ⦄ := by
  unfold bset.intersects_uuid_loop
  h5i_total (fun i => i) a.length
  all_goals total_steps

@[step] theorem bset_intersects_uuid_total
  (a : Slice Std.U128) (b : Slice Std.U128)  :
  bset.intersects_uuid a b ⦃ r => True ⦄ := by
  unfold bset.intersects_uuid
  total_steps

@[step] theorem bset_bytes_eq_loop_total
  (a : Slice Std.U8) (b : Slice Std.U8) (i : Std.Usize) (hlen : a.length = b.length) (hi : i.val ≤ a.length) :
  bset.bytes_eq_loop a b i ⦃ r => True ⦄ := by
  unfold bset.bytes_eq_loop
  h5i_total (fun i => i) a.length
  all_goals total_steps

@[step] theorem bset_bytes_eq_total
  (a : Slice Std.U8) (b : Slice Std.U8)  :
  bset.bytes_eq a b ⦃ r => True ⦄ := by
  unfold bset.bytes_eq
  total_steps

@[step] theorem entry_impl_get_ava_set_loop_total
  (e : Entry) (attr : Slice Std.U8) (i : Std.Usize)  (hi : i.val ≤ e.attrs.val.length) :
  entry_impl.get_ava_set_loop e attr i ⦃ r => True ⦄ := by
  unfold entry_impl.get_ava_set_loop
  h5i_total (fun i => i) e.attrs.val.length
  all_goals total_steps

@[step] theorem entry_impl_get_ava_set_total
  (e : Entry) (attr : Slice Std.U8)  :
  entry_impl.get_ava_set e attr ⦃ r => True ⦄ := by
  unfold entry_impl.get_ava_set
  total_steps

@[step] theorem entry_impl_get_ava_refer_total
  (e : Entry) (attr : Slice Std.U8)  :
  entry_impl.get_ava_refer e attr ⦃ r => True ⦄ := by
  unfold entry_impl.get_ava_refer
  total_steps

@[step] theorem identity_impl_get_memberof_total
  (ident : Identity)  :
  identity_impl.get_memberof ident ⦃ r => True ⦄ := by
  unfold identity_impl.get_memberof
  total_steps

@[step] theorem bset_contains_loop_total
  (set : Slice (alloc.vec.Vec Std.U8)) (x : Slice Std.U8) (i : Std.Usize)  (hi : i.val ≤ set.length) :
  bset.contains_loop set x i ⦃ r => True ⦄ := by
  unfold bset.contains_loop
  h5i_total (fun i => i) set.length
  all_goals total_steps

@[step] theorem bset_contains_total
  (set : Slice (alloc.vec.Vec Std.U8)) (x : Slice Std.U8)  :
  bset.contains set x ⦃ r => True ⦄ := by
  unfold bset.contains
  total_steps

@[step] theorem bset_is_disjoint_loop_total
  (a : Slice (alloc.vec.Vec Std.U8)) (b : Slice (alloc.vec.Vec Std.U8))
  (i : Std.Usize)  (hi : i.val ≤ a.length) :
  bset.is_disjoint_loop a b i ⦃ r => True ⦄ := by
  unfold bset.is_disjoint_loop
  h5i_total (fun i => i) a.length
  all_goals total_steps

@[step] theorem bset_is_disjoint_total
  (a : Slice (alloc.vec.Vec Std.U8)) (b : Slice (alloc.vec.Vec Std.U8))  :
  bset.is_disjoint a b ⦃ r => True ⦄ := by
  unfold bset.is_disjoint
  total_steps

-- Recursive filters are measured by their finite syntax trees.
theorem listN_member_size {α : Type} [SizeOf α] {n : Nat}
    (l : Aeneas.Data.ListN.ListN α n) (x : α) (hx : x ∈ l.toList) :
    sizeOf x < sizeOf l := by
  induction l with
  | nil => simp [Aeneas.Data.ListN.ListN.toList] at hx
  | cons y ys ih =>
    simp only [Aeneas.Data.ListN.ListN.toList, List.mem_cons] at hx
    rcases hx with rfl | hx
    · simp only [Aeneas.Data.ListN.ListN.cons.sizeOf_spec]; omega
    · have := ih hx
      simp only [Aeneas.Data.ListN.ListN.cons.sizeOf_spec]; omega

theorem vec_member_size {α : Type} [SizeOf α] (v : alloc.vec.Vec α)
    (x : α) (hx : x ∈ v.val) : sizeOf x < sizeOf v := by
  have h := listN_member_size v.slice.list x hx
  cases v with
  | mk s =>
    cases s
    simp_all [alloc.vec.Vec.mk.sizeOf_spec, Slice.mk.sizeOf_spec]
    omega

@[step] theorem resolve_list_aux
    (vs : alloc.vec.Vec FilterComp) (ev : Identity) (i : Usize)
    (acc : alloc.vec.Vec FilterResolved)
    (hall : ∀ x ∈ vs.val, filter_impl.resolve_no_idx x ev ⦃ _ => True ⦄)
    (hi : i.val ≤ vs.val.length)
    (hacc : acc.val.length + (vs.val.length - i.val) ≤ Usize.max) :
    filter_impl.resolve_no_idx_list vs ev i acc ⦃ _ => True ⦄ := by
  h5i_measure_induction (vs.val.length - i.val) with ih
  have hrec : ∀ (vs : alloc.vec.Vec FilterComp) (ev : Identity) (i : Usize)
      (acc : alloc.vec.Vec FilterResolved),
      (∀ x ∈ vs.val, filter_impl.resolve_no_idx x ev ⦃ _ => True ⦄) →
      i.val ≤ vs.val.length →
      acc.val.length + (vs.val.length - i.val) ≤ Usize.max →
      vs.val.length - i.val < k →
      filter_impl.resolve_no_idx_list vs ev i acc ⦃ _ => True ⦄ := by
    intro vs ev i acc hall hi hacc hlt
    exact ih _ hlt vs ev i acc hall hi hacc rfl
  clear ih
  rw [filter_impl.resolve_no_idx_list.eq_def]
  step*
  all_goals (try scalar_tac)
  all_goals (try (step with hall by simp))
  all_goals (repeat' (first | step | split))
  all_goals (try simp_all)
  all_goals (try scalar_tac)

@[step] theorem resolve_total (fc : FilterComp) (ev : Identity) :
    filter_impl.resolve_no_idx fc ev ⦃ _ => True ⦄ := by
  induction hn : sizeOf fc using Nat.strong_induction_on generalizing fc with
  | h n ih =>
    have hall : ∀ (vs : alloc.vec.Vec FilterComp), sizeOf vs < n →
        ∀ x ∈ vs.val, filter_impl.resolve_no_idx x ev ⦃ _ => True ⦄ := by
      intro vs hv x hx
      exact ih (sizeOf x) (by have := vec_member_size vs x hx; omega) x rfl
    have hrec : ∀ f : FilterComp, sizeOf f < n →
        filter_impl.resolve_no_idx f ev ⦃ _ => True ⦄ := by
      intro f hf
      exact ih _ hf f rfl
    clear ih
    rw [filter_impl.resolve_no_idx.eq_def]
    cases fc <;> total_steps
    all_goals (try (step with resolve_list_aux by
      first | (apply hall; simp_all) | scalar_tac))
    all_goals (try (step with hrec by simp_all))
    all_goals total_steps

@[step] theorem filter_resolve_total (fc : FilterComp) (ev : Identity) :
    filter_impl.resolve fc ev ⦃ _ => True ⦄ := by
  unfold filter_impl.resolve
  total_steps

@[step] theorem access_resolve_access_conditions_total
  (ident : Identity) (ident_memberof : Option (alloc.vec.Vec Std.U128))
  (receiver : profiles.AccessControlReceiver)
  (target : profiles.AccessControlTarget)  :
  access.resolve_access_conditions ident ident_memberof receiver target ⦃ r => True ⦄ := by
  unfold access.resolve_access_conditions
  total_steps

@[step] theorem bset_insert_total
  (set : alloc.vec.Vec (alloc.vec.Vec Std.U8)) (x : Slice Std.U8) (hcap : set.val.length < Usize.max) :
  bset.insert set x ⦃ r => r.val.length ≤ set.val.length + 1 ⦄ := by
  unfold bset.insert
  total_steps

@[step] theorem bset_extend_loop_total
  (set : alloc.vec.Vec (alloc.vec.Vec Std.U8))
  (xs : Slice (alloc.vec.Vec Std.U8)) (i : Std.Usize) (hi : i.val ≤ xs.length) (hcap : set.val.length + (xs.length - i.val) ≤ Usize.max)  :
  bset.extend_loop set xs i ⦃ r => r.val.length ≤ set.val.length + (xs.length - i.val) ⦄ := by
  unfold bset.extend_loop
  apply loop.spec_decr_nat (measure := fun x => xs.length - x.2.val)
    (inv := fun x => x.2.val ≤ xs.length ∧ x.1.val.length + (xs.length - x.2.val) ≤ set.val.length + (xs.length - i.val))
  · rintro ⟨s, j⟩ ⟨hj, hs⟩
    h5i_unfold_body
    total_steps
  · exact ⟨hi, by simp⟩

@[step] theorem bset_extend_total
  (set : alloc.vec.Vec (alloc.vec.Vec Std.U8))
  (xs : Slice (alloc.vec.Vec Std.U8)) (hcap : set.val.length + xs.length ≤ Usize.max) :
  bset.extend set xs ⦃ r => r.val.length ≤ set.val.length + xs.length ⦄ := by
  unfold bset.extend
  total_steps

@[step] theorem search_acc_extend_if_total
  (set : alloc.vec.Vec (alloc.vec.Vec Std.U8)) (ok1 : Bool)
  (xs : Slice (alloc.vec.Vec Std.U8)) (hcap : set.val.length + xs.length ≤ Usize.max) :
  search_acc.extend_if set ok1 xs ⦃ r => r.val.length ≤ set.val.length + xs.length ⦄ := by
  unfold search_acc.extend_if
  total_steps

@[step] theorem valueset_as_iutf8_set_total
  (vs : ValueSet)  :
  valueset.as_iutf8_set vs ⦃ r => True ⦄ := by
  unfold valueset.as_iutf8_set
  total_steps

@[step] theorem entry_impl_get_ava_as_iutf8_total
  (e : Entry) (attr : Slice Std.U8)  :
  entry_impl.get_ava_as_iutf8 e attr ⦃ r => True ⦄ := by
  unfold entry_impl.get_ava_as_iutf8
  total_steps

@[step] theorem entry_impl_class_contains_total
  (e : Entry) («class» : Slice Std.U8)  :
  entry_impl.class_contains e «class» ⦃ r => True ⦄ := by
  unfold entry_impl.class_contains
  total_steps

@[step] theorem search_acc_is_sync_account_user_total
  (e : Entry)  :
  search_acc.is_sync_account_user e ⦃ r => True ⦄ := by
  unfold search_acc.is_sync_account_user
  total_steps

@[step] theorem valueset_to_refer_single_total
  (vs : ValueSet)  :
  valueset.to_refer_single vs ⦃ r => True ⦄ := by
  unfold valueset.to_refer_single
  total_steps

@[step] theorem entry_impl_get_ava_single_refer_total
  (e : Entry) (attr : Slice Std.U8)  :
  entry_impl.get_ava_single_refer e attr ⦃ r => True ⦄ := by
  unfold entry_impl.get_ava_single_refer
  total_steps

@[step] theorem search_acc_linked_group_member_total
  (group : Option Std.U128) (mo : Option (alloc.vec.Vec Std.U128))  :
  search_acc.linked_group_member group mo ⦃ r => True ⦄ := by
  unfold search_acc.linked_group_member
  total_steps

@[step] theorem search_acc_scope_member_total
  (maps : Option (alloc.vec.Vec Std.U128))
  (mo : Option (alloc.vec.Vec Std.U128))  :
  search_acc.scope_member maps mo ⦃ r => True ⦄ := by
  unfold search_acc.scope_member
  total_steps

@[step] theorem valueset_as_oauthscopemap_total
  (vs : ValueSet)  :
  valueset.as_oauthscopemap vs ⦃ r => True ⦄ := by
  unfold valueset.as_oauthscopemap
  total_steps

@[step] theorem entry_impl_get_ava_as_oauthscopemaps_total
  (e : Entry) (attr : Slice Std.U8)  :
  entry_impl.get_ava_as_oauthscopemaps e attr ⦃ r => True ⦄ := by
  unfold entry_impl.get_ava_as_oauthscopemaps
  total_steps

@[step] theorem migration_migration_entry_classes_total
  (c : Slice Std.U8)  :
  migration.migration_entry_classes c ⦃ r => True ⦄ := by
  unfold migration.migration_entry_classes
  total_steps

@[step] theorem migration_migration_ignore_classes_total
  (c : Slice Std.U8)  :
  migration.migration_ignore_classes c ⦃ r => True ⦄ := by
  unfold migration.migration_ignore_classes
  total_steps

@[step] theorem migration_subset_migration_entry_loop_total
  (classes : Slice (alloc.vec.Vec Std.U8)) (i : Std.Usize) (hi : i.val ≤ classes.length) :
  migration.subset_migration_entry_loop classes i ⦃ r => True ⦄ := by
  unfold migration.subset_migration_entry_loop
  h5i_total (fun i => i) classes.length

@[step] theorem migration_subset_migration_entry_total
  (classes : Slice (alloc.vec.Vec Std.U8))  :
  migration.subset_migration_entry classes ⦃ r => True ⦄ := by
  unfold migration.subset_migration_entry
  total_steps

@[step] theorem valueset_any_less_u32_loop_total
  (set : Slice Std.U32) (u : Std.U32) (i : Std.Usize) (hi : i.val ≤ set.length) :
  valueset.any_less_u32_loop set u i ⦃ r => True ⦄ := by
  unfold valueset.any_less_u32_loop
  h5i_total (fun i => i) set.length

@[step] theorem valueset_any_less_u32_total
  (set : Slice Std.U32) (u : Std.U32)  :
  valueset.any_less_u32 set u ⦃ r => True ⦄ := by
  unfold valueset.any_less_u32
  total_steps

@[step] theorem valueset_any_less_uuid_loop_total
  (set : Slice Std.U128) (u : Std.U128) (i : Std.Usize) (hi : i.val ≤ set.length) :
  valueset.any_less_uuid_loop set u i ⦃ r => True ⦄ := by
  unfold valueset.any_less_uuid_loop
  h5i_total (fun i => i) set.length

@[step] theorem valueset_any_less_uuid_total
  (set : Slice Std.U128) (u : Std.U128)  :
  valueset.any_less_uuid set u ⦃ r => True ⦄ := by
  unfold valueset.any_less_uuid
  total_steps

@[step] theorem valueset_contains_u32_loop_total
  (set : Slice Std.U32) (u : Std.U32) (i : Std.Usize) (hi : i.val ≤ set.length) :
  valueset.contains_u32_loop set u i ⦃ r => True ⦄ := by
  unfold valueset.contains_u32_loop
  h5i_total (fun i => i) set.length

@[step] theorem valueset_contains_u32_total
  (set : Slice Std.U32) (u : Std.U32)  :
  valueset.contains_u32 set u ⦃ r => True ⦄ := by
  unfold valueset.contains_u32
  total_steps

@[step] theorem valueset_vs_lessthan_total
  (vs : ValueSet) (pv : PartialValue)  :
  valueset.vs_lessthan vs pv ⦃ r => True ⦄ := by
  unfold valueset.vs_lessthan
  total_steps

@[step] theorem entry_impl_attribute_lessthan_total
  (e : Entry) (attr : Slice Std.U8) (subvalue : PartialValue)  :
  entry_impl.attribute_lessthan e attr subvalue ⦃ r => True ⦄ := by
  unfold entry_impl.attribute_lessthan
  total_steps

@[step] theorem valueset_vs_contains_total
  (vs : ValueSet) (pv : PartialValue)  :
  valueset.vs_contains vs pv ⦃ r => True ⦄ := by
  unfold valueset.vs_contains
  total_steps

@[step] theorem entry_impl_attribute_equality_total
  (e : Entry) (attr : Slice Std.U8) (value : PartialValue)  :
  entry_impl.attribute_equality e attr value ⦃ r => True ⦄ := by
  unfold entry_impl.attribute_equality
  total_steps

@[step] theorem entry_impl_attribute_pres_total
  (e : Entry) (attr : Slice Std.U8)  :
  entry_impl.attribute_pres e attr ⦃ r => True ⦄ := by
  unfold entry_impl.attribute_pres
  total_steps

@[step] theorem identity_impl_access_scope_total
  (ident : Identity)  :
  identity_impl.access_scope ident ⦃ r => True ⦄ := by
  unfold identity_impl.access_scope
  total_steps

@[step] theorem migration_sub_migration_ignore_loop_total
  (classes : Slice (alloc.vec.Vec Std.U8))
  (out : alloc.vec.Vec (alloc.vec.Vec Std.U8)) (i : Std.Usize) (hi : i.val ≤ classes.length) (hcap : out.val.length + (classes.length - i.val) ≤ Usize.max)  :
  migration.sub_migration_ignore_loop classes out i ⦃ r => r.val.length ≤ out.val.length + (classes.length - i.val) ⦄ := by
  unfold migration.sub_migration_ignore_loop
  apply loop.spec_decr_nat (measure := fun x => classes.length - x.2.val)
    (inv := fun x => x.2.val ≤ classes.length ∧ x.1.val.length + (classes.length - x.2.val) ≤ out.val.length + (classes.length - i.val))
  · rintro ⟨s, j⟩ ⟨hj, hs⟩
    h5i_unfold_body
    total_steps
  · exact ⟨hi, by simp⟩

@[step] theorem migration_sub_migration_ignore_total
  (classes : Slice (alloc.vec.Vec Std.U8))  :
  migration.sub_migration_ignore classes ⦃ r => r.val.length ≤ classes.length ⦄ := by
  unfold migration.sub_migration_ignore
  total_steps

@[step] theorem search_acc_valid_migration_class_total
  (entry : Entry)  :
  search_acc.valid_migration_class entry ⦃ r => True ⦄ := by
  unfold search_acc.valid_migration_class
  total_steps

@[step] theorem valueset_to_lowercase_loop_total
  (s : Slice Std.U8) (out : alloc.vec.Vec Std.U8) (i : Std.Usize) (hi : i.val ≤ s.length) (hcap : out.val.length + (s.length - i.val) ≤ Usize.max)  :
  valueset.to_lowercase_loop s out i ⦃ r => r.val.length ≤ out.val.length + (s.length - i.val) ⦄ := by
  unfold valueset.to_lowercase_loop
  apply loop.spec_decr_nat (measure := fun x => s.length - x.2.val)
    (inv := fun x => x.2.val ≤ s.length ∧ x.1.val.length + (s.length - x.2.val) ≤ out.val.length + (s.length - i.val))
  · rintro ⟨s, j⟩ ⟨hj, hs⟩
    h5i_unfold_body
    total_steps
  · exact ⟨hi, by simp⟩

@[step] theorem valueset_to_lowercase_total
  (s : Slice Std.U8)  :
  valueset.to_lowercase s ⦃ r => r.val.length ≤ s.length ⦄ := by
  unfold valueset.to_lowercase
  total_steps

@[step] theorem valueset_starts_at_loop_total
  (hay : Slice Std.U8) («at» : Std.Usize) (needle : Slice Std.U8)
  (j : Std.Usize) (hi : j.val ≤ needle.length) (hfit : «at».val + needle.length ≤ hay.length) :
  valueset.starts_at_loop hay «at» needle j ⦃ r => needle.length = 0 → r = true ⦄ := by
  unfold valueset.starts_at_loop
  h5i_total (fun j => j) needle.length
  all_goals total_steps

@[step] theorem valueset_starts_at_total
  (hay : Slice Std.U8) («at» : Std.Usize) (needle : Slice Std.U8) (hfit : «at».val + needle.length ≤ hay.length) :
  valueset.starts_at hay «at» needle ⦃ r => needle.length = 0 → r = true ⦄ := by
  unfold valueset.starts_at
  total_steps

@[step] theorem valueset_str_ends_with_total
  (hay : Slice Std.U8) (needle : Slice Std.U8)  :
  valueset.str_ends_with hay needle ⦃ r => True ⦄ := by
  unfold valueset.str_ends_with
  total_steps

@[step] theorem valueset_str_starts_with_total
  (hay : Slice Std.U8) (needle : Slice Std.U8)  :
  valueset.str_starts_with hay needle ⦃ r => True ⦄ := by
  unfold valueset.str_starts_with
  total_steps

@[step] theorem valueset_str_contains_loop_total
  (hay : Slice Std.U8) (needle : Slice Std.U8) (last : Std.Usize)
  (i : Std.Usize) (hi : i.val ≤ last.val + 1) (hfit : last.val + needle.length ≤ hay.length) :
  valueset.str_contains_loop hay needle last i ⦃ r => True ⦄ := by
  unfold valueset.str_contains_loop
  h5i_total (fun i => i) (last.val + 1)
  all_goals total_steps

@[step] theorem valueset_str_contains_total
  (hay : Slice Std.U8) (needle : Slice Std.U8)  :
  valueset.str_contains hay needle ⦃ r => True ⦄ := by
  unfold valueset.str_contains
  total_steps

@[step] theorem valueset_any_ends_with_lower_loop_total
  (set : Slice (alloc.vec.Vec Std.U8)) (s2_lower : Slice Std.U8)
  (i : Std.Usize) (hi : i.val ≤ set.length) :
  valueset.any_ends_with_lower_loop set s2_lower i ⦃ r => True ⦄ := by
  unfold valueset.any_ends_with_lower_loop
  h5i_total (fun i => i) set.length

@[step] theorem valueset_any_ends_with_lower_total
  (set : Slice (alloc.vec.Vec Std.U8)) (s2_lower : Slice Std.U8)  :
  valueset.any_ends_with_lower set s2_lower ⦃ r => True ⦄ := by
  unfold valueset.any_ends_with_lower
  total_steps

@[step] theorem valueset_any_ends_with_loop_total
  (set : Slice (alloc.vec.Vec Std.U8)) (s2 : Slice Std.U8) (i : Std.Usize) (hi : i.val ≤ set.length) :
  valueset.any_ends_with_loop set s2 i ⦃ r => True ⦄ := by
  unfold valueset.any_ends_with_loop
  h5i_total (fun i => i) set.length

@[step] theorem valueset_any_ends_with_total
  (set : Slice (alloc.vec.Vec Std.U8)) (s2 : Slice Std.U8)  :
  valueset.any_ends_with set s2 ⦃ r => True ⦄ := by
  unfold valueset.any_ends_with
  total_steps

@[step] theorem valueset_vs_endswith_total
  (vs : ValueSet) (pv : PartialValue)  :
  valueset.vs_endswith vs pv ⦃ r => True ⦄ := by
  unfold valueset.vs_endswith
  total_steps

@[step] theorem entry_impl_attribute_endswith_total
  (e : Entry) (attr : Slice Std.U8) (subvalue : PartialValue)  :
  entry_impl.attribute_endswith e attr subvalue ⦃ r => True ⦄ := by
  unfold entry_impl.attribute_endswith
  total_steps

@[step] theorem valueset_any_starts_with_lower_loop_total
  (set : Slice (alloc.vec.Vec Std.U8)) (s2_lower : Slice Std.U8)
  (i : Std.Usize) (hi : i.val ≤ set.length) :
  valueset.any_starts_with_lower_loop set s2_lower i ⦃ r => True ⦄ := by
  unfold valueset.any_starts_with_lower_loop
  h5i_total (fun i => i) set.length

@[step] theorem valueset_any_starts_with_lower_total
  (set : Slice (alloc.vec.Vec Std.U8)) (s2_lower : Slice Std.U8)  :
  valueset.any_starts_with_lower set s2_lower ⦃ r => True ⦄ := by
  unfold valueset.any_starts_with_lower
  total_steps

@[step] theorem valueset_any_starts_with_loop_total
  (set : Slice (alloc.vec.Vec Std.U8)) (s2 : Slice Std.U8) (i : Std.Usize) (hi : i.val ≤ set.length) :
  valueset.any_starts_with_loop set s2 i ⦃ r => True ⦄ := by
  unfold valueset.any_starts_with_loop
  h5i_total (fun i => i) set.length

@[step] theorem valueset_any_starts_with_total
  (set : Slice (alloc.vec.Vec Std.U8)) (s2 : Slice Std.U8)  :
  valueset.any_starts_with set s2 ⦃ r => True ⦄ := by
  unfold valueset.any_starts_with
  total_steps

@[step] theorem valueset_vs_startswith_total
  (vs : ValueSet) (pv : PartialValue)  :
  valueset.vs_startswith vs pv ⦃ r => True ⦄ := by
  unfold valueset.vs_startswith
  total_steps

@[step] theorem entry_impl_attribute_startswith_total
  (e : Entry) (attr : Slice Std.U8) (subvalue : PartialValue)  :
  entry_impl.attribute_startswith e attr subvalue ⦃ r => True ⦄ := by
  unfold entry_impl.attribute_startswith
  total_steps

@[step] theorem valueset_any_contains_lower_loop_total
  (set : Slice (alloc.vec.Vec Std.U8)) (s2_lower : Slice Std.U8)
  (i : Std.Usize) (hi : i.val ≤ set.length) :
  valueset.any_contains_lower_loop set s2_lower i ⦃ r => True ⦄ := by
  unfold valueset.any_contains_lower_loop
  h5i_total (fun i => i) set.length

@[step] theorem valueset_any_contains_lower_total
  (set : Slice (alloc.vec.Vec Std.U8)) (s2_lower : Slice Std.U8)  :
  valueset.any_contains_lower set s2_lower ⦃ r => True ⦄ := by
  unfold valueset.any_contains_lower
  total_steps

@[step] theorem valueset_any_contains_loop_total
  (set : Slice (alloc.vec.Vec Std.U8)) (s2 : Slice Std.U8) (i : Std.Usize) (hi : i.val ≤ set.length) :
  valueset.any_contains_loop set s2 i ⦃ r => True ⦄ := by
  unfold valueset.any_contains_loop
  h5i_total (fun i => i) set.length

@[step] theorem valueset_any_contains_total
  (set : Slice (alloc.vec.Vec Std.U8)) (s2 : Slice Std.U8)  :
  valueset.any_contains set s2 ⦃ r => True ⦄ := by
  unfold valueset.any_contains
  total_steps

@[step] theorem valueset_vs_substring_total
  (vs : ValueSet) (pv : PartialValue)  :
  valueset.vs_substring vs pv ⦃ r => True ⦄ := by
  unfold valueset.vs_substring
  total_steps

@[step] theorem entry_impl_attribute_substring_total
  (e : Entry) (attr : Slice Std.U8) (subvalue : PartialValue)  :
  entry_impl.attribute_substring e attr subvalue ⦃ r => True ⦄ := by
  unfold entry_impl.attribute_substring
  total_steps

@[step] theorem entry_impl_match_any_total
  (e : Entry) (l : alloc.vec.Vec FilterResolved) (i : Std.Usize) (hall : ∀ x ∈ l.val, entry_impl.entry_match_no_index_inner e x ⦃ _ => True ⦄) (hi : i.val ≤ l.val.length) :
  entry_impl.match_any e l i ⦃ r => True ⦄ := by
  h5i_measure_induction (l.val.length - i.val) with ih
  have hrec : ∀ (e : Entry) (l : alloc.vec.Vec FilterResolved) (i : Usize),
      (∀ x ∈ l.val, entry_impl.entry_match_no_index_inner e x ⦃ _ => True ⦄) →
      i.val ≤ l.val.length → l.val.length - i.val < k →
      entry_impl.match_any e l i ⦃ _ => True ⦄ := by
    intro e l i hall hi hlt
    exact ih _ hlt e l i hall hi rfl
  clear ih
  rw [entry_impl.match_any.eq_def]
  total_steps

@[step] theorem entry_impl_match_all_total
  (e : Entry) (l : alloc.vec.Vec FilterResolved) (i : Std.Usize) (hall : ∀ x ∈ l.val, entry_impl.entry_match_no_index_inner e x ⦃ _ => True ⦄) (hi : i.val ≤ l.val.length) :
  entry_impl.match_all e l i ⦃ r => True ⦄ := by
  h5i_measure_induction (l.val.length - i.val) with ih
  have hrec : ∀ (e : Entry) (l : alloc.vec.Vec FilterResolved) (i : Usize),
      (∀ x ∈ l.val, entry_impl.entry_match_no_index_inner e x ⦃ _ => True ⦄) →
      i.val ≤ l.val.length → l.val.length - i.val < k →
      entry_impl.match_all e l i ⦃ _ => True ⦄ := by
    intro e l i hall hi hlt
    exact ih _ hlt e l i hall hi rfl
  clear ih
  rw [entry_impl.match_all.eq_def]
  total_steps

@[step] theorem entry_match_inner_total (e : Entry) (filter : FilterResolved) :
    entry_impl.entry_match_no_index_inner e filter ⦃ _ => True ⦄ := by
  induction hn : sizeOf filter using Nat.strong_induction_on generalizing filter with
  | h n ih =>
    have hall : ∀ (l : alloc.vec.Vec FilterResolved), sizeOf l < n →
        ∀ x ∈ l.val, entry_impl.entry_match_no_index_inner e x ⦃ _ => True ⦄ := by
      intro l hl x hx
      exact ih (sizeOf x) (by have := vec_member_size l x hx; omega) x rfl
    have hrec : ∀ f : FilterResolved, sizeOf f < n →
        entry_impl.entry_match_no_index_inner e f ⦃ _ => True ⦄ := by
      intro f hf
      exact ih _ hf f rfl
    clear ih
    rw [entry_impl.entry_match_no_index_inner.eq_def]
    cases filter <;> total_steps
    all_goals (apply hall; omega)

@[step] theorem entry_impl_entry_match_no_index_total
  (e : Entry) (filter : FilterResolved)  :
  entry_impl.entry_match_no_index e filter ⦃ r => True ⦄ := by
  unfold entry_impl.entry_match_no_index
  total_steps

@[step] theorem search_acc_target_applies_total
  (target_condition : profiles.AccessControlTargetCondition) (entry : Entry)  :
  search_acc.target_applies target_condition entry ⦃ r => True ⦄ := by
  unfold search_acc.target_applies
  total_steps

@[step] theorem search_acc_receiver_applies_total
  (receiver_condition : profiles.AccessControlReceiverCondition)
  (ident_memberof : Option (alloc.vec.Vec Std.U128)) (ident_uuid : Std.U128)
  (entry : Entry)  :
  search_acc.receiver_applies receiver_condition ident_memberof ident_uuid entry ⦃ r => True ⦄ := by
  unfold search_acc.receiver_applies
  total_steps

@[step] theorem search_acc_acp_applies_total
  (receiver_condition : profiles.AccessControlReceiverCondition)
  (target_condition : profiles.AccessControlTargetCondition)
  (ident_memberof : Option (alloc.vec.Vec Std.U128)) (ident_uuid : Std.U128)
  (entry : Entry)  :
  search_acc.acp_applies receiver_condition target_condition ident_memberof ident_uuid entry ⦃ r => True ⦄ := by
  unfold search_acc.acp_applies
  total_steps

-- Sum of the storage contributed by a table, including a remaining suffix.
def cost {α : Type} (f : α → Nat) (xs : List α) : Nat := (xs.map f).sum

@[simp] theorem cost_nil {α : Type} (f : α → Nat) : cost f [] = 0 := rfl
@[simp] theorem cost_cons {α : Type} (f : α → Nat) (x : α) (xs : List α) :
    cost f (x :: xs) = f x + cost f xs := rfl
@[simp] theorem cost_append {α : Type} (f : α → Nat) (xs ys : List α) :
    cost f (xs ++ ys) = cost f xs + cost f ys := by
  simp [cost, List.map_append, List.sum_append]
theorem cost_drop_step {α : Type} (f : α → Nat) (xs : List α)
    (i : Nat) (hi : i < xs.length) :
    cost f (xs.drop i) = f xs[i] + cost f (xs.drop (i + 1)) := by
  rw [List.drop_eq_getElem_cons hi, cost_cons]

theorem cost_mem {α : Type} (f : α → Nat) (xs : List α) (x : α) (hx : x ∈ xs) :
    f x ≤ cost f xs := by
  induction xs with
  | nil => simp at hx
  | cons a xs ih =>
    simp only [List.mem_cons] at hx
    simp only [cost_cons]
    rcases hx with rfl | hx
    · omega
    · have := ih hx; omega

abbrev searchWeight (x : profiles.AccessControlSearch) := x.attrs.val.length
abbrev resolvedSearchWeight (x : profiles.AccessControlSearchResolved) := x.attrs.val.length
abbrev grantWeight (x : profiles.ModifyGrants) :=
  x.presattrs.val.length + x.remattrs.val.length +
  x.pres_classes.val.length + x.rem_classes.val.length
abbrev modifyWeight (x : profiles.AccessControlModify) :=
  x.presattrs.val.length + x.remattrs.val.length +
  x.pres_classes.val.length + x.rem_classes.val.length
abbrev resolvedModifyWeight (x : profiles.AccessControlModifyResolved) := grantWeight x.acp
abbrev syncWeight (x : SyncAgreement) := x.attrs.val.length

attribute [simp, step_pre_simps, step_post_simps, scalar_tac_simps]
  searchWeight resolvedSearchWeight modifyWeight resolvedModifyWeight grantWeight syncWeight

@[step] theorem access_search_related_acp_loop_total
  (ident : Identity) (attrs : Option (alloc.vec.Vec (alloc.vec.Vec Std.U8)))
  (search_state : alloc.vec.Vec profiles.AccessControlSearch)
  (ident_memberof : Option (alloc.vec.Vec Std.U128))
  (related_acp : alloc.vec.Vec profiles.AccessControlSearchResolved)
  (i : Std.Usize) (hi : i.val ≤ search_state.val.length)
    (hcount : related_acp.val.length + (search_state.val.length - i.val) ≤ Usize.max) :
  access.search_related_acp_loop ident attrs search_state ident_memberof related_acp i ⦃ r => cost resolvedSearchWeight r.val ≤ cost resolvedSearchWeight related_acp.val + cost searchWeight (search_state.val.drop i.val) ⦄ := by
  unfold access.search_related_acp_loop
  apply loop.spec_decr_nat (measure := fun x => search_state.val.length - (x.2.2).val)
    (inv := fun x => (x.2.2).val ≤ search_state.val.length ∧
      (x.2.1).val.length + (search_state.val.length - (x.2.2).val) ≤ related_acp.val.length + (search_state.val.length - i.val) ∧
      cost resolvedSearchWeight (x.2.1).val + cost searchWeight (search_state.val.drop (x.2.2).val) ≤ cost resolvedSearchWeight related_acp.val + cost searchWeight (search_state.val.drop i.val))
  · intro x hx
    rcases x with ⟨atrs, s, j⟩
    simp only [Prod.fst, Prod.snd] at hx ⊢
    rcases hx with ⟨hj, hcount', hcost'⟩
    by_cases hlt : j.val < search_state.val.length
    · have hcost := cost_drop_step searchWeight search_state.val j.val hlt
      h5i_unfold_body
      total_steps
    · h5i_unfold_body
      total_steps
  · simp only [Prod.fst, Prod.snd]
    exact ⟨hi, by omega, by omega⟩

@[step] theorem access_search_related_acp_total
  (ctl : AccessControlsInner) (ident : Identity)
  (attrs : Option (alloc.vec.Vec (alloc.vec.Vec Std.U8)))  :
  access.search_related_acp ctl ident attrs ⦃ r => cost resolvedSearchWeight r.val ≤ cost searchWeight ctl.acps_search.val ⦄ := by
  unfold access.search_related_acp
  total_steps

@[step] theorem access_modify_related_acp_loop_total
  (ident : Identity)
  (modify_state : alloc.vec.Vec profiles.AccessControlModify)
  (ident_memberof : Option (alloc.vec.Vec Std.U128))
  (related_acp : alloc.vec.Vec profiles.AccessControlModifyResolved)
  (i : Std.Usize) (hi : i.val ≤ modify_state.val.length)
    (hcount : related_acp.val.length + (modify_state.val.length - i.val) ≤ Usize.max) :
  access.modify_related_acp_loop ident modify_state ident_memberof related_acp i ⦃ r => cost resolvedModifyWeight r.val ≤ cost resolvedModifyWeight related_acp.val + cost modifyWeight (modify_state.val.drop i.val) ⦄ := by
  unfold access.modify_related_acp_loop
  apply loop.spec_decr_nat (measure := fun x => modify_state.val.length - (x.2).val)
    (inv := fun x => (x.2).val ≤ modify_state.val.length ∧
      (x.1).val.length + (modify_state.val.length - (x.2).val) ≤ related_acp.val.length + (modify_state.val.length - i.val) ∧
      cost resolvedModifyWeight (x.1).val + cost modifyWeight (modify_state.val.drop (x.2).val) ≤ cost resolvedModifyWeight related_acp.val + cost modifyWeight (modify_state.val.drop i.val))
  · intro x hx
    rcases x with ⟨s, j⟩
    simp only [Prod.fst, Prod.snd] at hx ⊢
    rcases hx with ⟨hj, hcount', hcost'⟩
    by_cases hlt : j.val < modify_state.val.length
    · have hcost := cost_drop_step modifyWeight modify_state.val j.val hlt
      h5i_unfold_body
      total_steps
    · h5i_unfold_body
      total_steps
  · simp only [Prod.fst, Prod.snd]
    exact ⟨hi, by omega, by omega⟩

@[step] theorem access_modify_related_acp_total
  (ctl : AccessControlsInner) (ident : Identity)  :
  access.modify_related_acp ctl ident ⦃ r => cost resolvedModifyWeight r.val ≤ cost modifyWeight ctl.acps_modify.val ⦄ := by
  unfold access.modify_related_acp
  total_steps

@[step] theorem access_delete_related_acp_loop_total
  (ident : Identity)
  (delete_state : alloc.vec.Vec profiles.AccessControlDelete)
  (ident_memberof : Option (alloc.vec.Vec Std.U128))
  (related_acp : alloc.vec.Vec profiles.AccessControlDeleteResolved)
  (i : Std.Usize) (hi : i.val ≤ delete_state.val.length) (hcap : related_acp.val.length + (delete_state.val.length - i.val) ≤ Usize.max)  :
  access.delete_related_acp_loop ident delete_state ident_memberof related_acp i ⦃ r => r.val.length ≤ related_acp.val.length + (delete_state.val.length - i.val) ⦄ := by
  unfold access.delete_related_acp_loop
  apply loop.spec_decr_nat (measure := fun x => delete_state.val.length - x.2.val)
    (inv := fun x => x.2.val ≤ delete_state.val.length ∧ x.1.val.length + (delete_state.val.length - x.2.val) ≤ related_acp.val.length + (delete_state.val.length - i.val))
  · rintro ⟨s, j⟩ ⟨hj, hs⟩
    h5i_unfold_body
    total_steps
  · exact ⟨hi, by simp⟩

@[step] theorem access_delete_related_acp_total
  (ctl : AccessControlsInner) (ident : Identity)  :
  access.delete_related_acp ctl ident ⦃ r => True ⦄ := by
  unfold access.delete_related_acp
  total_steps

def SrchBound (n : Nat) : AccessSrchResult → Prop
  | .Allow xs => xs.val.length ≤ n
  | _ => True

def ModBound (n : Nat) : AccessModResult → Prop
  | .Allow p r pc rc => p.val.length ≤ n ∧ r.val.length ≤ n ∧
      pc.val.length ≤ n ∧ rc.val.length ≤ n
  | .Constrain p r pc rc => p.val.length ≤ n ∧ r.val.length ≤ n ∧
      (∀ xs, pc = some xs → xs.val.length ≤ n) ∧
      (∀ xs, rc = some xs → xs.val.length ≤ n)
  | _ => True

attribute [simp, step_pre_simps, step_post_simps] SrchBound ModBound

macro "bounded_steps" : tactic => `(tactic| (
  total_steps
  all_goals (try simp_all [SrchBound, ModBound])
  all_goals h5i_steps
  all_goals (try simp_all [SrchBound, ModBound])
  all_goals (try scalar_tac)))

-- Summarize a conditional vector construction before continuing past its bind.
open Lean Elab Tactic Meta in
elab "join_vec_if" : tactic => withMainContext do
  let target ← instantiateMVars (← getMainTarget)
  let args := target.getAppArgs
  unless target.isAppOfArity ``Aeneas.Std.WP.spec 3 do
    throwError "expected a WP"
  let computation := args[1]!.consumeMData
  let ba := computation.getAppArgs
  let m ←
    if computation.isAppOfArity ``Bind.bind 6 then pure ba[4]!
    else if computation.isAppOfArity ``Aeneas.Std.bind 4 then pure ba[2]!
    else throwError "expected a bind"
  let m := m.consumeMData
  unless m.isAppOfArity ``ite 5 do throwError "expected a conditional"
  let mt ← inferType m
  let rt := mt.getAppArgs.back!
  unless rt.isAppOfArity ``alloc.vec.Vec 1 do throwError "expected a vector"
  let elem := rt.getAppArgs[0]!
  let counter ← IO.mkRef (0 : Nat)
  let baseline ← IO.mkRef (#[] : Array Expr)
  m.forEach fun e => do
    let bases ← baseline.get
    let e := e.consumeMData
    if e.isAppOfArity ``bset.insert 2 || e.isAppOfArity ``migration.ins 2 then
      counter.modify (· + 1)
      let acc := e.getAppArgs[0]!
      if acc.isFVar && !bases.contains acc then baseline.modify (·.push acc)
    if e.isAppOfArity ``Result.ok 2 then
      let v := e.getAppArgs[1]!
      if v.isFVar && !bases.contains v then
        let vt ← inferType v
        if ← isDefEq vt rt then baseline.modify (·.push v)
  let count ← counter.get
  let bases ← baseline.get
  let mut bound := mkNatLit count
  for base in bases do
    let value ← mkAppM ``alloc.vec.Vec.val #[base]
    let len ← mkAppM ``List.length #[value]
    bound ← mkAppM ``Nat.add #[len, bound]
  let bsyntax ← Term.exprToSyntax bound
  let esyntax ← Term.exprToSyntax elem
  evalTactic (← `(tactic|
    apply WP.spec_bind (Pₘ := fun (r : alloc.vec.Vec $esyntax) => r.val.length ≤ $bsyntax)))
  let gs ← getGoals
  unless gs.length == 2 do throwError "expected two bind obligations"
  setGoals [gs.head!]
  evalTactic (← `(tactic| total_steps))
  unless (← getGoals).isEmpty do throwError "conditional bound did not close"
  setGoals gs.tail!
  evalTactic (← `(tactic| intro joined joined_bound))

macro "literal_steps" : tactic => `(tactic| (
  have hmax := H5iAppLib.usize_max_ge
  repeat' (first
    | join_vec_if
    | step
    | split
    | (simp_all))
  all_goals (try simp_all)
  all_goals (try scalar_tac)))

@[step] theorem search_acc_search_oauth2_filter_entry_total
  (ident : Identity) (entry : Entry)  :
  search_acc.search_oauth2_filter_entry ident entry ⦃ r => SrchBound 6 r ⦄ := by
  unfold search_acc.search_oauth2_filter_entry
  bounded_steps

@[step] theorem search_acc_search_applications_filter_entry_total
  (ident : Identity) (entry : Entry)  :
  search_acc.search_applications_filter_entry ident entry ⦃ r => SrchBound 6 r ⦄ := by
  unfold search_acc.search_applications_filter_entry
  bounded_steps

@[step] theorem search_acc_search_sync_account_filter_entry_total
  (ident : Identity) (entry : Entry)  :
  search_acc.search_sync_account_filter_entry ident entry ⦃ r => SrchBound 6 r ⦄ := by
  unfold search_acc.search_sync_account_filter_entry
  bounded_steps

@[step] theorem search_acc_search_allowed_attrs_loop_total
  (related_acp : Slice profiles.AccessControlSearchResolved)
  (ident_memberof : Option (alloc.vec.Vec Std.U128)) (ident_uuid : Std.U128)
  (entry : Entry) (allowed_attrs : alloc.vec.Vec (alloc.vec.Vec Std.U8))
  (i : Std.Usize) (hi : i.val ≤ related_acp.length)
    (hcap : allowed_attrs.val.length + cost resolvedSearchWeight (related_acp.val.drop i.val) ≤ Usize.max) :
  search_acc.search_allowed_attrs_loop related_acp ident_memberof ident_uuid entry allowed_attrs i ⦃ r => r.val.length ≤ allowed_attrs.val.length + cost resolvedSearchWeight (related_acp.val.drop i.val) ⦄ := by
  unfold search_acc.search_allowed_attrs_loop
  apply loop.spec_decr_nat (measure := fun x => related_acp.length - x.2.val)
    (inv := fun x => x.2.val ≤ related_acp.length ∧
      x.1.val.length + cost resolvedSearchWeight (related_acp.val.drop x.2.val) ≤
      allowed_attrs.val.length + cost resolvedSearchWeight (related_acp.val.drop i.val))
  · rintro ⟨s, j⟩ ⟨hj, hs⟩
    by_cases hlt : j.val < related_acp.length
    · have hcost := cost_drop_step resolvedSearchWeight related_acp.val j.val hlt
      h5i_unfold_body
      total_steps
    · h5i_unfold_body
      total_steps
  · exact ⟨hi, by simp⟩

@[step] theorem search_acc_search_allowed_attrs_total
  (related_acp : Slice profiles.AccessControlSearchResolved)
  (ident_memberof : Option (alloc.vec.Vec Std.U128)) (ident_uuid : Std.U128)
  (entry : Entry) (hcap : cost resolvedSearchWeight related_acp.val ≤ Usize.max) :
  search_acc.search_allowed_attrs related_acp ident_memberof ident_uuid entry ⦃ r => r.val.length ≤ cost resolvedSearchWeight related_acp.val ⦄ := by
  unfold search_acc.search_allowed_attrs
  total_steps

@[step] theorem search_acc_search_filter_entry_total
  (ident : Identity) (related_acp : Slice profiles.AccessControlSearchResolved)
  (entry : Entry) (hcap : cost resolvedSearchWeight related_acp.val ≤ Usize.max) :
  search_acc.search_filter_entry ident related_acp entry ⦃ r => SrchBound (cost resolvedSearchWeight related_acp.val) r ⦄ := by
  unfold search_acc.search_filter_entry
  bounded_steps

theorem search_start_spec (asr : AccessSrchResult) (n : Nat) (hb : SrchBound n asr)
    (hcap : n ≤ Usize.max) :
    (match asr with
    | .Deny => ok (true, false, alloc.vec.Vec.new (alloc.vec.Vec U8))
    | .Grant => ok (false, true, alloc.vec.Vec.new (alloc.vec.Vec U8))
    | .Ignore => ok (false, false, alloc.vec.Vec.new (alloc.vec.Vec U8))
    | .Allow attr => do
        let allow ← bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) attr.deref
        ok (false, false, allow))
    ⦃ r => r.2.2.val.length ≤ n ⦄ := by
  cases asr <;> bounded_steps

theorem search_merge_spec (asr : AccessSrchResult) (n : Nat) (hb : SrchBound n asr)
    (denied grant : Bool) (allow : alloc.vec.Vec (alloc.vec.Vec U8))
    (hcap : allow.val.length + n ≤ Usize.max) :
    (match asr with
    | .Deny => ok (true, grant, allow)
    | .Grant => ok (denied, true, allow)
    | .Ignore => ok (denied, grant, allow)
    | .Allow attr => do
        let allow ← bset.extend allow attr.deref
        ok (denied, grant, allow))
    ⦃ r => r.2.2.val.length ≤ allow.val.length + n ⦄ := by
  cases asr <;> bounded_steps

@[step] theorem search_acc_apply_search_access_total
  (ident : Identity) (related_acp : Slice profiles.AccessControlSearchResolved)
  (entry : Entry) (hcap : cost resolvedSearchWeight related_acp.val + 18 ≤ Usize.max) :
  search_acc.apply_search_access ident related_acp entry ⦃ r => True ⦄ := by
  unfold search_acc.apply_search_access
  step as ⟨asr, hasr⟩
  apply WP.spec_bind (search_start_spec asr _ hasr (by omega))
  rintro ⟨denied, grant, allow⟩ hallow
  step as ⟨asr1, hasr1⟩
  apply WP.spec_bind (search_merge_spec asr1 6 hasr1 denied grant allow (by simp_all; omega))
  rintro ⟨denied1, grant1, allow1⟩ hallow1
  step as ⟨asr2, hasr2⟩
  apply WP.spec_bind (search_merge_spec asr2 6 hasr2 denied1 grant1 allow1 (by simp_all; omega))
  rintro ⟨denied2, grant2, allow2⟩ hallow2
  step as ⟨asr3, hasr3⟩
  apply WP.spec_bind (search_merge_spec asr3 6 hasr3 denied2 grant2 allow2 (by simp_all; omega))
  rintro ⟨denied3, grant3, allow3⟩ hallow3
  bounded_steps

@[step] theorem bset_intersection_loop_total
  (a : Slice (alloc.vec.Vec Std.U8)) (b : Slice (alloc.vec.Vec Std.U8))
  (out : alloc.vec.Vec (alloc.vec.Vec Std.U8)) (i : Std.Usize) (hi : i.val ≤ a.length) (hcap : out.val.length + (a.length - i.val) ≤ Usize.max)  :
  bset.intersection_loop a b out i ⦃ r => r.val.length ≤ out.val.length + (a.length - i.val) ⦄ := by
  unfold bset.intersection_loop
  apply loop.spec_decr_nat (measure := fun x => a.length - x.2.val)
    (inv := fun x => x.2.val ≤ a.length ∧ x.1.val.length + (a.length - x.2.val) ≤ out.val.length + (a.length - i.val))
  · rintro ⟨s, j⟩ ⟨hj, hs⟩
    h5i_unfold_body
    total_steps
  · exact ⟨hi, by simp⟩

@[step] theorem bset_intersection_total
  (a : Slice (alloc.vec.Vec Std.U8)) (b : Slice (alloc.vec.Vec Std.U8))  :
  bset.intersection a b ⦃ r => r.val.length ≤ a.length ⦄ := by
  unfold bset.intersection
  total_steps

@[step] theorem protected_protected_mod_rem_entry_classes_total
  (c : Slice Std.U8)  :
  protected.protected_mod_rem_entry_classes c ⦃ r => True ⦄ := by
  unfold protected.protected_mod_rem_entry_classes
  total_steps

@[step] theorem protected_protected_mod_pres_entry_classes_total
  (c : Slice Std.U8)  :
  protected.protected_mod_pres_entry_classes c ⦃ r => True ⦄ := by
  unfold protected.protected_mod_pres_entry_classes
  total_steps

@[step] theorem protected_protected_mod_entry_classes_total
  (c : Slice Std.U8)  :
  protected.protected_mod_entry_classes c ⦃ r => True ⦄ := by
  unfold protected.protected_mod_entry_classes
  total_steps

@[step] theorem protected_locked_entry_classes_total
  (c : Slice Std.U8)  :
  protected.locked_entry_classes c ⦃ r => True ⦄ := by
  unfold protected.locked_entry_classes
  total_steps

@[step] theorem protected_protected_entry_classes_total
  (c : Slice Std.U8)  :
  protected.protected_entry_classes c ⦃ r => True ⦄ := by
  unfold protected.protected_entry_classes
  total_steps

@[step] theorem protected_disjoint_protected_mod_entry_classes_loop_total
  (classes : Slice (alloc.vec.Vec Std.U8)) (i : Std.Usize) (hi : i.val ≤ classes.length) :
  protected.disjoint_protected_mod_entry_classes_loop classes i ⦃ r => True ⦄ := by
  unfold protected.disjoint_protected_mod_entry_classes_loop
  h5i_total (fun i => i) classes.length

@[step] theorem protected_disjoint_protected_mod_entry_classes_total
  (classes : Slice (alloc.vec.Vec Std.U8))  :
  protected.disjoint_protected_mod_entry_classes classes ⦃ r => True ⦄ := by
  unfold protected.disjoint_protected_mod_entry_classes
  total_steps

@[step] theorem protected_disjoint_locked_entry_classes_loop_total
  (classes : Slice (alloc.vec.Vec Std.U8)) (i : Std.Usize) (hi : i.val ≤ classes.length) :
  protected.disjoint_locked_entry_classes_loop classes i ⦃ r => True ⦄ := by
  unfold protected.disjoint_locked_entry_classes_loop
  h5i_total (fun i => i) classes.length

@[step] theorem protected_disjoint_locked_entry_classes_total
  (classes : Slice (alloc.vec.Vec Std.U8))  :
  protected.disjoint_locked_entry_classes classes ⦃ r => True ⦄ := by
  unfold protected.disjoint_locked_entry_classes
  total_steps

@[step] theorem protected_disjoint_protected_entry_classes_loop_total
  (classes : Slice (alloc.vec.Vec Std.U8)) (i : Std.Usize) (hi : i.val ≤ classes.length) :
  protected.disjoint_protected_entry_classes_loop classes i ⦃ r => True ⦄ := by
  unfold protected.disjoint_protected_entry_classes_loop
  h5i_total (fun i => i) classes.length

@[step] theorem protected_disjoint_protected_entry_classes_total
  (classes : Slice (alloc.vec.Vec Std.U8))  :
  protected.disjoint_protected_entry_classes classes ⦃ r => True ⦄ := by
  unfold protected.disjoint_protected_entry_classes
  total_steps

@[step] theorem delete_acc_delete_any_acp_loop_total
  (related_acp : Slice profiles.AccessControlDeleteResolved)
  (ident_memberof : Option (alloc.vec.Vec Std.U128)) (ident_uuid : Std.U128)
  (entry : Entry) (i : Std.Usize) (hi : i.val ≤ related_acp.length) :
  delete_acc.delete_any_acp_loop related_acp ident_memberof ident_uuid entry i ⦃ r => True ⦄ := by
  unfold delete_acc.delete_any_acp_loop
  h5i_total (fun i => i) related_acp.length

@[step] theorem delete_acc_delete_any_acp_total
  (related_acp : Slice profiles.AccessControlDeleteResolved)
  (ident_memberof : Option (alloc.vec.Vec Std.U128)) (ident_uuid : Std.U128)
  (entry : Entry)  :
  delete_acc.delete_any_acp related_acp ident_memberof ident_uuid entry ⦃ r => True ⦄ := by
  unfold delete_acc.delete_any_acp
  total_steps

@[step] theorem protected_remove_protected_mod_rem_loop_total
  (set : Slice (alloc.vec.Vec Std.U8))
  (out : alloc.vec.Vec (alloc.vec.Vec Std.U8)) (i : Std.Usize) (hi : i.val ≤ set.length) (hcap : out.val.length + (set.length - i.val) ≤ Usize.max)  :
  protected.remove_protected_mod_rem_loop set out i ⦃ r => r.val.length ≤ out.val.length + (set.length - i.val) ⦄ := by
  unfold protected.remove_protected_mod_rem_loop
  apply loop.spec_decr_nat (measure := fun x => set.length - x.2.val)
    (inv := fun x => x.2.val ≤ set.length ∧ x.1.val.length + (set.length - x.2.val) ≤ out.val.length + (set.length - i.val))
  · rintro ⟨s, j⟩ ⟨hj, hs⟩
    h5i_unfold_body
    total_steps
  · exact ⟨hi, by simp⟩

@[step] theorem protected_remove_protected_mod_rem_total
  (set : Slice (alloc.vec.Vec Std.U8))  :
  protected.remove_protected_mod_rem set ⦃ r => r.val.length ≤ set.length ⦄ := by
  unfold protected.remove_protected_mod_rem
  total_steps

@[step] theorem protected_remove_protected_mod_pres_loop_total
  (set : Slice (alloc.vec.Vec Std.U8))
  (out : alloc.vec.Vec (alloc.vec.Vec Std.U8)) (i : Std.Usize) (hi : i.val ≤ set.length) (hcap : out.val.length + (set.length - i.val) ≤ Usize.max)  :
  protected.remove_protected_mod_pres_loop set out i ⦃ r => r.val.length ≤ out.val.length + (set.length - i.val) ⦄ := by
  unfold protected.remove_protected_mod_pres_loop
  apply loop.spec_decr_nat (measure := fun x => set.length - x.2.val)
    (inv := fun x => x.2.val ≤ set.length ∧ x.1.val.length + (set.length - x.2.val) ≤ out.val.length + (set.length - i.val))
  · rintro ⟨s, j⟩ ⟨hj, hs⟩
    h5i_unfold_body
    total_steps
  · exact ⟨hi, by simp⟩

@[step] theorem protected_remove_protected_mod_pres_total
  (set : Slice (alloc.vec.Vec Std.U8))  :
  protected.remove_protected_mod_pres set ⦃ r => r.val.length ≤ set.length ⦄ := by
  unfold protected.remove_protected_mod_pres
  total_steps

@[step] theorem delete_acc_protected_filter_entry_total
  (ident : Identity) (entry : Entry)  :
  delete_acc.protected_filter_entry ident entry ⦃ r => True ⦄ := by
  unfold delete_acc.protected_filter_entry
  total_steps

@[step] theorem delete_acc_delete_filter_entry_total
  (ident : Identity) (related_acp : Slice profiles.AccessControlDeleteResolved)
  (entry : Entry)  :
  delete_acc.delete_filter_entry ident related_acp entry ⦃ r => True ⦄ := by
  unfold delete_acc.delete_filter_entry
  total_steps

@[step] theorem delete_acc_apply_delete_access_total
  (ident : Identity) (related_acp : Slice profiles.AccessControlDeleteResolved)
  (entry : Entry)  :
  delete_acc.apply_delete_access ident related_acp entry ⦃ r => True ⦄ := by
  unfold delete_acc.apply_delete_access
  total_steps

@[step] theorem modify_acc_modify_ident_test_total
  (ident : Identity)  :
  modify_acc.modify_ident_test ident ⦃ r => True ⦄ := by
  unfold modify_acc.modify_ident_test
  total_steps

@[step] theorem modify_acc_class_set_contains_total
  (entry : Entry) (pv : PartialValue)  :
  modify_acc.class_set_contains entry pv ⦃ r => True ⦄ := by
  unfold modify_acc.class_set_contains
  total_steps

@[step] theorem modify_acc_sync_agreement_get_loop_total
  (sync_agreements : Slice SyncAgreement) (sync_uuid : Std.U128)
  (i : Std.Usize) (hi : i.val ≤ sync_agreements.length) :
  modify_acc.sync_agreement_get_loop sync_agreements sync_uuid i ⦃ r => match r with | some xs => xs.val.length ≤ cost syncWeight sync_agreements.val | none => True ⦄ := by
  unfold modify_acc.sync_agreement_get_loop
  apply loop.spec_decr_nat (measure := fun j => sync_agreements.length - j.val)
    (inv := fun j => j.val ≤ sync_agreements.length)
  · intro j hj
    by_cases hlt : j.val < sync_agreements.length
    · have hb := cost_mem syncWeight sync_agreements.val sync_agreements.val[j.val]
          (List.getElem_mem hlt)
      h5i_unfold_body
      total_steps
    · h5i_unfold_body
      total_steps
  · exact hi

@[step] theorem modify_acc_sync_agreement_get_total
  (sync_agreements : Slice SyncAgreement) (sync_uuid : Std.U128)  :
  modify_acc.sync_agreement_get sync_agreements sync_uuid ⦃ r => match r with | some xs => xs.val.length ≤ cost syncWeight sync_agreements.val | none => True ⦄ := by
  unfold modify_acc.sync_agreement_get
  total_steps

@[step] theorem modify_acc_extend_sync_yield_authority_total
  (set : alloc.vec.Vec (alloc.vec.Vec Std.U8))
  (sync_agreements : Slice SyncAgreement) (sync_uuid : Std.U128) (hcap : set.val.length + cost syncWeight sync_agreements.val ≤ Usize.max) :
  modify_acc.extend_sync_yield_authority set sync_agreements sync_uuid ⦃ r => r.val.length ≤ set.val.length + cost syncWeight sync_agreements.val ⦄ := by
  unfold modify_acc.extend_sync_yield_authority
  total_steps

@[step] theorem modify_acc_modify_sync_constrain_total
  (ident : Identity) (entry : Entry) (sync_agreements : Slice SyncAgreement) (hcap : cost syncWeight sync_agreements.val + 4 ≤ Usize.max) :
  modify_acc.modify_sync_constrain ident entry sync_agreements ⦃ r => ModBound (cost syncWeight sync_agreements.val + 4) r ⦄ := by
  unfold modify_acc.modify_sync_constrain
  bounded_steps

@[step] theorem modify_acc_push_if_total
  (scoped_acp : alloc.vec.Vec profiles.ModifyGrants) (ok1 : Bool)
  (g : profiles.ModifyGrants) (hcap : scoped_acp.val.length < Usize.max) :
  modify_acc.push_if scoped_acp ok1 g ⦃ r => r.val.length ≤ scoped_acp.val.length + 1 ∧ cost grantWeight r.val ≤ cost grantWeight scoped_acp.val + grantWeight g ⦄ := by
  unfold modify_acc.push_if
  total_steps

@[step] theorem modify_acc_modify_scoped_acp_loop_total
  (related_acp : Slice profiles.AccessControlModifyResolved)
  (ident_memberof : Option (alloc.vec.Vec Std.U128)) (ident_uuid : Std.U128)
  (entry : Entry) (scoped_acp : alloc.vec.Vec profiles.ModifyGrants)
  (i : Std.Usize) (hi : i.val ≤ related_acp.length)
    (hcount : scoped_acp.val.length + (related_acp.length - i.val) ≤ Usize.max) :
  modify_acc.modify_scoped_acp_loop related_acp ident_memberof ident_uuid entry scoped_acp i ⦃ r => cost grantWeight r.val ≤ cost grantWeight scoped_acp.val + cost resolvedModifyWeight (related_acp.val.drop i.val) ⦄ := by
  unfold modify_acc.modify_scoped_acp_loop
  apply loop.spec_decr_nat (measure := fun x => related_acp.length - x.2.val)
    (inv := fun x => x.2.val ≤ related_acp.length ∧
      x.1.val.length + (related_acp.length - x.2.val) ≤ scoped_acp.val.length + (related_acp.length - i.val) ∧
      cost grantWeight x.1.val + cost resolvedModifyWeight (related_acp.val.drop x.2.val) ≤
      cost grantWeight scoped_acp.val + cost resolvedModifyWeight (related_acp.val.drop i.val))
  · rintro ⟨s, j⟩ ⟨hj, hn, hs⟩
    by_cases hlt : j.val < related_acp.length
    · have hcost := cost_drop_step resolvedModifyWeight related_acp.val j.val hlt
      h5i_unfold_body
      total_steps
    · h5i_unfold_body
      total_steps
  · exact ⟨hi, by simp, by simp⟩

@[step] theorem modify_acc_modify_scoped_acp_total
  (related_acp : Slice profiles.AccessControlModifyResolved)
  (ident_memberof : Option (alloc.vec.Vec Std.U128)) (ident_uuid : Std.U128)
  (entry : Entry)  :
  modify_acc.modify_scoped_acp related_acp ident_memberof ident_uuid entry ⦃ r => cost grantWeight r.val ≤ cost resolvedModifyWeight related_acp.val ⦄ := by
  unfold modify_acc.modify_scoped_acp
  total_steps

@[step] theorem modify_acc_modify_pres_test_loop_total
  (scoped_acp : Slice profiles.ModifyGrants)
  (pres_attr : alloc.vec.Vec (alloc.vec.Vec Std.U8))
  (rem_attr : alloc.vec.Vec (alloc.vec.Vec Std.U8))
  (pres_class : alloc.vec.Vec (alloc.vec.Vec Std.U8))
  (rem_class : alloc.vec.Vec (alloc.vec.Vec Std.U8)) (i : Std.Usize) (hi : i.val ≤ scoped_acp.length)
    (hcap : pres_attr.val.length + rem_attr.val.length + pres_class.val.length + rem_class.val.length + cost grantWeight (scoped_acp.val.drop i.val) ≤ Usize.max) :
  modify_acc.modify_pres_test_loop scoped_acp pres_attr rem_attr pres_class rem_class i ⦃ r => r.1.val.length + r.2.1.val.length + r.2.2.1.val.length + r.2.2.2.val.length ≤
    pres_attr.val.length + rem_attr.val.length + pres_class.val.length + rem_class.val.length + cost grantWeight (scoped_acp.val.drop i.val) ⦄ := by
  unfold modify_acc.modify_pres_test_loop
  apply loop.spec_decr_nat (measure := fun x => scoped_acp.length - x.2.2.2.2.val)
    (inv := fun x => x.2.2.2.2.val ≤ scoped_acp.length ∧
      x.1.val.length + x.2.1.val.length + x.2.2.1.val.length + x.2.2.2.1.val.length + cost grantWeight (scoped_acp.val.drop x.2.2.2.2.val) ≤
      pres_attr.val.length + rem_attr.val.length + pres_class.val.length + rem_class.val.length + cost grantWeight (scoped_acp.val.drop i.val))
  · rintro ⟨p, r, pc, rc, j⟩ ⟨hj, hs⟩
    by_cases hlt : j.val < scoped_acp.length
    · have hcost := cost_drop_step grantWeight scoped_acp.val j.val hlt
      h5i_unfold_body
      total_steps
    · h5i_unfold_body
      total_steps
  · exact ⟨hi, by simp⟩

@[step] theorem modify_acc_modify_pres_test_total
  (scoped_acp : Slice profiles.ModifyGrants) (hcap : cost grantWeight scoped_acp.val ≤ Usize.max) :
  modify_acc.modify_pres_test scoped_acp ⦃ r => ModBound (cost grantWeight scoped_acp.val) r ⦄ := by
  unfold modify_acc.modify_pres_test
  bounded_steps

@[step] theorem migration_ins_total
  (set : alloc.vec.Vec (alloc.vec.Vec Std.U8)) (a : Slice Std.U8) (hcap : set.val.length < Usize.max) :
  migration.ins set a ⦃ r => r.val.length ≤ set.val.length + 1 ⦄ := by
  unfold migration.ins
  total_steps

@[step] theorem migration_migration_entry_attrs_total
  (classes : Slice (alloc.vec.Vec Std.U8))  :
  migration.migration_entry_attrs classes ⦃ r => r.1.val.length ≤ 73 ∧ r.2.val.length ≤ 73 ⦄ := by
  unfold migration.migration_entry_attrs
  literal_steps

@[step] theorem modify_acc_modify_migration_attrs_total
  (ident : Identity) (entry : Entry)  :
  modify_acc.modify_migration_attrs ident entry ⦃ r => ModBound 73 r ⦄ := by
  unfold modify_acc.modify_migration_attrs
  bounded_steps

@[step] theorem modify_acc_modify_protected_entry_attrs_total
  (classes : Slice (alloc.vec.Vec Std.U8))  :
  modify_acc.modify_protected_entry_attrs classes ⦃ r => ModBound 40 r ⦄ := by
  unfold modify_acc.modify_protected_entry_attrs
  literal_steps

@[step] theorem modify_acc_modify_protected_attrs_total
  (ident : Identity) (entry : Entry)  :
  modify_acc.modify_protected_attrs ident entry ⦃ r => ModBound 40 r ⦄ := by
  unfold modify_acc.modify_protected_attrs
  bounded_steps

abbrev Attrs := alloc.vec.Vec (alloc.vec.Vec U8)

def FourBound (n : Nat) (r : Bool × Attrs × Attrs × Attrs × Attrs) : Prop :=
  r.2.1.val.length ≤ n ∧ r.2.2.1.val.length ≤ n ∧
  r.2.2.2.1.val.length ≤ n ∧ r.2.2.2.2.val.length ≤ n

attribute [simp, step_pre_simps, step_post_simps] FourBound

theorem modify_start_spec (amr : AccessModResult) (n : Nat) (hb : ModBound n amr)
    (denied : Bool) (hcap : n ≤ Usize.max) :
    (match amr with
    | .Deny => ok (true, alloc.vec.Vec.new (alloc.vec.Vec U8),
        alloc.vec.Vec.new (alloc.vec.Vec U8), alloc.vec.Vec.new (alloc.vec.Vec U8),
        alloc.vec.Vec.new (alloc.vec.Vec U8))
    | .Ignore | .Constrain _ _ _ _ => ok (denied, alloc.vec.Vec.new (alloc.vec.Vec U8),
        alloc.vec.Vec.new (alloc.vec.Vec U8), alloc.vec.Vec.new (alloc.vec.Vec U8),
        alloc.vec.Vec.new (alloc.vec.Vec U8))
    | .Allow p r pc rc => do
        let p ← bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) p.deref
        let r ← bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) r.deref
        let pc ← bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) pc.deref
        let rc ← bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) rc.deref
        ok (denied, p, r, pc, rc))
    ⦃ r => FourBound n r ⦄ := by
  cases amr <;> bounded_steps

theorem modify_protected_spec (amr : AccessModResult) (n : Nat) (hb : ModBound n amr)
    (denied : Bool) (hcap : n ≤ Usize.max) :
    (match amr with
    | .Deny => ok (true, alloc.vec.Vec.new (alloc.vec.Vec U8),
        alloc.vec.Vec.new (alloc.vec.Vec U8), alloc.vec.Vec.new (alloc.vec.Vec U8),
        alloc.vec.Vec.new (alloc.vec.Vec U8))
    | .Ignore | .Allow _ _ _ _ => ok (denied, alloc.vec.Vec.new (alloc.vec.Vec U8),
        alloc.vec.Vec.new (alloc.vec.Vec U8), alloc.vec.Vec.new (alloc.vec.Vec U8),
        alloc.vec.Vec.new (alloc.vec.Vec U8))
    | .Constrain p r pc rc => do
        let r ← bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) r.deref
        let p ← bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) p.deref
        let pc ← match pc with
          | none => ok (alloc.vec.Vec.new (alloc.vec.Vec U8))
          | some pc => bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) pc.deref
        let rc ← match rc with
          | none => ok (alloc.vec.Vec.new (alloc.vec.Vec U8))
          | some rc => bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) rc.deref
        ok (denied, p, r, pc, rc))
    ⦃ r => FourBound n r ⦄ := by
  cases amr <;> bounded_steps

theorem modify_sync_spec (amr : AccessModResult) (n : Nat) (hb : ModBound n amr)
    (p r : Attrs)
    (hcapP : p.val.length + n ≤ Usize.max)
    (hcapR : r.val.length + n ≤ Usize.max) :
    (match amr with
    | .Deny => ok (true, p, r)
    | .Ignore | .Allow _ _ _ _ => ok (false, p, r)
    | .Constrain pa ra _ _ => do
        let r ← bset.extend r ra.deref
        let p ← bset.extend p pa.deref
        ok (false, p, r))
    ⦃ x => x.2.1.val.length ≤ p.val.length + n ∧
      x.2.2.val.length ≤ r.val.length + n ⦄ := by
  cases amr <;> bounded_steps

theorem modify_allow_spec (amr : AccessModResult) (n : Nat) (hb : ModBound n amr)
    (denied : Bool) (p r pc rc : Attrs)
    (hp : p.val.length + n ≤ Usize.max) (hr : r.val.length + n ≤ Usize.max)
    (hpc : pc.val.length + n ≤ Usize.max) (hrc : rc.val.length + n ≤ Usize.max) :
    (match amr with
    | .Deny => ok (true, p, r, pc, rc)
    | .Ignore | .Constrain _ _ _ _ => ok (denied, p, r, pc, rc)
    | .Allow pa ra pca rca => do
        let p ← bset.extend p pa.deref
        let r ← bset.extend r ra.deref
        let pc ← bset.extend pc pca.deref
        let rc ← bset.extend rc rca.deref
        ok (denied, p, r, pc, rc))
    ⦃ x => x.2.1.val.length ≤ p.val.length + n ∧
      x.2.2.1.val.length ≤ r.val.length + n ∧
      x.2.2.2.1.val.length ≤ pc.val.length + n ∧
      x.2.2.2.2.val.length ≤ rc.val.length + n ⦄ := by
  cases amr <;> bounded_steps

@[step] theorem modify_acc_apply_modify_access_total
  (ident : Identity) (related_acp : Slice profiles.AccessControlModifyResolved)
  (sync_agreements : Slice SyncAgreement) (entry : Entry) (hcap : cost resolvedModifyWeight related_acp.val + cost syncWeight sync_agreements.val + 73 < Usize.max) :
  modify_acc.apply_modify_access ident related_acp sync_agreements entry ⦃ r => True ⦄ := by
  unfold modify_acc.apply_modify_access
  step
  step
  step as ⟨abr⟩
  apply WP.spec_bind (Pₘ := fun _ => True)
  · cases abr <;> simp
  rintro ⟨denied, grant⟩ _
  step as ⟨amr, hamr⟩
  apply WP.spec_bind (modify_start_spec amr 73 hamr denied (by omega))
  rintro ⟨denied1, ap, ar, apc, arc⟩ hallow
  simp only [FourBound, Prod.fst, Prod.snd] at hallow
  step as ⟨amr1, hamr1⟩
  apply WP.spec_bind (modify_protected_spec amr1 40 hamr1 denied1 (by omega))
  rintro ⟨denied2, cp, cr, cpc, crc⟩ hconstrain
  simp only [FourBound, Prod.fst, Prod.snd] at hconstrain
  apply WP.spec_bind (Pₘ := fun x : Bool × Attrs × Attrs × Attrs × Attrs × Attrs × Attrs =>
    x.2.1.val.length ≤ cost syncWeight sync_agreements.val + 44 ∧
    x.2.2.2.1.val.length ≤ cost syncWeight sync_agreements.val + 44 ∧
    x.2.2.1.val.length ≤ cost resolvedModifyWeight related_acp.val + 73 ∧
    x.2.2.2.2.1.val.length ≤ cost resolvedModifyWeight related_acp.val + 73 ∧
    x.2.2.2.2.2.1.val.length ≤ cost resolvedModifyWeight related_acp.val + 73 ∧
    x.2.2.2.2.2.2.val.length ≤ cost resolvedModifyWeight related_acp.val + 73)
  · by_cases hg : grant = true
    · simp only [hg, if_true]
      simp only [WP.spec_ok, Prod.fst, Prod.snd]
      omega
    · simp only [hg, if_false]
      by_cases hd : denied2 = true
      · simp only [hd, if_true]
        simp only [WP.spec_ok, Prod.fst, Prod.snd]
        omega
      · simp only [hd, if_false]
        step as ⟨amr2, hamr2⟩
        apply WP.spec_bind (modify_sync_spec amr2 _ hamr2 cp cr (by omega) (by omega))
        rintro ⟨denied4, cp2, cr2⟩ hsync
        simp only [Prod.fst, Prod.snd] at hsync
        step as ⟨scoped, hscoped⟩
        step as ⟨amr3, hamr3⟩
        apply WP.spec_bind (modify_allow_spec amr3 _ hamr3 denied4 ap ar apc arc
          (by omega) (by omega) (by omega) (by omega))
        rintro ⟨b, p, r, pc, rc⟩ hallowed
        simp only [Prod.fst, Prod.snd] at hallowed
        simp only [WP.spec_ok, Prod.fst, Prod.snd]
        omega
  · rintro ⟨denied3, cp1, ap1, cr1, ar1, apc1, arc1⟩ hbounds
    bounded_steps

@[step] theorem access_entry_effective_permission_check_total
  (ident : Identity) (entry : Entry)
  (search_related_acp : Slice profiles.AccessControlSearchResolved)
  (modify_related_acp : Slice profiles.AccessControlModifyResolved)
  (delete_related_acp : Slice profiles.AccessControlDeleteResolved)
  (sync_agmts : Slice SyncAgreement) (hcap : cost resolvedSearchWeight search_related_acp.val + cost resolvedModifyWeight modify_related_acp.val + cost syncWeight sync_agmts.val + 73 < Usize.max) :
  access.entry_effective_permission_check ident entry search_related_acp modify_related_acp delete_related_acp sync_agmts ⦃ r => True ⦄ := by
  unfold access.entry_effective_permission_check
  total_steps

@[step] theorem access_effective_permission_check_loop_total
  (ident : Identity) (entries : Slice Entry)
  (search_related_acp : alloc.vec.Vec profiles.AccessControlSearchResolved)
  (modify_related_acp : alloc.vec.Vec profiles.AccessControlModifyResolved)
  (delete_related_acp : alloc.vec.Vec profiles.AccessControlDeleteResolved)
  (sync_agmts : alloc.vec.Vec SyncAgreement)
  (effective_permissions : alloc.vec.Vec AccessEffectivePermission)
  (i : Std.Usize) (hi : i.val ≤ entries.length) (hcap : effective_permissions.val.length + (entries.length - i.val) ≤ Usize.max) (hpermissions : cost resolvedSearchWeight search_related_acp.val + cost resolvedModifyWeight modify_related_acp.val + cost syncWeight sync_agmts.val + 73 < Usize.max) :
  access.effective_permission_check_loop ident entries search_related_acp modify_related_acp delete_related_acp sync_agmts effective_permissions i ⦃ r => r.val.length ≤ effective_permissions.val.length + (entries.length - i.val) ⦄ := by
  unfold access.effective_permission_check_loop
  apply loop.spec_decr_nat (measure := fun x => entries.length - x.2.val)
    (inv := fun x => x.2.val ≤ entries.length ∧ x.1.val.length + (entries.length - x.2.val) ≤ effective_permissions.val.length + (entries.length - i.val))
  · rintro ⟨s, j⟩ ⟨hj, hs⟩
    h5i_unfold_body
    total_steps
  · exact ⟨hi, by simp⟩

theorem effective_permission_check_total (ctl : AccessControlsInner) (ident : Identity)
    (attrs : Option (alloc.vec.Vec (alloc.vec.Vec U8))) (es : Slice Entry)
    (hcap : (ctl.acps_search.val.map (·.attrs.length)).sum +
      (ctl.acps_modify.val.map (fun m => m.presattrs.length + m.remattrs.length +
        m.pres_classes.length + m.rem_classes.length)).sum +
      (ctl.sync_agreements.val.map (·.attrs.length)).sum + 73 < Usize.max) :
    ∃ y, access.effective_permission_check ctl ident attrs es = ok y := by
  apply ok_of (P := fun _ => True)
  change cost searchWeight ctl.acps_search.val + cost modifyWeight ctl.acps_modify.val +
    cost syncWeight ctl.sync_agreements.val + 73 < Usize.max at hcap
  unfold access.effective_permission_check
  total_steps

end kanidm_kernel.Solution
