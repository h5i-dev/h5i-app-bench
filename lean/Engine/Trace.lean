import Lean.Data.Json
import Engine.Check
/-!
# Checking recorded engine runs against the model

The Rust engine (`Engine::with_trace`) emits one event per protocol step. This
file replays such a trace through the model: every event must be a `Step` from
some state the model can be in. Successors come only from `next`, which is
proven equal to `Step`, so an accepted trace is a run of the model
(`check_sound`).

Instantiation: the state is the commit count, actors are idempotency scopes
(empty without a key), commands are fingerprints (or `req<id>` without a key),
replies are hex strings. The kernel is read off the trace's `kernel` events,
and must be a function of (version, actor, command).

Event order: the engine emits events from several connections, so the recorded
order can differ from the database order. Events are sorted into bands by the
versions they carry: `begin v` sits after the commit that made version `v`,
`commit w` just before version `w` is visible. Other events stay right after
their request's `begin`. Steps of different clients that touch nothing shared
commute, so this loses nothing.
-/

namespace Engine.Trace

open Lean

abbrev St := Sys Nat String String String String

inductive Ev where
  | start (who cmd : String) (key : Option String)
  | begin (ver : Nat)
  | kernel (ver : Nat) (write : Bool) (reply : String)
  | replay (reply : String)
  | conflict
  | refuse
  | commit (ver : Nat) (reply : String)
  | lost (ver : Nat)
  | abort
  deriving Repr, BEq, Inhabited

structure Rec where
  tenant : Nat
  req : Nat
  seq : Nat
  ev : Ev
  deriving Repr, Inhabited

def parseLine (seq : Nat) (s : String) : Except String Rec := do
  let j ← Json.parse s
  let tag ← j.getObjValAs? String "ev"
  let tenant ← j.getObjValAs? Nat "tenant"
  let req ← j.getObjValAs? Nat "req"
  let str (f : String) := j.getObjValAs? String f
  let nat (f : String) := j.getObjValAs? Nat f
  let ev : Ev ← match tag with
    | "start" => pure (.start (← str "who") (← str "cmd") (str "key").toOption)
    | "begin" => pure (.begin (← nat "ver"))
    | "kernel" => pure (.kernel (← nat "ver") (← j.getObjValAs? Bool "write") (← str "reply"))
    | "replay" => pure (.replay (← str "reply"))
    | "conflict" => pure .conflict
    | "refuse" => pure .refuse
    | "commit" => pure (.commit (← nat "ver") (← str "reply"))
    | "lost" => pure (.lost (← nat "ver"))
    | "abort" => pure .abort
    | t => throw s!"unknown event {t}"
  return ⟨tenant, req, seq, ev⟩

/-! ## The kernel, as observed -/

/-- `(version, actor, command) ↦ reply` for writes; absent means refused. -/
abbrev Table := List ((Nat × String × String) × Option String)

def kstep (t : Table) (s : Nat) (w c : String) : Option (Nat × String) :=
  match t.lookup (s, w, c) with
  | some (some r) => some (s + 1, r)
  | _ => none

/-- Build the table; the kernel must give one verdict per (version, actor, command). -/
def table (cmds : List (Nat × String × String)) (recs : List Rec) : Except String Table :=
  recs.foldlM (init := []) fun t r =>
    match r.ev with
    | .kernel v w reply =>
      match cmds.lookup r.req with
      | none => throw s!"kernel event for unknown request {r.req}"
      | some c =>
        let verdict := if w then some reply else none
        match t.lookup (v, c) with
        | none => pure (((v, c), verdict) :: t)
        | some old =>
          if old == verdict then pure t
          else throw s!"kernel not deterministic at version {v} for request {r.req}"
    | _ => pure t

/-! ## One event, as a model step -/

/-- Does `b` follow from `a` by client `i` doing `ev`? -/
def fits (i : Nat) (ev : Ev) (a b : St) : Bool :=
  match a.clients[i]?, b.clients[i]? with
  | some ca, some cb =>
    decide (ca.phase ≠ cb.phase) &&
    match ev, ca.phase, cb.phase with
    | .begin v, .ready, .active snap _ => snap.ver == v
    | .replay r, .active _ (.replay _), .done (.ok r') => r == r' && b.db == a.db
    | .conflict, .active _ .conflict, .done .conflict => true
    | .refuse, .active _ .refuse, .done .refused => true
    | .commit w r, .active _ (.write _ _), .done (.ok r') => r == r' && b.db.ver == w
    | .lost _, .active _ (.write _ _), p => p == afterLost ca.req
    | .abort, .active _ _, .ready => b.db == a.db
    | _, _, _ => false
  | _, _ => false

/-- Events that are not model steps only filter: `kernel` must see the attempt's snapshot. -/
def keep (i : Nat) (ev : Ev) (a : St) : Bool :=
  match ev, a.clients[i]? with
  | .kernel v _ _, some c =>
    match c.phase with
    | .active snap _ => snap.ver == v
    | _ => false
  | .start .., _ => true
  | _, _ => false

def isStep : Ev → Bool
  | .start .. | .kernel .. => false
  | _ => true

def advance (step : Nat → String → String → Option (Nat × String)) (i : Nat) (ev : Ev) (xs : List St) : List St :=
  if isStep ev then
    (xs.flatMap fun a => (next step true false a).filter (fits i ev a)).eraseDups
  else xs.filter (keep i ev)

theorem advance_sound {step : Nat → String → String → Option (Nat × String)} {reqs i ev xs}
    (h : ∀ a ∈ xs, Reachable step true false 0 reqs a) :
    ∀ b ∈ advance step i ev xs, Reachable step true false 0 reqs b := by
  intro b hb
  unfold advance at hb
  split at hb
  · rw [List.mem_eraseDups, List.mem_flatMap] at hb
    obtain ⟨a, ha, hb⟩ := hb
    exact .step (h a ha) (mem_next (List.mem_filter.1 hb).1)
  · exact h b (List.mem_filter.1 hb).1

def replay (step : Nat → String → String → Option (Nat × String)) (idx : List (Nat × Nat)) :
    List Rec → List St → Except String (List St)
  | [], xs => pure xs
  | r :: rs, xs =>
    match idx.lookup r.req with
    | none => throw s!"event for unknown request {r.req}"
    | some i =>
      let ys := advance step i r.ev xs
      if ys.isEmpty then throw s!"request {r.req}: {repr r.ev} is not a model step here (seq {r.seq})"
      else replay step idx rs ys

theorem replay_sound {step : Nat → String → String → Option (Nat × String)} {reqs idx recs xs ys}
    (h : ∀ a ∈ xs, Reachable step true false 0 reqs a) (hr : replay step idx recs xs = .ok ys) :
    ∀ b ∈ ys, Reachable step true false 0 reqs b := by
  induction recs generalizing xs with
  | nil => simp only [replay, pure, Except.pure, Except.ok.injEq] at hr; subst hr; exact h
  | cons r rs ih =>
    simp only [replay] at hr
    split at hr
    · simp at hr
    · split at hr
      · simp at hr
      · exact ih (advance_sound h) hr

/-! ## Ordering -/

/-- A lost COMMIT from snapshot `v` landed iff version `v + 1` shows up with no
`commit` event producing it. -/
def landed (recs : List Rec) (v : Nat) : Bool :=
  let seen := recs.any fun r => match r.ev with
    | .begin w | .commit w _ | .lost w => decide (v + 1 ≤ w)
    | _ => false
  let made := recs.any fun r => match r.ev with
    | .commit w _ => w == v + 1
    | _ => false
  seen && !made

/-- Sort into version bands, keeping each request's own order. -/
def linearize (recs : List Rec) : List Rec := Id.run do
  let mut last : List (Nat × Nat) := []
  let mut keyed : Array (Nat × Nat × Rec) := #[]
  for r in recs do
    let band := match r.ev with
      | .start .. => 0
      | .begin v => 2 * v + 2
      | .commit w _ => 2 * w + 1
      -- Landed: it made version v + 1. Otherwise a local step of its attempt.
      | .lost v => if landed recs v then 2 * v + 3 else 2 * v + 2
      | _ => 2 * (last.lookup r.req).getD 0 + 2
    if let .begin v := r.ev then last := (r.req, v) :: last
    keyed := keyed.push (band, r.seq, r)
  let sorted := keyed.qsort fun (b₁, s₁, _) (b₂, s₂, _) => b₁ < b₂ || (b₁ == b₂ && s₁ < s₂)
  return sorted.toList.map (·.2.2)

/-! ## A whole tenant -/

structure Report where
  events : Nat
  requests : Nat
  commits : Nat
  states : Nat

/-- The properties proven for all reachable states, evaluated on the final ones. -/
def final (step : Nat → String → String → Option (Nat × String)) (sys : St) : Bool :=
  run step 0 sys.db.log == some sys.db.state &&
  decide (sys.db.log.filterMap (·.key)).Nodup

def checkTenant (recs : List Rec) : Except String Report := do
  let starts := recs.filterMap fun r =>
    match r.ev with
    | .start w c k => some (r.req, (⟨w, c, k⟩ : Req String String String))
    | _ => none
  let reqs := starts.map (·.2)
  let idx := (starts.map (·.1)).zipIdx
  let cmds := starts.map fun (q, rq) => (q, (rq.who, rq.cmd))
  let t ← table cmds recs
  let step := kstep t
  let ys ← replay step idx (linearize recs) [init 0 reqs]
  unless ys.all (final step) do throw "a final state breaks serializability or at-most-once"
  let commits := recs.countP fun r => match r.ev with | .commit .. => true | _ => false
  return ⟨recs.length, reqs.length, commits, ys.length⟩

/-- Accepted traces are runs of the model. -/
theorem check_sound {reqs : List (Req String String String)} {step idx recs ys}
    (hr : replay step idx recs [init 0 reqs] = .ok ys) :
    ∀ b ∈ ys, Reachable step true false 0 reqs b :=
  replay_sound (fun a ha => by simp at ha; subst ha; exact .init) hr

end Engine.Trace
