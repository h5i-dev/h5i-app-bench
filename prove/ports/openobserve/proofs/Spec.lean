import SpecTables
/-!
# OpenObserve's delegated-token policy, over lists

Written from openobserve @ a774547 (`config/src/utils/delegation.rs`,
`api/common/src/auth/delegation.rs`, `core/src/auth.rs`) without calling the
kernel's functions: byte strings are `List Nat`, tables are the lists in
`SpecTables.lean` (generated from the same upstream source). The extracted
kernel's *types* (`Method`, `Claims`, error enums) are reused as plain data.
-/
open Aeneas Aeneas.Std openobserve_kernel openobserve_kernel.delegation

namespace openobserve_kernel.Spec

/-- A byte string as numbers. -/
def nats (v : List U8) : List Nat := v.map (·.val)

/-! ## Strings -/

/-- `str::split('/')`, accumulating the current piece. -/
def splitAcc : List Nat → List Nat → List (List Nat)
  | cur, [] => [cur]
  | cur, c :: cs => if c = 47 then cur :: splitAcc [] cs else splitAcc (cur ++ [c]) cs

def splitSlash (s : List Nat) : List (List Nat) := splitAcc [] s

/-! ## Delegated-token claims (`verify`) -/

/-- What `verify` demands of decoded claims at time `now`: version 1, not
expired, issued at most 60 s in the future, living at most 3660 s. The
arithmetic is over `Int`, where nothing wraps. -/
def ClaimsFresh (c : Claims) (now : Int) : Prop :=
  c.v.val = 1 ∧ now < c.exp.val ∧ c.iat.val ≤ now + 60 ∧ c.exp.val - c.iat.val ≤ 3660

/-- The signature check: the decoded MAC equals the MAC under the current
key, or under the previous key when one is configured. -/
def SignatureOk (o : VerifyOracle) : Prop :=
  ∃ g, o.given_mac = some g ∧ (o.mac_current.val = g.val ∨ ∃ p, o.mac_previous = some p ∧ p.val = g.val)

/-- The token has the shape `o2dt.<claims>.<mac>`. -/
def TokenShape (t : List Nat) : Prop :=
  lit "o2dt." <+: t ∧ 46 ∈ t.drop 5

/-! ## Route scopes (`check_route`) -/

/-- `relative_path`: one leading `/` stripped. -/
def relativePath (p : List Nat) : List Nat :=
  match p with
  | 47 :: q => q
  | _ => p

/-- `path_org`: the org segment, second after a `v2` segment, else first,
when it is non-empty and more of the path follows. -/
def pathOrg (rel : List Nat) : Option (List Nat) :=
  let (org, rest) : List Nat × List (List Nat) :=
    match splitSlash rel with
    | v :: o :: r => if v = lit "v2" then (o, r) else (v, o :: r)
    | [v] => (v, [])
    | [] => ([], [])
  if org ≠ [] ∧ rest ≠ [] then some org else none

/-- One `segments_match` slot. -/
def segOk : SSeg → List Nat → Bool
  | .lit l, c => c = l
  | .param, c => c ≠ []
  | .stream, c => c ≠ [] ∧ c ∉ reservedStreamSlots
  | .alertId, c => c ≠ [] ∧ c ∉ alertIdLiterals

/-- `segments_match`: as many columns as patterns, each matching its slot. -/
def segsMatch (ps : List SSeg) (cs : List (List Nat)) : Bool :=
  ps.length = cs.length ∧ (ps.zip cs).all (fun pc => segOk pc.1 pc.2)

/-- `in_scope`: never DELETE; a `v2/` prefix selects the v2 routes. -/
def inScope (routes : List SRoute) (m : Method) (path : List Nat) : Bool :=
  let (v2, rest) := if lit "v2/" <+: path then (true, path.drop 3) else (false, path)
  m ≠ .Delete ∧ routes.any (fun r => r.v2 = v2 ∧ m ∈ r.methods ∧ segsMatch r.segs (splitSlash rest))

def scopeRoutes (s : List Nat) : Option (List SRoute) :=
  if s = lit "assistant" then some assistantScope
  else if s = lit "slack_action" then some slackActionScope
  else none

/-- `check_route`, in upstream's order. -/
def checkRoute (path pfx : List Nat) (m : Method) (org scope : List Nat) :
    core.result.Result Unit AuthError :=
  if pfx = lit "/proxy/" then .Err (.Forbidden .Proxy) else
  match scopeRoutes scope with
  | none => .Err (.Forbidden .UnknownScope)
  | some routes =>
    match pathOrg (relativePath path) with
    | none => .Err (.Forbidden .NoOrg)
    | some o =>
      if o ≠ org then .Err (.Forbidden .OtherOrg)
      else if !inScope routes m (relativePath path) then .Err (.Forbidden .OutOfScope)
      else .Ok ()

/-! ## `core::auth::org_from_path` -/

def v2OrgModules : List (List Nat) :=
  [lit "alerts", lit "folders", lit "reports", lit "synthetics", lit "incidents", lit "downtimes",
   lit "workflows", lit "alert_calibration", lit "fleets"]

/-- The org the router serves for a path's segments. -/
def orgFromPath (cols : List (List Nat)) : List Nat :=
  match cols with
  | v :: org :: m :: _ => if v = lit "v2" ∧ m ∈ v2OrgModules then org else v
  | v :: _ => v
  | [] => []

end openobserve_kernel.Spec
