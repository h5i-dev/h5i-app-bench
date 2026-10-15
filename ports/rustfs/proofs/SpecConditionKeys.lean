import SpecOperators
open Aeneas Aeneas.Std
namespace rustfs_kernel.Spec
/-- Operator keys, retaining their list order and repetitions. -/
def OperatorKeys : condfuncs.Cond → List condfuncs.Key
  | .Str _ f => f.val.map Prod.fst
  | .Ip _ f => f.val.map Prod.fst
  | .Null f => f.val.map Prod.fst
  | .Bool f => f.val.map Prod.fst
  | .Num _ _ f => f.val.map Prod.fst
/-- Presence depends on the key, including when its request value list is empty. -/
def OperatorKeyPresent (c : condfuncs.Cond)
    (values : List (List U8 × List (List U8))) : Prop :=
  ∃ key ∈ OperatorKeys c, ∃ entry ∈ values, entry.1 = LookupName key
/-- Resource selection examines the full condition key names in all three groups. -/
def OperatorReferences (c : condfuncs.Cond) (needle : List U8) : Prop :=
  ∃ key ∈ OperatorKeys c, key.key_name.val=needle
def FunctionsReference (f : condfuncs.Functions) (needle : List U8) : Prop :=
  ∃ c ∈ f.for_any_value.val ++ f.for_all_values.val ++ f.for_normal.val,
    OperatorReferences c.cond needle
end rustfs_kernel.Spec
