import Aeneas
import H5iAppLib.Basic
/-!
# Spec: pico-bit's armory path-confinement policy, as a list-level model

This file states the security policy *independently of the kernel*: a decoded
filename is "safe" exactly when appending it after `/armory/` names a direct,
non-escaping child of the armory directory. `Properties.lean` proves the
extracted kernel's accept gate implies this policy.
-/
open Aeneas Aeneas.Std

namespace PicoBit.Spec

/-- `/` (0x2F), `\` (0x5C) and NUL (0x00): the bytes that, inside a filename,
would let `/armory/<name>` denote something other than a direct child of
`/armory`. Mirrors `is_separator` in the kernel. -/
def IsSep (b : Std.U8) : Prop := b = 47#u8 ∨ b = 92#u8 ∨ b = 0#u8

instance (b : Std.U8) : Decidable (IsSep b) := by unfold IsSep; infer_instance

/-- The confinement policy on a decoded filename `bs`.

`bs` is safe when it is a non-empty, at-most-64-byte component that is neither
the current-directory `.` nor the parent-directory `..`, and contains no path
separator or NUL. A LittleFS path `/armory/` ++ `bs` built from a safe `bs`
therefore has exactly the two segments `armory` and `bs`, with `bs` a leaf that
cannot ascend out of `/armory`. This is the traversal-confinement property an
auditor cares about; it is phrased without reference to the kernel. -/
def SafeName (bs : List Std.U8) : Prop :=
  bs ≠ [] ∧
  bs.length ≤ 64 ∧
  bs ≠ [46#u8] ∧
  bs ≠ [46#u8, 46#u8] ∧
  (∀ b ∈ bs, ¬ IsSep b)

end PicoBit.Spec
