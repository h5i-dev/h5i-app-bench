import SpecKernel
open Aeneas Aeneas.Std
namespace rustfs_kernel.Spec
def ByteOccurrence (s p : List U8) (k : Nat) : Prop :=
  k + p.length ≤ s.length ∧ ∀ j < p.length, s[k+j]? = p[j]?
/-- The first literal occurrence at or after the requested offset. Absence
means that no such occurrence exists. An empty pattern occurs at each
position up to and including the end of the input. -/
def FirstOccurrence (s p : List U8) (offset : Nat) : Option Nat → Prop
  | none => ∀ k, offset ≤ k → ¬ ByteOccurrence s p k
  | some j => offset ≤ j ∧ ByteOccurrence s p j ∧ ∀ k, offset ≤ k → k < j → ¬ ByteOccurrence s p k
/-- Wrap each replacement in the surrounding bytes and resume scanning after
its inserted bytes. Results preserve the replacement-list order. -/
def WrappedValues (pre : List U8) (values : List (List U8)) (post : List U8) (offset : Nat) :
    List (List U8 × Nat) := values.map (fun v => (pre++v++post,offset+v.length))
/-- First-occurrence duplicate removal, preserving the order of distinct texts. -/
def UniqueBytes (values : List (List U8)) : List (List U8) :=
  values.foldl (fun acc text => if text ∈ acc then acc else acc++[text]) []
end rustfs_kernel.Spec
