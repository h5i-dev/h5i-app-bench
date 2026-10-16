import SpecClaims
open Aeneas Aeneas.Std rustfs_kernel
namespace rustfs_kernel.Spec
/-- Scalar claim values exposed to variable substitution. Compound JSON values are omitted. -/
def VariableScalar : claims.Value → Option (List Nat)
  | .String s | .Number s => some (nats s.val)
  | .Bool b => some (if b then lit "true" else lit "false")
  | _ => none
/-- First exact-name lookup in the ordered claim entries. -/
def NamedClaimValue (table : List (alloc.vec.Vec U8 × claims.Value))
    (needle : List Nat) : Option claims.Value :=
  (table.find? (fun e => decide (nats e.1.val = needle))).map Prod.snd

/-- Array claims expose their scalar elements in order; scalar claims expose a singleton. -/
def VariableStrings (v : claims.Value) : Option (List (List Nat)) :=
  match v with
  | .Array es => some (es.val.filterMap VariableScalar)
  | _ => (VariableScalar v).map (fun s => [s])
def ResolverStrings (r : varctx.VariableResolver) (needle : List Nat) : Option (List (List Nat)) :=
  r.context.claims.bind (fun table => (NamedClaimValue table.val needle).bind VariableStrings)

/-- Missing string lists fall back to parent; an empty selected list has no last value. -/
def VariableUserID (r : varctx.VariableResolver) : Option (List Nat) :=
  ((ResolverStrings r (lit "sub")).orElse (fun _ => ResolverStrings r (lit "parent"))).bind List.getLast?

/-- Claim classification depends on key presence, regardless of its JSON value. -/
def VariableClaimPresent (r : varctx.VariableResolver) (needle : List Nat) : Prop :=
  ∃ table, r.context.claims = some table ∧ ∃ e ∈ table.val, nats e.1.val = needle
noncomputable def VariablePrincipalType (r : varctx.VariableResolver) : List Nat := by
  classical
  exact if VariableClaimPresent r (lit "roleArn") then lit "AssumedRole"
  else if VariableClaimPresent r (lit "parent") ∧ VariableClaimPresent r (lit "sa-policy")
    then lit "ServiceAccount" else lit "User"

def CustomValue (table : List (alloc.vec.Vec U8 × alloc.vec.Vec U8))
    (needle : List U8) : Option (alloc.vec.Vec U8) :=
  (table.find? (fun e => decide (e.1.val = needle))).map Prod.snd
def VariableCustom (r : varctx.VariableResolver) (needle : List U8) : Option (alloc.vec.Vec U8) :=
  if lit "custom:" <+: nats needle then CustomValue r.context.custom_variables.val (needle.drop 7)
  else none

/-- Substitution values from the context, explicit clock inputs, and custom namespace. -/
noncomputable def VariableResolution (r : varctx.VariableResolver) (needle : List U8)
    (env : condfuncs.Env) : Option (List Nat) := by
  classical
  exact if nats needle = lit "aws:username" then r.context.username.map (fun v => nats v.val)
    else if nats needle = lit "aws:userid" then VariableUserID r
    else if nats needle = lit "aws:PrincipalType" then some (VariablePrincipalType r)
    else if nats needle = lit "aws:SecureTransport" then some (if r.context.is_https then lit "true" else lit "false")
    else if nats needle = lit "aws:CurrentTime" then some (nats env.now_rfc3339.val)
    else if nats needle = lit "aws:EpochTime" then some (nats env.now_epoch.val)
    else if nats needle = lit "aws:AccountId" then r.context.account_id.map (fun v => nats v.val)
    else if nats needle = lit "aws:Region" then r.context.region.map (fun v => nats v.val)
    else if nats needle = lit "aws:SourceIp" then r.context.source_ip.map (fun v => nats v.val)
    else (VariableCustom r needle).map (fun v => nats v.val)

/-- User IDs expose all claim strings; other variables expose singleton values. -/
noncomputable def VariableMultiple (r : varctx.VariableResolver) (needle : List U8)
    (env : condfuncs.Env) : Option (List (List Nat)) :=
  if nats needle = lit "aws:userid" then
    (ResolverStrings r (lit "sub")).orElse (fun _ => ResolverStrings r (lit "parent"))
  else (VariableResolution r needle env).map (fun v => [v])
end rustfs_kernel.Spec
