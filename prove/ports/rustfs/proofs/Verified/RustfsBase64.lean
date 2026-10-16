import Verified.RustfsCondData
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Spec
theorem Base64Blocks.lengths {es ds} (h : Base64Blocks es ds) :
    3 * es.length = 4 * ds.length ∧ es.length % 4 = 0 := by
  induction h with
  | empty => simp
  | append _ _ _ _ _ ih =>
    simp only [List.length_append, List.length_cons, List.length_nil, Base64Bytes]
    omega

theorem Base64Encoding.lengths {es ds} (h : Base64Encoding es ds) :
    es.length % 4 = 0 ∧ ds.length ≤ 3 * (es.length / 4) ∧
      3 * (es.length / 4) ≤ ds.length + 2 := by
  cases h with
  | complete hb => have := hb.lengths; omega
  | one hb _ _ _ =>
    have := hb.lengths
    simp only [List.length_append, List.length_cons, List.length_nil]
    omega
  | two hb _ _ _ _ =>
    have := hb.lengths
    simp only [List.length_append, List.length_cons, List.length_nil]
    omega

end rustfs_kernel.Spec
namespace rustfs_kernel.Verified.RustfsBase64
 theorem take_four {T : Type} (xs : List T) (i : Nat) (hi : i + 3 < xs.length) :
    xs.take (i + 4) = xs.take i ++ [xs[i], xs[i+1], xs[i+2], xs[i+3]] := by
  have h0 : i < xs.length := by omega
  have h1 : i+1 < xs.length := by omega
  have h2 : i+2 < xs.length := by omega
  have ht0 := List.take_add_one (l := xs) (i := i)
  have ht1 := List.take_add_one (l := xs) (i := i+1)
  have ht2 := List.take_add_one (l := xs) (i := i+2)
  have ht3 := List.take_add_one (l := xs) (i := i+3)
  simp only [List.getElem?_eq_getElem h0, Option.toList_some] at ht0
  simp only [List.getElem?_eq_getElem h1, Option.toList_some] at ht1
  simp only [List.getElem?_eq_getElem h2, Option.toList_some] at ht2
  simp only [List.getElem?_eq_getElem hi, Option.toList_some] at ht3
  rw [ht3, ht2, ht1, ht0]
  simp only [List.append_assoc, List.cons_append, List.nil_append]

 theorem shl_bv (a : U8) (n : I32) (r : U8) (h0 : 0 ≤ n.val) (hn : n.val < 8)
    (h : a <<< n = ok r) : r.bv = a.bv <<< n.toNat := by
  exact (post_of_ok (UScalar.ShiftLeft_IScalar_spec a n (UScalar.size .U8) h0 hn rfl) h).2
 theorem shr_bv (a : U8) (n : I32) (r : U8) (h0 : 0 ≤ n.val) (hn : n.val < 8)
    (h : a >>> n = ok r) : r.bv = a.bv >>> n.toNat := by
  exact (post_of_ok (UScalar.ShiftRight_IScalar_spec a n h0 hn) h).2

set_option maxHeartbeats 1000000 in
theorem decode_sound (encoded : Slice U8) (v : alloc.vec.Vec U8)
    (h : conddata.decode_base64 encoded = ok (.Ok v)) :
    Base64Encoding (nats encoded.val) (v.val.map (·.bv)) := by
  unfold conddata.decode_base64 at h
  h5i_invert h
  unfold conddata.decode_base64_loop at h
  have hh : ∀ vv : alloc.vec.Vec U8, (core.result.Result.Ok v : core.result.Result (alloc.vec.Vec U8) conddata.BinaryFuncValueError) = core.result.Result.Ok vv →
      Base64Encoding (nats encoded.val) (vv.val.map (·.bv)) := by
    refine loop_ok _ (fun x : alloc.vec.Vec U8 × Usize =>
        x.2.val ≤ encoded.val.length ∧
        Base64Blocks (nats (encoded.val.take x.2.val)) (x.1.val.map (·.bv)))
      (fun rr => ∀ vv, rr = core.result.Result.Ok vv →
        Base64Encoding (nats encoded.val) (vv.val.map (·.bv)))
      (fun x => encoded.val.length - x.2.val) ?_ (alloc.vec.Vec.new U8, 0#usize) (.Ok v)
      ⟨by simp, by simpa [nats] using Base64Blocks.empty⟩ h
    rintro ⟨out, i⟩ r ⟨hi, hb⟩ hr
    unfold conddata.decode_base64_loop.body at hr
    h5i_invert hr
    all_goals try (intro vv hv; cases hv)
    all_goals try
      apply Base64Encoding.complete
      have he : encoded.val.take i.val = encoded.val := List.take_of_length_le (by scalar_tac)
      simpa only [he] using hb
    all_goals
      have hsA := (rustfs_kernel.Verified.RustfsCondData.base64_digit_ok _ _ ho a).1 rfl
      have hsB := (rustfs_kernel.Verified.RustfsCondData.base64_digit_ok _ _ ho1 a_1).1 rfl
      have hleft : i5.bv = a.bv <<< 2 := by simpa using shl_bv a 2#i32 i5 (by decide) (by decide) hi5
      have hright : i6.bv = a_1.bv >>> 4 := by simpa using shr_bv a_1 4#i32 i6 (by decide) (by decide) hi6
      have hor := hi7
      simp only [lift, Result.ok.injEq] at hor
      have hpack1 : i7.bv = (a.bv <<< 2) ||| (a_1.bv >>> 4) := by
        rw [← hor, UScalar.bv_or, hleft, hright]
      have hp1 : out1.val.map (·.bv) = out.val.map (·.bv) ++ [(a.bv <<< 2) ||| (a_1.bv >>> 4)] := by
        rw [rustfs_kernel.Verified.RustfsBytes.push_ok hout1, List.map_append]
        simp only [List.map_cons, List.map_nil, hpack1]
      obtain ⟨hl0, he0⟩ := slice_index_ok hi2
      obtain ⟨hl1raw, he1raw⟩ := slice_index_ok hi4
      have hadd1 := add_ok_val hi3
      have hl1 : i.val + 1 < encoded.val.length := by scalar_tac
      have he1 : encoded.val[i.val+1]'hl1 = i4 := by simpa [hadd1] using he1raw
    · have hlen : i.val + 4 = encoded.val.length := by
        have := add_ok_val hi10
        scalar_tac
      obtain ⟨hl3raw, he3raw⟩ := slice_index_ok hi13
      have ha3 := add_ok_val hi12
      have hl3 : i.val + 3 < encoded.val.length := by scalar_tac
      have he3 : encoded.val[i.val+3]'hl3 = i13 := by
        simpa [show i12.val = i.val + 3 by scalar_tac] using he3raw
      obtain ⟨hl2raw, he2raw⟩ := slice_index_ok hi9
      have ha2 := add_ok_val hi8
      have hl2 : i.val + 2 < encoded.val.length := by scalar_tac
      have he2 : encoded.val[i.val+2]'hl2 = i9 := by
        simpa [show i8.val = i.val + 2 by scalar_tac] using he2raw
      have heq : i13 = 61#u8 := by scalar_tac
      have hm : a_1.bv &&& 15 = 0 := by
        have hm := hi14
        simp only [lift, Result.ok.injEq] at hm
        have hz : i14 = 0#u8 := by scalar_tac
        have hz' := congrArg UScalar.bv (hm.trans hz)
        simpa [UScalar.bv_and] using hz'
      have ht := take_four encoded.val i.val hl3
      rw [hlen, List.take_length, he0, he1, he2, he3, hc_2, heq] at ht
      rw [ht, hp1]
      simp only [nats, List.map_append, List.map_cons, List.map_nil]
      apply Base64Encoding.one hb
      · simpa only [UScalar.bv_toNat] using hsA
      · simpa only [UScalar.bv_toNat] using hsB
      · exact hm
    all_goals
      have hsC := (rustfs_kernel.Verified.RustfsCondData.base64_digit_ok _ _ ho2 a_2).1 rfl
      have hlft : i11.bv = a_1.bv <<< 4 := by simpa using shl_bv a_1 4#i32 i11 (by decide) (by decide) hi11
      have hrgt : i12.bv = a_2.bv >>> 2 := by simpa using shr_bv a_2 2#i32 i12 (by decide) (by decide) hi12
      have hor2 := hi13
      simp only [lift, Result.ok.injEq] at hor2
      have hpack2 : i13.bv = (a_1.bv <<< 4) ||| (a_2.bv >>> 2) := by
        rw [← hor2, UScalar.bv_or, hlft, hrgt]
      have hp2 : out2.val.map (·.bv) = out.val.map (·.bv) ++
          [(a.bv <<< 2) ||| (a_1.bv >>> 4), (a_1.bv <<< 4) ||| (a_2.bv >>> 2)] := by
        rw [rustfs_kernel.Verified.RustfsBytes.push_ok hout2, List.map_append, hp1]
        simp only [List.map_cons, List.map_nil, hpack2, List.append_assoc, List.cons_append, List.nil_append]
      obtain ⟨hl2raw, he2raw⟩ := slice_index_ok hi10
      have ha2 := add_ok_val hi8
      have hl2 : i.val + 2 < encoded.val.length := by scalar_tac
      have he2 : encoded.val[i.val+2]'hl2 = i10 := by
        simpa [show i8.val = i.val + 2 by scalar_tac] using he2raw
      obtain ⟨hl3raw, he3raw⟩ := slice_index_ok hi15
      have ha3 := add_ok_val hi14
      have hl3 : i.val + 3 < encoded.val.length := by scalar_tac
      have he3 : encoded.val[i.val+3]'hl3 = i15 := by
        simpa [show i14.val = i.val + 3 by scalar_tac] using he3raw
    · have hlen : i.val + 4 = encoded.val.length := by
        have := add_ok_val hi16
        scalar_tac
      have hm : a_2.bv &&& 3 = 0 := by
        have hm := hi18
        simp only [lift, Result.ok.injEq] at hm
        have hz : i18 = 0#u8 := by scalar_tac
        have hz' := congrArg UScalar.bv (hm.trans hz)
        simpa [UScalar.bv_and] using hz'
      have ht := take_four encoded.val i.val hl3
      rw [hlen, List.take_length, he0, he1, he2, he3, hc_3] at ht
      rw [ht, hp2]
      simp only [nats, List.map_append, List.map_cons, List.map_nil]
      apply Base64Encoding.two hb
      · simpa only [UScalar.bv_toNat] using hsA
      · simpa only [UScalar.bv_toNat] using hsB
      · simpa only [UScalar.bv_toNat] using hsC
      · exact hm
    · have hsD := (rustfs_kernel.Verified.RustfsCondData.base64_digit_ok _ _ ho3 a_3).1 rfl
      have hlf3 : i17.bv = a_2.bv <<< 6 := by simpa using shl_bv a_2 6#i32 i17 (by decide) (by decide) hi17
      have hor3 := hi18
      simp only [lift, Result.ok.injEq] at hor3
      have hpack3 : i18.bv = (a_2.bv <<< 6) ||| a_3.bv := by
        rw [← hor3, UScalar.bv_or, hlf3]
      have hp3 : out3.val.map (·.bv) = out.val.map (·.bv) ++ Base64Bytes a.bv a_1.bv a_2.bv a_3.bv := by
        rw [rustfs_kernel.Verified.RustfsBytes.push_ok hout3, List.map_append, hp2]
        simp only [List.map_cons, List.map_nil, hpack3, Base64Bytes, List.append_assoc, List.cons_append, List.nil_append]
      obtain ⟨hl3raw', he3raw'⟩ := slice_index_ok hi16
      have he3' : encoded.val[i.val+3]'hl3 = i16 := by
        simpa [show i14.val = i.val + 3 by scalar_tac] using he3raw'
      have hadv := add_ok_val hi19
      have hstep : i19.val = i.val + 4 := by scalar_tac
      change (_ ∧ _) ∧ _
      refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
      have ht := take_four encoded.val i.val hl3
      rw [hstep, ht, he0, he1, he2, he3', hp3]
      simp only [nats, List.map_append, List.map_cons, List.map_nil]
      apply Base64Blocks.append hb
      · simpa only [UScalar.bv_toNat] using hsA
      · simpa only [UScalar.bv_toNat] using hsB
      · simpa only [UScalar.bv_toNat] using hsC
      · simpa only [UScalar.bv_toNat] using hsD
  exact hh v rfl
end rustfs_kernel.Verified.RustfsBase64
