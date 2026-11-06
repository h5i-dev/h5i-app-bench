import Verified.Validate
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

/-- F: the kernel's (and upstream's) lifetime check computes `exp - iat` in
`i64`. For `exp = i64::MAX, iat = -10` that overflows: the extracted kernel
fails (Rust debug: panic) instead of refusing; upstream's release build wraps
and accepts the token (difftest `upstream_release_wraps_lifetime_check`). -/
theorem lifetime_check_overflows (c : Claims) (hv : c.v = 1#u8) (he : c.exp.val = I64.max)
    (hi : c.iat.val = -10) (r) : check_claims c 1791937000#i64 ≠ ok r :=
  Verified.check_claims_overflow c hv he hi r

end openobserve_kernel.Properties
