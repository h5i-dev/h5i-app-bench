import Spec
open Aeneas Aeneas.Std Result bootstrapacademy_kernel bootstrapacademy_kernel.Spec H5iAppLib

namespace bootstrapacademy_kernel.Properties

/-- A request whose access token does not authenticate writes nothing, not
even to the cache, and fails. -/
theorem unauthenticated_writes_nothing (s : Snapshot) (env : Env) (req : Request)
    (ws : alloc.vec.Vec Write) (r : core.result.Result Reply Error)
    (h : transition s env req = ok (ws, r)) (hc : NeedsToken req.cmd)
    (ha : ∀ a, req.token = some a → ¬ Authenticates s env.now.val a) :
    ws.val = [] ∧ ∃ e, r = .Err e := by
  sorry

/-- A user-scoped command (`/users/{user_id}/...`) succeeds only for the
account itself or for an administrator whose session passed the second
factor (`ensure_self_or_admin`). -/
theorem self_or_admin (s : Snapshot) (env : Env) (req : Request) (ws : alloc.vec.Vec Write) (x : Reply)
    (t : UserIdOrSelf)
    (h : transition s env req = ok (ws, .Ok x)) (ht : target req.cmd = some t) :
    ∃ a, req.token = some a ∧ Authenticates s env.now.val a ∧
      (resolve t a.user_id.val = a.user_id.val ∨ AdminMfa s a) := by
  sorry

/-- Impersonation and debiting coins need an administrator account and a
session established with a verified second factor, as stored in the
database. -/
theorem admin_needs_mfa (s : Snapshot) (env : Env) (req : Request) (ws : alloc.vec.Vec Write) (x : Reply)
    (h : transition s env req = ok (ws, .Ok x)) (hc : AdminOnly req.cmd) :
    ∃ a, req.token = some a ∧ Authenticates s env.now.val a ∧ AdminMfa s a := by
  sorry

/-- The `admin`, `email_verified` and `mfa` claims of an access token change
nothing: authority is read from the account and the session. -/
theorem token_claims_ignored (s : Snapshot) (env : Env) (c : Command) (a b : Authentication)
    (hu : a.user_id = b.user_id) (hs : a.session_id = b.session_id)
    (hr : a.refresh_token_hash = b.refresh_token_hash) :
    transition s env ⟨some a, c⟩ = transition s env ⟨some b, c⟩ := by
  sorry

/-- A session created by impersonation never carries the second factor, so
it grants no administrative authority. -/
theorem impersonation_without_mfa (s : Snapshot) (env : Env) (tok : Option Authentication) (u : U64)
    (ws : alloc.vec.Vec Write) (r : core.result.Result Reply Error)
    (h : transition s env ⟨tok, .Impersonate u⟩ = ok (ws, r)) :
    (∀ x, Write.CreateSession x ∈ ws.val → x.mfa_verified = false) ∧
    (∀ l, r = .Ok (.Login l) → l.session.mfa_verified = false ∧ l.access_token.mfa_verified = false) := by
  sorry

/-- A session is marked `mfa_verified` only by a password login with a TOTP
code that the account's enabled device accepts; a recovery code does not
count. -/
theorem mfa_session_needs_totp (s : Snapshot) (env : Env) (req : Request)
    (ws : alloc.vec.Vec Write) (r : core.result.Result Reply Error) (x : Session)
    (h : transition s env req = ok (ws, r)) (hx : Write.CreateSession x ∈ ws.val)
    (hm : x.mfa_verified = true) :
    ∃ c code d, req.cmd = .CreateSession c ∧ c.mfa.totp_code = some code ∧
      d ∈ s.db.totp_devices.val ∧ d.user_id = x.user_id ∧ d.enabled = true ∧
      TotpAccepts env code.val d.secret.val := by
  sorry

/-- A user-scoped command writes only rows and cache entries of the account
it names. -/
theorem writes_confined (s : Snapshot) (env : Env) (a : Authentication) (c : Command)
    (ws : alloc.vec.Vec Write) (r : core.result.Result Reply Error) (t : UserIdOrSelf)
    (hw : Wf s.db) (h : transition s env ⟨some a, c⟩ = ok (ws, r)) (ht : target c = some t) :
    ∀ w ∈ ws.val, Touches s.db (resolve t a.user_id.val) w := by
  sorry

/-- Balances never go negative: applying a request's writes to a `coins`
table without negative entries leaves none. -/
theorem coins_nonnegative (s : Snapshot) (env : Env) (req : Request)
    (ws : alloc.vec.Vec Write) (r : core.result.Result Reply Error)
    (h : transition s env req = ok (ws, r))
    (hs : ∀ x ∈ coinRows s.db, 0 ≤ x.2.1 ∧ 0 ≤ x.2.2) :
    ∀ x ∈ coinsAfter (coinRows s.db) ws.val, 0 ≤ x.2.1 ∧ 0 ≤ x.2.2 := by
  sorry

/-- No ported endpoint credits coins ("Use the purchase or verified recovery
path to credit coins"), for a refill price that fits an `i64`. -/
theorem no_minting (s : Snapshot) (env : Env) (req : Request)
    (ws : alloc.vec.Vec Write) (r : core.result.Result Reply Error)
    (hp : s.config.hearts_refill_price.val < 2 ^ 63)
    (h : transition s env req = ok (ws, r)) (u : U64) (c w : I64)
    (hw : Write.AddCoins u c w ∈ ws.val) :
    c.val ≤ 0 ∧ w.val ≤ 0 := by
  sorry

/-- Hearts are refilled only against payment: the caller is charged the
refill price and the withdrawal declaration for the current text is
recorded. -/
theorem refill_is_paid (s : Snapshot) (env : Env) (tok : Option Authentication) (d : Declaration)
    (ws : alloc.vec.Vec Write) (r : core.result.Result Reply Error) (u hs t : U64)
    (hp : s.config.hearts_refill_price.val < 2 ^ 63)
    (h : transition s env ⟨tok, .RefillHearts d⟩ = ok (ws, r)) (hw : Write.SetHearts u hs t ∈ ws.val) :
    ∃ a, tok = some a ∧ Authenticates s env.now.val a ∧ u = a.user_id ∧
      (∃ c w, Write.AddCoins u c w ∈ ws.val ∧ c.val = -(s.config.hearts_refill_price.val : Int) ∧ w.val = 0) ∧
      ∃ k, Write.CreateConsent k ∈ ws.val ∧ k.user_id = u ∧ nats k.text_version.val = lit "2026-09" := by
  sorry

/-- While a login is locked, a login attempt is refused with the remaining
time before any password is checked, and nothing is written. -/
theorem locked_login_refused (s : Snapshot) (env : Env) (tok : Option Authentication) (cmd : SessionCreateCommand)
    (c : Command) (ws : alloc.vec.Vec Write) (r : core.result.Result Reply Error) (n b : U64)
    (hc : c = .CreateSession cmd ∨ c = .ProveRecipient cmd)
    (hl : lookup s.cache.val env.now.val (isAccount (lowered (loginBytes cmd.name_or_email))) =
      some (.Attempts ⟨n, some b⟩))
    (hb : env.now.val ≤ b.val)
    (h : transition s env ⟨tok, c⟩ = ok (ws, r)) :
    ws.val = [] ∧ ∃ e, r = .Err (.TooManyFailedAttempts e) ∧ e.val = b.val - env.now.val := by
  sorry

/-- A login refused for bad credentials counts one more failure against the
client address. -/
theorem failed_login_counted (s : Snapshot) (env : Env) (tok : Option Authentication) (cmd : SessionCreateCommand)
    (ws : alloc.vec.Vec Write)
    (h : transition s env ⟨tok, .CreateSession cmd⟩ = ok (ws, .Err .InvalidCredentials)) :
    ∃ e a, Write.CacheSet e ∈ ws.val ∧ isIp env.client_ip.val e.key = true ∧ e.value = .Attempts a ∧
      a.count.val = min (ipCount s env.now.val env.client_ip.val + 1) U64.max := by
  sorry

/-- Removing the second factor ends the authority it granted: the devices
go, every session of the account loses `mfa_verified`, and every access
token of the account is invalidated. -/
theorem mfa_disable_revokes (s : Snapshot) (env : Env) (a : Authentication) (t : UserIdOrSelf)
    (ws : alloc.vec.Vec Write) (x : Reply)
    (hw : Wf s.db) (h : transition s env ⟨some a, .MfaDisable t⟩ = ok (ws, .Ok x)) :
    (∃ v, Write.ClearMfaVerified v ∈ ws.val ∧ v.val = resolve t a.user_id.val) ∧
    (∃ v, Write.DeleteTotpDevicesByUser v ∈ ws.val ∧ v.val = resolve t a.user_id.val) ∧
    ∀ rt ∈ s.db.refresh_tokens.val,
      (∃ y ∈ s.db.sessions.val, y.id = rt.session_id ∧ y.user_id.val = resolve t a.user_id.val) →
      ∃ e, Write.CacheSet e ∈ ws.val ∧ e.key = .Invalidated rt.hash := by
  sorry

/-- A refresh token yields a login only for a session that has not expired,
of an enabled account, and the new token keeps the session's second-factor
flag. -/
theorem refresh_needs_live_session (s : Snapshot) (env : Env) (tok : Option Authentication) (rt : U64)
    (ws : alloc.vec.Vec Write) (l : Login)
    (h : transition s env ⟨tok, .RefreshSession rt⟩ = ok (ws, .Ok (.Login l))) :
    ∃ x u, sessionByHash s.db rt.val = some x ∧
      env.now.val < x.updated_at.val + s.config.refresh_token_ttl.val ∧
      userOf s.db x.user_id.val = some u ∧ u.enabled = true ∧
      l.session.id = x.id ∧ l.access_token.mfa_verified = x.mfa_verified := by
  sorry

/-- Disabled accounts get no new session. -/
theorem disabled_accounts_get_no_session (s : Snapshot) (env : Env) (req : Request)
    (ws : alloc.vec.Vec Write) (r : core.result.Result Reply Error) (x : Session)
    (hw : Wf s.db) (h : transition s env req = ok (ws, r)) (hx : Write.CreateSession x ∈ ws.val) :
    ∃ u, userOf s.db x.user_id.val = some u ∧ u.enabled = true := by
  sorry

/-- The kernel never panics, overflows or diverges on tables of realistic size. -/
theorem transition_total (s : Snapshot) (env : Env) (req : Request) (hb : Bounded s) :
    ∃ y, transition s env req = ok y := by
  sorry

end bootstrapacademy_kernel.Properties
