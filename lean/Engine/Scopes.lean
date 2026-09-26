import Engine.Proofs
/-!
# Idempotency keys and scopes

The engine matches a repeated key on the command's fingerprint, not on who
sent it. So a key must name its scope: otherwise a user who reuses another
user's key and command gets that user's stored reply.

- `replay_in_scope`: if requests with the same key share a scope, a caller
  under a key only ever sees a reply committed in its own scope.
- `rust_keys_scoped`: the Rust engine's keys (`scope/key`, with `/` refused in
  scopes) have that property.
- `tenant_keys_leak`: with keys scoped by tenant only, a reachable run hands
  one user another user's reply, even under the tenant lock.
-/

set_option linter.unusedSectionVars false

namespace Engine

variable {S W Cmd Reply Key : Type} [DecidableEq Cmd] [DecidableEq Key] [DecidableEq Reply]
variable {step : S → W → Cmd → Option (S × Reply)} {s₀ : S} {reqs : List (Req W Cmd Key)}
  {check locking : Bool}

theorem map_req_set (l : List (Client S W Cmd Reply Key)) (i : Nat) (c : Client S W Cmd Reply Key)
    (hc : l[i]? = some c) (ph : Phase S W Cmd Reply Key) :
    (l.set i { c with phase := ph }).map (·.req) = l.map (·.req) := by
  rw [List.map_set]
  apply List.ext_getElem?
  intro j
  rw [List.getElem?_set]
  by_cases hj : i = j
  · subst hj
    obtain ⟨hlt, he⟩ := List.getElem?_eq_some_iff.1 hc
    simp [hlt, he]
  · simp [hj]

/-- Requests never change. -/
theorem reqs_const {sys : Sys S W Cmd Reply Key} (h : Reachable step check locking s₀ reqs sys) :
    sys.clients.map (·.req) = reqs := by
  induction h with
  | init => simp [init, Function.comp_def]
  | step _ hs ih =>
    cases hs <;> simp only [map_req_set _ _ _ ‹_› _, ih]

/-- Every committed entry comes from some request. -/
theorem log_origin {sys : Sys S W Cmd Reply Key} (h : Reachable step check locking s₀ reqs sys) :
    ∀ e ∈ sys.db.log, (⟨e.who, e.cmd, e.key⟩ : Req W Cmd Key) ∈ reqs := by
  induction h with
  | init => simp [init, initDB]
  | @step a b ha hs ih =>
    have hq : ∀ i (c : Client S W Cmd Reply Key), a.clients[i]? = some c → c.req ∈ reqs := fun i c hc => by
      rw [← reqs_const ha]; exact List.mem_map.2 ⟨c, List.mem_of_getElem? hc, rfl⟩
    cases hs with
    | @commit i c snap s r hc _ _ =>
      intro e he
      simp only [DB.commit, List.mem_append, List.mem_singleton] at he
      rcases he with he | rfl
      · exact ih e he
      · exact hq i c hc
    | @commitLost i c snap s r hc _ _ =>
      intro e he
      simp only [DB.commit, List.mem_append, List.mem_singleton] at he
      rcases he with he | rfl
      · exact ih e he
      · exact hq i c hc
    | _ => exact ih

/-- Requests that share a key share a scope. -/
def KeysScoped {Sc : Type} (scope : W → Sc) (reqs : List (Req W Cmd Key)) : Prop :=
  ∀ q ∈ reqs, ∀ q' ∈ reqs, ∀ k, q.key = some k → q'.key = some k → scope q.who = scope q'.who

/-- A caller under a key only ever sees a reply committed, for the same
command, by a request in its own scope. -/
theorem replay_in_scope {Sc : Type} (scope : W → Sc) (hk : KeysScoped scope reqs)
    {sys : Sys S W Cmd Reply Key} (h : Reachable step true locking s₀ reqs sys) :
    ∀ c ∈ sys.clients, ∀ k r, c.req.key = some k → c.phase = .done (.ok r) →
      ∃ e ∈ sys.db.log, e.key = some k ∧ e.cmd = c.req.cmd ∧ e.reply = r ∧ scope e.who = scope c.req.who := by
  intro c hc k r hck hph
  obtain ⟨e, he, h1, h2⟩ := (at_most_once h).2 c hc k r hck hph
  have hmem : e ∈ sys.db.log := List.mem_of_find?_eq_some he
  have hek : e.key = some k := by simpa using List.find?_some he
  have hq : c.req ∈ reqs := by rw [← reqs_const h]; exact List.mem_map.2 ⟨c, hc, rfl⟩
  exact ⟨e, hmem, hek, h1, h2, hk _ (log_origin h e hmem) _ hq k hek hck⟩

/-- When a scope names one actor, the reply came from the kernel running
this very actor's command. -/
theorem replay_same_actor {Sc : Type} (scope : W → Sc) (hinj : Function.Injective scope)
    (hk : KeysScoped scope reqs) {sys : Sys S W Cmd Reply Key} (h : Reachable step true locking s₀ reqs sys) :
    ∀ c ∈ sys.clients, ∀ k r, c.req.key = some k → c.phase = .done (.ok r) →
      ∃ e ∈ sys.db.log, e.key = some k ∧ e.who = c.req.who ∧ e.cmd = c.req.cmd ∧ e.reply = r := by
  intro c hc k r hck hph
  obtain ⟨e, hm, h1, h2, h3, h4⟩ := replay_in_scope scope hk h c hc k r hck hph
  exact ⟨e, hm, h1, hinj h4, h2, h3⟩

/-! ## The Rust engine's keys -/

/-- `Engine::execute_idempotent` stores key `k` of a user as `scope ++ "/" ++ k`. -/
def rustKey (scope k : String) : String := scope ++ "/" ++ k

theorem slash_split {a b c d : List Char} (ha : '/' ∉ a) (hb : '/' ∉ b)
    (h : a ++ '/' :: c = b ++ '/' :: d) : a = b := by
  induction a generalizing b with
  | nil =>
    cases b with
    | nil => rfl
    | cons x xs => simp at h; exact absurd (List.mem_cons_self ..) (h.1 ▸ hb)
  | cons x xs ih =>
    cases b with
    | nil => simp at h; exact absurd (List.mem_cons_self ..) (h.1 ▸ ha)
    | cons y ys =>
      simp only [List.cons_append, List.cons.injEq] at h
      rw [h.1, ih (fun hm => ha (List.mem_cons_of_mem _ hm)) (fun hm => hb (List.mem_cons_of_mem _ hm)) h.2]

theorem rustKey_scope {s s' k k' : String} (hs : '/' ∉ s.toList) (hs' : '/' ∉ s'.toList)
    (h : rustKey s k = rustKey s' k') : s = s' := by
  have := congrArg String.toList h
  simp only [rustKey, String.toList_append] at this
  have e := slash_split hs hs' (by simpa using this)
  exact String.ext e

/-- Keys built as `rustKey (scope who) k`, with no `/` in any scope, are scoped. -/
theorem rust_keys_scoped {reqs : List (Req W Cmd String)} (scope : W → String)
    (hs : ∀ w, '/' ∉ (scope w).toList)
    (hk : ∀ q ∈ reqs, ∀ k, q.key = some k → ∃ raw, k = rustKey (scope q.who) raw) :
    KeysScoped scope reqs := by
  intro q hq q' hq' k h1 h2
  obtain ⟨r, rfl⟩ := hk q hq k h1
  obtain ⟨r', hr'⟩ := hk q' hq' _ h2
  exact rustKey_scope (hs _) (hs _) hr'

/-! ## Without scopes: a leak -/

/-- A kernel whose reply is the caller's own data (here, its id). -/
def leakStep (s : Nat) (w : Nat) (_ : Nat) : Option (Nat × Nat) := some (s + 1, w)

/-- Users 1 and 2 send the same command under the same key. -/
def leakReqs : List (Req Nat Nat Nat) := [⟨1, 0, some 7⟩, ⟨2, 0, some 7⟩]

/-- With keys scoped by tenant only, user 2 receives user 1's reply, even
with the tenant lock and the conflict check on. -/
theorem tenant_keys_leak : ∃ sys : Sys Nat Nat Nat Nat Nat, Reachable leakStep true true 0 leakReqs sys ∧
    ∃ c ∈ sys.clients, c.req.who = 2 ∧ c.phase = .done (.ok 1) := by
  let q1 : Req Nat Nat Nat := ⟨1, 0, some 7⟩
  let q2 : Req Nat Nat Nat := ⟨2, 0, some 7⟩
  let db1 : DB Nat Nat Nat Nat Nat := (initDB 0).commit q1 1 1
  refine ⟨⟨db1, [⟨q1, .done (.ok 1)⟩, ⟨q2, .done (.ok 1)⟩]⟩, ?_, ⟨q2, .done (.ok 1)⟩, by simp, rfl, rfl⟩
  have s1 : Step leakStep true true (init 0 leakReqs : Sys Nat Nat Nat Nat Nat)
      ⟨initDB 0, [⟨q1, .active (initDB 0) (.write 1 1)⟩, ⟨q2, .ready⟩]⟩ :=
    .begin (i := 0) (c := ⟨q1, .ready⟩) rfl rfl (fun _ => by simp [Idle, init])
  have s2 : Step leakStep true true
      (⟨initDB 0, [⟨q1, .active (initDB 0) (.write 1 1)⟩, ⟨q2, .ready⟩]⟩ : Sys Nat Nat Nat Nat Nat)
      ⟨db1, [⟨q1, .done (.ok 1)⟩, ⟨q2, .ready⟩]⟩ :=
    .commit (i := 0) (c := ⟨q1, .active (initDB 0) (.write 1 1)⟩) rfl rfl (fun _ => rfl)
  have s3 : Step leakStep true true (⟨db1, [⟨q1, .done (.ok 1)⟩, ⟨q2, .ready⟩]⟩ : Sys Nat Nat Nat Nat Nat)
      ⟨db1, [⟨q1, .done (.ok 1)⟩, ⟨q2, .active db1 (.replay 1)⟩]⟩ :=
    .begin (i := 1) (c := ⟨q2, .ready⟩) rfl rfl (fun _ => by simp [Idle])
  have s4 : Step leakStep true true
      (⟨db1, [⟨q1, .done (.ok 1)⟩, ⟨q2, .active db1 (.replay 1)⟩]⟩ : Sys Nat Nat Nat Nat Nat)
      ⟨db1, [⟨q1, .done (.ok 1)⟩, ⟨q2, .done (.ok 1)⟩]⟩ :=
    .replay (i := 1) (c := ⟨q2, .active db1 (.replay 1)⟩) rfl rfl
  exact .step (.step (.step (.step .init s1) s2) s3) s4

end Engine
