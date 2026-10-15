import SpecKernel
open Aeneas Aeneas.Std rustfs_kernel

deriving instance DecidableEq for conddata.Op

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

/-- Table characterization: projection onto the legacy string operator family. -/
def StringOpProjection : conddata.Op → condfuncs.StrOp
  | .StringNotEquals => .StringNotEquals
  | .StringEqualsIgnoreCase => .StringEqualsIgnoreCase
  | .StringNotEqualsIgnoreCase => .StringNotEqualsIgnoreCase
  | .StringLike => .StringLike
  | .StringNotLike => .StringNotLike
  | .ArnLike => .ArnLike
  | .ArnNotLike => .ArnNotLike
  | .ArnEquals => .ArnEquals
  | .ArnNotEquals => .ArnNotEquals
  | _ => .StringEquals

/-- Table characterization: projection onto the legacy numeric operator family. -/
def NumberOpProjection : conddata.Op → condfuncs.NumOp
  | .NumericNotEquals => .Ne
  | .NumericLessThan => .Lt
  | .NumericLessThanEquals => .Le
  | .NumericGreaterThan => .Gt
  | .NumericGreaterThanIfExists | .NumericGreaterThanEquals => .Ge
  | _ => .Eq

/-- Matching views preserve typed entries and expose date/binary key presence. -/
def MatchingViewContents (c : conddata.Condition) (d : condfuncs.Cond) : Prop :=
  match c.data, d with
  | .Str f, .Str op es => op = StringOpProjection c.op ∧
      es.val = f.entries.val.map (fun e => (e.key, e.values))
  | .Addr f, .Ip neg es => neg = decide (c.op = .NotIpAddress) ∧
      es.val = f.entries.val.map (fun e => (e.key, e.values))
  | .Boolean f, .Null es => c.op = .Null ∧
      es.val = f.entries.val.map (fun e => (e.key, e.values))
  | .Boolean f, .Bool es => c.op ≠ .Null ∧
      es.val = f.entries.val.map (fun e => (e.key, e.values))
  | .Num f, .Num op flag es => op = NumberOpProjection c.op ∧
      flag = decide (c.op = .NumericGreaterThanIfExists) ∧
      es.val = f.entries.val.map (fun e => (e.key, e.values))
  | .Date f, .Null es => es.val = f.entries.val.map (fun e => (e.key, false))
  | .Binary f, .Null es => es.val = f.entries.val.map (fun e => (e.key, false))
  | _, _ => False

def MatchingView (c : conddata.Condition) (v : condfuncs.Condition) : Prop :=
  (v.if_exists = true ↔ 0 < c.wrappers.val) ∧ MatchingViewContents c v.cond

/-- View sequences preserve length, order and each condition's typed contents. -/
def MatchingViews (cs : List conddata.Condition) (vs : List condfuncs.Condition) : Prop :=
  List.Forall₂ MatchingView cs vs
/-- The base key exposes IfExists when a wrapper is present. -/
def ConditionBaseKeyName (c : conddata.Condition) : List Nat :=
  if 0 < c.wrappers.val then lit "IfExists" else lit (OpSpelling c.op)

/-- Standard Base64 byte packing from four six-bit symbols. -/
def Base64Bytes (a b c d : BitVec 8) : List (BitVec 8) :=
  [(a <<< 2) ||| (b >>> 4), (b <<< 4) ||| (c >>> 2), (c <<< 6) ||| d]

/-- An unpadded sequence of complete three-byte/four-symbol blocks. -/
inductive Base64Blocks : List Nat → List (BitVec 8) → Prop
  | empty : Base64Blocks [] []
  | append {es ds : _} {x y z w : Nat} {a b c d : BitVec 8} :
      Base64Blocks es ds → Base64Symbol x a.toNat → Base64Symbol y b.toNat →
      Base64Symbol z c.toNat → Base64Symbol w d.toNat →
      Base64Blocks (es ++ [x, y, z, w]) (ds ++ Base64Bytes a b c d)

/-- Canonical padded Base64: complete blocks followed by at most one padded block. -/
inductive Base64Encoding : List Nat → List (BitVec 8) → Prop
  | complete {es ds : _} : Base64Blocks es ds → Base64Encoding es ds
  | one {es ds : _} {x y : Nat} {a b : BitVec 8} :
      Base64Blocks es ds → Base64Symbol x a.toNat → Base64Symbol y b.toNat →
      b &&& 15 = 0 → Base64Encoding (es ++ [x, y, 61, 61])
        (ds ++ [(a <<< 2) ||| (b >>> 4)])
  | two {es ds : _} {x y z : Nat} {a b c : BitVec 8} :
      Base64Blocks es ds → Base64Symbol x a.toNat → Base64Symbol y b.toNat →
      Base64Symbol z c.toNat → c &&& 3 = 0 →
      Base64Encoding (es ++ [x, y, z, 61])
        (ds ++ [(a <<< 2) ||| (b >>> 4), (b <<< 4) ||| (c >>> 2)])
/-- Each binary condition value is paired with its canonical encoded input. -/
def BinaryValueEncoding (e d : alloc.vec.Vec U8) : Prop :=
  Base64Encoding (nats e.val) (d.val.map (·.bv))

/-- A request value has a canonical Base64 decoding. -/
def ValidBinaryRequest (e : alloc.vec.Vec U8) : Prop :=
  ∃ ds, Base64Encoding (nats e.val) ds

/-- A request value decodes to one of the expected byte strings. -/
def MatchingBinaryRequest (f : conddata.BinaryFuncValue) (e : alloc.vec.Vec U8) : Prop :=
  ∃ d ∈ f.decoded.val, Base64Encoding (nats e.val) (d.val.map (·.bv))

/-- Each binary condition entry has named request data, all valid, including a match. -/
def BinaryEntrySatisfied
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (e : conddata.FuncKeyValue conddata.BinaryFuncValue) : Prop :=
  ∃ kv ∈ values.val, kv.1.val = LookupName e.key ∧
    (∀ req ∈ kv.2.val, ValidBinaryRequest req) ∧
    ∃ req ∈ kv.2.val, MatchingBinaryRequest e.values req
end rustfs_kernel.Spec
