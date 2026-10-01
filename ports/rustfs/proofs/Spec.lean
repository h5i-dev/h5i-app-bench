import RustfsKernel
import H5iAppLib
/-!
# rustfs policy evaluation: the spec

From rustfs's `crates/policy` at e870a6d and the AWS IAM rules it follows.
Statements about a whole policy take a single statement's verdict from the
extracted `statement_is_allowed`; the matchers have their own theorems.
-/
open Aeneas Aeneas.Std rustfs_kernel

namespace rustfs_kernel.Spec

/-- A byte string as numbers. -/
def nats (v : List U8) : List Nat := v.map (·.val)

/-- The UTF-8 bytes of a literal. -/
def lit (s : String) : List Nat := s.toUTF8.toList.map (·.toNat)

/-- `pattern` matches `name`: `*` any run of bytes, `?` exactly one. -/
def globSpec : List Nat → List Nat → Bool
  | [], n => n = []
  | 42 :: p, n => globSpec p n || match n with
    | [] => false
    | _ :: n' => globSpec (42 :: p) n'
  | 63 :: p, n => match n with
    | [] => false
    | _ :: n' => globSpec p n'
  | c :: p, n => match n with
    | [] => false
    | x :: n' => c = x && globSpec p n'
termination_by p n => p.length + n.length

/-- One of the two force-delete actions, which `s3:*` does not grant. -/
def IsForceDelete (a : acts.Action) : Prop :=
  a.family = .S3 ∧ (nats a.name.val = lit "s3:ForceDeleteBucket" ∨ nats a.name.val = lit "s3:ForceDeleteObject")

/-- A cleaned path: `.`, or `/`-separated segments that are neither empty
nor `.`, after an optional leading `/`. -/
def CleanShape (c : List Nat) : Prop :=
  c = lit "." ∨ c = lit "/" ∨
    ∀ seg ∈ (if c.head? = some 47 then c.tail else c).splitOn 47, seg ≠ [] ∧ seg ≠ lit "."

/-- The decimal value of a nonempty digit string. -/
def digitsVal : List Nat → Option Nat
  | [] => none
  | ds => if ds.all (fun d => 48 ≤ d ∧ d ≤ 57) then some (ds.foldl (fun acc d => 10 * acc + (d - 48)) 0) else none

/-- `str::parse::<i64>()`: an optional `+` or `-`, then digits, in range. -/
def parseI64Spec (s : List Nat) : Option Int :=
  let (neg, ds) := match s with
    | 45 :: r => (true, r)
    | 43 :: r => (false, r)
    | r => (false, r)
  match digitsVal ds with
  | none => none
  | some v =>
    let x : Int := if neg then -(v : Int) else v
    if -(2 ^ 63 : Int) ≤ x ∧ x < 2 ^ 63 then some x else none

/-- `s` contains no variable reference `${`. -/
def NoVarRef (s : List U8) : Prop := ¬ (lit "${").IsInfix (nats s)

/-- Every value the resolver can substitute is free of `${`. -/
def PlainValues (ctx : awsvars.VarContext) : Prop :=
  NoVarRef ctx.username.val ∧ NoVarRef ctx.account.val ∧ NoVarRef ctx.now_rfc3339.val ∧
  NoVarRef ctx.now_epoch.val ∧
  (∀ l, ctx.claims.sub = some l → ∀ v ∈ l.val, NoVarRef v.val) ∧
  (∀ l, ctx.claims.parent = some l → ∀ v ∈ l.val, NoVarRef v.val)

end rustfs_kernel.Spec
