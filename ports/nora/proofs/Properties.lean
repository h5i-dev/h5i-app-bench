import Verified.NoraReference
import Verified.NoraRevokeAll
import Verified.NoraReadOnly
import Verified.NoraAuditNeverDenies
import Verified.NoraLifetime
import Verified.NoraAdminPath
import Verified.NoraTokenUnexpired
import Verified.NoraUntrustedPeer
import Verified.NoraCidr
import Verified.NoraDigest
import Spec
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

namespace nora_kernel.Properties

/-- A write goes through only for a role that may write: the first rule
matching the token's subject grants `write` or `admin`. -/
theorem read_only_cannot_write (p : OidcProvider) (c : Claims) (r : Request) (x : Reply)
    (h : transition p c r = ok (.Ok x)) (hw : isWrite r.method) :
    ∃ i, ∃ hi : i < p.role_rules.val.length, FirstMatch p (subject c) i ∧
      (nats (p.role_rules.val[i]).role.val = lit "write" ∨
       nats (p.role_rules.val[i]).role.val = lit "admin") := by
  apply nora_kernel.Verified.NoraReadOnly.read_only_cannot_write <;> assumption

/-- The provider scope is a ceiling: an enforced, namespaced request that
goes through is inside it, unless it contains `*`. -/
theorem provider_ceiling (p : OidcProvider) (c : Claims) (r : Request) (x : Reply) (ns : alloc.vec.Vec U8)
    (h : transition p c r = ok (.Ok x)) (he : p.namespace_scope_enforcement = .Enforce)
    (hn : r.namespace = some ns) (hu : ¬ Unrestricted p.namespace_scope.val) :
    InScope p.namespace_scope.val ns.val := by
  sorry

/-- A rule's scope narrows the provider's: an enforced, namespaced request
that goes through is also inside the matched rule's scope. -/
theorem rule_narrows (p : OidcProvider) (c : Claims) (r : Request) (x : Reply) (ns : alloc.vec.Vec U8)
    (i : Nat) (hi : i < p.role_rules.val.length) (sc : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : transition p c r = ok (.Ok x)) (he : p.namespace_scope_enforcement = .Enforce)
    (hn : r.namespace = some ns) (hm : FirstMatch p (subject c) i)
    (hs : (p.role_rules.val[i]).namespace_scope = some sc) (hu : ¬ Unrestricted sc.val) :
    InScope sc.val ns.val := by
  sorry

/-- In audit mode a namespace mismatch is logged, never denied. -/
theorem audit_never_denies (p : OidcProvider) (c : Claims) (r : Request)
    (ha : p.namespace_scope_enforcement = .Audit) :
    transition p c r ≠ ok (.Err .NamespaceDenied) := by
  apply nora_kernel.Verified.NoraAuditNeverDenies.audit_never_denies <;> assumption

/-- A token whose lifetime exceeds the provider's ceiling is refused. -/
theorem lifetime_bounded (p : OidcProvider) (c : Claims) (r : Request) (x : Reply) (iat exp : U64)
    (h : transition p c r = ok (.Ok x)) (hi : c.iat = some iat) (he : c.exp = some exp) :
    exp.val - iat.val ≤ p.max_token_lifetime_secs.val := by
  apply nora_kernel.Verified.NoraLifetime.lifetime_bounded <;> assumption

/-- The subject matcher computes `globSpec`, for a pattern shorter than
`Usize.max`. Aeneas lets a slice be `Usize.max` long; a pattern of that many `*`
bytes then splits into `Usize.max + 1` parts, more than a modeled `Vec` holds,
and the function fails. Rust slices hold at most `isize::MAX` bytes, so the bound
only excludes lengths Rust cannot have. -/
theorem glob_match_spec (pattern v : Slice U8) (hlt : pattern.length < Usize.max) :
    glob_match pattern v = ok (globSpec (nats pattern.val) (nats v.val)) := by
  sorry

/-- The backtracking segment matcher agrees with the plain recursive glob. -/
theorem segment_glob_spec (pattern v : Slice U8) :
    segment_glob pattern v = ok (segGlobSpec (nats pattern.val) (nats v.val)) := by
  sorry

/-- The kernel never panics, overflows or loops, for role-rule patterns shorter
than `Usize.max` (see `glob_match_spec`: a longer one splits into more parts than
a modeled `Vec` holds; Rust cannot allocate such a pattern). -/
theorem transition_total (p : OidcProvider) (c : Claims) (r : Request)
    (hpat : ∀ rule ∈ p.role_rules.val, rule.pattern.length < Usize.max) :
    ∃ y, transition p c r = ok y := by
  sorry

/-! ## The middleware -/

/-- An admin path reaches its handler only with an admin role. -/
theorem admin_path_needs_admin (cfg : middleware.Config) (fs : Slice lockout.FailureEntry)
    (cr : oracle.Crypto) (jw : Option middleware.Jwt) (req : middleware.Request)
    (ws : alloc.vec.Vec middleware.Write) (a : NamespaceAuthority) (u : alloc.vec.Vec U8) (r : Option Role)
    (he : cfg.enabled = true) (hp : isAdminPath (nats req.path.val))
    (h : middleware.auth_middleware cfg fs cr jw req = ok (ws, .Next a u r)) :
    r = some .Admin := by
  apply nora_kernel.Verified.NoraAdminPath.admin_path_needs_admin <;> assumption

/-- Without credentials a request never gets a role that can write. -/
theorem no_credentials_no_write_role (cfg : middleware.Config) (fs : Slice lockout.FailureEntry)
    (cr : oracle.Crypto) (jw : Option middleware.Jwt) (req : middleware.Request)
    (ws : alloc.vec.Vec middleware.Write) (a : NamespaceAuthority) (u : alloc.vec.Vec U8) (r : Option Role)
    (he : cfg.enabled = true) (hn : req.auth_header = none)
    (h : middleware.auth_middleware cfg fs cr jw req = ok (ws, .Next a u r)) :
    r = none ∨ r = some .Read := by
  sorry

/-- A write method on a gated path, other than the npm audit endpoints,
reaches its handler only with a role that can write. -/
theorem writes_need_write_role (cfg : middleware.Config) (fs : Slice lockout.FailureEntry)
    (cr : oracle.Crypto) (jw : Option middleware.Jwt) (req : middleware.Request)
    (ws : alloc.vec.Vec middleware.Write) (a : NamespaceAuthority) (u : alloc.vec.Vec U8) (r : Option Role)
    (he : cfg.enabled = true) (hw : isWriteMethod req.method)
    (ho : ¬ IsOpen cfg (nats req.path.val)) (hn : isNpmAudit (nats req.path.val) = false)
    (h : middleware.auth_middleware cfg fs cr jw req = ok (ws, .Next a u r)) :
    r = some .Write ∨ r = some .Admin := by
  sorry

/-- A locked-out client authenticates only on open paths. -/
theorem locked_out_only_open (cfg : middleware.Config) (fs : Slice lockout.FailureEntry)
    (cr : oracle.Crypto) (jw : Option middleware.Jwt) (req : middleware.Request)
    (ws : alloc.vec.Vec middleware.Write) (a : NamespaceAuthority) (u : alloc.vec.Vec U8) (r : Option Role)
    (peer ip : net.IpAddr) (secs : U64)
    (he : cfg.enabled = true) (hp : req.peer = some peer)
    (hip : net.resolve_client_ip peer req.xff req.x_real_ip cfg.trusted_proxies = ok ip)
    (hb : lockout.AuthFailureTracker.check_blocked cfg.tracker fs ip req.mono = ok (some secs))
    (hu : nats u.val ≠ lit "anonymous")
    (h : middleware.auth_middleware cfg fs cr jw req = ok (ws, .Next a u r)) :
    IsOpen cfg (nats req.path.val) := by
  sorry

/-- `/v2/_catalog` and the token pages are never served without credentials. -/
theorem catalog_and_token_pages_need_credentials (cfg : middleware.Config)
    (fs : Slice lockout.FailureEntry) (cr : oracle.Crypto) (jw : Option middleware.Jwt)
    (req : middleware.Request) (ws : alloc.vec.Vec middleware.Write) (o : middleware.Outcome)
    (he : cfg.enabled = true)
    (hp : nats req.path.val = lit "/v2/_catalog" ∨ isTokenPage (nats req.path.val))
    (h : middleware.auth_middleware cfg fs cr jw req = ok (ws, o)) (hpass : Passes o) :
    req.auth_header ≠ none := by
  sorry

/-- A failure is recorded only when the credentials were wrong. -/
theorem failure_recorded_only_for_bad_credentials (cfg : middleware.Config)
    (fs : Slice lockout.FailureEntry) (cr : oracle.Crypto) (jw : Option middleware.Jwt)
    (req : middleware.Request) (ws : alloc.vec.Vec middleware.Write) (o : middleware.Outcome)
    (e : lockout.FailureEntry)
    (h : middleware.auth_middleware cfg fs cr jw req = ok (ws, o)) (hw : .PutFailures e ∈ ws.val) :
    o = .Deny .InvalidOrExpiredToken ∨ o = .Deny .InvalidUsernameOrPassword := by
  sorry

/-- The failure count is cleared only when the credentials were right. -/
theorem failures_cleared_only_for_good_credentials (cfg : middleware.Config)
    (fs : Slice lockout.FailureEntry) (cr : oracle.Crypto) (jw : Option middleware.Jwt)
    (req : middleware.Request) (ws : alloc.vec.Vec middleware.Write) (o : middleware.Outcome)
    (ip : net.IpAddr)
    (h : middleware.auth_middleware cfg fs cr jw req = ok (ws, o)) (hw : .ClearFailures ip ∈ ws.val) :
    Passes o ∨ o = .Deny .ReadOnlyToken ∨ o = .Deny .ReadOnlyOidc ∨ o = .Deny .AdminRequired := by
  sorry

/-- An API token is accepted only with the `nra_` prefix and only while a
cached or stored record for it has not expired. -/
theorem token_accepted_only_unexpired (store : tokens.TokenStore) (cr : oracle.Crypto)
    (t : Slice U8) (now mono : U64) (ws : alloc.vec.Vec tokens.TokenWrite) (u : alloc.vec.Vec U8) (r : Role)
    (h : tokens.verify_token store cr t now mono = ok (ws, .Ok (u, r))) :
    lit "nra_" <+: nats t.val ∧
      ((∃ c ∈ store.cache.val, c.user = u ∧ c.role = r ∧ now.val ≤ c.expires_at.val) ∨
       (∃ f ∈ store.files.val, ∃ i, f.info = some i ∧ i.user = u ∧ i.role = r ∧
         now.val ≤ i.expires_at.val)) := by
  apply nora_kernel.Verified.NoraTokenUnexpired.token_accepted_only_unexpired <;> assumption

/-- Forwarding headers from an untrusted peer are ignored. -/
theorem untrusted_peer_is_client (tp : net.TrustedProxies) (peer : net.IpAddr)
    (xff xri : Option net.IpAddr) (hc : cidrContains tp.entries.val peer = false) :
    net.resolve_client_ip peer xff xri tp = ok peer := by
  apply nora_kernel.Verified.NoraUntrustedPeer.untrusted_peer_is_client <;> assumption

/-- `TrustedProxies::contains` compares the top `prefix` bits. -/
theorem trusted_proxies_contains_spec (tp : net.TrustedProxies) (ip : net.IpAddr) :
    net.TrustedProxies.contains tp ip = ok (cidrContains tp.entries.val ip) := by
  apply nora_kernel.Verified.NoraCidr.trusted_proxies_contains_spec <;> assumption

/-- A revoked token is refused afterwards, also when it was cached. -/
theorem revoked_token_rejected (store store' : tokens.TokenStore) (cr : oracle.Crypto) (p t : Slice U8)
    (sha : alloc.vec.Vec U8) (now mono : U64) (ws : alloc.vec.Vec tokens.TokenWrite)
    (res : core.result.Result (alloc.vec.Vec U8 × Role) tokens.TokenError)
    (hr : tokens.revoke_token store p = ok (store', .Ok ()))
    (hs : oracle.Crypto.sha256_hex cr t = ok sha) (hp : p.val <+: sha.val)
    (h : tokens.verify_token store' cr t now mono = ok (ws, res)) :
    ∃ e, res = .Err e := by
  sorry

/-- Once `revoke_all_for_user` removed a token of a user, no token
authenticates as that user. -/
theorem revoke_all_effective (store store' : tokens.TokenStore) (cr : oracle.Crypto) (user t : Slice U8)
    (n : Usize) (now mono : U64) (ws : alloc.vec.Vec tokens.TokenWrite) (u : alloc.vec.Vec U8) (r : Role)
    (hr : tokens.revoke_all_for_user store user = ok (store', n)) (hn : 0 < n.val)
    (h : tokens.verify_token store' cr t now mono = ok (ws, .Ok (u, r))) :
    u.val ≠ user.val := by
  apply nora_kernel.Verified.NoraRevokeAll.revoke_all_effective <;> assumption

/-! ## Validators -/

/-- An accepted storage key stays inside its directory. -/
theorem storage_key_safe (k : Slice U8) (h : validation.validate_storage_key k = ok (.Ok ())) :
    SafeKey (nats k.val) := by
  sorry

/-- An accepted Docker name has the OCI shape. -/
theorem docker_name_shape (n : Slice U8) (h : validation.validate_docker_name n = ok (.Ok ())) :
    DockerNameShape (nats n.val) := by
  sorry

/-- `validate_digest` accepts exactly the `sha256`/`sha512` digests. -/
theorem digest_iff (d : Slice U8) :
    validation.validate_digest d = ok (.Ok ()) ↔ DigestShape (nats d.val) := by
  apply nora_kernel.Verified.NoraDigest.digest_iff <;> assumption

/-- An accepted reference is a digest or a tag. -/
theorem reference_shape (x : Slice U8) (h : validation.validate_docker_reference x = ok (.Ok ())) :
    DigestShape (nats x.val) ∨ TagShape (nats x.val) := by
  apply nora_kernel.Verified.NoraReference.reference_shape <;> assumption

/-- The middleware never panics or loops, as long as no failure counter is at
`u32::MAX` and every OIDC role-rule pattern is shorter than `Usize.max` (see
`transition_total`; Rust cannot allocate a longer one). -/
theorem middleware_total (cfg : middleware.Config) (fs : Slice lockout.FailureEntry)
    (cr : oracle.Crypto) (jw : Option middleware.Jwt) (req : middleware.Request)
    (hf : ∀ e ∈ fs.val, e.failures.val < U32.max)
    (hpat : ∀ p b, cfg.oidc = some (p, b) → ∀ rule ∈ p.role_rules.val, rule.pattern.length < Usize.max) :
    ∃ y, middleware.auth_middleware cfg fs cr jw req = ok y := by
  sorry

end nora_kernel.Properties
