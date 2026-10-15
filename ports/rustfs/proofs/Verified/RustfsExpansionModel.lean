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
theorem placeholder_tail (head : Nat) (rest : List Nat)
    (h : HasPlaceholder (head::rest)=false) : HasPlaceholder rest=false := by
  rw [HasPlaceholder.eq_def] at h
  split at h
  · contradiction
  · contradiction
  · next other tail hn he =>
      rcases List.cons.inj he with ⟨rfl,rfl⟩
      exact h

theorem expansion_literal (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (text : List Nat) (h : HasPlaceholder text=false) : ExpansionPass inner c text=[text] := by
  induction text using ExpansionPass.induct inner c with
  | case1 => simp [ExpansionPass]
  | case2 tail closing balance he hb => simp [HasPlaceholder] at h
  | case3 tail closing balance he hb ih => simp [HasPlaceholder] at h
  | case4 head rest hnot ih =>
    have hr := ih (placeholder_tail head rest h)
    rw [ExpansionPass.eq_def]
    split
    · simp_all
    · next tail he => exact False.elim (hnot tail (List.cons.inj he).1 (List.cons.inj he).2)
    · next other tail hn he =>
      rcases List.cons.inj he with ⟨rfl,rfl⟩
      simp [hr]
theorem expansion_cons (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (head : Nat) (rest : List Nat)
    (hn : ∀ tail, head = 36 → rest = 123::tail → False) :
    ExpansionPass inner c (head::rest) = (ExpansionPass inner c rest).map (head::·) := by
  rw [ExpansionPass.eq_def]
  split
  · contradiction
  · next tail he => exact False.elim (hn tail (List.cons.inj he).1 (List.cons.inj he).2)
  · next other tail hnot he =>
      rcases List.cons.inj he with ⟨rfl,rfl⟩
      rfl

theorem expansion_pre (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (pre tail : List Nat) (h : HasPlaceholder pre=false) :
    ExpansionPass inner c (pre ++ 36::123::tail) =
      (ExpansionPass inner c (36::123::tail)).map (pre++·) := by
  induction pre with
  | nil => simp
  | cons head rest ih =>
    have hr := placeholder_tail head rest h
    have hn : ∀ suffix, head=36 → rest ++ 36::123::tail=123::suffix → False := by
      intro suffix hh he
      subst head
      cases rest with
      | nil => simp at he
      | cons x xs =>
        have hx : x=123 := (List.cons.inj he).1
        subst x
        simp [HasPlaceholder] at h
    rw [List.cons_append, expansion_cons inner c head _ hn, ih hr]
    simp [List.map_map, Function.comp_def]
theorem placeholder_false_iff (text : List Nat) :
    HasPlaceholder text=false ↔ ∀ k, ¬ (text[k]?=some 36 ∧ text[k+1]?=some 123) := by
  induction text with
  | nil => simp [HasPlaceholder]
  | cons head rest ih =>
    constructor
    · intro h k
      cases k with
      | zero =>
        intro hp
        have hh : head=36 := by simpa using hp.1
        subst head
        cases rest with
        | nil => simp at hp
        | cons x xs =>
          have hx : x=123 := by simpa using hp.2
          subst x
          simp [HasPlaceholder] at h
      | succ k =>
        have ht := ih.mp (placeholder_tail head rest h) k
        simpa [Nat.add_assoc] using ht
    · intro h
      by_cases hh : head=36
      · subst head
        cases rest with
        | nil => rfl
        | cons x xs =>
          by_cases hx : x=123
          · subst x; exact False.elim (h 0 (by simp))
          · have hr : HasPlaceholder (x::xs)=false := ih.mpr (by
              intro k
              simpa [Nat.add_assoc] using h (k+1))
            simpa [HasPlaceholder,hx] using hr
      · have hr : HasPlaceholder rest=false := ih.mpr (by
          intro k
          simpa [Nat.add_assoc] using h (k+1))
        simpa [HasPlaceholder,hh] using hr
end rustfs_kernel.Spec
