import SpecKernel
open Aeneas Aeneas.Std rustfs_kernel

namespace rustfs_kernel.Spec

/-- STANDARD base64 encodes six-bit indices using ASCII upper/lower letters,
digits, plus and slash. Padding is not an alphabet symbol. -/
def Base64Symbol (c i : Nat) : Prop :=
  (i < 26 ∧ c = 65 + i) ∨
  (26 ≤ i ∧ i < 52 ∧ c = 97 + (i - 26)) ∨
  (52 ≤ i ∧ i < 62 ∧ c = 48 + (i - 52)) ∨
  (i = 62 ∧ c = 43) ∨ (i = 63 ∧ c = 47)

end rustfs_kernel.Spec
