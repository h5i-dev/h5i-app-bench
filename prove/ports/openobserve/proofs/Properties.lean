import Verified.Grpc
/-!
# Security properties of OpenObserve's delegated (`o2dt.`) tokens

Each theorem is about the extracted kernel (`validate_delegated`, `verify`,
`check_claims`) and is stated in terms of the request's inputs: the token, its
decoded claims and MACs (`VerifyOracle`, filled by the shell from HMAC-SHA256,
base64 and JSON), and the stores (`DelegationEnv`). Lean integers do not wrap,
so "exp - iat ≤ 3660" is exact arithmetic.
-/
open Aeneas Aeneas.Std Result openobserve_kernel openobserve_kernel.Spec openobserve_kernel.Verified
open openobserve_kernel.delegation

namespace openobserve_kernel.Properties

/-- The decoded claims behind an accepted delegated request. -/
theorem accepted_claims {env o now t path pfx m d}
    (h : validate_delegated env o now t path pfx m = ok (.Ok d)) :
    ∃ c, o.claims = some c ∧ ClaimsFresh c now.val ∧ SignatureOk o ∧ d.org = c.org ∧ d.user_email = c.sub := by
  obtain ⟨c, hv, -, -, -, -, -, -, he, ho, -, -⟩ := Verified.validate_delegated_ok h
  obtain ⟨-, hs, hc, hf⟩ := Verified.verify_ok t o now c hv
  exact ⟨c, hc, hf, hs, ho, he⟩

/-- S: no delegated request is accepted on an expired token. -/
theorem expired_token_never_accepted {env o now t path pfx m d}
    (h : validate_delegated env o now t path pfx m = ok (.Ok d)) :
    ∃ c, o.claims = some c ∧ now.val < c.exp.val := by
  obtain ⟨c, hc, ⟨_, he, _, _⟩, _⟩ := accepted_claims h
  exact ⟨c, hc, he⟩

/-- S: no delegated request is accepted unless the token's MAC equals the
MAC under the current key, or under the previous key when one is configured. -/
theorem forged_token_never_accepted {env o now t path pfx m d}
    (h : validate_delegated env o now t path pfx m = ok (.Ok d)) :
    ∃ g, o.given_mac = some g ∧
      (nats o.mac_current.val = nats g.val ∨ ∃ p, o.mac_previous = some p ∧ nats p.val = nats g.val) := by
  obtain ⟨c, -, -, hs, -⟩ := accepted_claims h
  exact hs

/-- S: with no previous key configured, only the current key's MAC verifies. -/
theorem previous_key_only_when_configured {env o now t path pfx m d}
    (hp : o.mac_previous = none) (h : validate_delegated env o now t path pfx m = ok (.Ok d)) :
    ∃ g, o.given_mac = some g ∧ nats o.mac_current.val = nats g.val := by
  obtain ⟨g, hg, h1 | ⟨p, hp', _⟩⟩ := forged_token_never_accepted h
  · exact ⟨g, hg, h1⟩
  · rw [hp] at hp'; cases hp'

/-- S: an accepted token expires within 3720 s of now (issued at most 60 s
ahead, living at most 3660 s), whatever `exp` it claims. -/
theorem accepted_token_lifetime_bounded {env o now t path pfx m d}
    (h : validate_delegated env o now t path pfx m = ok (.Ok d)) :
    ∃ c, o.claims = some c ∧ c.v.val = 1 ∧ c.exp.val ≤ now.val + 3720 := by
  obtain ⟨c, hc, ⟨hv, _, hi, hl⟩, _⟩ := accepted_claims h
  exact ⟨c, hc, hv, by omega⟩

/-- S: the identity a delegated request runs as is a member of the token's
org, with that membership's role; neither the org nor the role comes from
anywhere else. -/
theorem delegated_identity_is_org_member {env o now t path pfx m d}
    (h : validate_delegated env o now t path pfx m = ok (.Ok d)) :
    ∃ u ∈ env.members.val, nats u.org.val = nats d.org.val ∧ nats u.email.val = nats d.user_email.val ∧
      u.role = d.user_role ∧ d.is_internal_user = !u.is_external := by
  obtain ⟨c, -, -, -, -, -, -, ⟨u, hu, ho, he, hr, hi, -⟩, hde, hdo, -, -⟩ := Verified.validate_delegated_ok h
  exact ⟨u, hu, by rw [hdo]; exact ho, by rw [hde]; exact he, hr.symm, hi⟩

/-- S: revoking a link revokes every token minted for it: if each link row
with the token's link id is revoked, nothing is accepted. -/
theorem revoked_link_denies {env o now t path pfx m d}
    (hrev : ∀ l ∈ env.links.val, nats l.id.val = nats d.link_id.val → l.revoked = true)
    (h : validate_delegated env o now t path pfx m = ok (.Ok d)) : False := by
  obtain ⟨c, -, -, -, -, -, ⟨l, hl, hid, hr, -⟩, -, -, -, hlid, -⟩ := Verified.validate_delegated_ok h
  have := hrev l hl (by rw [hlid]; exact hid)
  simp_all

/-- S: the token's subject is the user the link belongs to, and the link's
installation is live and serves the token's org. -/
theorem delegated_subject_is_linked_user {env o now t path pfx m d}
    (h : validate_delegated env o now t path pfx m = ok (.Ok d)) :
    ∃ l ∈ env.links.val, nats l.id.val = nats d.link_id.val ∧ l.revoked = false ∧
      nats l.user_email.val = nats d.user_email.val ∧
      ∃ i ∈ env.installations.val, nats i.id.val = nats l.installation_id.val ∧ i.revoked = false ∧
        nats d.org.val ∈ i.served_orgs.val.map (fun v => nats v.val) := by
  obtain ⟨c, -, -, -, -, -, ⟨l, hl, hid, hr, hue, i, hi, hiid, hir, hio⟩, -, hde, hdo, hlid, -⟩ :=
    Verified.validate_delegated_ok h
  refine ⟨l, hl, by rw [hlid]; exact hid, hr, by rw [hde]; exact hue, i, hi, hiid, hir, by rw [hdo]; exact hio⟩

/-- S: with Slack integration off, or the org's Slack disabled, no delegated
token is accepted. -/
theorem slack_off_denies {env o now t path pfx m d}
    (h : validate_delegated env o now t path pfx m = ok (.Ok d)) :
    env.slack_on = true ∧ env.keys_ok = true ∧
      nats d.org.val ∉ env.disabled_orgs.val.map (fun v => nats v.val) := by
  obtain ⟨c, -, hs, hk, hd, -, -, -, -, hdo, -⟩ := Verified.validate_delegated_ok h
  exact ⟨hs, hk, by rw [hdo]; exact hd⟩

/-- S: an external identity the domain blocklist denies is never accepted. -/
theorem blocked_external_denied {env o now t path pfx m d}
    (h : validate_delegated env o now t path pfx m = ok (.Ok d))
    (hb : nats d.user_email.val ∈ env.denied.val.map (fun v => nats v.val)) :
    d.is_internal_user = true := by
  obtain ⟨c, -, -, -, -, -, -, ⟨u, -, -, he, -, hi, hn⟩, hde, -⟩ := Verified.validate_delegated_ok h
  cases hx : u.is_external
  · simp [hi, hx]
  · exfalso; apply hn; refine ⟨hx, ?_⟩; rw [he, ← hde]; exact hb

/-- The route check behind an accepted request, as the `Spec` model. -/
theorem accepted_route {env o now t path pfx m d}
    (hp : path.length < Usize.max) (h : validate_delegated env o now t path pfx m = ok (.Ok d)) :
    checkRoute (nats path.val) (nats pfx.val) m (nats d.org.val) (nats d.scope.val) = .Ok () := by
  obtain ⟨c, -, -, -, -, hr, -, -, -, hdo, -, hds⟩ := Verified.validate_delegated_ok h
  have := H5iAppLib.post_of_ok (Verified.check_route_spec path pfx m c hp) hr
  rw [hdo, hds, ← this]

/-- S (cross-org isolation): an accepted delegated request names the token's
org in its path (`/{org}/…` or `/v2/{org}/…`). A token for org A never
authorizes a route of org B. -/
theorem delegated_route_in_token_org {env o now t path pfx m d}
    (hp : path.length < Usize.max) (h : validate_delegated env o now t path pfx m = ok (.Ok d)) :
    pathOrg (relativePath (nats path.val)) = some (nats d.org.val) :=
  (Verified.checkRoute_ok (accepted_route hp h)).2.1

/-- S: delegated tokens only read, create and patch: never DELETE, PUT or
any other method. -/
theorem delegated_methods_limited {env o now t path pfx m d}
    (hp : path.length < Usize.max) (h : validate_delegated env o now t path pfx m = ok (.Ok d)) :
    m = .Get ∨ m = .Post ∨ m = .Patch := by
  obtain ⟨-, -, routes, hr, hin⟩ := Verified.checkRoute_ok (accepted_route hp h)
  obtain ⟨-, r, hrm, hm, -⟩ := Verified.inScope_true hin
  exact Verified.scope_methods r (Verified.scopeRoutes_sub hr r hrm) m hm

/-- S: proxy routes are never reachable with a delegated token. -/
theorem delegated_never_on_proxy {env o now t path pfx m d}
    (hp : path.length < Usize.max) (h : validate_delegated env o now t path pfx m = ok (.Ok d)) :
    nats pfx.val ≠ [47, 112, 114, 111, 120, 121, 47] /- /proxy/ -/ :=
  (Verified.checkRoute_ok (accepted_route hp h)).1

/-- S: a `slack_action` token (minted for Slack alert buttons) only reaches
`…/{org}/alerts/…` and `…/{org}/oncall/…` routes. -/
theorem slack_action_only_alerts_and_oncall {env o now t path pfx m d}
    (hp : path.length < Usize.max) (h : validate_delegated env o now t path pfx m = ok (.Ok d))
    (hs : nats d.scope.val = [115, 108, 97, 99, 107, 95, 97, 99, 116, 105, 111, 110] /- slack_action -/) :
    let rel := relativePath (nats path.val)
    let rest := if [118, 50, 47] <+: rel then rel.drop 3 else rel
    (splitSlash rest)[1]? = some Verified.alertsLit ∨ (splitSlash rest)[1]? = some Verified.oncallLit := by
  obtain ⟨-, -, routes, hr, hin⟩ := Verified.checkRoute_ok (accepted_route hp h)
  rw [hs] at hr
  have hr' : routes = slackActionScope := by
    unfold scopeRoutes at hr
    rw [if_neg (by decide), if_pos rfl] at hr
    exact (Option.some.inj hr).symm
  subst hr'
  obtain ⟨-, r, hrm, -, -, hseg⟩ := Verified.inScope_true hin
  rcases Verified.slack_scope_second r hrm with h1 | h1
  · exact Or.inl (Verified.segsMatch_lit hseg h1)
  · exact Or.inr (Verified.segsMatch_lit hseg h1)

/-- S (the two org checks agree): for an accepted delegated request, the org
the `AuthExtractor` derives from the same path (`org_from_path`, which the
permission check and user lookup use) is the token's org. A route whose org
slot the delegation check reads differently from RBAC would break this. -/
theorem delegated_org_is_rbac_org {env o now t path pfx m d}
    (hp : path.length < Usize.max) (h : validate_delegated env o now t path pfx m = ok (.Ok d)) :
    ∃ e, auth.extractor_org_id path = ok e ∧ nats e.val = nats d.org.val := by
  have hc := Verified.checkRoute_org_consistent (accepted_route hp h)
  have hs := Verified.extractor_org_id_spec path hp
  obtain ⟨e, he⟩ := H5iAppLib.ok_of hs
  exact ⟨e, he, by rw [H5iAppLib.post_of_ok hs he, hc]⟩

/-! ## gRPC authentication (`api/grpc/src/handler/grpc/auth/mod.rs`) -/

/-- S: node-to-node RPCs (`check_internal_auth`) accept only the internal or
super-cluster token, never an empty one, an org ingestion token or a user
credential. -/
theorem internal_rpc_only_internal_token {env tok a}
    (h : grpc.check_internal_auth env tok = ok (.Ok a)) :
    ∃ t, tok = some t ∧ t.val ≠ [] ∧
      (nats t.val = nats env.internal_token.val ∨ ∃ x, env.super_cluster_token = some x ∧ nats x.val = nats t.val) :=
  (Verified.check_internal_auth_ok h).2

/-- S: an empty `authorization` value never authenticates, even when the
internal token is unset (empty). -/
theorem grpc_empty_token_never_authenticates {env tok org creds allow a}
    (h : grpc.check_auth_inner env tok org creds allow = ok (.Ok a)) : ∃ t, tok = some t ∧ t.val ≠ [] := by
  cases a with
  | Internal => obtain ⟨t, ht, hn, -⟩ := Verified.check_auth_inner_internal h; exact ⟨t, ht, hn⟩
  | User uid => obtain ⟨t, -, -, ht, hn, -⟩ := Verified.check_auth_inner_user h; exact ⟨t, ht, hn⟩

/-- S: a blank password never authenticates a user, so it can never match a
token or hash that is stored blank. The attached `user_id` is the one presented. -/
theorem grpc_empty_password_never_authenticates {env tok org creds allow uid}
    (h : grpc.check_auth_inner env tok org creds allow = ok (.Ok (.User uid))) :
    ∃ c, creds = some c ∧ c.password.val ≠ [] ∧ nats uid.val = nats c.user_id.val := by
  obtain ⟨-, -, c, -, -, -, hc, hp, hu, -⟩ := Verified.check_auth_inner_user h
  exact ⟨c, hc, hp, hu⟩

/-- S: an org ingestion token (`o2oi_…`) authenticates only in the org whose
cache holds it: the key `"{org header}/{token}"` is in `ORG_INGESTION_TOKENS`. -/
theorem ingestion_token_scoped_to_header_org {env tok org creds uid}
    (h : grpc.check_auth_inner env tok org creds true = ok (.Ok (.User uid))) :
    ∃ o c, org = .Value o ∧ creds = some c ∧
      ([111, 50, 111, 105, 95] <+: nats c.password.val →
        joinKey (nats o.val) (nats c.password.val) ∈ env.ingestion_keys.val.map (fun k => nats k.val)) := by
  obtain ⟨-, o, c, -, -, ho, hc, -, -, hcase⟩ := Verified.check_auth_inner_user h
  refine ⟨o, c, ho, hc, fun hp => ?_⟩
  rcases hcase with ⟨-, -, hk⟩ | ⟨hn, -⟩
  · exact hk
  · exact absurd hp (hn rfl)

/-- S: outside the OTLP services (`allow_org_ingestion_token = false`), the
ingestion-token table plays no part: every accepted user credential matched a
user record's token or password. -/
theorem ingestion_token_only_on_otlp {env tok org creds uid}
    (h : grpc.check_auth_inner env tok org creds false = ok (.Ok (.User uid))) :
    ∃ o c u, org = .Value o ∧ creds = some c ∧
      Verified.UserFacts env (nats o.val) (nats c.user_id.val) u ∧ Verified.CredentialOk env u c := by
  obtain ⟨-, o, c, -, -, ho, hc, -, -, hcase⟩ := Verified.check_auth_inner_user h
  rcases hcase with ⟨hf, -⟩ | ⟨-, u, hu, hok⟩
  · cases hf
  · exact ⟨o, c, u, ho, hc, hu, hok⟩

/-- S (cross-org isolation): a non-root user credential authenticates only
through the membership record of the header org (`"{org}/{lowercased id}"`),
with that record's token or the user's password. -/
theorem grpc_user_is_member_of_header_org {env tok org creds allow uid}
    (h : grpc.check_auth_inner env tok org creds allow = ok (.Ok (.User uid))) :
    ∃ o c, org = .Value o ∧ creds = some c ∧
      ((allow = true ∧ joinKey (nats o.val) (nats c.password.val) ∈ env.ingestion_keys.val.map (fun k => nats k.val)) ∨
       Verified.IsRoot env (nats c.user_id.val) ∨
       ∃ ou ∈ env.org_users.val, nats ou.key.val = joinKey (nats o.val) (asciiLower (nats c.user_id.val)) ∧
         ∃ ur ∈ env.users.val, nats ur.key.val = asciiLower (nats c.user_id.val) ∧
           (nats ou.token.val = nats c.password.val ∨
            (nats c.user_id.val = nats ur.email.val ∧ ∃ hv,
              ((env.hashes.val.find? (Verified.hashP (nats c.password.val) (nats ur.salt.val))).map (·.hash)).getD none = some hv ∧
              nats hv.val = nats ur.password.val))) := by
  obtain ⟨-, o, c, -, -, ho, hc, -, -, hcase⟩ := Verified.check_auth_inner_user h
  refine ⟨o, c, ho, hc, ?_⟩
  rcases hcase with ⟨ha, -, hk⟩ | ⟨-, u, hu, hok⟩
  · exact Or.inl ⟨ha, hk⟩
  · rcases hu with ⟨hr, -⟩ | ⟨-, ou, hou, hk, ur, hur, hk2, rfl⟩
    · exact Or.inr (Or.inl hr)
    · exact Or.inr (Or.inr ⟨ou, hou, hk, ur, hur, hk2, hok⟩)

/-- S: an SSO user (stored with an empty salt, which `try_get_hash` refuses)
authenticates only with its API token, never with a password. -/
theorem sso_credential_is_token {env : grpc.GrpcEnv} {c : grpc.Credentials} {u : grpc.User}
    (hsalt : u.salt.val = [])
    (hnone : ∀ r ∈ env.hashes.val, r.salt.val = [] → r.hash = none)
    (hok : Verified.CredentialOk env u c) : nats u.token.val = nats c.password.val := by
  rcases hok with ht | ⟨-, hv, hf, -⟩
  · exact ht
  · exfalso
    cases hfind : env.hashes.val.find? (Verified.hashP (nats c.password.val) (nats u.salt.val)) with
    | none => rw [hfind] at hf; cases hf
    | some r =>
      rw [hfind] at hf
      have hm := List.mem_of_find?_eq_some hfind
      have hp := List.find?_some hfind
      simp only [Verified.hashP, Bool.and_eq_true, decide_eq_true_eq, hsalt] at hp
      have hs : r.salt.val = [] := by simpa [nats] using hp.2
      simp [hnone r hm hs] at hf

/-- S: an SSO user (stored with an empty salt, which `try_get_hash` refuses)
authenticates outside OTLP only with its API token, never with a password. -/
theorem sso_user_needs_token {env tok org creds uid}
    (hnone : ∀ r ∈ env.hashes.val, r.salt.val = [] → r.hash = none)
    (h : grpc.check_auth_inner env tok org creds false = ok (.Ok (.User uid))) :
    ∃ o c u, org = .Value o ∧ creds = some c ∧ Verified.UserFacts env (nats o.val) (nats c.user_id.val) u ∧
      (u.salt.val = [] → nats u.token.val = nats c.password.val) := by
  obtain ⟨o, c, u, ho, hc, hu, hok⟩ := ingestion_token_only_on_otlp h
  exact ⟨o, c, u, ho, hc, hu, fun hs => sso_credential_is_token hs hnone hok⟩

/-- F: the kernel's (and upstream's) lifetime check computes `exp - iat` in
`i64`. For `exp = i64::MAX, iat = -10` that overflows: the extracted kernel
fails (Rust debug: panic) instead of refusing; upstream's release build wraps
and accepts the token (difftest `upstream_release_wraps_lifetime_check`). -/
theorem lifetime_check_overflows (c : Claims) (hv : c.v = 1#u8) (he : c.exp.val = I64.max)
    (hi : c.iat.val = -10) (r) : check_claims c 1791937000#i64 ≠ ok r :=
  Verified.check_claims_overflow c hv he hi r

end openobserve_kernel.Properties
