/-!
# The i5h-pg engine protocol

One tenant, many clients. Each client runs one request through the engine:
BEGIN, read the snapshot (state and idempotency table), decide, then COMMIT or
retry. The kernel is an arbitrary function `step`.

Modeling choices:
- A snapshot is the whole database at some version. COMMIT succeeds only if no
  other commit happened since the snapshot. This is stricter than PostgreSQL
  SERIALIZABLE, which is the property we rely on.
- `abort` covers serialization failures, deadlocks, and connections lost
  before COMMIT. It can happen at any time.
- `commitLost` is a COMMIT that reached the server but whose reply was lost.
  `lostBeforeCommit` is a COMMIT that never reached it. The client cannot tell
  them apart: with a key it retries, without one it reports `unknown`.
-/

namespace Engine

/-- A committed request. -/
structure Entry (Cmd Reply Key : Type) where
  cmd : Cmd
  key : Option Key
  reply : Reply
  deriving DecidableEq, Repr, Hashable

/-- The database of one tenant. `ver` counts commits; `log` is ghost state. -/
structure DB (S Cmd Reply Key : Type) where
  state : S
  ver : Nat
  log : List (Entry Cmd Reply Key)
  deriving DecidableEq, Repr, Hashable

structure Req (Cmd Key : Type) where
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

inductive Phase (S Cmd Reply Key : Type) where
  | ready
  | active (snap : DB S Cmd Reply Key) (d : Decision S Reply)
  | done (o : Outcome Reply)
  deriving DecidableEq, Repr, Hashable

structure Client (S Cmd Reply Key : Type) where
  req : Req Cmd Key
  phase : Phase S Cmd Reply Key
  deriving DecidableEq, Repr, Hashable

structure Sys (S Cmd Reply Key : Type) where
  db : DB S Cmd Reply Key
  clients : List (Client S Cmd Reply Key)
  deriving DecidableEq, Repr, Hashable

variable {S Cmd Reply Key : Type} [DecidableEq Cmd] [DecidableEq Key]

/-- The idempotency table: the first committed entry with key `k`. -/
def stored (log : List (Entry Cmd Reply Key)) (k : Key) : Option (Entry Cmd Reply Key) :=
  log.find? (fun e => e.key = some k)

/-- What the engine decides inside one attempt, from its snapshot. -/
def plan (step : S → Cmd → Option (S × Reply)) (db : DB S Cmd Reply Key) (q : Req Cmd Key) :
    Decision S Reply :=
  let fresh : Decision S Reply :=
    match step db.state q.cmd with
    | some (s, r) => .write s r
    | none => .refuse
  match q.key with
  | none => fresh
  | some k =>
    match stored db.log k with
    | some e => if e.cmd = q.cmd then .replay e.reply else .conflict
    | none => fresh

/-- The database after committing `q` with new state `s` and reply `r`. -/
def DB.commit (db : DB S Cmd Reply Key) (q : Req Cmd Key) (s : S) (r : Reply) : DB S Cmd Reply Key :=
  { state := s, ver := db.ver + 1, log := db.log ++ [⟨q.cmd, q.key, r⟩] }

/-- After a lost COMMIT reply: retry under a key, else report `unknown`. -/
def afterLost (q : Req Cmd Key) : Phase S Cmd Reply Key :=
  if q.key.isSome then .ready else .done .unknown

/-- Protocol steps. `check = false` drops the conflict check at COMMIT (a broken engine). -/
inductive Step (step : S → Cmd → Option (S × Reply)) (check : Bool) :
    Sys S Cmd Reply Key → Sys S Cmd Reply Key → Prop
  | begin {sys i c} : sys.clients[i]? = some c → c.phase = .ready →
      Step step check sys
        ({ sys with clients := sys.clients.set i ({ c with phase := .active sys.db (plan step sys.db c.req) }) })
  | replay {sys i c snap r} : sys.clients[i]? = some c → c.phase = .active snap (.replay r) →
      Step step check sys ({ sys with clients := sys.clients.set i ({ c with phase := .done (.ok r) }) })
  | refuse {sys i c snap} : sys.clients[i]? = some c → c.phase = .active snap .refuse →
      Step step check sys ({ sys with clients := sys.clients.set i ({ c with phase := .done .refused }) })
  | conflict {sys i c snap} : sys.clients[i]? = some c → c.phase = .active snap .conflict →
      Step step check sys ({ sys with clients := sys.clients.set i ({ c with phase := .done .conflict }) })
  | abort {sys i c snap d} : sys.clients[i]? = some c → c.phase = .active snap d →
      Step step check sys ({ sys with clients := sys.clients.set i ({ c with phase := .ready }) })
  | commit {sys i c snap s r} : sys.clients[i]? = some c → c.phase = .active snap (.write s r) →
      (check → snap.ver = sys.db.ver) →
      Step step check sys
        ⟨sys.db.commit c.req s r, sys.clients.set i ({ c with phase := .done (.ok r) })⟩
  | commitLost {sys i c snap s r} : sys.clients[i]? = some c → c.phase = .active snap (.write s r) →
      (check → snap.ver = sys.db.ver) →
      Step step check sys
        ⟨sys.db.commit c.req s r, sys.clients.set i ({ c with phase := afterLost c.req })⟩
  | lostBeforeCommit {sys i c snap s r} : sys.clients[i]? = some c → c.phase = .active snap (.write s r) →
      Step step check sys ({ sys with clients := sys.clients.set i ({ c with phase := afterLost c.req }) })

def initDB (s₀ : S) : DB S Cmd Reply Key := ⟨s₀, 0, []⟩

def init (s₀ : S) (reqs : List (Req Cmd Key)) : Sys S Cmd Reply Key :=
  ⟨initDB s₀, reqs.map (fun q => ⟨q, .ready⟩)⟩

inductive Reachable (step : S → Cmd → Option (S × Reply)) (check : Bool) (s₀ : S)
    (reqs : List (Req Cmd Key)) : Sys S Cmd Reply Key → Prop
  | init : Reachable step check s₀ reqs (init s₀ reqs)
  | step {a b} : Reachable step check s₀ reqs a → Step step check a b → Reachable step check s₀ reqs b

/-- Replaying the committed log from the initial state, checking each reply. -/
def run [DecidableEq Reply] (step : S → Cmd → Option (S × Reply)) :
    S → List (Entry Cmd Reply Key) → Option S
  | s, [] => some s
  | s, e :: es =>
    match step s e.cmd with
    | some (s', r) => if r = e.reply then run step s' es else none
    | none => none

end Engine
