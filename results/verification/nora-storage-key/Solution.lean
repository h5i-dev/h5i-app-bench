import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP

namespace nora_kernel.Solution

@[step] theorem contains_byte_spec (k : Slice U8) (c : U8) :
    validation.contains_byte k c ⦃ b => b = k.val.any (fun x => decide (x = c)) ⦄ := by
  unfold validation.contains_byte validation.contains_byte_loop
  h5i_search_any k.val (fun x => decide (x = c))

@[step] theorem first_non_ascii_spec (k : Slice U8) :
    validation.first_non_ascii k ⦃ b => b = k.val.any (fun x => decide (128 ≤ x.val)) ⦄ := by
  unfold validation.first_non_ascii validation.first_non_ascii_loop
  h5i_search_any k.val (fun x => decide (128 ≤ x.val))

def GoodSeg (s : List Nat) : Prop := s ≠ [46] ∧ s ≠ [46, 46]

def piece (l : List Nat) (s i : Nat) : List Nat := (l.drop s).take (i - s)

theorem piece_length (l : List Nat) (s i : Nat) (_hs : s ≤ i) (hi : i ≤ l.length) :
    (piece l s i).length = i - s := by
  simp [piece]
  omega

theorem piece_get (l : List Nat) (s i j : Nat) (hj : j < i - s) :
    (piece l s i)[j]? = l[s + j]? := by
  simp [piece, hj, List.getElem?_drop]

theorem index_of_nats (k : Slice U8) (i : Usize) (c : U8)
    (h : (nats k.val)[i.val]? = some c.val) : k.index_usize i = ok c := by
  simp only [nats, List.getElem?_map, Option.map_eq_some_iff] at h
  obtain ⟨x, hx, he⟩ := h
  have : x = c := (u8_eq_iff x c).2 he
  subst x
  simp [Slice.index_usize, Slice.getElem?_Usize_eq, hx]

theorem dot_boundary_good (k : Slice U8) (s i s' i' : Usize)
    (hs : s.val ≤ i.val) (hi : i.val ≤ k.val.length)
    (hb : i.val = k.val.length ∨ k.index_usize i = ok 47#u8)
    (hr : validation.has_dot_segment_loop.body k s i = ok (.cont (s', i'))) :
    GoodSeg (piece (nats k.val) s.val i.val) := by
  have hlen := piece_length (nats k.val) s.val i.val hs (by simpa [nats] using hi)
  constructor
  · intro he
    have hn : i.val - s.val = 1 := by simpa [he] using hlen.symm
    have hfirst : k.index_usize s = ok 46#u8 := by
      apply index_of_nats
      have hg := piece_get (nats k.val) s.val i.val 0 (by omega)
      simpa [he] using hg.symm
    have hsub : i - s = ok 1#usize := by
      apply eq_ok_of_spec
      step*
    have hle : i ≤ k.len := by scalar_tac
    unfold validation.has_dot_segment_loop.body at hr
    dsimp only at hr
    simp only [hle, if_true, hsub, hfirst] at hr
    rcases hb with hb | hb
    · have heq : i = k.len := by scalar_tac
      simp [heq] at hr
    · simp [hb] at hr
  · intro he
    have hn : i.val - s.val = 2 := by simpa [he] using hlen.symm
    have hfirst : k.index_usize s = ok 46#u8 := by
      apply index_of_nats
      have hg := piece_get (nats k.val) s.val i.val 0 (by omega)
      simpa [he] using hg.symm
    have hsub : i - s = ok 2#usize := by
      apply eq_ok_of_spec
      step*
    have hplus : s + 1#usize ⦃ j => j.val = s.val + 1 ⦄ := by
      step*
    obtain ⟨j, hj, hjval⟩ := (spec_equiv_exists _ _).1 hplus
    have hsecond : k.index_usize j = ok 46#u8 := by
      apply index_of_nats
      have hg := piece_get (nats k.val) s.val i.val 1 (by omega)
      simpa [he, hjval] using hg.symm
    have hle : i ≤ k.len := by scalar_tac
    unfold validation.has_dot_segment_loop.body at hr
    dsimp only at hr
    simp only [hle, if_true, hsub, hfirst, hj] at hr
    rcases hb with hb | hb
    · have heq : i = k.len := by scalar_tac
      simp [heq, hsecond] at hr
    · simp [hb, hsecond] at hr

theorem dot_done_false (k : Slice U8) (s i : Usize)
    (hr : validation.has_dot_segment_loop.body k s i = ok (.done false)) :
    k.val.length < i.val := by
  unfold validation.has_dot_segment_loop.body at hr
  h5i_invert hr
  all_goals try simp only [ControlFlow.done.injEq, Bool.true_eq_false] at hr
  all_goals scalar_tac

theorem dot_cont_shape (k : Slice U8) (s i s' i' : Usize)
    (hr : validation.has_dot_segment_loop.body k s i = ok (.cont (s', i'))) :
    i'.val = i.val + 1 ∧
      ((s'.val = i'.val ∧ (i.val = k.val.length ∨ k.index_usize i = ok 47#u8)) ∨
       (s'.val = s.val ∧ i.val < k.val.length ∧ (nats k.val)[i.val]? ≠ some 47)) := by
  unfold validation.has_dot_segment_loop.body at hr
  h5i_invert hr
  all_goals simp only [ControlFlow.cont.injEq, Prod.mk.injEq] at hr
  all_goals rcases hr with ⟨rfl, rfl⟩
  all_goals refine ⟨by h5i_arith, ?_⟩
  all_goals first
    | (left; refine ⟨rfl, Or.inl ?_⟩;
        have heq : i = k.len := (by assumption);
        simpa only [Slice.len_val] using congrArg UScalar.val heq)
    | (left; exact ⟨rfl, Or.inr (by simpa only [hc_2] using hi3)⟩)
    | (right; refine ⟨rfl, by scalar_tac, ?_⟩; intro he;
        have hidx := index_of_nats k i 47#u8 he;
        exact hc_2 (result_ok_inj (hi3.symm.trans hidx)))

def SegmentsGood (l : List Nat) : Prop := ∀ seg ∈ l.splitOn 47, GoodSeg seg

/-- The completed segments are safe; the pending segment starts at `s`. -/
def ScanInv (l : List Nat) (s i : Nat) : Prop :=
  s ≤ i ∧ i ≤ l.length + 1 ∧
    if i ≤ l.length then
      ∃ out : List (List Nat),
        (∀ seg ∈ out, GoodSeg seg) ∧
        l.splitOn 47 = out ++ List.splitOnPPrepend (· == 47) (l.drop i) (piece l s i).reverse
    else SegmentsGood l

theorem piece_succ (l : List Nat) (s i : Nat) (hs : s ≤ i) (hi : i < l.length) :
    piece l s (i + 1) = piece l s i ++ [l[i]] := by
  unfold piece
  rw [show i + 1 - s = (i - s) + 1 by omega, List.take_add_one]
  rw [List.getElem?_drop, show s + (i - s) = i by omega,
    List.getElem?_eq_getElem hi]
  rfl

theorem scan_boundary (l : List Nat) (s i : Nat)
    (hI : ScanInv l s i) (hi : i ≤ l.length)
    (hb : i = l.length ∨ l[i]? = some 47) (hg : GoodSeg (piece l s i)) :
    ScanInv l (i + 1) (i + 1) := by
  obtain ⟨hs, hle, hI⟩ := hI
  simp only [if_pos hi] at hI
  obtain ⟨out, hout, heq⟩ := hI
  refine ⟨le_refl _, by omega, ?_⟩
  by_cases hend : i = l.length
  · simp only [show ¬i + 1 ≤ l.length by omega, if_false]
    have hfull : l.splitOn 47 = out ++ [piece l s i] := by
      simpa [hend] using heq
    intro seg hseg
    rw [hfull] at hseg
    rcases List.mem_append.1 hseg with hseg | hseg
    · exact hout seg hseg
    · simpa using (List.mem_singleton.1 hseg ▸ hg)
  · have hlt : i < l.length := by omega
    have hx : l[i] = 47 := by
      rcases hb with hb | hb
      · contradiction
      · simpa [List.getElem?_eq_getElem hlt] using hb
    simp only [show i + 1 ≤ l.length by omega, if_true]
    refine ⟨out ++ [piece l s i], ?_, ?_⟩
    · intro seg hseg
      rcases List.mem_append.1 hseg with hseg | hseg
      · exact hout seg hseg
      · simpa using (List.mem_singleton.1 hseg ▸ hg)
    · rw [List.drop_eq_getElem_cons hlt, hx,
        List.splitOnPPrepend_cons_pos (by decide)] at heq
      simpa [piece, List.append_assoc] using heq

theorem scan_byte (l : List Nat) (s i : Nat)
    (hI : ScanInv l s i) (hi : i < l.length) (hx : l[i]? ≠ some 47) :
    ScanInv l s (i + 1) := by
  obtain ⟨hs, hle, hI⟩ := hI
  simp only [if_pos (show i ≤ l.length by omega)] at hI
  obtain ⟨out, hout, heq⟩ := hI
  refine ⟨by omega, by omega, ?_⟩
  simp only [show i + 1 ≤ l.length by omega, if_true]
  refine ⟨out, hout, ?_⟩
  have hx' : (l[i] == 47) = false := by
    simpa [List.getElem?_eq_getElem hi] using hx
  rw [List.drop_eq_getElem_cons hi,
    List.splitOnPPrepend_cons_neg (p := fun x : Nat => x == 47) hx'] at heq
  simpa only [piece_succ l s i hs hi, List.reverse_append, List.reverse_singleton,
    List.singleton_append] using heq

theorem no_dot_segments (k : Slice U8) (h : validation.has_dot_segment k = ok false) :
    SegmentsGood (nats k.val) := by
  unfold validation.has_dot_segment validation.has_dot_segment_loop at h
  apply loop_false_all
    (body := fun (s, i) => validation.has_dot_segment_loop.body k s i)
    (Inv := fun (s, i) => ScanInv (nats k.val) s.val i.val)
    (μ := fun (_, i) => k.val.length + 1 - i.val)
    (x := (0#usize, 0#usize)) (h := h)
  case hstep =>
    rintro ⟨s, i⟩ r hI hr
    cases r with
    | done b =>
      intro hb
      subst b
      have hi := dot_done_false k s i hr
      obtain ⟨_, _, hI⟩ := hI
      simpa [nats, show ¬i.val ≤ k.val.length by omega] using hI
    | cont st =>
      obtain ⟨s', i'⟩ := st
      obtain ⟨hinc, hb | hx⟩ := dot_cont_shape k s i s' i' hr
      · obtain ⟨hstart, hb⟩ := hb
        have hi : i.val ≤ k.val.length := by
          rcases hb with hb | hb
          · omega
          · obtain ⟨hlt, _⟩ := slice_index_ok hb
            omega
        have hgood := dot_boundary_good k s i s' i' hI.1 hi hb hr
        have hb' : i.val = (nats k.val).length ∨ (nats k.val)[i.val]? = some 47 := by
          rcases hb with hb | hb
          · exact Or.inl (by simpa [nats] using hb)
          · obtain ⟨hlt, he⟩ := slice_index_ok hb
            right
            simp [nats, List.getElem?_map, List.getElem?_eq_getElem hlt, he]
        have hnext := scan_boundary (nats k.val) s.val i.val hI
          (by simpa [nats] using hi) hb' hgood
        refine ⟨?_, ?_⟩
        · simpa [hstart, hinc] using hnext
        · dsimp only
          omega
      · obtain ⟨hstart, hi, hx⟩ := hx
        have hnext := scan_byte (nats k.val) s.val i.val hI
          (by simpa [nats] using hi) hx
        refine ⟨?_, by dsimp only; omega⟩
        simpa [hstart, hinc] using hnext
  · simp [ScanInv, piece]
    exact ⟨[], by simp, by simp [List.splitOn_eq_splitOnP]⟩

theorem storage_key_safe (k : Slice U8) (h : validation.validate_storage_key k = ok (.Ok ())) :
    SafeKey (nats k.val) := by
  unfold validation.validate_storage_key at h
  h5i_invert h
  have hascii := post_of_ok (first_non_ascii_spec k) hb
  have hzero := post_of_ok (contains_byte_spec k 0#u8) hb1
  have hback := post_of_ok (contains_byte_spec k 92#u8) hb3
  have hb4false : b4 = false := by cases b4 <;> simp_all
  have hdot := no_dot_segments k (by simpa [hb4false] using hb4)
  unfold SafeKey
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩
  · intro he
    have hlen : k.val.length = 0 := by
      have := congrArg List.length he
      simpa [nats] using this
    scalar_tac
  · simp only [nats, List.all_map, List.all_eq_true]
    intro c hc
    have hn : k.val.any (fun x => decide (128 ≤ x.val)) = false := by
      cases b <;> simp_all
    have := (List.any_eq_false.1 hn) c hc
    simpa using this
  · simp only [nats, List.mem_map]
    rintro ⟨c, hc, he⟩
    have hn : k.val.any (fun x => decide (x = 0#u8)) = false := by
      cases b1 <;> simp_all
    have hne := (List.any_eq_false.1 hn) c hc
    have heq : c = 0#u8 := by scalar_tac
    simp [heq] at hne
  · simp only [nats, List.mem_map]
    rintro ⟨c, hc, he⟩
    have hn : k.val.any (fun x => decide (x = 92#u8)) = false := by
      cases b3 <;> simp_all
    have hne := (List.any_eq_false.1 hn) c hc
    have heq : c = 92#u8 := by scalar_tac
    simp [heq] at hne
  · intro he
    have hget : (nats k.val)[0]? = some 47 := by simpa only [List.head?_eq_getElem?] using he
    have heq := index_of_nats k 0#usize 47#u8 hget
    exact hc_4 (result_ok_inj (hi2.symm.trans heq))
  · have hdotlit : lit "." = [46] := by decide +kernel
    have hdotdotlit : lit ".." = [46, 46] := by decide +kernel
    simpa only [SegmentsGood, GoodSeg, hdotlit, hdotdotlit] using hdot

end nora_kernel.Solution
