import NoraKernel
import H5iAppLib
/-!
# nora's OIDC write authorization: the spec

From nora's documentation and code comments at f864a9a (`auth/namespace.rs`,
`auth/oidc.rs`, `config/auth.rs`). The authorization theorems take the two
matchers, `glob_match` (subjects) and `namespace_match` (namespaces), as
given: they are stated with the extracted matchers. The matchers' own
theorems compare them with `globSpec` and `segGlobSpec` below.
-/
open Aeneas Aeneas.Std nora_kernel

namespace nora_kernel.Spec

/-- A byte string as numbers. -/
def nats (v : List U8) : List Nat := v.map (·.val)

/-- The UTF-8 bytes of a literal. -/
def lit (s : String) : List Nat := s.toUTF8.toList.map (·.toNat)

/-- The middleware treats these methods as writes. -/
def isWrite : Method → Bool
  | .Put | .Post | .Delete | .Patch => true
  | .Get | .Head => false

/-- `glob_match pattern sub` holds for the subject matcher. -/
def Glob (pattern sub : List U8) (b : Bool) : Prop :=
  ∃ hp hs, glob_match (.from pattern hp) (.from sub hs) = .ok b

/-- `namespace_match pattern ns` holds. -/
def NsMatch (pattern ns : List U8) : Prop :=
  ∃ hp hs, namespace_match (.from pattern hp) (.from ns hs) = .ok true

/-- Rule `i` is the first role rule whose pattern matches `sub`
(`match_role`: "First match wins"). -/
def FirstMatch (p : OidcProvider) (sub : List U8) (i : Nat) : Prop :=
  ∃ h : i < p.role_rules.val.length,
    (∀ j (hj : j < i), Glob (p.role_rules.val[j]).pattern.val sub false) ∧
    Glob (p.role_rules.val[i]).pattern.val sub true

/-- The subject a token presents; a missing `sub` is the empty string. -/
def subject (c : Claims) : List U8 := (c.sub.map (·.val)).getD []

/-- A scope containing a bare `*` places no restriction. -/
def Unrestricted (scope : List (alloc.vec.Vec U8)) : Prop := ∃ p ∈ scope, nats p.val = lit "*"

/-- A namespace is inside a scope when it matches one of its patterns. -/
def InScope (scope : List (alloc.vec.Vec U8)) (ns : List U8) : Prop := ∃ p ∈ scope, NsMatch p.val ns

/-! ## Reference models of the matchers -/

/-- `glob_match` (`auth/oidc.rs`) over lists: the pattern split at `*`; the
first part is a prefix, the last a suffix, and the middle parts occur in
order, each at its leftmost position. -/
def partsMatch : List (List Nat) → Nat → List Nat → Bool
  | [], _, _ => true
  | part :: rest, i, v =>
    if part = [] then partsMatch rest (i + 1) v
    else if i = 0 then
      if part <+: v then partsMatch rest (i + 1) (v.drop part.length) else false
    else if rest = [] then part <:+ v
    else match (List.range (v.length + 1)).find? (fun k => part <+: v.drop k) with
      | some k => partsMatch rest (i + 1) (v.drop (k + part.length))
      | none => false

def globSpec (pattern v : List Nat) : Bool :=
  if pattern = lit "*" then true
  else
    let parts := pattern.splitOn 42
    if parts.length = 1 then pattern = v else partsMatch parts 0 v

/-- Shell-style glob on one segment: `*` matches any run of bytes. -/
def segGlobSpec : List Nat → List Nat → Bool
  | [], v => v = []
  | 42 :: p, v => segGlobSpec p v || match v with
    | [] => false
    | _ :: v' => segGlobSpec (42 :: p) v'
  | c :: p, v => match v with
    | [] => false
    | x :: v' => c = x && segGlobSpec p v'
termination_by p v => p.length + v.length

/-! ## The middleware (`auth/mod.rs`) -/

def isPublicPath (p : List Nat) : Bool :=
  p = lit "/" || p = lit "/health" || p = lit "/ready" || p = lit "/api/tokens" ||
    p = lit "/api/tokens/list" || p = lit "/api/tokens/revoke"

def isTokenPage (p : List Nat) : Bool := (lit "/ui/tokens").isPrefixOf p || (lit "/api/ui/tokens").isPrefixOf p

def isWebSurface (p : List Nat) : Bool :=
  !isTokenPage p && ((lit "/ui").isPrefixOf p || (lit "/api/ui").isPrefixOf p || (lit "/api-docs").isPrefixOf p)

def isAdminPath (p : List Nat) : Bool := (lit "/api/v1/admin/").isPrefixOf p

def isNpmAudit (p : List Nat) : Bool :=
  p = lit "/npm/-/npm/v1/security/advisories/bulk" || p = lit "/npm/-/npm/v1/security/audits/quick"

/-- Paths served without credentials under this configuration. -/
def IsOpen (cfg : middleware.Config) (p : List Nat) : Prop :=
  isPublicPath p ∨ (isWebSurface p ∧ (cfg.anonymous_read ∨ cfg.public_web_ui)) ∨
    (p = lit "/metrics" ∧ cfg.public_metrics)

def isWriteMethod : middleware.HttpMethod → Bool
  | .Post | .Put | .Delete | .Patch => true
  | _ => false

/-- The request passes to the handler. -/
def Passes (o : middleware.Outcome) : Prop := ∃ a u r, o = .Next a u r

/-! ## CIDR ranges (`TrustedProxies::contains`) -/

/-- `addr` is in `net/len`: the top `len` bits agree. -/
def inPrefix (bits : Nat) (net addr len : Nat) : Bool :=
  if len = 0 then true
  else if bits ≤ len then net = addr
  else net / 2 ^ (bits - len) = addr / 2 ^ (bits - len)

def entryContains : net.IpAddr × U8 → net.IpAddr → Bool
  | (.V4 n, p), .V4 a => inPrefix 32 n.val a.val p.val
  | (.V6 n, p), .V6 a => inPrefix 128 n.val a.val p.val
  | _, _ => false

def cidrContains (entries : List (net.IpAddr × U8)) (ip : net.IpAddr) : Bool :=
  entries.any (entryContains · ip)

/-! ## Validators (`validation.rs`) -/

def isAlnum (c : Nat) : Bool := (48 ≤ c && c ≤ 57) || (65 ≤ c && c ≤ 90) || (97 ≤ c && c ≤ 122)
def isLowerHex (c : Nat) : Bool := (48 ≤ c && c ≤ 57) || (97 ≤ c && c ≤ 102)

/-- `sha256:` and 64 lowercase hex digits, or `sha512:` and 128. -/
def DigestShape (d : List Nat) : Prop :=
  (∃ h, d = lit "sha256:" ++ h ∧ h.length = 64 ∧ h.all isLowerHex) ∨
  (∃ h, d = lit "sha512:" ++ h ∧ h.length = 128 ∧ h.all isLowerHex)

/-- A tag: 1 to 128 characters, starting alphanumeric, of `[A-Za-z0-9._-]`. -/
def TagShape (t : List Nat) : Prop :=
  ∃ c rest, t = c :: rest ∧ t.length ≤ 128 ∧ isAlnum c ∧
    t.all (fun x => isAlnum x || x = 46 || x = 95 || x = 45)

/-- A storage key that cannot leave its directory. -/
def SafeKey (k : List Nat) : Prop :=
  k ≠ [] ∧ k.all (· < 128) ∧ 0 ∉ k ∧ 92 ∉ k ∧ k.head? ≠ some 47 ∧
    ∀ seg ∈ k.splitOn 47, seg ≠ lit "." ∧ seg ≠ lit ".."

/-- A Docker name: at most 256 bytes; `/`-separated segments that are
nonempty, start alphanumeric, and use `[a-z0-9._-]`. -/
def DockerNameShape (n : List Nat) : Prop :=
  n.length ≤ 256 ∧ ∀ seg ∈ n.splitOn 47, ∃ c rest, seg = c :: rest ∧ isAlnum c ∧
    seg.all (fun x => (97 ≤ x && x ≤ 122) || (48 ≤ x && x ≤ 57) || x = 46 || x = 95 || x = 45)

end nora_kernel.Spec
