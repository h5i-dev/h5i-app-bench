import SpecKernel
open Aeneas Aeneas.Std rustfs_kernel
namespace rustfs_kernel.Spec
/-- Exact claim lookup selects the first entry with the requested byte name. -/
def FirstNamedClaim (table : List (alloc.vec.Vec U8 × claims.Value))
    (needle : List U8) (index : Nat) : Prop :=
  ∃ hi : index < table.length, table[index].1.val = needle ∧
    ∀ j (hj : j < index), table[j]'(by omega) |>.1.val ≠ needle

def ClaimLookupResult (table : List (alloc.vec.Vec U8 × claims.Value))
    (needle : List U8) : Option Usize → Prop
  | some index => FirstNamedClaim table needle index.val
  | none => ∀ e ∈ table, e.1.val ≠ needle
end rustfs_kernel.Spec
namespace rustfs_kernel.Spec
/-- Existing-object tag keys have either a bare or s3-qualified name,
with an optional slash-delimited suffix. -/
def ExistingTagKey (key : List Nat) : Prop :=
  key = lit "ExistingObjectTag" ∨ key = lit "s3:ExistingObjectTag" ∨
  lit "ExistingObjectTag/" <+: key ∨ lit "s3:ExistingObjectTag/" <+: key
end rustfs_kernel.Spec
namespace rustfs_kernel.Spec
/-- A matching object key occurs anywhere in the JSON tree. Scalar values
contribute no keys, and array elements contribute their nested object keys. -/
inductive ExistingTagUse : claims.Value → Prop
  | object_key (entries : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value))
      (e : alloc.vec.Vec U8 × claims.Value) :
      e ∈ entries.val → ExistingTagKey (nats e.1.val) → ExistingTagUse (.Object entries)
  | object_value (entries : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value))
      (e : alloc.vec.Vec U8 × claims.Value) :
      e ∈ entries.val → ExistingTagUse e.2 → ExistingTagUse (.Object entries)
  | array_value (entries : alloc.vec.Vec claims.Value) (v : claims.Value) :
      v ∈ entries.val → ExistingTagUse v → ExistingTagUse (.Array entries)
end rustfs_kernel.Spec

namespace rustfs_kernel.Spec
/-- Every extracted policy token contains at least one byte. -/
def NonemptyClaimTokens (vs : List (alloc.vec.Vec U8)) : Prop :=
  ∀ v ∈ vs, v.val ≠ []

/-- Claims expose strings directly or through an array; other JSON types do
not supply policy strings. -/
def ClaimStringContainer : claims.Value → Prop
  | .String _ | .Array _ => True
  | _ => False
end rustfs_kernel.Spec
