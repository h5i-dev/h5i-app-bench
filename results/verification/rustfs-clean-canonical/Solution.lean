import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit

namespace rustfs_kernel.Solution
set_option maxHeartbeats 2000000
set_option maxRecDepth 4096
set_option backward.split true
set_option linter.unusedSimpArgs false

@[simp] lemma lit_dot : lit "." = [46] := by decide +kernel
@[simp] lemma lit_slash : lit "/" = [47] := by decide +kernel

def Valid (l : List Nat) : Prop := ∀ s ∈ l.splitOn 47, s ≠ [] ∧ s ≠ [46]
def Canon (root : Bool) (l : List Nat) : Prop :=
  ∃ t, l = (if root then [47] else []) ++ t ∧ (t = [] ∨ Valid t)
def pref (b : alloc.vec.Vec U8) (w : Usize) : List Nat := nats (b.val.take w.val)

lemma valid_append (a s : List Nat) (ha : Valid a) (hs : s ≠ [] ∧ s ≠ [46])
    (hn : 47 ∉ s) : Valid (a ++ 47 :: s) := by
  unfold Valid at *
  rw [List.splitOn_append_cons_self, List.splitOn_eq_singleton hn]
  intro t ht
  rcases List.mem_append.mp ht with ht | ht
  · exact ha t ht
  · have he : t = s := by simpa using ht
    simpa [he] using hs

lemma valid_single (s : List Nat) (hs : s ≠ [] ∧ s ≠ [46]) (hn : 47 ∉ s) : Valid s := by
  unfold Valid
  rw [List.splitOn_eq_singleton hn]
  simpa using hs

lemma canon_base (r : Bool) : Canon r (if r then [47] else []) := by
  exact ⟨[], by simp, Or.inl rfl⟩

lemma canon_append (r : Bool) (l s : List Nat) (hl : Canon r l)
    (hs : s ≠ [] ∧ s ≠ [46]) (hn : 47 ∉ s) :
    Canon r (l ++ (if l.length = (if r then 1 else 0) then [] else [47]) ++ s) := by
  obtain ⟨t, rfl, ht⟩ := hl
  rcases ht with rfl | ht
  · cases r <;> simp only [Bool.false_eq_true, if_false, if_true, List.length_append,
      List.length_nil, List.length_cons, Nat.add_zero, List.append_nil, ↓reduceIte,
      List.nil_append] <;> exact ⟨s, rfl, Or.inr (valid_single s hs hn)⟩
  · have hne : t ≠ [] := by
      intro e
      subst t
      have := ht [] (by simp)
      exact this.1 rfl
    have hlen : t.length ≠ 0 := fun h => hne (List.length_eq_zero_iff.mp h)
    refine ⟨t ++ 47 :: s, ?_, Or.inr (valid_append t s ht hs hn)⟩
    cases r <;> simp_all [List.append_assoc]

lemma valid_take (l : List Nat) (k : Nat) (h : Valid l) (hk : l[k]? = some 47) :
    Valid (l.take k) := by
  have he : l = l.take k ++ 47 :: l.drop (k+1) := by
    obtain ⟨hb, he⟩ := List.getElem?_eq_some_iff.mp hk
    conv_lhs => rw [← List.take_append_drop k l, List.drop_eq_getElem_cons hb, he]
  rw [he] at h
  unfold Valid at *
  rw [List.splitOn_append_cons_self] at h
  intro s hs
  exact h s (List.mem_append_left _ hs)

lemma canon_take (r : Bool) (l : List Nat) (k : Nat) (h : Canon r l)
    (hk : l[k]? = some 47) (hb : (if r then 1 else 0) ≤ k) : Canon r (l.take k) := by
  obtain ⟨t, rfl, ht⟩ := h
  cases r with
  | false =>
    simp only [Bool.false_eq_true, if_false, List.nil_append] at *
    rcases ht with rfl | ht
    · simp at hk
    · exact ⟨t.take k, rfl, Or.inr (valid_take t k ht hk)⟩
  | true =>
    simp only [if_true, List.singleton_append] at *
    cases k with
    | zero => omega
    | succ k =>
      simp only [List.getElem?_cons_succ, List.take_succ_cons] at *
      rcases ht with rfl | ht
      · simp at hk
      · exact ⟨t.take k, rfl, Or.inr (valid_take t k ht hk)⟩

lemma canon_shape (r : Bool) (l : List Nat) (h : Canon r l) (hne : l ≠ []) : CleanShape l := by
  obtain ⟨t, rfl, ht⟩ := h
  cases r with
  | false =>
    simp only [Bool.false_eq_true, if_false, List.nil_append] at *
    rcases ht with rfl | ht
    · exact False.elim (hne rfl)
    · right; right
      have hh : t.head? ≠ some 47 := by
        intro hh
        obtain ⟨u, rfl⟩ := List.head?_eq_some_iff.mp hh
        have he := ht [] (by simp [List.splitOn_cons_eq_if_modifyHead])
        exact he.1 rfl
      simpa [hh, Valid] using ht
  | true =>
    simp only [if_true, List.singleton_append] at *
    rcases ht with rfl | ht
    · right; left; simp
    · right; right; simpa [Valid] using ht

lemma mut_ok {b : alloc.vec.Vec U8} {w : Usize} {x : U8} {f : U8 → alloc.vec.Vec U8}
    (h : alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) b w = ok (x,f)) :
    w.val < b.val.length ∧ f = b.set w := by
  rw [alloc.vec.Vec.index_mut_slice_index, alloc.vec.Vec.index_mut_usize] at h
  obtain ⟨v, hv, he⟩ := bind_tc_eq_ok.mp h
  have hb := (vec_index_ok hv).1
  simp only [ok.injEq, Prod.mk.injEq] at he
  exact ⟨hb, he.2.symm⟩

lemma pref_write (b : alloc.vec.Vec U8) (w w' : Usize) (x : U8)
    (hb : w.val < b.val.length) (hw : w'.val = w.val + 1) :
    pref (b.set w x) w' = pref b w ++ [x.val] := by
  simp only [pref, alloc.vec.Vec.set_val_eq, hw, nats, List.map_append]
  rw [List.take_add_one, List.take_set_of_le (Nat.le_refl _), List.getElem?_set_self hb]
  simp only [Option.toList_some, List.map_append, List.map_cons, List.map_nil]

lemma pref_write_before (b : alloc.vec.Vec U8) (w d : Usize) (x : U8) (hd : d.val ≤ w.val) :
    pref (b.set w x) d = pref b d := by
  simp only [pref, alloc.vec.Vec.set_val_eq]
  rw [List.take_set_of_le hd]

lemma pref_length (b : alloc.vec.Vec U8) (w : Usize) (h : w.val ≤ b.val.length) :
    (pref b w).length = w.val := by simp [pref, nats, List.length_take, Nat.min_eq_left h]

lemma index_nat {p : Slice U8} {r : Usize} {x : U8} (h : p.index_usize r = ok x) :
    (nats p.val)[r.val]? = some x.val := by
  obtain ⟨hb, he⟩ := slice_index_ok h
  simp [nats, List.getElem?_eq_getElem hb, he]

lemma copy_ok (b : alloc.vec.Vec U8) (w : Usize) (p : Slice U8) (r : Usize)
    (out : alloc.vec.Vec U8 × Usize × Usize)
    (hw : w.val ≤ b.val.length) (hr : r.val < p.val.length)
    (hc : (nats p.val)[r.val]? ≠ some 47)
    (h : pathclean.copy_element b w p r = ok out) :
    ∃ s, pref out.1 out.2.1 = pref b w ++ s ∧ out.2.1.val ≤ out.1.val.length ∧
      r.val < out.2.2.val ∧ out.2.2.val ≤ p.val.length ∧ 47 ∉ s ∧ s ≠ [] ∧
      (s = [46] → (nats p.val)[r.val]? = some 46 ∧
        ((nats p.val)[r.val+1]? = some 47 ∨ r.val+1 = p.val.length)) := by
  let I := fun (x : alloc.vec.Vec U8 × Usize × Usize) =>
    x.2.1.val ≤ x.1.val.length ∧ x.2.2.val ≤ p.val.length ∧
    ∃ s, pref x.1 x.2.1 = pref b w ++ s ∧ 47 ∉ s ∧
      s.length = x.2.2.val - r.val ∧ x.2.1.val = w.val + s.length ∧ r.val ≤ x.2.2.val ∧
      (s = [] ∨ s.head? = (nats p.val)[r.val]?)
  have hx : I (b,w,r) := by
    dsimp [I]
    refine ⟨hw, Nat.le_of_lt hr, [], by simp, by simp, by simp, by simp, by omega, Or.inl rfl⟩
  unfold pathclean.copy_element pathclean.copy_element_loop at h
  have hh := loop_ok
    (fun (bb,ww,rr) => pathclean.copy_element_loop.body p bb ww rr) I
    (fun x => I x ∧ (x.2.2.val = p.val.length ∨ (nats p.val)[x.2.2.val]? = some 47))
    (fun x => p.val.length - x.2.2.val) ?_ (b,w,r) out hx h
  · obtain ⟨⟨hwb, hrb, s, he, hn, hlen, hww, hrr, hhead⟩, hend⟩ := hh
    have hprogress : r.val < out.2.2.val := by
      by_contra hh
      have eq : out.2.2.val = r.val := by omega
      rcases hend with hend | hend
      · omega
      · exact hc (eq ▸ hend)
    refine ⟨s, he, hwb, hprogress, hrb, hn, ?_, ?_⟩
    · intro he
      simp only [he, List.length_nil] at hlen
      omega
    · intro he
      have hfirst : (nats p.val)[r.val]? = some 46 := by
        rcases hhead with hhead | hhead
        · simp [he] at hhead
        · simpa only [he, List.head?_cons] using hhead.symm
      refine ⟨hfirst, ?_⟩
      simp only [he, List.length_cons, List.length_nil] at hlen
      have eq : out.2.2.val = r.val + 1 := by omega
      rcases hend with hend | hend
      · exact Or.inr (by omega)
      · exact Or.inl (eq ▸ hend)
  · rintro ⟨bb,ww,rr⟩ res ⟨hwb, hrb, s, he, hn, hlen, hww, hrr, hhead⟩ hs
    dsimp only at hwb hrb he hlen hww hrr ⊢
    unfold pathclean.copy_element_loop.body at hs
    h5i_invert hs
    · rcases x with ⟨x,f⟩
      obtain ⟨hb, rfl⟩ := mut_ok hx_1
      change (do let w1 ← ww + 1#usize; let r1 ← rr + 1#usize;
                 ok (ControlFlow.cont (bb.set ww i1, w1, r1))) = ok res at hs
      h5i_invert hs
      have hw1 := add_ok_val hw1
      have hr1 := add_ok_val hr1
      have hp := (slice_index_ok hi1).1
      have hn1 : i1.val ≠ 47 := by scalar_tac
      simp only [UScalar.ofNatCore_val_eq] at hw1 hr1
      dsimp [I]
      refine ⟨⟨?_, ?_, s ++ [i1.val], ?_, ?_, ?_, ?_, ?_, ?_⟩, ?_⟩
      · simp only [alloc.vec.Vec.set_val_eq, List.length_set]; omega
      · omega
      · rw [pref_write bb ww w1 i1 hb hw1, he, List.append_assoc]
      · simpa using And.intro hn hn1
      · simp only [List.length_append, List.length_cons, List.length_nil]; omega
      · simp only [List.length_append, List.length_cons, List.length_nil]; omega
      · omega
      · right
        rcases hhead with rfl | hhead
        · simp only [List.length_nil] at hlen
          have heq : rr.val = r.val := by omega
          simpa only [heq, List.nil_append, List.head?_cons] using (index_nat hi1).symm
        · cases s with
          | nil =>
            simp only [List.length_nil] at hlen
            have heq : rr.val = r.val := by omega
            simpa only [heq, List.nil_append, List.head?_cons] using (index_nat hi1).symm
          | cons a s => simpa only [List.cons_append, List.head?_cons] using hhead
      · omega
    · have hi : i1 = 47#u8 := by scalar_tac
      dsimp [I]
      refine ⟨⟨hwb, hrb, s, he, hn, hlen, hww, hrr, hhead⟩, Or.inr ?_⟩
      simpa [hi] using index_nat hi1
    · have hh : rr.val ≥ p.val.length := by scalar_tac
      dsimp [I]
      exact ⟨⟨hwb, hrb, s, he, hn, hlen, hww, hrr, hhead⟩, Or.inl (by omega)⟩

lemma back_ok (p : Slice U8) (w d out : Usize) (hd : d.val ≤ w.val)
    (h : pathclean.back_to_slash p w d = ok out) :
    d.val ≤ out.val ∧ out.val ≤ w.val ∧
      (out.val = d.val ∨ (nats p.val)[out.val]? = some 47) := by
  unfold pathclean.back_to_slash pathclean.back_to_slash_loop at h
  apply loop_ok _ (fun k : Usize => d.val ≤ k.val ∧ k.val ≤ w.val)
    (fun k : Usize => d.val ≤ k.val ∧ k.val ≤ w.val ∧
      (k.val = d.val ∨ (nats p.val)[k.val]? = some 47))
    (fun k => k.val) ?_ w out ⟨hd, by omega⟩ h
  intro k res hk hs
  unfold pathclean.back_to_slash_loop.body at hs
  split at hs
  h5i_invert hs
  · have hv := sub_ok_val hw1
    simp only [UScalar.ofNatCore_val_eq] at hv
    refine ⟨⟨by scalar_tac, by omega⟩, by omega⟩
  · have he : i = 47#u8 := by scalar_tac
    exact ⟨hk.1, hk.2, Or.inr (by simpa [he] using index_nat hi)⟩
  · exact ⟨hk.1, hk.2, Or.inl (by scalar_tac)⟩

lemma canon_min (r : Bool) (l : List Nat) (h : Canon r l) :
    (if r then 1 else 0) ≤ l.length := by
  obtain ⟨t, rfl, ht⟩ := h
  cases r <;> simp

lemma pref_take (b : alloc.vec.Vec U8) (w : Usize) (k : Nat) (hk : k ≤ w.val) :
    (pref b w).take k = nats (b.val.take k) := by
  simp only [pref, nats, ← List.map_take, List.take_take, Nat.min_eq_left hk]

def Inv (root : Bool) (b : alloc.vec.Vec U8) (w d : Usize) : Prop :=
  w.val ≤ b.val.length ∧ d.val ≤ w.val ∧ Canon root (pref b w) ∧ Canon root (pref b d)

lemma inv_back (root : Bool) (b : alloc.vec.Vec U8) (w d w1 w2 : Usize)
    (hi : Inv root b w d) (hgt : w > d) (hw1 : w - 1#usize = ok w1)
    (hb : pathclean.back_to_slash (alloc.vec.Vec.deref b) w1 d = ok w2) :
    Inv root b w2 d := by
  obtain ⟨hlen, hd, hc, hdc⟩ := hi
  have hv := sub_ok_val hw1
  simp only [UScalar.ofNatCore_val_eq] at hv
  have hle : d.val ≤ w1.val := by scalar_tac
  obtain ⟨hd2, hw2, he⟩ := back_ok _ _ _ _ hle hb
  refine ⟨by omega, hd2, ?_, hdc⟩
  rcases he with he | he
  · have : w2 = d := by scalar_tac
    simpa [this] using hdc
  · have hroot := canon_min root (pref b d) hdc
    rw [pref_length b d (by omega)] at hroot
    simp only [alloc.vec.Vec.deref, Slice.from_val] at he
    change (nats b.val)[w2.val]? = some 47 at he
    have he' : (pref b w)[w2.val]? = some 47 := by
      simp only [pref, nats, List.map_take, List.getElem?_take]
      simpa only [show w2.val < w.val from by omega, ↓reduceIte, nats] using he
    have ht := canon_take root (pref b w) w2.val hc he' (by omega)
    rw [pref_take b w w2.val (by omega)] at ht
    exact ht

lemma inv_extend (root : Bool) (b b' : alloc.vec.Vec U8) (w w' d : Usize)
    (hi : Inv root b w d) (hb : w'.val ≤ b'.val.length)
    (s : List Nat) (he : pref b' w' = pref b w ++ s)
    (hc : Canon root (pref b' w')) : Inv root b' w' d := by
  obtain ⟨hw, hd, ho, hdo⟩ := hi
  have hlen := congrArg List.length he
  simp only [List.length_append, pref_length b w hw, pref_length b' w' hb] at hlen
  refine ⟨hb, by omega, hc, ?_⟩
  have ht := congrArg (List.take d.val) he
  rw [List.take_append_of_le_length (by rw [pref_length b w hw]; exact hd)] at ht
  rw [pref_take b' w' d.val (by omega), pref_take b w d.val hd] at ht
  change Canon root (nats (b'.val.take d.val))
  rw [ht]
  exact hdo

def separator (root : Bool) (b : alloc.vec.Vec U8) (w : Usize) : Result (alloc.vec.Vec U8 × Usize) := do
  if root then
    if w != 1#usize then do
      let (_,back) ← alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) b w
      let w2 ← w + 1#usize
      ok (back 47#u8,w2)
    else ok (b,w)
  else
    if w != 0#usize then do
      let (_,back) ← alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) b w
      let w2 ← w + 1#usize
      ok (back 47#u8,w2)
    else ok (b,w)

lemma separator_ok (root : Bool) (b : alloc.vec.Vec U8) (w : Usize)
    (out : alloc.vec.Vec U8 × Usize) (hw : w.val ≤ b.val.length)
    (h : separator root b w = ok out) :
    out.2.val ≤ out.1.val.length ∧
    pref out.1 out.2 = pref b w ++ (if w.val = (if root then 1 else 0) then [] else [47]) := by
  unfold separator at h
  h5i_invert h
  all_goals first
  | (rcases x with ⟨x,f⟩
     obtain ⟨hb, rfl⟩ := mut_ok hx
     change (do let w2 ← w + 1#usize; ok (b.set w 47#u8,w2)) = ok out at h
     h5i_invert h
     have hv := add_ok_val hw2
     simp only [UScalar.ofNatCore_val_eq] at hv
     have hneq : w.val ≠ (if root then 1 else 0) := by split <;> scalar_tac
     dsimp only
     refine ⟨?_, ?_⟩
     · simp only [alloc.vec.Vec.set_val_eq, List.length_set]; omega
     · simp only [hneq, if_false]
       exact pref_write b w w2 47#u8 hb hv)
  | (have heq : w.val = (if root then 1 else 0) := by split <;> scalar_tac
     dsimp only
     exact ⟨hw, by simp only [heq, if_true, List.append_nil]⟩)

def ordinary (root : Bool) (b : alloc.vec.Vec U8) (w r d : Usize) (p : Slice U8) :
    Result (ControlFlow (Bool × alloc.vec.Vec U8 × Usize × Usize × Usize) (alloc.vec.Vec U8 × Usize)) := do
  let (b1,w1) ← if root then
    if w != 1#usize then do
      let (_,back) ← alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) b w
      let w2 ← w + 1#usize
      ok (back 47#u8,w2)
    else ok (b,w)
  else
    if w != 0#usize then do
      let (_,back) ← alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) b w
      let w2 ← w + 1#usize
      ok (back 47#u8,w2)
    else ok (b,w)
  let (b2,w2,r2) ← pathclean.copy_element b1 w1 p r
  ok (ControlFlow.cont (root,b2,w2,r2,d))

def Progress (r : Usize) :
    ControlFlow (Bool × alloc.vec.Vec U8 × Usize × Usize × Usize) (alloc.vec.Vec U8 × Usize) → Prop
  | .done _ => False
  | .cont x => Inv x.1 x.2.1 x.2.2.1 x.2.2.2.2 ∧ r.val < x.2.2.2.1.val

lemma ordinary_ok (root : Bool) (b : alloc.vec.Vec U8) (w r d : Usize) (p : Slice U8)
    (res : ControlFlow (Bool × alloc.vec.Vec U8 × Usize × Usize × Usize) (alloc.vec.Vec U8 × Usize))
    (hi : Inv root b w d) (hr : r.val < p.val.length)
    (hslash : (nats p.val)[r.val]? ≠ some 47)
    (hdot : (nats p.val)[r.val]? ≠ some 46 ∨
      ((nats p.val)[r.val+1]? ≠ some 47 ∧ r.val+1 ≠ p.val.length))
    (h : ordinary root b w r d p = ok res) : Progress r res := by
  unfold ordinary at h
  rw [← separator] at h
  obtain ⟨⟨b1,w1⟩, hsep, h⟩ := bind_tc_eq_ok.mp h
  obtain ⟨⟨b2,w2,r2⟩, hcopy, h⟩ := bind_tc_eq_ok.mp h
  change ok (ControlFlow.cont (root,b2,w2,r2,d)) = ok res at h
  have heq := result_ok_inj h
  rw [← heq]
  dsimp only [Progress]
  obtain ⟨hwb, hpref⟩ := separator_ok root b w (b1,w1) hi.1 hsep
  dsimp only at hwb hpref
  obtain ⟨s, he, hb2, hr2, hrb, hn, hne, hdot'⟩ := copy_ok b1 w1 p r (b2,w2,r2) hwb hr hslash hcopy
  dsimp only at he hb2 hr2 hrb hdot'
  have hnotdot : s ≠ [46] := by
    intro hs
    obtain ⟨hfirst,hend⟩ := hdot' hs
    rcases hdot with hh | ⟨hh,hh'⟩
    · exact hh hfirst
    · rcases hend with hend | hend
      · exact hh hend
      · exact hh' hend
  have he' : pref b2 w2 = pref b w ++
      ((if w.val = (if root then 1 else 0) then [] else [47]) ++ s) := by
    rw [he, hpref, List.append_assoc]
  have hc := canon_append root (pref b w) s hi.2.2.1 ⟨hne,hnotdot⟩ hn
  rw [pref_length b w hi.1] at hc
  rw [List.append_assoc, ← he'] at hc
  exact ⟨inv_extend root b b2 w w2 d hi hb2 _ he' hc, hr2⟩

def relativeSep (b : alloc.vec.Vec U8) (w : Usize) : Result (alloc.vec.Vec U8 × Usize) := do
  if w > 0#usize then
    let (_,back) ← alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) b w
    let w2 ← w + 1#usize
    ok (back 47#u8,w2)
  else ok (b,w)

lemma relativeSep_eq (b : alloc.vec.Vec U8) (w : Usize) : relativeSep b w = separator false b w := by
  unfold relativeSep separator
  simp only [Bool.false_eq_true, if_false]
  by_cases hp : w > 0#usize
  · have he : (w != 0#usize) = true := by scalar_tac
    simp only [hp, he, if_true]
  · have hw : w = 0#usize := by scalar_tac
    have he : (w != 0#usize) = false := by simp only [hw, bne_self_eq_false]
    simp only [hp, he, Bool.false_eq_true, if_false]

def dots (b : alloc.vec.Vec U8) (w rNext : Usize) :
    Result (ControlFlow (Bool × alloc.vec.Vec U8 × Usize × Usize × Usize) (alloc.vec.Vec U8 × Usize)) := do
  let (_,back) ← alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) b w
  let w2 ← w + 1#usize
  let b2 := back 46#u8
  let (_,back1) ← alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) b2 w2
  let w3 ← w2 + 1#usize
  ok (ControlFlow.cont (false,back1 46#u8,w3,rNext,w3))

lemma dots_ok (b : alloc.vec.Vec U8) (w rNext : Usize) (res)
    (h : dots b w rNext = ok res) :
    ∃ b' w', res = ControlFlow.cont (false,b',w',rNext,w') ∧
      w'.val ≤ b'.val.length ∧ pref b' w' = pref b w ++ [46,46] := by
  unfold dots at h
  obtain ⟨⟨x,f⟩, hx, h⟩ := bind_tc_eq_ok.mp h
  obtain ⟨hb, rfl⟩ := mut_ok hx
  obtain ⟨w2, hw2, h⟩ := bind_tc_eq_ok.mp h
  obtain ⟨⟨x1,f1⟩, hx1, h⟩ := bind_tc_eq_ok.mp h
  obtain ⟨hb1, rfl⟩ := mut_ok hx1
  obtain ⟨w3, hw3, h⟩ := bind_tc_eq_ok.mp h
  change ok (ControlFlow.cont (false,(b.set w 46#u8).set w2 46#u8,w3,rNext,w3)) = ok res at h
  refine ⟨_, w3, (result_ok_inj h).symm, ?_, ?_⟩
  have hv2 := add_ok_val hw2
  have hv3 := add_ok_val hw3
  simp only [UScalar.ofNatCore_val_eq] at hv2 hv3
  · simp only [alloc.vec.Vec.set_val_eq, List.length_set] at hb1 ⊢
    have hv3 := add_ok_val hw3
    simp only [UScalar.ofNatCore_val_eq] at hv3
    omega
  · have hv2 := add_ok_val hw2
    have hv3 := add_ok_val hw3
    simp only [UScalar.ofNatCore_val_eq] at hv2 hv3
    rw [pref_write _ w2 w3 46#u8 hb1 hv3, pref_write b w w2 46#u8 hb hv2]
    simp only [UScalar.ofNatCore_val_eq, List.append_assoc, List.singleton_append]

def parent (root : Bool) (b : alloc.vec.Vec U8) (w rNext d : Usize) :
    Result (ControlFlow (Bool × alloc.vec.Vec U8 × Usize × Usize × Usize) (alloc.vec.Vec U8 × Usize)) := do
  if w > d then
    let w1 ← w - 1#usize
    let w2 ← pathclean.back_to_slash (alloc.vec.Vec.deref b) w1 d
    ok (ControlFlow.cont (root,b,w2,rNext,d))
  else if root then ok (ControlFlow.cont (true,b,w,rNext,d))
  else
    let (b1,w1) ← if w > 0#usize then do
      let (_,back) ← alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) b w
      let w2 ← w + 1#usize
      ok (back 47#u8,w2)
    else ok (b,w)
    let (_,back) ← alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) b1 w1
    let w2 ← w1 + 1#usize
    let b2 := back 46#u8
    let (_,back1) ← alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) b2 w2
    let w3 ← w2 + 1#usize
    ok (ControlFlow.cont (false,back1 46#u8,w3,rNext,w3))

lemma parent_ok (root : Bool) (b : alloc.vec.Vec U8) (w r rNext d : Usize) (res)
    (hi : Inv root b w d) (hr : r.val < rNext.val)
    (h : parent root b w rNext d = ok res) : Progress r res := by
  unfold parent at h
  simp only [← relativeSep.eq_def, ← dots.eq_def] at h
  h5i_invert h
  · exact ⟨inv_back root b w d w1 w2 hi hc hw1 hw2, hr⟩
  · simpa only [Progress, hc_1] using And.intro hi hr
  · rcases x with ⟨b1,w1⟩
    change dots b1 w1 rNext = ok res at h
    have hroot : root = false := by cases root <;> simp_all
    subst root
    obtain ⟨b2,w2,he,hb2,hpref⟩ := dots_ok b1 w1 rNext res h
    rw [he]
    dsimp only [Progress]
    rw [relativeSep_eq] at hx
    obtain ⟨hb1,hp1⟩ := separator_ok false b w (b1,w1) hi.1 hx
    dsimp only at hb1 hp1
    have hcanon := canon_append false (pref b w) [46,46] hi.2.2.1 (by simp) (by simp)
    rw [pref_length b w hi.1] at hcanon
    have hc : Canon false (pref b2 w2) := by
      rw [hpref,hp1]
      exact hcanon
    exact ⟨⟨hb2, by omega, hc, hc⟩,hr⟩

def Measured (r : Usize) :
    ControlFlow (Bool × alloc.vec.Vec U8 × Usize × Usize × Usize) (alloc.vec.Vec U8 × Usize) → Prop
  | .done y => ∃ root, y.2.val ≤ y.1.val.length ∧ Canon root (pref y.1 y.2)
  | .cont x => Inv x.1 x.2.1 x.2.2.1 x.2.2.2.2 ∧ Usize.max - x.2.2.2.1.val < Usize.max - r.val

lemma progress_measure (r : Usize) (res) (h : Progress r res) : Measured r res := by
  cases res with
  | done y => exact False.elim h
  | cont x =>
    exact ⟨h.1, by have hb := x.2.2.2.1.hBounds; dsimp [Progress] at h; scalar_tac⟩

lemma index_ne {p : Slice U8} {r : Usize} {x c : U8}
    (h : p.index_usize r = ok x) (hc : x ≠ c) : (nats p.val)[r.val]? ≠ some c.val := by
  rw [index_nat h]
  intro he
  have he := Option.some.inj he
  exact hc ((u8_eq_iff x c).mpr he)

lemma main_loop_ok (p : Slice U8) (n : Usize) (root : Bool) (b : alloc.vec.Vec U8)
    (w r d : Usize) (out : alloc.vec.Vec U8 × Usize) (hn : n.val = p.val.length)
    (hi : Inv root b w d) (h : pathclean.clean_loop0 p n root b w r d = ok out) :
    ∃ root', out.2.val ≤ out.1.val.length ∧ Canon root' (pref out.1 out.2) := by
  unfold pathclean.clean_loop0 at h
  apply loop_ok _ (fun (root,b,w,r,d) => Inv root b w d)
    (fun out => ∃ root', out.2.val ≤ out.1.val.length ∧ Canon root' (pref out.1 out.2))
    (fun (root,b,w,r,d) => Usize.max - r.val) ?_ (root,b,w,r,d) out hi h
  rintro ⟨root,b,w,r,d⟩ res hi hs
  dsimp only at hi ⊢
  unfold pathclean.clean_loop0.body at hs
  simp only [← ordinary.eq_def, ← parent.eq_def] at hs
  h5i_invert hs
  · exact ⟨hi, by h5i_arith⟩
  · exact ⟨hi, by h5i_arith⟩
  · exact ⟨hi, by h5i_arith⟩
  · have hp := parent_ok root b w r i4 d res hi (by h5i_arith) hs
    cases res <;> exact progress_measure r _ hp
  · have hp := parent_ok root b w r i4 d res hi (by h5i_arith) hs
    cases res <;> exact progress_measure r _ hp
  · suffices hp : Progress r res by cases res <;> exact progress_measure r _ hp
    apply ordinary_ok root b w r d p res hi (by scalar_tac)
      (index_ne hi_1 hc_1)
    · right
      refine ⟨?_, by h5i_arith⟩
      have hnxt := index_ne hi2 hc_4
      have hv := add_ok_val hi1
      simp only [UScalar.ofNatCore_val_eq] at hv
      simpa only [hv, UScalar.ofNatCore_val_eq] using hnxt
    · exact hs
  · suffices hp : Progress r res by cases res <;> exact progress_measure r _ hp
    apply ordinary_ok root b w r d p res hi (by scalar_tac)
      (index_ne hi_1 hc_1)
    · right
      refine ⟨?_, by h5i_arith⟩
      have hnxt := index_ne hi2 hc_4
      have hv := add_ok_val hi1
      simp only [UScalar.ofNatCore_val_eq] at hv
      simpa only [hv, UScalar.ofNatCore_val_eq] using hnxt
    · exact hs
  · have hp := ordinary_ok root b w r d p res hi (by scalar_tac)
      (index_ne hi_1 hc_1) (Or.inl (index_ne hi_1 hc_2)) hs
    cases res <;> exact progress_measure r _ hp
  · exact ⟨root,hi.1,hi.2.2.1⟩

lemma output_ok (b : alloc.vec.Vec U8) (w : Usize) (c : alloc.vec.Vec U8)
    (h : pathclean.clean_loop1 b w (alloc.vec.Vec.new U8) 0#usize = ok c) :
    c.val = b.val.take w.val := by
  unfold pathclean.clean_loop1 at h
  apply loop_ok _ (fun (out,i) => i.val ≤ w.val ∧ out.val = b.val.take i.val)
    (fun out => out.val = b.val.take w.val) (fun (out,i) => w.val-i.val)
    ?_ (alloc.vec.Vec.new U8, 0#usize) c (by simp [alloc.vec.Vec.new]) h
  rintro ⟨out,i⟩ res ⟨hle,he⟩ hs
  dsimp only at hle he ⊢
  unfold pathclean.clean_loop1.body at hs
  h5i_invert hs
  · have hp := post_of_ok (alloc.vec.Vec.push_spec out i1 (by
        rw [he, List.length_take]; scalar_tac)) hout1
    have hv := add_ok_val hi2
    simp only [UScalar.ofNatCore_val_eq] at hv
    rw [alloc.vec.Vec.index_slice_index] at hi1
    obtain ⟨hb,helem⟩ := vec_index_ok hi1
    refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
    rw [hp, he, hv, ← helem]
    exact List.take_append_getElem hb
  · have eq : i.val = w.val := by scalar_tac
    simpa only [eq] using he

lemma to_vec_ok (p : Slice U8) (b : alloc.vec.Vec U8)
    (h : alloc.slice.Slice.to_vec core.clone.CloneU8 p = ok b) : b.val = p.val := by
  have hs := post_of_ok (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 p (fun _ _ => rfl)) h
  simpa only [alloc.vec.Vec.val] using congrArg Slice.val hs.symm

def initState (b : alloc.vec.Vec U8) (first : U8) :
    Result (Bool × alloc.vec.Vec U8 × Usize × Usize × Usize) := do
  if first = 47#u8 then
    let (_,back) ← alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) b 0#usize
    let w ← 0#usize + 1#usize
    ok (true,back 47#u8,w,1#usize,1#usize)
  else ok (false,b,0#usize,0#usize,0#usize)

lemma initState_ok (b : alloc.vec.Vec U8) (first : U8) (out)
    (h : initState b first = ok out) : Inv out.1 out.2.1 out.2.2.1 out.2.2.2.2 := by
  unfold initState at h
  h5i_invert h
  · rcases x with ⟨x,f⟩
    obtain ⟨hb,rfl⟩ := mut_ok hx
    change (do let w ← 0#usize + 1#usize;
               ok (true,b.set 0#usize 47#u8,w,1#usize,1#usize)) = ok out at h
    h5i_invert h
    have hw := add_ok_val hw
    have heq : w = 1#usize := by scalar_tac
    subst w
    have hp := pref_write b 0#usize 1#usize 47#u8 hb (by scalar_tac)
    simp only [pref, UScalar.ofNatCore_val_eq, List.take_zero, nats, List.map_nil,
      List.nil_append] at hp
    dsimp only [Inv]
    refine ⟨?_, by scalar_tac, ?_, ?_⟩
    · simp only [alloc.vec.Vec.set_val_eq, List.length_set] at *; scalar_tac
    · simp only [pref, nats, UScalar.ofNatCore_val_eq, hp]
      exact canon_base true
    · simp only [pref, nats, UScalar.ofNatCore_val_eq, hp]
      exact canon_base true
  · dsimp only [Inv]
    simp only [pref, UScalar.ofNatCore_val_eq, List.take_zero, nats, List.map_nil]
    exact ⟨by omega, by omega, canon_base false, canon_base false⟩

lemma literal_dot_ok (s : Slice U8) (c : alloc.vec.Vec U8) (hs : s.val = [46#u8])
    (h : alloc.slice.Slice.to_vec core.clone.CloneU8 s = ok c) : CleanShape (nats c.val) := by
  rw [to_vec_ok s c h, hs]
  left
  simp only [nats, List.map_cons, List.map_nil, UScalar.ofNatCore_val_eq, lit_dot]

theorem clean_canonical (p : Slice U8) (c : alloc.vec.Vec U8) (h : pathclean.clean p = ok c) :
    CleanShape (nats c.val) := by
  unfold pathclean.clean at h
  simp only [← initState.eq_def, lift, bind_tc_ok] at h
  h5i_invert h
  · exact literal_dot_ok _ c (by simp only [Array.to_slice, Slice.from_val, Array.make_val]) h
  · rcases x with ⟨root,b1,w,r,d⟩
    have hinv := initState_ok buf i1 (root,b1,w,r,d) hx
    dsimp only at hinv
    obtain ⟨⟨b2,w2⟩,hloop,h⟩ := bind_tc_eq_ok.mp h
    change (if w2 = 0#usize then _ else pathclean.clean_loop1 b2 w2 (alloc.vec.Vec.new U8) 0#usize) = ok c at h
    h5i_invert h
    · exact literal_dot_ok _ c (by simp only [Array.to_slice, Slice.from_val, Array.make_val]) h
    · obtain ⟨root',hb,hcanon⟩ := main_loop_ok p p.len root b1 w r d (b2,w2) (by simp) hinv hloop
      dsimp only at hb hcanon
      rw [output_ok b2 w2 c h]
      apply canon_shape root' (pref b2 w2) hcanon
      intro he
      have hlen := pref_length b2 w2 hb
      rw [he, List.length_nil] at hlen
      scalar_tac

end rustfs_kernel.Solution
