import SpecUnicode
import Verified.RustfsUnicodeAppend
import Verified.RustfsUnicodeDecode
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsUnicodeCodec
set_option maxHeartbeats 2000000
/-- The bytes appended are exactly the numerical scalar encoding. -/
theorem append_ok (initial out : alloc.vec.Vec U8) (cp : U32)
    (h : unicode.append_scalar initial cp = ok out) :
    nats out.val = nats initial.val ++ EncodeScalar cp.val := by
  unfold unicode.append_scalar at h
  h5i_invert h
  all_goals
    have hf := RustfsBytes.push_ok h
    try have h1 := RustfsBytes.push_ok hout1
    try have h2 := RustfsBytes.push_ok hout2
    try have h3 := RustfsBytes.push_ok hout3
    try have hs := post_of_ok (UScalar.ShiftRight_IScalar_spec cp 6#i32 (by scalar_tac) (by scalar_tac)) hi
    try have hs := post_of_ok (UScalar.ShiftRight_IScalar_spec cp 12#i32 (by scalar_tac) (by scalar_tac)) hi
    try have hs := post_of_ok (UScalar.ShiftRight_IScalar_spec cp 18#i32 (by scalar_tac) (by scalar_tac)) hi
    try have hs3 := post_of_ok (UScalar.ShiftRight_IScalar_spec cp 6#i32 (by scalar_tac) (by scalar_tac)) hi3
    try have hs3 := post_of_ok (UScalar.ShiftRight_IScalar_spec cp 12#i32 (by scalar_tac) (by scalar_tac)) hi3
    try have hs7 := post_of_ok (UScalar.ShiftRight_IScalar_spec cp 6#i32 (by scalar_tac) (by scalar_tac)) hi7
    simp only [lift, Result.ok.injEq] at *
    subst_vars
    simp only [hf, nats, List.map_append, List.map_cons, List.map_nil,
      List.append_assoc, UScalar.cast_val_eq, UScalar.val_or, UScalar.val_and]
    simp_scalar at hc
    try simp_scalar at hc_1
    try simp_scalar at hc_2
    simp_all [EncodeScalar]
    all_goals split_ifs <;> simp_all <;> omega

theorem slice_index_ok_get? {α} {s : Slice α} {i : Usize} {x : α}
    (h : s.index_usize i = ok x) : s.val[i.val]? = some x := by
  obtain ⟨hlt,he⟩ := slice_index_ok h
  rw [List.getElem?_eq_getElem hlt,he]

theorem cast_u8_val (a : U8) : (UScalar.cast .U32 a).val = a.val := by
  rw [UScalar.cast_val_eq]
  apply Nat.mod_eq_of_lt
  have := U8.lt_succ_max a
  change a.val < 4294967296
  omega

theorem masked_mod (a mask shift : Nat) (h : mask * 2 ^ shift < 4294967296) :
    ((a &&& mask) <<< shift) % 4294967296 = (a &&& mask) <<< shift := by
  apply Nat.mod_eq_of_lt
  rw [Nat.shiftLeft_eq]
  exact lt_of_le_of_lt (Nat.mul_le_mul_right _ Nat.and_le_right) h

theorem decode_ok (s : Slice U8) (i : Usize) (out : U32 × Usize)
    (h : unicode.scalar_at s i = ok out) :
    (out.1.val,out.2.val) = DecodeScalar (nats s.val) i.val := by
  unfold unicode.scalar_at at h
  h5i_invert h
  · have hx := slice_index_ok_get? hi1
    have hn := add_ok_val hi2
    simp only [lift,Result.ok.injEq] at hfirst
    subst first
    have hc : i1.val < 128 := by
      simpa only [UScalar.lt_equiv,cast_u8_val,show (128#u32).val = 128 by decide +kernel] using hc
    simp only [Prod.fst,Prod.snd,cast_u8_val]
    unfold DecodeScalar
    simp only [nats,List.getElem?_map,hx,Option.map_some,Option.getD_some,if_pos hc]
    congr 1
  · have hx := slice_index_ok_get? hi1
    have hy := slice_index_ok_get? hi5
    have ha1 := add_ok_val hi4
    have hn := add_ok_val hi9
    have hs3 := (post_of_ok (U32.ShiftLeft_IScalar_spec i2 6#i32 (by scalar_tac) (by scalar_tac)) hi3).1
    simp only [lift,Result.ok.injEq] at hfirst hi2 hi6 hi7 hi8
    subst first i2 i6 i7 i8
    have l31 : (31#u32).val = 31 := by decide +kernel
    have l63 : (63#u32).val = 63 := by decide +kernel
    have l128 : (128#u32).val = 128 := by decide +kernel
    have l224 : (224#u32).val = 224 := by decide +kernel
    have l240 : (240#u32).val = 240 := by decide +kernel
    simp only [UScalar.lt_equiv,cast_u8_val,l128] at hc
    simp only [UScalar.lt_equiv,cast_u8_val,l224] at hc_1
    have sz : U32.size = 4294967296 := by simp [U32.size, U32.numBits]
    have sh6 : (6#i32).toNat = 6 := by decide +kernel
    simp only [UScalar.val_and,cast_u8_val,l31,sh6,sz] at hs3
    rw [masked_mod _ 31 6 (by decide +kernel)] at hs3
    have u1 : (1#usize).val = 1 := by decide +kernel
    have u2 : (2#usize).val = 2 := by decide +kernel
    rw [u1] at ha1
    rw [ha1] at hy
    rw [u2] at hn
    simp only [Prod.fst,Prod.snd,UScalar.val_or,UScalar.val_and,cast_u8_val,l63,hs3,hn]
    unfold DecodeScalar
    simp only [nats,List.getElem?_map,hx,hy,Option.map_some,Option.getD_some,if_neg hc,if_pos hc_1]
  · have hx := slice_index_ok_get? hi1
    have hy := slice_index_ok_get? hi5
    have ha1 := add_ok_val hi4
    have hz := slice_index_ok_get? hi11
    have ha2 := add_ok_val hi10
    have hn := add_ok_val hi15
    have hs3 := (post_of_ok (U32.ShiftLeft_IScalar_spec i2 12#i32 (by scalar_tac) (by scalar_tac)) hi3).1
    have hs8 := (post_of_ok (U32.ShiftLeft_IScalar_spec i7 6#i32 (by scalar_tac) (by scalar_tac)) hi8).1
    simp only [lift,Result.ok.injEq] at hfirst hi2 hi6 hi7 hi9 hi12 hi13 hi14
    subst first i2 i6 i7 i9 i12 i13 i14
    have l15 : (15#u32).val = 15 := by decide +kernel
    have l63 : (63#u32).val = 63 := by decide +kernel
    have l128 : (128#u32).val = 128 := by decide +kernel
    have l224 : (224#u32).val = 224 := by decide +kernel
    have l240 : (240#u32).val = 240 := by decide +kernel
    simp only [UScalar.lt_equiv,cast_u8_val,l128] at hc
    simp only [UScalar.lt_equiv,cast_u8_val,l224] at hc_1
    simp only [UScalar.lt_equiv,cast_u8_val,l240] at hc_2
    have sz : U32.size = 4294967296 := by simp [U32.size, U32.numBits]
    have sh6 : (6#i32).toNat = 6 := by decide +kernel
    have sh12 : (12#i32).toNat = 12 := by decide +kernel
    simp only [UScalar.val_and,cast_u8_val,l15,sh12,sz] at hs3
    rw [masked_mod _ 15 12 (by decide +kernel)] at hs3
    simp only [UScalar.val_and,cast_u8_val,l63,sh6,sz] at hs8
    rw [masked_mod _ 63 6 (by decide +kernel)] at hs8
    have u1 : (1#usize).val = 1 := by decide +kernel
    have u2 : (2#usize).val = 2 := by decide +kernel
    have u3 : (3#usize).val = 3 := by decide +kernel
    rw [u1] at ha1
    rw [ha1] at hy
    rw [u2] at ha2
    rw [ha2] at hz
    rw [u3] at hn
    simp only [Prod.fst,Prod.snd,UScalar.val_or,UScalar.val_and,cast_u8_val,l63,hs3,hs8,hn]
    unfold DecodeScalar
    simp only [nats,List.getElem?_map,hx,hy,hz,Option.map_some,Option.getD_some,if_neg hc,if_neg hc_1,if_pos hc_2]
  · have hx := slice_index_ok_get? hi1
    have hy := slice_index_ok_get? hi5
    have ha1 := add_ok_val hi4
    have hz := slice_index_ok_get? hi11
    have ha2 := add_ok_val hi10
    have hw := slice_index_ok_get? hi17
    have ha3 := add_ok_val hi16
    have hn := add_ok_val hi21
    have hs3 := (post_of_ok (U32.ShiftLeft_IScalar_spec i2 18#i32 (by scalar_tac) (by scalar_tac)) hi3).1
    have hs8 := (post_of_ok (U32.ShiftLeft_IScalar_spec i7 12#i32 (by scalar_tac) (by scalar_tac)) hi8).1
    have hs14 := (post_of_ok (U32.ShiftLeft_IScalar_spec i13 6#i32 (by scalar_tac) (by scalar_tac)) hi14).1
    simp only [lift,Result.ok.injEq] at hfirst hi2 hi6 hi7 hi9 hi12 hi13 hi15 hi18 hi19 hi20
    subst first i2 i6 i7 i9 i12 i13 i15 i18 i19 i20
    have l7 : (7#u32).val = 7 := by decide +kernel
    have l63 : (63#u32).val = 63 := by decide +kernel
    have l128 : (128#u32).val = 128 := by decide +kernel
    have l224 : (224#u32).val = 224 := by decide +kernel
    have l240 : (240#u32).val = 240 := by decide +kernel
    simp only [UScalar.lt_equiv,cast_u8_val,l128] at hc
    simp only [UScalar.lt_equiv,cast_u8_val,l224] at hc_1
    simp only [UScalar.lt_equiv,cast_u8_val,l240] at hc_2
    have sz : U32.size = 4294967296 := by simp [U32.size, U32.numBits]
    have sh6 : (6#i32).toNat = 6 := by decide +kernel
    have sh12 : (12#i32).toNat = 12 := by decide +kernel
    have sh18 : (18#i32).toNat = 18 := by decide +kernel
    simp only [UScalar.val_and,cast_u8_val,l7,sh18,sz] at hs3
    rw [masked_mod _ 7 18 (by decide +kernel)] at hs3
    simp only [UScalar.val_and,cast_u8_val,l63,sh12,sz] at hs8
    rw [masked_mod _ 63 12 (by decide +kernel)] at hs8
    simp only [UScalar.val_and,cast_u8_val,l63,sh6,sz] at hs14
    rw [masked_mod _ 63 6 (by decide +kernel)] at hs14
    have u1 : (1#usize).val = 1 := by decide +kernel
    have u2 : (2#usize).val = 2 := by decide +kernel
    have u3 : (3#usize).val = 3 := by decide +kernel
    have u4 : (4#usize).val = 4 := by decide +kernel
    rw [u1] at ha1
    rw [ha1] at hy
    rw [u2] at ha2
    rw [ha2] at hz
    rw [u3] at ha3
    rw [ha3] at hw
    rw [u4] at hn
    simp only [Prod.fst,Prod.snd,UScalar.val_or,UScalar.val_and,cast_u8_val,l63,hs3,hs8,hs14,hn]
    unfold DecodeScalar
    simp only [nats,List.getElem?_map,hx,hy,hz,hw,Option.map_some,Option.getD_some,if_neg hc,if_neg hc_1,if_neg hc_2]
end rustfs_kernel.Verified.RustfsUnicodeCodec

