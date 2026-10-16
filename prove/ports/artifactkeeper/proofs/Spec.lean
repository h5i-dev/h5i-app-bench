import ArtifactkeeperKernel
import H5iAppLib
/-!
# artifact-keeper's repository access decisions: the spec

From artifact-keeper's code and comments at 7c42891
(`services/permission_service.rs`, `api/middleware/auth.rs`,
`api/middleware/guest_access.rs`, `api/handlers/permissions.rs`). The
definitions restate the SQL of `PermissionService` over plain lists. Two
extracted functions serve as given oracles in statements: `extract_repo_key`
(which repository a path names) and `is_non_mutating_format_post` (which
POST routes are negotiation steps).
-/
open Aeneas Aeneas.Std artifactkeeper_kernel

namespace artifactkeeper_kernel.Spec

/-- A byte string as numbers. -/
def nats (v : List U8) : List Nat := v.map (·.val)

/-- The UTF-8 bytes of a literal. -/
def lit (s : String) : List Nat := s.toUTF8.toList.map (·.toNat)

/-- Some entry of `xs` spells `a`. -/
def Carries (xs : List (alloc.vec.Vec U8)) (a : List Nat) : Prop := ∃ x ∈ xs, nats x.val = a

/-! ## The permission tables -/

/-- `(SELECT project_id FROM repositories WHERE id = repo) = pid`. -/
def ProjectOf (db : tables.Db) (repo pid : U64) : Prop :=
  ((db.repositories.val.find? (fun r => r.id = repo)).bind (·.project_id)) = some pid

/-- The rule names this user: directly (`user`, `service_account`) or through
a group the user is a member of. -/
def PrincipalMatches (db : tables.Db) (p : tables.Permission) (user : U64) : Prop :=
  ((nats p.principal_type.val = lit "user" ∨ nats p.principal_type.val = lit "service_account") ∧
    p.principal_id = user) ∨
  (nats p.principal_type.val = lit "group" ∧ (user, p.principal_id) ∈ db.members.val)

/-- The rule targets the repository, or the project that owns it. -/
def OnRepo (db : tables.Db) (p : tables.Permission) (repo : U64) : Prop :=
  (nats p.target_type.val = lit "repository" ∧ p.target_id = repo) ∨
  (nats p.target_type.val = lit "project" ∧ ProjectOf db repo p.target_id)

/-- `ip` lies in `c`: the first `prefix_len` bits agree (all of them when the
prefix exceeds the width), same address family. -/
def inCidr (c : net.CidrRange) (ip : net.IpAddr) : Bool :=
  match c.network, ip with
  | .V4 n, .V4 a => let s := 32 - min c.prefix_len.val 32; n.val / 2 ^ s == a.val / 2 ^ s
  | .V6 n, .V6 a => let s := 128 - min c.prefix_len.val 128; n.val / 2 ^ s == a.val / 2 ^ s
  | _, _ => false

/-- The rule's `allowed_cidrs` condition holds for the client IP: no
condition, or a known IP inside one of the ranges. -/
def IpOk (p : tables.Permission) (ip : Option net.IpAddr) : Prop :=
  p.allowed_cidrs = none ∨
  ∃ cs a, p.allowed_cidrs = some cs ∧ ip = some a ∧ ∃ c ∈ cs.val, inCidr c a = true

/-- A row of `applicable_rules`. -/
def Applicable (db : tables.Db) (ip : Option net.IpAddr) (user repo : U64) (p : tables.Permission) : Prop :=
  p ∈ db.permissions.val ∧ PrincipalMatches db p user ∧ OnRepo db p repo ∧ IpOk p ip

/-- A role assigned to the user on this repository, or on all of them,
carries `perm`. -/
def RoleGrants (db : tables.Db) (user repo : U64) (perm : List Nat) : Prop :=
  ∃ ra ∈ db.role_assignments.val, ra.user_id = user ∧
    (ra.repository_id = some repo ∨ ra.repository_id = none) ∧
    ∃ r ∈ db.roles.val, r.id = ra.role_id ∧ Carries r.permissions.val perm

/-- `check_repository_action` for a non-admin: an `admin` role always wins;
otherwise the applicable rules decide when there are any, and the roles
decide when there are none. -/
def RepoAction (db : tables.Db) (ip : Option net.IpAddr) (user repo : U64) (a : List Nat) : Prop :=
  RoleGrants db user repo (lit "admin") ∨
  ((∃ p, Applicable db ip user repo p) ∧
    ∃ p, Applicable db ip user repo p ∧ (Carries p.actions.val a ∨ Carries p.actions.val (lit "admin"))) ∨
  ((¬ ∃ p, Applicable db ip user repo p) ∧ (RoleGrants db user repo a ∨ RoleGrants db user repo (lit "admin")))

/-- An anonymous rule grants `read` on the repository to this client IP. -/
def AnonymousRead (db : tables.Db) (ip : Option net.IpAddr) (repo : U64) : Prop :=
  ∃ p ∈ db.permissions.val, nats p.principal_type.val = lit "anonymous" ∧ OnRepo db p repo ∧
    (Carries p.actions.val (lit "read") ∨ Carries p.actions.val (lit "admin")) ∧ IpOk p ip

/-- The user holds some grant on the repository: a role assignment (on it or
global), or an applicable rule. -/
def HasGrant (db : tables.Db) (ip : Option net.IpAddr) (user repo : U64) : Prop :=
  (∃ ra ∈ db.role_assignments.val, ra.user_id = user ∧
    (ra.repository_id = some repo ∨ ra.repository_id = none)) ∨
  ∃ p, Applicable db ip user repo p

/-! ## Requests -/

/-- The repository the request's path names: the first row whose key is the
key `extract_repo_key` reads from the path. -/
def RepoOf (db : tables.Db) (req : http.Request) (r : tables.Repository) : Prop :=
  ∃ key, paths.extract_repo_key (alloc.vec.Vec.deref req.path) = .ok key ∧
    db.repositories.val.find? (fun x => decide (x.key.val = key.val)) = some r

/-- The path is one of the POST negotiation routes (git-lfs batch, conan
authenticate, VS Code gallery query, PyPI XML-RPC). -/
def NonMutatingPost (req : http.Request) : Prop :=
  paths.is_non_mutating_format_post (alloc.vec.Vec.deref req.path) = .ok true

/-- The permission action of a write method. -/
def writeAction : Method → List Nat
  | .Delete => lit "delete"
  | _ => lit "write"

def isMutation (m : Method) : Prop := m = .Put ∨ m = .Patch ∨ m = .Delete

/-- The scopes grant `admin`, or are not restricted at all. -/
def AdminScoped (scopes : Option (alloc.vec.Vec (alloc.vec.Vec U8))) : Prop :=
  scopes = none ∨ ∃ s, scopes = some s ∧ (Carries s.val (lit "admin") ∨ Carries s.val (lit "*"))

/-- Paths the guest-access guard leaves open. -/
def Allowlisted (path : List Nat) : Prop :=
  path ∈ [lit "/health", lit "/healthz", lit "/ready", lit "/readyz", lit "/livez",
          lit "/api/v1/system/config", lit "/v2/token", lit "/api/v1/auth", lit "/api/v1/setup"] ∨
  lit "/api/v1/auth/" <+: path ∨ lit "/api/v1/setup/" <+: path

/-- The request presents no credential: no header that can carry one, and no
conda token channel in the path. -/
def NoCredential (req : http.Request) : Prop :=
  (∀ h ∈ req.headers.val, nats h.1.val ∉
    [lit "authorization", lit "x-api-key", lit "cookie", lit "x-nuget-apikey"]) ∧
  ¬ (lit "conda/" <+: (nats req.path.val).dropWhile (· = 47))

/-! ## Scopes -/

/-- `scopes_grant_access`: an exact match, a `*` or `admin` wildcard, or the
bare action parent (the text before the first `:`) of a colon-form
requirement, so `write` covers `write:artifacts`. -/
def scopeGrants (scopes : List (List Nat)) (req : List Nat) : Bool :=
  let parent := req.takeWhile (· ≠ 58)
  scopes.contains (lit "*") || scopes.contains (lit "admin") || scopes.contains req ||
    (req.contains 58 && !parent.isEmpty && scopes.contains parent)

end artifactkeeper_kernel.Spec
