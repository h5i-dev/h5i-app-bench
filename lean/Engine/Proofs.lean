import Engine.Model
/-!
# Properties of the protocol

With the conflict check on (`check = true`):
1. `serializable`: the committed state is the log replayed through `step`.
2. `invariant_holds`: so any invariant of `step` holds in the database.
3. `at_most_once`: each key is committed at most once, and every reply a
   caller gets under a key is the reply of that one commit.
4. `fresh_decision`: every commit was decided on the state it lands on.
-/

set_option linter.unusedSectionVars false

namespace Engine

variable {S W Cmd Reply Key : Type} [DecidableEq Cmd] [DecidableEq Key] [DecidableEq Reply]
variable {step : S → W → Cmd → Option (S × Reply)} {s₀ : S} {reqs : List (Req W Cmd Key)} {locking : Bool}

/-! ## List facts -/

theorem mem_of_mem_set {α} {l : List α} {i : Nat} {x y : α} (h : y ∈ l.set i x) : y = x ∨ y ∈ l := by
  rcases List.mem_or_eq_of_mem_set h with h | h
  · exact .inr h
  · exact .inl h

theorem stored_prefix {l₁ l₂ : List (Entry W Cmd Reply Key)} {k e} (hp : l₁ <+: l₂)
    (h : stored l₁ k = some e) : stored l₂ k = some e := by
  obtain ⟨t, rfl⟩ := hp
  simp [stored, List.find?_append] at *
  simp [h]

theorem stored_append_of_some {l : List (Entry W Cmd Reply Key)} {k e e'}
    (h : stored l k = some e) : stored (l ++ [e']) k = some e :=
  stored_prefix ⟨_, rfl⟩ h

theorem stored_append_of_none {l : List (Entry W Cmd Reply Key)} {k} {e : Entry W Cmd Reply Key}
    (h : stored l k = none) (he : e.key = some k) : stored (l ++ [e]) k = some e := by
  simp only [stored] at *
  rw [List.find?_append, h]
  simp [he]

theorem not_mem_keys_of_stored_none {l : List (Entry W Cmd Reply Key)} {k}
    (h : stored l k = none) : k ∉ l.filterMap (·.key) := by
  simp only [stored, List.find?_eq_none, decide_eq_true_eq] at h
  simp only [List.mem_filterMap, not_exists, not_and]
  intro e he hk
  exact h e he hk

/-! ## What a decision means -/

theorem decide_write {db : DB S W Cmd Reply Key} {q : Req W Cmd Key} {s r}
    (h : plan step db q = .write s r) :
    step db.state q.who q.cmd = some (s, r) ∧ ∀ k, q.key = some k → stored db.log k = none := by
  unfold plan at h
  cases hq : q.key with
  | none =>
    simp only [hq] at h
    split at h <;> simp_all
  | some k =>
    simp only [hq] at h
    split at h
    · split at h <;> simp at h
    · rename_i hs
      split at h <;> simp_all

theorem decide_replay {db : DB S W Cmd Reply Key} {q : Req W Cmd Key} {r}
    (h : plan step db q = .replay r) :
    ∃ k e, q.key = some k ∧ stored db.log k = some e ∧ e.cmd = q.cmd ∧ e.reply = r := by
  unfold plan at h
  cases hq : q.key with
  | none =>
    simp only [hq] at h
    split at h <;> simp at h
  | some k =>
    simp only [hq] at h
    split at h
    · rename_i e hs
      split at h
      · simp at h
        exact ⟨k, e, rfl, hs, by assumption, h⟩
      · simp at h
    · split at h <;> simp at h

theorem run_append (s : S) (l : List (Entry W Cmd Reply Key)) (e : Entry W Cmd Reply Key) :
    run step s (l ++ [e]) = (run step s l).bind (fun t =>
      match step t e.who e.cmd with
      | some (t', r) => if r = e.reply then some t' else none
      | none => none) := by
  induction l generalizing s with
  | nil => simp only [run, List.nil_append, Option.bind_some]; split <;> simp_all
  | cons x xs ih =>
    simp only [run, List.cons_append]
    split
    · split <;> simp_all
    · simp

/-! ## The invariant -/

structure Good (step : S → W → Cmd → Option (S × Reply)) (s₀ : S) (sys : Sys S W Cmd Reply Key) : Prop where
  run_ok : run step s₀ sys.db.log = some sys.db.state
  ver_len : sys.db.ver = sys.db.log.length
  keys : (sys.db.log.filterMap (·.key)).Nodup
  active : ∀ c ∈ sys.clients, ∀ snap d, c.phase = .active snap d →
    d = plan step snap c.req ∧ snap.log <+: sys.db.log ∧ snap.ver = snap.log.length ∧
    (snap.ver = sys.db.ver → snap = sys.db)
  done : ∀ c ∈ sys.clients, ∀ k r, c.req.key = some k → c.phase = .done (.ok r) →
    ∃ e, stored sys.db.log k = some e ∧ e.cmd = c.req.cmd ∧ e.reply = r

theorem good_init : Good step s₀ (init s₀ reqs : Sys S W Cmd Reply Key) := by
  constructor <;> simp [init, initDB, run]

/-- Committing a write decided on the current database keeps `Good`. -/
theorem good_commit {sys : Sys S W Cmd Reply Key} {i c s r} (ph : Phase S W Cmd Reply Key)
    (g : Good step s₀ sys) (hc : sys.clients[i]? = some c)
    (hd : step sys.db.state c.req.who c.req.cmd = some (s, r))
    (hk : ∀ k, c.req.key = some k → stored sys.db.log k = none)
    (hph : ∀ r', ph = .done (.ok r') → r' = r) (hna : ∀ snap d, ph ≠ .active snap d) :
    Good step s₀ ⟨sys.db.commit c.req s r, sys.clients.set i ({ c with phase := ph })⟩ := by
  have hmem := List.mem_of_getElem? hc
  constructor
  · simp [DB.commit, run_append, g.run_ok, hd]
  · simp [DB.commit, g.ver_len]
  · cases hq : c.req.key with
    | none => simpa [DB.commit, hq] using g.keys
    | some k =>
      have hk' := not_mem_keys_of_stored_none (hk _ hq)
      simp only [DB.commit, List.filterMap_append, hq, List.filterMap_cons, List.filterMap_nil]
      exact List.nodup_append.2 ⟨g.keys, by simp, by
        simp only [List.mem_singleton, ne_eq, List.mem_filterMap]
        rintro a ⟨x, hx, hxa⟩ b rfl rfl
        exact hk' (List.mem_filterMap.2 ⟨x, hx, hxa⟩)⟩
  · intro c' hc' snap d hph'
    rcases mem_of_mem_set hc' with rfl | hc'
    · exact absurd hph' (hna snap d)
    · obtain ⟨h1, h2, h3, _⟩ := g.active c' hc' snap d hph'
      have hle : snap.log.length ≤ sys.db.log.length := h2.length_le
      refine ⟨h1, h2.trans ⟨_, rfl⟩, h3, ?_⟩
      intro hv
      simp [DB.commit, g.ver_len] at hv
      omega
  · intro c' hc' k r' hk' hph'
    rcases mem_of_mem_set hc' with rfl | hc'
    · simp only at hph' hk'
      have := hph r' hph'
      subst this
      exact ⟨_, stored_append_of_none (hk k hk') (by simp [hk']), rfl, rfl⟩
    · obtain ⟨e, he, h1, h2⟩ := g.done c' hc' k r' hk' hph'
      exact ⟨e, stored_append_of_some he, h1, h2⟩

/-- Changing one client's phase without touching the database keeps `Good`,
if the new phase adds no obligation that does not already hold. -/
theorem good_set {sys : Sys S W Cmd Reply Key} {i c} (ph : Phase S W Cmd Reply Key)
    (g : Good step s₀ sys) (_hc : sys.clients[i]? = some c)
    (ha : ∀ snap d, ph = .active snap d →
      d = plan step snap c.req ∧ snap.log <+: sys.db.log ∧ snap.ver = snap.log.length ∧
      (snap.ver = sys.db.ver → snap = sys.db))
    (hd : ∀ k r, c.req.key = some k → ph = .done (.ok r) →
      ∃ e, stored sys.db.log k = some e ∧ e.cmd = c.req.cmd ∧ e.reply = r) :
    Good step s₀ { sys with clients := sys.clients.set i ({ c with phase := ph }) } := by
  refine ⟨g.run_ok, g.ver_len, g.keys, ?_, ?_⟩
  · intro c' hc' snap d hph'
    rcases mem_of_mem_set hc' with rfl | hc'
    · exact ha snap d hph'
    · exact g.active c' hc' snap d hph'
  · intro c' hc' k r hk hph'
    rcases mem_of_mem_set hc' with rfl | hc'
    · exact hd k r hk hph'
    · exact g.done c' hc' k r hk hph'

theorem good_step {a b : Sys S W Cmd Reply Key} (g : Good step s₀ a) (h : Step step true locking a b) :
    Good step s₀ b := by
  cases h with
  | @begin i c hc hr _ =>
    refine good_set _ g hc ?_ (by simp)
    intro snap d hph
    simp only [Phase.active.injEq] at hph
    obtain ⟨rfl, rfl⟩ := hph
    exact ⟨rfl, List.prefix_refl _, g.ver_len, fun _ => rfl⟩
  | @replay i c snap r hc hph =>
    refine good_set _ g hc (by simp) ?_
    intro k r' hk hr'
    simp only [Phase.done.injEq, Outcome.ok.injEq] at hr'
    subst hr'
    obtain ⟨hd, hp, -, -⟩ := g.active c (List.mem_of_getElem? hc) snap _ hph
    obtain ⟨k', e, hk', he, h1, h2⟩ := decide_replay hd.symm
    rw [hk] at hk'
    cases hk'
    exact ⟨e, stored_prefix hp he, h1, h2⟩
  | @refuse i c snap hc hph => exact good_set _ g hc (by simp) (by simp)
  | @conflict i c snap hc hph => exact good_set _ g hc (by simp) (by simp)
  | @abort i c snap d hc hph => exact good_set _ g hc (by simp) (by simp)
  | @lostBeforeCommit i c snap s r hc hph =>
    exact good_set _ g hc (by unfold afterLost; split <;> simp) (by unfold afterLost; split <;> simp)
  | @commit i c snap s r hc hph hv =>
    obtain ⟨hd, -, -, hsnap⟩ := g.active c (List.mem_of_getElem? hc) snap _ hph
    have := hsnap (hv rfl)
    subst this
    obtain ⟨h1, h2⟩ := decide_write hd.symm
    exact good_commit _ g hc h1 h2 (by simp) (by simp)
  | @commitLost i c snap s r hc hph hv =>
    obtain ⟨hd, -, -, hsnap⟩ := g.active c (List.mem_of_getElem? hc) snap _ hph
    have := hsnap (hv rfl)
    subst this
    obtain ⟨h1, h2⟩ := decide_write hd.symm
    exact good_commit _ g hc h1 h2 (by unfold afterLost; split <;> simp) (by unfold afterLost; split <;> simp)

theorem good_of_reachable {sys : Sys S W Cmd Reply Key} (h : Reachable step true locking s₀ reqs sys) :
    Good step s₀ sys := by
  induction h with
  | init => exact good_init
  | step _ hs ih => exact good_step ih hs

/-! ## Main theorems -/

/-- The committed state is the committed log replayed through the kernel. -/
theorem serializable {sys : Sys S W Cmd Reply Key} (h : Reachable step true locking s₀ reqs sys) :
    run step s₀ sys.db.log = some sys.db.state :=
  (good_of_reachable h).run_ok

theorem run_inv (Inv : S → Prop) (hstep : ∀ s w c s' r, Inv s → step s w c = some (s', r) → Inv s') :
    ∀ (l : List (Entry W Cmd Reply Key)) s t, Inv s → run step s l = some t → Inv t := by
  intro l
  induction l with
  | nil => intro s t hs h; simp [run] at h; exact h ▸ hs
  | cons e es ih =>
    intro s t hs h
    simp only [run] at h
    split at h
    · rename_i s' r hst
      split at h
      · exact ih s' t (hstep _ _ _ _ _ hs hst) h
      · simp at h
    · simp at h

/-- Any invariant the kernel preserves holds in every reachable database. -/
theorem invariant_holds (Inv : S → Prop) (hstep : ∀ s w c s' r, Inv s → step s w c = some (s', r) → Inv s')
    (h0 : Inv s₀) {sys : Sys S W Cmd Reply Key} (h : Reachable step true locking s₀ reqs sys) :
    Inv sys.db.state :=
  run_inv Inv hstep _ _ _ h0 (serializable h)

/-- Each key commits at most once, and callers under a key only ever see the
reply of that commit. -/
theorem at_most_once {sys : Sys S W Cmd Reply Key} (h : Reachable step true locking s₀ reqs sys) :
    (sys.db.log.filterMap (·.key)).Nodup ∧
    ∀ c ∈ sys.clients, ∀ k r, c.req.key = some k → c.phase = .done (.ok r) →
      ∃ e, stored sys.db.log k = some e ∧ e.cmd = c.req.cmd ∧ e.reply = r :=
  let g := good_of_reachable h
  ⟨g.keys, g.done⟩

/-- Every commit was decided on the state it is applied to: no stale decision
survives a retry. -/
theorem fresh_decision {a b : Sys S W Cmd Reply Key} (h : Reachable step true locking s₀ reqs a)
    (hs : Step step true locking a b) (hne : b.db ≠ a.db) :
    ∃ e, b.db.log = a.db.log ++ [e] ∧ step a.db.state e.who e.cmd = some (b.db.state, e.reply) := by
  have g := good_of_reachable h
  cases hs with
  | @commit i c snap s r hc hph hv =>
    obtain ⟨hd, -, -, hsnap⟩ := g.active c (List.mem_of_getElem? hc) snap _ hph
    have := hsnap (hv rfl); subst this
    exact ⟨⟨c.req.who, c.req.cmd, c.req.key, r⟩, rfl, (decide_write hd.symm).1⟩
  | @commitLost i c snap s r hc hph hv =>
    obtain ⟨hd, -, -, hsnap⟩ := g.active c (List.mem_of_getElem? hc) snap _ hph
    have := hsnap (hv rfl); subst this
    exact ⟨⟨c.req.who, c.req.cmd, c.req.key, r⟩, rfl, (decide_write hd.symm).1⟩
  | _ => exact absurd rfl hne

end Engine
