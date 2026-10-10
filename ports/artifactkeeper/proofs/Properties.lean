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
  sorry

/-- An anonymous request reaches a repository that is not public only
through an anonymous `read` rule that applies to the client IP (#1849). -/
theorem anonymous_needs_rule (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (t : Bool) (r : tables.Repository)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, .Next none t))
    (hr : RepoOf db req r) (hv : r.visibility ≠ some .Public) :
    AnonymousRead db ip r.id := by
  sorry

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
  sorry

/-- A repository-restricted credential reaches a repository outside its
allowlist only to read a public one (#504, #3648). -/
theorem scoped_token_confined (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (e : AuthExtension) (t : Bool)
    (r : tables.Repository) (ids : alloc.vec.Vec U64)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, .Next (some e) t))
    (hs : e.allowed_repo_ids = .Restricted ids) (hr : RepoOf db req r) (hi : r.id ∉ ids.val) :
    r.visibility = some .Public ∧ ¬ isMutation req.method := by
  sorry

/-- A download ticket authorizes only GET or HEAD, as a non-admin principal
with no scopes. -/
theorem ticket_read_only (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (auth : Option AuthExtension)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, .Next auth true)) :
    (req.method = .Get ∨ req.method = .Head) ∧
    ∃ e, auth = some e ∧ e.is_admin = false ∧ e.scopes.map (·.val) = some [] := by
  sorry

/-- A ticket is consumed only by a GET or HEAD, and only if it is live. -/
theorem ticket_consumed_on_read (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (out : middleware.Outcome)
    (tk : alloc.vec.Vec U8)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, out))
    (hw : resolve.Write.DeleteTicket tk ∈ ws.val) :
    (req.method = .Get ∨ req.method = .Head) ∧ ∃ x ∈ db.tickets.val, x.ticket = tk ∧ x.live = true := by
  sorry

/-- The middleware never panics, overflows or loops. -/
theorem repo_visibility_total (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) :
    ∃ y, middleware.repo_visibility_middleware db o ip req = ok y := by
  sorry

/-! ## `PermissionService` -/

/-- `check_repository_action` computes its SQL: `RepoAction`. -/
theorem check_repository_action_spec (db : tables.Db) (ip : Option net.IpAddr) (user repo : U64)
    (a : Slice U8) (hf : tables.Query.RepositoryAction ∉ db.failing.val) :
    ∃ b, permission.check_repository_action db ip user repo a false = ok (.Ok b) ∧
      (b = true ↔ RepoAction db ip user repo (nats a.val)) := by
  sorry

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
  sorry

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
  sorry

/-- `scopes_grant_access` computes `scopeGrants`. -/
theorem scopes_grant_access_spec (scopes : Slice (alloc.vec.Vec U8)) (req : Slice U8) :
    token_scope.scopes_grant_access scopes req =
      ok (scopeGrants (scopes.val.map (fun s => nats s.val)) (nats req.val)) := by
  sorry

end artifactkeeper_kernel.Properties
