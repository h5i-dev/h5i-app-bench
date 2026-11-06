import Verified.Authn
import Spec
/-!
# crates.io: the security properties

Each theorem is stated over the extracted kernel and `Spec`; the proofs are
in `Verified/`.
-/
open Aeneas Aeneas.Std Result cratesio_kernel cratesio_kernel.Spec
open H5iAppLib hiding Covers

namespace cratesio_kernel.Properties

/-! ## Authentication (`authenticate`) -/

/-- A request carrying an `Origin` outside `allowed_origins` is never
authenticated, by cookie or by token. -/
theorem cross_origin_never_authenticates (allowed : Slice U64) (users : Slice auth.User)
    (tokens : alloc.vec.Vec auth.ApiToken) (req : auth.Request) (now : I64) (a : auth.Authentication)
    (o : U64) (ho : o ∈ req.origins.val) (hn : o ∉ allowed.val) :
    auth.authenticate allowed users tokens req now ≠ ok (.Ok a) := by
  intro h
  exact hn ((Verified.Authn.authenticate_ok h).1 o ho)

/-- An API token authenticates only if a row accepts it now: not revoked,
not expired, and the presented `cio…` secret; its owner exists and is not
locked. The token is used only when the request has no session. -/
theorem token_authentication_is_live (allowed : Slice U64) (users : Slice auth.User)
    (tokens : alloc.vec.Vec auth.ApiToken) (req : auth.Request) (now : I64) (i : Usize) (u : auth.User)
    (h : auth.authenticate allowed users tokens req now = ok (.Ok (.Token i u))) :
    req.session_uid = none ∧ ∃ hd s, req.authorization = some hd ∧
      auth.parse_auth_header hd.deref = ok (.Ok s) ∧
      ∃ hi : i.val < tokens.val.length, Live (tokens.val[i.val]) s.val now.val ∧
        u ∈ users.val ∧ u.id = (tokens.val[i.val]).user_id ∧ ¬ Locked u now.val := by
  obtain ⟨-, hs, hd, s, hh, hp, -, hi, hl, hm, hid, hlk⟩ := Verified.Authn.authenticate_ok h
  exact ⟨hs, hd, s, hh, hp, hi, hl, hm, hid, hlk⟩

/-- A revoked or expired token row never authenticates a request. -/
theorem revoked_or_expired_token_rejected (allowed : Slice U64) (users : Slice auth.User)
    (tokens : alloc.vec.Vec auth.ApiToken) (req : auth.Request) (now : I64) (i : Usize) (u : auth.User)
    (h : auth.authenticate allowed users tokens req now = ok (.Ok (.Token i u)))
    (hi : i.val < tokens.val.length) :
    (tokens.val[i.val]).revoked = false ∧
      ∀ e, (tokens.val[i.val]).expired_at = some e → now.val < e.val := by
  obtain ⟨-, -, s, -, -, hi', ⟨hr, he, -⟩, -⟩ := token_authentication_is_live allowed users tokens req now i u h
  refine ⟨hr, fun e hx => ?_⟩
  rcases he with he | ⟨e', he', hlt⟩
  · rw [he] at hx; cases hx
  · rw [he'] at hx; cases hx; exact hlt

/-- A session cookie authenticates only the user it names, if that user
exists, is not locked, and the cookie carries the user's current session
epoch (so logging out everywhere, which bumps the epoch, kills old cookies). -/
theorem session_needs_current_epoch (allowed : Slice U64) (users : Slice auth.User)
    (tokens : alloc.vec.Vec auth.ApiToken) (req : auth.Request) (now : I64) (u : auth.User)
    (h : auth.authenticate allowed users tokens req now = ok (.Ok (.Cookie u))) :
    req.session_uid = some u.id ∧ u ∈ users.val ∧ ¬ Locked u now.val ∧
      epochOf req.session_epoch = some u.session_epoch.val :=
  (Verified.Authn.authenticate_ok h).2

/-- A locked account is never authenticated, by cookie or token. -/
theorem locked_account_never_authenticates (allowed : Slice U64) (users : Slice auth.User)
    (tokens : alloc.vec.Vec auth.ApiToken) (req : auth.Request) (now : I64) (a : auth.Authentication)
    (h : auth.authenticate allowed users tokens req now = ok (.Ok a)) :
    match a with
    | .Cookie u => ¬ Locked u now.val
    | .Token _ u => ¬ Locked u now.val := by
  have := (Verified.Authn.authenticate_ok h).2
  rcases a with u | ⟨i, u⟩
  · exact this.2.2.1
  · obtain ⟨-, -, -, -, -, -, -, -, -, -, hl⟩ := this; exact hl

/-! ## Authorization (`AuthCheck::check`) -/

/-- Endpoints built with `AuthCheck::only_cookie` never accept an API token. -/
theorem cookie_only_rejects_tokens (ac : auth.AuthCheck) (allowed : Slice U64) (users : Slice auth.User)
    (tokens : alloc.vec.Vec auth.ApiToken) (req : auth.Request) (now : I64) (a : auth.Authentication)
    (hac : ac.allow_token = false) (h : auth.check ac allowed users tokens req now = ok (.Ok a)) :
    ∃ u, a = .Cookie u := by
  obtain ⟨-, ht⟩ := Verified.Authn.check_ok h
  rcases a with u | ⟨i, u⟩
  · exact ⟨u, rfl⟩
  · have := (ht i u rfl).1; rw [hac] at this; cases this

/-- A scoped token passes only on an endpoint whose scope it lists; a legacy
token (no endpoint scopes) passes anywhere tokens are allowed. -/
theorem token_needs_endpoint_scope (ac : auth.AuthCheck) (allowed : Slice U64) (users : Slice auth.User)
    (tokens : alloc.vec.Vec auth.ApiToken) (req : auth.Request) (now : I64) (i : Usize) (u : auth.User)
    (h : auth.check ac allowed users tokens req now = ok (.Ok (.Token i u))) :
    ∃ hi : i.val < tokens.val.length, Legacy (tokens.val[i.val]) ∨
      ∃ v s, (tokens.val[i.val]).endpoint_scopes = some v ∧ ac.endpoint_scope = some s ∧ s ∈ v.val := by
  obtain ⟨-, ht⟩ := Verified.Authn.check_ok h
  obtain ⟨-, hi, he, -⟩ := ht i u rfl
  exact ⟨hi, he⟩

/-- A crate-scoped token acting on a crate passes only if one of its patterns
covers that crate's name (`serde*` covers `serde_json`, `serde` only
`serde`). -/
theorem token_confined_to_crate_scopes (ac : auth.AuthCheck) (allowed : Slice U64) (users : Slice auth.User)
    (tokens : alloc.vec.Vec auth.ApiToken) (req : auth.Request) (now : I64) (i : Usize) (u : auth.User)
    (n : alloc.vec.Vec U8) (v : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : auth.check ac allowed users tokens req now = ok (.Ok (.Token i u)))
    (hn : ac.crate_name = some n) (hi : i.val < tokens.val.length)
    (hv : (tokens.val[i.val]).crate_scopes = some v) (hne : v.val ≠ []) :
    ∃ p ∈ v.val, Covers p.val n.val := by
  obtain ⟨-, ht⟩ := Verified.Authn.check_ok h
  obtain ⟨-, hi', -, hc⟩ := ht i u rfl
  rcases hc with h0 | ⟨v', h1, h2⟩ | ⟨v', h1, h2, -⟩ | ⟨v', n', h1, h2, h3⟩
  · rw [hv] at h0; cases h0
  · rw [hv] at h1; cases h1; exact absurd h2 hne
  · rw [hn] at h2; cases h2
  · rw [hv] at h1; cases h1; rw [hn] at h2; cases h2; exact h3

/-- A crate-scoped token on an endpoint that names no crate passes only if
the endpoint explicitly allows any crate scope (and then filters itself). -/
theorem crate_scoped_token_needs_crate_or_opt_in (ac : auth.AuthCheck) (allowed : Slice U64)
    (users : Slice auth.User) (tokens : alloc.vec.Vec auth.ApiToken) (req : auth.Request) (now : I64)
    (i : Usize) (u : auth.User) (v : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : auth.check ac allowed users tokens req now = ok (.Ok (.Token i u)))
    (hn : ac.crate_name = none) (hi : i.val < tokens.val.length)
    (hv : (tokens.val[i.val]).crate_scopes = some v) (hne : v.val ≠ []) :
    ac.allow_any_crate_scope = true := by
  obtain ⟨-, ht⟩ := Verified.Authn.check_ok h
  obtain ⟨-, hi', -, hc⟩ := ht i u rfl
  rcases hc with h0 | ⟨v', h1, h2⟩ | ⟨v', h1, h2, h3⟩ | ⟨v', n', h1, h2, h3⟩
  · rw [hv] at h0; cases h0
  · rw [hv] at h1; cases h1; exact absurd h2 hne
  · exact h3
  · rw [hn] at h2; cases h2

end cratesio_kernel.Properties
