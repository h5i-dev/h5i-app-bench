import Verified.EntryValidationHelpers
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel
open Aeneas.Std.WP H5iAppLib
namespace kanidm_kernel.Verified.EntryValidation
set_option maxHeartbeats 600000
set_option maxRecDepth 4096

/-- The full error, including ordered payloads, independent of vector bounds. -/
inductive Outcome where
  | accepted | noClass | invalidClass (names : List U16)
  | supplements (names : List U16) | excludes (names : List U16)
  | corrupted | missing (names : List U16)
  | phantom (key : U16) | invalidAttribute (key : U16)
  | invalidSyntax (key : U16) | notAllowed (key : U16)
def outcome : core.result.Result Unit entry_validation.Error → Outcome
  | .Ok _ => .accepted
  | .Err .NoClassFound => .noClass
  | .Err (.InvalidClass xs) => .invalidClass xs.val
  | .Err (.SupplementsNotSatisfied xs) => .supplements xs.val
  | .Err (.ExcludesNotSatisfied xs) => .excludes xs.val
  | .Err .Corrupted => .corrupted
  | .Err (.MissingMustAttribute xs) => .missing xs.val
  | .Err (.PhantomAttribute k) => .phantom k
  | .Err (.InvalidAttribute k) => .invalidAttribute k
  | .Err (.InvalidAttributeSyntax k) => .invalidSyntax k
  | .Err (.AttributeNotValidForClass k) => .notAllowed k

/-- Complete ordered schema decision. Interned identifiers and the supplied
    ValueSet intrinsic-validity flag are the explicit port boundaries. -/
def validateModel (entry : entry_validation.Entry)
    (classes : List entry_validation.ClassSchema) (attrs : List entry_validation.AttributeSchema) : Outcome :=
  if !entry.class_present then .noClass else
  match entry.classes with
  | none => .noClass
  | some names =>
    if 0#u16 ∈ names.val then .accepted else
    let invalid := invalidClasses classes names.val
    if invalid ≠ [] then .invalidClass invalid else
    let supplements := constraintsModel classes names.val 0#u8
    if supplements ≠ [] ∧ ¬(supplements.any (fun k => decide (k ∈ names.val))) then
      .supplements supplements else
    let excluded := (constraintsModel classes names.val 1#u8).filter (fun k => decide (k ∈ names.val))
    if excluded ≠ [] then .excludes excluded else
    let must := constraintsModel classes names.val 2#u8
    if !schemaComplete attrs must then .corrupted else
    let missing := missingModel entry attrs must
    if missing ≠ [] ∧ ¬2#u16 ∈ names.val then .missing missing else
    if 1#u16 ∈ names.val then outcome (attributesModel entry.attrs.val attrs [] true) else
    let may := constraintsModel classes names.val 3#u8
    if !schemaComplete attrs may then .corrupted else
    outcome (attributesModel entry.attrs.val attrs may false)

/-- All collected class lists fit in a machine-sized vector. This is solely an
    allocation bound, not an assumption that validation succeeds. -/
def capacity (entry : entry_validation.Entry) (classes : List entry_validation.ClassSchema) : Prop :=
  match entry.classes with
  | none => True
  | some names => constraintsWeight classes names.val ≤ Usize.max

/-- Total decision, exact first error and ordered payload, for every input whose
    collected schema constraints fit in a machine-sized vector. -/
@[step] theorem validate_spec (entry : entry_validation.Entry)
    (classes : Slice entry_validation.ClassSchema) (attrs : Slice entry_validation.AttributeSchema)
    (hcap : capacity entry classes.val) :
    entry_validation.validate entry classes attrs ⦃ r =>
      outcome r = validateModel entry classes.val attrs.val ⦄ := by
  unfold entry_validation.validate
  cases hc : entry.class_present
  all_goals cases hn : entry.classes
  all_goals simp only [capacity, hn] at hcap
  all_goals h5i_steps
  all_goals try simp_all [validateModel, outcome, alloc.vec.Vec.new, UScalar.eq_equiv,
    Std.Array.empty]
  all_goals try grind

end kanidm_kernel.Verified.EntryValidation
