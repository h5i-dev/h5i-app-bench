import Properties
open Aeneas Aeneas.Std Result m5airq_kernel
/-!
# `Status` is read-only

Self-contained (no `H5iAppLib.ReadOnly` dependency): a command the kernel
classifies read-only (`read_only c = true`, i.e. `Status`) never produces a
write set, so it cannot change the OTA session state.
-/
namespace m5airq_kernel.ReadOnly

/-- Every accepted read-only command writes nothing, for all actors/states. -/
theorem sound (a : Device) (s : OtaState) (c : Command) (ws : Option OtaState) (r : Reply)
    (hro : read_only c = ok true) (ht : transition a s c = ok (.Ok (ws, r))) : ws = none := by
  cases c <;> simp_all [read_only, transition]

end m5airq_kernel.ReadOnly
