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

deriving instance DecidableEq for openobserve_kernel.delegation.Method

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
  ∃ g, o.given_mac = some g ∧
    (nats o.mac_current.val = nats g.val ∨ ∃ p, o.mac_previous = some p ∧ nats p.val = nats g.val)

/-- The token has the shape `o2dt.<claims>.<mac>`. -/
def TokenShape (t : List Nat) : Prop :=
  [111, 50, 100, 116, 46] /- o2dt. -/ <+: t ∧ 46 ∈ t.drop 5

/-- `verify`'s checks after the signature, in upstream's order, over `Int`. -/
def checkClaims (c : Claims) (now : Int) : core.result.Result Claims DelegationError :=
  if c.v.val ≠ 1 then .Err (.UnsupportedVersion c.v)
  else if c.exp.val ≤ now then .Err .Expired
  else if now + 60 < c.iat.val then .Err (.Malformed .IssuedInFuture)
  else if 3660 < c.exp.val - c.iat.val then .Err (.Malformed .LifetimeOverAnHour)
  else .Ok c

/-- The MAC under the previous key, if one is configured, matches. -/
def previousMatches (o : VerifyOracle) (g : List Nat) : Bool :=
  match o.mac_previous with
  | none => false
  | some p => nats p.val = g

/-- `verify(keys, token, now)`, in upstream's order. -/
def verifySpec (t : List Nat) (o : VerifyOracle) (now : Int) : core.result.Result Claims DelegationError :=
  if ¬ ([111, 50, 100, 116, 46] /- o2dt. -/ <+: t ∧ 46 ∈ t.drop 5) then .Err (.Malformed .Shape) else
  match o.given_mac with
  | none => .Err (.Malformed .MacEncoding)
  | some g =>
    if nats o.mac_current.val = nats g.val ∨ previousMatches o (nats g.val) then
      match o.claims with
      | none => .Err (.Malformed .ClaimsEncoding)
      | some c => checkClaims c now
    else .Err .BadSignature

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
    | v :: o :: r => if v = [118, 50] /- v2 -/ then (o, r) else (v, o :: r)
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
  let (v2, rest) := if [118, 50, 47] /- v2/ -/ <+: path then (true, path.drop 3) else (false, path)
  decide (m ≠ .Delete) && routes.any (fun r => decide (r.v2 = v2) && decide (m ∈ r.methods) && segsMatch r.segs (splitSlash rest))

def scopeRoutes (s : List Nat) : Option (List SRoute) :=
  if s = [97, 115, 115, 105, 115, 116, 97, 110, 116] /- assistant -/ then some assistantScope
  else if s = [115, 108, 97, 99, 107, 95, 97, 99, 116, 105, 111, 110] /- slack_action -/ then some slackActionScope
  else none

/-- `check_route`, in upstream's order. -/
def checkRoute (path pfx : List Nat) (m : Method) (org scope : List Nat) :
    core.result.Result Unit AuthError :=
  if pfx = [47, 112, 114, 111, 120, 121, 47] /- /proxy/ -/ then .Err (.Forbidden .Proxy) else
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
  [[97, 108, 101, 114, 116, 115] /- alerts -/, [102, 111, 108, 100, 101, 114, 115] /- folders -/, [114, 101, 112, 111, 114, 116, 115] /- reports -/, [115, 121, 110, 116, 104, 101, 116, 105, 99, 115] /- synthetics -/, [105, 110, 99, 105, 100, 101, 110, 116, 115] /- incidents -/, [100, 111, 119, 110, 116, 105, 109, 101, 115] /- downtimes -/,
   [119, 111, 114, 107, 102, 108, 111, 119, 115] /- workflows -/, [97, 108, 101, 114, 116, 95, 99, 97, 108, 105, 98, 114, 97, 116, 105, 111, 110] /- alert_calibration -/, [102, 108, 101, 101, 116, 115] /- fleets -/]

/-- The org the router serves for a path's segments. -/
def orgFromPath (cols : List (List Nat)) : List Nat :=
  match cols with
  | v :: org :: m :: _ => if v = [118, 50] /- v2 -/ ∧ m ∈ v2OrgModules then org else v
  | v :: _ => v
  | [] => []

/-- The `org_id` the `AuthExtractor` gives the permission check: the routed
path split at `/`, one trailing empty segment dropped (`core/src/auth.rs:346-360`). -/
def extractorOrg (path : List Nat) : List Nat :=
  let cols := splitSlash (relativePath path)
  orgFromPath (if 1 < cols.length ∧ cols.getLast? = some [] then cols.dropLast else cols)

/-! ## gRPC authentication -/

/-- ASCII lowercase. -/
def asciiLower (s : List Nat) : List Nat := s.map (fun c => if 65 ≤ c ∧ c ≤ 90 then c + 32 else c)

/-- A cache key `"{a}/{b}"`. -/
def joinKey (a b : List Nat) : List Nat := a ++ [47] ++ b

end openobserve_kernel.Spec
