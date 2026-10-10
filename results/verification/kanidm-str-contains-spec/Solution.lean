import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit

namespace kanidm_kernel.Solution

def byteMatches (hay needle : List U8) (a : Nat) : Prop :=
  ∀ k, k < needle.length → hay[a + k]! = needle[k]!

instance (hay needle : List U8) (a : Nat) : Decidable (byteMatches hay needle a) :=
  inferInstanceAs (Decidable (∀ k, k < needle.length → hay[a + k]! = needle[k]!))

theorem matches_iff_window (hay needle : List U8) (a : Nat)
    (ha : a + needle.length ≤ hay.length) :
    byteMatches hay needle a ↔ (hay.drop a).take needle.length = needle := by
  constructor
  · intro h
    apply List.ext_getElem
    · simp; omega
    · intro k hk hk'
      have he := h k hk'
      simpa only [getElem!_pos hay (a + k) (by omega),
        getElem!_pos needle k hk', List.getElem_take, List.getElem_drop,
        Nat.add_comm] using he
  · intro h k hk
    have he := congrArg (fun l : List U8 => l[k]!) h
    simpa only [getElem!_pos ((hay.drop a).take needle.length) k (by simp; omega),
      getElem!_pos needle k hk, getElem!_pos hay (a + k) (by omega),
      List.getElem_take, List.getElem_drop, Nat.add_comm] using he

@[step] theorem starts_at_spec (hay needle : Slice U8) (a : Usize)
    (ha : a.val + needle.val.length ≤ hay.val.length) :
    valueset.starts_at hay a needle ⦃ b => b = decide (byteMatches hay.val needle.val a.val) ⦄ := by
  unfold valueset.starts_at valueset.starts_at_loop
  apply loop.spec_decr_nat (measure := fun j : Usize => needle.val.length - j.val)
    (inv := fun j => j.val ≤ needle.val.length ∧
      ∀ k, k < j.val → hay.val[a.val + k]! = needle.val[k]!)
  · rintro j ⟨hj, hpre⟩
    unfold valueset.starts_at_loop.body
    step*
    · rename_i hlt hne
      have hjlt : j.val < needle.val.length := by scalar_tac
      have haj : a.val + j.val < hay.val.length := by omega
      have hne' : i2 ≠ i3 := by simpa using hne
      have hm : ¬ byteMatches hay.val needle.val a.val := by
        intro hm
        have he := hm j.val hjlt
        simp only [getElem!_pos hay.val (a.val + j.val) haj,
          getElem!_pos needle.val j.val hjlt] at he
        apply hne'
        simpa [i1_post, i2_post, i3_post] using he
      simp [hm]
    · rename_i hlt heq
      have hjlt : j.val < needle.val.length := by scalar_tac
      have haj : a.val + j.val < hay.val.length := by omega
      have heq' : i2 = i3 := by scalar_tac
      refine ⟨by omega, ?_, by omega⟩
      intro k hk
      by_cases hkj : k < j.val
      · exact hpre k hkj
      · have hkj : k = j.val := by omega
        subst k
        simp only [getElem!_pos hay.val (a.val + j.val) haj,
          getElem!_pos needle.val j.val hjlt]
        simpa [i1_post, i2_post, i3_post] using heq'
    · have hjge : needle.val.length ≤ j.val := by scalar_tac
      have hm : byteMatches hay.val needle.val a.val := by
        intro k hk
        exact hpre k (by omega)
      simp [hm]
  · simp

@[step] theorem contains_loop_spec (hay needle : Slice U8) (last : Usize)
    (hlast : last.val + needle.val.length = hay.val.length)
    (hpos : 0 < needle.val.length) :
    valueset.str_contains_loop hay needle last 0#usize ⦃ b =>
      b = decide (∃ k, k ≤ last.val ∧ byteMatches hay.val needle.val k) ⦄ := by
  unfold valueset.str_contains_loop
  apply loop.spec_decr_nat (measure := fun i : Usize => last.val + 1 - i.val)
    (inv := fun i => i.val ≤ last.val + 1 ∧
      ∀ k, k < i.val → ¬ byteMatches hay.val needle.val k)
  · rintro i ⟨hi, hpre⟩
    unfold valueset.str_contains_loop.body
    step*
    rename_i hle hmiss
    have hile : i.val ≤ last.val := by scalar_tac
    have hm : ¬ byteMatches hay.val needle.val i.val := by
      simpa [b_post] using hmiss
    refine ⟨by omega, ?_, by omega⟩
    intro k hk
    by_cases hki : k < i.val
    · exact hpre k hki
    · have hki : k = i.val := by omega
      simpa [hki] using hm
  · simp

theorem str_contains_spec (hay needle : Slice U8) :
    valueset.str_contains hay needle = ok (decide (needle.val <:+: hay.val)) := by
  apply eq_ok_of_spec
  unfold valueset.str_contains
  dsimp only
  split
  · rename_i hlong
    have hninf : ¬ needle.val <:+: hay.val := by
      intro h
      have := h.length_le
      scalar_tac
    simp [hninf]
  · rename_i hle
    step
    have hlast : last.val + needle.val.length = hay.val.length := by scalar_tac
    by_cases hpos : 0 < needle.val.length
    · apply WP.spec_mono (contains_loop_spec hay needle last hlast hpos)
      intro b hb
      rw [hb]
      apply decide_eq_decide.mpr
      rw [infix_iff_window]
      constructor
      · rintro ⟨k, hk, hm⟩
        have hbound : k + needle.val.length ≤ hay.val.length := by omega
        exact ⟨k, hbound, (matches_iff_window _ _ _ hbound).mp hm⟩
      · rintro ⟨k, hk, hw⟩
        exact ⟨k, by omega, (matches_iff_window _ _ _ hk).mpr hw⟩
    · have hn : needle.val = [] := List.length_eq_zero_iff.mp (by omega)
      have hs : valueset.starts_at hay 0#usize needle = ok true := by
        apply eq_ok_of_spec
        apply WP.spec_mono (starts_at_spec hay needle 0#usize (by scalar_tac))
        intro b hb
        simpa [byteMatches, hn] using hb
      have hz : (0#usize : Usize) ≤ last := by scalar_tac
      unfold valueset.str_contains_loop
      rw [loop]
      simp [valueset.str_contains_loop.body, hs, hz, hn]

end kanidm_kernel.Solution
