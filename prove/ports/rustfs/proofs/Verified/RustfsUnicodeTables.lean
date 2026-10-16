import SpecUnicode
import Verified.RustfsValids
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsUnicodeTables
set_option maxRecDepth 8192
set_option maxHeartbeats 2000000

theorem within_ok (cp start stop parity : U32) (b : Bool)
    (h : unicode.within cp start stop parity = ok b) :
    (b = true ↔ LowerRangeApplies cp.val (start.val,stop.val,parity.val,0)) := by
  unfold unicode.within at h
  h5i_invert h
  all_goals simp only [LowerRangeApplies,Prod.fst,Prod.snd]
  all_goals first
    | (have := rem_ok_val hi; have := sub_ok_val hi1; scalar_tac)
    | scalar_tac

theorem within_delta (cp start stop parity : U32) (delta : Int) (b : Bool)
    (h : unicode.within cp start stop parity = ok b) :
    (b = true ↔ LowerRangeApplies cp.val (start.val,stop.val,parity.val,delta)) :=
  within_ok cp start stop parity b h

theorem range0_ok (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_0 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges0 := by
  unfold unicode.range_0 at h
  h5i_invert h
  all_goals
    try have hb_spec := within_delta _ _ _ _ 32 _ hb
    try simp only [hc,Bool.false_eq_true,true_iff,false_iff] at hb_spec
    try simp_scalar at hb_spec
    try have hb1_spec := within_delta _ _ _ _ 32 _ hb1
    try simp only [hc_1,Bool.false_eq_true,true_iff,false_iff] at hb1_spec
    try simp_scalar at hb1_spec
    try have hb2_spec := within_delta _ _ _ _ 32 _ hb2
    try simp only [hc_2,Bool.false_eq_true,true_iff,false_iff] at hb2_spec
    try simp_scalar at hb2_spec
    try have hb3_spec := within_delta _ _ _ _ 1 _ hb3
    try simp only [hc_3,Bool.false_eq_true,true_iff,false_iff] at hb3_spec
    try simp_scalar at hb3_spec
    try have hb4_spec := within_delta _ _ _ _ 1 _ hb4
    try simp only [hc_4,Bool.false_eq_true,true_iff,false_iff] at hb4_spec
    try simp_scalar at hb4_spec
    try have hb5_spec := within_delta _ _ _ _ 1 _ hb5
    try simp only [hc_5,Bool.false_eq_true,true_iff,false_iff] at hb5_spec
    try simp_scalar at hb5_spec
    try have hb6_spec := within_delta _ _ _ _ 1 _ hb6
    try simp only [hc_6,Bool.false_eq_true,true_iff,false_iff] at hb6_spec
    try simp_scalar at hb6_spec
    try have hb7_spec := within_delta _ _ _ _ 1 _ hb7
    try simp only [hc_7,Bool.false_eq_true,true_iff,false_iff] at hb7_spec
    try simp_scalar at hb7_spec
    try have hb8_spec := within_delta _ _ _ _ 1 _ hb8
    try simp only [hc_8,Bool.false_eq_true,true_iff,false_iff] at hb8_spec
    try simp_scalar at hb8_spec
    try have hb9_spec := within_delta _ _ _ _ 205 _ hb9
    try simp only [hc_9,Bool.false_eq_true,true_iff,false_iff] at hb9_spec
    try simp_scalar at hb9_spec
    simp only [LowerRanges0,LookupLowerRanges,
      * , ↓reduceIte,Option.map_some,Option.map_none]
    try (have hadd := add_ok_val hi; simp [LowerRangeValue]; scalar_tac)
theorem range1_ok (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_1 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges1 := by
  unfold unicode.range_1 at h
  h5i_invert h
  all_goals
    try have hb_spec := within_delta _ _ _ _ 1 _ hb
    try simp only [hc,Bool.false_eq_true,true_iff,false_iff] at hb_spec
    try simp_scalar at hb_spec
    try have hb1_spec := within_delta _ _ _ _ 217 _ hb1
    try simp only [hc_1,Bool.false_eq_true,true_iff,false_iff] at hb1_spec
    try simp_scalar at hb1_spec
    try have hb2_spec := within_delta _ _ _ _ 1 _ hb2
    try simp only [hc_2,Bool.false_eq_true,true_iff,false_iff] at hb2_spec
    try simp_scalar at hb2_spec
    try have hb3_spec := within_delta _ _ _ _ 1 _ hb3
    try simp only [hc_3,Bool.false_eq_true,true_iff,false_iff] at hb3_spec
    try simp_scalar at hb3_spec
    try have hb4_spec := within_delta _ _ _ _ 1 _ hb4
    try simp only [hc_4,Bool.false_eq_true,true_iff,false_iff] at hb4_spec
    try simp_scalar at hb4_spec
    try have hb5_spec := within_delta _ _ _ _ 1 _ hb5
    try simp only [hc_5,Bool.false_eq_true,true_iff,false_iff] at hb5_spec
    try simp_scalar at hb5_spec
    try have hb6_spec := within_delta _ _ _ _ 1 _ hb6
    try simp only [hc_6,Bool.false_eq_true,true_iff,false_iff] at hb6_spec
    try simp_scalar at hb6_spec
    try have hb7_spec := within_delta _ _ _ _ 1 _ hb7
    try simp only [hc_7,Bool.false_eq_true,true_iff,false_iff] at hb7_spec
    try simp_scalar at hb7_spec
    try have hb8_spec := within_delta _ _ _ _ 1 _ hb8
    try simp only [hc_8,Bool.false_eq_true,true_iff,false_iff] at hb8_spec
    try simp_scalar at hb8_spec
    try have hb9_spec := within_delta _ _ _ _ 1 _ hb9
    try simp only [hc_9,Bool.false_eq_true,true_iff,false_iff] at hb9_spec
    try simp_scalar at hb9_spec
    simp only [LowerRanges1,LookupLowerRanges,
      * , ↓reduceIte,Option.map_some,Option.map_none]
    all_goals first
    | (have hadd := add_ok_val hi; simp [LowerRangeValue]; scalar_tac)
    | (have hsub := sub_ok_val hi; simp [LowerRangeValue]; scalar_tac)
    | rfl
theorem range2_ok (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_2 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges2 := by
  unfold unicode.range_2 at h
  h5i_invert h
  all_goals
    try have hb_spec := within_delta _ _ _ _ 37 _ hb
    try simp only [hc,Bool.false_eq_true,true_iff,false_iff] at hb_spec
    try simp_scalar at hb_spec
    try have hb1_spec := within_delta _ _ _ _ 63 _ hb1
    try simp only [hc_1,Bool.false_eq_true,true_iff,false_iff] at hb1_spec
    try simp_scalar at hb1_spec
    try have hb2_spec := within_delta _ _ _ _ 32 _ hb2
    try simp only [hc_2,Bool.false_eq_true,true_iff,false_iff] at hb2_spec
    try simp_scalar at hb2_spec
    try have hb3_spec := within_delta _ _ _ _ 32 _ hb3
    try simp only [hc_3,Bool.false_eq_true,true_iff,false_iff] at hb3_spec
    try simp_scalar at hb3_spec
    try have hb4_spec := within_delta _ _ _ _ 1 _ hb4
    try simp only [hc_4,Bool.false_eq_true,true_iff,false_iff] at hb4_spec
    try simp_scalar at hb4_spec
    try have hb5_spec := within_delta _ _ _ _ (-130) _ hb5
    try simp only [hc_5,Bool.false_eq_true,true_iff,false_iff] at hb5_spec
    try simp_scalar at hb5_spec
    try have hb6_spec := within_delta _ _ _ _ 80 _ hb6
    try simp only [hc_6,Bool.false_eq_true,true_iff,false_iff] at hb6_spec
    try simp_scalar at hb6_spec
    try have hb7_spec := within_delta _ _ _ _ 32 _ hb7
    try simp only [hc_7,Bool.false_eq_true,true_iff,false_iff] at hb7_spec
    try simp_scalar at hb7_spec
    try have hb8_spec := within_delta _ _ _ _ 1 _ hb8
    try simp only [hc_8,Bool.false_eq_true,true_iff,false_iff] at hb8_spec
    try simp_scalar at hb8_spec
    try have hb9_spec := within_delta _ _ _ _ 1 _ hb9
    try simp only [hc_9,Bool.false_eq_true,true_iff,false_iff] at hb9_spec
    try simp_scalar at hb9_spec
    simp only [LowerRanges2,LookupLowerRanges,
      * , ↓reduceIte,Option.map_some,Option.map_none]
    all_goals first
    | (have hadd := add_ok_val hi; simp [LowerRangeValue]; scalar_tac)
    | (have hsub := sub_ok_val hi; simp [LowerRangeValue]; scalar_tac)
    | rfl
theorem range3_ok (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_3 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges3 := by
  unfold unicode.range_3 at h
  h5i_invert h
  all_goals
    try have hb_spec := within_delta _ _ _ _ 1 _ hb
    try simp only [hc,Bool.false_eq_true,true_iff,false_iff] at hb_spec
    try simp_scalar at hb_spec
    try have hb1_spec := within_delta _ _ _ _ 1 _ hb1
    try simp only [hc_1,Bool.false_eq_true,true_iff,false_iff] at hb1_spec
    try simp_scalar at hb1_spec
    try have hb2_spec := within_delta _ _ _ _ 48 _ hb2
    try simp only [hc_2,Bool.false_eq_true,true_iff,false_iff] at hb2_spec
    try simp_scalar at hb2_spec
    try have hb3_spec := within_delta _ _ _ _ 7264 _ hb3
    try simp only [hc_3,Bool.false_eq_true,true_iff,false_iff] at hb3_spec
    try simp_scalar at hb3_spec
    try have hb4_spec := within_delta _ _ _ _ 38864 _ hb4
    try simp only [hc_4,Bool.false_eq_true,true_iff,false_iff] at hb4_spec
    try simp_scalar at hb4_spec
    try have hb5_spec := within_delta _ _ _ _ 8 _ hb5
    try simp only [hc_5,Bool.false_eq_true,true_iff,false_iff] at hb5_spec
    try simp_scalar at hb5_spec
    try have hb6_spec := within_delta _ _ _ _ (-3008) _ hb6
    try simp only [hc_6,Bool.false_eq_true,true_iff,false_iff] at hb6_spec
    try simp_scalar at hb6_spec
    try have hb7_spec := within_delta _ _ _ _ (-3008) _ hb7
    try simp only [hc_7,Bool.false_eq_true,true_iff,false_iff] at hb7_spec
    try simp_scalar at hb7_spec
    try have hb8_spec := within_delta _ _ _ _ 1 _ hb8
    try simp only [hc_8,Bool.false_eq_true,true_iff,false_iff] at hb8_spec
    try simp_scalar at hb8_spec
    try have hb9_spec := within_delta _ _ _ _ 1 _ hb9
    try simp only [hc_9,Bool.false_eq_true,true_iff,false_iff] at hb9_spec
    try simp_scalar at hb9_spec
    simp only [LowerRanges3,LookupLowerRanges,
      * , ↓reduceIte,Option.map_some,Option.map_none]
    all_goals first
    | (have hadd := add_ok_val hi; simp [LowerRangeValue]; scalar_tac)
    | (have hsub := sub_ok_val hi; simp [LowerRangeValue]; scalar_tac)
    | rfl
theorem range4_ok (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_4 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges4 := by
  unfold unicode.range_4 at h
  h5i_invert h
  all_goals
    try have hb_spec := within_delta _ _ _ _ (-8) _ hb
    try simp only [hc,Bool.false_eq_true,true_iff,false_iff] at hb_spec
    try simp_scalar at hb_spec
    try have hb1_spec := within_delta _ _ _ _ (-8) _ hb1
    try simp only [hc_1,Bool.false_eq_true,true_iff,false_iff] at hb1_spec
    try simp_scalar at hb1_spec
    try have hb2_spec := within_delta _ _ _ _ (-8) _ hb2
    try simp only [hc_2,Bool.false_eq_true,true_iff,false_iff] at hb2_spec
    try simp_scalar at hb2_spec
    try have hb3_spec := within_delta _ _ _ _ (-8) _ hb3
    try simp only [hc_3,Bool.false_eq_true,true_iff,false_iff] at hb3_spec
    try simp_scalar at hb3_spec
    try have hb4_spec := within_delta _ _ _ _ (-8) _ hb4
    try simp only [hc_4,Bool.false_eq_true,true_iff,false_iff] at hb4_spec
    try simp_scalar at hb4_spec
    try have hb5_spec := within_delta _ _ _ _ (-8) _ hb5
    try simp only [hc_5,Bool.false_eq_true,true_iff,false_iff] at hb5_spec
    try simp_scalar at hb5_spec
    try have hb6_spec := within_delta _ _ _ _ (-8) _ hb6
    try simp only [hc_6,Bool.false_eq_true,true_iff,false_iff] at hb6_spec
    try simp_scalar at hb6_spec
    try have hb7_spec := within_delta _ _ _ _ (-8) _ hb7
    try simp only [hc_7,Bool.false_eq_true,true_iff,false_iff] at hb7_spec
    try simp_scalar at hb7_spec
    try have hb8_spec := within_delta _ _ _ _ (-8) _ hb8
    try simp only [hc_8,Bool.false_eq_true,true_iff,false_iff] at hb8_spec
    try simp_scalar at hb8_spec
    try have hb9_spec := within_delta _ _ _ _ (-8) _ hb9
    try simp only [hc_9,Bool.false_eq_true,true_iff,false_iff] at hb9_spec
    try simp_scalar at hb9_spec
    simp only [LowerRanges4,LookupLowerRanges,
      * , ↓reduceIte,Option.map_some,Option.map_none]
    all_goals first
    | (have hadd := add_ok_val hi; simp [LowerRangeValue]; scalar_tac)
    | (have hsub := sub_ok_val hi; simp [LowerRangeValue]; scalar_tac)
    | rfl
theorem range5_ok (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_5 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges5 := by
  unfold unicode.range_5 at h
  h5i_invert h
  all_goals
    try have hb_spec := within_delta _ _ _ _ (-8) _ hb
    try simp only [hc,Bool.false_eq_true,true_iff,false_iff] at hb_spec
    try simp_scalar at hb_spec
    try have hb1_spec := within_delta _ _ _ _ (-74) _ hb1
    try simp only [hc_1,Bool.false_eq_true,true_iff,false_iff] at hb1_spec
    try simp_scalar at hb1_spec
    try have hb2_spec := within_delta _ _ _ _ (-86) _ hb2
    try simp only [hc_2,Bool.false_eq_true,true_iff,false_iff] at hb2_spec
    try simp_scalar at hb2_spec
    try have hb3_spec := within_delta _ _ _ _ (-8) _ hb3
    try simp only [hc_3,Bool.false_eq_true,true_iff,false_iff] at hb3_spec
    try simp_scalar at hb3_spec
    try have hb4_spec := within_delta _ _ _ _ (-100) _ hb4
    try simp only [hc_4,Bool.false_eq_true,true_iff,false_iff] at hb4_spec
    try simp_scalar at hb4_spec
    try have hb5_spec := within_delta _ _ _ _ (-8) _ hb5
    try simp only [hc_5,Bool.false_eq_true,true_iff,false_iff] at hb5_spec
    try simp_scalar at hb5_spec
    try have hb6_spec := within_delta _ _ _ _ (-112) _ hb6
    try simp only [hc_6,Bool.false_eq_true,true_iff,false_iff] at hb6_spec
    try simp_scalar at hb6_spec
    try have hb7_spec := within_delta _ _ _ _ (-128) _ hb7
    try simp only [hc_7,Bool.false_eq_true,true_iff,false_iff] at hb7_spec
    try simp_scalar at hb7_spec
    try have hb8_spec := within_delta _ _ _ _ (-126) _ hb8
    try simp only [hc_8,Bool.false_eq_true,true_iff,false_iff] at hb8_spec
    try simp_scalar at hb8_spec
    try have hb9_spec := within_delta _ _ _ _ 16 _ hb9
    try simp only [hc_9,Bool.false_eq_true,true_iff,false_iff] at hb9_spec
    try simp_scalar at hb9_spec
    simp only [LowerRanges5,LookupLowerRanges,
      * , ↓reduceIte,Option.map_some,Option.map_none]
    all_goals first
    | (have hadd := add_ok_val hi; simp [LowerRangeValue]; scalar_tac)
    | (have hsub := sub_ok_val hi; simp [LowerRangeValue]; scalar_tac)
    | rfl
theorem range6_ok (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_6 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges6 := by
  unfold unicode.range_6 at h
  h5i_invert h
  all_goals
    try have hb_spec := within_delta _ _ _ _ 26 _ hb
    try simp only [hc,Bool.false_eq_true,true_iff,false_iff] at hb_spec
    try simp_scalar at hb_spec
    try have hb1_spec := within_delta _ _ _ _ 48 _ hb1
    try simp only [hc_1,Bool.false_eq_true,true_iff,false_iff] at hb1_spec
    try simp_scalar at hb1_spec
    try have hb2_spec := within_delta _ _ _ _ 1 _ hb2
    try simp only [hc_2,Bool.false_eq_true,true_iff,false_iff] at hb2_spec
    try simp_scalar at hb2_spec
    try have hb3_spec := within_delta _ _ _ _ (-10815) _ hb3
    try simp only [hc_3,Bool.false_eq_true,true_iff,false_iff] at hb3_spec
    try simp_scalar at hb3_spec
    try have hb4_spec := within_delta _ _ _ _ 1 _ hb4
    try simp only [hc_4,Bool.false_eq_true,true_iff,false_iff] at hb4_spec
    try simp_scalar at hb4_spec
    try have hb5_spec := within_delta _ _ _ _ 1 _ hb5
    try simp only [hc_5,Bool.false_eq_true,true_iff,false_iff] at hb5_spec
    try simp_scalar at hb5_spec
    try have hb6_spec := within_delta _ _ _ _ 1 _ hb6
    try simp only [hc_6,Bool.false_eq_true,true_iff,false_iff] at hb6_spec
    try simp_scalar at hb6_spec
    try have hb7_spec := within_delta _ _ _ _ 1 _ hb7
    try simp only [hc_7,Bool.false_eq_true,true_iff,false_iff] at hb7_spec
    try simp_scalar at hb7_spec
    try have hb8_spec := within_delta _ _ _ _ 1 _ hb8
    try simp only [hc_8,Bool.false_eq_true,true_iff,false_iff] at hb8_spec
    try simp_scalar at hb8_spec
    try have hb9_spec := within_delta _ _ _ _ 1 _ hb9
    try simp only [hc_9,Bool.false_eq_true,true_iff,false_iff] at hb9_spec
    try simp_scalar at hb9_spec
    simp only [LowerRanges6,LookupLowerRanges,
      * , ↓reduceIte,Option.map_some,Option.map_none]
    all_goals first
    | (have hadd := add_ok_val hi; simp [LowerRangeValue]; scalar_tac)
    | (have hsub := sub_ok_val hi; simp [LowerRangeValue]; scalar_tac)
    | rfl
theorem range7_ok (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_7 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges7 := by
  unfold unicode.range_7 at h
  h5i_invert h
  all_goals
    try have hb_spec := within_delta _ _ _ _ 1 _ hb
    try simp only [hc,Bool.false_eq_true,true_iff,false_iff] at hb_spec
    try simp_scalar at hb_spec
    try have hb1_spec := within_delta _ _ _ _ 1 _ hb1
    try simp only [hc_1,Bool.false_eq_true,true_iff,false_iff] at hb1_spec
    try simp_scalar at hb1_spec
    try have hb2_spec := within_delta _ _ _ _ 1 _ hb2
    try simp only [hc_2,Bool.false_eq_true,true_iff,false_iff] at hb2_spec
    try simp_scalar at hb2_spec
    try have hb3_spec := within_delta _ _ _ _ 1 _ hb3
    try simp only [hc_3,Bool.false_eq_true,true_iff,false_iff] at hb3_spec
    try simp_scalar at hb3_spec
    try have hb4_spec := within_delta _ _ _ _ 1 _ hb4
    try simp only [hc_4,Bool.false_eq_true,true_iff,false_iff] at hb4_spec
    try simp_scalar at hb4_spec
    try have hb5_spec := within_delta _ _ _ _ 1 _ hb5
    try simp only [hc_5,Bool.false_eq_true,true_iff,false_iff] at hb5_spec
    try simp_scalar at hb5_spec
    try have hb6_spec := within_delta _ _ _ _ 1 _ hb6
    try simp only [hc_6,Bool.false_eq_true,true_iff,false_iff] at hb6_spec
    try simp_scalar at hb6_spec
    try have hb7_spec := within_delta _ _ _ _ 32 _ hb7
    try simp only [hc_7,Bool.false_eq_true,true_iff,false_iff] at hb7_spec
    try simp_scalar at hb7_spec
    try have hb8_spec := within_delta _ _ _ _ 40 _ hb8
    try simp only [hc_8,Bool.false_eq_true,true_iff,false_iff] at hb8_spec
    try simp_scalar at hb8_spec
    try have hb9_spec := within_delta _ _ _ _ 40 _ hb9
    try simp only [hc_9,Bool.false_eq_true,true_iff,false_iff] at hb9_spec
    try simp_scalar at hb9_spec
    simp only [LowerRanges7,LookupLowerRanges,
      * , ↓reduceIte,Option.map_some,Option.map_none]
    all_goals first
    | (have hadd := add_ok_val hi; simp [LowerRangeValue]; scalar_tac)
    | (have hsub := sub_ok_val hi; simp [LowerRangeValue]; scalar_tac)
    | rfl
theorem range8_ok (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_8 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges8 := by
  unfold unicode.range_8 at h
  h5i_invert h
  all_goals
    try have hb_spec := within_delta _ _ _ _ 39 _ hb
    try simp only [hc,Bool.false_eq_true,true_iff,false_iff] at hb_spec
    try simp_scalar at hb_spec
    try have hb1_spec := within_delta _ _ _ _ 39 _ hb1
    try simp only [hc_1,Bool.false_eq_true,true_iff,false_iff] at hb1_spec
    try simp_scalar at hb1_spec
    try have hb2_spec := within_delta _ _ _ _ 39 _ hb2
    try simp only [hc_2,Bool.false_eq_true,true_iff,false_iff] at hb2_spec
    try simp_scalar at hb2_spec
    try have hb3_spec := within_delta _ _ _ _ 39 _ hb3
    try simp only [hc_3,Bool.false_eq_true,true_iff,false_iff] at hb3_spec
    try simp_scalar at hb3_spec
    try have hb4_spec := within_delta _ _ _ _ 64 _ hb4
    try simp only [hc_4,Bool.false_eq_true,true_iff,false_iff] at hb4_spec
    try simp_scalar at hb4_spec
    try have hb5_spec := within_delta _ _ _ _ 32 _ hb5
    try simp only [hc_5,Bool.false_eq_true,true_iff,false_iff] at hb5_spec
    try simp_scalar at hb5_spec
    try have hb6_spec := within_delta _ _ _ _ 32 _ hb6
    try simp only [hc_6,Bool.false_eq_true,true_iff,false_iff] at hb6_spec
    try simp_scalar at hb6_spec
    try have hb7_spec := within_delta _ _ _ _ 32 _ hb7
    try simp only [hc_7,Bool.false_eq_true,true_iff,false_iff] at hb7_spec
    try simp_scalar at hb7_spec
    try have hb8_spec := within_delta _ _ _ _ 27 _ hb8
    try simp only [hc_8,Bool.false_eq_true,true_iff,false_iff] at hb8_spec
    try simp_scalar at hb8_spec
    try have hb9_spec := within_delta _ _ _ _ 34 _ hb9
    try simp only [hc_9,Bool.false_eq_true,true_iff,false_iff] at hb9_spec
    try simp_scalar at hb9_spec
    simp only [LowerRanges8,LookupLowerRanges,
      * , ↓reduceIte,Option.map_some,Option.map_none]
    all_goals first
    | (have hadd := add_ok_val hi; simp [LowerRangeValue]; scalar_tac)
    | (have hsub := sub_ok_val hi; simp [LowerRangeValue]; scalar_tac)
    | rfl
end rustfs_kernel.Verified.RustfsUnicodeTables
