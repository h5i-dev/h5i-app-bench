import Verified.RustfsBytes
import Verified.RustfsValids
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsUnicodeAppend
set_option maxRecDepth 8192
set_option maxHeartbeats 2000000

def Utf8Width (cp : Nat) : Nat :=
  if cp < 128 then 1 else if cp < 2048 then 2 else if cp < 65536 then 3 else 4

theorem append_preserves_prefix (initial out : alloc.vec.Vec U8) (cp : U32)
    (h : unicode.append_scalar initial cp = ok out) :
    ∃ bs : List U8, out.val = initial.val ++ bs ∧ bs.length = Utf8Width cp.val := by
  unfold unicode.append_scalar at h
  h5i_invert h
  all_goals
    have hf := RustfsBytes.push_ok h
    try have h1 := RustfsBytes.push_ok hout1
    try have h2 := RustfsBytes.push_ok hout2
    try have h3 := RustfsBytes.push_ok hout3
    simp only [*,List.append_assoc]
    refine ⟨_,rfl,?_⟩
    try simp_scalar at hc
    try simp_scalar at hc_1
    try simp_scalar at hc_2
    simp [Utf8Width, *]
  all_goals split_ifs <;> scalar_tac
end rustfs_kernel.Verified.RustfsUnicodeAppend
