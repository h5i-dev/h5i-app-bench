import Verified.ClosedRecords
import Verified.FiniteCatalog
import Verified.TokenScope
import Verified.TotpPolicy
import Verified.TokenExpiry
import Verified.ArtifactkeeperAnonymousNeverMutates
import Verified.ArtifactkeeperAnonymousNeedsRule
import Verified.ArtifactkeeperMutationNeedsAction
import Verified.ArtifactkeeperScopedToken
import Verified.ArtifactkeeperTicketReadOnly
import Verified.ArtifactkeeperTicketConsumed
import Verified.ArtifactkeeperVisibilityTotal
import Verified.ArtifactkeeperRepoActionSpec
import Verified.ArtifactkeeperGuestBlocksAnonymous
import Verified.ArtifactkeeperAnonymousRuleRead
import Verified.ArtifactkeeperScopesGrant
import Verified.ArtifactkeeperAdminAudited
import Verified.ArtifactkeeperOnlyAdminRules
import Verified.ArtifactkeeperPrivateNeedsGrant
import Verified.ArtifactkeeperRuleOverridesRole
import Verified.ArtifactkeeperCidrContains
import Verified.ArtifactkeeperAdminGate
import Spec
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit

namespace artifactkeeper_kernel.Properties

/-! ## `repo_visibility_middleware` -/

/-- A PUT, PATCH or DELETE reaches a format handler only with a principal,
and never on a download ticket (#508). -/
theorem anonymous_never_mutates (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (auth : Option AuthExtension) (t : Bool)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, .Next auth t))
    (hm : isMutation req.method) :
    auth.isSome ∧ t = false := by
  apply artifactkeeper_kernel.Verified.ArtifactkeeperAnonymousNeverMutates.anonymous_never_mutates <;> assumption

/-- An anonymous request reaches a repository that is not public only
through an anonymous `read` rule that applies to the client IP (#1849). -/
theorem anonymous_needs_rule (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (t : Bool) (r : tables.Repository)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, .Next none t))
    (hr : RepoOf db req r) (hv : r.visibility ≠ some .Public) :
    AnonymousRead db ip r.id := by
  apply artifactkeeper_kernel.Verified.ArtifactkeeperAnonymousNeedsRule.anonymous_needs_rule <;> assumption

/-- A non-admin principal reaches a private repository only if it holds a
grant on it: a role assignment or an applicable rule. -/
theorem private_needs_grant (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (e : AuthExtension) (t : Bool)
    (r : tables.Repository)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, .Next (some e) t))
    (ha : e.is_admin = false) (hr : RepoOf db req r)
    (hv : r.visibility ≠ some .Public ∧ r.visibility ≠ some .Internal) :
    HasGrant db ip e.user_id r.id := by
  apply artifactkeeper_kernel.Verified.ArtifactkeeperPrivateNeedsGrant.private_needs_grant <;> assumption

/-- Writes are deny-by-default (#2603): a non-admin PUT, PATCH or DELETE
outside the negotiation routes goes through only if `check_repository_action`'s
rule grants the action. -/
theorem mutation_needs_action (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (e : AuthExtension) (t : Bool)
    (r : tables.Repository)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, .Next (some e) t))
    (ha : e.is_admin = false) (hm : isMutation req.method) (hn : ¬ NonMutatingPost req)
    (hr : RepoOf db req r) :
    RepoAction db ip e.user_id r.id (writeAction req.method) := by
  apply artifactkeeper_kernel.Verified.ArtifactkeeperMutationNeedsAction.mutation_needs_action <;> assumption

/-- A repository-restricted credential reaches a repository outside its
allowlist only to read a public one (#504, #3648). -/
theorem scoped_token_confined (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (e : AuthExtension) (t : Bool)
    (r : tables.Repository) (ids : alloc.vec.Vec U64)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, .Next (some e) t))
    (hs : e.allowed_repo_ids = .Restricted ids) (hr : RepoOf db req r) (hi : r.id ∉ ids.val) :
    r.visibility = some .Public ∧ ¬ isMutation req.method := by
  apply artifactkeeper_kernel.Verified.ArtifactkeeperScopedToken.scoped_token_confined <;> assumption

/-- A download ticket authorizes only GET or HEAD, as a non-admin principal
with no scopes. -/
theorem ticket_read_only (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (auth : Option AuthExtension)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, .Next auth true)) :
    (req.method = .Get ∨ req.method = .Head) ∧
    ∃ e, auth = some e ∧ e.is_admin = false ∧ e.scopes.map (·.val) = some [] := by
  apply artifactkeeper_kernel.Verified.ArtifactkeeperTicketReadOnly.ticket_read_only <;> assumption

/-- A ticket is consumed only by a GET or HEAD, and only if it is live. -/
theorem ticket_consumed_on_read (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (out : middleware.Outcome)
    (tk : alloc.vec.Vec U8)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, out))
    (hw : resolve.Write.DeleteTicket tk ∈ ws.val) :
    (req.method = .Get ∨ req.method = .Head) ∧ ∃ x ∈ db.tickets.val, x.ticket = tk ∧ x.live = true := by
  apply artifactkeeper_kernel.Verified.ArtifactkeeperTicketConsumed.ticket_consumed_on_read <;> assumption

/-- The middleware never panics, overflows or loops, for request byte strings
shorter than `Usize.max`. Aeneas lets a slice be `Usize.max` long; a Cookie
header of that many `;` splits into more parts than a modeled `Vec` holds.
A query is bounded by half that, since decoding a ticket can double its
bytes, and permission rows list fewer than `Usize.max` actions in total (their
union is collected). Rust cannot allocate such a request, so the bounds only exclude lengths
Rust cannot have. -/
theorem repo_visibility_total (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request)
    (hreq : req.path.length < Usize.max ∧ (∀ q, req.query = some q → 2 * q.length < Usize.max) ∧
      ∀ h ∈ req.headers.val, h.1.length < Usize.max ∧ h.2.length < Usize.max)
    (hdb : (db.permissions.val.map (·.actions.length)).sum < Usize.max) :
    ∃ y, middleware.repo_visibility_middleware db o ip req = ok y := by
  apply artifactkeeper_kernel.Verified.ArtifactkeeperVisibilityTotal.repo_visibility_total <;> assumption

/-! ## `PermissionService` -/

/-- `check_repository_action` computes its SQL: `RepoAction`. -/
theorem check_repository_action_spec (db : tables.Db) (ip : Option net.IpAddr) (user repo : U64)
    (a : Slice U8) (hf : tables.Query.RepositoryAction ∉ db.failing.val) :
    ∃ b, permission.check_repository_action db ip user repo a false = ok (.Ok b) ∧
      (b = true ↔ RepoAction db ip user repo (nats a.val)) := by
  apply artifactkeeper_kernel.Verified.ArtifactkeeperRepoActionSpec.check_repository_action_spec <;> assumption

/-- An applicable rule overrides an ordinary role: a principal named by
rules none of which carries the action (or `admin`) is denied, whatever its
non-admin roles grant. -/
theorem rule_overrides_role (db : tables.Db) (ip : Option net.IpAddr) (user repo : U64) (a : Slice U8)
    (hp : ∃ p, Applicable db ip user repo p)
    (hn : ∀ p, Applicable db ip user repo p →
      ¬ Carries p.actions.val (nats a.val) ∧ ¬ Carries p.actions.val (lit "admin"))
    (hr : ¬ RoleGrants db user repo (lit "admin")) :
    permission.check_repository_action db ip user repo a false ≠ ok (.Ok true) := by
  apply artifactkeeper_kernel.Verified.ArtifactkeeperRuleOverridesRole.rule_overrides_role <;> assumption

/-- `CidrRange::contains` is prefix agreement. -/
theorem cidr_contains_spec (c : net.CidrRange) (a : net.IpAddr) :
    c.contains a = ok (inCidr c a) := by
  apply artifactkeeper_kernel.Verified.ArtifactkeeperCidrContains.cidr_contains_spec <;> assumption

/-! ## Admin and guest gates -/

/-- `admin_middleware` passes only an admin whose credential carries the
`admin` (or `*`) scope, or no scope ceiling (GHSA-vvc3). -/
theorem admin_gate (db : tables.Db) (o : trusted.Oracle) (req : http.Request)
    (ws : alloc.vec.Vec resolve.Write) (auth : Option AuthExtension) (t : Bool)
    (h : middleware.admin_middleware db o req = ok (ws, .Next auth t)) :
    ∃ e, auth = some e ∧ e.is_admin = true ∧ AdminScoped e.scopes := by
  apply artifactkeeper_kernel.Verified.ArtifactkeeperAdminGate.admin_gate <;> assumption

/-- Every non-admin turned away by `admin_middleware` is audited, and
nothing else is written. -/
theorem admin_denial_audited (db : tables.Db) (o : trusted.Oracle) (req : http.Request)
    (ws : alloc.vec.Vec resolve.Write)
    (h : middleware.admin_middleware db o req = ok (ws, .Respond .AdminRequired)) :
    ∃ u, ws.val = [resolve.Write.AuditPermissionDenied u req.path req.method] := by
  apply artifactkeeper_kernel.Verified.ArtifactkeeperAdminAudited.admin_denial_audited <;> assumption

/-- With guest access off, a request presenting no credential gets through
only on an allowlisted path (#850). -/
theorem guest_blocks_anonymous (o : trusted.Oracle) (req : http.Request) (auth : Option AuthExtension)
    (t : Bool) (h : middleware.guest_access_guard false o req = ok (.Next auth t))
    (hc : NoCredential req) :
    Allowlisted (nats req.path.val) := by
  apply artifactkeeper_kernel.Verified.ArtifactkeeperGuestBlocksAnonymous.guest_blocks_anonymous <;> assumption

/-! ## Permission rules -/

/-- Only an admin creates a permission rule. -/
theorem only_admin_creates_rules (db : tables.Db) (o : trusted.Oracle) (auth : Option AuthExtension)
    (p : handlers.CreatePermissionRequest) (ws : alloc.vec.Vec resolve.Write) (r : core.result.Result Unit AppError)
    (h : handlers.create_permission db o auth p = ok (ws, r)) (hw : ws.val ≠ []) :
    ∃ e, auth = some e ∧ e.is_admin = true := by
  apply artifactkeeper_kernel.Verified.ArtifactkeeperOnlyAdminRules.only_admin_creates_rules <;> assumption

/-- A stored anonymous rule grants only `read`, on a repository or project,
under the nil principal id. -/
theorem anonymous_rule_read_only (db : tables.Db) (o : trusted.Oracle) (auth : Option AuthExtension)
    (p : handlers.CreatePermissionRequest) (ws : alloc.vec.Vec resolve.Write) (r : core.result.Result Unit AppError)
    (row : tables.Permission)
    (h : handlers.create_permission db o auth p = ok (ws, r)) (hw : resolve.Write.InsertPermission row ∈ ws.val)
    (ha : nats row.principal_type.val = lit "anonymous") :
    row.principal_id = 0#u64 ∧
    (nats row.target_type.val = lit "repository" ∨ nats row.target_type.val = lit "project") ∧
    ∀ x ∈ row.actions.val, nats x.val = lit "read" := by
  apply artifactkeeper_kernel.Verified.ArtifactkeeperAnonymousRuleRead.anonymous_rule_read_only <;> assumption

/-- `scopes_grant_access` computes `scopeGrants`. -/
theorem scopes_grant_access_spec (scopes : Slice (alloc.vec.Vec U8)) (req : Slice U8) :
    token_scope.scopes_grant_access scopes req =
      ok (scopeGrants (scopes.val.map (fun s => nats s.val)) (nats req.val)) := by
  apply artifactkeeper_kernel.Verified.ArtifactkeeperScopesGrant.scopes_grant_access_spec <;> assumption

end artifactkeeper_kernel.Properties

namespace artifactkeeper_kernel.Properties

/-- Default expiry configuration is valid and starts in opt-in mode. -/
theorem token_expiry_default_valid :
    ∃ p, token_expiry.default_policy = ok p ∧ Verified.TokenExpiry.Valid p ∧
      p.require_expiration = false ∧ p.apply_to_service_accounts = false :=
  Verified.TokenExpiry.default_valid

/-- Acceptance is exactly the bounded lifetime configuration predicate. -/
theorem token_expiry_validation_iff (p : token_expiry.Policy) :
    token_expiry.validate p = ok (.Ok ()) ↔ Verified.TokenExpiry.Valid p :=
  Verified.TokenExpiry.validation_iff p

/-- Full mint resolution includes disabled/exempt, default and error paths. -/
theorem token_expiry_resolution_spec (p : token_expiry.Policy)
    (requested : Option Std.I64) (service : Bool) :
    token_expiry.resolve_expiry p requested service =
      ok (Verified.TokenExpiry.resolve p requested service) :=
  Verified.TokenExpiry.resolution_spec p requested service

/-- Enforced explicit requests never bypass lifetime bounds. -/
theorem token_expiry_accepted_request_bounded (p : token_expiry.Policy) (d : Std.I64)
    (service : Bool) (r : token_expiry.ResolvedExpiry)
    (h : token_expiry.resolve_expiry p (some d) service = ok (.Ok r))
    (ha : r.policy_applied = true) :
    p.min_days.val ≤ d.val ∧ d.val ≤ p.max_days.val :=
  Verified.TokenExpiry.accepted_request_bounded p d service r h ha

end artifactkeeper_kernel.Properties

namespace artifactkeeper_kernel.Properties

theorem totp_login_spec (p : totp_policy.TotpPolicy) (s : totp_policy.TotpSubject) :
    totp_policy.totp_login_requirement p s = ok (Verified.TotpPolicy.login p s) :=
  Verified.TotpPolicy.login_spec p s

theorem totp_disabling_spec (p : totp_policy.TotpPolicy) (s : totp_policy.TotpSubject) :
    totp_policy.policy_requires_totp p s = ok (Verified.TotpPolicy.covered p s) :=
  Verified.TotpPolicy.disabling_spec p s

theorem totp_activation_spec (current requested : totp_policy.TotpPolicy) (pinned enrolled : Bool) :
    totp_policy.check_policy_activation current requested pinned enrolled =
      ok (Verified.TotpPolicy.activation current requested pinned enrolled) :=
  Verified.TotpPolicy.activation_spec current requested pinned enrolled

theorem totp_enforcing_spec (p : totp_policy.TotpPolicy) :
    totp_policy.is_enforcing p = ok (decide (0 < Verified.TotpPolicy.rank p)) :=
  Verified.TotpPolicy.enforcing_spec p

theorem totp_relaxation_allowed (current requested : totp_policy.TotpPolicy) (enrolled : Bool)
    (h : Verified.TotpPolicy.rank requested ≤ Verified.TotpPolicy.rank current) :
    totp_policy.check_policy_activation current requested false enrolled = ok (.Ok ()) :=
  Verified.TotpPolicy.relaxation_allowed current requested enrolled h

theorem totp_enrolled_challenged (p : totp_policy.TotpPolicy) (s : totp_policy.TotpSubject)
    (h : s.totp_enabled = true) :
    totp_policy.totp_login_requirement p s = ok .ChallengeExisting :=
  Verified.TotpPolicy.enrolled_challenged p s h

end artifactkeeper_kernel.Properties

namespace artifactkeeper_kernel.Properties

/-- Full scope-list validation returns the first offending value. -/
theorem scope_validation_spec (scopes : Slice (alloc.vec.Vec U8)) :
    token_scope.validate_scopes_pure scopes = ok (Verified.TokenScope.validation scopes.val) :=
  Verified.TokenScope.validation_spec scopes

/-- Full admin-only scope check, including the admin bypass. -/
theorem scope_admin_validation_spec (scopes : Slice (alloc.vec.Vec U8)) (admin : Bool) :
    token_scope.enforce_admin_only_scopes scopes admin =
      ok (Verified.TokenScope.adminValidation scopes.val admin) :=
  Verified.TokenScope.admin_validation_spec scopes admin

/-- Delegated actions are bounded by the credential's effective scopes. -/
theorem scope_mint_spec (e : AuthExtension) (requested : Slice (alloc.vec.Vec U8)) :
    token_scope.check_mint_ceiling e requested = ok (Verified.TokenScope.mint e requested.val) :=
  Verified.TokenScope.mint_spec e requested

/-- Repository restrictions are inherited for admin and non-admin credentials. -/
theorem scope_repo_mint_spec (e : AuthExtension) (requested : Bool) :
    token_scope.check_repo_ceiling e requested = ok (Verified.TokenScope.repoMint e requested) :=
  Verified.TokenScope.repo_mint_spec e requested

end artifactkeeper_kernel.Properties

namespace artifactkeeper_kernel.Properties
open Verified.FiniteCatalog
theorem finite_repodata_encoding_df7b79f6_content_type_complete (v : finite_catalog.repodata_encoding_df7b79f6.RepodataEncoding) :
    finite_catalog.repodata_encoding_df7b79f6.RepodataEncoding.content_type v ⦃r => r.val = repodata_encoding_df7b79f6_content_type_model v⦄ := Verified.FiniteCatalog.repodata_encoding_df7b79f6_content_type_complete v

theorem finite_repodata_encoding_df7b79f6_upstream_filename_complete (v : finite_catalog.repodata_encoding_df7b79f6.RepodataEncoding) :
    finite_catalog.repodata_encoding_df7b79f6.RepodataEncoding.upstream_filename v ⦃r => r.val = repodata_encoding_df7b79f6_upstream_filename_model v⦄ := Verified.FiniteCatalog.repodata_encoding_df7b79f6_upstream_filename_complete v

theorem finite_signed_release_variant_007f0cf5_as_str_complete (v : finite_catalog.signed_release_variant_007f0cf5.SignedReleaseVariant) :
    finite_catalog.signed_release_variant_007f0cf5.SignedReleaseVariant.as_str v ⦃r => r.val = signed_release_variant_007f0cf5_as_str_model v⦄ := Verified.FiniteCatalog.signed_release_variant_007f0cf5_as_str_complete v

theorem finite_upload_session_state_a43ea4df_as_str_complete (v : finite_catalog.upload_session_state_a43ea4df.UploadSessionState) :
    finite_catalog.upload_session_state_a43ea4df.UploadSessionState.as_str v ⦃r => r.val = upload_session_state_a43ea4df_as_str_model v⦄ := Verified.FiniteCatalog.upload_session_state_a43ea4df_as_str_complete v

theorem finite_cached_object_verdict_b87a78e2_may_serve_stored_object_complete (v : finite_catalog.cached_object_verdict_b87a78e2.CachedObjectVerdict) :
    finite_catalog.cached_object_verdict_b87a78e2.CachedObjectVerdict.may_serve_stored_object v ⦃r => r = cached_object_verdict_b87a78e2_may_serve_stored_object_model v⦄ := Verified.FiniteCatalog.cached_object_verdict_b87a78e2_may_serve_stored_object_complete v

theorem finite_outbound_url_context_dd3b7559_env_var_complete (v : finite_catalog.outbound_url_context_dd3b7559.OutboundUrlContext) :
    finite_catalog.outbound_url_context_dd3b7559.OutboundUrlContext.env_var v ⦃r => r.val = outbound_url_context_dd3b7559_env_var_model v⦄ := Verified.FiniteCatalog.outbound_url_context_dd3b7559_env_var_complete v

theorem finite_jwt_secret_warning_4946346a_message_complete (v : finite_catalog.jwt_secret_warning_4946346a.JwtSecretWarning) :
    finite_catalog.jwt_secret_warning_4946346a.JwtSecretWarning.message v ⦃r => r.val = jwt_secret_warning_4946346a_message_model v⦄ := Verified.FiniteCatalog.jwt_secret_warning_4946346a_message_complete v

theorem finite_incus_file_type_eee7eb85_as_str_complete (v : finite_catalog.incus_file_type_eee7eb85.IncusFileType) :
    finite_catalog.incus_file_type_eee7eb85.IncusFileType.as_str v ⦃r => r.val = incus_file_type_eee7eb85_as_str_model v⦄ := Verified.FiniteCatalog.incus_file_type_eee7eb85_as_str_complete v

theorem finite_incus_file_type_eee7eb85_is_tarball_complete (v : finite_catalog.incus_file_type_eee7eb85.IncusFileType) :
    finite_catalog.incus_file_type_eee7eb85.IncusFileType.is_tarball v ⦃r => r = incus_file_type_eee7eb85_is_tarball_model v⦄ := Verified.FiniteCatalog.incus_file_type_eee7eb85_is_tarball_complete v

theorem finite_sbom_format_104be95e_as_str_complete (v : finite_catalog.sbom_format_104be95e.SbomFormat) :
    finite_catalog.sbom_format_104be95e.SbomFormat.as_str v ⦃r => r.val = sbom_format_104be95e_as_str_model v⦄ := Verified.FiniteCatalog.sbom_format_104be95e_as_str_complete v

theorem finite_sbom_format_104be95e_content_type_complete (v : finite_catalog.sbom_format_104be95e.SbomFormat) :
    finite_catalog.sbom_format_104be95e.SbomFormat.content_type v ⦃r => r.val = sbom_format_104be95e_content_type_model v⦄ := Verified.FiniteCatalog.sbom_format_104be95e_content_type_complete v

theorem finite_cve_status_104be95e_as_str_complete (v : finite_catalog.cve_status_104be95e.CveStatus) :
    finite_catalog.cve_status_104be95e.CveStatus.as_str v ⦃r => r.val = cve_status_104be95e_as_str_model v⦄ := Verified.FiniteCatalog.cve_status_104be95e_as_str_complete v

theorem finite_policy_action_104be95e_as_str_complete (v : finite_catalog.policy_action_104be95e.PolicyAction) :
    finite_catalog.policy_action_104be95e.PolicyAction.as_str v ⦃r => r.val = policy_action_104be95e_as_str_model v⦄ := Verified.FiniteCatalog.policy_action_104be95e_as_str_complete v

theorem finite_severity_1259a9af_penalty_weight_complete (v : finite_catalog.severity_1259a9af.Severity) :
    finite_catalog.severity_1259a9af.Severity.penalty_weight v ⦃r => r = severity_1259a9af_penalty_weight_model v⦄ := Verified.FiniteCatalog.severity_1259a9af_penalty_weight_complete v

theorem finite_severity_1259a9af_as_str_complete (v : finite_catalog.severity_1259a9af.Severity) :
    finite_catalog.severity_1259a9af.Severity.as_str v ⦃r => r.val = severity_1259a9af_as_str_model v⦄ := Verified.FiniteCatalog.severity_1259a9af_as_str_complete v

theorem finite_age_gate_mode_3fdb45b7_as_str_complete (v : finite_catalog.age_gate_mode_3fdb45b7.AgeGateMode) :
    finite_catalog.age_gate_mode_3fdb45b7.AgeGateMode.as_str v ⦃r => r.val = age_gate_mode_3fdb45b7_as_str_model v⦄ := Verified.FiniteCatalog.age_gate_mode_3fdb45b7_as_str_complete v

theorem finite_age_gate_review_status_3fdb45b7_as_str_complete (v : finite_catalog.age_gate_review_status_3fdb45b7.AgeGateReviewStatus) :
    finite_catalog.age_gate_review_status_3fdb45b7.AgeGateReviewStatus.as_str v ⦃r => r.val = age_gate_review_status_3fdb45b7_as_str_model v⦄ := Verified.FiniteCatalog.age_gate_review_status_3fdb45b7_as_str_complete v

theorem finite_audit_stream_mode_8053ef47_name_complete (v : finite_catalog.audit_stream_mode_8053ef47.AuditStreamMode) :
    finite_catalog.audit_stream_mode_8053ef47.AuditStreamMode.name v ⦃r => r.val = audit_stream_mode_8053ef47_name_model v⦄ := Verified.FiniteCatalog.audit_stream_mode_8053ef47_name_complete v

theorem finite_audit_action_3ef0ea8f_as_str_complete (v : finite_catalog.audit_action_3ef0ea8f.AuditAction) :
    finite_catalog.audit_action_3ef0ea8f.AuditAction.as_str v ⦃r => r.val = audit_action_3ef0ea8f_as_str_model v⦄ := Verified.FiniteCatalog.audit_action_3ef0ea8f_as_str_complete v

theorem finite_resource_type_3ef0ea8f_as_str_complete (v : finite_catalog.resource_type_3ef0ea8f.ResourceType) :
    finite_catalog.resource_type_3ef0ea8f.ResourceType.as_str v ⦃r => r.val = resource_type_3ef0ea8f_as_str_model v⦄ := Verified.FiniteCatalog.resource_type_3ef0ea8f_as_str_complete v

theorem finite_noarch_kind_b8478f7b_as_str_complete (v : finite_catalog.noarch_kind_b8478f7b.NoarchKind) :
    finite_catalog.noarch_kind_b8478f7b.NoarchKind.as_str v ⦃r => r.val = noarch_kind_b8478f7b_as_str_model v⦄ := Verified.FiniteCatalog.noarch_kind_b8478f7b_as_str_complete v

theorem finite_conda_archive_type_b8478f7b_as_str_complete (v : finite_catalog.conda_archive_type_b8478f7b.CondaArchiveType) :
    finite_catalog.conda_archive_type_b8478f7b.CondaArchiveType.as_str v ⦃r => r.val = conda_archive_type_b8478f7b_as_str_model v⦄ := Verified.FiniteCatalog.conda_archive_type_b8478f7b_as_str_complete v

theorem finite_script_kind_a04cea8b_as_str_complete (v : finite_catalog.script_kind_a04cea8b.ScriptKind) :
    finite_catalog.script_kind_a04cea8b.ScriptKind.as_str v ⦃r => r.val = script_kind_a04cea8b_as_str_model v⦄ := Verified.FiniteCatalog.script_kind_a04cea8b_as_str_complete v

theorem finite_script_kind_a04cea8b_runs_as_root_complete (v : finite_catalog.script_kind_a04cea8b.ScriptKind) :
    finite_catalog.script_kind_a04cea8b.ScriptKind.runs_as_root v ⦃r => r = script_kind_a04cea8b_runs_as_root_model v⦄ := Verified.FiniteCatalog.script_kind_a04cea8b_runs_as_root_complete v

theorem finite_candidate_confidence_8223875f_as_str_complete (v : finite_catalog.candidate_confidence_8223875f.CandidateConfidence) :
    finite_catalog.candidate_confidence_8223875f.CandidateConfidence.as_str v ⦃r => r.val = candidate_confidence_8223875f_as_str_model v⦄ := Verified.FiniteCatalog.candidate_confidence_8223875f_as_str_complete v

theorem finite_check_b0946112_bit_complete (v : finite_catalog.check_b0946112.Check) :
    finite_catalog.check_b0946112.Check.bit v ⦃r => r = check_b0946112_bit_model v⦄ := Verified.FiniteCatalog.check_b0946112_bit_complete v

theorem finite_check_b0946112_reason_label_complete (v : finite_catalog.check_b0946112.Check) :
    finite_catalog.check_b0946112.Check.reason_label v ⦃r => r.val = check_b0946112_reason_label_model v⦄ := Verified.FiniteCatalog.check_b0946112_reason_label_complete v

theorem finite_attestation_state_b0946112_as_str_complete (v : finite_catalog.attestation_state_b0946112.AttestationState) :
    finite_catalog.attestation_state_b0946112.AttestationState.as_str v ⦃r => r.val = attestation_state_b0946112_as_str_model v⦄ := Verified.FiniteCatalog.attestation_state_b0946112_as_str_complete v

theorem finite_inventory_completeness_0e70a8c0_as_str_complete (v : finite_catalog.inventory_completeness_0e70a8c0.InventoryCompleteness) :
    finite_catalog.inventory_completeness_0e70a8c0.InventoryCompleteness.as_str v ⦃r => r.val = inventory_completeness_0e70a8c0_as_str_model v⦄ := Verified.FiniteCatalog.inventory_completeness_0e70a8c0_as_str_complete v

theorem finite_egress_proxy_mode_2d09e195_as_str_complete (v : finite_catalog.egress_proxy_mode_2d09e195.EgressProxyMode) :
    finite_catalog.egress_proxy_mode_2d09e195.EgressProxyMode.as_str v ⦃r => r.val = egress_proxy_mode_2d09e195_as_str_model v⦄ := Verified.FiniteCatalog.egress_proxy_mode_2d09e195_as_str_complete v

theorem finite_rate_limit_decision_2593facc_label_complete (v : finite_catalog.rate_limit_decision_2593facc.RateLimitDecision) :
    finite_catalog.rate_limit_decision_2593facc.RateLimitDecision.label v ⦃r => r.val = rate_limit_decision_2593facc_label_model v⦄ := Verified.FiniteCatalog.rate_limit_decision_2593facc_label_complete v

theorem finite_lock_format_99735155_as_str_complete (v : finite_catalog.lock_format_99735155.LockFormat) :
    finite_catalog.lock_format_99735155.LockFormat.as_str v ⦃r => r.val = lock_format_99735155_as_str_model v⦄ := Verified.FiniteCatalog.lock_format_99735155_as_str_complete v

theorem finite_lock_format_99735155_is_per_platform_complete (v : finite_catalog.lock_format_99735155.LockFormat) :
    finite_catalog.lock_format_99735155.LockFormat.is_per_platform v ⦃r => r = lock_format_99735155_is_per_platform_model v⦄ := Verified.FiniteCatalog.lock_format_99735155_is_per_platform_complete v

theorem finite_ecosystem_99735155_as_str_complete (v : finite_catalog.ecosystem_99735155.Ecosystem) :
    finite_catalog.ecosystem_99735155.Ecosystem.as_str v ⦃r => r.val = ecosystem_99735155_as_str_model v⦄ := Verified.FiniteCatalog.ecosystem_99735155_as_str_complete v

theorem finite_edge_kind_99735155_as_str_complete (v : finite_catalog.edge_kind_99735155.EdgeKind) :
    finite_catalog.edge_kind_99735155.EdgeKind.as_str v ⦃r => r.val = edge_kind_99735155_as_str_model v⦄ := Verified.FiniteCatalog.edge_kind_99735155_as_str_complete v

theorem finite_unresolved_kind_99735155_as_str_complete (v : finite_catalog.unresolved_kind_99735155.UnresolvedKind) :
    finite_catalog.unresolved_kind_99735155.UnresolvedKind.as_str v ⦃r => r.val = unresolved_kind_99735155_as_str_model v⦄ := Verified.FiniteCatalog.unresolved_kind_99735155_as_str_complete v

theorem finite_unresolved_kind_99735155_is_parse_failure_complete (v : finite_catalog.unresolved_kind_99735155.UnresolvedKind) :
    finite_catalog.unresolved_kind_99735155.UnresolvedKind.is_parse_failure v ⦃r => r = unresolved_kind_99735155_is_parse_failure_model v⦄ := Verified.FiniteCatalog.unresolved_kind_99735155_is_parse_failure_complete v

theorem finite_unresolved_kind_99735155_is_graph_gap_complete (v : finite_catalog.unresolved_kind_99735155.UnresolvedKind) :
    finite_catalog.unresolved_kind_99735155.UnresolvedKind.is_graph_gap v ⦃r => r = unresolved_kind_99735155_is_graph_gap_model v⦄ := Verified.FiniteCatalog.unresolved_kind_99735155_is_graph_gap_complete v

theorem finite_package_manager_7f965e35_as_str_complete (v : finite_catalog.package_manager_7f965e35.PackageManager) :
    finite_catalog.package_manager_7f965e35.PackageManager.as_str v ⦃r => r.val = package_manager_7f965e35_as_str_model v⦄ := Verified.FiniteCatalog.package_manager_7f965e35_as_str_complete v

theorem finite_package_manager_7f965e35_is_system_complete (v : finite_catalog.package_manager_7f965e35.PackageManager) :
    finite_catalog.package_manager_7f965e35.PackageManager.is_system v ⦃r => r = package_manager_7f965e35_is_system_model v⦄ := Verified.FiniteCatalog.package_manager_7f965e35_is_system_complete v

theorem finite_policy_type_080e6210_as_wire_str_complete (v : finite_catalog.policy_type_080e6210.PolicyType) :
    finite_catalog.policy_type_080e6210.PolicyType.as_wire_str v ⦃r => r.val = policy_type_080e6210_as_wire_str_model v⦄ := Verified.FiniteCatalog.policy_type_080e6210_as_wire_str_complete v

theorem finite_flat_key_write_claim_6572c2eb_needs_release_on_failure_complete (v : finite_catalog.flat_key_write_claim_6572c2eb.FlatKeyWriteClaim) :
    finite_catalog.flat_key_write_claim_6572c2eb.FlatKeyWriteClaim.needs_release_on_failure v ⦃r => r = flat_key_write_claim_6572c2eb_needs_release_on_failure_model v⦄ := Verified.FiniteCatalog.flat_key_write_claim_6572c2eb_needs_release_on_failure_complete v

theorem finite_source_view_73842ce1_overwrites_complete (v : finite_catalog.source_view_73842ce1.SourceView) :
    finite_catalog.source_view_73842ce1.SourceView.overwrites v ⦃r => r = source_view_73842ce1_overwrites_model v⦄ := Verified.FiniteCatalog.source_view_73842ce1_overwrites_complete v

theorem finite_repository_type_73842ce1_to_artifact_keeper_complete (v : finite_catalog.repository_type_73842ce1.RepositoryType) :
    finite_catalog.repository_type_73842ce1.RepositoryType.to_artifact_keeper v ⦃r => r.val = repository_type_73842ce1_to_artifact_keeper_model v⦄ := Verified.FiniteCatalog.repository_type_73842ce1_to_artifact_keeper_complete v

theorem finite_advisory_scan_status_38f3e57f_as_str_complete (v : finite_catalog.advisory_scan_status_38f3e57f.AdvisoryScanStatus) :
    finite_catalog.advisory_scan_status_38f3e57f.AdvisoryScanStatus.as_str v ⦃r => r.val = advisory_scan_status_38f3e57f_as_str_model v⦄ := Verified.FiniteCatalog.advisory_scan_status_38f3e57f_as_str_complete v

theorem finite_proxy_scan_action_2c5d20ab_is_fail_closed_complete (v : finite_catalog.proxy_scan_action_2c5d20ab.ProxyScanAction) :
    finite_catalog.proxy_scan_action_2c5d20ab.ProxyScanAction.is_fail_closed v ⦃r => r = proxy_scan_action_2c5d20ab_is_fail_closed_model v⦄ := Verified.FiniteCatalog.proxy_scan_action_2c5d20ab_is_fail_closed_complete v

theorem finite_vendoring_tool_8d235a49_as_str_complete (v : finite_catalog.vendoring_tool_8d235a49.VendoringTool) :
    finite_catalog.vendoring_tool_8d235a49.VendoringTool.as_str v ⦃r => r.val = vendoring_tool_8d235a49_as_str_model v⦄ := Verified.FiniteCatalog.vendoring_tool_8d235a49_as_str_complete v

theorem finite_quarantine_state_63e328a6_as_str_complete (v : finite_catalog.quarantine_state_63e328a6.QuarantineState) :
    finite_catalog.quarantine_state_63e328a6.QuarantineState.as_str v ⦃r => r.val = quarantine_state_63e328a6_as_str_model v⦄ := Verified.FiniteCatalog.quarantine_state_63e328a6_as_str_complete v

theorem finite_inventory_status_731e13d3_as_db_str_complete (v : finite_catalog.inventory_status_731e13d3.InventoryStatus) :
    finite_catalog.inventory_status_731e13d3.InventoryStatus.as_db_str v ⦃r => r.val = inventory_status_731e13d3_as_db_str_model v⦄ := Verified.FiniteCatalog.inventory_status_731e13d3_as_db_str_complete v

theorem finite_scan_state_5f365d9c_is_unscanned_complete (v : finite_catalog.scan_state_5f365d9c.ScanState) :
    finite_catalog.scan_state_5f365d9c.ScanState.is_unscanned v ⦃r => r = scan_state_5f365d9c_is_unscanned_model v⦄ := Verified.FiniteCatalog.scan_state_5f365d9c_is_unscanned_complete v

theorem finite_scan_state_5f365d9c_reason_token_complete (v : finite_catalog.scan_state_5f365d9c.ScanState) :
    finite_catalog.scan_state_5f365d9c.ScanState.reason_token v ⦃r => r.val = scan_state_5f365d9c_reason_token_model v⦄ := Verified.FiniteCatalog.scan_state_5f365d9c_reason_token_complete v

theorem finite_scan_completeness_ba4d10ac_as_str_complete (v : finite_catalog.scan_completeness_ba4d10ac.ScanCompleteness) :
    finite_catalog.scan_completeness_ba4d10ac.ScanCompleteness.as_str v ⦃r => r.val = scan_completeness_ba4d10ac_as_str_model v⦄ := Verified.FiniteCatalog.scan_completeness_ba4d10ac_as_str_complete v

theorem finite_oci_content_kind_bc817bda_path_segment_complete (v : finite_catalog.oci_content_kind_bc817bda.OciContentKind) :
    finite_catalog.oci_content_kind_bc817bda.OciContentKind.path_segment v ⦃r => r.val = oci_content_kind_bc817bda_path_segment_model v⦄ := Verified.FiniteCatalog.oci_content_kind_bc817bda_path_segment_complete v

theorem finite_oci_cleanup_key_family_c9cc8f67_session_predicate_sql_complete (v : finite_catalog.oci_cleanup_key_family_c9cc8f67.OciCleanupKeyFamily) :
    finite_catalog.oci_cleanup_key_family_c9cc8f67.OciCleanupKeyFamily.session_predicate_sql v ⦃r => r.val = oci_cleanup_key_family_c9cc8f67_session_predicate_sql_model v⦄ := Verified.FiniteCatalog.oci_cleanup_key_family_c9cc8f67_session_predicate_sql_complete v

theorem finite_dedup_scope_78b2cf8c_as_str_complete (v : finite_catalog.dedup_scope_78b2cf8c.DedupScope) :
    finite_catalog.dedup_scope_78b2cf8c.DedupScope.as_str v ⦃r => r.val = dedup_scope_78b2cf8c_as_str_model v⦄ := Verified.FiniteCatalog.dedup_scope_78b2cf8c_as_str_complete v

theorem finite_totp_policy_31812d2d_as_str_complete (v : finite_catalog.totp_policy_31812d2d.TotpPolicy) :
    finite_catalog.totp_policy_31812d2d.TotpPolicy.as_str v ⦃r => r.val = totp_policy_31812d2d_as_str_model v⦄ := Verified.FiniteCatalog.totp_policy_31812d2d_as_str_complete v

theorem finite_totp_policy_31812d2d_is_enforcing_complete (v : finite_catalog.totp_policy_31812d2d.TotpPolicy) :
    finite_catalog.totp_policy_31812d2d.TotpPolicy.is_enforcing v ⦃r => r = totp_policy_31812d2d_is_enforcing_model v⦄ := Verified.FiniteCatalog.totp_policy_31812d2d_is_enforcing_complete v

theorem finite_policy_activation_refusal_31812d2d_message_complete (v : finite_catalog.policy_activation_refusal_31812d2d.PolicyActivationRefusal) :
    finite_catalog.policy_activation_refusal_31812d2d.PolicyActivationRefusal.message v ⦃r => r.val = policy_activation_refusal_31812d2d_message_model v⦄ := Verified.FiniteCatalog.policy_activation_refusal_31812d2d_message_complete v

theorem finite_storage_path_format_9d04c6bd_has_fallback_complete (v : finite_catalog.storage_path_format_9d04c6bd.StoragePathFormat) :
    finite_catalog.storage_path_format_9d04c6bd.StoragePathFormat.has_fallback v ⦃r => r = storage_path_format_9d04c6bd_has_fallback_model v⦄ := Verified.FiniteCatalog.storage_path_format_9d04c6bd_has_fallback_complete v

theorem finite_log_format_f5cc6ea1_name_complete (v : finite_catalog.log_format_f5cc6ea1.LogFormat) :
    finite_catalog.log_format_f5cc6ea1.LogFormat.name v ⦃r => r.val = log_format_f5cc6ea1_name_model v⦄ := Verified.FiniteCatalog.log_format_f5cc6ea1_name_complete v

theorem finite_otlp_protocol_f5cc6ea1_name_complete (v : finite_catalog.otlp_protocol_f5cc6ea1.OtlpProtocol) :
    finite_catalog.otlp_protocol_f5cc6ea1.OtlpProtocol.name v ⦃r => r.val = otlp_protocol_f5cc6ea1_name_model v⦄ := Verified.FiniteCatalog.otlp_protocol_f5cc6ea1_name_complete v

theorem finite_sampler_choice_f5cc6ea1_name_complete (v : finite_catalog.sampler_choice_f5cc6ea1.SamplerChoice) :
    finite_catalog.sampler_choice_f5cc6ea1.SamplerChoice.name v ⦃r => r.val = sampler_choice_f5cc6ea1_name_model v⦄ := Verified.FiniteCatalog.sampler_choice_f5cc6ea1_name_complete v

theorem finite_sampler_choice_f5cc6ea1_uses_ratio_complete (v : finite_catalog.sampler_choice_f5cc6ea1.SamplerChoice) :
    finite_catalog.sampler_choice_f5cc6ea1.SamplerChoice.uses_ratio v ⦃r => r = sampler_choice_f5cc6ea1_uses_ratio_model v⦄ := Verified.FiniteCatalog.sampler_choice_f5cc6ea1_uses_ratio_complete v

end artifactkeeper_kernel.Properties
-- Complete pinned closed record constructors.
namespace artifactkeeper_kernel.Properties

theorem closed_records_plugin_resource_limits_default_a005c35c_complete :
    closed_records.plugin_resource_limits_default_a005c35c.make ⦃r => r.memory_mb.val = 64 ∧
      r.timeout_secs.val = 5 ∧
      r.fuel.val = 500000000⦄ :=
  Verified.ClosedRecords.plugin_resource_limits_default_a005c35c_complete

theorem closed_records_plugin_capabilities_default_a005c35c_complete :
    closed_records.plugin_capabilities_default_a005c35c.make ⦃r => r.parse_metadata = true ∧
      r.generate_index = false ∧
      r.validate_artifact = true ∧
      r.handle_request = false⦄ :=
  Verified.ClosedRecords.plugin_capabilities_default_a005c35c_complete

theorem closed_records_capabilities_config_default_75c080e9_complete :
    closed_records.capabilities_config_default_75c080e9.make ⦃r => r.parse_metadata = true ∧
      r.generate_index = false ∧
      r.validate_artifact = true ∧
      r.handle_request = false⦄ :=
  Verified.ClosedRecords.capabilities_config_default_75c080e9_complete

theorem closed_records_telemetry_settings_default_453927f4_complete :
    closed_records.telemetry_settings_default_453927f4.make ⦃r => r.enabled = false ∧
      r.review_before_send = true ∧
      r.scrub_level.val = [115#u8, 116#u8, 97#u8, 110#u8, 100#u8, 97#u8, 114#u8, 100#u8] ∧
      r.include_logs = false⦄ :=
  Verified.ClosedRecords.telemetry_settings_default_453927f4_complete

theorem closed_records_password_policy_config_default_97110402_complete :
    closed_records.password_policy_config_default_97110402.make ⦃r => r.min_length.val = 8 ∧
      r.max_length.val = 128 ∧
      r.require_uppercase = false ∧
      r.require_lowercase = false ∧
      r.require_digit = false ∧
      r.require_special = false ∧
      r.min_strength.val = 0⦄ :=
  Verified.ClosedRecords.password_policy_config_default_97110402_complete

end artifactkeeper_kernel.Properties
