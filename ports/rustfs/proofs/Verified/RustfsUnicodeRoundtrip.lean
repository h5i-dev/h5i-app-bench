import Verified.RustfsUnicodeCodec
import Verified.RustfsForceDelete
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
namespace rustfs_kernel.Verified.RustfsUnicodeRoundtrip

theorem or_prefix (low high bits : Nat) (h : low < 2 ^ bits) :
    (2 ^ bits * high) ||| low = 2 ^ bits * high + low :=
  (Nat.two_pow_add_eq_or_of_lt h high).symm

theorem pack (high low bits : Nat) (h : low < 2 ^ bits) :
    (high <<< bits) ||| low = high * 2 ^ bits + low := by
  rw [Nat.shiftLeft_eq,Nat.mul_comm]
  exact or_prefix low high bits h

theorem mask63 (a : Nat) : a &&& 63 = a % 64 := by
  exact Nat.and_two_pow_sub_one_eq_mod a 6

theorem mask31 (a : Nat) : a &&& 31 = a % 32 := by
  exact Nat.and_two_pow_sub_one_eq_mod a 5

theorem encoding_two (cp : Nat) (h0 : 128 ≤ cp) (h1 : cp < 2048) :
    EncodeScalar cp = [192 + cp / 64,128 + cp % 64] := by
  have h192 : 192 ||| (cp >>> 6) = 192 + cp / 64 := by
    simp only [Nat.shiftRight_eq_div_pow]
    exact or_prefix (cp / 64) 6 5 (by omega)
  have h128 : 128 ||| (cp &&& 63) = 128 + cp % 64 := by
    rw [mask63]
    exact or_prefix (cp % 64) 2 6 (by omega)
  simp only [EncodeScalar,if_neg (by omega : ¬ cp < 128),if_pos h1,h192,h128]
  rw [Nat.mod_eq_of_lt (by omega),Nat.mod_eq_of_lt (by omega)]

theorem roundtrip_two (cp : Nat) (h0 : 128 ≤ cp) (h1 : cp < 2048) :
    DecodeScalar (EncodeScalar cp) 0 = (cp,2) := by
  rw [encoding_two cp h0 h1]
  unfold DecodeScalar
  dsimp only
  simp only [List.getElem?_cons_zero,List.getElem?_cons_succ,Option.getD_some]
  rw [if_neg (by omega),if_pos (by omega)]
  rw [mask31,mask63]
  have hm : (192 + cp / 64) % 32 = cp / 64 := by omega
  have hl : (128 + cp % 64) % 64 = cp % 64 := by omega
  rw [hm,hl,pack _ _ 6 (by omega)]
  congr 1
  omega

theorem mask15 (a : Nat) : a &&& 15 = a % 16 :=
  Nat.and_two_pow_sub_one_eq_mod a 4

theorem mask7 (a : Nat) : a &&& 7 = a % 8 :=
  Nat.and_two_pow_sub_one_eq_mod a 3

theorem encoding_three (cp : Nat) (h0 : 2048 ≤ cp) (h1 : cp < 65536) :
    EncodeScalar cp = [224 + cp / 4096,128 + (cp / 64) % 64,128 + cp % 64] := by
  have h224 : 224 ||| (cp >>> 12) = 224 + cp / 4096 := by
    simp only [Nat.shiftRight_eq_div_pow]
    exact or_prefix (cp / 4096) 14 4 (by omega)
  have h128 (x : Nat) : 128 ||| (x &&& 63) = 128 + x % 64 := by
    rw [mask63]
    exact or_prefix (x % 64) 2 6 (by omega)
  simp only [EncodeScalar,if_neg (by omega : ¬ cp < 128),
    if_neg (by omega : ¬ cp < 2048),if_pos h1,h224,h128]
  simp only [Nat.shiftRight_eq_div_pow]
  change [(224+cp/4096)%256,(128+(cp/64)%64)%256,(128+cp%64)%256] = _
  simp only [Nat.mod_eq_of_lt (by omega : 224+cp/4096<256),
    Nat.mod_eq_of_lt (by omega : 128+(cp/64)%64<256),
    Nat.mod_eq_of_lt (by omega : 128+cp%64<256)]

theorem roundtrip_three (cp : Nat) (h0 : 2048 ≤ cp) (h1 : cp < 65536) :
    DecodeScalar (EncodeScalar cp) 0 = (cp,3) := by
  rw [encoding_three cp h0 h1]
  unfold DecodeScalar
  dsimp only
  simp only [List.getElem?_cons_zero,List.getElem?_cons_succ,Option.getD_some]
  rw [if_neg (by omega),if_neg (by omega),if_pos (by omega)]
  rw [mask15,mask63,mask63]
  have hm : (224 + cp / 4096) % 16 = cp / 4096 := by omega
  have hb : (128 + (cp / 64) % 64) % 64 = (cp / 64) % 64 := by omega
  have hc : (128 + cp % 64) % 64 = cp % 64 := by omega
  rw [hm,hb,hc,Nat.or_assoc,pack _ _ 6 (by omega),pack _ _ 12 (by omega)]
  congr 1
  omega

theorem encoding_four (cp : Nat) (h0 : 65536 ≤ cp) (h1 : cp < 1114112) :
    EncodeScalar cp = [240 + cp / 262144,128 + (cp / 4096) % 64,
      128 + (cp / 64) % 64,128 + cp % 64] := by
  have h240 : 240 ||| (cp >>> 18) = 240 + cp / 262144 := by
    simp only [Nat.shiftRight_eq_div_pow]
    exact or_prefix (cp / 262144) 30 3 (by omega)
  have h128 (x : Nat) : 128 ||| (x &&& 63) = 128 + x % 64 := by
    rw [mask63]
    exact or_prefix (x % 64) 2 6 (by omega)
  simp only [EncodeScalar,if_neg (by omega : ¬ cp < 128),
    if_neg (by omega : ¬ cp < 2048),if_neg (by omega : ¬ cp < 65536),
    h240,h128]
  simp only [Nat.shiftRight_eq_div_pow]
  change [(240+cp/262144)%256,(128+(cp/4096)%64)%256,
    (128+(cp/64)%64)%256,(128+cp%64)%256] = _
  simp only [Nat.mod_eq_of_lt (by omega : 240+cp/262144<256),
    Nat.mod_eq_of_lt (by omega : 128+(cp/4096)%64<256),
    Nat.mod_eq_of_lt (by omega : 128+(cp/64)%64<256),
    Nat.mod_eq_of_lt (by omega : 128+cp%64<256)]

theorem roundtrip_four (cp : Nat) (h0 : 65536 ≤ cp) (h1 : cp < 1114112) :
    DecodeScalar (EncodeScalar cp) 0 = (cp,4) := by
  rw [encoding_four cp h0 h1]
  unfold DecodeScalar
  dsimp only
  simp only [List.getElem?_cons_zero,List.getElem?_cons_succ,Option.getD_some]
  rw [if_neg (by omega),if_neg (by omega),if_neg (by omega)]
  rw [mask7,mask63,mask63,mask63]
  have hm : (240 + cp / 262144) % 8 = cp / 262144 := by omega
  have hb : (128 + (cp / 4096) % 64) % 64 = (cp / 4096) % 64 := by omega
  have hc : (128 + (cp / 64) % 64) % 64 = (cp / 64) % 64 := by omega
  have hd : (128 + cp % 64) % 64 = cp % 64 := by omega
  rw [hm,hb,hc,hd,Nat.or_assoc,Nat.or_assoc,
    pack _ _ 6 (by omega),pack _ _ 12 (by omega),pack _ _ 18 (by omega)]
  congr 1
  omega

/-- Numeric UTF-8 encoding and decoding round trip for Unicode scalar values.
The equation also holds for surrogate code points in this numeric interval. -/
theorem roundtrip (cp : Nat) (h : cp < 1114112) :
    DecodeScalar (EncodeScalar cp) 0 = (cp,(EncodeScalar cp).length) := by
  by_cases h0 : cp < 128
  · simp [EncodeScalar,h0,DecodeScalar,Nat.mod_eq_of_lt (by omega : cp < 256)]
  by_cases h1 : cp < 2048
  · rw [roundtrip_two cp (by omega) h1,encoding_two cp (by omega) h1]
    rfl
  by_cases h2 : cp < 65536
  · rw [roundtrip_three cp (by omega) h2,encoding_three cp (by omega) h2]
    rfl
  · rw [roundtrip_four cp (by omega) h,encoding_four cp (by omega) h]
    rfl

/-- Decoding the successful encoding of a scalar returns that scalar and
consumes precisely the emitted octets. -/
theorem append_decode (cp : U32) (encoded : alloc.vec.Vec U8) (actual : U32 × Usize)
    (hc : cp.val < 1114112)
    (he : unicode.append_scalar (alloc.vec.Vec.new U8) cp = ok encoded)
    (hd : unicode.scalar_at (alloc.vec.Vec.deref encoded) 0#usize = ok actual) :
    actual.1 = cp ∧ actual.2.val = encoded.val.length := by
  have he' : nats encoded.val = EncodeScalar cp.val := by
    simpa [alloc.vec.Vec.new,nats] using (RustfsUnicodeCodec.append_ok _ _ _ he)
  have hd' := RustfsUnicodeCodec.decode_ok _ _ _ hd
  rw [RustfsForceDelete.deref_val, he'] at hd'
  change (actual.1.val,actual.2.val) = DecodeScalar (EncodeScalar cp.val) 0 at hd'
  rw [roundtrip cp.val hc] at hd'
  have hl : (EncodeScalar cp.val).length = encoded.val.length := by
    rw [← he']; simp [nats]
  constructor
  · apply UScalar.eq_of_val_eq
    exact congrArg Prod.fst hd'
  · exact (congrArg Prod.snd hd').trans hl

end rustfs_kernel.Verified.RustfsUnicodeRoundtrip
