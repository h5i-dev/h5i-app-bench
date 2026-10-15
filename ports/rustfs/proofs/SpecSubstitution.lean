import SpecKernel
open Aeneas Aeneas.Std
namespace rustfs_kernel.Spec
/-- Left-to-right non-overlapping literal replacement. An empty search string
leaves the input unchanged. Replacement bytes are not searched again. -/
def ReplaceSuffix (s search replacement : List U8) (offset : Nat) : List U8 :=
  if hi : offset < s.length then
    if hp : 0 < search.length ∧ search <+: s.drop offset then
      replacement ++ ReplaceSuffix s search replacement (offset+search.length)
    else s[offset] :: ReplaceSuffix s search replacement (offset+1)
  else []
termination_by s.length-offset

def ReplaceBytes (s search replacement : List U8) : List U8 :=
  ReplaceSuffix s search replacement 0
end rustfs_kernel.Spec
