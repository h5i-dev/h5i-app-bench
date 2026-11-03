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
