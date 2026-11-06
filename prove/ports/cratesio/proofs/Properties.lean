import Verified.Authn
import Verified.Publish
import Verified.Exchange
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

/-! ## Ownership rights (`Rights::get`) -/

/-- Full rights (managing owners, deleting the crate) only come from being a
listed user owner; team membership never gives them. -/
theorem full_rights_only_for_listed_user (user : rights.Actor) (owners : Slice rights.Owner)
    (answers : Slice (I64 × rights.Membership))
    (h : rights.rights user owners answers = ok (.Ok .Full)) :
    rights.Owner.User user.id ∈ owners.val :=
  (Verified.Rights.rights_ok user owners answers _ h).1 rfl

/-- Publish rights without being a listed user owner need an owning team that
GitHub reports the user an *active* member of, through a GitHub token that
decrypts and a GitHub login. -/
theorem team_rights_need_active_membership (user : rights.Actor) (owners : Slice rights.Owner)
    (answers : Slice (I64 × rights.Membership))
    (h : rights.rights user owners answers = ok (.Ok .Publish)) :
    ∃ t, rights.Owner.Team t ∈ owners.val ∧ Verified.Rights.answerOf answers.val t = .Active ∧
      user.gh_token = some true ∧ user.gh_login = true :=
  (Verified.Rights.rights_ok user owners answers _ h).2 rfl

/-! ## Publishing (`publish`) -/

section Publish
open Verified.Publish

/-- A Trusted Publishing publish is accepted only for an existing crate and
only with an unexpired Trusted Publishing token, the one presented, that
lists that crate. -/
theorem trustpub_publish_bound_to_crate (nm : Slice U8) (existing : Option publish.Crate)
    (ow : Option (alloc.vec.Vec rights.Owner)) (allowed : Slice U64) (users : Slice auth.User)
    (tokens : alloc.vec.Vec auth.ApiToken) (tp : alloc.vec.Vec publish.TrustpubToken) (req : auth.Request)
    (now : I64) (gt : Option Bool) (gl : Bool) (answers : Slice (I64 × rights.Membership)) (id : I32)
    (h : publish.publish_auth nm existing ow allowed users tokens tp req now gt gl answers = ok (.Ok (.TrustPub id))) :
    ∃ k raw, existing = some k ∧ id = k.id ∧
      ∃ i, ∃ hi : i < tp.val.length, now.val < (tp.val[i]).expires_at.val ∧ (tp.val[i]).raw.val = raw ∧
        some k.id ∈ (tp.val[i]).crate_ids.val := by
  obtain ⟨-, -, -, -, k, raw, hk, hid, -, i, hi, ⟨hl, hr⟩, hm⟩ := publish_ok h
  exact ⟨k, raw.val, hk, hid, i, hi, hl, hr, hm⟩

/-- Trusted Publishing never creates a crate. -/
theorem trustpub_cannot_create_crates (nm : Slice U8) (ow : Option (alloc.vec.Vec rights.Owner))
    (allowed : Slice U64) (users : Slice auth.User) (tokens : alloc.vec.Vec auth.ApiToken)
    (tp : alloc.vec.Vec publish.TrustpubToken) (req : auth.Request) (now : I64) (gt : Option Bool) (gl : Bool)
    (answers : Slice (I64 × rights.Membership)) (id : I32) :
    publish.publish_auth nm none ow allowed users tokens tp req now gt gl answers ≠ ok (.Ok (.TrustPub id)) := by
  intro h
  obtain ⟨-, -, -, -, k, -, hk, -⟩ := publish_ok h
  cases hk

/-- A crate that requires Trusted Publishing never accepts a publish by a
user (cookie or API token). -/
theorem trustpub_only_rejects_users (nm : Slice U8) (k : publish.Crate) (hk : k.trustpub_only = true)
    (ow : Option (alloc.vec.Vec rights.Owner)) (allowed : Slice U64) (users : Slice auth.User)
    (tokens : alloc.vec.Vec auth.ApiToken) (tp : alloc.vec.Vec publish.TrustpubToken) (req : auth.Request)
    (now : I64) (gt : Option Bool) (gl : Bool) (answers : Slice (I64 × rights.Membership)) (uid : I32) :
    publish.publish_auth nm (some k) ow allowed users tokens tp req now gt gl answers ≠ ok (.Ok (.User uid)) := by
  intro h
  obtain ⟨-, -, -, -, -, ht, -⟩ := publish_ok h
  rw [ht k rfl] at hk; cases hk

/-- A user publishing into a crate that already exists when the row is
written (even one created concurrently) is a listed owner or an active
member of an owning team. -/
theorem publish_existing_needs_ownership (nm : Slice U8) (existing : Option publish.Crate)
    (owners : alloc.vec.Vec rights.Owner) (allowed : Slice U64) (users : Slice auth.User)
    (tokens : alloc.vec.Vec auth.ApiToken) (tp : alloc.vec.Vec publish.TrustpubToken) (req : auth.Request)
    (now : I64) (gt : Option Bool) (gl : Bool) (answers : Slice (I64 × rights.Membership)) (uid : I32)
    (h : publish.publish_auth nm existing (some owners) allowed users tokens tp req now gt gl answers =
      ok (.Ok (.User uid))) :
    rights.Owner.User uid ∈ owners.val ∨ ∃ t, rights.Owner.Team t ∈ owners.val ∧
      Verified.Rights.answerOf answers.val t = .Active ∧ gt = some true ∧ gl = true := by
  obtain ⟨-, -, -, -, -, -, ho⟩ := publish_ok h
  exact ho owners rfl

/-- A user publish authenticated by an API token used a token scoped for it:
legacy, or listing `publish-update` for an existing crate and `publish-new`
for a new one; and its crate scopes, if any, cover the crate's name. -/
theorem publish_token_scoped (nm : Slice U8) (existing : Option publish.Crate)
    (ow : Option (alloc.vec.Vec rights.Owner)) (allowed : Slice U64) (users : Slice auth.User)
    (tokens : alloc.vec.Vec auth.ApiToken) (tp : alloc.vec.Vec publish.TrustpubToken) (req : auth.Request)
    (now : I64) (gt : Option Bool) (gl : Bool) (answers : Slice (I64 × rights.Membership)) (uid : I32)
    (h : publish.publish_auth nm existing ow allowed users tokens tp req now gt gl answers = ok (.Ok (.User uid))) :
    ∃ a, auth.authenticate allowed users tokens req now = ok (.Ok a) ∧
      ∀ i u, a = .Token i u → ∃ hi : i.val < tokens.val.length,
        (Legacy (tokens.val[i.val]) ∨ ∃ v, (tokens.val[i.val]).endpoint_scopes = some v ∧
          pubScope existing ∈ v.val) ∧
        (∀ v, (tokens.val[i.val]).crate_scopes = some v → v.val ≠ [] → ∃ p ∈ v.val, Covers p.val nm.val) := by
  obtain ⟨v, a, hv, hc, -, -, -⟩ := publish_ok h
  obtain ⟨ha, ht⟩ := Verified.Authn.check_ok hc
  refine ⟨a, ha, fun i u e => ?_⟩
  obtain ⟨-, hi, he, hcs⟩ := ht i u e
  refine ⟨hi, ?_, fun w hw hne => ?_⟩
  · rcases he with he | ⟨w, s, hw, hs, hm⟩
    · exact .inl he
    · simp only [publishCheck, Option.some.injEq] at hs
      exact .inr ⟨w, hw, hs ▸ hm⟩
  · rcases hcs with h0 | ⟨w', h1, h2⟩ | ⟨w', h1, h2, -⟩ | ⟨w', n', h1, h2, h3⟩
    · rw [hw] at h0; cases h0
    · rw [hw] at h1; cases h1; exact absurd h2 hne
    · simp [publishCheck] at h2
    · rw [hw] at h1; cases h1
      simp only [publishCheck, Option.some.injEq] at h2
      subst h2; rw [← hv]; exact h3

end Publish

/-! ## Trusted Publishing token exchange (`handle_github_token_inner`) -/

section Exchange
open Verified.Exchange

/-- An access token is issued only for crates whose Trusted Publishing config
matches the OIDC token: the repository owner and name (ignoring case, split
at the first `/`), the numeric repository owner id, the workflow file, and,
if the config names an environment, the same environment. -/
theorem exchange_only_matching_configs (used : alloc.vec.Vec (alloc.vec.Vec U8))
    (configs : alloc.vec.Vec trustpub.GitHubConfig) (claims : trustpub.GitHubClaims)
    (ids : alloc.vec.Vec I32) (used' : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : trustpub.exchange_github used configs claims = ok (.Ok (ids, used'))) :
    ids.val ≠ [] ∧ ∃ k wf oid, claims.repository.val.findIdx? (fun b => decide (b = 47#u8)) = some k ∧
      trustpub.workflow_filename claims.workflow_ref.deref = ok (some wf) ∧
      trustpub.parse_i32 claims.repository_owner_id.deref = ok (some oid) ∧
      ∀ id ∈ ids.val, ∃ c ∈ configs.val, c.crate_id = id ∧
        EqLower c.repository_owner.val (claims.repository.val.take k) ∧
        EqLower c.repository_name.val (claims.repository.val.drop (k + 1)) ∧
        c.repository_owner_id = oid ∧ c.workflow_filename.val = wf.val ∧
        EnvOk (c.environment.map (·.val)) (claims.environment.map (·.val)) := by
  obtain ⟨-, -, -, -, hne, k, wf, oid, hk, hw, ho, hm⟩ := exchange_ok h
  exact ⟨hne, k, wf, oid, hk, hw, ho, hm⟩

/-- A config that names an environment is never matched by an OIDC token
without that environment. -/
theorem exchange_environment_enforced (used : alloc.vec.Vec (alloc.vec.Vec U8))
    (configs : alloc.vec.Vec trustpub.GitHubConfig) (claims : trustpub.GitHubClaims)
    (ids : alloc.vec.Vec I32) (used' : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : trustpub.exchange_github used configs claims = ok (.Ok (ids, used')))
    (id : I32) (hid : id ∈ ids.val) :
    ∃ c ∈ configs.val, c.crate_id = id ∧ ∀ e, c.environment = some e →
      ∃ s, claims.environment = some s ∧ EqLower e.val s.val := by
  obtain ⟨-, -, -, -, -, k, wf, oid, -, -, -, hm⟩ := exchange_ok h
  obtain ⟨c, hc, hcid, -, -, -, -, henv⟩ := hm id hid
  refine ⟨c, hc, hcid, fun e he => ?_⟩
  rcases henv with h0 | ⟨c', s', h1, h2, h3⟩
  · rw [he] at h0; cases h0
  · rw [he] at h1; simp only [Option.map_some, Option.some.injEq] at h1
    rcases hs : claims.environment with _ | s
    · rw [hs] at h2; cases h2
    · rw [hs] at h2; simp only [Option.map_some, Option.some.injEq] at h2
      exact ⟨s, rfl, by rw [h1, h2]; exact h3⟩

/-- An OIDC token's `jti` is single-use: an exchange succeeds only if the
`jti` was never used, and records it. -/
theorem exchange_jti_single_use (used : alloc.vec.Vec (alloc.vec.Vec U8))
    (configs : alloc.vec.Vec trustpub.GitHubConfig) (claims : trustpub.GitHubClaims)
    (ids : alloc.vec.Vec I32) (used' : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : trustpub.exchange_github used configs claims = ok (.Ok (ids, used'))) :
    claims.jti.val ∉ used.val.map (·.val) ∧ used'.val.map (·.val) = used.val.map (·.val) ++ [claims.jti.val] :=
  ⟨(exchange_ok h).1, (exchange_ok h).2.1⟩

/-- Replaying an OIDC token (same `jti`) after a successful exchange is
refused, whatever the configs are by then. -/
theorem exchange_replay_rejected (used : alloc.vec.Vec (alloc.vec.Vec U8))
    (configs configs' : alloc.vec.Vec trustpub.GitHubConfig) (claims claims' : trustpub.GitHubClaims)
    (ids : alloc.vec.Vec I32) (used' : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : trustpub.exchange_github used configs claims = ok (.Ok (ids, used')))
    (hj : claims'.jti = claims.jti) :
    trustpub.exchange_github used' configs' claims' = ok (.Err .JtiReused) := by
  have hrec := (exchange_ok h).2.1
  have hin : claims'.jti.val ∈ used'.val.map (·.val) := by rw [hrec, hj]; simp
  unfold trustpub.exchange_github
  obtain ⟨b, hb⟩ := ok_of (jti_used_spec used' claims'.jti.deref)
  have := post_of_ok (jti_used_spec used' claims'.jti.deref) hb
  simp only [Verified.Bytes.deref_val] at this
  have hbt : b = true := by rw [← this]; simpa using hin
  subst hbt
  simp [hb]

/-- OIDC tokens from `pull_request_target` and `workflow_run` workflows are
never exchanged. -/
theorem exchange_rejects_forbidden_events (used : alloc.vec.Vec (alloc.vec.Vec U8))
    (configs : alloc.vec.Vec trustpub.GitHubConfig) (claims : trustpub.GitHubClaims)
    (r : alloc.vec.Vec I32 × alloc.vec.Vec (alloc.vec.Vec U8))
    (he : claims.event_name.val = trustpub.PULL_REQUEST_TARGET.val ∨
      claims.event_name.val = trustpub.WORKFLOW_RUN.val) :
    trustpub.exchange_github used configs claims ≠ ok (.Ok r) := by
  intro h
  obtain ⟨ids, used'⟩ := r
  obtain ⟨-, -, h1, h2, -⟩ := exchange_ok h
  rcases he with he | he
  · exact h1 he
  · exact h2 he

end Exchange

end cratesio_kernel.Properties
