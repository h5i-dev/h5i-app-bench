import I5hLib.Loops
/-!
# Keyed tables as lists

A kernel table is a list of rows with a key. `upsert` is what the database
does for `INSERT ... ON CONFLICT (key) DO UPDATE`, read back as a list:
replace the row with the same key, or append.
-/
namespace I5hLib

/-- Replace the first row with `x`'s key by `x`, or append `x`. -/
def upsert {α} (key : α → Nat × Nat) (x : α) : List α → List α
  | [] => [x]
  | y :: ys => if key y = key x then x :: ys else y :: upsert key x ys

theorem upsert_eq {α} (key : α → Nat × Nat) (x : α) (l : List α) :
    upsert key x l = upsertBy (fun y => decide (key y = key x)) x l := by
  induction l with
  | nil => rfl
  | cons y ys ih => simp only [upsert, upsertBy, ih, decide_eq_true_eq]

/-- What an upsert loop started at `i` returns, when the prefix before `i`
has no match. -/
theorem upsert_loop_result {α} (key : α → Nat × Nat) (x : α) (v : List α) (i : Nat)
    (hi : i ≤ v.length) (hpre : upsert key x v = v.take i ++ upsert key x (v.drop i)) :
    searchFrom v (fun q => decide (key q = key x)) (fun j _ => v.set j x) (v ++ [x]) i =
      upsert key x v := by
  rw [searchFrom_upsert _ _ _ _ hi, ← upsert_eq, hpre]

/-- A delete loop keeps the rows satisfying `P`, pushing them into `out`. -/
theorem filter_split {α} (P : α → Bool) (l : List α) (k : Nat) :
    (l.take k).filter P ++ (l.drop k).filter P = l.filter P := by
  rw [← List.filter_append, List.take_append_drop]

theorem upsert_length {α} (key : α → Nat × Nat) (x : α) (l : List α) :
    (upsert key x l).length ≤ l.length + 1 := by
  induction l with
  | nil => simp [upsert]
  | cons y ys ih => rw [upsert]; split <;> simp; omega

section Lists
variable {α β : Type}

theorem mem_upsert_of {k : α → Nat × Nat} {x z : α} {l : List α}
    (h : z ∈ upsert k x l) : z = x ∨ z ∈ l := by
  induction l with
  | nil => simp [upsert] at h; exact Or.inl h
  | cons y ys ih =>
    unfold upsert at h
    split at h
    · simp at h; rcases h with h | h
      · exact Or.inl h
      · exact Or.inr (List.mem_cons_of_mem _ h)
    · simp at h; rcases h with h | h
      · exact Or.inr (h ▸ List.mem_cons_self)
      · rcases ih h with h | h
        · exact Or.inl h
        · exact Or.inr (List.mem_cons_of_mem _ h)

theorem mem_upsert_self (k : α → Nat × Nat) (x : α) (l : List α) : x ∈ upsert k x l := by
  induction l with
  | nil => simp [upsert]
  | cons y ys ih => unfold upsert; split <;> simp [ih]

theorem mem_upsert_of_ne {k : α → Nat × Nat} {x z : α} {l : List α}
    (hz : z ∈ l) (hk : k z ≠ k x) : z ∈ upsert k x l := by
  induction l with
  | nil => simp at hz
  | cons y ys ih =>
    unfold upsert
    simp at hz
    split
    · rename_i hy
      rcases hz with rfl | hz
      · exact absurd hy hk
      · exact List.mem_cons_of_mem _ hz
    · rcases hz with rfl | hz
      · exact List.mem_cons_self
      · exact List.mem_cons_of_mem _ (ih hz)

/-- With unique keys, `upsert` replaces exactly the row with `x`'s key. -/
theorem mem_upsert_iff {k : α → Nat × Nat} {x z : α} {l : List α} (hl : (l.map k).Nodup) :
    z ∈ upsert k x l ↔ z = x ∨ (z ∈ l ∧ k z ≠ k x) := by
  constructor
  · intro h
    induction l with
    | nil => simp [upsert] at h; exact Or.inl h
    | cons y ys ih =>
      simp only [List.map_cons, List.nodup_cons, List.mem_map] at hl
      unfold upsert at h
      split at h
      · rename_i hy
        simp at h; rcases h with h | h
        · exact Or.inl h
        · right; refine ⟨List.mem_cons_of_mem _ h, ?_⟩
          intro hzk; exact hl.1 ⟨z, h, hzk.trans hy.symm⟩
      · rename_i hy
        simp at h; rcases h with rfl | h
        · exact Or.inr ⟨List.mem_cons_self, hy⟩
        · rcases ih hl.2 h with h | ⟨h1, h2⟩
          · exact Or.inl h
          · exact Or.inr ⟨List.mem_cons_of_mem _ h1, h2⟩
  · rintro (rfl | ⟨hz, hk⟩)
    · exact mem_upsert_self k _ l
    · exact mem_upsert_of_ne hz hk

theorem nodup_map_upsert (k : α → Nat × Nat) (g : α → β) (hk : ∀ a b, k a = k b ↔ g a = g b)
    (x : α) (l : List α) (h : (l.map g).Nodup) : ((upsert k x l).map g).Nodup := by
  induction l with
  | nil => simp [upsert]
  | cons y ys ih =>
    simp only [List.map_cons, List.nodup_cons, List.mem_map] at h
    unfold upsert
    split
    · rename_i hy
      simp only [List.map_cons, List.nodup_cons, List.mem_map]
      refine ⟨?_, h.2⟩
      rintro ⟨z, hz, hzg⟩
      exact h.1 ⟨z, hz, hzg.trans ((hk y x).1 hy).symm⟩
    · rename_i hy
      simp only [List.map_cons, List.nodup_cons, List.mem_map]
      refine ⟨?_, ih h.2⟩
      rintro ⟨z, hz, hzg⟩
      rcases mem_upsert_of hz with rfl | hz
      · exact hy ((hk _ _).2 hzg.symm)
      · exact h.1 ⟨z, hz, hzg⟩

theorem nodup_map_k_of_g (k : α → Nat × Nat) (g : α → β) (hk : ∀ a b, k a = k b ↔ g a = g b)
    (l : List α) (h : (l.map g).Nodup) : (l.map k).Nodup := by
  induction l with
  | nil => simp
  | cons y ys ih =>
    simp only [List.map_cons, List.nodup_cons, List.mem_map] at h ⊢
    refine ⟨?_, ih h.2⟩
    rintro ⟨z, hz, hzk⟩
    exact h.1 ⟨z, hz, (hk _ _).1 hzk⟩

theorem nodup_map_filter (g : α → β) (p : α → Bool) (l : List α) (h : (l.map g).Nodup) :
    ((l.filter p).map g).Nodup :=
  (List.Sublist.map g List.filter_sublist).nodup h

end Lists

end I5hLib
