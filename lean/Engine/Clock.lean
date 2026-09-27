import Engine.Proofs
/-!
# Time

Each attempt reads the clock when it begins and the kernel decides at that
time. With the `monotonic` option the engine also keeps, per tenant, the time
of the latest commit and never begins an attempt earlier than it (`mono`).

- `times_monotone`: with the conflict check and `mono`, committed times never
  decrease in commit order, whatever the clock reads.
- `clock_back`: without `mono`, a clock that goes back commits a later request
  at an earlier time, even under the tenant lock.
-/

set_option linter.unusedSectionVars false

namespace Engine

variable {S W Cmd Reply Key : Type} [DecidableEq Cmd] [DecidableEq Key] [DecidableEq Reply]
variable {step : S → W → Nat → Cmd → Option (S × Reply)} {s₀ : S} {reqs : List (Req W Cmd Key)}
  {locking : Bool}

theorem le_foldl_max (l : List (Entry W Cmd Reply Key)) (m : Nat) :
    m ≤ l.foldl (fun m e => max m e.time) m := by
  induction l generalizing m with
  | nil => exact Nat.le_refl _
  | cons e es ih => exact Nat.le_trans (Nat.le_max_left _ _) (ih _)

theorem le_lastTime {l : List (Entry W Cmd Reply Key)} {e} (h : e ∈ l) : e.time ≤ lastTime l := by
  unfold lastTime
  generalize 0 = m
  induction l generalizing m with
  | nil => simp at h
  | cons x xs ih =>
    simp only [List.foldl_cons]
    rcases List.mem_cons.1 h with rfl | h
    · exact Nat.le_trans (Nat.le_max_right _ _) (le_foldl_max _ _)
    · exact ih h _

/-- Committed times are sorted, and every attempt began no earlier than the
commits in its snapshot. -/
structure MonoInv (sys : Sys S W Cmd Reply Key) : Prop where
  sorted : (sys.db.log.map (·.time)).Pairwise (· ≤ ·)
  active : ∀ c ∈ sys.clients, ∀ snap d, c.phase = .active snap d → lastTime snap.log ≤ c.now

/-- Replacing a client by one that is not in an attempt keeps `MonoInv`, for
any sorted log. -/
theorem mono_set {sys : Sys S W Cmd Reply Key} {i} (c : Client S W Cmd Reply Key) (db : DB S W Cmd Reply Key)
    (m : MonoInv sys) (hs : (db.log.map (·.time)).Pairwise (· ≤ ·)) (hna : ∀ snap d, c.phase ≠ .active snap d) :
    MonoInv (⟨db, sys.clients.set i c⟩ : Sys S W Cmd Reply Key) := by
  refine ⟨hs, fun c' hc' snap d hph => ?_⟩
  rcases mem_of_mem_set hc' with rfl | hc'
  · exact absurd hph (hna _ _)
  · exact m.active c' hc' snap d hph

/-- The log after a commit decided at time `t`, no earlier than the log's commits, stays sorted. -/
theorem sorted_commit {db : DB S W Cmd Reply Key} {q t s r} (hs : (db.log.map (·.time)).Pairwise (· ≤ ·))
    (ht : lastTime db.log ≤ t) : ((db.commit q t s r).log.map (·.time)).Pairwise (· ≤ ·) := by
  simp only [DB.commit, List.map_append, List.map_cons, List.map_nil]
  refine List.pairwise_append.2 ⟨hs, List.pairwise_singleton _ _, ?_⟩
  intro a ha b hb
  obtain ⟨e, he, rfl⟩ := List.mem_map.1 ha
  rw [List.mem_singleton.1 hb]
  exact Nat.le_trans (le_lastTime he) ht

theorem mono_step {a b : Sys S W Cmd Reply Key} (g : Good step s₀ a) (m : MonoInv a)
    (h : Step step true locking true a b) : MonoInv b := by
  cases h with
  | @begin i c t hc hr _ ht =>
    refine ⟨m.sorted, fun c' hc' snap d hph => ?_⟩
    rcases mem_of_mem_set hc' with rfl | hc'
    · simp only [Phase.active.injEq] at hph
      rw [← hph.1]
      exact ht rfl
    · exact m.active c' hc' snap d hph
  | @replay i c snap r hc hph => exact mono_set _ _ m m.sorted (by simp)
  | @refuse i c snap hc hph => exact mono_set _ _ m m.sorted (by simp)
  | @conflict i c snap hc hph => exact mono_set _ _ m m.sorted (by simp)
  | @abort i c snap d hc hph => exact mono_set _ _ m m.sorted (by simp)
  | @lostBeforeCommit i c snap s r hc hph =>
    exact mono_set _ _ m m.sorted (by unfold afterLost; split <;> simp)
  | @commit i c snap s r hc hph hv =>
    have hsnap := (g.active c (List.mem_of_getElem? hc) snap _ hph).2.2.2 (hv rfl)
    have ht := m.active c (List.mem_of_getElem? hc) snap _ hph
    rw [hsnap] at ht
    exact mono_set _ _ m (sorted_commit m.sorted ht) (by simp)
  | @commitLost i c snap s r hc hph hv =>
    have hsnap := (g.active c (List.mem_of_getElem? hc) snap _ hph).2.2.2 (hv rfl)
    have ht := m.active c (List.mem_of_getElem? hc) snap _ hph
    rw [hsnap] at ht
    exact mono_set _ _ m (sorted_commit m.sorted ht) (by unfold afterLost; split <;> simp)

theorem mono_of_reachable {sys : Sys S W Cmd Reply Key} (h : Reachable step true locking true s₀ reqs sys) :
    Good step s₀ sys ∧ MonoInv sys := by
  induction h with
  | init =>
    refine ⟨good_init, by simp [init, initDB], fun c hc snap d hph => ?_⟩
    simp only [init, List.mem_map] at hc
    obtain ⟨q, -, rfl⟩ := hc
    simp at hph
  | step _ hs ih => exact ⟨good_step ih.1 hs, mono_step ih.1 ih.2 hs⟩

/-- With `mono`, committed times never decrease in commit order. -/
theorem times_monotone {sys : Sys S W Cmd Reply Key} (h : Reachable step true locking true s₀ reqs sys) :
    (sys.db.log.map (·.time)).Pairwise (· ≤ ·) :=
  (mono_of_reachable h).2.sorted

/-! ## Without `mono`: time goes back -/

/-- A kernel that counts commits and replies with the time it decided at. -/
def tick (s : Nat) (_ : Nat) (t : Nat) (_ : Nat) : Option (Nat × Nat) := some (s + 1, t)

/-- Two requests without keys. -/
def tickReqs : List (Req Nat Nat Nat) := [⟨1, 0, none⟩, ⟨2, 0, none⟩]

/-- The first request reads 5 and commits; the clock then reads 3, and the
second request commits at 3, after a commit at 5. The lock and the conflict
check are on. -/
theorem clock_back : ∃ sys : Sys Nat Nat Nat Nat Nat, Reachable tick true true false 0 tickReqs sys ∧
    ¬ (sys.db.log.map (·.time)).Pairwise (· ≤ ·) := by
  let q1 : Req Nat Nat Nat := ⟨1, 0, none⟩
  let q2 : Req Nat Nat Nat := ⟨2, 0, none⟩
  let db1 : DB Nat Nat Nat Nat Nat := (initDB 0).commit q1 5 1 5
  let db2 : DB Nat Nat Nat Nat Nat := db1.commit q2 3 2 3
  have s1 : Step tick true true false (init 0 tickReqs : Sys Nat Nat Nat Nat Nat)
      ⟨initDB 0, [⟨q1, .active (initDB 0) (.write 1 5), 5⟩, ⟨q2, .ready, 0⟩]⟩ :=
    .begin (i := 0) (c := ⟨q1, .ready, 0⟩) (t := 5) rfl rfl (fun _ => by simp [Idle, init])
      (fun h => nomatch h)
  have s2 : Step tick true true false
      (⟨initDB 0, [⟨q1, .active (initDB 0) (.write 1 5), 5⟩, ⟨q2, .ready, 0⟩]⟩ : Sys Nat Nat Nat Nat Nat)
      ⟨db1, [⟨q1, .done (.ok 5), 5⟩, ⟨q2, .ready, 0⟩]⟩ :=
    .commit (i := 0) (c := ⟨q1, .active (initDB 0) (.write 1 5), 5⟩) rfl rfl (fun _ => rfl)
  have s3 : Step tick true true false (⟨db1, [⟨q1, .done (.ok 5), 5⟩, ⟨q2, .ready, 0⟩]⟩ : Sys Nat Nat Nat Nat Nat)
      ⟨db1, [⟨q1, .done (.ok 5), 5⟩, ⟨q2, .active db1 (.write 2 3), 3⟩]⟩ :=
    .begin (i := 1) (c := ⟨q2, .ready, 0⟩) (t := 3) rfl rfl (fun _ => by simp [Idle]) (fun h => nomatch h)
  have s4 : Step tick true true false
      (⟨db1, [⟨q1, .done (.ok 5), 5⟩, ⟨q2, .active db1 (.write 2 3), 3⟩]⟩ : Sys Nat Nat Nat Nat Nat)
      ⟨db2, [⟨q1, .done (.ok 5), 5⟩, ⟨q2, .done (.ok 3), 3⟩]⟩ :=
    .commit (i := 1) (c := ⟨q2, .active db1 (.write 2 3), 3⟩) rfl rfl (fun _ => rfl)
  exact ⟨_, .step (.step (.step (.step .init s1) s2) s3) s4, by decide⟩

end Engine
