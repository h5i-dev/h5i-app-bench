import SpecAwsResolution
open Aeneas Aeneas.Std
namespace rustfs_kernel.Spec
set_option maxHeartbeats 1000000
set_option linter.unnecessarySimpa false
theorem expansion_pass_nonempty (inner : List Nat → List (List Nat))
    (c : AwsValueContext) (text : List Nat) : ExpansionPass inner c text ≠ [] := by
  apply ExpansionPass.induct inner c (fun s => ExpansionPass inner c s ≠ [])
  · simp [ExpansionPass]
  · intro tail closing balance he hb
    simp [ExpansionPass,he,hb]
  · intro tail closing balance he hb ih
    simp only [ExpansionPass,he,hb,ite_false]
    generalize hrep : (if HasPlaceholder (tail.take closing) then
      let expanded := inner (tail.take closing)
      if expanded=[] ∨ expanded=[tail.take closing] then
        [(36::123::tail).take (closing+3)] else expanded
      else match AwsValues c (tail.take closing) with
        | none => [(36::123::tail).take (closing+3)]
        | some [] => [[]]
        | some values => values) = replacements
    have hn : replacements ≠ [] := by
      rw [←hrep]
      split
      · dsimp only
        split
        · simp
        · rename_i h; exact fun he => h (Or.inl he)
      · split
        · simp
        · simp
        · simp_all
    obtain ⟨replacement,hr⟩ := List.exists_mem_of_ne_nil replacements hn
    obtain ⟨suffix,hs⟩ := List.exists_mem_of_ne_nil _ ih
    intro empty
    have hm : replacement++suffix ∈ replacements.flatMap
        (fun replacement => (ExpansionPass inner c (tail.drop (closing+1))).map (replacement++·)) :=
      List.mem_flatMap.mpr ⟨replacement,hr,List.mem_map.mpr ⟨suffix,hs,rfl⟩⟩
    simpa only [empty,List.not_mem_nil] using hm
  · intro head rest hnot ih
    rw [ExpansionPass.eq_def]
    split
    · simp_all
    · next tail he => exact False.elim (hnot tail (List.cons.inj he).1 (List.cons.inj he).2)
    · next h a hnot2 he =>
        have hh := List.cons.inj he
        rcases hh with ⟨rfl,rfl⟩
        simpa using ih
end rustfs_kernel.Spec
