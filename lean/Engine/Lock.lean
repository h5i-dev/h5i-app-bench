import Engine.Proofs
/-!
# The tenant lock

`Engine` takes a per-tenant session advisory lock before `BEGIN` and releases
it after the attempt, so attempts on one tenant never overlap. In the model
(`locking = true`), an attempt begins only when no other is active.

- `locked_current`: every active attempt's snapshot is the current database.
- `locked_commit_ok`: so COMMIT's conflict check never fails; under the lock,
  retries come only from aborts (lost connections, deadlocks elsewhere).

Correctness does not rest on the lock (`serializable` holds without it); it
removes serialization failures within a tenant.
-/

set_option linter.unusedSectionVars false

namespace Engine

variable {S W Cmd Reply Key : Type} [DecidableEq Cmd] [DecidableEq Key]
variable {step : S → W → Cmd → Option (S × Reply)} {s₀ : S} {reqs : List (Req W Cmd Key)} {check : Bool}

/-- At most one attempt is active, and it read the current database. -/
def LockInv (sys : Sys S W Cmd Reply Key) : Prop :=
  ∀ (i : Nat) (c : Client S W Cmd Reply Key) snap d, sys.clients[i]? = some c → c.phase = .active snap d →
    snap = sys.db ∧ ∀ (j : Nat) (c' : Client S W Cmd Reply Key), j ≠ i → sys.clients[j]? = some c' →
      ∀ snap' d', c'.phase ≠ .active snap' d'

theorem getElem?_set_ne' {α} {l : List α} {i j : Nat} {x : α} (h : j ≠ i) : (l.set i x)[j]? = l[j]? := by
  rw [List.getElem?_set]; simp [Ne.symm h]

theorem getElem?_set_self' {α} {l : List α} {i : Nat} {x y : α} (h : l[i]? = some y) : (l.set i x)[i]? = some x := by
  rw [List.getElem?_set]; simp [(List.getElem?_eq_some_iff.1 h).1]

/-- Client `i` leaves its attempt: no one is active afterwards. -/
theorem lockInv_leave {sys : Sys S W Cmd Reply Key} (g : LockInv sys) {i c snap d}
    (hc : sys.clients[i]? = some c) (hph : c.phase = .active snap d) (db : DB S W Cmd Reply Key)
    (ph : Phase S W Cmd Reply Key) (hna : ∀ snap d, ph ≠ .active snap d) :
    LockInv (⟨db, sys.clients.set i { c with phase := ph }⟩ : Sys S W Cmd Reply Key) := by
  intro j c' snap' d' hj hph'
  by_cases hji : j = i
  · subst hji
    rw [getElem?_set_self' hc] at hj
    cases hj
    exact absurd hph' (hna _ _)
  · rw [getElem?_set_ne' hji] at hj
    exact absurd hph' ((g i c snap d hc hph).2 j c' hji hj snap' d')

theorem lockInv_step {a b : Sys S W Cmd Reply Key} (g : LockInv a) (h : Step step check true a b) :
    LockInv b := by
  cases h with
  | @begin i c hc hr hl =>
    have hidle := hl rfl
    intro j c' snap' d' hj hph'
    by_cases hji : j = i
    · subst hji
      rw [getElem?_set_self' hc] at hj
      cases hj
      simp only [Phase.active.injEq] at hph'
      refine ⟨hph'.1.symm, fun k c'' hk hc'' snap'' d'' => ?_⟩
      rw [getElem?_set_ne' hk] at hc''
      exact hidle c'' (List.mem_of_getElem? hc'') snap'' d''
    · rw [getElem?_set_ne' hji] at hj
      exact absurd hph' (hidle c' (List.mem_of_getElem? hj) snap' d')
  | @replay i c snap r hc hph => exact lockInv_leave g hc hph _ _ (by simp)
  | @refuse i c snap hc hph => exact lockInv_leave g hc hph _ _ (by simp)
  | @conflict i c snap hc hph => exact lockInv_leave g hc hph _ _ (by simp)
  | @abort i c snap d hc hph => exact lockInv_leave g hc hph _ _ (by simp)
  | @commit i c snap s r hc hph _ => exact lockInv_leave g hc hph _ _ (by simp)
  | @commitLost i c snap s r hc hph _ =>
    exact lockInv_leave g hc hph _ _ (by unfold afterLost; split <;> simp)
  | @lostBeforeCommit i c snap s r hc hph =>
    exact lockInv_leave g hc hph _ _ (by unfold afterLost; split <;> simp)

theorem lockInv_reachable {sys : Sys S W Cmd Reply Key} (h : Reachable step check true s₀ reqs sys) :
    LockInv sys := by
  induction h with
  | init => intro i c snap d hc hph; simp [init] at hc; obtain ⟨_, _, rfl⟩ := hc; simp at hph
  | step _ hs ih => exact lockInv_step ih hs

/-- Under the lock, every active attempt read the current database. -/
theorem locked_current {sys : Sys S W Cmd Reply Key} (h : Reachable step check true s₀ reqs sys) :
    ∀ c ∈ sys.clients, ∀ snap d, c.phase = .active snap d → snap = sys.db := by
  intro c hc snap d hph
  obtain ⟨i, hi⟩ := List.getElem?_of_mem hc
  exact (lockInv_reachable h i c snap d hi hph).1

/-- Under the lock, COMMIT's conflict check always passes. -/
theorem locked_commit_ok {sys : Sys S W Cmd Reply Key} (h : Reachable step check true s₀ reqs sys) :
    ∀ c ∈ sys.clients, ∀ snap s r, c.phase = .active snap (.write s r) → snap.ver = sys.db.ver := by
  intro c hc snap s r hph
  rw [locked_current h c hc snap _ hph]

end Engine
