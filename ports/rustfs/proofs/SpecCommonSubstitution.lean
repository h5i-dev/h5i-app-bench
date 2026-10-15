import SpecSubstitution
import SpecOperators
open Aeneas Aeneas.Std
namespace rustfs_kernel.Spec
/-- Interpret each natural number as a byte, modulo 256. -/
def ByteOfNat (n : Nat) : U8 := UScalar.ofNatCore (n % 256) (Nat.mod_lt _ (by decide))
def BytesOfNats (ns : List Nat) : List U8 := ns.map ByteOfNat
/-- The ordered common-key table is data, independent of the lookup helper. -/
def CommonByteEntries : List (List U8 × List U8) :=
  commonKeyEntries.map (fun e => (BytesOfNats e.1,BytesOfNats e.2))
/-- The first request value supplies a replacement only when it is nonempty. -/
def CommonReplacement (values : List (List U8 × List (List U8))) (keyName : List U8) :
    Option (List U8) :=
  ((ConditionValues values keyName).bind List.head?).filter (fun text => !text.isEmpty)
def ApplyCommonEntry (values : List (List U8 × List (List U8)))
    (pattern : List U8) (entry : List U8 × List U8) : List U8 :=
  match CommonReplacement values entry.1 with
  | none => pattern
  | some text => ReplaceBytes pattern entry.2 text
/-- Resource substitution visits every common key in table order. -/
def SubstituteCommon (pattern : List U8) (values : List (List U8 × List (List U8))) : List U8 :=
  CommonByteEntries.foldl (ApplyCommonEntry values) pattern
/-- String substitution selects the first eligible common key in table order.
Selection is independent of whether that key's placeholder occurs in the text. -/
def SubstituteFirstCommonFrom (values : List (List U8 × List (List U8)))
    (pattern : List U8) : List (List U8 × List U8) → List U8
  | [] => pattern
  | entry :: rest =>
    match CommonReplacement values entry.1 with
    | some text => ReplaceBytes pattern entry.2 text
    | none => SubstituteFirstCommonFrom values pattern rest
def SubstituteFirstCommon (pattern : List U8) (values : List (List U8 × List (List U8))) : List U8 :=
  SubstituteFirstCommonFrom values pattern CommonByteEntries
end rustfs_kernel.Spec
