import SpecKernel
open Aeneas Aeneas.Std rustfs_kernel

namespace rustfs_kernel.Spec

/-- STANDARD base64 encodes six-bit indices using ASCII upper/lower letters,
digits, plus and slash. Padding is not an alphabet symbol. -/
def Base64Symbol (c i : Nat) : Prop :=
  (i < 26 ∧ c = 65 + i) ∨
  (26 ≤ i ∧ i < 52 ∧ c = 97 + (i - 26)) ∨
  (52 ≤ i ∧ i < 62 ∧ c = 48 + (i - 52)) ∨
  (i = 62 ∧ c = 43) ∨ (i = 63 ∧ c = 47)

/-- Request keys use the base name, followed by a slash and variable suffix when present. -/
def LookupName (k : condfuncs.Key) : List U8 :=
  match k.variable with
  | none => k.name.val
  | some v => k.name.val ++ [47#u8] ++ v.val

/-- The request key names associated with a condition, in entry order. -/
def ConditionLookupNames (c : conddata.Condition) : List (List U8) :=
  match c.data with
  | .Str f => f.entries.val.map (fun e => LookupName e.key)
  | .Addr f => f.entries.val.map (fun e => LookupName e.key)
  | .Boolean f => f.entries.val.map (fun e => LookupName e.key)
  | .Num f => f.entries.val.map (fun e => LookupName e.key)
  | .Date f => f.entries.val.map (fun e => LookupName e.key)
  | .Binary f => f.entries.val.map (fun e => LookupName e.key)

def RequestHasConditionKey (c : conddata.Condition)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8))) : Prop :=
  ∃ needle ∈ ConditionLookupNames c, ∃ entry ∈ values.val, entry.1.val = needle

/-- Canonical condition operator spellings used in policy keys. -/
def OpSpelling : conddata.Op → String
  | .StringEquals => "StringEquals"
  | .StringNotEquals => "StringNotEquals"
  | .StringEqualsIgnoreCase => "StringEqualsIgnoreCase"
  | .StringNotEqualsIgnoreCase => "StringNotEqualsIgnoreCase"
  | .StringLike => "StringLike"
  | .StringNotLike => "StringNotLike"
  | .ArnLike => "ArnLike"
  | .ArnNotLike => "ArnNotLike"
  | .ArnEquals => "ArnEquals"
  | .ArnNotEquals => "ArnNotEquals"
  | .BinaryEquals => "BinaryEquals"
  | .IpAddress => "IpAddress"
  | .NotIpAddress => "NotIpAddress"
  | .Null => "Null"
  | .Boolean => "Bool"
  | .NumericEquals => "NumericEquals"
  | .NumericNotEquals => "NumericNotEquals"
  | .NumericLessThan => "NumericLessThan"
  | .NumericLessThanEquals => "NumericLessThanEquals"
  | .NumericGreaterThan => "NumericGreaterThan"
  | .NumericGreaterThanIfExists => "NumericGreaterThanIfExists"
  | .NumericGreaterThanEquals => "NumericGreaterThanEquals"
  | .DateEquals => "DateEquals"
  | .DateNotEquals => "DateNotEquals"
  | .DateLessThan => "DateLessThan"
  | .DateLessThanEquals => "DateLessThanEquals"
  | .DateGreaterThan => "DateGreaterThan"
  | .DateGreaterThanEquals => "DateGreaterThanEquals"
/-- Nested wrappers retain one literal IfExists suffix per wrapper. -/
def ConditionKeyName (c : conddata.Condition) : List Nat :=
  lit (OpSpelling c.op) ++ (List.replicate c.wrappers.val (lit "IfExists")).flatten

end rustfs_kernel.Spec
