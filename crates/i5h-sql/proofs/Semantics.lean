import I5hSql
/-!
# The extracted planner, and what its statements mean

`plan` turns a write set into keyed statements. We prove it computes
`planA` on plain lists, then give statements a database semantics and show
that running the plan agrees with applying the writes to keyed tables.
-/
open Aeneas Aeneas.Std Result i5h_sql

namespace i5h_sql.Sem

/-! ## Plain-list views of the extracted types -/

inductive AStmt where
  | up (t : Nat) (key rest : List Val)
  | del (t : Nat) (key : List Val)

inductive AWrite where
  | put (t kl : Nat) (row : List Val)
  | del (t : Nat) (key : List Val)

def Stmt.abs : Stmt → AStmt
  | .Upsert t k r => .up t.val k.val r.val
  | .Delete t k => .del t.val k.val

def Write.abs : Write → AWrite
  | .Put t kl row => .put t.val kl.val row.val
  | .Del t k => .del t.val k.val

/-- The plan, over lists: split a put's row into key and rest. -/
def planA : AWrite → AStmt
  | .put t kl row => .up t (row.take kl) (row.drop kl)
  | .del t k => .del t k

/-! ## The extracted planner computes `planA` -/

theorem clone_bytes (v : alloc.vec.Vec U8) :
    alloc.vec.CloneVec.clone core.clone.CloneU8 v = ok v := by
  have h := Slice.clone_spec (clone := liftFun1 core.clone.impls.CloneU8.clone) (s := v.slice)
    (fun _ _ => rfl)
  rw [WP.spec_equiv_exists] at h
  obtain ⟨s', hs, rfl⟩ := h
  simp [alloc.vec.CloneVec.clone, hs]

theorem val_clone (x : Val) : Val.Insts.CoreCloneClone.clone x = ok x := by
  cases x <;> simp [Val.Insts.CoreCloneClone.clone, clone_bytes, lift]

@[step]
theorem val_clone_spec (x : Val) : Val.Insts.CoreCloneClone.clone x ⦃ y => y = x ⦄ := by
  simp [val_clone]

theorem vals_clone (v : alloc.vec.Vec Val) :
    alloc.vec.CloneVec.clone Val.Insts.CoreCloneClone v = ok v := by
  have h := Slice.clone_spec (clone := Val.Insts.CoreCloneClone.clone) (s := v.slice)
    (fun x _ => val_clone x)
  rw [WP.spec_equiv_exists] at h
  obtain ⟨s', hs, rfl⟩ := h
  simp [alloc.vec.CloneVec.clone, hs]

@[step]
theorem prefix_loop_spec (row : alloc.vec.Vec Val) (n : Usize) :
    prefix_loop row n (alloc.vec.Vec.new Val) 0#usize ⦃ v => v.val = row.val.take n.val ⦄ := by
  unfold prefix_loop
  apply loop.spec_decr_nat
    (measure := fun (x : alloc.vec.Vec Val × Usize) => row.length - x.2.val)
    (inv := fun x => x.2.val ≤ row.length ∧ x.2.val ≤ n.val ∧ x.1.val = row.val.take x.2.val)
  · rintro ⟨o, j⟩ ⟨hj, hn, heq⟩
    simp only at hj hn heq ⊢
    unfold prefix_loop.body
    step*
    · refine ⟨by scalar_tac, by scalar_tac, ?_, by scalar_tac⟩
      rw [out1_post, heq, i2_post, v1_post, v_post, List.take_add_one,
        List.getElem?_eq_getElem (by scalar_tac)]
      rfl
    · rw [heq, List.take_of_length_le (by scalar_tac), List.take_of_length_le (by scalar_tac)]
  · simp

@[step]
theorem suffix_loop_spec (row : alloc.vec.Vec Val) (n : Usize) :
    suffix_loop row (alloc.vec.Vec.new Val) n ⦃ v => v.val = row.val.drop n.val ⦄ := by
  unfold suffix_loop
  apply loop.spec_decr_nat
    (measure := fun (x : alloc.vec.Vec Val × Usize) => row.length - x.2.val)
    (inv := fun x => x.1.length ≤ x.2.val ∧ x.1.val ++ row.val.drop x.2.val = row.val.drop n.val)
  · rintro ⟨o, j⟩ ⟨hl, heq⟩
    simp only at hl heq ⊢
    unfold suffix_loop.body
    step*
    · have hc : row.val.drop j.val = row.val[j.val] :: row.val.drop (j.val + 1) :=
        List.drop_eq_getElem_cons (by scalar_tac)
      refine ⟨?_, ?_, by scalar_tac⟩
      · simp only [alloc.vec.Vec.length, out1_post, List.length_append, List.length_singleton, i2_post]
        simp only [alloc.vec.Vec.length] at hl
        omega
      · rw [← heq, out1_post, i2_post, hc, v1_post, v_post]; simp
    · rw [← heq, List.drop_eq_nil_of_le (by scalar_tac), List.append_nil]
  · simp

@[step]
theorem plan_one_spec (w : Write) : plan_one w ⦃ s => Stmt.abs s = planA (Write.abs w) ⦄ := by
  unfold plan_one
  cases w <;> simp only
  · step*
    simp only [Stmt.abs, Write.abs, planA, v_post, v1_post, n_post, U32.cast_Usize_val_eq]
  · simp [vals_clone, Stmt.abs, Write.abs, planA]

/-- `plan` succeeds and computes `planA` on every write, in order. -/
@[step]
theorem plan_spec (ws : alloc.vec.Vec Write) :
    plan ws ⦃ ss => ss.val.map Stmt.abs = ws.val.map (planA ∘ Write.abs) ⦄ := by
  unfold plan plan_loop
  apply loop.spec_decr_nat
    (measure := fun (x : alloc.vec.Vec Stmt × Usize) => ws.length - x.2.val)
    (inv := fun x => x.2.val ≤ ws.length ∧ x.1.length = x.2.val ∧
      x.1.val.map Stmt.abs = (ws.val.take x.2.val).map (planA ∘ Write.abs))
  · rintro ⟨o, j⟩ ⟨hj, hl, heq⟩
    simp only at hj hl heq ⊢
    unfold plan_loop.body
    step*
    · refine ⟨by scalar_tac, ?_, ?_, by scalar_tac⟩
      · simp only [alloc.vec.Vec.length, out1_post, List.length_append, List.length_singleton, i2_post]
        simp only [alloc.vec.Vec.length] at hl
        omega
      · have hj' : j.val < ws.val.length := by scalar_tac
        rw [out1_post, i2_post, List.map_append, heq, List.take_add_one,
          List.getElem?_eq_getElem hj', Option.toList_some, List.map_append]
        simp [s_post, w_post]
    · rw [heq, List.take_of_length_le (by scalar_tac)]
  · simp

/-! ## What statements mean -/

open Classical

/-- One tenant's database: the row stored at each (table, key), if any. -/
def Db := Nat → List Val → Option (List Val)

/-- Trusted: this is what PostgreSQL does for `INSERT ... ON CONFLICT (pk) DO
UPDATE SET <rest>` and `DELETE ... WHERE pk = key`, where the primary key is
`tenant_id` plus the key columns. -/
noncomputable def exec (db : Db) : AStmt → Db
  | .up t k r => fun t' k' => if t' = t ∧ k' = k then some (k ++ r) else db t' k'
  | .del t k => fun t' k' => if t' = t ∧ k' = k then none else db t' k'

noncomputable def execAll (db : Db) (ss : List AStmt) : Db := ss.foldl exec db

/-! ## Keyed tables as lists (the kernel's view) -/

/-- Rows per table. -/
def Tables := Nat → List (List Val)

/-- Replace the first row with the same key, or append. -/
noncomputable def upsertRow (n : Nat) (row : List Val) : List (List Val) → List (List Val)
  | [] => [row]
  | r :: rs => if r.take n = row.take n then row :: rs else r :: upsertRow n row rs

section
variable (kl : Nat → Nat)

/-- Apply one write; `kl t` is table `t`'s key length. -/
noncomputable def applyW (tabs : Tables) : AWrite → Tables
  | .put t _ row => fun t' => if t' = t then upsertRow (kl t) row (tabs t) else tabs t'
  | .del t k => fun t' => if t' = t then (tabs t).filter (fun r => ¬ r.take (kl t) = k) else tabs t'

noncomputable def applyAllW (tabs : Tables) (ws : List AWrite) : Tables := ws.foldl (applyW kl) tabs

/-- The database a set of keyed tables stands for. Row order does not matter. -/
noncomputable def readBack (tabs : Tables) : Db :=
  fun t k => (tabs t).find? (fun r => r.take (kl t) = k)

/-- Keys are unique and every row has a full key. -/
def WellKeyed (tabs : Tables) : Prop :=
  ∀ t, ((tabs t).map (·.take (kl t))).Nodup ∧ ∀ r ∈ tabs t, kl t ≤ r.length

/-- A put uses its table's key length. -/
def WriteOk : AWrite → Prop
  | .put t n row => n = kl t ∧ kl t ≤ row.length
  | .del _ _ => True
end

theorem find_upsert (n : Nat) (row : List Val) (k : List Val) (rs : List (List Val)) :
    (upsertRow n row rs).find? (fun r => r.take n = k) =
      if row.take n = k then some row else rs.find? (fun r => r.take n = k) := by
  induction rs with
  | nil => simp [upsertRow]
  | cons r rs ih =>
    unfold upsertRow
    by_cases hr : r.take n = row.take n
    · simp only [hr, if_true, List.find?_cons]
      by_cases hk : row.take n = k <;> simp_all
    · simp only [hr, if_false, List.find?_cons, ih]
      by_cases hk : row.take n = k <;> by_cases hk' : r.take n = k <;> simp_all

theorem keys_upsert (n : Nat) (row : List Val) (rs : List (List Val)) :
    (upsertRow n row rs).map (·.take n) =
      if row.take n ∈ rs.map (·.take n) then rs.map (·.take n) else rs.map (·.take n) ++ [row.take n] := by
  induction rs with
  | nil => simp [upsertRow]
  | cons r rs ih =>
    unfold upsertRow
    by_cases hr : r.take n = row.take n
    · simp [hr]
    · simp only [hr, if_false, List.map_cons, ih, List.mem_cons]
      by_cases hm : row.take n ∈ rs.map (·.take n)
      · simp [hm]
      · have : ¬ row.take n = r.take n := fun h => hr h.symm
        simp [hm, this]

theorem mem_upsert {n : Nat} {row x : List Val} {rs : List (List Val)}
    (h : x ∈ upsertRow n row rs) : x = row ∨ x ∈ rs := by
  induction rs with
  | nil => simp_all [upsertRow]
  | cons r rs ih =>
    unfold upsertRow at h
    split at h
    · simp only [List.mem_cons] at h
      rcases h with h | h <;> simp_all
    · simp only [List.mem_cons] at h
      rcases h with h | h
      · exact Or.inr (List.mem_cons.2 (Or.inl h))
      · rcases ih h with h | h
        · exact Or.inl h
        · exact Or.inr (List.mem_cons_of_mem _ h)

theorem find_filter_ne (n : Nat) (k k' : List Val) (h : k' ≠ k) (rs : List (List Val)) :
    (rs.filter (fun r => ¬ r.take n = k)).find? (fun r => r.take n = k') =
      rs.find? (fun r => r.take n = k') := by
  simp only [List.find?_filter]
  congr 1
  funext r
  by_cases hr : r.take n = k' <;> simp_all

theorem find_filter_eq (n : Nat) (k : List Val) (rs : List (List Val)) :
    (rs.filter (fun r => ¬ r.take n = k)).find? (fun r => r.take n = k) = none := by
  rw [List.find?_eq_none]
  intro x hx
  simp only [List.mem_filter, decide_eq_true_eq] at hx
  simpa using hx.2

theorem step_sound (kl : Nat → Nat) (tabs : Tables) (w : AWrite)
    (hk : WellKeyed kl tabs) (hw : WriteOk kl w) :
    readBack kl (applyW kl tabs w) = exec (readBack kl tabs) (planA w) ∧
    WellKeyed kl (applyW kl tabs w) := by
  cases w with
  | put t n row =>
    obtain ⟨rfl, hlen⟩ := hw
    refine ⟨?_, ?_⟩
    · funext t' k'
      simp only [readBack, applyW, exec, planA, List.take_append_drop]
      by_cases ht : t' = t
      · subst ht
        simp only [if_true, true_and, find_upsert]
        by_cases hk' : k' = row.take (kl t') <;> simp_all [eq_comm]
      · simp [ht]
    · intro t'
      simp only [applyW]
      by_cases ht : t' = t
      · subst ht
        simp only [if_true, keys_upsert]
        refine ⟨?_, fun r hr => ?_⟩
        · split
          · exact (hk t').1
          · rename_i hm
            exact List.nodup_append.2 ⟨(hk t').1, by simp, fun a ha b hb hab =>
              hm (by rw [List.mem_singleton] at hb; subst hb; subst hab; exact ha)⟩
        · rcases mem_upsert hr with rfl | hr
          · exact hlen
          · exact (hk t').2 r hr
      · simpa [ht] using hk t'
  | del t k =>
    refine ⟨?_, ?_⟩
    · funext t' k'
      simp only [readBack, applyW, exec, planA]
      by_cases ht : t' = t
      · subst ht
        by_cases hk' : k' = k
        · subst hk'
          simp only [if_true, and_self]
          exact find_filter_eq _ _ _
        · simp only [if_true, true_and, hk', if_false]
          exact find_filter_ne _ _ _ hk' _
      · simp [ht]
    · intro t'
      simp only [applyW]
      by_cases ht : t' = t
      · subst ht
        simp only [if_true]
        refine ⟨?_, fun r hr => (hk t').2 r (List.mem_filter.1 hr).1⟩
        exact (hk t').1.sublist (List.Sublist.map _ List.filter_sublist)
      · simpa [ht] using hk t'

/-- Running the plan on the database equals applying the writes to keyed
tables, and keys stay unique. -/
theorem plan_sound (kl : Nat → Nat) (ws : List AWrite) :
    ∀ tabs, WellKeyed kl tabs → (∀ w ∈ ws, WriteOk kl w) →
      readBack kl (applyAllW kl tabs ws) = execAll (readBack kl tabs) (ws.map planA) ∧
      WellKeyed kl (applyAllW kl tabs ws) := by
  induction ws with
  | nil => intro tabs hk _; exact ⟨rfl, hk⟩
  | cons w ws ih =>
    intro tabs hk hw
    obtain ⟨h1, h2⟩ := step_sound kl tabs w hk (hw w (by simp))
    obtain ⟨h3, h4⟩ := ih (applyW kl tabs w) h2 (fun w' hw' => hw w' (by simp [hw']))
    refine ⟨?_, h4⟩
    simp only [applyAllW, List.foldl_cons, execAll, List.map_cons] at h3 ⊢
    rw [h3, h1]

/-- End to end: the extracted `plan` on an extracted write set, run under the
statement semantics, gives the keyed-table result. -/
theorem extracted_plan_sound (kl : Nat → Nat) (ws : alloc.vec.Vec Write) (tabs : Tables)
    (hk : WellKeyed kl tabs) (hw : ∀ w ∈ ws.val, WriteOk kl (Write.abs w)) :
    plan ws ⦃ ss =>
      execAll (readBack kl tabs) (ss.val.map Stmt.abs) =
        readBack kl (applyAllW kl tabs (ws.val.map Write.abs)) ⦄ := by
  have h := plan_spec ws
  refine WP.spec_mono h ?_
  intro ss hss
  rw [hss, ← List.map_map]
  exact (plan_sound kl _ tabs hk (by simpa using hw)).1.symm

end i5h_sql.Sem
