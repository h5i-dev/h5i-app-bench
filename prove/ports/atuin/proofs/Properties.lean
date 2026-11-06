import Spec
open Aeneas Aeneas.Std Result atuin_kernel

namespace atuin_kernel.Properties

theorem ascii_lower_A : ascii_lower 65#u8 = ok 97#u8 := by
  simp [ascii_lower]

end atuin_kernel.Properties
