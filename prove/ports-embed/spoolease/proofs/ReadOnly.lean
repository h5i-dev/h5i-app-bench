import Properties
import H5iAppLib.ReadOnly
open Aeneas Aeneas.Std Result spoolease_kernel
namespace spoolease_kernel.ReadOnly

def writesOf : Option Store → List Store
  | none => []
  | some n => [n]

/-- Every accepted `Query` writes nothing, for all actors and states. -/
theorem sound : H5iAppLib.ReadOnly.Sound read_only transition writesOf := by
  apply H5iAppLib.ReadOnly.sound_of_spec
  intro a s c hro
  cases c <;> simp [read_only] at hro
  unfold transition
  simp [H5iAppLib.OnOk, writesOf]

end spoolease_kernel.ReadOnly
