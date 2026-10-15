import SpecKernel
open Aeneas Aeneas.Std
namespace rustfs_kernel.Spec
/-- Resolver inputs represented only as byte lists and presence flags. -/
structure AwsValueContext where
  username : List Nat
  account : List Nat
  sub : Option (List (List Nat))
  parent : Option (List (List Nat))
  hasParent : Bool
  hasRoleArn : Bool
  hasSaPolicy : Bool
  currentTime : List Nat
  epochTime : List Nat
/-- A present subject list takes priority over parent, including an empty list. -/
def AwsUserIds (c : AwsValueContext) : Option (List (List Nat)) :=
  c.sub.orElse (fun _ => c.parent)
def AwsPrincipalType (c : AwsValueContext) : List Nat :=
  if c.hasRoleArn then lit "AssumedRole"
  else if c.hasParent && c.hasSaPolicy then lit "ServiceAccount" else lit "User"
/-- The policy resolver exposes these seven names. SecureTransport is the
literal false; all other names, including Region and SourceIp, are absent. -/
def AwsValue (c : AwsValueContext) (needle : List Nat) : Option (List Nat) :=
  if needle = lit "aws:username" then some c.username
  else if needle = lit "aws:userid" then (AwsUserIds c).bind List.getLast?
  else if needle = lit "aws:PrincipalType" then some (AwsPrincipalType c)
  else if needle = lit "aws:SecureTransport" then some (lit "false")
  else if needle = lit "aws:CurrentTime" then some c.currentTime
  else if needle = lit "aws:EpochTime" then some c.epochTime
  else if needle = lit "aws:AccountId" then some c.account
  else none
/-- User IDs retain every selected claim value; other resolved names expose
one value. An empty selected user-ID list remains present and empty. -/
def AwsValues (c : AwsValueContext) (needle : List Nat) : Option (List (List Nat)) :=
  if needle = lit "aws:userid" then AwsUserIds c
  else (AwsValue c needle).map (fun v => [v])

/-- Scan balanced braces from the start of a byte list. The offset points at
 the closing brace when the balance becomes zero, or past the list when no
 closing brace is found. Every opening and closing brace affects the balance. -/
def ClosingTail : List Nat → Nat → Nat × Nat
  | xs,b => if b=0 then (0,0) else
    match xs with
    | [] => (0,b)
    | x::rest =>
      let next := if x=123 then b+1 else if x=125 then b-1 else b
      if next=0 then (0,0)
      else let result := ClosingTail rest next
           (result.1+1,result.2)
def ClosingAt (s : List Nat) (offset balance : Nat) : Nat × Nat :=
  let result := ClosingTail (s.drop offset) balance
  (offset+result.1,result.2)

end rustfs_kernel.Spec
