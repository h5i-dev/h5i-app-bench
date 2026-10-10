import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP

namespace nora_kernel.Solution
set_option maxHeartbeats 2000000
set_option maxRecDepth 4096

@[simp] theorem deref_val {α : Type} (v : alloc.vec.Vec α) : v.deref.val = v.val := by
  simp [alloc.vec.Vec.deref, alloc.vec.Vec.val]
@[simp] theorem deref_length {α : Type} (v : alloc.vec.Vec α) : v.deref.length = v.val.length := by
  simp [Slice.length]

@[simp] theorem nats_length (l : List U8) : (nats l).length = l.length := by simp [nats]
@[simp] theorem nats_drop (l : List U8) (i : Nat) : nats (l.drop i) = (nats l).drop i := by simp [nats]
@[simp] theorem nats_nil : nats [] = [] := rfl
@[simp] theorem nats_cons (x : U8) (l : List U8) : nats (x :: l) = x.val :: nats l := rfl
@[simp] theorem nats_reverse (l : List U8) : nats l.reverse = (nats l).reverse := by simp [nats]
theorem val_injective : Function.Injective (fun x : U8 => x.val) := by
  intro a b h; exact (u8_eq_iff a b).mpr h
@[simp] theorem nats_eq (a b : List U8) : nats a = nats b ↔ a = b :=
  List.map_inj_right val_injective
@[simp] theorem nats_prefix (a b : List U8) : nats a <+: nats b ↔ a <+: b :=
  List.prefix_map_iff_of_injective val_injective
@[simp] theorem nats_suffix (a b : List U8) : nats a <:+ nats b ↔ a <:+ b :=
  List.suffix_map_iff_of_injective val_injective

@[simp] theorem lit_star : lit "*" = [42] := by
  decide +kernel
@[step] theorem star_spec (p : Slice U8) :
    is_star p ⦃ b => b = decide (nats p.val = lit "*") ⦄ := by
  unfold is_star
  dsimp only
  split
  · rename_i h
    have hl : p.val.length = 1 := by scalar_tac
    obtain ⟨x, hx⟩ := List.length_eq_one_iff.mp hl
    step*
    simp only [WP.spec_ok, lit_star, nats, hx, List.map_cons, List.map_nil,
      List.getElem_cons_zero, List.cons.injEq, and_true, u8_eq_iff] at *
    simpa only [i1_post, UScalar.ofNatCore_val_eq]
  · rename_i h
    have hl : p.val.length ≠ 1 := by scalar_tac
    have hn : nats p.val ≠ [42] := by
      intro he; have := congrArg List.length he; simp at this; exact hl this
    simp [lit_star, hn]

 theorem starts_loop_spec (s p : Slice U8) (f i : Usize)
    (hfit : f.val + p.length ≤ s.length) (hi : i.val ≤ p.length) :
    starts_with_at_loop s f p i ⦃ b => b = decide (p.val.drop i.val <+: s.val.drop (f.val + i.val)) ⦄ := by
  induction h : p.length - i.val using Nat.strong_induction_on generalizing i with
  | h n ih =>
    rw [starts_with_at_loop, loop]
    unfold starts_with_at_loop.body
    dsimp only
    simp only [bind_tc_ite, bind_ite]
    split
    · rename_i hc
      have hp : i.val < p.val.length := by scalar_tac
      have hs : f.val + i.val < s.val.length := by scalar_tac
      step*
      split
      · step*
        rw [List.drop_eq_getElem_cons hp, List.drop_eq_getElem_cons hs]
        simp only [WP.spec_ok, Bool.false_eq, decide_eq_false_iff_not, List.cons_prefix_cons]
        intro he
        have heq := he.1
        scalar_tac
      · step*
        apply spec_mono (ih (p.length - x.val) (by scalar_tac) x (by scalar_tac) rfl)
        intro b hb
        rw [List.drop_eq_getElem_cons hp, List.drop_eq_getElem_cons hs]
        simp only [List.cons_prefix_cons]
        have heq : p.val[i.val] = s.val[f.val + i.val] := by scalar_tac
        simp only [heq, true_and]
        simpa only [x_post, Nat.add_assoc] using hb
    · rename_i hc
      have hp : p.length ≤ i.val := by scalar_tac
      simp [List.drop_eq_nil_of_le hp]

@[step] theorem starts_spec (s : Slice U8) (f : Usize) (p : Slice U8)
    (hf : f.val ≤ s.length) :
    starts_with_at s f p ⦃ b => b = decide (p.val <+: s.val.drop f.val) ⦄ := by
  unfold starts_with_at
  step*
  · rename_i hc
    have hn : ¬ p.val <+: s.val.drop f.val := by
      intro h; have := h.length_le; simp only [List.length_drop] at this; scalar_tac
    simp [hn]
  · apply spec_mono (starts_loop_spec s p f 0#usize (by scalar_tac) (by simp))
    intro b hb; simpa using hb

theorem eq_loop_spec (a b : Slice U8) (i : Usize)
    (hlen : a.length = b.length) (hi : i.val ≤ a.length) :
    bytes_eq_loop a b i ⦃ r => r = decide (a.val.drop i.val = b.val.drop i.val) ⦄ := by
  induction h : a.length - i.val using Nat.strong_induction_on generalizing i with
  | h n ih =>
    rw [bytes_eq_loop, loop]
    unfold bytes_eq_loop.body
    dsimp only
    simp only [bind_ite]
    split
    · have ha : i.val < a.val.length := by scalar_tac
      have hb : i.val < b.val.length := by scalar_tac
      step*
      split
      · step*
        rw [List.drop_eq_getElem_cons ha, List.drop_eq_getElem_cons hb]
        simp only [List.cons.injEq, Bool.false_eq, decide_eq_false_iff_not]
        intro he; have := he.1; scalar_tac
      · step*
        apply spec_mono (ih (a.length - x.val) (by scalar_tac) x (by scalar_tac) rfl)
        intro r hr
        rw [List.drop_eq_getElem_cons ha, List.drop_eq_getElem_cons hb]
        have he : a.val[i.val] = b.val[i.val] := by scalar_tac
        simpa only [List.cons.injEq, he, true_and, x_post] using hr
    · step*
      have ha : a.val.length ≤ i.val := by scalar_tac
      have hb : b.val.length ≤ i.val := by scalar_tac
      simp [List.drop_eq_nil_of_le ha, List.drop_eq_nil_of_le hb]

@[step] theorem eq_spec (a b : Slice U8) :
    bytes_eq a b ⦃ r => r = decide (nats a.val = nats b.val) ⦄ := by
  unfold bytes_eq
  dsimp only
  split
  · have hn : a.val ≠ b.val := by intro he; have := congrArg List.length he; scalar_tac
    simp [hn]
  · apply spec_mono (eq_loop_spec a b 0#usize (by scalar_tac) (by simp))
    intro r hr; simpa using hr

@[step] theorem split_loop_spec (s : Slice U8) (sep : U8) (hlt : s.length < Usize.max) :
    split_loop s sep (alloc.vec.Vec.new _) (alloc.vec.Vec.new _) 0#usize
      ⦃ r => (r.1.val.map (·.val), r.2.val) = s.val.foldl (splitStep sep) ([], []) ∧
        r.1.val.length ≤ s.length ∧ r.2.val.length ≤ s.length ⦄ := by
  unfold split_loop
  apply spec_mono (loop_fold2 s.val
    (fun (a : alloc.vec.Vec (alloc.vec.Vec U8)) (b : alloc.vec.Vec U8) => (a.val.map (·.val), b.val))
    (splitStep sep) (fun a b i => a.val.length ≤ i ∧ b.val.length ≤ i)
    _ ?_ (alloc.vec.Vec.new _) (alloc.vec.Vec.new _) 0#usize (by simp) (by simp [vec_new_val]))
  · intro r hr
    simpa [vec_new_val] using hr
  · intro a b i hi hinv
    unfold split_loop.body
    dsimp only
    simp only [bind_ite]
    split
    · step* <;> simp_all [FoldStep2, splitStep, vec_new_val]
      all_goals scalar_tac
    · step*
      simp_all [FoldStep2]
      try scalar_tac

@[step] theorem split_spec (s : Slice U8) (sep : U8) (hlt : s.length < Usize.max) :
    nora_kernel.split s sep ⦃ r => r.val.map (·.val) = s.val.splitOn sep ⦄ := by
  unfold nora_kernel.split
  step as ⟨out, cur, hr, ho, hc⟩
  step*
  simp only [r_post, List.map_append, List.map_cons, List.map_nil]
  have hm := foldl_splitStep sep s.val [] []
  rw [← hr] at hm
  have he : (fun x : U8 => decide (x = sep)) = (fun x => x == sep) := by
    funext x
    apply Bool.eq_iff_iff.mpr
    simp only [decide_eq_true_eq, beq_iff_eq]
  rw [he] at hm
  simpa only [List.nil_append, List.reverse_nil, List.splitOnPPrepend_nil_right, List.splitOn] using hm

theorem split_map_aux (s acc : List U8) (sep : U8) :
    (List.splitOnPPrepend (fun x => x == sep) s acc).map nats =
      List.splitOnPPrepend (fun x => x == sep.val) (nats s) (nats acc) := by
  induction s generalizing acc with
  | nil => simp
  | cons x xs ih =>
    rw [List.splitOnPPrepend_cons_eq_if]
    rw [nats_cons, List.splitOnPPrepend_cons_eq_if]
    have he : (x == sep) = (x.val == sep.val) := by
      apply Bool.eq_iff_iff.mpr
      simp only [beq_iff_eq, u8_eq_iff]
    rw [he]
    split
    · simp only [List.map_cons, nats_reverse, ← List.splitOnPPrepend_nil_right, ih, nats_nil]
    · exact ih _

theorem split_map (s : List U8) :
    (s.splitOn 42#u8).map nats = (nats s).splitOn 42 := by
  simpa only [List.splitOn, List.splitOnP_eq_splitOnPPrepend, nats_nil, UScalar.ofNatCore_val_eq]
    using split_map_aux s [] 42#u8

def findModel (s p : List U8) (i : Nat) : Option Nat :=
  (List.range' i (s.length + 1 - i)).find? (fun k => decide (p <+: s.drop k))

theorem findModel_step (s p : List U8) (i : Nat) (hi : i ≤ s.length) :
    findModel s p i = if p <+: s.drop i then some i else findModel s p (i + 1) := by
  unfold findModel
  rw [show s.length + 1 - i = (s.length - i) + 1 by omega, List.range'_succ]
  simp only [List.find?_cons, Nat.mul_one]
  rw [show s.length + 1 - (i + 1) = s.length - i by omega]
  by_cases h : p <+: s.drop i <;> simp [h]

theorem findModel_none (s p : List U8) (i : Nat) (hi : s.length - i < p.length) :
    findModel s p i = none := by
  apply List.find?_eq_none.mpr
  intro k hk
  have hk := List.mem_range'_1.mp hk
  simp only [decide_eq_true_eq]
  intro hp
  have := hp.length_le
  simp only [List.length_drop] at this
  omega

theorem findModel_some (s p : List U8) (i k : Nat) (h : findModel s p i = some k) :
    i ≤ k ∧ k + p.length ≤ s.length ∧ p <+: s.drop k := by
  have hm := List.mem_of_find?_eq_some h
  have hp := List.find?_some h
  have hk := List.mem_range'_1.mp hm
  simp only [decide_eq_true_eq] at hp
  have := hp.length_le
  simp only [List.length_drop] at this
  have hbound : k ≤ s.length := by omega
  exact ⟨hk.1, by omega, hp⟩

@[step] theorem find_spec (s : Slice U8) (i : Usize) (p : Slice U8)
    (hi : i.val ≤ s.length) (hp : 0 < p.length) :
    find_from s i p ⦃ o => o.map (·.val) = findModel s.val p.val i.val ∧
      ∀ k ∈ o, i.val ≤ k.val ∧ k.val + p.length ≤ s.length ⦄ := by
  induction h : s.length + 1 - i.val using Nat.strong_induction_on generalizing i with
  | h n ih =>
    rw [find_from, find_from_loop, loop]
    unfold find_from_loop.body
    dsimp only
    simp only [bind_ite]
    split
    · step*
      simp -failIfUnchanged only [bind_ite]
      split
      · step as ⟨b, hb⟩
        simp only [bind_ite]
        split
        · step*
          rename_i hbool
          have hpre : p.val <+: s.val.drop i.val := by simpa [hbool] using hb.symm
          rw [findModel_step _ _ _ hi, if_pos hpre]
          simp only [Option.map_some, Option.mem_some_iff, forall_eq]
          constructor
          · trivial
          · intro k hk; subst k; exact ⟨le_refl _, by scalar_tac⟩
        · step as ⟨j, hj⟩
          rename_i hbool
          have hpre : ¬p.val <+: s.val.drop i.val := by simpa [hbool] using hb.symm
          apply spec_mono (ih (s.length + 1 - j.val) (by scalar_tac) j (by scalar_tac) rfl)
          intro o ho
          rw [findModel_step _ _ _ hi, if_neg hpre]
          exact ⟨by simpa only [hj] using ho.1, fun k hk => ⟨by have := (ho.2 k hk).1; scalar_tac, (ho.2 k hk).2⟩⟩
      · step*
        rw [findModel_none _ _ _ (by scalar_tac)]
        simp
    · exfalso; scalar_tac

theorem findModel_rebase (s p : List U8) (i : Nat) (hi : i ≤ s.length) :
    findModel s p i =
      ((List.range (((nats s).drop i).length + 1)).find?
        (fun k => decide (nats p <+: ((nats s).drop i).drop k))).map (i + ·) := by
  unfold findModel
  have hr : List.range' i (s.length + 1 - i) =
      (List.range (s.length - i + 1)).map (i + ·) := by
    rw [List.range_eq_range', List.map_add_range', Nat.add_zero]
    congr 1; omega
  rw [hr, List.find?_map]
  simp only [List.length_drop, nats_length, Function.comp_def, List.drop_drop]
  congr 2
  funext k
  simp only [← nats_drop, nats_prefix, Nat.add_comm]

theorem suffix_at (p s : List U8) (r : Nat) (hr : r ≤ s.length)
    (hp : p.length ≤ s.length - r) :
    (p <:+ s.drop r) ↔ (p <+: s.drop (s.length - p.length)) := by
  have hlen : (s.drop (s.length - p.length)).length = p.length := by
    simp only [List.length_drop]; omega
  rw [suffix_iff_drop, prefix_iff_take]
  simp only [List.length_drop, hlen, le_refl, true_and, List.drop_drop, hp, List.take_length]
  rw [show r + (s.length - r - p.length) = s.length - p.length by omega]
  rw [show List.take p.length (s.drop (s.length - p.length)) = s.drop (s.length - p.length) by
    exact List.take_of_length_le (by omega)]

@[step] theorem parts_loop_spec (parts : Slice (alloc.vec.Vec U8)) (value : Slice U8)
    (r i : Usize) (hr : r.val ≤ value.length) (hi : i.val ≤ parts.length) :
    glob_parts_loop parts value r i ⦃ b => b =
      partsMatch ((parts.val.map (fun p => nats p.val)).drop i.val) i.val
        ((nats value.val).drop r.val) ⦄ := by
  induction h : parts.length - i.val using Nat.strong_induction_on generalizing r i with
  | h n ih =>
    rw [glob_parts_loop, loop]
    unfold glob_parts_loop.body
    dsimp only
    simp only [bind_ite]
    split
    · have hit : i.val < parts.val.length := by scalar_tac
      step as ⟨part, hpart⟩
      subst part
      have hd : (parts.val.map (fun p => nats p.val)).drop i.val =
          nats parts.val[i.val].val :: (parts.val.map (fun p => nats p.val)).drop (i.val + 1) := by
        rw [← List.map_drop, List.drop_eq_getElem_cons hit, List.map_cons, List.map_drop]
      rw [hd, partsMatch]
      split
      · have hpos : 0 < parts.val[i.val].val.length := by scalar_tac
        have hne : nats parts.val[i.val].val ≠ [] := by
          intro he; have := congrArg List.length he
          simp only [nats_length, List.length_nil] at this; omega
        simp only [if_neg hne, bind_ite]
        split
        · have hi0 : i.val = 0 := by scalar_tac
          simp only [if_pos hi0]
          step as ⟨b, hb⟩
          simp only [bind_ite]
          split
          · rename_i hbool
            have hpre : parts.val[i.val].val <+: value.val.drop r.val := by
              simpa [hbool, alloc.vec.Vec.deref, alloc.vec.Vec.val] using hb.symm
            have hpreN : nats parts.val[i.val].val <+: (nats value.val).drop r.val := by
              simpa only [← nats_drop, nats_prefix] using hpre
            have hbound := hpre.length_le
            step as ⟨r', hr'⟩
            step as ⟨i', hi'⟩
            step*
            simp only [if_pos hpreN, nats_length, List.drop_drop]
            apply spec_mono (ih (parts.length - i'.val) (by scalar_tac) r' i'
              (by simp only [List.length_drop] at hbound; scalar_tac) (by scalar_tac) rfl)
            intro b hb
            simpa only [hr', hi', alloc.vec.Vec.len_val] using hb
          · rename_i hbool
            have hpre : ¬parts.val[i.val].val <+: value.val.drop r.val := by
              simpa [hbool, alloc.vec.Vec.deref, alloc.vec.Vec.val] using hb.symm
            have hpreN : ¬nats parts.val[i.val].val <+: (nats value.val).drop r.val := by
              simpa only [← nats_drop, nats_prefix] using hpre
            step*
            all_goals simp only [if_neg hpreN]
        · have hi0 : i.val ≠ 0 := by scalar_tac
          simp only [if_neg hi0]
          step as ⟨last, hlast⟩
          simp only [bind_ite]
          split
          · have he : (parts.val.map (fun p => nats p.val)).drop (i.val + 1) = [] := by
              apply List.drop_eq_nil_of_le
              simp only [List.length_map]
              scalar_tac
            simp only [if_pos he]
            step as ⟨remaining, hremaining⟩
            simp only [bind_ite]
            split
            · have hn : ¬parts.val[i.val].val <:+ value.val.drop r.val := by
                intro hs; have := hs.length_le
                simp only [List.length_drop] at this
                scalar_tac
              step*
              all_goals simp only [← nats_drop, nats_suffix, hn, decide_false]
            · have hfit : parts.val[i.val].val.length ≤ value.val.length - r.val := by scalar_tac
              step as ⟨f, hf⟩
              step as ⟨b, hb⟩
              step*
              have hs := suffix_at parts.val[i.val].val value.val r.val hr hfit
              have hb' : b = decide (parts.val[i.val].val <+:
                  value.val.drop (value.val.length - parts.val[i.val].val.length)) := by
                apply Bool.eq_iff_iff.mpr
                have hbiff := Bool.eq_iff_iff.mp hb
                simpa only [deref_val, hf, Slice.len_val, alloc.vec.Vec.len_val,
                  alloc.vec.Vec.length, Slice.length, decide_eq_true_eq] using hbiff
              simpa only [← nats_drop, nats_suffix, hs] using hb'
          · have he : (parts.val.map (fun p => nats p.val)).drop (i.val + 1) ≠ [] := by
              intro he
              have hl := List.drop_eq_nil_iff.mp he
              simp only [List.length_map] at hl
              scalar_tac
            simp only [if_neg he]
            step with (find_spec value r parts.val[i.val].deref hr
              (by simpa only [deref_length] using hpos)) as ⟨o, ho, hbounds⟩
            simp only [deref_val, deref_length] at ho hbounds
            rw [findModel_rebase _ _ _ hr] at ho
            cases o with
            | none =>
              have hf : (List.range (((nats value.val).drop r.val).length + 1)).find?
                  (fun k => decide (nats parts.val[i.val].val <+: ((nats value.val).drop r.val).drop k)) = none := by
                apply Option.map_eq_none_iff.mp
                exact ho.symm
              simp only [hf]
              step*
            | some pos =>
              obtain ⟨k, hk, hpos⟩ := Option.map_eq_some_iff.mp ho.symm
              simp only [hk]
              have hfit := (hbounds pos (by simp)).2
              step as ⟨r', hr'⟩
              step as ⟨i', hi'⟩
              step*
              apply spec_mono (ih (parts.length - i'.val) (by scalar_tac) r' i'
                (by scalar_tac) (by scalar_tac) rfl)
              intro b hb
              simpa only [hr', hi', alloc.vec.Vec.len_val, List.drop_drop, nats_length,
                ← hpos, Nat.add_assoc] using hb
      · have he : nats parts.val[i.val].val = [] := by
          have hz : parts.val[i.val].val.length = 0 := by scalar_tac
          simp [List.length_eq_zero_iff.mp hz]
        simp only [if_pos he]
        step as ⟨i', hi'⟩
        step*
        apply spec_mono (ih (parts.length - i'.val) (by scalar_tac) r i' hr (by scalar_tac) rfl)
        intro b hb
        simpa only [hi'] using hb
    · step*
      have he : parts.val.length ≤ i.val := by scalar_tac
      simp [List.drop_eq_nil_of_le (by simpa using he : (parts.val.map (fun p => nats p.val)).length ≤ i.val), partsMatch]

@[step] theorem parts_spec (parts : Slice (alloc.vec.Vec U8)) (value : Slice U8) :
    glob_parts parts value ⦃ b => b = partsMatch (parts.val.map (fun p => nats p.val)) 0 (nats value.val) ⦄ := by
  unfold glob_parts
  apply spec_mono (parts_loop_spec parts value 0#usize 0#usize (by simp) (by simp))
  intro b hb; simpa using hb

theorem glob_match_spec (pattern v : Slice U8) (hlt : pattern.length < Usize.max) :
    glob_match pattern v = ok (globSpec (nats pattern.val) (nats v.val)) := by
  apply eq_ok_of_spec
  unfold glob_match
  step as ⟨b, hb⟩
  split
  · rename_i hbool
    have hs : nats pattern.val = lit "*" := by simpa [hbool] using hb.symm
    step*
    simp [globSpec, hs]
  · rename_i hbool
    have hs : nats pattern.val ≠ lit "*" := by simpa [hbool] using hb.symm
    step as ⟨parts, hparts⟩
    have hm : parts.val.map (fun p => nats p.val) = (nats pattern.val).splitOn 42 := by
      rw [← split_map, ← hparts, List.map_map]
      rfl
    have hlen := congrArg List.length hm
    simp only [List.length_map] at hlen
    split
    · have hl : ((nats pattern.val).splitOn 42).length = 1 := by scalar_tac
      simp only [globSpec, if_neg hs, if_pos hl]
      step*
    · have hl : ((nats pattern.val).splitOn 42).length ≠ 1 := by scalar_tac
      simp only [globSpec, if_neg hs, if_neg hl]
      step as ⟨b, hb⟩
      simpa only [deref_val, hm] using hb

end nora_kernel.Solution
