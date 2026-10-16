import SpecKernel
open Aeneas Aeneas.Std Result rustfs_kernel
namespace rustfs_kernel.Spec
/-- A text can be extended to match the pattern: either an encountered star
absorbs the remaining text, or every byte of the text agrees with the pattern. -/
def PatternPrefix (p t : List U8) : Prop :=
  ∃ k, k ≤ p.length ∧ k ≤ t.length ∧
    (∀ j < k, p[j]? = some (63#u8) ∨ p[j]? = t[j]?) ∧
    ((k < p.length ∧ k < t.length ∧ p[k]? = some (42#u8)) ∨ k = t.length)
end rustfs_kernel.Spec
