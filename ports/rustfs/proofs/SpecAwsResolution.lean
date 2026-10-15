import SpecAwsValues
open Aeneas Aeneas.Std
namespace rustfs_kernel.Spec
/-- Whether a byte list contains the two-byte placeholder introducer. -/
def HasPlaceholder : List Nat → Bool
  | [] => false
  | 36 :: 123 :: _ => true
  | _ :: rest => HasPlaceholder rest
/-- Retain each text's first occurrence in expansion order. -/
def DistinctTexts (texts : List (List Nat)) : List (List Nat) :=
  texts.foldl (fun acc text => if text ∈ acc then acc else acc++[text]) []
/-- One left-to-right substitution pass. Inserted bytes are retained literally
for this pass. Unresolved and unbalanced placeholders are retained; a present
empty value list removes its placeholder. Nested placeholder bodies expand
as text, rather than becoming a fresh variable name in this pass. -/
def ExpansionPass (inner : List Nat → List (List Nat)) (c : AwsValueContext) :
    List Nat → List (List Nat)
  | [] => [[]]
  | 36 :: 123 :: rest =>
    let (closing,balance) := ClosingTail rest 1
    if balance ≠ 0 then [36 :: 123 :: rest]
    else
      let bodyBytes := rest.take closing
      let literal := (36 :: 123 :: rest).take (closing+3)
      let replacements := if HasPlaceholder bodyBytes then
          let expanded := inner bodyBytes
          if expanded=[] ∨ expanded=[bodyBytes] then [literal] else expanded
        else match AwsValues c bodyBytes with
          | none => [literal]
          | some [] => [[]]
          | some values => values
      replacements.flatMap (fun replacement =>
        (ExpansionPass inner c (rest.drop (closing+1))).map (replacement++·))
  | byte :: rest => (ExpansionPass inner c rest).map (byte::·)
termination_by text => text.length
decreasing_by all_goals simp_wf <;> omega
/-- A bounded sequence of substitution rounds. Every round removes duplicates,
including the final round in which every text expands to itself. -/
def ExpansionRounds (pass : List Nat → List (List Nat)) : Nat → List (List Nat) → List (List Nat)
  | 0, texts => texts
  | rounds+1, texts =>
    let next := DistinctTexts (texts.flatMap pass)
    if texts.any (fun previous => decide (pass previous ≠ [previous])) then
      ExpansionRounds pass rounds next
    else next
/-- Expansion performs at most ten passes at each of ten nesting levels.
Each pass forms ordered Cartesian alternatives, then retains first occurrences.
A pass with unchanged alternatives ends iteration after deduplication. -/
def ExpandVariables (c : AwsValueContext) (depth : Nat) (text : List Nat) :
    List (List Nat) :=
  if depth ≥ 10 then [text]
  else ExpansionRounds (ExpansionPass (ExpandVariables c (depth+1)) c) 10 [text]
termination_by 10-depth
decreasing_by omega
end rustfs_kernel.Spec
