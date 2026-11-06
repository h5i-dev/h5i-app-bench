import AtuinKernel
import H5iAppLib
/-!
# atuin's sync server: the policy

Stated from atuin-server's code and comments at df152cd (`router.rs`
`UserAuth`, `handlers/user.rs`, `handlers/v0/record.rs`, `db/mod.rs` and the
SQLite migrations), over plain lists. Nothing here calls the kernel's
functions; the theorems in `Properties.lean` relate the extracted kernel to
these definitions.
-/
open Aeneas Aeneas.Std atuin_kernel

namespace atuin_kernel.Spec

/-- The bytes of an ASCII literal. -/
def lit (s : String) : List Nat := s.toList.map Char.toNat

/-- A byte string as numbers. -/
def nats (v : List U8) : List Nat := v.map (·.val)

/-! ## Authentication -/

/-- `HeaderValue::to_str` accepts the value: every byte is visible ASCII or a tab. -/
def visibleAscii (h : List U8) : Bool :=
  h.all (fun c => decide (c.val = 9) || (decide (32 ≤ c.val) && decide (c.val < 127)))

/-- The session token an `Authorization` header presents: the value is
`Token ` followed by the token (`split_once(' ')` then `typ == "Token"`). -/
def presentedToken : Option (alloc.vec.Vec U8) → Option (List U8)
  | none => none
  | some v => if visibleAscii v.val = true ∧ nats (v.val.take 6) = lit "Token " then some (v.val.drop 6) else none

/-- `u` is the user of the session that holds token `t` (`GET_SESSION_USER`). -/
def SessionOf (s : Snapshot) (t : List U8) (u : User) : Prop :=
  u ∈ s.users.val ∧ ∃ x ∈ s.sessions.val, x.token.val = t ∧ x.user_id = u.id

/-- The request's header authenticates it as `u`. -/
def Authenticated (s : Snapshot) (h : Option (alloc.vec.Vec U8)) (u : User) : Prop :=
  ∃ t, presentedToken h = some t ∧ SessionOf s t u

/-- `HashedPassword::verify(hash, pw)`, by the crypto table. -/
def Verify (c : Crypto) (hash pw : List U8) : Prop :=
  ∃ v ∈ c.verified.val, v.hash.val = hash ∧ v.password.val = pw

instance (c : Crypto) (hash pw : List U8) : Decidable (Verify c hash pw) := by unfold Verify; infer_instance

/-! ## Registration -/

/-- SQLite's `LOWER` on one byte (ASCII letters only). -/
def lowerN (n : Nat) : Nat := if 65 ≤ n ∧ n ≤ 90 then n + 32 else n

/-- `LOWER(a) = LOWER(b)`. -/
def LowerEq (a b : List U8) : Prop := a.map (fun c => lowerN c.val) = b.map (fun c => lowerN c.val)

instance (a b : List U8) : Decidable (LowerEq a b) := by unfold LowerEq; infer_instance

/-- A letter, digit or `-`. -/
def nameChar (c : U8) : Bool :=
  (decide (97 ≤ c.val) && decide (c.val ≤ 122)) || (decide (65 ≤ c.val) && decide (c.val ≤ 90)) ||
    (decide (48 ≤ c.val) && decide (c.val ≤ 57)) || decide (c.val = 45)

/-- `NewUsername`: non-empty letters, digits and hyphens. -/
def ValidUsername (u : List U8) : Prop := u ≠ [] ∧ ∀ c ∈ u, nameChar c = true

instance (u : List U8) : Decidable (ValidUsername u) := by unfold ValidUsername; infer_instance

/-- No `users` or `sessions` constraint stops the insert: `UNIQUE(username)`,
`UNIQUE(email)`, `UNIQUE(password)`, `UNIQUE(LOWER(username))`,
`UNIQUE(LOWER(email))`, `sessions.token UNIQUE`. -/
def Fresh (s : Snapshot) (uname email hash token : List U8) : Prop :=
  (∀ x ∈ s.users.val, ¬ LowerEq x.username.val uname ∧ ¬ LowerEq x.email.val email ∧ x.password.val ≠ hash) ∧
  (∀ x ∈ s.sessions.val, x.token.val ≠ token)

/-! ## Records -/

/-- `len <= max || max == 0`. -/
def Fits (max : U64) (r : RecordIn) : Prop := r.data.val.length ≤ max.val ∨ max.val = 0

instance (max : U64) (r : RecordIn) : Decidable (Fits max r) := by unfold Fits; infer_instance

/-- The row `ADD_RECORDS` inserts for user `uid`. -/
def rowOf (uid : U64) (r : RecordIn) : StoreRow :=
  { user_id := uid, client_id := r.client_id, host := r.host, idx := r.idx, timestamp := r.timestamp,
    version := r.version, tag := r.tag, data := r.data, cek := r.cek }

/-- A user's rows of the store. -/
def ownRows (s : Snapshot) (uid : U64) : List StoreRow := s.store.val.filter (fun r => r.user_id = uid)

/-- A user's sessions. -/
def ownSessions (s : Snapshot) (uid : U64) : List Session := s.sessions.val.filter (fun x => x.user_id = uid)

/-- A user's legacy history rows. -/
def ownHistory (s : Snapshot) (uid : U64) : List HistoryRow := s.history.val.filter (fun x => x.user_id = uid)

/-! ## The write policy

For each kind of write, when a request may make it, judged against the
state before the request. -/

def allowed (cfg : Config) (c : Crypto) (s : Snapshot) (req : Request) : Write → Prop
  | .AddUser u => ∃ uname email hash token,
      req.command = .Register uname email hash token ∧ cfg.open_registration = true ∧
      ValidUsername uname.val ∧ Fresh s uname.val email.val hash.val token.val ∧
      u = { id := s.next_user_id, username := uname, email := email, password := hash }
  | .AddSession x => ∃ uname email hash token,
      req.command = .Register uname email hash token ∧ cfg.open_registration = true ∧
      ValidUsername uname.val ∧ Fresh s uname.val email.val hash.val token.val ∧
      x = { id := s.next_session_id, user_id := s.next_user_id, token := token }
  | .SetPassword uid hash => ∃ u, Authenticated s req.authorization u ∧ uid = u.id ∧
      ∃ cur, req.command = .ChangePassword cur hash ∧ Verify c u.password.val cur.val ∧
      ∀ x ∈ s.users.val, x.id ≠ u.id → x.password.val ≠ hash.val
  | .DeleteUser uid => ∃ u, Authenticated s req.authorization u ∧ uid = u.id ∧
      ∃ pw, req.command = .DeleteAccount pw ∧ Verify c u.password.val pw.val
  | .InsertRecord row => ∃ u, Authenticated s req.authorization u ∧
      ∃ rs, req.command = .PostRecords rs ∧ (∀ r ∈ rs.val, Fits cfg.max_record_size r) ∧
      ∃ r ∈ rs.val, row = rowOf u.id r
  | .DeleteStore uid => ∃ u, Authenticated s req.authorization u ∧ uid = u.id ∧
      req.command = .DeleteStore

/-- The user a write belongs to. -/
def Write.owner : Write → U64
  | .AddUser u => u.id
  | .AddSession x => x.user_id
  | .SetPassword uid _ => uid
  | .DeleteUser uid => uid
  | .InsertRecord r => r.user_id
  | .DeleteStore uid => uid

/-! ## Reachable states -/

/-- The empty database: AUTOINCREMENT starts at 1. -/
def empty : Snapshot :=
  { users := alloc.vec.Vec.new User, sessions := alloc.vec.Vec.new Session,
    history := alloc.vec.Vec.new HistoryRow, store := alloc.vec.Vec.new StoreRow,
    next_user_id := 1#u64, next_session_id := 1#u64 }

/-- The states the server reaches from an empty database, one successful
request (under any settings and any verification table) at a time. -/
inductive Reachable : Snapshot → Prop
  | init : Reachable empty
  | step {s s' : Snapshot} {cfg : Config} {c : Crypto} {req : Request} {ws : alloc.vec.Vec Write} {r : Reply} :
      Reachable s → transition cfg c s req = .ok (.Ok (ws, r)) → apply s ws = .ok s' → Reachable s'

/-- What holds in every reachable state. -/
structure Inv (s : Snapshot) : Prop where
  user_ids_below : ∀ u ∈ s.users.val, u.id.val < s.next_user_id.val
  session_ids_below : ∀ x ∈ s.sessions.val, x.id.val < s.next_session_id.val
  sessions_owned : ∀ x ∈ s.sessions.val, ∃ u ∈ s.users.val, u.id = x.user_id
  store_owned : ∀ r ∈ s.store.val, ∃ u ∈ s.users.val, u.id = r.user_id
  history_owned : ∀ h ∈ s.history.val, ∃ u ∈ s.users.val, u.id = h.user_id
  tokens_unique : (s.sessions.val.map (fun x => x.token.val)).Nodup
  user_ids_unique : (s.users.val.map (fun u => u.id)).Nodup

end atuin_kernel.Spec
