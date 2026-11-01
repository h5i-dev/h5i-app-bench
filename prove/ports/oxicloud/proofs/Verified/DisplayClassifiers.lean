import OxicloudKernel
import H5iAppLib
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.DisplayClassifiers
set_option maxRecDepth 16384
set_option maxHeartbeats 2000000

def window (hay needle : List U8) (pos : Nat) : Bool :=
  decide (pos ≤ hay.length ∧ needle.length ≤ hay.length - pos ∧ (hay.drop pos).take needle.length = needle)

@[step] theorem starts_at_complete (hay needle : Slice U8) (pos : Usize) :
    display_classifiers.starts_at hay needle pos ⦃r => r = window hay.val needle.val pos.val⦄ := by
  unfold display_classifiers.starts_at
  h5i_steps
  all_goals simp_all [window, Slice.eq_iff, List.slice]

@[step] theorem prefix_complete (hay needle : Slice U8) :
    display_classifiers.prefix hay needle ⦃r => r = window hay.val needle.val 0⦄ := by
  unfold display_classifiers.prefix
  h5i_steps

def within (hay needle : List U8) (last : Nat) : Bool :=
  (List.range (last + 1)).any (window hay needle)

@[step] theorem contains_loop_complete (hay needle : Slice U8) (last i : Usize)
    (_hl : last.val ≤ hay.val.length) (hi : i.val ≤ last.val)
    (hp : ∀ j < i.val, window hay.val needle.val j = false) :
    display_classifiers.contains_loop hay needle last i ⦃r => r = within hay.val needle.val last.val⦄ := by
  unfold display_classifiers.contains_loop
  apply loop_idx_spec _ id last.val
    (fun i => ∀ j < i.val, window hay.val needle.val j = false)
    (fun r => r = within hay.val needle.val last.val) ?_ i hp hi
  intro x hx hbound
  unfold display_classifiers.contains_loop.body
  h5i_steps
  all_goals simp_all [within, List.any_eq_true, List.any_eq_false]
  · exact ⟨x.val, hbound, b_post⟩
  · intro j hj
    by_cases he : j = last.val
    · simpa [he] using b_post
    · exact hx j (by omega)
  · scalar_tac
  · constructor
    · intro j hj
      by_cases he : j = x.val
      · simpa [he] using b_post
      · exact hx j (by omega)
    · omega

def contains_model (hay needle : List U8) : Bool :=
  if needle.length > hay.length then false else within hay needle (hay.length - needle.length)

@[step] theorem contains_complete (hay needle : Slice U8) :
    display_classifiers.contains hay needle ⦃r => r = contains_model hay.val needle.val⦄ := by
  unfold display_classifiers.contains
  h5i_steps
  all_goals simp_all [contains_model]
-- Generated ordered decision specifications.
def icon_class_with_ext_exact_0_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 112#u8, 100#u8, 102#u8]) then some .V41 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 109#u8, 115#u8, 119#u8, 111#u8, 114#u8, 100#u8]) then some .V44 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 120#u8, 109#u8, 108#u8, 102#u8, 111#u8, 114#u8, 109#u8, 97#u8, 116#u8, 115#u8, 45#u8, 111#u8, 102#u8, 102#u8, 105#u8, 99#u8, 101#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 119#u8, 111#u8, 114#u8, 100#u8, 112#u8, 114#u8, 111#u8, 99#u8, 101#u8, 115#u8, 115#u8, 105#u8, 110#u8, 103#u8, 109#u8, 108#u8, 46#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8]) then some .V44 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 97#u8, 115#u8, 105#u8, 115#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 116#u8, 101#u8, 120#u8, 116#u8]) then some .V44 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 109#u8, 115#u8, 45#u8, 101#u8, 120#u8, 99#u8, 101#u8, 108#u8]) then some .V39 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 120#u8, 109#u8, 108#u8, 102#u8, 111#u8, 114#u8, 109#u8, 97#u8, 116#u8, 115#u8, 45#u8, 111#u8, 102#u8, 102#u8, 105#u8, 99#u8, 101#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 115#u8, 112#u8, 114#u8, 101#u8, 97#u8, 100#u8, 115#u8, 104#u8, 101#u8, 101#u8, 116#u8, 109#u8, 108#u8, 46#u8, 115#u8, 104#u8, 101#u8, 101#u8, 116#u8]) then some .V39 else (none))))))
@[step] theorem icon_class_with_ext_exact_0_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_exact_0 raw ⦃r => r = icon_class_with_ext_exact_0_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_exact_0
  h5i_steps
  all_goals simp_all [icon_class_with_ext_exact_0_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_exact_1_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 97#u8, 115#u8, 105#u8, 115#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 115#u8, 112#u8, 114#u8, 101#u8, 97#u8, 100#u8, 115#u8, 104#u8, 101#u8, 101#u8, 116#u8]) then some .V39 else (if decide (raw = [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 99#u8, 115#u8, 118#u8]) then some .V39 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 109#u8, 115#u8, 45#u8, 112#u8, 111#u8, 119#u8, 101#u8, 114#u8, 112#u8, 111#u8, 105#u8, 110#u8, 116#u8]) then some .V42 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 120#u8, 109#u8, 108#u8, 102#u8, 111#u8, 114#u8, 109#u8, 97#u8, 116#u8, 115#u8, 45#u8, 111#u8, 102#u8, 102#u8, 105#u8, 99#u8, 101#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 112#u8, 114#u8, 101#u8, 115#u8, 101#u8, 110#u8, 116#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 109#u8, 108#u8, 46#u8, 112#u8, 114#u8, 101#u8, 115#u8, 101#u8, 110#u8, 116#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8]) then some .V42 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 97#u8, 115#u8, 105#u8, 115#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 112#u8, 114#u8, 101#u8, 115#u8, 101#u8, 110#u8, 116#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8]) then some .V42 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 122#u8, 105#u8, 112#u8]) then some .V36 else (none))))))
@[step] theorem icon_class_with_ext_exact_1_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_exact_1 raw ⦃r => r = icon_class_with_ext_exact_1_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_exact_1
  h5i_steps
  all_goals simp_all [icon_class_with_ext_exact_1_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_exact_2_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 114#u8, 97#u8, 114#u8, 45#u8, 99#u8, 111#u8, 109#u8, 112#u8, 114#u8, 101#u8, 115#u8, 115#u8, 101#u8, 100#u8]) then some .V36 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 114#u8, 97#u8, 114#u8]) then some .V36 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 55#u8, 122#u8, 45#u8, 99#u8, 111#u8, 109#u8, 112#u8, 114#u8, 101#u8, 115#u8, 115#u8, 101#u8, 100#u8]) then some .V36 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 103#u8, 122#u8, 105#u8, 112#u8]) then some .V36 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 103#u8, 122#u8, 105#u8, 112#u8]) then some .V36 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 116#u8, 97#u8, 114#u8]) then some .V36 else (none))))))
@[step] theorem icon_class_with_ext_exact_2_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_exact_2 raw ⦃r => r = icon_class_with_ext_exact_2_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_exact_2
  h5i_steps
  all_goals simp_all [icon_class_with_ext_exact_2_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_exact_3_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 98#u8, 122#u8, 105#u8, 112#u8, 50#u8]) then some .V36 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 120#u8, 122#u8]) then some .V36 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 99#u8, 111#u8, 109#u8, 112#u8, 114#u8, 101#u8, 115#u8, 115#u8]) then some .V36 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 106#u8, 115#u8, 111#u8, 110#u8]) then some .V38 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 108#u8, 100#u8, 43#u8, 106#u8, 115#u8, 111#u8, 110#u8]) then some .V38 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 106#u8, 97#u8, 118#u8, 97#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8]) then some .V38 else (none))))))
@[step] theorem icon_class_with_ext_exact_3_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_exact_3 raw ⦃r => r = icon_class_with_ext_exact_3_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_exact_3
  h5i_steps
  all_goals simp_all [icon_class_with_ext_exact_3_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_exact_4_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 116#u8, 121#u8, 112#u8, 101#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8]) then some .V38 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 104#u8, 116#u8, 116#u8, 112#u8, 100#u8, 45#u8, 112#u8, 104#u8, 112#u8]) then some .V38 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 109#u8, 108#u8]) then some .V38 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 104#u8, 116#u8, 109#u8, 108#u8, 43#u8, 120#u8, 109#u8, 108#u8]) then some .V38 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 115#u8, 113#u8, 108#u8]) then some .V38 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 121#u8, 97#u8, 109#u8, 108#u8]) then some .V38 else (none))))))
@[step] theorem icon_class_with_ext_exact_4_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_exact_4 raw ⦃r => r = icon_class_with_ext_exact_4_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_exact_4
  h5i_steps
  all_goals simp_all [icon_class_with_ext_exact_4_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_exact_5_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 116#u8, 111#u8, 109#u8, 108#u8]) then some .V38 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 115#u8, 104#u8]) then some .V38 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 115#u8, 104#u8, 101#u8, 108#u8, 108#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8]) then some .V38 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 99#u8, 115#u8, 104#u8]) then some .V38 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 97#u8, 112#u8, 112#u8, 108#u8, 101#u8, 45#u8, 100#u8, 105#u8, 115#u8, 107#u8, 105#u8, 109#u8, 97#u8, 103#u8, 101#u8]) then some .V45 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 109#u8, 115#u8, 45#u8, 100#u8, 111#u8, 115#u8, 45#u8, 101#u8, 120#u8, 101#u8, 99#u8, 117#u8, 116#u8, 97#u8, 98#u8, 108#u8, 101#u8]) then some .V45 else (none))))))
@[step] theorem icon_class_with_ext_exact_5_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_exact_5 raw ⦃r => r = icon_class_with_ext_exact_5_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_exact_5
  h5i_steps
  all_goals simp_all [icon_class_with_ext_exact_5_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_exact_6_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 109#u8, 115#u8, 100#u8, 111#u8, 119#u8, 110#u8, 108#u8, 111#u8, 97#u8, 100#u8]) then some .V45 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 109#u8, 115#u8, 105#u8]) then some .V45 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 100#u8, 101#u8, 98#u8, 105#u8, 97#u8, 110#u8, 46#u8, 98#u8, 105#u8, 110#u8, 97#u8, 114#u8, 121#u8, 45#u8, 112#u8, 97#u8, 99#u8, 107#u8, 97#u8, 103#u8, 101#u8]) then some .V45 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 114#u8, 112#u8, 109#u8]) then some .V45 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 97#u8, 112#u8, 112#u8, 105#u8, 109#u8, 97#u8, 103#u8, 101#u8]) then some .V45 else (none)))))
@[step] theorem icon_class_with_ext_exact_6_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_exact_6 raw ⦃r => r = icon_class_with_ext_exact_6_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_exact_6
  h5i_steps
  all_goals simp_all [icon_class_with_ext_exact_6_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_mime_0_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if window raw [105#u8, 109#u8, 97#u8, 103#u8, 101#u8, 47#u8] 0 then some .V40 else (if window raw [118#u8, 105#u8, 100#u8, 101#u8, 111#u8, 47#u8] 0 then some .V43 else (if window raw [97#u8, 117#u8, 100#u8, 105#u8, 111#u8, 47#u8] 0 then some .V37 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8] 0 then some .V38 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 112#u8, 121#u8, 116#u8, 104#u8, 111#u8, 110#u8] 0 then some .V38 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 106#u8, 97#u8, 118#u8, 97#u8] 0 then some .V38 else (none))))))
@[step] theorem icon_class_with_ext_mime_0_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_mime_0 raw ⦃r => r = icon_class_with_ext_mime_0_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_mime_0
  h5i_steps
  all_goals simp_all [icon_class_with_ext_mime_0_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_mime_1_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 99#u8] 0 then some .V38 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 114#u8, 117#u8, 115#u8, 116#u8] 0 then some .V38 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 103#u8, 111#u8] 0 then some .V38 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 114#u8, 117#u8, 98#u8, 121#u8] 0 then some .V38 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 115#u8, 104#u8, 101#u8, 108#u8, 108#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8] 0 then some .V38 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 112#u8, 104#u8, 112#u8] 0 then some .V38 else (none))))))
@[step] theorem icon_class_with_ext_mime_1_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_mime_1 raw ⦃r => r = icon_class_with_ext_mime_1_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_mime_1
  h5i_steps
  all_goals simp_all [icon_class_with_ext_mime_1_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_mime_2_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if contains_model raw [106#u8, 97#u8, 118#u8, 97#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8] then some .V38 else (if contains_model raw [116#u8, 121#u8, 112#u8, 101#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8] then some .V38 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8] 0 then some .V35 else (none)))
@[step] theorem icon_class_with_ext_mime_2_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_mime_2 raw ⦃r => r = icon_class_with_ext_mime_2_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_mime_2
  h5i_steps
  all_goals simp_all [icon_class_with_ext_mime_2_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_0_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [112#u8, 100#u8, 102#u8]) then some .V41 else (if decide (raw = [100#u8, 111#u8, 99#u8]) then some .V44 else (if decide (raw = [100#u8, 111#u8, 99#u8, 120#u8]) then some .V44 else (if decide (raw = [111#u8, 100#u8, 116#u8]) then some .V44 else (if decide (raw = [114#u8, 116#u8, 102#u8]) then some .V44 else (if decide (raw = [120#u8, 108#u8, 115#u8]) then some .V39 else (none))))))
@[step] theorem icon_class_with_ext_ext_0_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_0 raw ⦃r => r = icon_class_with_ext_ext_0_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_0
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_0_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_1_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [120#u8, 108#u8, 115#u8, 120#u8]) then some .V39 else (if decide (raw = [111#u8, 100#u8, 115#u8]) then some .V39 else (if decide (raw = [99#u8, 115#u8, 118#u8]) then some .V39 else (if decide (raw = [112#u8, 112#u8, 116#u8]) then some .V42 else (if decide (raw = [112#u8, 112#u8, 116#u8, 120#u8]) then some .V42 else (if decide (raw = [111#u8, 100#u8, 112#u8]) then some .V42 else (none))))))
@[step] theorem icon_class_with_ext_ext_1_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_1 raw ⦃r => r = icon_class_with_ext_ext_1_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_1
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_1_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_2_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [107#u8, 101#u8, 121#u8]) then some .V42 else (if decide (raw = [106#u8, 112#u8, 103#u8]) then some .V40 else (if decide (raw = [106#u8, 112#u8, 101#u8, 103#u8]) then some .V40 else (if decide (raw = [112#u8, 110#u8, 103#u8]) then some .V40 else (if decide (raw = [103#u8, 105#u8, 102#u8]) then some .V40 else (if decide (raw = [98#u8, 109#u8, 112#u8]) then some .V40 else (none))))))
@[step] theorem icon_class_with_ext_ext_2_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_2 raw ⦃r => r = icon_class_with_ext_ext_2_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_2
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_2_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_3_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [115#u8, 118#u8, 103#u8]) then some .V40 else (if decide (raw = [119#u8, 101#u8, 98#u8, 112#u8]) then some .V40 else (if decide (raw = [105#u8, 99#u8, 111#u8]) then some .V40 else (if decide (raw = [116#u8, 105#u8, 102#u8, 102#u8]) then some .V40 else (if decide (raw = [116#u8, 105#u8, 102#u8]) then some .V40 else (if decide (raw = [104#u8, 101#u8, 105#u8, 99#u8]) then some .V40 else (none))))))
@[step] theorem icon_class_with_ext_ext_3_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_3 raw ⦃r => r = icon_class_with_ext_ext_3_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_3
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_3_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_4_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [104#u8, 101#u8, 105#u8, 102#u8]) then some .V40 else (if decide (raw = [97#u8, 118#u8, 105#u8, 102#u8]) then some .V40 else (if decide (raw = [109#u8, 112#u8, 52#u8]) then some .V43 else (if decide (raw = [97#u8, 118#u8, 105#u8]) then some .V43 else (if decide (raw = [109#u8, 107#u8, 118#u8]) then some .V43 else (if decide (raw = [109#u8, 111#u8, 118#u8]) then some .V43 else (none))))))
@[step] theorem icon_class_with_ext_ext_4_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_4 raw ⦃r => r = icon_class_with_ext_ext_4_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_4
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_4_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_5_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [119#u8, 109#u8, 118#u8]) then some .V43 else (if decide (raw = [102#u8, 108#u8, 118#u8]) then some .V43 else (if decide (raw = [119#u8, 101#u8, 98#u8, 109#u8]) then some .V43 else (if decide (raw = [109#u8, 52#u8, 118#u8]) then some .V43 else (if decide (raw = [109#u8, 112#u8, 51#u8]) then some .V37 else (if decide (raw = [119#u8, 97#u8, 118#u8]) then some .V37 else (none))))))
@[step] theorem icon_class_with_ext_ext_5_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_5 raw ⦃r => r = icon_class_with_ext_ext_5_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_5
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_5_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_6_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [111#u8, 103#u8, 103#u8]) then some .V37 else (if decide (raw = [102#u8, 108#u8, 97#u8, 99#u8]) then some .V37 else (if decide (raw = [97#u8, 97#u8, 99#u8]) then some .V37 else (if decide (raw = [119#u8, 109#u8, 97#u8]) then some .V37 else (if decide (raw = [109#u8, 52#u8, 97#u8]) then some .V37 else (if decide (raw = [111#u8, 112#u8, 117#u8, 115#u8]) then some .V37 else (none))))))
@[step] theorem icon_class_with_ext_ext_6_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_6 raw ⦃r => r = icon_class_with_ext_ext_6_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_6
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_6_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_7_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [122#u8, 105#u8, 112#u8]) then some .V36 else (if decide (raw = [114#u8, 97#u8, 114#u8]) then some .V36 else (if decide (raw = [55#u8, 122#u8]) then some .V36 else (if decide (raw = [116#u8, 97#u8, 114#u8]) then some .V36 else (if decide (raw = [103#u8, 122#u8]) then some .V36 else (if decide (raw = [98#u8, 122#u8, 50#u8]) then some .V36 else (none))))))
@[step] theorem icon_class_with_ext_ext_7_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_7 raw ⦃r => r = icon_class_with_ext_ext_7_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_7
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_7_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_8_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [120#u8, 122#u8]) then some .V36 else (if decide (raw = [122#u8, 115#u8, 116#u8]) then some .V36 else (if decide (raw = [108#u8, 122#u8, 52#u8]) then some .V36 else (if decide (raw = [101#u8, 120#u8, 101#u8]) then some .V45 else (if decide (raw = [109#u8, 115#u8, 105#u8]) then some .V45 else (if decide (raw = [100#u8, 109#u8, 103#u8]) then some .V45 else (none))))))
@[step] theorem icon_class_with_ext_ext_8_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_8 raw ⦃r => r = icon_class_with_ext_ext_8_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_8
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_8_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_9_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [100#u8, 101#u8, 98#u8]) then some .V45 else (if decide (raw = [114#u8, 112#u8, 109#u8]) then some .V45 else (if decide (raw = [97#u8, 112#u8, 112#u8, 105#u8, 109#u8, 97#u8, 103#u8, 101#u8]) then some .V45 else (if decide (raw = [112#u8, 107#u8, 103#u8]) then some .V45 else (if decide (raw = [115#u8, 110#u8, 97#u8, 112#u8]) then some .V45 else (if decide (raw = [102#u8, 108#u8, 97#u8, 116#u8, 112#u8, 97#u8, 107#u8]) then some .V45 else (none))))))
@[step] theorem icon_class_with_ext_ext_9_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_9 raw ⦃r => r = icon_class_with_ext_ext_9_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_9
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_9_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_10_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [106#u8, 115#u8]) then some .V38 else (if decide (raw = [106#u8, 115#u8, 120#u8]) then some .V38 else (if decide (raw = [109#u8, 106#u8, 115#u8]) then some .V38 else (if decide (raw = [99#u8, 106#u8, 115#u8]) then some .V38 else (if decide (raw = [116#u8, 115#u8]) then some .V38 else (if decide (raw = [116#u8, 115#u8, 120#u8]) then some .V38 else (none))))))
@[step] theorem icon_class_with_ext_ext_10_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_10 raw ⦃r => r = icon_class_with_ext_ext_10_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_10
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_10_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_11_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [112#u8, 121#u8]) then some .V38 else (if decide (raw = [112#u8, 121#u8, 119#u8]) then some .V38 else (if decide (raw = [114#u8, 115#u8]) then some .V38 else (if decide (raw = [103#u8, 111#u8]) then some .V38 else (if decide (raw = [106#u8, 97#u8, 118#u8, 97#u8]) then some .V38 else (if decide (raw = [107#u8, 116#u8]) then some .V38 else (none))))))
@[step] theorem icon_class_with_ext_ext_11_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_11 raw ⦃r => r = icon_class_with_ext_ext_11_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_11
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_11_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_12_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [107#u8, 116#u8, 115#u8]) then some .V38 else (if decide (raw = [115#u8, 99#u8, 97#u8, 108#u8, 97#u8]) then some .V38 else (if decide (raw = [99#u8]) then some .V38 else (if decide (raw = [104#u8]) then some .V38 else (if decide (raw = [99#u8, 112#u8, 112#u8]) then some .V38 else (if decide (raw = [104#u8, 112#u8, 112#u8]) then some .V38 else (none))))))
@[step] theorem icon_class_with_ext_ext_12_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_12 raw ⦃r => r = icon_class_with_ext_ext_12_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_12
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_12_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_13_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [99#u8, 99#u8]) then some .V38 else (if decide (raw = [99#u8, 120#u8, 120#u8]) then some .V38 else (if decide (raw = [99#u8, 115#u8]) then some .V38 else (if decide (raw = [114#u8, 98#u8]) then some .V38 else (if decide (raw = [112#u8, 104#u8, 112#u8]) then some .V38 else (if decide (raw = [115#u8, 119#u8, 105#u8, 102#u8, 116#u8]) then some .V38 else (none))))))
@[step] theorem icon_class_with_ext_ext_13_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_13 raw ⦃r => r = icon_class_with_ext_ext_13_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_13
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_13_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_14_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [114#u8]) then some .V38 else (if decide (raw = [108#u8, 117#u8, 97#u8]) then some .V38 else (if decide (raw = [112#u8, 108#u8]) then some .V38 else (if decide (raw = [112#u8, 109#u8]) then some .V38 else (if decide (raw = [104#u8, 116#u8, 109#u8, 108#u8]) then some .V38 else (if decide (raw = [104#u8, 116#u8, 109#u8]) then some .V38 else (none))))))
@[step] theorem icon_class_with_ext_ext_14_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_14 raw ⦃r => r = icon_class_with_ext_ext_14_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_14
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_14_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_15_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [99#u8, 115#u8, 115#u8]) then some .V38 else (if decide (raw = [115#u8, 99#u8, 115#u8, 115#u8]) then some .V38 else (if decide (raw = [115#u8, 97#u8, 115#u8, 115#u8]) then some .V38 else (if decide (raw = [108#u8, 101#u8, 115#u8, 115#u8]) then some .V38 else (if decide (raw = [106#u8, 115#u8, 111#u8, 110#u8]) then some .V38 else (if decide (raw = [120#u8, 109#u8, 108#u8]) then some .V38 else (none))))))
@[step] theorem icon_class_with_ext_ext_15_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_15 raw ⦃r => r = icon_class_with_ext_ext_15_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_15
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_15_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_16_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [121#u8, 97#u8, 109#u8, 108#u8]) then some .V38 else (if decide (raw = [121#u8, 109#u8, 108#u8]) then some .V38 else (if decide (raw = [116#u8, 111#u8, 109#u8, 108#u8]) then some .V38 else (if decide (raw = [105#u8, 110#u8, 105#u8]) then some .V38 else (if decide (raw = [99#u8, 102#u8, 103#u8]) then some .V38 else (if decide (raw = [99#u8, 111#u8, 110#u8, 102#u8]) then some .V38 else (none))))))
@[step] theorem icon_class_with_ext_ext_16_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_16 raw ⦃r => r = icon_class_with_ext_ext_16_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_16
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_16_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_17_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [115#u8, 113#u8, 108#u8]) then some .V38 else (if decide (raw = [103#u8, 114#u8, 97#u8, 112#u8, 104#u8, 113#u8, 108#u8]) then some .V38 else (if decide (raw = [112#u8, 114#u8, 111#u8, 116#u8, 111#u8]) then some .V38 else (if decide (raw = [118#u8, 117#u8, 101#u8]) then some .V38 else (if decide (raw = [115#u8, 118#u8, 101#u8, 108#u8, 116#u8, 101#u8]) then some .V38 else (if decide (raw = [115#u8, 104#u8]) then some .V46 else (none))))))
@[step] theorem icon_class_with_ext_ext_17_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_17 raw ⦃r => r = icon_class_with_ext_ext_17_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_17
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_17_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_18_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [98#u8, 97#u8, 115#u8, 104#u8]) then some .V46 else (if decide (raw = [122#u8, 115#u8, 104#u8]) then some .V46 else (if decide (raw = [102#u8, 105#u8, 115#u8, 104#u8]) then some .V46 else (if decide (raw = [112#u8, 115#u8, 49#u8]) then some .V46 else (if decide (raw = [98#u8, 97#u8, 116#u8]) then some .V46 else (if decide (raw = [99#u8, 109#u8, 100#u8]) then some .V46 else (none))))))
@[step] theorem icon_class_with_ext_ext_18_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_18 raw ⦃r => r = icon_class_with_ext_ext_18_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_18
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_18_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_ext_19_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [109#u8, 100#u8]) then some .V35 else (if decide (raw = [109#u8, 97#u8, 114#u8, 107#u8, 100#u8, 111#u8, 119#u8, 110#u8]) then some .V35 else (if decide (raw = [114#u8, 115#u8, 116#u8]) then some .V35 else (if decide (raw = [116#u8, 120#u8, 116#u8]) then some .V35 else (none))))
@[step] theorem icon_class_with_ext_ext_19_complete (raw : Slice U8) :
    display_classifiers.icon_class_with_ext_ext_19 raw ⦃r => r = icon_class_with_ext_ext_19_model raw.val⦄ := by
  unfold display_classifiers.icon_class_with_ext_ext_19
  h5i_steps
  all_goals simp_all [icon_class_with_ext_ext_19_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_exact_0_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 112#u8, 100#u8, 102#u8]) then some .V49 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 109#u8, 115#u8, 119#u8, 111#u8, 114#u8, 100#u8]) then some .V33 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 120#u8, 109#u8, 108#u8, 102#u8, 111#u8, 114#u8, 109#u8, 97#u8, 116#u8, 115#u8, 45#u8, 111#u8, 102#u8, 102#u8, 105#u8, 99#u8, 101#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 119#u8, 111#u8, 114#u8, 100#u8, 112#u8, 114#u8, 111#u8, 99#u8, 101#u8, 115#u8, 115#u8, 105#u8, 110#u8, 103#u8, 109#u8, 108#u8, 46#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8]) then some .V33 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 97#u8, 115#u8, 105#u8, 115#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 116#u8, 101#u8, 120#u8, 116#u8]) then some .V33 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 109#u8, 115#u8, 45#u8, 101#u8, 120#u8, 99#u8, 101#u8, 108#u8]) then some .V52 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 120#u8, 109#u8, 108#u8, 102#u8, 111#u8, 114#u8, 109#u8, 97#u8, 116#u8, 115#u8, 45#u8, 111#u8, 102#u8, 102#u8, 105#u8, 99#u8, 101#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 115#u8, 112#u8, 114#u8, 101#u8, 97#u8, 100#u8, 115#u8, 104#u8, 101#u8, 101#u8, 116#u8, 109#u8, 108#u8, 46#u8, 115#u8, 104#u8, 101#u8, 101#u8, 116#u8]) then some .V52 else (none))))))
@[step] theorem icon_special_class_with_ext_exact_0_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_exact_0 raw ⦃r => r = icon_special_class_with_ext_exact_0_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_exact_0
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_exact_0_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_exact_1_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 97#u8, 115#u8, 105#u8, 115#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 115#u8, 112#u8, 114#u8, 101#u8, 97#u8, 100#u8, 115#u8, 104#u8, 101#u8, 101#u8, 116#u8]) then some .V52 else (if decide (raw = [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 99#u8, 115#u8, 118#u8]) then some .V52 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 109#u8, 115#u8, 45#u8, 112#u8, 111#u8, 119#u8, 101#u8, 114#u8, 112#u8, 111#u8, 105#u8, 110#u8, 116#u8]) then some .V50 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 120#u8, 109#u8, 108#u8, 102#u8, 111#u8, 114#u8, 109#u8, 97#u8, 116#u8, 115#u8, 45#u8, 111#u8, 102#u8, 102#u8, 105#u8, 99#u8, 101#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 112#u8, 114#u8, 101#u8, 115#u8, 101#u8, 110#u8, 116#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 109#u8, 108#u8, 46#u8, 112#u8, 114#u8, 101#u8, 115#u8, 101#u8, 110#u8, 116#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8]) then some .V50 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 97#u8, 115#u8, 105#u8, 115#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 112#u8, 114#u8, 101#u8, 115#u8, 101#u8, 110#u8, 116#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8]) then some .V50 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 122#u8, 105#u8, 112#u8]) then some .V13 else (none))))))
@[step] theorem icon_special_class_with_ext_exact_1_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_exact_1 raw ⦃r => r = icon_special_class_with_ext_exact_1_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_exact_1
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_exact_1_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_exact_2_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 114#u8, 97#u8, 114#u8, 45#u8, 99#u8, 111#u8, 109#u8, 112#u8, 114#u8, 101#u8, 115#u8, 115#u8, 101#u8, 100#u8]) then some .V13 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 114#u8, 97#u8, 114#u8]) then some .V13 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 55#u8, 122#u8, 45#u8, 99#u8, 111#u8, 109#u8, 112#u8, 114#u8, 101#u8, 115#u8, 115#u8, 101#u8, 100#u8]) then some .V13 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 103#u8, 122#u8, 105#u8, 112#u8]) then some .V13 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 103#u8, 122#u8, 105#u8, 112#u8]) then some .V13 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 116#u8, 97#u8, 114#u8]) then some .V13 else (none))))))
@[step] theorem icon_special_class_with_ext_exact_2_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_exact_2 raw ⦃r => r = icon_special_class_with_ext_exact_2_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_exact_2
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_exact_2_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_exact_3_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 98#u8, 122#u8, 105#u8, 112#u8, 50#u8]) then some .V13 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 120#u8, 122#u8]) then some .V13 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 99#u8, 111#u8, 109#u8, 112#u8, 114#u8, 101#u8, 115#u8, 115#u8]) then some .V13 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 106#u8, 115#u8, 111#u8, 110#u8]) then some .V24 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 108#u8, 100#u8, 43#u8, 106#u8, 115#u8, 111#u8, 110#u8]) then some .V24 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 106#u8, 97#u8, 118#u8, 97#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8]) then some .V23 else (none))))))
@[step] theorem icon_special_class_with_ext_exact_3_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_exact_3 raw ⦃r => r = icon_special_class_with_ext_exact_3_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_exact_3
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_exact_3_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_exact_4_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 116#u8, 121#u8, 112#u8, 101#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8]) then some .V32 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 109#u8, 108#u8]) then some .V21 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 104#u8, 116#u8, 109#u8, 108#u8, 43#u8, 120#u8, 109#u8, 108#u8]) then some .V21 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 115#u8, 113#u8, 108#u8]) then some .V30 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 121#u8, 97#u8, 109#u8, 108#u8]) then some .V17 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 116#u8, 111#u8, 109#u8, 108#u8]) then some .V17 else (none))))))
@[step] theorem icon_special_class_with_ext_exact_4_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_exact_4 raw ⦃r => r = icon_special_class_with_ext_exact_4_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_exact_4
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_exact_4_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_exact_5_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 104#u8, 116#u8, 116#u8, 112#u8, 100#u8, 45#u8, 112#u8, 104#u8, 112#u8]) then some .V26 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 115#u8, 104#u8]) then some .V51 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 115#u8, 104#u8, 101#u8, 108#u8, 108#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8]) then some .V51 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 99#u8, 115#u8, 104#u8]) then some .V51 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 97#u8, 112#u8, 112#u8, 108#u8, 101#u8, 45#u8, 100#u8, 105#u8, 115#u8, 107#u8, 105#u8, 109#u8, 97#u8, 103#u8, 101#u8]) then some .V48 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 109#u8, 115#u8, 45#u8, 100#u8, 111#u8, 115#u8, 45#u8, 101#u8, 120#u8, 101#u8, 99#u8, 117#u8, 116#u8, 97#u8, 98#u8, 108#u8, 101#u8]) then some .V48 else (none))))))
@[step] theorem icon_special_class_with_ext_exact_5_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_exact_5 raw ⦃r => r = icon_special_class_with_ext_exact_5_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_exact_5
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_exact_5_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_exact_6_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 109#u8, 115#u8, 100#u8, 111#u8, 119#u8, 110#u8, 108#u8, 111#u8, 97#u8, 100#u8]) then some .V48 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 109#u8, 115#u8, 105#u8]) then some .V48 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 100#u8, 101#u8, 98#u8, 105#u8, 97#u8, 110#u8, 46#u8, 98#u8, 105#u8, 110#u8, 97#u8, 114#u8, 121#u8, 45#u8, 112#u8, 97#u8, 99#u8, 107#u8, 97#u8, 103#u8, 101#u8]) then some .V48 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 114#u8, 112#u8, 109#u8]) then some .V48 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 97#u8, 112#u8, 112#u8, 105#u8, 109#u8, 97#u8, 103#u8, 101#u8]) then some .V48 else (none)))))
@[step] theorem icon_special_class_with_ext_exact_6_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_exact_6 raw ⦃r => r = icon_special_class_with_ext_exact_6_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_exact_6
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_exact_6_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_mime_0_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if window raw [105#u8, 109#u8, 97#u8, 103#u8, 101#u8, 47#u8] 0 then some .V47 else (if window raw [118#u8, 105#u8, 100#u8, 101#u8, 111#u8, 47#u8] 0 then some .V53 else (if window raw [97#u8, 117#u8, 100#u8, 105#u8, 111#u8, 47#u8] 0 then some .V14 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 112#u8, 121#u8, 116#u8, 104#u8, 111#u8, 110#u8] 0 then some .V27 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 114#u8, 117#u8, 115#u8, 116#u8] 0 then some .V29 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 106#u8, 97#u8, 118#u8, 97#u8] 0 then some .V15 else (none))))))
@[step] theorem icon_special_class_with_ext_mime_0_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_mime_0 raw ⦃r => r = icon_special_class_with_ext_mime_0_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_mime_0
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_mime_0_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_mime_1_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 99#u8] 0 then some .V15 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 103#u8, 111#u8] 0 then some .V20 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 114#u8, 117#u8, 98#u8, 121#u8] 0 then some .V28 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 115#u8, 104#u8, 101#u8, 108#u8, 108#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8] 0 then some .V51 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8] 0 then some .V15 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8, 112#u8, 104#u8, 112#u8] 0 then some .V15 else (none))))))
@[step] theorem icon_special_class_with_ext_mime_1_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_mime_1 raw ⦃r => r = icon_special_class_with_ext_mime_1_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_mime_1
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_mime_1_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_mime_2_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 109#u8, 97#u8, 114#u8, 107#u8, 100#u8, 111#u8, 119#u8, 110#u8] 0 then some .V25 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 104#u8, 116#u8, 109#u8, 108#u8] 0 then some .V21 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 99#u8, 115#u8, 115#u8] 0 then some .V19 else (if contains_model raw [106#u8, 97#u8, 118#u8, 97#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8] then some .V23 else (if contains_model raw [116#u8, 121#u8, 112#u8, 101#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8] then some .V32 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8] 0 then some .V33 else (none))))))
@[step] theorem icon_special_class_with_ext_mime_2_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_mime_2 raw ⦃r => r = icon_special_class_with_ext_mime_2_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_mime_2
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_mime_2_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_0_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [112#u8, 100#u8, 102#u8]) then some .V49 else (if decide (raw = [100#u8, 111#u8, 99#u8]) then some .V33 else (if decide (raw = [100#u8, 111#u8, 99#u8, 120#u8]) then some .V33 else (if decide (raw = [111#u8, 100#u8, 116#u8]) then some .V33 else (if decide (raw = [114#u8, 116#u8, 102#u8]) then some .V33 else (if decide (raw = [120#u8, 108#u8, 115#u8]) then some .V52 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_0_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_0 raw ⦃r => r = icon_special_class_with_ext_ext_0_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_0
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_0_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_1_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [120#u8, 108#u8, 115#u8, 120#u8]) then some .V52 else (if decide (raw = [111#u8, 100#u8, 115#u8]) then some .V52 else (if decide (raw = [99#u8, 115#u8, 118#u8]) then some .V52 else (if decide (raw = [112#u8, 112#u8, 116#u8]) then some .V50 else (if decide (raw = [112#u8, 112#u8, 116#u8, 120#u8]) then some .V50 else (if decide (raw = [111#u8, 100#u8, 112#u8]) then some .V50 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_1_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_1 raw ⦃r => r = icon_special_class_with_ext_ext_1_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_1
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_1_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_2_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [107#u8, 101#u8, 121#u8]) then some .V50 else (if decide (raw = [106#u8, 112#u8, 103#u8]) then some .V47 else (if decide (raw = [106#u8, 112#u8, 101#u8, 103#u8]) then some .V47 else (if decide (raw = [112#u8, 110#u8, 103#u8]) then some .V47 else (if decide (raw = [103#u8, 105#u8, 102#u8]) then some .V47 else (if decide (raw = [98#u8, 109#u8, 112#u8]) then some .V47 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_2_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_2 raw ⦃r => r = icon_special_class_with_ext_ext_2_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_2
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_2_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_3_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [115#u8, 118#u8, 103#u8]) then some .V47 else (if decide (raw = [119#u8, 101#u8, 98#u8, 112#u8]) then some .V47 else (if decide (raw = [105#u8, 99#u8, 111#u8]) then some .V47 else (if decide (raw = [116#u8, 105#u8, 102#u8, 102#u8]) then some .V47 else (if decide (raw = [116#u8, 105#u8, 102#u8]) then some .V47 else (if decide (raw = [104#u8, 101#u8, 105#u8, 99#u8]) then some .V47 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_3_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_3 raw ⦃r => r = icon_special_class_with_ext_ext_3_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_3
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_3_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_4_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [104#u8, 101#u8, 105#u8, 102#u8]) then some .V47 else (if decide (raw = [97#u8, 118#u8, 105#u8, 102#u8]) then some .V47 else (if decide (raw = [109#u8, 112#u8, 52#u8]) then some .V53 else (if decide (raw = [97#u8, 118#u8, 105#u8]) then some .V53 else (if decide (raw = [109#u8, 107#u8, 118#u8]) then some .V53 else (if decide (raw = [109#u8, 111#u8, 118#u8]) then some .V53 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_4_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_4 raw ⦃r => r = icon_special_class_with_ext_ext_4_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_4
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_4_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_5_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [119#u8, 109#u8, 118#u8]) then some .V53 else (if decide (raw = [102#u8, 108#u8, 118#u8]) then some .V53 else (if decide (raw = [119#u8, 101#u8, 98#u8, 109#u8]) then some .V53 else (if decide (raw = [109#u8, 52#u8, 118#u8]) then some .V53 else (if decide (raw = [109#u8, 112#u8, 51#u8]) then some .V14 else (if decide (raw = [119#u8, 97#u8, 118#u8]) then some .V14 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_5_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_5 raw ⦃r => r = icon_special_class_with_ext_ext_5_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_5
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_5_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_6_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [111#u8, 103#u8, 103#u8]) then some .V14 else (if decide (raw = [102#u8, 108#u8, 97#u8, 99#u8]) then some .V14 else (if decide (raw = [97#u8, 97#u8, 99#u8]) then some .V14 else (if decide (raw = [119#u8, 109#u8, 97#u8]) then some .V14 else (if decide (raw = [109#u8, 52#u8, 97#u8]) then some .V14 else (if decide (raw = [111#u8, 112#u8, 117#u8, 115#u8]) then some .V14 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_6_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_6 raw ⦃r => r = icon_special_class_with_ext_ext_6_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_6
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_6_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_7_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [122#u8, 105#u8, 112#u8]) then some .V13 else (if decide (raw = [114#u8, 97#u8, 114#u8]) then some .V13 else (if decide (raw = [55#u8, 122#u8]) then some .V13 else (if decide (raw = [116#u8, 97#u8, 114#u8]) then some .V13 else (if decide (raw = [103#u8, 122#u8]) then some .V13 else (if decide (raw = [98#u8, 122#u8, 50#u8]) then some .V13 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_7_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_7 raw ⦃r => r = icon_special_class_with_ext_ext_7_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_7
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_7_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_8_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [120#u8, 122#u8]) then some .V13 else (if decide (raw = [122#u8, 115#u8, 116#u8]) then some .V13 else (if decide (raw = [108#u8, 122#u8, 52#u8]) then some .V13 else (if decide (raw = [101#u8, 120#u8, 101#u8]) then some .V48 else (if decide (raw = [109#u8, 115#u8, 105#u8]) then some .V48 else (if decide (raw = [100#u8, 109#u8, 103#u8]) then some .V48 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_8_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_8 raw ⦃r => r = icon_special_class_with_ext_ext_8_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_8
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_8_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_9_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [100#u8, 101#u8, 98#u8]) then some .V48 else (if decide (raw = [114#u8, 112#u8, 109#u8]) then some .V48 else (if decide (raw = [97#u8, 112#u8, 112#u8, 105#u8, 109#u8, 97#u8, 103#u8, 101#u8]) then some .V48 else (if decide (raw = [112#u8, 107#u8, 103#u8]) then some .V48 else (if decide (raw = [115#u8, 110#u8, 97#u8, 112#u8]) then some .V48 else (if decide (raw = [102#u8, 108#u8, 97#u8, 116#u8, 112#u8, 97#u8, 107#u8]) then some .V48 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_9_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_9 raw ⦃r => r = icon_special_class_with_ext_ext_9_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_9
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_9_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_10_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [112#u8, 121#u8]) then some .V27 else (if decide (raw = [112#u8, 121#u8, 119#u8]) then some .V27 else (if decide (raw = [114#u8, 115#u8]) then some .V29 else (if decide (raw = [103#u8, 111#u8]) then some .V20 else (if decide (raw = [106#u8, 97#u8, 118#u8, 97#u8]) then some .V22 else (if decide (raw = [107#u8, 116#u8]) then some .V22 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_10_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_10 raw ⦃r => r = icon_special_class_with_ext_ext_10_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_10
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_10_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_11_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [107#u8, 116#u8, 115#u8]) then some .V22 else (if decide (raw = [115#u8, 99#u8, 97#u8, 108#u8, 97#u8]) then some .V22 else (if decide (raw = [106#u8, 115#u8]) then some .V23 else (if decide (raw = [106#u8, 115#u8, 120#u8]) then some .V23 else (if decide (raw = [109#u8, 106#u8, 115#u8]) then some .V23 else (if decide (raw = [99#u8, 106#u8, 115#u8]) then some .V23 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_11_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_11 raw ⦃r => r = icon_special_class_with_ext_ext_11_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_11
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_11_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_12_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [116#u8, 115#u8]) then some .V32 else (if decide (raw = [116#u8, 115#u8, 120#u8]) then some .V32 else (if decide (raw = [99#u8]) then some .V16 else (if decide (raw = [104#u8]) then some .V16 else (if decide (raw = [99#u8, 112#u8, 112#u8]) then some .V16 else (if decide (raw = [104#u8, 112#u8, 112#u8]) then some .V16 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_12_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_12 raw ⦃r => r = icon_special_class_with_ext_ext_12_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_12
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_12_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_13_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [99#u8, 99#u8]) then some .V16 else (if decide (raw = [99#u8, 120#u8, 120#u8]) then some .V16 else (if decide (raw = [99#u8, 115#u8]) then some .V18 else (if decide (raw = [114#u8, 98#u8]) then some .V28 else (if decide (raw = [112#u8, 104#u8, 112#u8]) then some .V26 else (if decide (raw = [115#u8, 119#u8, 105#u8, 102#u8, 116#u8]) then some .V31 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_13_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_13 raw ⦃r => r = icon_special_class_with_ext_ext_13_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_13
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_13_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_14_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [114#u8]) then some .V15 else (if decide (raw = [108#u8, 117#u8, 97#u8]) then some .V15 else (if decide (raw = [112#u8, 108#u8]) then some .V15 else (if decide (raw = [112#u8, 109#u8]) then some .V15 else (if decide (raw = [104#u8, 116#u8, 109#u8, 108#u8]) then some .V21 else (if decide (raw = [104#u8, 116#u8, 109#u8]) then some .V21 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_14_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_14 raw ⦃r => r = icon_special_class_with_ext_ext_14_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_14
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_14_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_15_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [99#u8, 115#u8, 115#u8]) then some .V19 else (if decide (raw = [115#u8, 99#u8, 115#u8, 115#u8]) then some .V19 else (if decide (raw = [115#u8, 97#u8, 115#u8, 115#u8]) then some .V19 else (if decide (raw = [108#u8, 101#u8, 115#u8, 115#u8]) then some .V19 else (if decide (raw = [106#u8, 115#u8, 111#u8, 110#u8]) then some .V24 else (if decide (raw = [120#u8, 109#u8, 108#u8]) then some .V21 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_15_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_15 raw ⦃r => r = icon_special_class_with_ext_ext_15_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_15
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_15_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_16_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [121#u8, 97#u8, 109#u8, 108#u8]) then some .V17 else (if decide (raw = [121#u8, 109#u8, 108#u8]) then some .V17 else (if decide (raw = [116#u8, 111#u8, 109#u8, 108#u8]) then some .V17 else (if decide (raw = [105#u8, 110#u8, 105#u8]) then some .V17 else (if decide (raw = [99#u8, 102#u8, 103#u8]) then some .V17 else (if decide (raw = [99#u8, 111#u8, 110#u8, 102#u8]) then some .V17 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_16_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_16 raw ⦃r => r = icon_special_class_with_ext_ext_16_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_16
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_16_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_17_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [115#u8, 113#u8, 108#u8]) then some .V30 else (if decide (raw = [103#u8, 114#u8, 97#u8, 112#u8, 104#u8, 113#u8, 108#u8]) then some .V30 else (if decide (raw = [112#u8, 114#u8, 111#u8, 116#u8, 111#u8]) then some .V30 else (if decide (raw = [118#u8, 117#u8, 101#u8]) then some .V23 else (if decide (raw = [115#u8, 118#u8, 101#u8, 108#u8, 116#u8, 101#u8]) then some .V23 else (if decide (raw = [115#u8, 104#u8]) then some .V51 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_17_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_17 raw ⦃r => r = icon_special_class_with_ext_ext_17_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_17
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_17_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_18_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [98#u8, 97#u8, 115#u8, 104#u8]) then some .V51 else (if decide (raw = [122#u8, 115#u8, 104#u8]) then some .V51 else (if decide (raw = [102#u8, 105#u8, 115#u8, 104#u8]) then some .V51 else (if decide (raw = [112#u8, 115#u8, 49#u8]) then some .V51 else (if decide (raw = [98#u8, 97#u8, 116#u8]) then some .V51 else (if decide (raw = [99#u8, 109#u8, 100#u8]) then some .V51 else (none))))))
@[step] theorem icon_special_class_with_ext_ext_18_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_18 raw ⦃r => r = icon_special_class_with_ext_ext_18_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_18
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_18_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_special_class_with_ext_ext_19_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [109#u8, 100#u8]) then some .V25 else (if decide (raw = [109#u8, 97#u8, 114#u8, 107#u8, 100#u8, 111#u8, 119#u8, 110#u8]) then some .V25 else (if decide (raw = [114#u8, 115#u8, 116#u8]) then some .V25 else (if decide (raw = [116#u8, 120#u8, 116#u8]) then some .V33 else (none))))
@[step] theorem icon_special_class_with_ext_ext_19_complete (raw : Slice U8) :
    display_classifiers.icon_special_class_with_ext_ext_19 raw ⦃r => r = icon_special_class_with_ext_ext_19_model raw.val⦄ := by
  unfold display_classifiers.icon_special_class_with_ext_ext_19
  h5i_steps
  all_goals simp_all [icon_special_class_with_ext_ext_19_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_exact_0_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 112#u8, 100#u8, 102#u8]) then some .V8 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 109#u8, 115#u8, 119#u8, 111#u8, 114#u8, 100#u8]) then some .V4 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 120#u8, 109#u8, 108#u8, 102#u8, 111#u8, 114#u8, 109#u8, 97#u8, 116#u8, 115#u8, 45#u8, 111#u8, 102#u8, 102#u8, 105#u8, 99#u8, 101#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 119#u8, 111#u8, 114#u8, 100#u8, 112#u8, 114#u8, 111#u8, 99#u8, 101#u8, 115#u8, 115#u8, 105#u8, 110#u8, 103#u8, 109#u8, 108#u8, 46#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8]) then some .V4 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 97#u8, 115#u8, 105#u8, 115#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 116#u8, 101#u8, 120#u8, 116#u8]) then some .V4 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 109#u8, 115#u8, 45#u8, 101#u8, 120#u8, 99#u8, 101#u8, 108#u8]) then some .V10 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 120#u8, 109#u8, 108#u8, 102#u8, 111#u8, 114#u8, 109#u8, 97#u8, 116#u8, 115#u8, 45#u8, 111#u8, 102#u8, 102#u8, 105#u8, 99#u8, 101#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 115#u8, 112#u8, 114#u8, 101#u8, 97#u8, 100#u8, 115#u8, 104#u8, 101#u8, 101#u8, 116#u8, 109#u8, 108#u8, 46#u8, 115#u8, 104#u8, 101#u8, 101#u8, 116#u8]) then some .V10 else (none))))))
@[step] theorem category_with_ext_exact_0_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_exact_0 raw ⦃r => r = category_with_ext_exact_0_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_exact_0
  h5i_steps
  all_goals simp_all [category_with_ext_exact_0_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_exact_1_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 97#u8, 115#u8, 105#u8, 115#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 115#u8, 112#u8, 114#u8, 101#u8, 97#u8, 100#u8, 115#u8, 104#u8, 101#u8, 101#u8, 116#u8]) then some .V10 else (if decide (raw = [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 99#u8, 115#u8, 118#u8]) then some .V10 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 109#u8, 115#u8, 45#u8, 112#u8, 111#u8, 119#u8, 101#u8, 114#u8, 112#u8, 111#u8, 105#u8, 110#u8, 116#u8]) then some .V9 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 120#u8, 109#u8, 108#u8, 102#u8, 111#u8, 114#u8, 109#u8, 97#u8, 116#u8, 115#u8, 45#u8, 111#u8, 102#u8, 102#u8, 105#u8, 99#u8, 101#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 112#u8, 114#u8, 101#u8, 115#u8, 101#u8, 110#u8, 116#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 109#u8, 108#u8, 46#u8, 112#u8, 114#u8, 101#u8, 115#u8, 101#u8, 110#u8, 116#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8]) then some .V9 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 111#u8, 97#u8, 115#u8, 105#u8, 115#u8, 46#u8, 111#u8, 112#u8, 101#u8, 110#u8, 100#u8, 111#u8, 99#u8, 117#u8, 109#u8, 101#u8, 110#u8, 116#u8, 46#u8, 112#u8, 114#u8, 101#u8, 115#u8, 101#u8, 110#u8, 116#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8]) then some .V9 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 122#u8, 105#u8, 112#u8]) then some .V1 else (none))))))
@[step] theorem category_with_ext_exact_1_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_exact_1 raw ⦃r => r = category_with_ext_exact_1_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_exact_1
  h5i_steps
  all_goals simp_all [category_with_ext_exact_1_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_exact_2_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 114#u8, 97#u8, 114#u8, 45#u8, 99#u8, 111#u8, 109#u8, 112#u8, 114#u8, 101#u8, 115#u8, 115#u8, 101#u8, 100#u8]) then some .V1 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 118#u8, 110#u8, 100#u8, 46#u8, 114#u8, 97#u8, 114#u8]) then some .V1 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 55#u8, 122#u8, 45#u8, 99#u8, 111#u8, 109#u8, 112#u8, 114#u8, 101#u8, 115#u8, 115#u8, 101#u8, 100#u8]) then some .V1 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 103#u8, 122#u8, 105#u8, 112#u8]) then some .V1 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 116#u8, 97#u8, 114#u8]) then some .V1 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 106#u8, 115#u8, 111#u8, 110#u8]) then some .V3 else (none))))))
@[step] theorem category_with_ext_exact_2_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_exact_2 raw ⦃r => r = category_with_ext_exact_2_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_exact_2
  h5i_steps
  all_goals simp_all [category_with_ext_exact_2_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_exact_3_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 106#u8, 97#u8, 118#u8, 97#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8]) then some .V3 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 116#u8, 121#u8, 112#u8, 101#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8]) then some .V3 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 109#u8, 108#u8]) then some .V3 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 115#u8, 113#u8, 108#u8]) then some .V3 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 115#u8, 104#u8]) then some .V3 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 115#u8, 104#u8, 101#u8, 108#u8, 108#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8]) then some .V3 else (none))))))
@[step] theorem category_with_ext_exact_3_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_exact_3 raw ⦃r => r = category_with_ext_exact_3_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_exact_3
  h5i_steps
  all_goals simp_all [category_with_ext_exact_3_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_exact_4_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 97#u8, 112#u8, 112#u8, 108#u8, 101#u8, 45#u8, 100#u8, 105#u8, 115#u8, 107#u8, 105#u8, 109#u8, 97#u8, 103#u8, 101#u8]) then some .V6 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 109#u8, 115#u8, 45#u8, 100#u8, 111#u8, 115#u8, 45#u8, 101#u8, 120#u8, 101#u8, 99#u8, 117#u8, 116#u8, 97#u8, 98#u8, 108#u8, 101#u8]) then some .V6 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 109#u8, 115#u8, 100#u8, 111#u8, 119#u8, 110#u8, 108#u8, 111#u8, 97#u8, 100#u8]) then some .V6 else (if decide (raw = [97#u8, 112#u8, 112#u8, 108#u8, 105#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 47#u8, 120#u8, 45#u8, 109#u8, 115#u8, 105#u8]) then some .V6 else (none))))
@[step] theorem category_with_ext_exact_4_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_exact_4 raw ⦃r => r = category_with_ext_exact_4_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_exact_4
  h5i_steps
  all_goals simp_all [category_with_ext_exact_4_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_mime_0_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if window raw [105#u8, 109#u8, 97#u8, 103#u8, 101#u8, 47#u8] 0 then some .V5 else (if window raw [118#u8, 105#u8, 100#u8, 101#u8, 111#u8, 47#u8] 0 then some .V12 else (if window raw [97#u8, 117#u8, 100#u8, 105#u8, 111#u8, 47#u8] 0 then some .V2 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 120#u8, 45#u8] 0 then some .V3 else (if contains_model raw [115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8] then some .V3 else (if contains_model raw [106#u8, 97#u8, 118#u8, 97#u8, 115#u8, 99#u8, 114#u8, 105#u8, 112#u8, 116#u8] then some .V3 else (none))))))
@[step] theorem category_with_ext_mime_0_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_mime_0 raw ⦃r => r = category_with_ext_mime_0_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_mime_0
  h5i_steps
  all_goals simp_all [category_with_ext_mime_0_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_mime_1_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 109#u8, 97#u8, 114#u8, 107#u8, 100#u8, 111#u8, 119#u8, 110#u8] 0 then some .V7 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 104#u8, 116#u8, 109#u8, 108#u8] 0 then some .V3 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8, 99#u8, 115#u8, 115#u8] 0 then some .V3 else (if window raw [116#u8, 101#u8, 120#u8, 116#u8, 47#u8] 0 then some .V11 else (none))))
@[step] theorem category_with_ext_mime_1_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_mime_1 raw ⦃r => r = category_with_ext_mime_1_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_mime_1
  h5i_steps
  all_goals simp_all [category_with_ext_mime_1_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_ext_0_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [112#u8, 100#u8, 102#u8]) then some .V8 else (if decide (raw = [100#u8, 111#u8, 99#u8]) then some .V4 else (if decide (raw = [100#u8, 111#u8, 99#u8, 120#u8]) then some .V4 else (if decide (raw = [111#u8, 100#u8, 116#u8]) then some .V4 else (if decide (raw = [114#u8, 116#u8, 102#u8]) then some .V4 else (if decide (raw = [116#u8, 120#u8, 116#u8]) then some .V4 else (none))))))
@[step] theorem category_with_ext_ext_0_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_ext_0 raw ⦃r => r = category_with_ext_ext_0_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_ext_0
  h5i_steps
  all_goals simp_all [category_with_ext_ext_0_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_ext_1_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [120#u8, 108#u8, 115#u8]) then some .V10 else (if decide (raw = [120#u8, 108#u8, 115#u8, 120#u8]) then some .V10 else (if decide (raw = [111#u8, 100#u8, 115#u8]) then some .V10 else (if decide (raw = [99#u8, 115#u8, 118#u8]) then some .V10 else (if decide (raw = [112#u8, 112#u8, 116#u8]) then some .V9 else (if decide (raw = [112#u8, 112#u8, 116#u8, 120#u8]) then some .V9 else (none))))))
@[step] theorem category_with_ext_ext_1_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_ext_1 raw ⦃r => r = category_with_ext_ext_1_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_ext_1
  h5i_steps
  all_goals simp_all [category_with_ext_ext_1_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_ext_2_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [111#u8, 100#u8, 112#u8]) then some .V9 else (if decide (raw = [107#u8, 101#u8, 121#u8]) then some .V9 else (if decide (raw = [106#u8, 112#u8, 103#u8]) then some .V5 else (if decide (raw = [106#u8, 112#u8, 101#u8, 103#u8]) then some .V5 else (if decide (raw = [112#u8, 110#u8, 103#u8]) then some .V5 else (if decide (raw = [103#u8, 105#u8, 102#u8]) then some .V5 else (none))))))
@[step] theorem category_with_ext_ext_2_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_ext_2 raw ⦃r => r = category_with_ext_ext_2_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_ext_2
  h5i_steps
  all_goals simp_all [category_with_ext_ext_2_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_ext_3_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [98#u8, 109#u8, 112#u8]) then some .V5 else (if decide (raw = [115#u8, 118#u8, 103#u8]) then some .V5 else (if decide (raw = [119#u8, 101#u8, 98#u8, 112#u8]) then some .V5 else (if decide (raw = [105#u8, 99#u8, 111#u8]) then some .V5 else (if decide (raw = [116#u8, 105#u8, 102#u8, 102#u8]) then some .V5 else (if decide (raw = [104#u8, 101#u8, 105#u8, 99#u8]) then some .V5 else (none))))))
@[step] theorem category_with_ext_ext_3_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_ext_3 raw ⦃r => r = category_with_ext_ext_3_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_ext_3
  h5i_steps
  all_goals simp_all [category_with_ext_ext_3_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_ext_4_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [97#u8, 118#u8, 105#u8, 102#u8]) then some .V5 else (if decide (raw = [109#u8, 112#u8, 52#u8]) then some .V12 else (if decide (raw = [97#u8, 118#u8, 105#u8]) then some .V12 else (if decide (raw = [109#u8, 107#u8, 118#u8]) then some .V12 else (if decide (raw = [109#u8, 111#u8, 118#u8]) then some .V12 else (if decide (raw = [119#u8, 109#u8, 118#u8]) then some .V12 else (none))))))
@[step] theorem category_with_ext_ext_4_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_ext_4 raw ⦃r => r = category_with_ext_ext_4_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_ext_4
  h5i_steps
  all_goals simp_all [category_with_ext_ext_4_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_ext_5_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [102#u8, 108#u8, 118#u8]) then some .V12 else (if decide (raw = [119#u8, 101#u8, 98#u8, 109#u8]) then some .V12 else (if decide (raw = [109#u8, 52#u8, 118#u8]) then some .V12 else (if decide (raw = [109#u8, 112#u8, 51#u8]) then some .V2 else (if decide (raw = [119#u8, 97#u8, 118#u8]) then some .V2 else (if decide (raw = [111#u8, 103#u8, 103#u8]) then some .V2 else (none))))))
@[step] theorem category_with_ext_ext_5_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_ext_5 raw ⦃r => r = category_with_ext_ext_5_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_ext_5
  h5i_steps
  all_goals simp_all [category_with_ext_ext_5_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_ext_6_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [102#u8, 108#u8, 97#u8, 99#u8]) then some .V2 else (if decide (raw = [97#u8, 97#u8, 99#u8]) then some .V2 else (if decide (raw = [119#u8, 109#u8, 97#u8]) then some .V2 else (if decide (raw = [109#u8, 52#u8, 97#u8]) then some .V2 else (if decide (raw = [111#u8, 112#u8, 117#u8, 115#u8]) then some .V2 else (if decide (raw = [122#u8, 105#u8, 112#u8]) then some .V1 else (none))))))
@[step] theorem category_with_ext_ext_6_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_ext_6 raw ⦃r => r = category_with_ext_ext_6_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_ext_6
  h5i_steps
  all_goals simp_all [category_with_ext_ext_6_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_ext_7_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [114#u8, 97#u8, 114#u8]) then some .V1 else (if decide (raw = [55#u8, 122#u8]) then some .V1 else (if decide (raw = [116#u8, 97#u8, 114#u8]) then some .V1 else (if decide (raw = [103#u8, 122#u8]) then some .V1 else (if decide (raw = [98#u8, 122#u8, 50#u8]) then some .V1 else (if decide (raw = [120#u8, 122#u8]) then some .V1 else (none))))))
@[step] theorem category_with_ext_ext_7_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_ext_7 raw ⦃r => r = category_with_ext_ext_7_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_ext_7
  h5i_steps
  all_goals simp_all [category_with_ext_ext_7_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_ext_8_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [101#u8, 120#u8, 101#u8]) then some .V6 else (if decide (raw = [109#u8, 115#u8, 105#u8]) then some .V6 else (if decide (raw = [100#u8, 109#u8, 103#u8]) then some .V6 else (if decide (raw = [100#u8, 101#u8, 98#u8]) then some .V6 else (if decide (raw = [114#u8, 112#u8, 109#u8]) then some .V6 else (if decide (raw = [97#u8, 112#u8, 112#u8, 105#u8, 109#u8, 97#u8, 103#u8, 101#u8]) then some .V6 else (none))))))
@[step] theorem category_with_ext_ext_8_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_ext_8 raw ⦃r => r = category_with_ext_ext_8_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_ext_8
  h5i_steps
  all_goals simp_all [category_with_ext_ext_8_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_ext_9_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [106#u8, 115#u8]) then some .V3 else (if decide (raw = [106#u8, 115#u8, 120#u8]) then some .V3 else (if decide (raw = [116#u8, 115#u8]) then some .V3 else (if decide (raw = [116#u8, 115#u8, 120#u8]) then some .V3 else (if decide (raw = [112#u8, 121#u8]) then some .V3 else (if decide (raw = [114#u8, 115#u8]) then some .V3 else (none))))))
@[step] theorem category_with_ext_ext_9_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_ext_9 raw ⦃r => r = category_with_ext_ext_9_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_ext_9
  h5i_steps
  all_goals simp_all [category_with_ext_ext_9_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_ext_10_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [103#u8, 111#u8]) then some .V3 else (if decide (raw = [106#u8, 97#u8, 118#u8, 97#u8]) then some .V3 else (if decide (raw = [99#u8]) then some .V3 else (if decide (raw = [99#u8, 112#u8, 112#u8]) then some .V3 else (if decide (raw = [99#u8, 115#u8]) then some .V3 else (if decide (raw = [114#u8, 98#u8]) then some .V3 else (none))))))
@[step] theorem category_with_ext_ext_10_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_ext_10 raw ⦃r => r = category_with_ext_ext_10_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_ext_10
  h5i_steps
  all_goals simp_all [category_with_ext_ext_10_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_ext_11_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [112#u8, 104#u8, 112#u8]) then some .V3 else (if decide (raw = [115#u8, 119#u8, 105#u8, 102#u8, 116#u8]) then some .V3 else (if decide (raw = [107#u8, 116#u8]) then some .V3 else (if decide (raw = [115#u8, 99#u8, 97#u8, 108#u8, 97#u8]) then some .V3 else (if decide (raw = [114#u8]) then some .V3 else (if decide (raw = [108#u8, 117#u8, 97#u8]) then some .V3 else (none))))))
@[step] theorem category_with_ext_ext_11_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_ext_11 raw ⦃r => r = category_with_ext_ext_11_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_ext_11
  h5i_steps
  all_goals simp_all [category_with_ext_ext_11_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_ext_12_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [112#u8, 108#u8]) then some .V3 else (if decide (raw = [104#u8, 116#u8, 109#u8, 108#u8]) then some .V3 else (if decide (raw = [104#u8, 116#u8, 109#u8]) then some .V3 else (if decide (raw = [99#u8, 115#u8, 115#u8]) then some .V3 else (if decide (raw = [115#u8, 99#u8, 115#u8, 115#u8]) then some .V3 else (if decide (raw = [106#u8, 115#u8, 111#u8, 110#u8]) then some .V3 else (none))))))
@[step] theorem category_with_ext_ext_12_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_ext_12 raw ⦃r => r = category_with_ext_ext_12_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_ext_12
  h5i_steps
  all_goals simp_all [category_with_ext_ext_12_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_ext_13_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [120#u8, 109#u8, 108#u8]) then some .V3 else (if decide (raw = [121#u8, 97#u8, 109#u8, 108#u8]) then some .V3 else (if decide (raw = [121#u8, 109#u8, 108#u8]) then some .V3 else (if decide (raw = [116#u8, 111#u8, 109#u8, 108#u8]) then some .V3 else (if decide (raw = [115#u8, 113#u8, 108#u8]) then some .V3 else (if decide (raw = [115#u8, 104#u8]) then some .V3 else (none))))))
@[step] theorem category_with_ext_ext_13_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_ext_13 raw ⦃r => r = category_with_ext_ext_13_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_ext_13
  h5i_steps
  all_goals simp_all [category_with_ext_ext_13_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_ext_14_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [98#u8, 97#u8, 115#u8, 104#u8]) then some .V3 else (if decide (raw = [98#u8, 97#u8, 116#u8]) then some .V3 else (if decide (raw = [112#u8, 115#u8, 49#u8]) then some .V3 else (if decide (raw = [118#u8, 117#u8, 101#u8]) then some .V3 else (if decide (raw = [115#u8, 118#u8, 101#u8, 108#u8, 116#u8, 101#u8]) then some .V3 else (if decide (raw = [109#u8, 100#u8]) then some .V7 else (none))))))
@[step] theorem category_with_ext_ext_14_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_ext_14 raw ⦃r => r = category_with_ext_ext_14_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_ext_14
  h5i_steps
  all_goals simp_all [category_with_ext_ext_14_model, Slice.eq_iff, Array.to_slice, Array.make]
def category_with_ext_ext_15_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  if decide (raw = [109#u8, 97#u8, 114#u8, 107#u8, 100#u8, 111#u8, 119#u8, 110#u8]) then some .V7 else (if decide (raw = [114#u8, 115#u8, 116#u8]) then some .V7 else (none))
@[step] theorem category_with_ext_ext_15_complete (raw : Slice U8) :
    display_classifiers.category_with_ext_ext_15 raw ⦃r => r = category_with_ext_ext_15_model raw.val⦄ := by
  unfold display_classifiers.category_with_ext_ext_15
  h5i_steps
  all_goals simp_all [category_with_ext_ext_15_model, Slice.eq_iff, Array.to_slice, Array.make]
def icon_class_with_ext_model (mime : List U8) (ext : Option (List U8)) : display_classifiers.DisplayValue :=
  match icon_class_with_ext_exact_0_model mime with | some v => v | none => (match icon_class_with_ext_exact_1_model mime with | some v => v | none => (match icon_class_with_ext_exact_2_model mime with | some v => v | none => (match icon_class_with_ext_exact_3_model mime with | some v => v | none => (match icon_class_with_ext_exact_4_model mime with | some v => v | none => (match icon_class_with_ext_exact_5_model mime with | some v => v | none => (match icon_class_with_ext_exact_6_model mime with | some v => v | none => (match icon_class_with_ext_mime_0_model mime with | some v => v | none => (match icon_class_with_ext_mime_1_model mime with | some v => v | none => (match icon_class_with_ext_mime_2_model mime with | some v => v | none => (match ext with | none => .V34 | some ext => (match icon_class_with_ext_ext_0_model ext with | some v => v | none => (match icon_class_with_ext_ext_1_model ext with | some v => v | none => (match icon_class_with_ext_ext_2_model ext with | some v => v | none => (match icon_class_with_ext_ext_3_model ext with | some v => v | none => (match icon_class_with_ext_ext_4_model ext with | some v => v | none => (match icon_class_with_ext_ext_5_model ext with | some v => v | none => (match icon_class_with_ext_ext_6_model ext with | some v => v | none => (match icon_class_with_ext_ext_7_model ext with | some v => v | none => (match icon_class_with_ext_ext_8_model ext with | some v => v | none => (match icon_class_with_ext_ext_9_model ext with | some v => v | none => (match icon_class_with_ext_ext_10_model ext with | some v => v | none => (match icon_class_with_ext_ext_11_model ext with | some v => v | none => (match icon_class_with_ext_ext_12_model ext with | some v => v | none => (match icon_class_with_ext_ext_13_model ext with | some v => v | none => (match icon_class_with_ext_ext_14_model ext with | some v => v | none => (match icon_class_with_ext_ext_15_model ext with | some v => v | none => (match icon_class_with_ext_ext_16_model ext with | some v => v | none => (match icon_class_with_ext_ext_17_model ext with | some v => v | none => (match icon_class_with_ext_ext_18_model ext with | some v => v | none => (match icon_class_with_ext_ext_19_model ext with | some v => v | none => (.V34)))))))))))))))))))))))))))))))
@[step] theorem icon_class_with_ext_complete (mime : Slice U8) (ext : Option (Slice U8)) :
    display_classifiers.icon_class_with_ext mime ext ⦃r => r = icon_class_with_ext_model mime.val (ext.map Slice.val)⦄ := by
  unfold display_classifiers.icon_class_with_ext
  unfold icon_class_with_ext_model
  step as ⟨o, ho⟩
  cases o with
  | some v => simp [← ho]
  | none =>
    simp only [← ho]
    step as ⟨o, ho⟩
    cases o with
    | some v => simp [← ho]
    | none =>
      simp only [← ho]
      step as ⟨o, ho⟩
      cases o with
      | some v => simp [← ho]
      | none =>
        simp only [← ho]
        step as ⟨o, ho⟩
        cases o with
        | some v => simp [← ho]
        | none =>
          simp only [← ho]
          step as ⟨o, ho⟩
          cases o with
          | some v => simp [← ho]
          | none =>
            simp only [← ho]
            step as ⟨o, ho⟩
            cases o with
            | some v => simp [← ho]
            | none =>
              simp only [← ho]
              step as ⟨o, ho⟩
              cases o with
              | some v => simp [← ho]
              | none =>
                simp only [← ho]
                step as ⟨o, ho⟩
                cases o with
                | some v => simp [← ho]
                | none =>
                  simp only [← ho]
                  step as ⟨o, ho⟩
                  cases o with
                  | some v => simp [← ho]
                  | none =>
                    simp only [← ho]
                    step as ⟨o, ho⟩
                    cases o with
                    | some v => simp [← ho]
                    | none =>
                      simp only [← ho]
                      cases ext with
                      | none => simp
                      | some ext =>
                        simp only [Option.map_some]
                        step as ⟨o, ho⟩
                        cases o with
                        | some v => simp [← ho]
                        | none =>
                          simp only [← ho]
                          step as ⟨o, ho⟩
                          cases o with
                          | some v => simp [← ho]
                          | none =>
                            simp only [← ho]
                            step as ⟨o, ho⟩
                            cases o with
                            | some v => simp [← ho]
                            | none =>
                              simp only [← ho]
                              step as ⟨o, ho⟩
                              cases o with
                              | some v => simp [← ho]
                              | none =>
                                simp only [← ho]
                                step as ⟨o, ho⟩
                                cases o with
                                | some v => simp [← ho]
                                | none =>
                                  simp only [← ho]
                                  step as ⟨o, ho⟩
                                  cases o with
                                  | some v => simp [← ho]
                                  | none =>
                                    simp only [← ho]
                                    step as ⟨o, ho⟩
                                    cases o with
                                    | some v => simp [← ho]
                                    | none =>
                                      simp only [← ho]
                                      step as ⟨o, ho⟩
                                      cases o with
                                      | some v => simp [← ho]
                                      | none =>
                                        simp only [← ho]
                                        step as ⟨o, ho⟩
                                        cases o with
                                        | some v => simp [← ho]
                                        | none =>
                                          simp only [← ho]
                                          step as ⟨o, ho⟩
                                          cases o with
                                          | some v => simp [← ho]
                                          | none =>
                                            simp only [← ho]
                                            step as ⟨o, ho⟩
                                            cases o with
                                            | some v => simp [← ho]
                                            | none =>
                                              simp only [← ho]
                                              step as ⟨o, ho⟩
                                              cases o with
                                              | some v => simp [← ho]
                                              | none =>
                                                simp only [← ho]
                                                step as ⟨o, ho⟩
                                                cases o with
                                                | some v => simp [← ho]
                                                | none =>
                                                  simp only [← ho]
                                                  step as ⟨o, ho⟩
                                                  cases o with
                                                  | some v => simp [← ho]
                                                  | none =>
                                                    simp only [← ho]
                                                    step as ⟨o, ho⟩
                                                    cases o with
                                                    | some v => simp [← ho]
                                                    | none =>
                                                      simp only [← ho]
                                                      step as ⟨o, ho⟩
                                                      cases o with
                                                      | some v => simp [← ho]
                                                      | none =>
                                                        simp only [← ho]
                                                        step as ⟨o, ho⟩
                                                        cases o with
                                                        | some v => simp [← ho]
                                                        | none =>
                                                          simp only [← ho]
                                                          step as ⟨o, ho⟩
                                                          cases o with
                                                          | some v => simp [← ho]
                                                          | none =>
                                                            simp only [← ho]
                                                            step as ⟨o, ho⟩
                                                            cases o with
                                                            | some v => simp [← ho]
                                                            | none =>
                                                              simp only [← ho]
                                                              step as ⟨o, ho⟩
                                                              cases o with
                                                              | some v => simp [← ho]
                                                              | none =>
                                                                simp only [← ho]
                                                                simp

def icon_special_class_with_ext_model (mime : List U8) (ext : Option (List U8)) : display_classifiers.DisplayValue :=
  match icon_special_class_with_ext_exact_0_model mime with | some v => v | none => (match icon_special_class_with_ext_exact_1_model mime with | some v => v | none => (match icon_special_class_with_ext_exact_2_model mime with | some v => v | none => (match icon_special_class_with_ext_exact_3_model mime with | some v => v | none => (match icon_special_class_with_ext_exact_4_model mime with | some v => v | none => (match icon_special_class_with_ext_exact_5_model mime with | some v => v | none => (match icon_special_class_with_ext_exact_6_model mime with | some v => v | none => (match icon_special_class_with_ext_mime_0_model mime with | some v => v | none => (match icon_special_class_with_ext_mime_1_model mime with | some v => v | none => (match icon_special_class_with_ext_mime_2_model mime with | some v => v | none => (match ext with | none => .V0 | some ext => (match icon_special_class_with_ext_ext_0_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_1_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_2_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_3_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_4_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_5_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_6_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_7_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_8_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_9_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_10_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_11_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_12_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_13_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_14_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_15_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_16_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_17_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_18_model ext with | some v => v | none => (match icon_special_class_with_ext_ext_19_model ext with | some v => v | none => (.V0)))))))))))))))))))))))))))))))
@[step] theorem icon_special_class_with_ext_complete (mime : Slice U8) (ext : Option (Slice U8)) :
    display_classifiers.icon_special_class_with_ext mime ext ⦃r => r = icon_special_class_with_ext_model mime.val (ext.map Slice.val)⦄ := by
  unfold display_classifiers.icon_special_class_with_ext
  unfold icon_special_class_with_ext_model
  step as ⟨o, ho⟩
  cases o with
  | some v => simp [← ho]
  | none =>
    simp only [← ho]
    step as ⟨o, ho⟩
    cases o with
    | some v => simp [← ho]
    | none =>
      simp only [← ho]
      step as ⟨o, ho⟩
      cases o with
      | some v => simp [← ho]
      | none =>
        simp only [← ho]
        step as ⟨o, ho⟩
        cases o with
        | some v => simp [← ho]
        | none =>
          simp only [← ho]
          step as ⟨o, ho⟩
          cases o with
          | some v => simp [← ho]
          | none =>
            simp only [← ho]
            step as ⟨o, ho⟩
            cases o with
            | some v => simp [← ho]
            | none =>
              simp only [← ho]
              step as ⟨o, ho⟩
              cases o with
              | some v => simp [← ho]
              | none =>
                simp only [← ho]
                step as ⟨o, ho⟩
                cases o with
                | some v => simp [← ho]
                | none =>
                  simp only [← ho]
                  step as ⟨o, ho⟩
                  cases o with
                  | some v => simp [← ho]
                  | none =>
                    simp only [← ho]
                    step as ⟨o, ho⟩
                    cases o with
                    | some v => simp [← ho]
                    | none =>
                      simp only [← ho]
                      cases ext with
                      | none => simp
                      | some ext =>
                        simp only [Option.map_some]
                        step as ⟨o, ho⟩
                        cases o with
                        | some v => simp [← ho]
                        | none =>
                          simp only [← ho]
                          step as ⟨o, ho⟩
                          cases o with
                          | some v => simp [← ho]
                          | none =>
                            simp only [← ho]
                            step as ⟨o, ho⟩
                            cases o with
                            | some v => simp [← ho]
                            | none =>
                              simp only [← ho]
                              step as ⟨o, ho⟩
                              cases o with
                              | some v => simp [← ho]
                              | none =>
                                simp only [← ho]
                                step as ⟨o, ho⟩
                                cases o with
                                | some v => simp [← ho]
                                | none =>
                                  simp only [← ho]
                                  step as ⟨o, ho⟩
                                  cases o with
                                  | some v => simp [← ho]
                                  | none =>
                                    simp only [← ho]
                                    step as ⟨o, ho⟩
                                    cases o with
                                    | some v => simp [← ho]
                                    | none =>
                                      simp only [← ho]
                                      step as ⟨o, ho⟩
                                      cases o with
                                      | some v => simp [← ho]
                                      | none =>
                                        simp only [← ho]
                                        step as ⟨o, ho⟩
                                        cases o with
                                        | some v => simp [← ho]
                                        | none =>
                                          simp only [← ho]
                                          step as ⟨o, ho⟩
                                          cases o with
                                          | some v => simp [← ho]
                                          | none =>
                                            simp only [← ho]
                                            step as ⟨o, ho⟩
                                            cases o with
                                            | some v => simp [← ho]
                                            | none =>
                                              simp only [← ho]
                                              step as ⟨o, ho⟩
                                              cases o with
                                              | some v => simp [← ho]
                                              | none =>
                                                simp only [← ho]
                                                step as ⟨o, ho⟩
                                                cases o with
                                                | some v => simp [← ho]
                                                | none =>
                                                  simp only [← ho]
                                                  step as ⟨o, ho⟩
                                                  cases o with
                                                  | some v => simp [← ho]
                                                  | none =>
                                                    simp only [← ho]
                                                    step as ⟨o, ho⟩
                                                    cases o with
                                                    | some v => simp [← ho]
                                                    | none =>
                                                      simp only [← ho]
                                                      step as ⟨o, ho⟩
                                                      cases o with
                                                      | some v => simp [← ho]
                                                      | none =>
                                                        simp only [← ho]
                                                        step as ⟨o, ho⟩
                                                        cases o with
                                                        | some v => simp [← ho]
                                                        | none =>
                                                          simp only [← ho]
                                                          step as ⟨o, ho⟩
                                                          cases o with
                                                          | some v => simp [← ho]
                                                          | none =>
                                                            simp only [← ho]
                                                            step as ⟨o, ho⟩
                                                            cases o with
                                                            | some v => simp [← ho]
                                                            | none =>
                                                              simp only [← ho]
                                                              step as ⟨o, ho⟩
                                                              cases o with
                                                              | some v => simp [← ho]
                                                              | none =>
                                                                simp only [← ho]
                                                                simp

def category_with_ext_model (mime : List U8) (ext : Option (List U8)) : display_classifiers.DisplayValue :=
  match category_with_ext_exact_0_model mime with | some v => v | none => (match category_with_ext_exact_1_model mime with | some v => v | none => (match category_with_ext_exact_2_model mime with | some v => v | none => (match category_with_ext_exact_3_model mime with | some v => v | none => (match category_with_ext_exact_4_model mime with | some v => v | none => (match category_with_ext_mime_0_model mime with | some v => v | none => (match category_with_ext_mime_1_model mime with | some v => v | none => (match ext with | none => .V4 | some ext => (match category_with_ext_ext_0_model ext with | some v => v | none => (match category_with_ext_ext_1_model ext with | some v => v | none => (match category_with_ext_ext_2_model ext with | some v => v | none => (match category_with_ext_ext_3_model ext with | some v => v | none => (match category_with_ext_ext_4_model ext with | some v => v | none => (match category_with_ext_ext_5_model ext with | some v => v | none => (match category_with_ext_ext_6_model ext with | some v => v | none => (match category_with_ext_ext_7_model ext with | some v => v | none => (match category_with_ext_ext_8_model ext with | some v => v | none => (match category_with_ext_ext_9_model ext with | some v => v | none => (match category_with_ext_ext_10_model ext with | some v => v | none => (match category_with_ext_ext_11_model ext with | some v => v | none => (match category_with_ext_ext_12_model ext with | some v => v | none => (match category_with_ext_ext_13_model ext with | some v => v | none => (match category_with_ext_ext_14_model ext with | some v => v | none => (match category_with_ext_ext_15_model ext with | some v => v | none => (.V4))))))))))))))))))))))))
@[step] theorem category_with_ext_complete (mime : Slice U8) (ext : Option (Slice U8)) :
    display_classifiers.category_with_ext mime ext ⦃r => r = category_with_ext_model mime.val (ext.map Slice.val)⦄ := by
  unfold display_classifiers.category_with_ext
  unfold category_with_ext_model
  step as ⟨o, ho⟩
  cases o with
  | some v => simp [← ho]
  | none =>
    simp only [← ho]
    step as ⟨o, ho⟩
    cases o with
    | some v => simp [← ho]
    | none =>
      simp only [← ho]
      step as ⟨o, ho⟩
      cases o with
      | some v => simp [← ho]
      | none =>
        simp only [← ho]
        step as ⟨o, ho⟩
        cases o with
        | some v => simp [← ho]
        | none =>
          simp only [← ho]
          step as ⟨o, ho⟩
          cases o with
          | some v => simp [← ho]
          | none =>
            simp only [← ho]
            step as ⟨o, ho⟩
            cases o with
            | some v => simp [← ho]
            | none =>
              simp only [← ho]
              step as ⟨o, ho⟩
              cases o with
              | some v => simp [← ho]
              | none =>
                simp only [← ho]
                cases ext with
                | none => simp
                | some ext =>
                  simp only [Option.map_some]
                  step as ⟨o, ho⟩
                  cases o with
                  | some v => simp [← ho]
                  | none =>
                    simp only [← ho]
                    step as ⟨o, ho⟩
                    cases o with
                    | some v => simp [← ho]
                    | none =>
                      simp only [← ho]
                      step as ⟨o, ho⟩
                      cases o with
                      | some v => simp [← ho]
                      | none =>
                        simp only [← ho]
                        step as ⟨o, ho⟩
                        cases o with
                        | some v => simp [← ho]
                        | none =>
                          simp only [← ho]
                          step as ⟨o, ho⟩
                          cases o with
                          | some v => simp [← ho]
                          | none =>
                            simp only [← ho]
                            step as ⟨o, ho⟩
                            cases o with
                            | some v => simp [← ho]
                            | none =>
                              simp only [← ho]
                              step as ⟨o, ho⟩
                              cases o with
                              | some v => simp [← ho]
                              | none =>
                                simp only [← ho]
                                step as ⟨o, ho⟩
                                cases o with
                                | some v => simp [← ho]
                                | none =>
                                  simp only [← ho]
                                  step as ⟨o, ho⟩
                                  cases o with
                                  | some v => simp [← ho]
                                  | none =>
                                    simp only [← ho]
                                    step as ⟨o, ho⟩
                                    cases o with
                                    | some v => simp [← ho]
                                    | none =>
                                      simp only [← ho]
                                      step as ⟨o, ho⟩
                                      cases o with
                                      | some v => simp [← ho]
                                      | none =>
                                        simp only [← ho]
                                        step as ⟨o, ho⟩
                                        cases o with
                                        | some v => simp [← ho]
                                        | none =>
                                          simp only [← ho]
                                          step as ⟨o, ho⟩
                                          cases o with
                                          | some v => simp [← ho]
                                          | none =>
                                            simp only [← ho]
                                            step as ⟨o, ho⟩
                                            cases o with
                                            | some v => simp [← ho]
                                            | none =>
                                              simp only [← ho]
                                              step as ⟨o, ho⟩
                                              cases o with
                                              | some v => simp [← ho]
                                              | none =>
                                                simp only [← ho]
                                                step as ⟨o, ho⟩
                                                cases o with
                                                | some v => simp [← ho]
                                                | none =>
                                                  simp only [← ho]
                                                  simp

end oxicloud_kernel.Verified.DisplayClassifiers
