import Std.Data.HashMap
import Engine.Proofs
/-!
# Exhaustive search on small instances

`next` lists the successors of a state. It is proven to be exactly `Step`, so
the search explores the real protocol. `#eval` runs it on a tiny kernel.
-/

namespace Engine

variable {S Cmd Reply Key : Type} [DecidableEq Cmd] [DecidableEq Key]

/-- Successors caused by client `i`. -/
def moves (step : S → Cmd → Option (S × Reply)) (check : Bool) (sys : Sys S Cmd Reply Key)
    (i : Nat) (c : Client S Cmd Reply Key) : List (Sys S Cmd Reply Key) :=
  let set (ph : Phase S Cmd Reply Key) : Sys S Cmd Reply Key :=
    { sys with clients := sys.clients.set i ({ c with phase := ph }) }
  match c.phase with
  | .ready => [set (.active sys.db (plan step sys.db c.req))]
  | .done _ => []
  | .active snap d =>
    let others : List (Sys S Cmd Reply Key) :=
      match d with
      | .replay r => [set (.done (.ok r))]
      | .refuse => [set (.done .refused)]
      | .conflict => [set (.done .conflict)]
      | .write s r =>
        set (afterLost c.req) ::
          (if !check || decide (snap.ver = sys.db.ver) then
            [⟨sys.db.commit c.req s r, sys.clients.set i ({ c with phase := .done (.ok r) })⟩,
             ⟨sys.db.commit c.req s r, sys.clients.set i ({ c with phase := afterLost c.req })⟩]
          else [])
    set .ready :: others

def next (step : S → Cmd → Option (S × Reply)) (check : Bool) (sys : Sys S Cmd Reply Key) :
    List (Sys S Cmd Reply Key) :=
  (List.range sys.clients.length).flatMap fun i =>
    match sys.clients[i]? with
    | some c => moves step check sys i c
    | none => []

theorem mem_next {step : S → Cmd → Option (S × Reply)} {check a b}
    (h : b ∈ next step check (a : Sys S Cmd Reply Key)) : Step step check a b := by
  simp only [next, List.mem_flatMap, List.mem_range] at h
  obtain ⟨i, -, h⟩ := h
  split at h
  · rename_i c hc
    unfold moves at h
    split at h
    · simp at h; subst h; exact .begin hc (by assumption)
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

theorem next_complete {step : S → Cmd → Option (S × Reply)} {check a b}
    (h : Step step check (a : Sys S Cmd Reply Key) b) : b ∈ next step check a := by
  simp only [next, List.mem_flatMap, List.mem_range]
  cases h with
  | @begin i c hc hr => exact ⟨i, (List.getElem?_eq_some_iff.1 hc).1, by simp [hc, moves, hr]⟩
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

def counter (s : Nat) (n : Nat) : Option (Nat × Nat) :=
  if s + n ≤ 3 then some (s + n, s + n) else none

/-- Two sends of the same keyed request, plus one request without a key. -/
def reqs : List (Req Nat Nat) := [⟨1, some 7⟩, ⟨1, some 7⟩, ⟨2, none⟩]

/-- The properties, as a check on one state. -/
def okState (sys : Sys Nat Nat Nat Nat) : Bool :=
  run counter 0 sys.db.log == some sys.db.state &&
  decide (sys.db.log.filterMap (·.key)).Nodup &&
  sys.clients.all fun c =>
    match c.req.key, c.phase with
    | some k, .done (.ok r) =>
      match stored sys.db.log k with
      | some e => e.cmd == c.req.cmd && e.reply == r
      | none => false
    | _, _ => true

/-- A compact view of a state for printing traces. -/
def brief (sys : Sys Nat Nat Nat Nat) : String :=
  let ph (c : Client Nat Nat Nat Nat) : String :=
    match c.phase with
    | .ready => "ready"
    | .active snap _ => s!"active@v{snap.ver}"
    | .done o => match o with
      | .ok r => s!"ok {r}" | .refused => "refused" | .conflict => "conflict" | .unknown => "unknown"
  s!"state={sys.db.state} commits={sys.db.log.length} clients={sys.clients.map ph}"

-- The real engine: exhaustive, no violation.
#eval
  let (n, cex) := search (next counter true) okState (init 0 reqs)
  s!"engine: {n} states explored, violation: {cex.isSome}"

-- Same kernel, but COMMIT skips the conflict check: a lost update.
#eval show IO Unit from do
  let two : List (Req Nat Nat) := [⟨1, none⟩, ⟨1, none⟩]
  let (n, cex) := search (next counter false) okState (init 0 two)
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

end Engine
