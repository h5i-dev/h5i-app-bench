import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit

namespace kanidm_kernel.Solution

@[step] theorem starts_at_spec (hay needle : Slice U8) (a : Usize)
    (h : a.val + needle.length ≤ hay.length) :
    valueset.starts_at hay a needle ⦃ b =>
      b = decide ((hay.val.drop a.val).take needle.length = needle.val) ⦄ := by
  unfold valueset.starts_at valueset.starts_at_loop
  apply loop_idx_spec _ (fun j => j) needle.length
    (fun j => ∀ k < j.val, hay.val[a.val + k]? = needle.val[k]?)
  · intro j hI hj
    unfold valueset.starts_at_loop.body
    step*
    · have hj' : j.val < needle.length := by scalar_tac
      have hne : i2 ≠ i3 := by simpa using ‹(i2 != i3) = true›
      have hlen : a.val + j.val < hay.length := by omega
      symm; rw [decide_eq_false_iff_not]
      intro heq
      have := congrArg (fun l => l[j.val]?) heq
      simp only [List.getElem?_take, List.getElem?_drop, hj', if_true] at this
      rw [List.getElem?_eq_getElem hlen, List.getElem?_eq_getElem hj'] at this
      apply hne
      simp only [i2_post, i3_post, i1_post]
      simpa using this
    · have hj' : j.val < needle.length := by scalar_tac
      have heq : i2 = i3 := by have := ‹¬(i2 != i3) = true›; simp at this; exact UScalar.eq_equiv _ _ |>.2 this
      have hlen : a.val + j.val < hay.length := by omega
      refine ⟨?_, by omega, by omega⟩
      intro k hk
      rcases Nat.lt_succ_iff_lt_or_eq.1 (j1_post ▸ hk) with hk | rfl
      · exact hI k hk
      · rw [List.getElem?_eq_getElem hlen, List.getElem?_eq_getElem hj']
        simp only [i2_post, i3_post, i1_post] at heq
        simpa using heq
    · have hj' : needle.val.length ≤ j.val := by scalar_tac
      have hl : needle.length = needle.val.length := rfl
      symm; rw [decide_eq_true_iff]
      apply List.ext_getElem?
      intro k
      rw [List.getElem?_take, List.getElem?_drop]
      split
      · exact hI k (by omega)
      · rw [List.getElem?_eq_none (by omega)]
  · simp
  · simp

theorem str_contains_spec (hay needle : Slice U8) (hlt : hay.length < Usize.max) :
    valueset.str_contains hay needle = ok (decide (needle.val <:+: hay.val)) := by
  apply eq_ok_of_spec
  unfold valueset.str_contains
  have hl : needle.length = needle.val.length := rfl
  have hh : hay.length = hay.val.length := rfl
  simp only []
  split
  · have : ¬ needle.val <:+: hay.val := fun hi => by
      have := hi.length_le; scalar_tac
    simp [this]
  · unfold valueset.str_contains_loop
    apply loop_idx_spec _ (fun i => i) (hay.val.length - needle.val.length + 1)
      (fun i => ∀ k < i.val, (hay.val.drop k).take needle.val.length ≠ needle.val)
    · intro i hI hi
      unfold valueset.str_contains_loop.body
      step*
      · rename_i hle hb
        have hb' : List.take needle.length (List.drop i.val hay.val) = needle.val := by
          simpa [hb] using b_post.symm
        have : i.val + needle.val.length ≤ hay.val.length := by scalar_tac
        symm; rw [decide_eq_true_iff, infix_iff_window]
        exact ⟨i.val, this, by rw [← hl]; exact hb'⟩
      · rename_i hle hb
        have hb' : List.take needle.length (List.drop i.val hay.val) ≠ needle.val := by
          intro h; apply hb; simp [b_post, h]
        have : i.val + needle.val.length ≤ hay.val.length := by scalar_tac
        refine ⟨?_, by omega, by omega⟩
        intro k hk
        rcases Nat.lt_succ_iff_lt_or_eq.1 (i4_post ▸ hk) with hk | rfl
        · exact hI k hk
        · rw [← hl]; exact hb'
      · rename_i hgt
        have : hay.val.length < i.val + needle.val.length := by scalar_tac
        symm; rw [decide_eq_false_iff_not, infix_iff_window]
        rintro ⟨k, hk, hw⟩
        exact hI k (by omega) hw
    · simp
    · simp
end kanidm_kernel.Solution
