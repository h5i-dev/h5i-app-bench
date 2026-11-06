import Spec
/-!
# The table statements as list functions

`find_row` is `rowOf`, `delete` is `without`, `delete_for` is `deletedBy`,
`contains_uid` is membership. Later files use only these specs.
-/
open Aeneas Aeneas.Std Result wastebin_kernel wastebin_kernel.Spec
open H5iAppLib
open Aeneas.Std.WP

namespace wastebin_kernel.Verified.Store

@[step] theorem contains_uid_spec (uids : Slice I64) (x : I64) :
    store.contains_uid uids x ⦃ b => b = decide (x ∈ uids.val) ⦄ := by
  unfold store.contains_uid store.contains_uid_loop
  apply WP.spec_mono (loop_search uids.val (fun u => decide (u = x)) (fun b : Bool => b)
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr
    rw [hr, searchFrom_const]
    simp [eq_comm]
  · intro j hj; unfold store.contains_uid_loop.body; h5i_step

@[step] theorem owned_by_spec (uid : Option I64) (uids : Slice I64) :
    store.owned_by uid uids ⦃ b => b = decide (∃ u, uid = some u ∧ u ∈ uids.val) ⦄ := by
  unfold store.owned_by
  cases uid <;> step* <;> simp_all

@[step] theorem find_row_spec (rows : alloc.vec.Vec Row) (id : I64) :
    store.find_row rows id ⦃ o => o = rowOf rows.val id ⦄ := by
  unfold store.find_row store.find_row_loop
  apply WP.spec_mono (loop_search rows.val (fun r => decide (r.id = id)) (fun o : Option Row => o)
    (fun _ r => some r) none _ ?_ 0#usize (by simp))
  · intro r hr; rw [search_find _ _ _ hr]; simp [rowOf]
  · intro j hj; unfold store.find_row_loop.body; h5i_step

/-- The model step of `delete`'s loop. -/
def delStep (id : I64) (acc : List Row × Bool) (r : Row) : List Row × Bool :=
  if r.id = id then (acc.1, true) else (acc.1 ++ [r], acc.2)

theorem foldl_delStep (id : I64) (l acc : List Row) (h : Bool) :
    l.foldl (delStep id) (acc, h) = (acc ++ without l id, h || l.any (fun r => decide (r.id = id))) := by
  induction l generalizing acc h with
  | nil => simp [without]
  | cons r l ih =>
    simp only [List.foldl_cons, delStep]
    split
    · rw [ih]; simp_all [without]
    · rw [ih]; simp_all [without]

@[step] theorem delete_spec (rows : alloc.vec.Vec Row) (id : I64) :
    store.delete rows id ⦃ r => r.1.val = without rows.val id ∧
      r.2 = rows.val.any (fun r => decide (r.id = id)) ⦄ := by
  unfold store.delete store.delete_loop
  apply WP.spec_mono (loop_fold2 rows.val (fun (a : alloc.vec.Vec Row) (b : Bool) => (a.val, b))
    (delStep id) (fun a _ i => a.val.length ≤ i) _ ?_ (alloc.vec.Vec.new Row) false 0#usize
    (by simp) (by simp [vec_new_val]))
  · rintro ⟨a, b⟩ ⟨h1, -⟩
    simp only [List.drop_zero, vec_new_val, foldl_delStep, List.nil_append, Bool.false_or] at h1
    simp only [Prod.mk.injEq] at h1
    exact ⟨h1.1, h1.2⟩
  · intro a b i hi hinv
    unfold store.delete_loop.body
    simp only [bind_ite]
    split
    · step*
      split <;> step* <;> simp_all [FoldStep2, delStep] <;> scalar_tac
    · step*
      simp_all [FoldStep2]
      scalar_tac

/-- The model step of `delete_for`'s loop. -/
def delForStep (id : I64) (uids : List I64) (acc : List Row × Bool) (r : Row) : List Row × Bool :=
  if r.id = id ∧ (∃ u, r.uid = some u ∧ u ∈ uids) then (acc.1, true) else (acc.1 ++ [r], acc.2)

theorem foldl_delForStep (id : I64) (uids : List I64) (l acc : List Row) (h : Bool) :
    l.foldl (delForStep id uids) (acc, h) = (acc ++ deletedBy l id uids,
      h || l.any (fun r => decide (r.id = id) && decide (∃ u, r.uid = some u ∧ u ∈ uids))) := by
  induction l generalizing acc h with
  | nil => simp [deletedBy]
  | cons r l ih =>
    simp only [List.foldl_cons, delForStep]
    split
    · rw [ih]; simp_all [deletedBy]
    · rw [ih]
      rename_i hn
      simp only [deletedBy, List.filter_cons, List.any_cons]
      by_cases hid : r.id = id
      · have : ¬ ∃ u, r.uid = some u ∧ u ∈ uids := fun h => hn ⟨hid, h⟩
        simp [hid, this]
      · simp [hid]

/-- `delete_for` is `deletedBy`, refused when `uids` is empty or no row is
the holder's paste with that id. -/
@[step] theorem delete_for_spec (rows : alloc.vec.Vec Row) (id : I64) (uids : Slice I64) :
    store.delete_for rows id uids ⦃ r =>
      r = if uids.val = [] ∨ ¬ (∃ x ∈ rows.val, x.id = id ∧ ∃ u, x.uid = some u ∧ u ∈ uids.val)
        then .Err .Delete
        else .Ok ⟨deletedBy rows.val id uids.val, by
          have := rows.property
          have : (deletedBy rows.val id uids.val).length ≤ rows.val.length := List.length_filter_le _ _
          scalar_tac⟩ ⦄ := by
  unfold store.delete_for store.delete_for_loop
  sorry

end wastebin_kernel.Verified.Store
