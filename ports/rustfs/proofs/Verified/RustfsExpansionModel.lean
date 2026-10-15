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
theorem resume_append (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (pre post : List Nat) :
    ResumeAlternatives inner c (pre++post) pre.length =
      (ExpansionPass inner c post).map (pre++·) := by
  simp [ResumeAlternatives]
theorem resume_literal (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (text : List Nat) (resume : Nat) (hm : HasPlaceholder (text.drop resume)=false) :
    ResumeAlternatives inner c text resume=[text] := by
  simp [ResumeAlternatives,expansion_literal inner c _ hm]
theorem resume_wrapped (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (pre inserted post : List Nat) :
    ResumeAlternatives inner c (pre++inserted++post) (pre.length+inserted.length) =
      (ExpansionPass inner c post).map (fun suffix => pre++inserted++suffix) := by
  simpa [List.append_assoc] using resume_append inner c (pre++inserted) post
theorem expansion_marker (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (tail : List Nat) (closing : Nat) (hc : ClosingTail tail 1=(closing,0)) :
    ExpansionPass inner c (36::123::tail) =
      (PlaceholderAlternatives inner c (tail.take closing)
        ((36::123::tail).take (closing+3))).flatMap (fun replacement =>
          (ExpansionPass inner c (tail.drop (closing+1))).map (replacement++·)) := by
  simp only [ExpansionPass,hc,ne_eq,not_true_eq_false,ite_false,PlaceholderAlternatives]

 theorem expansion_unbalanced (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (pre tail : List Nat) (closing balance : Nat) (hn : HasPlaceholder pre=false)
    (hc : ClosingTail tail 1=(closing,balance)) (hb : balance ≠ 0) :
    ExpansionPass inner c (pre++36::123::tail)=[pre++36::123::tail] := by
  rw [expansion_pre inner c pre tail hn]
  simp [ExpansionPass,hc,hb]
theorem resume_marker (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (pre middle tail : List Nat) (hm : HasPlaceholder middle=false) :
    ResumeAlternatives inner c (pre++middle++36::123::tail) pre.length =
      (ExpansionPass inner c (36::123::tail)).map (fun suffix => pre++middle++suffix) := by
  rw [List.append_assoc,resume_append,expansion_pre inner c middle tail hm]
  simp [List.map_map,Function.comp_def,List.append_assoc]
theorem closing_tail_bound (text : List Nat) (balance : Nat) :
    (ClosingTail text balance).1 ≤ text.length ∧
    (balance ≠ 0 → (ClosingTail text balance).2=0 → (ClosingTail text balance).1 < text.length) := by
  induction text generalizing balance with
  | nil =>
    by_cases hb : balance=0 <;> simp [ClosingTail,hb]
  | cons head rest ih =>
    by_cases hb : balance=0
    · simp [ClosingTail,hb]
    · simp only [ClosingTail,hb,ite_false]
      generalize hnext : (if head=123 then balance+1 else if head=125 then balance-1 else balance) = next
      by_cases hn : next=0
      · simp [hn]
      · simp only [hn,ite_false,Prod.fst,Prod.snd,List.length_cons]
        obtain ⟨hl,hs⟩ := ih next
        constructor
        · omega
        · intro _ he
          have ht := hs hn he
          omega
end rustfs_kernel.Spec
