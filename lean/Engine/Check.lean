import Std.Data.HashMap
import Engine.Proofs
import Engine.Scopes
import Engine.Lock
import Engine.Clock
import Engine.Outbox
/-!
# Exhaustive search on small instances

`next` lists the successors of a state. A new attempt may begin at any time in
the list `ts`. It is proven to be exactly `Step` for those times, so the search
explores the real protocol. `#eval` runs it on a tiny kernel.
-/

namespace Engine

variable {S W Cmd Reply Key : Type} [DecidableEq Cmd] [DecidableEq Key]

def Phase.isActive : Phase S W Cmd Reply Key → Bool
  | .active .. => true
  | _ => false

theorem idle_iff (sys : Sys S W Cmd Reply Key) :
    sys.clients.all (fun c => !c.phase.isActive) = true ↔ Idle sys := by
  simp only [List.all_eq_true, Bool.not_eq_eq_eq_not, Bool.not_true, Idle]
  constructor
  · intro h c hc snap d hph; have := h c hc; simp [hph, Phase.isActive] at this
  · intro h c hc; cases hph : c.phase <;> simp [Phase.isActive]; exact h c hc _ _ hph

/-- Successors caused by client `i`; attempts begin at the times in `ts`. -/
def moves (step : S → W → Nat → Cmd → Option (S × Reply)) (check locking mono : Bool) (ts : List Nat)
    (sys : Sys S W Cmd Reply Key) (i : Nat) (c : Client S W Cmd Reply Key) : List (Sys S W Cmd Reply Key) :=
  let set (ph : Phase S W Cmd Reply Key) : Sys S W Cmd Reply Key :=
    { sys with clients := sys.clients.set i ({ c with phase := ph }) }
  match c.phase with
  | .ready =>
    if !locking || sys.clients.all (fun c => !c.phase.isActive) then
      (ts.filter fun t => !mono || decide (lastTime sys.db.log ≤ t)).map fun t =>
        { sys with clients := sys.clients.set i ({ c with phase := .active sys.db (plan step sys.db c.req t), now := t }) }
    else []
  | .done _ => []
  | .active snap d =>
    let others : List (Sys S W Cmd Reply Key) :=
      match d with
      | .replay r => [set (.done (.ok r))]
      | .refuse => [set (.done .refused)]
      | .conflict => [set (.done .conflict)]
      | .write s r =>
        set (afterLost c.req) ::
          (if !check || decide (snap.ver = sys.db.ver) then
            [⟨sys.db.commit c.req c.now s r, sys.clients.set i ({ c with phase := .done (.ok r) })⟩,
             ⟨sys.db.commit c.req c.now s r, sys.clients.set i ({ c with phase := afterLost c.req })⟩]
          else [])
    set .ready :: others

def next (step : S → W → Nat → Cmd → Option (S × Reply)) (check locking mono : Bool) (ts : List Nat)
    (sys : Sys S W Cmd Reply Key) : List (Sys S W Cmd Reply Key) :=
  (List.range sys.clients.length).flatMap fun i =>
    match sys.clients[i]? with
    | some c => moves step check locking mono ts sys i c
    | none => []

theorem mem_next {step : S → W → Nat → Cmd → Option (S × Reply)} {check locking mono ts a b}
    (h : b ∈ next step check locking mono ts (a : Sys S W Cmd Reply Key)) : Step step check locking mono a b := by
  simp only [next, List.mem_flatMap, List.mem_range] at h
  obtain ⟨i, -, h⟩ := h
  split at h
  · rename_i c hc
    unfold moves at h
    split at h
    · split at h
      · rename_i hl
        simp only [List.mem_map, List.mem_filter] at h
        obtain ⟨t, ⟨-, ht⟩, rfl⟩ := h
        refine .begin hc (by assumption) (fun hk => (idle_iff a).1 ?_) (fun hm => ?_)
        · simpa [hk] using hl
        · simpa [hm] using ht
      · simp at h
    · simp at h
    · rename_i snap d hph
      simp only [List.mem_cons] at h
      rcases h with rfl | h
      · exact .abort hc hph
      · split at h
        · simp at h; subst h; exact .replay hc hph
        · simp at h; subst h; exact .refuse hc hph
        · simp at h; subst h; exact .conflict hc hph
        · simp only [List.mem_cons] at h
          rcases h with rfl | h
          · exact .lostBeforeCommit hc hph
          · split at h
            · rename_i hv
              simp at h
              have hv' : check → snap.ver = a.db.ver := by
                intro hc'; simpa [hc'] using hv
              rcases h with rfl | rfl
              · exact .commit hc hph hv'
              · exact .commitLost hc hph hv'
            · simp at h
  · simp at h

/-- Every step is found, if `ts` holds the times the clients hold afterwards
(in particular the time a new attempt began at). -/
theorem next_complete {step : S → W → Nat → Cmd → Option (S × Reply)} {check locking mono ts a b}
    (h : Step step check locking mono (a : Sys S W Cmd Reply Key) b) (hts : ∀ c ∈ b.clients, c.now ∈ ts) :
    b ∈ next step check locking mono ts a := by
  simp only [next, List.mem_flatMap, List.mem_range]
  cases h with
  | @begin i c t hc hr hl hm =>
    refine ⟨i, (List.getElem?_eq_some_iff.1 hc).1, ?_⟩
    have : (!locking || a.clients.all (fun c => !c.phase.isActive)) = true := by
      cases locking
      · rfl
      · simpa using (idle_iff a).2 (hl rfl)
    have ht : t ∈ ts := hts _ (List.mem_set (List.getElem?_eq_some_iff.1 hc).1 _)
    have hm' : (!mono || decide (lastTime a.db.log ≤ t)) = true := by
      cases mono
      · rfl
      · simpa using hm rfl
    simp only [hc, moves, hr, this, if_true, List.mem_map, List.mem_filter]
    exact ⟨t, ⟨ht, hm'⟩, rfl⟩
  | @replay i c snap r hc hph => exact ⟨i, (List.getElem?_eq_some_iff.1 hc).1, by simp [hc, moves, hph]⟩
  | @refuse i c snap hc hph => exact ⟨i, (List.getElem?_eq_some_iff.1 hc).1, by simp [hc, moves, hph]⟩
  | @conflict i c snap hc hph => exact ⟨i, (List.getElem?_eq_some_iff.1 hc).1, by simp [hc, moves, hph]⟩
  | @abort i c snap d hc hph =>
    refine ⟨i, (List.getElem?_eq_some_iff.1 hc).1, ?_⟩
    simp only [hc, moves, hph]
    cases d <;> simp
  | @lostBeforeCommit i c snap s r hc hph =>
    exact ⟨i, (List.getElem?_eq_some_iff.1 hc).1, by simp [hc, moves, hph]⟩
  | @commit i c snap s r hc hph hv =>
    refine ⟨i, (List.getElem?_eq_some_iff.1 hc).1, ?_⟩
    simp only [hc, moves, hph]
    cases check <;> simp_all
  | @commitLost i c snap s r hc hph hv =>
    refine ⟨i, (List.getElem?_eq_some_iff.1 hc).1, ?_⟩
    simp only [hc, moves, hph]
    cases check <;> simp_all

/-! ## Search -/

/-- Breadth-first search. Returns the number of states seen, and a path to the
first state failing `ok`, if any. -/
def search {α} [BEq α] [Hashable α] (next : α → List α) (ok : α → Bool) (start : α)
    (fuel : Nat := 1000000) : Nat × Option (List α) := Id.run do
  let mut parent : Std.HashMap α (Option α) := {}
  parent := parent.insert start none
  let mut frontier := #[start]
  let mut bad : Option α := none
  let mut f := fuel
  while f > 0 && !frontier.isEmpty && bad.isNone do
    f := f - 1
    let mut nextFrontier := #[]
    for s in frontier do
      if bad.isNone && !ok s then bad := some s
      for t in next s do
        if !parent.contains t then
          parent := parent.insert t (some s)
          nextFrontier := nextFrontier.push t
    frontier := nextFrontier
  match bad with
  | none => return (parent.size, none)
  | some b =>
    let mut path := [b]
    let mut cur := b
    let mut g := parent.size
    while g > 0 do
      g := g - 1
      match parent.get? cur with
      | some (some p) => path := p :: path; cur := p
      | _ => g := 0
    return (parent.size, some path)

/-! ## A tiny kernel: a counter capped at 3 -/

def counter (s : Nat) (_ _ : Nat) (n : Nat) : Option (Nat × Nat) :=
  if s + n ≤ 3 then some (s + n, s + n) else none

/-- Two sends of the same keyed request, plus one request without a key. -/
def reqs : List (Req Nat Nat Nat) := [⟨0, 1, some 7⟩, ⟨0, 1, some 7⟩, ⟨0, 2, none⟩]

/-! ## Scenarios: the guarded cases occur -/

/-- A keyed request whose COMMIT reply is lost retries and gets the stored
reply: one commit, and the caller sees its result. -/
theorem lost_commit_replayed : ∃ sys : Sys Nat Nat Nat Nat Nat,
    Reachable counter true true true 0 [⟨0, 1, some 7⟩] sys ∧ sys.db.log.length = 1 ∧
    sys.clients = [⟨⟨0, 1, some 7⟩, .done (.ok 1), 0⟩] :=
  ⟨_, .step (.step (.step (.step .init
    (.begin (i := 0) (t := 0) rfl rfl (fun _ => by simp [Idle, init]) (fun _ => by simp [init, initDB, lastTime])))
    (.commitLost (i := 0) rfl rfl (fun _ => rfl)))
    (.begin (i := 0) (t := 0) rfl rfl (fun _ => by simp [Idle, init, afterLost])
      (fun _ => by simp [init, initDB, DB.commit, lastTime])))
    (.replay (i := 0) rfl rfl), rfl, rfl⟩

/-- Without the conflict check, two requests decided on one snapshot both
commit and the log no longer replays to the state: `serializable` needs it. -/
theorem unchecked_lost_update : ∃ sys : Sys Nat Nat Nat Nat Nat,
    Reachable counter false false false 0 [⟨0, 1, none⟩, ⟨0, 1, none⟩] sys ∧
    run counter 0 sys.db.log ≠ some sys.db.state :=
  ⟨_, .step (.step (.step (.step .init
    (.begin (i := 0) (t := 0) rfl rfl (fun h => nomatch h) (fun h => nomatch h)))
    (.begin (i := 1) (t := 0) rfl rfl (fun h => nomatch h) (fun h => nomatch h)))
    (.commit (i := 0) rfl rfl (fun h => nomatch h)))
    (.commit (i := 1) rfl rfl (fun h => nomatch h)), by decide⟩

/-- The properties, as a check on one state. -/
def okState (sys : Sys Nat Nat Nat Nat Nat) : Bool :=
  run counter 0 sys.db.log == some sys.db.state &&
  decide (sys.db.log.filterMap (·.key)).Nodup &&
  decide ((sys.db.log.map (·.time)).Pairwise (· ≤ ·)) &&
  sys.clients.all fun c =>
    match c.req.key, c.phase with
    | some k, .done (.ok r) =>
      match stored sys.db.log k with
      | some e => e.cmd == c.req.cmd && e.reply == r
      | none => false
    | _, _ => true

/-- A compact view of a state for printing traces. -/
def brief (sys : Sys Nat Nat Nat Nat Nat) : String :=
  let ph (c : Client Nat Nat Nat Nat Nat) : String :=
    match c.phase with
    | .ready => "ready"
    | .active snap _ => s!"active@v{snap.ver}"
    | .done o => match o with
      | .ok r => s!"ok {r}" | .refused => "refused" | .conflict => "conflict" | .unknown => "unknown"
  s!"state={sys.db.state} commits={sys.db.log.length} clients={sys.clients.map ph}"

-- The real engine: exhaustive, no violation.
#eval
  let (n, cex) := search (next counter true false true [0, 1]) okState (init 0 reqs)
  s!"engine: {n} states explored, violation: {cex.isSome}"

-- Same kernel, but COMMIT skips the conflict check: a lost update.
#eval show IO Unit from do
  let two : List (Req Nat Nat Nat) := [⟨0, 1, none⟩, ⟨0, 1, none⟩]
  let (n, cex) := search (next counter false false false [0]) okState (init 0 two)
  match cex with
  | none => IO.println s!"broken engine: {n} states, no violation"
  | some path =>
    IO.println s!"broken engine: violation after {path.length - 1} steps"
    for st in path do IO.println s!"  {brief st}"

-- Only the standard axioms.
#print axioms serializable
#print axioms invariant_holds
#print axioms at_most_once
#print axioms fresh_decision
#print axioms mem_next
#print axioms next_complete
#print axioms replay_in_scope
#print axioms replay_same_actor
#print axioms rust_keys_scoped
#print axioms tenant_keys_leak
#print axioms locked_current
#print axioms locked_commit_ok
#print axioms Outbox.sent_committed
#print axioms Outbox.key_fixes_content
#print axioms Outbox.delivered_sent
#print axioms Outbox.dead_reason
#print axioms times_monotone
#print axioms clock_back
#print axioms lost_commit_replayed
#print axioms unchecked_lost_update
#print axioms Outbox.duplicate_send

end Engine
