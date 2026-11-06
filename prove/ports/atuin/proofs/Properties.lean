import Verified.Effects
/-!
# atuin's sync server: the security properties

Each theorem is about the extracted kernel (`transition`, `apply`, ...) and is
stated with the definitions of `Spec.lean`. The proofs are in `Verified/`.
-/
open Aeneas Aeneas.Std Result atuin_kernel atuin_kernel.Spec
open H5iAppLib hiding lit

namespace atuin_kernel.Properties

/-! ## Writes -/

/-- Every write of a successful request is allowed by `Spec.allowed`: a
registration only on an open server, with a valid, unused name and a fresh
token; a password change or account deletion only for the authenticated
user and after their current password verifies; records only into the
authenticated user's own store, each within the size limit; a store
deletion only of the authenticated user's own store. -/
theorem authorized (cfg : Config) (c : Crypto) (s : Snapshot) (req : Request)
    (ws : alloc.vec.Vec Write) (rep : Reply)
    (h : transition cfg c s req = ok (.Ok (ws, rep))) :
    ∀ w ∈ ws.val, allowed cfg c s req w :=
  Verified.authorized cfg c s req ws rep h

/-- A request whose header does not authenticate any user writes nothing,
unless it is a registration. -/
theorem unauthenticated_never_writes (cfg : Config) (c : Crypto) (s : Snapshot) (req : Request)
    (ws : alloc.vec.Vec Write) (rep : Reply)
    (hnone : ∀ u, ¬ Authenticated s req.authorization u)
    (hreg : ∀ n e hh t, req.command ≠ .Register n e hh t)
    (h : transition cfg c s req = ok (.Ok (ws, rep))) : ws.val = [] := by
  rcases Verified.transition_writes h with ⟨n, e, hh, t, hc, _⟩ | ⟨u, hu, _⟩ | h0
  · exact absurd hc (hreg n e hh t)
  · exact absurd hu (hnone u)
  · exact h0

/-- Apart from registration, every write belongs to the user the request
authenticates as: nobody writes into another user's account or store. -/
theorem writes_owned (cfg : Config) (c : Crypto) (s : Snapshot) (req : Request)
    (ws : alloc.vec.Vec Write) (rep : Reply)
    (h : transition cfg c s req = ok (.Ok (ws, rep))) (hreg : ∀ n e hh t, req.command ≠ .Register n e hh t) :
    ∀ w ∈ ws.val, ∃ u, Authenticated s req.authorization u ∧ ownerOf w = u.id := by
  intro w hw
  have ha := authorized cfg c s req ws rep h w hw
  cases w with
  | AddUser x => obtain ⟨n, e, hh, t, hc, _⟩ := ha; exact absurd hc (hreg n e hh t)
  | AddSession x => obtain ⟨n, e, hh, t, hc, _⟩ := ha; exact absurd hc (hreg n e hh t)
  | SetPassword uid hash => obtain ⟨u, hu, rfl, _⟩ := ha; exact ⟨u, hu, rfl⟩
  | DeleteUser uid => obtain ⟨u, hu, rfl, _⟩ := ha; exact ⟨u, hu, rfl⟩
  | InsertRecord row => obtain ⟨u, hu, rs, _, _, r, _, rfl⟩ := ha; exact ⟨u, hu, rfl⟩
  | DeleteStore uid => obtain ⟨u, hu, rfl, _⟩ := ha; exact ⟨u, hu, rfl⟩

/-- Deleting an account needs the account's current password. -/
theorem delete_account_needs_password (cfg : Config) (c : Crypto) (s : Snapshot) (req : Request)
    (ws : alloc.vec.Vec Write) (rep : Reply) (uid : U64)
    (h : transition cfg c s req = ok (.Ok (ws, rep))) (hw : .DeleteUser uid ∈ ws.val) :
    ∃ u, Authenticated s req.authorization u ∧ u.id = uid ∧
      ∃ pw, req.command = .DeleteAccount pw ∧ Verify c u.password.val pw.val := by
  obtain ⟨u, hu, rfl, pw, hc, hv⟩ := authorized cfg c s req ws rep h _ hw
  exact ⟨u, hu, rfl, pw, hc, hv⟩

/-- Changing a password needs the current one. -/
theorem change_password_needs_password (cfg : Config) (c : Crypto) (s : Snapshot) (req : Request)
    (ws : alloc.vec.Vec Write) (rep : Reply) (uid : U64) (hash : alloc.vec.Vec U8)
    (h : transition cfg c s req = ok (.Ok (ws, rep))) (hw : .SetPassword uid hash ∈ ws.val) :
    ∃ u, Authenticated s req.authorization u ∧ u.id = uid ∧
      ∃ cur, req.command = .ChangePassword cur hash ∧ Verify c u.password.val cur.val := by
  obtain ⟨u, hu, rfl, cur, hc, hv, _⟩ := authorized cfg c s req ws rep h _ hw
  exact ⟨u, hu, rfl, cur, hc, hv⟩

/-- A closed server registers nobody. -/
theorem closed_registration (cfg : Config) (c : Crypto) (s : Snapshot) (req : Request)
    (ws : alloc.vec.Vec Write) (rep : Reply) (hclosed : cfg.open_registration = false)
    (h : transition cfg c s req = ok (.Ok (ws, rep))) :
    ∀ w ∈ ws.val, ∀ u x, w ≠ .AddUser u ∧ w ≠ .AddSession x := by
  intro w hw u x
  have ha := authorized cfg c s req ws rep h w hw
  constructor
  · rintro rfl; obtain ⟨_, _, _, _, _, ho, _⟩ := ha; simp_all
  · rintro rfl; obtain ⟨_, _, _, _, _, ho, _⟩ := ha; simp_all

/-- Every record a request stores is within the size limit (or the limit is 0). -/
theorem stored_records_fit (cfg : Config) (c : Crypto) (s : Snapshot) (req : Request)
    (ws : alloc.vec.Vec Write) (rep : Reply) (row : StoreRow)
    (h : transition cfg c s req = ok (.Ok (ws, rep))) (hw : .InsertRecord row ∈ ws.val) :
    row.data.val.length ≤ cfg.max_record_size.val ∨ cfg.max_record_size.val = 0 := by
  obtain ⟨u, _, rs, _, hfit, r, hr, rfl⟩ := authorized cfg c s req ws rep h _ hw
  exact hfit r hr

/-- The universal form `h5i app lint` looks for: for every principal (the
settings, the verification table and the presented header), state and
command, every write is a registration on an open server or belongs to the
authenticated user. -/
def step (a : Config × Crypto × Option (alloc.vec.Vec U8)) (s : Snapshot) (cmd : Command) :
    Result (core.result.Result ((alloc.vec.Vec Write) × Reply) Error) :=
  transition a.1 a.2.1 s { authorization := a.2.2, command := cmd }

def ownerAllowed (s : Snapshot) (a : Config × Crypto × Option (alloc.vec.Vec U8)) : Write → Prop
  | .AddUser u => a.1.open_registration = true ∧ u.id = s.next_user_id ∧ ValidUsername u.username.val
  | .AddSession x => a.1.open_registration = true ∧ x.user_id = s.next_user_id ∧
      ∀ y ∈ s.sessions.val, y.token.val ≠ x.token.val
  | w => ∃ u, Authenticated s a.2.2 u ∧ ownerOf w = u.id

theorem writes_authorized :
    WritesAuthorized step (fun s => s) (fun ws => ws.val) ownerAllowed := by
  intro a s cmd ws rep h w hw
  have ha := authorized a.1 a.2.1 s _ ws rep h w hw
  cases w with
  | AddUser x => obtain ⟨n, e, hh, t, _, ho, hv, _, rfl⟩ := ha; exact ⟨ho, rfl, hv⟩
  | AddSession x => obtain ⟨n, e, hh, t, _, ho, _, hf, rfl⟩ := ha; exact ⟨ho, rfl, hf.2⟩
  | SetPassword uid hash => obtain ⟨u, hu, rfl, _⟩ := ha; exact ⟨u, hu, rfl⟩
  | DeleteUser uid => obtain ⟨u, hu, rfl, _⟩ := ha; exact ⟨u, hu, rfl⟩
  | InsertRecord row => obtain ⟨u, hu, rs, _, _, r, _, rfl⟩ := ha; exact ⟨u, hu, rfl⟩
  | DeleteStore uid => obtain ⟨u, hu, rfl, _⟩ := ha; exact ⟨u, hu, rfl⟩

/-! ## Session tokens -/

/-- `login` discloses a session token only after the password verifies, and
only the token of a session of the named user. -/
theorem login_needs_password (cfg : Config) (c : Crypto) (s : Snapshot) (auth : Option (alloc.vec.Vec U8))
    (n pw : alloc.vec.Vec U8) (ws : alloc.vec.Vec Write) (rep : Reply)
    (h : transition cfg c s { authorization := auth, command := .Login n pw } = ok (.Ok (ws, rep))) :
    ∃ u ∈ s.users.val, u.username.val = n.val ∧ Verify c u.password.val pw.val ∧
      ∃ x ∈ s.sessions.val, x.user_id = u.id ∧ rep = .Session x.token := by
  unfold transition at h
  exact (Verified.login_ok h).2

/-! ## Tenant isolation -/

/-- What a request does (reply, writes or error) never depends on another
user's records: two databases that agree on accounts, sessions, counters and
the requester's own records give the same outcome. -/
theorem outcome_independent_of_other_users (cfg : Config) (c : Crypto) (s s' : Snapshot) (req : Request)
    (hu : s.users = s'.users) (hs : s.sessions = s'.sessions)
    (hn : s.next_user_id = s'.next_user_id) (hn' : s.next_session_id = s'.next_session_id)
    (hown : ∀ u, Authenticated s req.authorization u → ownRows s u.id = ownRows s' u.id) :
    transition cfg c s req = transition cfg c s' req :=
  Verified.transition_isolated cfg c s s' req hu hs hn hn' hown

/-- A successful request changes no account but the requester's (and the
fresh id a registration takes): user row, sessions, history and records of
every other user stay exactly as they were. -/
theorem other_accounts_untouched (cfg : Config) (c : Crypto) (s s' : Snapshot) (req : Request)
    (ws : alloc.vec.Vec Write) (rep : Reply) (uid : U64)
    (h : transition cfg c s req = ok (.Ok (ws, rep))) (ha : apply s ws = ok s')
    (hnew : uid ≠ s.next_user_id) (hnot : ∀ u, Authenticated s req.authorization u → u.id ≠ uid) :
    Verified.Account s' uid = Verified.Account s uid :=
  Verified.other_accounts_untouched h ha hnew hnot

/-- Deleting an account leaves nothing of it: no user row, session,
history row or record with its id. -/
theorem account_deletion_purges (cfg : Config) (c : Crypto) (s s' : Snapshot) (req : Request)
    (ws : alloc.vec.Vec Write) (rep : Reply) (pw : alloc.vec.Vec U8)
    (hcmd : req.command = .DeleteAccount pw)
    (h : transition cfg c s req = ok (.Ok (ws, rep))) (ha : apply s ws = ok s') :
    ∃ u, Authenticated s req.authorization u ∧ Verified.Account s' u.id = ([], [], [], []) :=
  Verified.account_deletion_purges hcmd h ha

/-- Records are append-only: only deleting the account or the store removes
or changes a stored record; a re-posted `(host, tag, idx)` never overwrites. -/
theorem records_append_only (cfg : Config) (c : Crypto) (s s' : Snapshot) (req : Request)
    (ws : alloc.vec.Vec Write) (rep : Reply)
    (hd : ∀ pw, req.command ≠ .DeleteAccount pw) (hs : req.command ≠ .DeleteStore)
    (h : transition cfg c s req = ok (.Ok (ws, rep))) (ha : apply s ws = ok s') :
    s.store.val <+: s'.store.val :=
  Verified.records_append_only hd hs h ha

/-! ## Findings -/

/-- Finding: a password change keeps every session. A token obtained before
the change (e.g. stolen) still authenticates afterwards. -/
theorem password_change_keeps_sessions (cfg : Config) (c : Crypto) (s s' : Snapshot) (req : Request)
    (ws : alloc.vec.Vec Write) (rep : Reply) (cur h' : alloc.vec.Vec U8)
    (hcmd : req.command = .ChangePassword cur h')
    (h : transition cfg c s req = ok (.Ok (ws, rep))) (ha : apply s ws = ok s') :
    s'.sessions = s.sessions :=
  Verified.password_change_keeps_sessions hcmd h ha

/-- Finding: `count` is bound as `i64::conv(count)`; every count above
`i64::MAX` wraps negative, and SQLite reads a negative `LIMIT` as no limit,
so all such counts return the whole series. -/
theorem next_huge_count_is_unlimited (s : Snapshot) (uid : U64) (host : U128) (tag : alloc.vec.Vec U8)
    (start : Option U64) (n m : U64) (hn : n.val > 9223372036854775807) (hm : m.val > 9223372036854775807) :
    next_records s uid host tag start n = next_records s uid host tag start m := by
  rw [Verified.next_records_eq, Verified.next_records_eq]
  have h1 : n > 9223372036854775807#u64 := by scalar_tac
  have h2 : m > 9223372036854775807#u64 := by scalar_tac
  simp only [h1, h2, ↓reduceIte]

/-- Finding: `idx` and `start` are compared as signed `i64`s, so a `start`
of 2^63 or more selects records from index 0 up: a record at `idx = 0` is
"at or after" `start = 2^63`. -/
theorem next_start_wraps (r : StoreRow) (tag : Slice U8) (hu : r.tag.val = tag.val) (h0 : r.idx = 0#u64) :
    in_series r r.user_id r.host tag 9223372036854775808#u64 = ok true := by
  rw [Verified.in_series_eq]
  simp [Verified.InSeries, hu, h0, Verified.sk]

end atuin_kernel.Properties
