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

/-- The confinement policy on the first `len` bytes of a buffer `bytes`.

The first `len` bytes form a safe filename when `len` is in `1..=64`, the
component is neither `.` nor `..`, and none of those bytes is a path separator
or NUL. A LittleFS path `/armory/` ++ (first `len` bytes) built from a safe
prefix therefore has exactly the two segments `armory` and the filename, with
the filename a leaf that cannot ascend out of `/armory`. This is the
traversal-confinement property an auditor cares about; it is a statement about
the byte buffer, independent of the kernel code. -/
def SafeNameAt (bytes : List Std.U8) (len : Nat) : Prop :=
  0 < len ∧
  len ≤ 64 ∧
  len ≤ bytes.length ∧
  ¬ (len = 1 ∧ bytes[0]! = 46#u8) ∧
  ¬ (len = 2 ∧ bytes[0]! = 46#u8 ∧ bytes[1]! = 46#u8) ∧
  (∀ k, k < len → ¬ IsSep (bytes[k]!))

end PicoBit.Spec
