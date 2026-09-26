/-!
# The i5h-pg engine protocol

One tenant, many clients. Each client runs one request through the engine:
BEGIN, read the snapshot (state and idempotency table), decide, then COMMIT or
retry. The kernel is an arbitrary function `step` of the state, the actor
(`who`) and the command.

Modeling choices:
- A snapshot is the whole database at some version. COMMIT succeeds only if no
  other commit happened since the snapshot. This is stricter than PostgreSQL
  SERIALIZABLE, which is the property we rely on.
- `abort` covers serialization failures, deadlocks, and connections lost
  before COMMIT. It can happen at any time.
- `commitLost` is a COMMIT that reached the server but whose reply was lost.
  `lostBeforeCommit` is a COMMIT that never reached it. The client cannot tell
  them apart: with a key it retries, without one it reports `unknown`.
- A repeated key is matched on the command alone (its fingerprint), not the
  actor, as in the Rust engine. Keys must therefore name their scope
  (`Engine.Scopes`).
- `locking` adds the per-tenant session lock: an attempt begins only when no
  other attempt is active (`Engine.Lock`).
-/

namespace Engine

/-- A committed request. -/
structure Entry (W Cmd Reply Key : Type) where
  who : W
  cmd : Cmd
  key : Option Key
  reply : Reply
  deriving DecidableEq, Repr, Hashable

/-- The database of one tenant. `ver` counts commits; `log` is ghost state. -/
structure DB (S W Cmd Reply Key : Type) where
  state : S
  ver : Nat
  log : List (Entry W Cmd Reply Key)
  deriving DecidableEq, Repr, Hashable

structure Req (W Cmd Key : Type) where
  who : W
  cmd : Cmd
  key : Option Key
  deriving DecidableEq, Repr, Hashable

inductive Decision (S Reply : Type) where
  | replay (r : Reply)
  | conflict
  | refuse
  | write (s : S) (r : Reply)
  deriving DecidableEq, Repr, Hashable

/-- What the caller finally sees. -/
inductive Outcome (Reply : Type) where
  | ok (r : Reply)
  | refused
  | conflict
  | unknown
  deriving DecidableEq, Repr, Hashable

inductive Phase (S W Cmd Reply Key : Type) where
  | ready
  | active (snap : DB S W Cmd Reply Key) (d : Decision S Reply)
  | done (o : Outcome Reply)
  deriving DecidableEq, Repr, Hashable

structure Client (S W Cmd Reply Key : Type) where
  req : Req W Cmd Key
  phase : Phase S W Cmd Reply Key
  deriving DecidableEq, Repr, Hashable

structure Sys (S W Cmd Reply Key : Type) where
  db : DB S W Cmd Reply Key
  clients : List (Client S W Cmd Reply Key)
  deriving DecidableEq, Repr, Hashable

variable {S W Cmd Reply Key : Type} [DecidableEq Cmd] [DecidableEq Key]

/-- The idempotency table: the first committed entry with key `k`. -/
def stored (log : List (Entry W Cmd Reply Key)) (k : Key) : Option (Entry W Cmd Reply Key) :=
  log.find? (fun e => e.key = some k)

/-- What the engine decides inside one attempt, from its snapshot. -/
def plan (step : S → W → Cmd → Option (S × Reply)) (db : DB S W Cmd Reply Key) (q : Req W Cmd Key) :
    Decision S Reply :=
  let fresh : Decision S Reply :=
    match step db.state q.who q.cmd with
    | some (s, r) => .write s r
    | none => .refuse
  match q.key with
  | none => fresh
  | some k =>
    match stored db.log k with
    | some e => if e.cmd = q.cmd then .replay e.reply else .conflict
    | none => fresh

/-- The database after committing `q` with new state `s` and reply `r`. -/
def DB.commit (db : DB S W Cmd Reply Key) (q : Req W Cmd Key) (s : S) (r : Reply) : DB S W Cmd Reply Key :=
  { state := s, ver := db.ver + 1, log := db.log ++ [⟨q.who, q.cmd, q.key, r⟩] }

/-- After a lost COMMIT reply: retry under a key, else report `unknown`. -/
def afterLost (q : Req W Cmd Key) : Phase S W Cmd Reply Key :=
  if q.key.isSome then .ready else .done .unknown

/-- No attempt is in progress: the tenant lock is free. -/
def Idle (sys : Sys S W Cmd Reply Key) : Prop :=
  ∀ c ∈ sys.clients, ∀ snap d, c.phase ≠ .active snap d

/-- Protocol steps. `check = false` drops the conflict check at COMMIT (a
broken engine). `locking = true` holds the tenant lock for a whole attempt. -/
inductive Step (step : S → W → Cmd → Option (S × Reply)) (check locking : Bool) :
    Sys S W Cmd Reply Key → Sys S W Cmd Reply Key → Prop
  | begin {sys i c} : sys.clients[i]? = some c → c.phase = .ready → (locking → Idle sys) →
      Step step check locking sys
        ({ sys with clients := sys.clients.set i ({ c with phase := .active sys.db (plan step sys.db c.req) }) })
  | replay {sys i c snap r} : sys.clients[i]? = some c → c.phase = .active snap (.replay r) →
      Step step check locking sys ({ sys with clients := sys.clients.set i ({ c with phase := .done (.ok r) }) })
  | refuse {sys i c snap} : sys.clients[i]? = some c → c.phase = .active snap .refuse →
      Step step check locking sys ({ sys with clients := sys.clients.set i ({ c with phase := .done .refused }) })
  | conflict {sys i c snap} : sys.clients[i]? = some c → c.phase = .active snap .conflict →
      Step step check locking sys ({ sys with clients := sys.clients.set i ({ c with phase := .done .conflict }) })
  | abort {sys i c snap d} : sys.clients[i]? = some c → c.phase = .active snap d →
      Step step check locking sys ({ sys with clients := sys.clients.set i ({ c with phase := .ready }) })
  | commit {sys i c snap s r} : sys.clients[i]? = some c → c.phase = .active snap (.write s r) →
      (check → snap.ver = sys.db.ver) →
      Step step check locking sys
        ⟨sys.db.commit c.req s r, sys.clients.set i ({ c with phase := .done (.ok r) })⟩
  | commitLost {sys i c snap s r} : sys.clients[i]? = some c → c.phase = .active snap (.write s r) →
      (check → snap.ver = sys.db.ver) →
      Step step check locking sys
        ⟨sys.db.commit c.req s r, sys.clients.set i ({ c with phase := afterLost c.req })⟩
  | lostBeforeCommit {sys i c snap s r} : sys.clients[i]? = some c → c.phase = .active snap (.write s r) →
      Step step check locking sys ({ sys with clients := sys.clients.set i ({ c with phase := afterLost c.req }) })

def initDB (s₀ : S) : DB S W Cmd Reply Key := ⟨s₀, 0, []⟩

def init (s₀ : S) (reqs : List (Req W Cmd Key)) : Sys S W Cmd Reply Key :=
  ⟨initDB s₀, reqs.map (fun q => ⟨q, .ready⟩)⟩

inductive Reachable (step : S → W → Cmd → Option (S × Reply)) (check locking : Bool) (s₀ : S)
    (reqs : List (Req W Cmd Key)) : Sys S W Cmd Reply Key → Prop
  | init : Reachable step check locking s₀ reqs (init s₀ reqs)
  | step {a b} : Reachable step check locking s₀ reqs a → Step step check locking a b →
      Reachable step check locking s₀ reqs b

/-- Replaying the committed log from the initial state, checking each reply. -/
def run [DecidableEq Reply] (step : S → W → Cmd → Option (S × Reply)) :
    S → List (Entry W Cmd Reply Key) → Option S
  | s, [] => some s
  | s, e :: es =>
    match step s e.who e.cmd with
    | some (s', r) => if r = e.reply then run step s' es else none
    | none => none

end Engine
