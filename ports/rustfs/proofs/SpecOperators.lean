import SpecCondData
open Aeneas Aeneas.Std rustfs_kernel
namespace rustfs_kernel.Spec
/-- Numeric comparisons use the mathematical signed integer values. -/
def NumericComparison : condfuncs.NumOp → Int → Int → Prop
  | .Eq, a, b => a = b
  | .Ne, a, b => a ≠ b
  | .Lt, a, b => a < b
  | .Le, a, b => a ≤ b
  | .Gt, a, b => b < a
  | .Ge, a, b => b ≤ a
/-- Null tests value-list emptiness, including a missing key as an empty list. -/
def NullComparison (wantNull : Bool) (count : Nat) : Prop :=
  if wantNull then count = 0 else count ≠ 0
/-- CIDR membership compares the numeric prefix of addresses in the same family.
Prefixes at least the address width compare the whole address. -/
def NumericPrefix (width pref network address : Nat) : Prop :=
  network / 2 ^ (width - min pref width) = address / 2 ^ (width - min pref width)
end rustfs_kernel.Spec

namespace rustfs_kernel.Spec
/-- Ordered request lookup selects the first entry with this exact byte name. -/
def ConditionValues (values : List (List U8 × List (List U8))) (needle : List U8) :
    Option (List (List U8)) :=
  ((values.find? (fun e => decide (e.1 = needle))).map Prod.snd)

def RequestValueLists
    (values : List (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8))) :
    List (List U8 × List (List U8)) :=
  values.map (fun e => (e.1.val, e.2.val.map (·.val)))

def FirstConditionValue (values : List (List U8 × List (List U8))) (key : condfuncs.Key) :
    Option (List U8) :=
  (ConditionValues values (LookupName key)).bind List.head?

def NullConditions (funcs : List (condfuncs.Key × Bool))
    (values : List (List U8 × List (List U8))) : Prop :=
  ∀ e ∈ funcs, NullComparison e.2 ((ConditionValues values (LookupName e.1)).getD []).length
end rustfs_kernel.Spec

namespace rustfs_kernel.Spec
/-- Bool requires the first request value to spell exactly `true` or `false`. -/
def BoolConditions (funcs : List (condfuncs.Key × Bool))
    (values : List (List U8 × List (List U8))) : Prop :=
  ∀ e ∈ funcs, (FirstConditionValue values e.1).map nats =
    some (if e.2 then lit "true" else lit "false")

/-- Numeric evaluation is ordered. A missing first value terminates evaluation
with `ifExists`, even when later entries are present. Malformed decimal text
or a failed comparison terminates with false. -/
def NumericConditions (op : condfuncs.NumOp) (ifExists : Bool)
    (values : List (List U8 × List (List U8))) : List (condfuncs.Key × Int) → Prop
  | [] => True
  | (key, bound) :: rest =>
    match FirstConditionValue values key with
    | none => ifExists = true
    | some text => ∃ number, parseI64Spec (nats text) = some number ∧
        NumericComparison op number bound ∧ NumericConditions op ifExists values rest

/-- CIDR membership requires an address of the same family. -/
def IpPrefix : condfuncs.IpAddr → Nat → condfuncs.IpAddr → Prop
  | .V4 network, pref, .V4 address => NumericPrefix 32 pref network.val address.val
  | .V6 network, pref, .V6 address => NumericPrefix 128 pref network.val address.val
  | _, _, _ => False
end rustfs_kernel.Spec

namespace rustfs_kernel.Spec
/-- A request byte string matches at least one glob candidate. -/
def AnyStringLike (patterns : List (List U8)) (value : List U8) : Prop :=
  ∃ p ∈ patterns, globSpec (nats p) (nats value) = true
/-- Quantified string matching negates each match before taking the requested
quantifier. The unquantified case ignores the inner negation flag; its caller
applies negation to the aggregate match. -/
def StringMatchHolds (q : condfuncs.Quantifier) (negate matched : Bool) : Bool :=
  match q with
  | .None => matched
  | _ => matched != negate
/-- One quantified value decides universal failure or existential success. -/
def LikeStep (q : condfuncs.Quantifier) (negate matched : Bool) : Option Bool :=
  match q with
  | .ForAllValues => if StringMatchHolds q negate matched then none else some false
  | _ => if StringMatchHolds q negate matched then some true else none
end rustfs_kernel.Spec

namespace rustfs_kernel.Spec
/-- Date comparisons operate on UTC instants in nanoseconds. Other operators
have no date interpretation and return false. -/
def DateComparison : conddata.Op → Int → Int → Prop
  | .DateEquals, a, b => a = b
  | .DateNotEquals, a, b => a ≠ b
  | .DateLessThan, a, b => a < b
  | .DateLessThanEquals, a, b => a ≤ b
  | .DateGreaterThan, a, b => b < a
  | .DateGreaterThanEquals, a, b => b ≤ a
  | _, _, _ => False
end rustfs_kernel.Spec

namespace rustfs_kernel.Spec
/-- Address parsing is supplied by the environment's ordered text/address table.
The first exact-name entry wins, including an explicit parse failure. -/
def ParsedAddress (table : List (List U8 × Option condfuncs.IpAddr)) (text : List U8) :
    Option condfuncs.IpAddr :=
  (table.find? (fun e => decide (e.1 = text))).bind Prod.snd
end rustfs_kernel.Spec

namespace rustfs_kernel.Spec
/-- A network list denotes the union of its same-family numeric prefixes. -/
def AnyNetwork (networks : List (condfuncs.IpAddr × U8)) (address : condfuncs.IpAddr) : Prop :=
  ∃ entry ∈ networks, IpPrefix entry.1 entry.2.val address
end rustfs_kernel.Spec

namespace rustfs_kernel.Spec
/-- Per-value negation applies only to explicit quantifiers. -/
def LikeValue (q : condfuncs.Quantifier) (negate : Bool)
    (patterns : List (List U8)) (value : List U8) : Prop :=
  match q with
  | .None => AnyStringLike patterns value
  | _ => if negate then ¬ AnyStringLike patterns value else AnyStringLike patterns value
/-- Universal matching accepts an empty request list; the other forms require
at least one matching request value. -/
def QuantifiedLike (q : condfuncs.Quantifier) (negate : Bool)
    (patterns requests : List (List U8)) : Prop :=
  match q with
  | .ForAllValues => ∀ value ∈ requests, LikeValue q negate patterns value
  | _ => ∃ value ∈ requests, LikeValue q negate patterns value
end rustfs_kernel.Spec
