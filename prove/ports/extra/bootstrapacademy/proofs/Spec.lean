import BootstrapacademyKernel
import H5iAppLib
/-!
# Bootstrap Academy sessions, MFA, coins and hearts: the spec

From the backend's documentation and code comments at fbe5e60
(ARCHITECTURE.md "Authentication" and "Two Factor Authentication for
Administrators", `academy_auth`, `academy_core/{session,mfa,coin,heart}`).
Everything here reads the kernel's tables as plain lists and uses none of the
kernel's functions.
-/
open Aeneas Aeneas.Std bootstrapacademy_kernel

namespace bootstrapacademy_kernel

deriving instance DecidableEq for TotpCheck

end bootstrapacademy_kernel

namespace bootstrapacademy_kernel.Spec

/-- A byte string as numbers. -/
def nats (v : List U8) : List Nat := v.map (·.val)

/-- The UTF-8 bytes of a literal. -/
def lit (s : String) : List Nat := s.toUTF8.toList.map (·.toNat)

/-- ASCII lowercase: SQL `lower` and `to_lowercase` on ASCII. -/
def lowerNat (c : Nat) : Nat := if 65 ≤ c ∧ c ≤ 90 then c + 32 else c

def lowered (v : List U8) : List Nat := (nats v).map lowerNat

/-! ## The database, as upstream's queries read it -/

def userOf (db : Db) (u : Nat) : Option User := db.users.val.find? (·.id.val = u)

def sessionOf (db : Db) (sid : Nat) : Option Session := db.sessions.val.find? (·.id.val = sid)

/-- `get_by_refresh_token_hash`: the session a refresh token hash belongs to. -/
def sessionByHash (db : Db) (h : Nat) : Option Session :=
  (db.refresh_tokens.val.find? (·.hash.val = h)).bind (fun r => sessionOf db r.session_id.val)

/-- Primary keys: user, session and TOTP device ids are unique. -/
def Wf (db : Db) : Prop :=
  (db.users.val.map (·.id)).Nodup ∧ (db.sessions.val.map (·.id)).Nodup ∧
  (db.totp_devices.val.map (·.id)).Nodup

/-! ## The cache -/

def isInvalidated (h : Nat) : CacheKey → Bool
  | .Invalidated x => x.val = h
  | _ => false

def isAccount (l : List Nat) : CacheKey → Bool
  | .ThrottleAccount v => nats v.val = l
  | _ => false

def isIp (ip : Nat) : CacheKey → Bool
  | .ThrottleIp x => x.val = ip
  | _ => false

/-- The value under a key at time `now`: the first entry with that key, unless
it has expired (`now >= expires`). -/
def lookup (c : List CacheEntry) (now : Nat) (p : CacheKey → Bool) : Option CacheValue :=
  match c.find? (fun e => p e.key) with
  | some e => if e.expires.all (fun t => decide (now < t.val)) then some e.value else none
  | none => none

/-- The failed attempts counted against a client address. -/
def ipCount (s : Snapshot) (now ip : Nat) : Nat :=
  match lookup s.cache.val now (isIp ip) with
  | some (.Attempts a) => a.count.val
  | _ => 0

/-! ## Who a request acts for -/

/-- `authenticate` accepts the claims `a`: the access token is not
invalidated, the account exists and is enabled, and the refresh token hash
names the claimed session of that account. -/
def Authenticates (s : Snapshot) (now : Nat) (a : Authentication) : Prop :=
  lookup s.cache.val now (isInvalidated a.refresh_token_hash.val) = none ∧
  (∃ u, userOf s.db a.user_id.val = some u ∧ u.enabled = true) ∧
  ∃ x, sessionByHash s.db a.refresh_token_hash.val = some x ∧ x.id = a.session_id ∧ x.user_id = a.user_id

/-- Administrative authority, as stored: the account is an administrator and
the session was established with a verified second factor. -/
def AdminMfa (s : Snapshot) (a : Authentication) : Prop :=
  (∃ u, userOf s.db a.user_id.val = some u ∧ u.admin = true) ∧
  ∃ x, sessionOf s.db a.session_id.val = some x ∧ x.mfa_verified = true

/-- Commands that act for the bearer of an access token. -/
def NeedsToken : Command → Prop
  | .CreateSession _ | .ProveRecipient _ | .RefreshSession _ => False
  | _ => True

/-- Administrator-only commands. -/
def AdminOnly : Command → Prop
  | .Impersonate _ | .AddCoins _ _ _ _ => True
  | _ => False

/-- The account a user-scoped command names (`{user_id}` in the path). -/
def target : Command → Option UserIdOrSelf
  | .ListSessions t | .DeleteSession t _ | .DeleteSessionsByUser t | .MfaInitialize t
  | .MfaEnable t _ | .MfaDisable t | .GetBalance t | .GetHearts t => some t
  | _ => none

/-- `UserIdOrSelf::unwrap_or`. -/
def resolve (t : UserIdOrSelf) (self : Nat) : Nat :=
  match t with
  | .UserId u => u.val
  | .Slf => self

/-- The TOTP oracle accepts `code` for `secret`. -/
def TotpAccepts (env : Env) (code secret : Nat) : Prop :=
  (env.totp.val.find? (fun t => t.1.val = code ∧ t.2.1.val = secret)).map (·.2.2) = some .Ok

def loginBytes : NameOrEmail → List U8
  | .Name v => v.val
  | .Email v => v.val

/-- Write `w` only touches rows and cache entries of account `u`, judged on
the database before the request. -/
def Touches (db : Db) (u : Nat) : Write → Prop
  | .CacheSet e =>
    match e.key with
    | .Invalidated h => ∃ r ∈ db.refresh_tokens.val, r.hash = h ∧
        ∃ x ∈ db.sessions.val, x.id = r.session_id ∧ x.user_id.val = u
    | _ => False
  | .CacheRemove _ => False
  | .CreateSession x => x.user_id.val = u
  | .UpdateSessionUpdatedAt sid _ | .DeleteSession sid | .SaveRefreshTokenHash sid _ =>
    ∀ x ∈ db.sessions.val, x.id = sid → x.user_id.val = u
  | .ClearMfaVerified v | .DeleteSessionsByUser v | .UpdateLastLogin v _ | .DeleteTotpDevicesByUser v
  | .SaveRecoveryCodeHash v _ | .DeleteRecoveryCodeHash v | .AddCoins v _ _ | .SetHearts v _ _ => v.val = u
  | .CreateTotpDevice d => d.user_id.val = u
  | .UpdateTotpDeviceEnabled id _ | .SaveTotpDeviceSecret id _ =>
    ∀ d ∈ db.totp_devices.val, d.id = id → d.user_id.val = u
  | .CreateTransaction t => t.user_id.val = u
  | .CreateConsent c => c.user_id.val = u

/-! ## Coins -/

/-- `coin.sql` `add_coins`: `merge into coins ... when matched then update
set coins=coins+:coins ... when not matched then insert`. Rows are (user,
coins, withheld coins). -/
def mergeCoins : List (Nat × Int × Int) → Nat → Int → Int → List (Nat × Int × Int)
  | [], u, c, w => [(u, c, w)]
  | (v, a, b) :: rest, u, c, w =>
    if v = u then (v, a + c, b + w) :: rest else (v, a, b) :: mergeCoins rest u c w

/-- The `coins` table after the writes. -/
def coinsAfter (rows : List (Nat × Int × Int)) : List Write → List (Nat × Int × Int)
  | [] => rows
  | .AddCoins u c w :: ws => coinsAfter (mergeCoins rows u.val c.val w.val) ws
  | _ :: ws => coinsAfter rows ws

def coinRows (db : Db) : List (Nat × Int × Int) :=
  db.coins.val.map (fun r => (r.user_id.val, r.coins.val, r.withheld_coins.val))

/-! ## Size -/

/-- Every table and the cache are far from the `Vec` capacity. -/
def Bounded (s : Snapshot) : Prop :=
  s.db.users.val.length ≤ 2 ^ 30 ∧ s.db.passwords.val.length ≤ 2 ^ 30 ∧
  s.db.sessions.val.length ≤ 2 ^ 30 ∧ s.db.refresh_tokens.val.length ≤ 2 ^ 30 ∧
  s.db.totp_devices.val.length ≤ 2 ^ 30 ∧ s.db.recovery_codes.val.length ≤ 2 ^ 30 ∧
  s.db.coins.val.length ≤ 2 ^ 30 ∧ s.db.transactions.val.length ≤ 2 ^ 30 ∧
  s.db.hearts.val.length ≤ 2 ^ 30 ∧ s.db.consents.val.length ≤ 2 ^ 30 ∧
  s.cache.val.length ≤ 2 ^ 30

end bootstrapacademy_kernel.Spec
