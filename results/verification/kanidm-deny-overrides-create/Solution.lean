import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit

namespace kanidm_kernel.Solution

-- A deny does not short-circuit the extracted evaluator. These specifications
-- establish that the lookups, set checks, and filter operations it still runs succeed.
@[step] theorem bytes_eq_total (a b : Slice U8) :
    bset.bytes_eq a b ⦃ _ => True ⦄ := by
  unfold bset.bytes_eq
  dsimp only
  split
  · simp
  · unfold bset.bytes_eq_loop
    h5i_total (fun i => i) a.val.length

@[step] theorem get_ava_total (e : Entry) (a : Slice U8) :
    entry_impl.get_ava_set e a ⦃ _ => True ⦄ := by
  unfold entry_impl.get_ava_set entry_impl.get_ava_set_loop
  h5i_total (fun i => i) e.attrs.val.length

@[step] theorem iutf8_total (e : Entry) (a : Slice U8) :
    entry_impl.get_ava_as_iutf8 e a ⦃ _ => True ⦄ := by
  unfold entry_impl.get_ava_as_iutf8
  step*
  cases vs <;> simp [valueset.as_iutf8_set]

@[step] theorem contains_total (a : Slice (alloc.vec.Vec U8)) (b : Slice U8) :
    bset.contains a b ⦃ _ => True ⦄ := by
  unfold bset.contains bset.contains_loop
  h5i_total (fun i => i) a.val.length

@[step] theorem subset_total (a b : Slice (alloc.vec.Vec U8)) :
    bset.is_subset a b ⦃ _ => True ⦄ := by
  unfold bset.is_subset bset.is_subset_loop
  h5i_total (fun i => i) a.val.length

@[step] theorem contains_uuid_total (a : Slice U128) (u : U128) :
    bset.contains_uuid a u ⦃ _ => True ⦄ := by
  unfold bset.contains_uuid bset.contains_uuid_loop
  h5i_total (fun i => i) a.val.length

@[step] theorem contains_u32_total (a : Slice U32) (u : U32) :
    valueset.contains_u32 a u ⦃ _ => True ⦄ := by
  unfold valueset.contains_u32 valueset.contains_u32_loop
  h5i_total (fun i => i) a.val.length

@[step] theorem less_uuid_total (a : Slice U128) (u : U128) :
    valueset.any_less_uuid a u ⦃ _ => True ⦄ := by
  unfold valueset.any_less_uuid valueset.any_less_uuid_loop
  h5i_total (fun i => i) a.val.length

@[step] theorem less_u32_total (a : Slice U32) (u : U32) :
    valueset.any_less_u32 a u ⦃ _ => True ⦄ := by
  unfold valueset.any_less_u32 valueset.any_less_u32_loop
  h5i_total (fun i => i) a.val.length

@[step] theorem lowercase_total (s : Slice U8) :
    valueset.to_lowercase s ⦃ _ => True ⦄ := by
  unfold valueset.to_lowercase valueset.to_lowercase_loop
  apply loop_idx_spec _ (fun x => x.2) s.val.length
    (fun x => x.1.val.length ≤ x.2.val) _ ?_ _ (by simp) (by simp)
  rintro ⟨out, i⟩ hout hi
  unfold valueset.to_lowercase_loop.body
  h5i_steps <;> simp_all <;> scalar_tac

@[step] theorem starts_at_total (hay needle : Slice U8) (offset : Usize)
    (h : offset.val + needle.val.length ≤ hay.val.length) :
    valueset.starts_at hay offset needle ⦃ _ => True ⦄ := by
  unfold valueset.starts_at valueset.starts_at_loop
  h5i_total (fun i => i) needle.val.length

theorem starts_at_empty (hay needle : Slice U8) (offset : Usize)
    (h : needle.val.length = 0) : valueset.starts_at hay offset needle = ok true := by
  unfold valueset.starts_at valueset.starts_at_loop
  rw [loop]
  simp [valueset.starts_at_loop.body, Slice.len, h]

@[step] theorem starts_with_total (hay needle : Slice U8) :
    valueset.str_starts_with hay needle ⦃ _ => True ⦄ := by
  unfold valueset.str_starts_with
  h5i_steps <;> scalar_tac

@[step] theorem ends_with_total (hay needle : Slice U8) :
    valueset.str_ends_with hay needle ⦃ _ => True ⦄ := by
  unfold valueset.str_ends_with
  h5i_steps <;> scalar_tac

@[step] theorem str_contains_total (hay needle : Slice U8) :
    valueset.str_contains hay needle ⦃ _ => True ⦄ := by
  unfold valueset.str_contains
  dsimp only
  split
  · simp
  · by_cases hn : needle.val.length = 0
    · step*
      unfold valueset.str_contains_loop
      rw [loop]
      simp [valueset.str_contains_loop.body, starts_at_empty hay needle 0#usize hn]
    · step*
      unfold valueset.str_contains_loop
      apply loop_idx_spec _ (fun i => i) (last.val + 1) (fun _ => True) _ ?_
        _ trivial (by simp)
      intro i _ hi
      unfold valueset.str_contains_loop.body
      h5i_steps <;> scalar_tac

@[step] theorem any_contains_total (set : Slice (alloc.vec.Vec U8)) (s : Slice U8) :
    valueset.any_contains set s ⦃ _ => True ⦄ := by
  unfold valueset.any_contains valueset.any_contains_loop
  h5i_total (fun i => i) set.val.length

@[step] theorem any_contains_lower_total (set : Slice (alloc.vec.Vec U8)) (s : Slice U8) :
    valueset.any_contains_lower set s ⦃ _ => True ⦄ := by
  unfold valueset.any_contains_lower valueset.any_contains_lower_loop
  h5i_total (fun i => i) set.val.length

@[step] theorem any_starts_total (set : Slice (alloc.vec.Vec U8)) (s : Slice U8) :
    valueset.any_starts_with set s ⦃ _ => True ⦄ := by
  unfold valueset.any_starts_with valueset.any_starts_with_loop
  h5i_total (fun i => i) set.val.length

@[step] theorem any_starts_lower_total (set : Slice (alloc.vec.Vec U8)) (s : Slice U8) :
    valueset.any_starts_with_lower set s ⦃ _ => True ⦄ := by
  unfold valueset.any_starts_with_lower valueset.any_starts_with_lower_loop
  h5i_total (fun i => i) set.val.length

@[step] theorem any_ends_total (set : Slice (alloc.vec.Vec U8)) (s : Slice U8) :
    valueset.any_ends_with set s ⦃ _ => True ⦄ := by
  unfold valueset.any_ends_with valueset.any_ends_with_loop
  h5i_total (fun i => i) set.val.length

@[step] theorem any_ends_lower_total (set : Slice (alloc.vec.Vec U8)) (s : Slice U8) :
    valueset.any_ends_with_lower set s ⦃ _ => True ⦄ := by
  unfold valueset.any_ends_with_lower valueset.any_ends_with_lower_loop
  h5i_total (fun i => i) set.val.length

@[step] theorem vs_contains_total (vs : ValueSet) (pv : PartialValue) :
    valueset.vs_contains vs pv ⦃ _ => True ⦄ := by
  cases vs <;> cases pv <;> unfold valueset.vs_contains <;> step*

@[step] theorem vs_less_total (vs : ValueSet) (pv : PartialValue) :
    valueset.vs_lessthan vs pv ⦃ _ => True ⦄ := by
  cases vs <;> cases pv <;> unfold valueset.vs_lessthan <;> step*

@[step] theorem vs_substring_total (vs : ValueSet) (pv : PartialValue) :
    valueset.vs_substring vs pv ⦃ _ => True ⦄ := by
  cases vs <;> cases pv <;> unfold valueset.vs_substring <;> step*

@[step] theorem vs_starts_total (vs : ValueSet) (pv : PartialValue) :
    valueset.vs_startswith vs pv ⦃ _ => True ⦄ := by
  cases vs <;> cases pv <;> unfold valueset.vs_startswith <;> step*

@[step] theorem vs_ends_total (vs : ValueSet) (pv : PartialValue) :
    valueset.vs_endswith vs pv ⦃ _ => True ⦄ := by
  cases vs <;> cases pv <;> unfold valueset.vs_endswith <;> step*

@[step] theorem attr_eq_total (e : Entry) (attr : Slice U8) (pv : PartialValue) :
    entry_impl.attribute_equality e attr pv ⦃ _ => True ⦄ := by
  unfold entry_impl.attribute_equality
  step*

@[step] theorem attr_less_total (e : Entry) (attr : Slice U8) (pv : PartialValue) :
    entry_impl.attribute_lessthan e attr pv ⦃ _ => True ⦄ := by
  unfold entry_impl.attribute_lessthan
  step*

@[step] theorem attr_substring_total (e : Entry) (attr : Slice U8) (pv : PartialValue) :
    entry_impl.attribute_substring e attr pv ⦃ _ => True ⦄ := by
  unfold entry_impl.attribute_substring
  step*

@[step] theorem attr_starts_total (e : Entry) (attr : Slice U8) (pv : PartialValue) :
    entry_impl.attribute_startswith e attr pv ⦃ _ => True ⦄ := by
  unfold entry_impl.attribute_startswith
  step*

@[step] theorem attr_ends_total (e : Entry) (attr : Slice U8) (pv : PartialValue) :
    entry_impl.attribute_endswith e attr pv ⦃ _ => True ⦄ := by
  unfold entry_impl.attribute_endswith
  step*

@[step] theorem attr_pres_total (e : Entry) (attr : Slice U8) :
    entry_impl.attribute_pres e attr ⦃ _ => True ⦄ := by
  unfold entry_impl.attribute_pres
  step*

-- The list scans decrease the number of remaining entries. The nested recursor
-- then supplies their hypotheses for every child of a filter.
theorem match_any_total (e : Entry) (l : alloc.vec.Vec FilterResolved)
    (hs : ∀ f ∈ l.val, entry_impl.entry_match_no_index_inner e f ⦃ _ => True ⦄)
    (i : Usize) : entry_impl.match_any e l i ⦃ _ => True ⦄ := by
  induction hm : l.val.length - i.val using Nat.strong_induction_on generalizing i with
  | h n ih =>
    rw [entry_impl.match_any]
    split
    · simp
    · step
      step with hs fr (by rw [fr_post]; exact List.getElem_mem _)
      split
      · simp
      · step
        exact ih (l.val.length - i2.val) (by scalar_tac) i2 rfl

theorem match_all_total (e : Entry) (l : alloc.vec.Vec FilterResolved)
    (hs : ∀ f ∈ l.val, entry_impl.entry_match_no_index_inner e f ⦃ _ => True ⦄)
    (i : Usize) : entry_impl.match_all e l i ⦃ _ => True ⦄ := by
  induction hm : l.val.length - i.val using Nat.strong_induction_on generalizing i with
  | h n ih =>
    rw [entry_impl.match_all]
    split
    · simp
    · step
      step with hs fr (by rw [fr_post]; exact List.getElem_mem _)
      split
      · step
        exact ih (l.val.length - i2.val) (by scalar_tac) i2 rfl
      · simp

@[step] theorem match_inner_total (e : Entry) (f : FilterResolved) :
    entry_impl.entry_match_no_index_inner e f ⦃ _ => True ⦄ := by
  refine FilterResolved.rec
    (motive_1 := fun f => entry_impl.entry_match_no_index_inner e f ⦃ _ => True ⦄)
    (motive_2 := fun l => ∀ f ∈ l.val,
      entry_impl.entry_match_no_index_inner e f ⦃ _ => True ⦄)
    (motive_3 := fun s => ∀ f ∈ s.val,
      entry_impl.entry_match_no_index_inner e f ⦃ _ => True ⦄)
    (motive_4 := fun _ l => ∀ f ∈ l.toList,
      entry_impl.entry_match_no_index_inner e f ⦃ _ => True ⦄)
    ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ ?_ f
  · intro attr pv; rw [entry_impl.entry_match_no_index_inner]; step*
  · intro attr pv; rw [entry_impl.entry_match_no_index_inner]; step*
  · intro attr pv; rw [entry_impl.entry_match_no_index_inner]; step*
  · intro attr pv; rw [entry_impl.entry_match_no_index_inner]; step*
  · intro attr; rw [entry_impl.entry_match_no_index_inner]; step*
  · intro attr pv; rw [entry_impl.entry_match_no_index_inner]; step*
  · intro l ih; rw [entry_impl.entry_match_no_index_inner]; exact match_any_total e l ih _
  · intro l ih; rw [entry_impl.entry_match_no_index_inner]; exact match_all_total e l ih _
  · intro attr; rw [entry_impl.entry_match_no_index_inner]; simp
  · intro l ih; rw [entry_impl.entry_match_no_index_inner]; simp
  · intro f ih; rw [entry_impl.entry_match_no_index_inner]; step with ih
  · intro s ih; exact ih
  · intro n l bound ih; exact ih
  · simp [Data.ListN.ListN.toList]
  · intro n f l hf hl
    simpa only [Data.ListN.ListN.toList, List.mem_cons, forall_eq_or_imp] using And.intro hf hl

@[step] theorem target_total (target : profiles.AccessControlTargetCondition) (e : Entry) :
    search_acc.target_applies target e ⦃ _ => True ⦄ := by
  unfold search_acc.target_applies entry_impl.entry_match_no_index
  step*

@[step] theorem acp_allows_total (accr : profiles.AccessControlCreateResolved) (e : Entry)
    (attrs classes : Slice (alloc.vec.Vec U8)) :
    create_acc.create_acp_allows accr e attrs classes ⦃ _ => True ⦄ := by
  unfold create_acc.create_acp_allows
  h5i_steps

@[step] theorem any_acp_total (related : Slice profiles.AccessControlCreateResolved) (e : Entry)
    (attrs classes : Slice (alloc.vec.Vec U8)) :
    create_acc.create_any_acp related e attrs classes ⦃ _ => True ⦄ := by
  unfold create_acc.create_any_acp create_acc.create_any_acp_loop
  h5i_total (fun i => i) related.val.length

@[step] theorem names_total (e : Entry) :
    entry_impl.get_ava_names e ⦃ _ => True ⦄ := by
  unfold entry_impl.get_ava_names entry_impl.get_ava_names_loop
  apply loop_idx_spec _ (fun x => x.2) e.attrs.val.length
    (fun x => x.1.val.length ≤ x.2.val) _ ?_ _ (by simp) (by simp)
  rintro ⟨out, i⟩ hout hi
  unfold entry_impl.get_ava_names_loop.body
  h5i_steps <;> simp_all <;> scalar_tac

@[step] theorem insert_bound (set : alloc.vec.Vec (alloc.vec.Vec U8)) (x : Slice U8)
    (h : set.val.length < Usize.max) :
    bset.insert set x ⦃ r => r.val.length ≤ set.val.length + 1 ⦄ := by
  unfold bset.insert
  h5i_steps <;> simp_all <;> scalar_tac

@[step] theorem migration_ins_bound (set : alloc.vec.Vec (alloc.vec.Vec U8)) (x : Slice U8)
    (h : set.val.length < Usize.max) :
    migration.ins set x ⦃ r => r.val.length ≤ set.val.length + 1 ⦄ := by
  unfold migration.ins
  step* <;> scalar_tac

@[step] theorem ignore_classes_total (c : Slice U8) :
    migration.migration_ignore_classes c ⦃ _ => True ⦄ := by
  unfold migration.migration_ignore_classes
  h5i_steps

@[step] theorem entry_classes_total (c : Slice U8) :
    migration.migration_entry_classes c ⦃ _ => True ⦄ := by
  unfold migration.migration_entry_classes
  h5i_steps

@[step] theorem sub_ignore_total (classes : Slice (alloc.vec.Vec U8)) :
    migration.sub_migration_ignore classes ⦃ _ => True ⦄ := by
  unfold migration.sub_migration_ignore migration.sub_migration_ignore_loop
  apply loop_idx_spec _ (fun x => x.2) classes.val.length
    (fun x => x.1.val.length ≤ x.2.val) _ ?_ _ (by simp) (by simp)
  rintro ⟨out, i⟩ hout hi
  unfold migration.sub_migration_ignore_loop.body
  h5i_steps <;> simp_all <;> scalar_tac

@[step] theorem subset_migration_total (classes : Slice (alloc.vec.Vec U8)) :
    migration.subset_migration_entry classes ⦃ _ => True ⦄ := by
  unfold migration.subset_migration_entry migration.subset_migration_entry_loop
  h5i_total (fun i => i) classes.val.length

set_option maxHeartbeats 4000000 in
set_option maxRecDepth 8192 in
@[step] theorem migration_attrs_bound (classes : Slice (alloc.vec.Vec U8)) :
    migration.migration_entry_attrs classes ⦃ r =>
      r.1.val.length ≤ 64 ∧ r.2.val.length ≤ 64 ⦄ := by
  have hmax := usize_max_ge
  unfold migration.migration_entry_attrs
  -- Merge each optional class branch with a length bound, keeping later
  -- insertions below the vector capacity without enumerating combinations.
  step*
  apply WP.spec_bind (Pₘ := fun r : alloc.vec.Vec (alloc.vec.Vec U8) => r.val.length ≤ 6)
  · h5i_steps <;> scalar_tac
  · intro attrs2 h2
    step*
    apply WP.spec_bind (Pₘ := fun r : alloc.vec.Vec (alloc.vec.Vec U8) ×
        alloc.vec.Vec (alloc.vec.Vec U8) => r.1.val.length ≤ 11 ∧ r.2.val.length ≤ 3)
    · h5i_steps <;> scalar_tac
    · rintro ⟨attrs3, cls3⟩ ⟨h3, hc3⟩
      step*
      apply WP.spec_bind (Pₘ := fun r : alloc.vec.Vec (alloc.vec.Vec U8) ×
          alloc.vec.Vec (alloc.vec.Vec U8) => r.1.val.length ≤ 19 ∧ r.2.val.length ≤ 3)
      · h5i_steps
        all_goals (simp only [Prod.fst, Prod.snd, alloc.vec.Vec.new, alloc.vec.Vec.from_val,
          List.length_nil] at *; omega)
      · rintro ⟨attrs4, cls4⟩ ⟨h4, hc4⟩
        step*
        apply WP.spec_bind (Pₘ := fun r : alloc.vec.Vec (alloc.vec.Vec U8) ×
            alloc.vec.Vec (alloc.vec.Vec U8) => r.1.val.length ≤ 25 ∧ r.2.val.length ≤ 3)
        · h5i_steps <;> scalar_tac
        · rintro ⟨attrs5, cls5⟩ ⟨h5, hc5⟩
          step*
          apply WP.spec_bind (Pₘ := fun r : alloc.vec.Vec (alloc.vec.Vec U8) => r.val.length ≤ 33)
          · h5i_steps <;> scalar_tac
          · intro attrs6 h6
            h5i_steps
            all_goals (simp only [Prod.fst, Prod.snd, alloc.vec.Vec.new, alloc.vec.Vec.from_val,
              List.length_nil] at *; omega)

@[step] theorem extend_empty_total (xs : Slice (alloc.vec.Vec U8)) :
    bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) xs ⦃ _ => True ⦄ := by
  unfold bset.extend bset.extend_loop
  apply loop_idx_spec _ (fun x => x.2) xs.val.length
    (fun x => x.1.val.length ≤ x.2.val) _ ?_ _ (by simp) (by simp)
  rintro ⟨out, i⟩ hout hi
  unfold bset.extend_loop.body
  h5i_steps <;> simp_all <;> scalar_tac

@[step] theorem migration_total (scope : AccessScope) (entry : Entry) :
    create_acc.migration_filter_entry ⟨.Internal .Migration, scope⟩ entry ⦃ _ => True ⦄ := by
  unfold create_acc.migration_filter_entry
  h5i_steps

@[step] theorem create_user_total (u : IdentUser) (scope : AccessScope)
    (related : Slice profiles.AccessControlCreateResolved) (entry : Entry) :
    create_acc.create_filter_entry ⟨.User u, scope⟩ related entry ⦃ r =>
      match r with | .Allow _ _ => False | _ => True ⦄ := by
  unfold create_acc.create_filter_entry identity_impl.access_scope
  cases scope <;> h5i_steps

theorem protected_deny_overrides_create (ident : Identity)
    (related : Slice profiles.AccessControlCreateResolved) (e : Entry)
    (h : create_acc.protected_filter_entry ident e = ok .Deny) :
    create_acc.apply_create_access ident related e = ok .Deny := by
  rcases ident with ⟨origin, scope⟩
  cases origin with
  | User u =>
    obtain ⟨r, hr⟩ := ok_of (create_user_total u scope related e)
    have hs := post_of_ok (create_user_total u scope related e) hr
    cases r <;> simp_all [create_acc.apply_create_access, create_acc.message_queue,
      create_acc.migration_filter_entry]
  | Synch uuid =>
    simp [create_acc.apply_create_access, h, create_acc.message_queue,
      create_acc.migration_filter_entry, create_acc.create_filter_entry]
  | Internal role =>
    cases role with
    | System => simp [create_acc.protected_filter_entry] at h
    | AccountRequest => simp [create_acc.protected_filter_entry] at h
    | MessageQueue => simp [create_acc.protected_filter_entry] at h
    | Migration =>
      obtain ⟨r, hr⟩ := ok_of (migration_total scope e)
      apply eq_ok_of_spec
      simp only [create_acc.apply_create_access, h, bind_tc_ok,
        create_acc.message_queue, create_acc.create_filter_entry, hr]
      cases r <;> h5i_steps

end kanidm_kernel.Solution
