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



def SameKey (a b : condfuncs.Key) : Prop :=
  a.key_name.val = b.key_name.val ∧ a.name.val = b.name.val ∧
    a.variable.map (·.val) = b.variable.map (·.val)

def SameStringSet (a b : alloc.vec.Vec (alloc.vec.Vec U8)) : Prop :=
  (∀ x ∈ a.val, ∃ y ∈ b.val, y.val = x.val) ∧
  (∀ y ∈ b.val, ∃ x ∈ a.val, x.val = y.val)

def SameStringEntry (p : conddata.FuncKeyValue (alloc.vec.Vec (alloc.vec.Vec U8)) ×
    conddata.FuncKeyValue (alloc.vec.Vec (alloc.vec.Vec U8))) : Prop :=
  SameKey p.1.key p.2.key ∧ SameStringSet p.1.values p.2.values

def SameStringCondition (a b : conddata.InnerFunc (alloc.vec.Vec (alloc.vec.Vec U8))) : Prop :=
  a.entries.val.length = b.entries.val.length ∧
    ∀ p ∈ a.entries.val.zip b.entries.val, SameStringEntry p

def SameNumberEntry (p : conddata.FuncKeyValue I64 × conddata.FuncKeyValue I64) : Prop :=
  SameKey p.1.key p.2.key ∧ p.1.values = p.2.values

def SameNumberCondition (a b : conddata.InnerFunc I64) : Prop :=
  a.entries.val.length = b.entries.val.length ∧
    ∀ p ∈ a.entries.val.zip b.entries.val, SameNumberEntry p

def SameDateEntry (p : conddata.FuncKeyValue conddata.DateFuncValue × conddata.FuncKeyValue conddata.DateFuncValue) : Prop :=
  SameKey p.1.key p.2.key ∧ p.1.values.unix_nanos = p.2.values.unix_nanos

def SameDateCondition (a b : conddata.InnerFunc conddata.DateFuncValue) : Prop :=
  a.entries.val.length = b.entries.val.length ∧
    ∀ p ∈ a.entries.val.zip b.entries.val, SameDateEntry p


def SameBinaryEntry (p : conddata.FuncKeyValue conddata.BinaryFuncValue ×
    conddata.FuncKeyValue conddata.BinaryFuncValue) : Prop :=
  SameKey p.1.key p.2.key ∧ p.1.values.decoded.val = p.2.values.decoded.val

def SameBinaryCondition (a b : conddata.InnerFunc conddata.BinaryFuncValue) : Prop :=
  a.entries.val.length = b.entries.val.length ∧
    ∀ p ∈ a.entries.val.zip b.entries.val, SameBinaryEntry p


def SameBoolEntry (p : conddata.FuncKeyValue Bool × conddata.FuncKeyValue Bool) : Prop :=
  SameKey p.1.key p.2.key ∧ p.1.values = p.2.values

def SameBoolCondition (a b : conddata.InnerFunc Bool) : Prop :=
  a.entries.val.length = b.entries.val.length ∧
    ∀ p ∈ a.entries.val.zip b.entries.val, SameBoolEntry p

def SameAddrEntry (p : conddata.FuncKeyValue (alloc.vec.Vec (condfuncs.IpAddr × U8)) ×
    conddata.FuncKeyValue (alloc.vec.Vec (condfuncs.IpAddr × U8))) : Prop :=
  SameKey p.1.key p.2.key ∧ p.1.values.val = p.2.values.val

def SameAddrCondition (a b : conddata.InnerFunc (alloc.vec.Vec (condfuncs.IpAddr × U8))) : Prop :=
  a.entries.val.length = b.entries.val.length ∧
    ∀ p ∈ a.entries.val.zip b.entries.val, SameAddrEntry p

def SameConditionData : conddata.Data → conddata.Data → Prop
  | .Str a, .Str b => SameStringCondition a b
  | .Addr a, .Addr b => SameAddrCondition a b
  | .Boolean a, .Boolean b => SameBoolCondition a b
  | .Num a, .Num b => SameNumberCondition a b
  | .Date a, .Date b => SameDateCondition a b
  | .Binary a, .Binary b => SameBinaryCondition a b
  | _, _ => False

/-- Equality preserves operator, wrapper depth and ordered data semantics. -/
def SameCondition (a b : conddata.Condition) : Prop :=
  a.op = b.op ∧ a.wrappers = b.wrappers ∧ SameConditionData a.data b.data

/-- Every source condition has equivalent contents in the target group. -/
def ConditionGroupCovered (a b : List conddata.Condition) : Prop :=
  ∀ c ∈ a, ∃ d ∈ b, SameCondition d c
/-- Group comparison retains quantifier boundaries and occurrence counts. -/
def ConditionGroupsMatch (a b : conddata.Functions) : Prop :=
  a.for_any_value.val.length = b.for_any_value.val.length ∧
  a.for_all_values.val.length = b.for_all_values.val.length ∧
  a.for_normal.val.length = b.for_normal.val.length ∧
  ConditionGroupCovered a.for_any_value.val b.for_any_value.val ∧
  ConditionGroupCovered a.for_all_values.val b.for_all_values.val ∧
  ConditionGroupCovered a.for_normal.val b.for_normal.val

end rustfs_kernel.Spec
