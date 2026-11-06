import Verified.Commands
/-!
# Index loops over a vector are monadic folds

`while i < v.len() { acc = f(acc, &v[i]); i += 1 }` extracts to
`loop body (acc, i)`. `loop_eq_foldlM` states it equals `List.foldlM f`
over the rest of the list, as an equation of `Result`s (failures included),
so facts about folds (`foldlM_filter`) transfer to the kernel exactly.
-/
open Aeneas Aeneas.Std Result atuin_kernel atuin_kernel.Spec
open H5iAppLib hiding lit

namespace atuin_kernel.Verified

theorem vec_index_eq {α : Type} (v : alloc.vec.Vec α) (i : Usize) (h : i.val < v.val.length) :
    alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice α) v i = ok v.val[i.val] := by
  rw [alloc.vec.Vec.index_slice_index]
  simp only [alloc.vec.Vec.index_usize]
  rw [show v[i.val]? = some v.val[i.val] by simp [h]]

theorem usize_add_one_eq (i : Usize) (n : Nat) (hi : i.val < n) (hn : n ≤ Usize.max) :
    ∃ j : Usize, i + 1#usize = ok j ∧ j.val = i.val + 1 := by
  have hs : (i + 1#usize) ⦃ j => j.val = i.val + 1 ⦄ := by step*
  obtain ⟨j, hj⟩ := ok_of hs
  have h' := post_of_ok hs hj
  exact ⟨j, hj, h'⟩

theorem loop_eq_foldlM {α σ : Type} (l : List α) (f : σ → α → Result σ)
    (body : σ × Usize → Result (ControlFlow (σ × Usize) σ))
    (hb : ∀ acc (i : Usize) (h : i.val < l.length),
      body (acc, i) = (do let a ← f acc l[i.val]; let j ← i + 1#usize; ok (ControlFlow.cont (a, j))))
    (he : ∀ acc (i : Usize), l.length ≤ i.val → body (acc, i) = ok (ControlFlow.done acc))
    (hl : l.length ≤ Usize.max) :
    ∀ acc (i : Usize), i.val ≤ l.length → loop body (acc, i) = (l.drop i.val).foldlM f acc := by
  intro acc i hi
  induction h : l.length - i.val generalizing acc i with
  | zero =>
    have : l.length ≤ i.val := by omega
    rw [loop, he acc i this, List.drop_eq_nil_of_le this]
    simp only [bind_ok, List.foldlM_nil]
    rfl
  | succ n ih =>
    have hlt : i.val < l.length := by omega
    rw [loop, hb acc i hlt, List.drop_eq_getElem_cons hlt, List.foldlM_cons]
    obtain ⟨j, hj, hjv⟩ := usize_add_one_eq i l.length hlt hl
    simp only [hj, bind_ok]
    rw [Std.bind_assoc]
    congr 1; funext a
    simp only [bind_ok]
    rw [ih a j (by omega) (by omega), hjv]

/-- A fold that skips the elements failing `P` is a fold over `l.filter P`. -/
theorem foldlM_filter {α σ : Type} (P : α → Bool) (g : σ → α → Result σ) (l : List α) (a : σ) :
    l.foldlM (fun acc x => if P x then g acc x else ok acc) a = (l.filter P).foldlM g a := by
  induction l generalizing a with
  | nil => rfl
  | cons x xs ih =>
    by_cases hp : P x
    · simp only [List.foldlM_cons, hp, ↓reduceIte, List.filter_cons_of_pos hp]
      congr 1; funext b; exact ih b
    · simp only [List.foldlM_cons, hp, Bool.false_eq_true, ↓reduceIte, bind_tc_ok, List.filter_cons_of_neg hp]
      exact ih a

theorem status_eq (s : Snapshot) (uid : U64) :
    status s uid = s.store.val.foldlM (fun acc x => if decide (x.user_id = uid) then bump acc x else ok acc)
      (alloc.vec.Vec.new StatusPoint) := by
  unfold status status_loop
  rw [loop_eq_foldlM s.store.val (fun acc x => if decide (x.user_id = uid) then bump acc x else ok acc)
    _ ?hb ?he (by scalar_tac) _ 0#usize (by simp)]
  · simp
  case hb =>
    intro acc i hi
    unfold status_loop.body
    have hc : i < alloc.vec.Vec.len s.store := by scalar_tac
    simp only [hc, ↓reduceIte, vec_index_eq _ _ hi, bind_ok]
    first | rfl | (by_cases hu : s.store.val[i.val].user_id = uid <;> simp [hu])
  case he =>
    intro acc i hi
    unfold status_loop.body
    have hc : ¬ i < alloc.vec.Vec.len s.store := by scalar_tac
    simp only [hc, ↓reduceIte]

/-- `signed_key`, as a value. -/
def sk (x : U64) : U64 := x ^^^ 9223372036854775808#u64

theorem signed_key_eq (x : U64) : signed_key x = ok (sk x) := rfl

/-- `in_series`: the row is the user's, in the series, at or after `start` (signed). -/
def InSeries (uid : U64) (host : U128) (tag : List U8) (st : U64) (r : StoreRow) : Bool :=
  decide (r.user_id = uid) && decide (r.tag.val = tag) && decide (r.host = host) && decide (sk r.idx ≥ sk st)

theorem in_series_eq (r : StoreRow) (uid : U64) (host : U128) (tag : Slice U8) (st : U64) :
    in_series r uid host tag st = ok (InSeries uid host tag.val st r) := by
  unfold in_series InSeries
  have hb := eq_ok_of_spec (bytes_eq_spec (alloc.vec.Vec.deref r.tag) tag)
  simp only [vec_deref_val] at hb
  by_cases h1 : r.user_id = uid <;> by_cases h2 : r.tag.val = tag.val <;> by_cases h3 : r.host = host <;>
    simp [h1, h2, h3, hb, signed_key_eq]

theorem in_series_user {uid : U64} {host : U128} {tag : List U8} {st : U64} {r : StoreRow}
    (h : InSeries uid host tag st r = true) : r.user_id = uid := by
  simp only [InSeries, Bool.and_eq_true, decide_eq_true_eq] at h; exact h.1.1.1

theorem next_loop_eq (s : Snapshot) (uid : U64) (host : U128) (tag : alloc.vec.Vec U8) (st : U64) :
    next_records_loop s uid host tag st (alloc.vec.Vec.new StoreRow) 0#usize =
      s.store.val.foldlM (fun acc x => if InSeries uid host tag.val st x then insert_sorted acc x else ok acc)
        (alloc.vec.Vec.new StoreRow) := by
  unfold next_records_loop
  rw [loop_eq_foldlM s.store.val (fun acc x => if InSeries uid host tag.val st x then insert_sorted acc x else ok acc)
    _ ?hb ?he (by scalar_tac) _ 0#usize (by simp)]
  · simp
  case hb =>
    intro acc i hi
    unfold next_records_loop.body
    have hc : i < alloc.vec.Vec.len s.store := by scalar_tac
    simp only [hc, ↓reduceIte, vec_index_eq _ _ hi, bind_ok, in_series_eq, bind_tc_ok, vec_deref_val]
  case he =>
    intro acc i hi
    unfold next_records_loop.body
    have hc : ¬ i < alloc.vec.Vec.len s.store := by scalar_tac
    simp only [hc, ↓reduceIte]

theorem next_records_eq (s : Snapshot) (uid : U64) (host : U128) (tag : alloc.vec.Vec U8) (start : Option U64)
    (count : U64) :
    next_records s uid host tag start count = (do
      let sorted ← s.store.val.foldlM (fun acc x =>
        if InSeries uid host tag.val (start.getD 0#u64) x then insert_sorted acc x else ok acc)
        (alloc.vec.Vec.new StoreRow)
      if count > 9223372036854775807#u64 then ok sorted else take sorted count) := by
  unfold next_records
  cases start <;> simp only [bind_tc_ok, bind_ok, Option.getD_none, Option.getD_some, next_loop_eq] <;> rfl

end atuin_kernel.Verified
