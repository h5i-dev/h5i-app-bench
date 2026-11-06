import Verified.Lockout
/-!
# `merge_ranges` keeps the covered set
-/
open Aeneas Aeneas.Std Result defguard_kernel defguard_kernel.Spec
open H5iAppLib

namespace defguard_kernel.Verified

/-- Sorted by start. -/
def SortedStart (l : List ranges.Range) : Prop := l.Pairwise (fun a b => a.start.val ≤ b.start.val)

theorem insert_loop0_ok {v : alloc.vec.Vec ranges.Range} {r : ranges.Range} {res0 : alloc.vec.Vec ranges.Range}
    {i0 : Usize} {y : ranges.Range × alloc.vec.Vec ranges.Range × Usize}
    (hres0 : res0.val = v.val.take i0.val) (hpre : ∀ j (hj : j < i0.val) (hjl : j < v.val.length), v.val[j].start.val ≤ r.start.val)
    (hi0 : i0.val ≤ v.val.length)
    (h : ranges.insert_by_start_loop0 v r res0 i0 = ok y) :
    y.1 = r ∧ y.2.2.val ≤ v.val.length ∧ y.2.1.val = v.val.take y.2.2.val ∧
      (∀ j (hj : j < y.2.2.val) (hjl : j < v.val.length), v.val[j].start.val ≤ r.start.val) ∧
      (∀ hl : y.2.2.val < v.val.length, r.start.val < v.val[y.2.2.val].start.val) := by
  unfold ranges.insert_by_start_loop0 at h
  refine H5iAppLib.loop_idx_ok _ (fun x => x.2) v.val.length
    (fun x => x.1.val = v.val.take x.2.val ∧ ∀ j (hj : j < x.2.val) (hjl : j < v.val.length), v.val[j].start.val ≤ r.start.val)
    (fun y => y.1 = r ∧ y.2.2.val ≤ v.val.length ∧ y.2.1.val = v.val.take y.2.2.val ∧
      (∀ j (hj : j < y.2.2.val) (hjl : j < v.val.length), v.val[j].start.val ≤ r.start.val) ∧
      (∀ hl : y.2.2.val < v.val.length, r.start.val < v.val[y.2.2.val].start.val))
    ?_ (res0, i0) y ⟨hres0, hpre⟩ hi0 h
  rintro ⟨res, i⟩ rr ⟨hres, hp⟩ hi hb
  try simp only [] at hres hp hi
  unfold ranges.insert_by_start_loop0.body at hb
  h5i_invert hb
  · have hl : i.val < v.val.length := by scalar_tac
    rw [vec_index_eq _ _ hl] at hr1
    have e := (H5iAppLib.Result.ok.inj hr1); subst e
    have hv := push_ok_val hres1
    have hk := H5iAppLib.add_ok_val hi2
    simp only [UScalar.ofNatCore_val_eq] at hk
    refine ⟨⟨?_, fun j hj hjl => ?_⟩, by simp only []; omega, by simp only []; omega⟩
    · simp only [hv, hres, hk, List.take_add_one, List.getElem?_eq_getElem hl, Option.toList_some]
    · simp only [hk] at hj
      rcases Nat.lt_or_ge j i.val with hji | hji
      · exact hp j hji hjl
      · have : j = i.val := by omega
        subst this; scalar_tac
  · have hl : i.val < v.val.length := by scalar_tac
    rw [vec_index_eq _ _ hl] at hr1
    have e := (H5iAppLib.Result.ok.inj hr1); subst e
    exact ⟨rfl, hi, hres, hp, fun _ => by scalar_tac⟩
  · exact ⟨rfl, hi, hres, hp, fun hl => by scalar_tac⟩

theorem insert_loop1_ok {v res0 res : alloc.vec.Vec ranges.Range} {i0 : Usize}
    (hi0 : i0.val ≤ v.val.length)
    (h : ranges.insert_by_start_loop1 v res0 i0 = ok res) : res.val = res0.val ++ v.val.drop i0.val := by
  unfold ranges.insert_by_start_loop1 at h
  refine H5iAppLib.loop_idx_ok _ (fun x => x.2) v.val.length
    (fun x => x.1.val ++ v.val.drop x.2.val = res0.val ++ v.val.drop i0.val)
    (fun y => y.val = res0.val ++ v.val.drop i0.val) ?_ (res0, i0) res rfl hi0 h
  rintro ⟨acc, i⟩ rr hinv hi hb
  try simp only [] at hinv hi
  unfold ranges.insert_by_start_loop1.body at hb
  h5i_invert hb
  · have hl : i.val < v.val.length := by scalar_tac
    rw [vec_index_eq _ _ hl] at hr
    have e := (H5iAppLib.Result.ok.inj hr); subst e
    have hv := push_ok_val hres1
    have hk := H5iAppLib.add_ok_val hi2
    simp only [UScalar.ofNatCore_val_eq] at hk
    refine ⟨?_, by simp only []; omega, by simp only []; omega⟩
    simp only [hv, hk, List.append_assoc, List.singleton_append]
    rw [← List.drop_eq_getElem_cons hl]; exact hinv
  · simp only []
    have : v.val.drop i.val = [] := List.drop_eq_nil_of_le (by scalar_tac)
    rw [this] at hinv; simpa using hinv

/-- `insert_by_start` puts `r` after the ranges that start no later. -/
theorem insert_by_start_ok {v res : alloc.vec.Vec ranges.Range} {r : ranges.Range}
    (h : ranges.insert_by_start v r = ok res) :
    ∃ i ≤ v.val.length, res.val = v.val.take i ++ r :: v.val.drop i ∧
      (∀ j (hj : j < i) (hjl : j < v.val.length), v.val[j].start.val ≤ r.start.val) ∧
      (∀ hl : i < v.val.length, r.start.val < v.val[i].start.val) := by
  unfold ranges.insert_by_start at h
  obtain ⟨⟨r1, res1, i⟩, h1, h2⟩ := H5iAppLib.bind_tc_eq_ok.1 h
  have := insert_loop0_ok (res0 := alloc.vec.Vec.new ranges.Range) (i0 := 0#usize) (by simp) (by simp) (by simp) h1
  obtain ⟨rfl, hil, hres1, hp, hnext⟩ := this
  try simp only [] at h2
  obtain ⟨res2, h3, h4⟩ := H5iAppLib.bind_tc_eq_ok.1 h2
  have hv := push_ok_val h3
  have hf := insert_loop1_ok hil h4
  refine ⟨i.val, hil, ?_, hp, hnext⟩
  rw [hf, hv, hres1]; simp

theorem sorted_insert {l : List ranges.Range} {r : ranges.Range} {i : Nat} (hs : SortedStart l) (hil : i ≤ l.length)
    (hpre : ∀ j (hj : j < i) (hjl : j < l.length), l[j].start.val ≤ r.start.val)
    (hnext : ∀ hl : i < l.length, r.start.val < l[i].start.val) :
    SortedStart (l.take i ++ r :: l.drop i) := by
  unfold SortedStart at *
  have hsplit := hs
  rw [← List.take_append_drop i l, List.pairwise_append] at hsplit
  obtain ⟨ht, hd, hcross⟩ := hsplit
  rw [List.pairwise_append]
  refine ⟨ht, ?_, ?_⟩
  · rw [List.pairwise_cons]
    refine ⟨fun b hb => ?_, hd⟩
    have hlt : i < l.length := by
      rcases Nat.lt_or_ge i l.length with h | h
      · exact h
      · rw [List.drop_eq_nil_of_le h] at hb; cases hb
    have h0 := hnext hlt
    rw [List.drop_eq_getElem_cons hlt] at hb hd
    rcases List.mem_cons.1 hb with rfl | hb'
    · omega
    · have := (List.pairwise_cons.1 hd).1 b hb'; omega
  · intro a ha b hb
    obtain ⟨j, hj, rfl⟩ := List.getElem_of_mem ha
    have hjl : j < l.length := by simp at hj; omega
    have hjr : (l.take i)[j].start.val ≤ r.start.val := by
      rw [List.getElem_take]; exact hpre j (by simp at hj; omega) hjl
    rcases List.mem_cons.1 hb with rfl | hb'
    · exact hjr
    · exact hcross _ (List.getElem_mem hj) b hb'

theorem mem_insert_iff {l : List ranges.Range} {r x : ranges.Range} {i : Nat} :
    x ∈ l.take i ++ r :: l.drop i ↔ x = r ∨ x ∈ l := by
  constructor
  · intro h
    rcases List.mem_append.1 h with h | h
    · exact Or.inr (List.mem_of_mem_take h)
    · rcases List.mem_cons.1 h with h | h
      · exact Or.inl h
      · exact Or.inr (List.mem_of_mem_drop h)
  · rintro (rfl | h)
    · exact List.mem_append_right _ (List.mem_cons_self)
    · rw [← List.take_append_drop i l] at h
      rcases List.mem_append.1 h with h | h
      · exact List.mem_append_left _ h
      · exact List.mem_append_right _ (List.mem_cons_of_mem _ h)

/-- `sort_by_start`: sorted, with the same ranges. -/
theorem sort_by_start_ok {v out : alloc.vec.Vec ranges.Range} (h : ranges.sort_by_start v = ok out) :
    SortedStart out.val ∧ ∀ x, x ∈ out.val ↔ x ∈ v.val := by
  unfold ranges.sort_by_start ranges.sort_by_start_loop at h
  refine H5iAppLib.loop_idx_ok _ (fun x => x.2) v.val.length
    (fun x => SortedStart x.1.val ∧ ∀ y, y ∈ x.1.val ↔ y ∈ v.val.take x.2.val)
    (fun o => SortedStart o.val ∧ ∀ x, x ∈ o.val ↔ x ∈ v.val) ?_ (alloc.vec.Vec.new ranges.Range, 0#usize) out
    ⟨by simp [SortedStart], fun y => by simp⟩ (by simp) h
  rintro ⟨res, i⟩ rr ⟨hs, hm⟩ hi hb
  try simp only [] at hs hm hi
  unfold ranges.sort_by_start_loop.body at hb
  h5i_invert hb
  · have hl : i.val < v.val.length := by scalar_tac
    rw [vec_index_eq _ _ hl] at hr
    have e := (H5iAppLib.Result.ok.inj hr); subst e
    obtain ⟨j, hjl, hres, hpre, hnext⟩ := insert_by_start_ok hres1
    have hk := H5iAppLib.add_ok_val hi2
    simp only [UScalar.ofNatCore_val_eq] at hk
    refine ⟨⟨?_, fun y => ?_⟩, by simp only []; omega, by simp only []; omega⟩
    · rw [hres]; exact sorted_insert hs hjl hpre hnext
    · rw [hres, mem_insert_iff, hm, hk, List.take_add_one, List.getElem?_eq_getElem hl]
      simp only [Option.toList_some, List.mem_append, List.mem_singleton]
      tauto
  · have : v.val.take i.val = v.val := List.take_of_length_le (by scalar_tac)
    rw [this] at hm
    exact ⟨hs, hm⟩

/-- Every range has `start ≤ end ≤ max`. -/
def WF (max : U128) (l : List ranges.Range) : Prop := ∀ r ∈ l, r.start.val ≤ r.end.val ∧ r.end.val ≤ max.val

theorem inRanges_append_one (l : List ranges.Range) (r : ranges.Range) (x : Nat) :
    InRanges (l ++ [r]) x ↔ InRanges l x ∨ (r.start.val ≤ x ∧ x ≤ r.end.val) := by
  unfold InRanges; simp [or_and_right, exists_or]

theorem next_ok {x max y : U128} (h : ranges.next x max = ok y) :
    y.val = if max.val ≤ x.val then 0 else x.val + 1 := by
  unfold ranges.next at h
  split at h
  · have := (H5iAppLib.Result.ok.inj h).symm; subst this; simp_all
  · have := H5iAppLib.add_ok_val h; simp_all

theorem merge_cover {cs ce s e mx : Nat} (hcs : cs ≤ s) (hse : s ≤ e) (hce : ce ≤ mx) (he : e ≤ mx)
    (hnu : s ≤ if mx ≤ ce then 0 else ce + 1) (z : Nat) :
    ((cs ≤ z ∧ z ≤ ce) ∨ (s ≤ z ∧ z ≤ e)) ↔ (cs ≤ z ∧ z ≤ (if e ≥ ce then e else ce)) := by
  split_ifs at hnu ⊢ <;> omega

/-- The sweep state: `cur = [cs, ce]`, `nu = next ce`, and `merged ∪ cur`
covers the first `i` ranges. -/
def SInv (rs : alloc.vec.Vec ranges.Range) (max : U128)
    (x : alloc.vec.Vec ranges.Range × U128 × U128 × U128 × Usize) : Prop :=
  1 ≤ x.2.2.2.2.val ∧ x.2.1.val ≤ x.2.2.1.val ∧ x.2.2.1.val ≤ max.val ∧
    (x.2.2.2.1.val = if max.val ≤ x.2.2.1.val then 0 else x.2.2.1.val + 1) ∧
    (∀ k (hk : x.2.2.2.2.val ≤ k) (hl : k < rs.val.length), x.2.1.val ≤ rs.val[k].start.val) ∧
    (∀ y, (InRanges x.1.val y ∨ (x.2.1.val ≤ y ∧ y ≤ x.2.2.1.val)) ↔ InRanges (rs.val.take x.2.2.2.2.val) y)

theorem sweep_loop_ok (rs : alloc.vec.Vec ranges.Range) (max : U128) (hs : SortedStart rs.val) (hwf : WF max rs.val)
    (x0 : alloc.vec.Vec ranges.Range × U128 × U128 × U128 × Usize) (y : alloc.vec.Vec ranges.Range × U128 × U128)
    (hI : SInv rs max x0) (hil : x0.2.2.2.2.val ≤ rs.val.length)
    (h : ranges.sweep_loop rs max x0.1 x0.2.1 x0.2.2.1 x0.2.2.2.1 x0.2.2.2.2 = ok y) :
    ∀ z, (InRanges y.1.val z ∨ (y.2.1.val ≤ z ∧ z ≤ y.2.2.val)) ↔ InRanges rs.val z := by
  unfold ranges.sweep_loop at h
  refine H5iAppLib.loop_idx_ok _ (fun x => x.2.2.2.2) rs.val.length (SInv rs max)
    (fun y => ∀ z, (InRanges y.1.val z ∨ (y.2.1.val ≤ z ∧ z ≤ y.2.2.val)) ↔ InRanges rs.val z) ?_ x0 y hI hil h
  rintro ⟨merged, cs, ce, nu, i⟩ r ⟨hi1, hle, hce, hnu, hcs, hcov⟩ hil hb
  simp only [] at hi1 hle hce hnu hcs hcov hil hb
  unfold ranges.sweep_loop.body at hb
  h5i_invert hb
  · have hl : i.val < rs.val.length := by scalar_tac
    rw [vec_index_eq _ _ hl] at hr_1
    have e := (H5iAppLib.Result.ok.inj hr_1); subst e
    obtain ⟨m1, a1, b1, c1⟩ := x
    obtain ⟨j, hj, hb3⟩ := H5iAppLib.bind_tc_eq_ok.1 hb
    have := (H5iAppLib.Result.ok.inj hb3).symm; subst this
    have hjv := H5iAppLib.add_ok_val hj
    simp only [UScalar.ofNatCore_val_eq] at hjv
    dsimp only
    have hwfi := hwf _ (List.getElem_mem hl)
    have hsi := hcs i.val (le_refl _) hl
    have htake : ∀ z, InRanges (rs.val.take (i.val + 1)) z ↔
        InRanges (rs.val.take i.val) z ∨ (rs.val[i.val].start.val ≤ z ∧ z ≤ rs.val[i.val].end.val) := by
      intro z
      rw [List.take_add_one, List.getElem?_eq_getElem hl, Option.toList_some, inRanges_append_one]
    have hsorted : ∀ k (hk : i.val + 1 ≤ k) (hk' : k < rs.val.length), rs.val[i.val].start.val ≤ rs.val[k].start.val := by
      intro k hk hk'
      exact List.pairwise_iff_getElem.1 hs i.val k hl hk' (by omega)
    unfold SInv
    simp only [hjv]
    refine ⟨⟨by omega, ?_⟩, by omega, by omega⟩
    split at hx
    · rename_i hA
      have hA' : rs.val[i.val].start.val ≤ nu.val := by scalar_tac
      obtain ⟨⟨p1, p2⟩, hp, hq⟩ := H5iAppLib.bind_tc_eq_ok.1 hx
      have e := H5iAppLib.Result.ok.inj hq
      simp only [Prod.mk.injEq] at e
      obtain ⟨rfl, rfl, rfl, rfl⟩ := e
      have hmc := merge_cover hsi hwfi.1 hce hwfi.2 (hnu ▸ hA')
      split at hp
      · rename_i hB
        have hB' : ce.val ≤ rs.val[i.val].end.val := by scalar_tac
        obtain ⟨n2, hn2, hq2⟩ := H5iAppLib.bind_tc_eq_ok.1 hp
        have e := H5iAppLib.Result.ok.inj hq2
        simp only [Prod.mk.injEq] at e
        obtain ⟨rfl, rfl⟩ := e
        refine ⟨by omega, hwfi.2, next_ok hn2, fun k hk hl => hcs k (by omega) hl, fun z => ?_⟩
        rw [htake, ← hcov, or_assoc, hmc z, if_pos hB']
      · rename_i hB
        have hB' : ¬ ce.val ≤ rs.val[i.val].end.val := by scalar_tac
        have e := H5iAppLib.Result.ok.inj hp
        simp only [Prod.mk.injEq] at e
        obtain ⟨rfl, rfl⟩ := e
        refine ⟨hle, hce, hnu, fun k hk hl => hcs k (by omega) hl, fun z => ?_⟩
        rw [htake, ← hcov, or_assoc, hmc z, if_neg hB']
    · obtain ⟨m2, hm2, hq2⟩ := H5iAppLib.bind_tc_eq_ok.1 hx
      obtain ⟨n2, hn2, hq3⟩ := H5iAppLib.bind_tc_eq_ok.1 hq2
      have e := H5iAppLib.Result.ok.inj hq3
      simp only [Prod.mk.injEq] at e
      obtain ⟨rfl, rfl, rfl, rfl⟩ := e
      have hv := push_ok_val hm2
      refine ⟨hwfi.1, hwfi.2, next_ok hn2, hsorted, fun z => ?_⟩
      rw [htake, ← hcov, hv, inRanges_append_one]
  · have : rs.val.take i.val = rs.val := List.take_of_length_le (by scalar_tac)
    rw [this] at hcov
    exact hcov

theorem sweep_ok (rs out : alloc.vec.Vec ranges.Range) (max : U128) (hs : SortedStart rs.val) (hwf : WF max rs.val)
    (hne : 0 < rs.val.length) (h : ranges.sweep rs max = ok out) :
    ∀ z, InRanges out.val z ↔ InRanges rs.val z := by
  unfold ranges.sweep at h
  rw [vec_index_eq _ (0#usize) (by simpa using hne)] at h
  obtain ⟨r0, hr0, h1⟩ := H5iAppLib.bind_tc_eq_ok.1 h
  have e := (H5iAppLib.Result.ok.inj hr0).symm; subst e
  obtain ⟨nu, hnu, h2⟩ := H5iAppLib.bind_tc_eq_ok.1 h1
  obtain ⟨⟨m, a, b⟩, hl, h3⟩ := H5iAppLib.bind_tc_eq_ok.1 h2
  have hv := push_ok_val h3
  have hw0 := hwf _ (List.getElem_mem hne)
  have key := sweep_loop_ok rs max hs hwf (alloc.vec.Vec.new ranges.Range, rs.val[0].start, rs.val[0].end, nu, 1#usize)
    (m, a, b) ⟨by simp, hw0.1, hw0.2, next_ok hnu, fun k hk hl => List.pairwise_iff_getElem.1 hs 0 k hne hl (by simp at hk; omega),
      fun z => by
        rw [show (1#usize).val = 0 + 1 from rfl, List.take_add_one, List.getElem?_eq_getElem hne]
        simp [InRanges]⟩ (by simp; omega) hl
  intro z
  rw [hv, inRanges_append_one, ← key z]

/-- `merge_ranges` covers exactly the values its input covers. -/
theorem merge_ranges_ok (input out : alloc.vec.Vec ranges.Range) (max : U128) (hwf : WF max input.val)
    (h : ranges.merge_ranges input max = ok out) :
    ∀ z, InRanges out.val z ↔ InRanges input.val z := by
  unfold ranges.merge_ranges at h
  simp only [] at h
  split at h
  · rename_i h0
    have e := (H5iAppLib.Result.ok.inj h).symm; subst e
    have : input.val = [] := List.eq_nil_of_length_eq_zero (by scalar_tac)
    simp [this, InRanges]
  · rename_i h0
    obtain ⟨sorted, hs, h2⟩ := H5iAppLib.bind_tc_eq_ok.1 h
    obtain ⟨hsort, hmem⟩ := sort_by_start_ok hs
    have hne : 0 < sorted.val.length := by
      have hl : 0 < input.val.length := by scalar_tac
      have := (hmem _).2 (List.getElem_mem hl)
      exact List.length_pos_of_mem this
    have hwf' : WF max sorted.val := fun r hr => hwf r ((hmem r).1 hr)
    intro z
    rw [sweep_ok sorted out max hsort hwf' hne h2 z]
    unfold InRanges
    constructor
    · rintro ⟨r, hr, h⟩; exact ⟨r, (hmem r).1 hr, h⟩
    · rintro ⟨r, hr, h⟩; exact ⟨r, (hmem r).2 hr, h⟩

theorem usize_add_lit (a b c : Usize) (hc : c.val = a.val + b.val) : a + b = ok c := by
  have := UScalar.add_equiv a b
  revert this
  generalize a + b = r
  intro h
  cases r <;> simp_all
  · apply UScalar.eq_of_val_eq; omega
  · have := c.hBounds; rcases System.Platform.numBits_eq with h' | h' <;> simp_all <;> omega

theorem u128_add_lit (a b c : U128) (hc : c.val = a.val + b.val) : a + b = ok c := by
  have := UScalar.add_equiv a b
  revert this
  generalize a + b = r
  intro h
  cases r <;> simp_all
  · apply UScalar.eq_of_val_eq; omega
  · have := c.hBounds; simp_all; omega

def ex_in : alloc.vec.Vec ranges.Range :=
  alloc.vec.Vec.from [⟨1024#u128, 65535#u128⟩, ⟨2000#u128, 2000#u128⟩] (by simp; scalar_tac)

set_option linter.unusedSimpArgs false in
/-- Ports `1024-65535` and `2000`: the second range is not merged into the
first, because `next(65535)` wraps to 0. -/
theorem merge_ex_in : ranges.merge_ranges ex_in 65535#u128 = ok ex_in := by
  have h0 : (0:Nat) < U32.max := by scalar_tac
  have h1 : (1:Nat) < U32.max := by scalar_tac
  have h2 : (2:Nat) < U32.max := by scalar_tac
  have a1 : 0#usize + 1#usize = ok 1#usize := usize_add_lit _ _ _ (by simp)
  have a2 : 1#usize + 1#usize = ok 2#usize := usize_add_lit _ _ _ (by simp)
  have a3 : 2#usize + 1#usize = ok 3#usize := usize_add_lit _ _ _ (by simp)
  have b1 : 2000#u128 + 1#u128 = ok 2001#u128 := u128_add_lit _ _ _ (by simp)
  unfold ranges.merge_ranges ranges.sort_by_start ranges.sort_by_start_loop ranges.sweep ranges.sweep_loop
  simp [h0, h1, h2, a1, a2, a3, b1, ex_in, alloc.vec.Vec.index_usize, alloc.vec.Vec.push]
  repeat (rw [loop.eq_1]; simp [h0, h1, h2, a1, a2, a3, b1, ex_in, alloc.vec.Vec.index_usize, alloc.vec.Vec.push,
    ranges.sort_by_start_loop.body, ranges.sweep_loop.body, ranges.insert_by_start_loop0.body,
    ranges.insert_by_start_loop1.body, ranges.next, ranges.insert_by_start, ranges.insert_by_start_loop0,
    ranges.insert_by_start_loop1])

theorem ex_in_val : ex_in.val = [⟨1024#u128, 65535#u128⟩, ⟨2000#u128, 2000#u128⟩] := by simp [ex_in]

end defguard_kernel.Verified
