import Proofs
import H5iAppLib.ReadOnly
/-!
# `Peek` writes nothing

The only read-only command is `Peek` (report poll health). This proves that
every accepted `Peek` produces an empty write set, for every state — the
`h5i-app` read-only soundness obligation.
-/
open Aeneas Aeneas.Std Result anova_oven_kernel
namespace anova_oven_kernel.ReadOnly

/-- The write set a `transition` reply carries, as a list of states. -/
def writesOf : Option Queue → List Queue
  | none => []
  | some n => [n]

/-- The actorless `transition`, wrapped with a trivial principal for the
`h5i-app` run/read-only machinery. -/
def tr (_a : Unit) (s : Queue) (c : Command) :
    Result (core.result.Result ((Option Queue) × Reply) Error) :=
  transition s c

/-- Every accepted `Peek` writes nothing, for all states. -/
theorem sound : H5iAppLib.ReadOnly.Sound read_only tr writesOf := by
  apply H5iAppLib.ReadOnly.sound_of_spec
  intro a s c hro
  cases c <;> simp [read_only] at hro
  unfold tr transition
  step* <;> simp [H5iAppLib.OnOk, writesOf]

end anova_oven_kernel.ReadOnly
