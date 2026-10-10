import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP
open ControlFlow

namespace rustfs_kernel.Solution

abbrev slash : U8 := 47#u8
abbrev dot : U8 := 46#u8

def base (root : Bool) : List U8 := if root then [slash] else []
def sep (root : Bool) (xs : List U8) : List U8 :=
  if xs.length = (base root).length then [] else [slash]
def Segment (s : List U8) : Prop :=
  s ≠ [] ∧ slash ∉ s ∧ s ≠ [dot] ∧ s ≠ [dot, dot]

/-- Canonical prefixes, with the end of the leading parent segments recorded. -/
inductive Normal : Bool → Nat → List U8 → Prop
  | start (root) : Normal root (base root).length (base root)
  | part {root d xs s} : Normal root d xs → Segment s →
      Normal root d (xs ++ sep root xs ++ s)
  | parent {xs} : Normal false xs.length xs →
      Normal false (xs ++ sep false xs ++ [dot, dot]).length
        (xs ++ sep false xs ++ [dot, dot])

lemma normal_bounds {root d xs} (h : Normal root d xs) :
    (base root).length ≤ d ∧ d ≤ xs.length := by
  induction h with
  | start => simp
  | part h hs ih => simp only [List.length_append]; omega
  | parent h ih => simp only [List.length_append]; omega

lemma normal_cut_d {root d xs} (h : Normal root d xs) :
    Normal root d (xs.take d) := by
  induction h with
  | start root => simpa using Normal.start root
  | @part root d xs s h hs ih =>
      rw [List.take_append_of_le_length (by have := normal_bounds h; simp; omega),
        List.take_append_of_le_length (normal_bounds h).2]
      exact ih
  | parent h ih =>
      rw [List.take_of_length_le (by simp)]
      exact Normal.parent h

lemma get_mem {α} {xs : List α} {i : Nat} {x : α} (h : xs[i]? = some x) : x ∈ xs :=
  List.mem_of_getElem? h

lemma normal_cut_slash {root d xs} (h : Normal root d xs) :
    ∀ j, d ≤ j → j < xs.length → xs[j]? = some slash → Normal root d (xs.take j) := by
  induction h with
  | start root => intro j hd hj; omega
  | parent h ih => intro j hd hj; omega
  | @part root d xs s hn hs ih =>
      intro j hd hj he
      by_cases hjx : j < xs.length
      · rw [List.getElem?_append_left (by simp; omega),
          List.getElem?_append_left hjx] at he
        rw [List.take_append_of_le_length (by simp; omega),
          List.take_append_of_le_length (by omega)]
        exact ih j hd hjx he
      · by_cases hjp : j < (xs ++ sep root xs).length
        · have hsep : sep root xs = [slash] := by
            unfold sep at *
            split at hjp <;> simp_all <;> omega
          have hj' : j = xs.length := by simp [hsep] at hjp; omega
          subst j
          rw [List.take_append_of_le_length (by simp), List.take_append_length]
          exact hn
        · rw [List.getElem?_append_right (by omega)] at he
          exact False.elim (hs.2.1 (get_mem he))

lemma set_take_succ {α} (xs : List α) (i : Nat) (x : α) (h : i < xs.length) :
    (xs.set i x).take (i + 1) = xs.take i ++ [x] := by
  rw [List.take_add_one, List.take_set_of_le (by omega)]
  simp [List.getElem?_set, h]

lemma mut_ok {buf : alloc.vec.Vec U8} {w : Usize} {a : U8} {back : U8 → alloc.vec.Vec U8}
    (h : alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) buf w = ok (a, back)) :
    w.val < buf.val.length ∧ back = buf.set w := by
  simp only [alloc.vec.Vec.index_mut_slice_index, alloc.vec.Vec.index_mut_usize] at h
  h5i_invert h
  exact ⟨by have := vec_index_ok_get? hx; exact List.getElem?_eq_some_iff.mp this |>.1,
    h.2.symm⟩

lemma back_ok (buf : Slice U8) (w d u : Usize) (hd : d.val ≤ w.val)
    (h : pathclean.back_to_slash buf w d = ok u) :
    d.val ≤ u.val ∧ u.val ≤ w.val ∧
      (u.val = d.val ∨ buf.val[u.val]? = some slash) := by
  apply loop_ok (fun x => pathclean.back_to_slash_loop.body buf d x)
    (fun x => d.val ≤ x.val ∧ x.val ≤ w.val)
    (fun u => d.val ≤ u.val ∧ u.val ≤ w.val ∧
      (u.val = d.val ∨ buf.val[u.val]? = some slash))
    (fun x => x.val) ?_ w u ⟨hd, by omega⟩ h
  intro x z hx hz
  unfold pathclean.back_to_slash_loop.body at hz
  h5i_invert hz
  all_goals h5i_ok_facts
  all_goals simp only [gt_iff_lt, UScalar.lt_equiv, UScalar.ofNatCore_val_eq] at *
  · exact ⟨⟨by omega, by omega⟩, by omega⟩
  · refine ⟨hx.1, hx.2, Or.inr ?_⟩
    have he : i = slash := by scalar_tac
    simpa [he, alloc.vec.Vec.val] using hi_val
  · exact ⟨hx.1, hx.2, Or.inl (by omega)⟩

lemma read_ok {p : Slice U8} {r : Usize} {x : U8}
    (h : p.index_usize r = ok x) : p.val[r.val]? = some x := by
  obtain ⟨hr, he⟩ := slice_index_ok h
  simp [← he]

lemma copy_ok (p : Slice U8) (buf b : alloc.vec.Vec U8) (w r v t : Usize)
    (hr : r.val ≤ p.val.length) (hw : w.val ≤ buf.val.length)
    (h : pathclean.copy_element buf w p r = ok (b, v, t)) :
    ∃ s : List U8,
      b.val.take v.val = buf.val.take w.val ++ s ∧
      s = (p.val.drop r.val).take (t.val - r.val) ∧
      slash ∉ s ∧ r.val ≤ t.val ∧ t.val ≤ p.val.length ∧
      v.val = w.val + s.length ∧ v.val ≤ b.val.length ∧
      (t.val = p.val.length ∨ p.val[t.val]? = some slash) := by
  let inv := fun (x : alloc.vec.Vec U8 × Usize × Usize) =>
    r.val ≤ x.2.2.val ∧ x.2.2.val ≤ p.val.length ∧
    x.2.1.val = w.val + (x.2.2.val - r.val) ∧ x.2.1.val ≤ x.1.val.length ∧
    x.1.val.take x.2.1.val = buf.val.take w.val ++
      (p.val.drop r.val).take (x.2.2.val - r.val) ∧
    slash ∉ (p.val.drop r.val).take (x.2.2.val - r.val)
  apply loop_ok (fun (b, v, t) => pathclean.copy_element_loop.body p b v t)
    inv (fun (b, v, t) => ∃ s : List U8,
      b.val.take v.val = buf.val.take w.val ++ s ∧
      s = (p.val.drop r.val).take (t.val - r.val) ∧
      slash ∉ s ∧ r.val ≤ t.val ∧ t.val ≤ p.val.length ∧
      v.val = w.val + s.length ∧ v.val ≤ b.val.length ∧
      (t.val = p.val.length ∨ p.val[t.val]? = some slash))
    (fun x => p.val.length - x.2.2.val) ?_ (buf, w, r) (b, v, t) ?_ h
  · rintro ⟨b, v, t⟩ z ⟨hlo, hhi, hv, hb, he, hs⟩ hz
    dsimp only at hlo hhi hv hb he hs
    unfold pathclean.copy_element_loop.body at hz
    h5i_invert hz
    · obtain ⟨a, back⟩ := x
      change (do let w1 ← v + 1#usize
                 let r1 ← t + 1#usize
                 ok (cont (back i1, w1, r1))) = ok z at hz
      h5i_invert hz
      obtain ⟨hvb, hback⟩ := mut_ok hx
      have hv1 := add_ok_val hw1
      have ht1 := add_ok_val hr1
      have hread := read_ok hi1
      have hne : i1 ≠ slash := by simpa only [bne_iff_ne] using hc_1
      have hext : (p.val.drop r.val).take (r1.val - r.val) =
          (p.val.drop r.val).take (t.val - r.val) ++ [i1] := by
        rw [show r1.val - r.val = (t.val - r.val) + 1 by simp at ht1; omega,
          List.take_add_one]
        have hi : (p.val.drop r.val)[t.val - r.val]? = some i1 := by
          simpa [List.getElem?_drop, Nat.add_sub_of_le hlo] using hread
        simp [hi]
      change inv (back i1, w1, r1) ∧ _
      dsimp [inv]
      refine ⟨⟨by simp at ht1; omega, by simp at ht1; simp at hc; omega,
        by simp at hv1 ht1; omega, ?_, ?_, ?_⟩, ?_⟩
      · simp [hback]; simp at hv1; omega
      · rw [hback]
        simp only [alloc.vec.Vec.set_val_eq]
        rw [show w1.val = v.val + 1 by simpa using hv1, set_take_succ _ _ _ hvb,
          he, hext, List.append_assoc]
      · rw [hext]
        simpa only [List.mem_append, List.mem_singleton, not_or] using
          And.intro hs (Ne.symm hne)
      · simp at ht1; simp at hc; omega
    · have hread := read_ok hi1
      have hi : i1 = slash := by scalar_tac
      refine ⟨(p.val.drop r.val).take (t.val - r.val), he, rfl, hs,
        hlo, hhi, ?_, hb, Or.inr (by simpa [hi] using hread)⟩
      simp only [List.length_take, List.length_drop]
      omega
    · refine ⟨(p.val.drop r.val).take (t.val - r.val), he, rfl, hs,
        hlo, hhi, ?_, hb, Or.inl ?_⟩
      · simp only [List.length_take, List.length_drop]; omega
      · simp at hc; omega
  · dsimp [inv]; simp [hr, hw]

def write (buf : alloc.vec.Vec U8) (w : Usize) (a : U8) :
    Result (alloc.vec.Vec U8 × Usize) := do
  let (_, back) ← alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) buf w
  let v ← w + 1#usize
  ok (back a, v)

def separator (root : Bool) (buf : alloc.vec.Vec U8) (w : Usize) :
    Result (alloc.vec.Vec U8 × Usize) :=
  if root then
    if w != 1#usize then write buf w slash else ok (buf, w)
  else if w != 0#usize then write buf w slash else ok (buf, w)

def ordinary (p : Slice U8) (root : Bool) (buf : alloc.vec.Vec U8) (w r d : Usize) :
    Result (ControlFlow (Bool × alloc.vec.Vec U8 × Usize × Usize × Usize)
      (alloc.vec.Vec U8 × Usize)) := do
  let (b, v) ← separator root buf w
  let (b', v', t) ← pathclean.copy_element b v p r
  ok (cont (root, b', v', t, d))

def dots (b : alloc.vec.Vec U8) (v t : Usize) :
    Result (ControlFlow (Bool × alloc.vec.Vec U8 × Usize × Usize × Usize)
      (alloc.vec.Vec U8 × Usize)) := do
  let (_, back) ← alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) b v
  let v' ← v + 1#usize
  let b' := back dot
  let (_, back') ← alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) b' v'
  let v'' ← v' + 1#usize
  ok (cont (false, back' dot, v'', t, v''))

def up (root : Bool) (buf : alloc.vec.Vec U8) (w t d : Usize) :
    Result (ControlFlow (Bool × alloc.vec.Vec U8 × Usize × Usize × Usize)
      (alloc.vec.Vec U8 × Usize)) := do
  if w > d then
    let v ← w - 1#usize
    let u ← pathclean.back_to_slash buf.deref v d
    ok (cont (root, buf, u, t, d))
  else if root then ok (cont (true, buf, w, t, d))
  else
    let (b, v) ← if w > 0#usize then write buf w slash else ok (buf, w)
    dots b v t

def body (p : Slice U8) (n : Usize) (root : Bool) (buf : alloc.vec.Vec U8)
    (w r d : Usize) :
    Result (ControlFlow (Bool × alloc.vec.Vec U8 × Usize × Usize × Usize)
      (alloc.vec.Vec U8 × Usize)) := do
  if r < n then
    let a ← p.index_usize r
    if a = slash then
      let t ← r + 1#usize
      ok (cont (root, buf, w, t, d))
    else if a = dot then
      let t ← r + 1#usize
      if t = n then ok (cont (root, buf, w, t, d))
      else
        let b ← p.index_usize t
        if b = slash then ok (cont (root, buf, w, t, d))
        else
          let b' ← p.index_usize t
          if b' = dot then
            let u ← r + 2#usize
            if u = n then up root buf w u d
            else
              let c ← p.index_usize u
              if c = slash then up root buf w u d
              else ordinary p root buf w r d
          else ordinary p root buf w r d
    else ordinary p root buf w r d
  else ok (done (buf, w))

lemma body_eq (p : Slice U8) (n : Usize) (root : Bool) (buf : alloc.vec.Vec U8)
    (w r d : Usize) : pathclean.clean_loop0.body p n root buf w r d = body p n root buf w r d := by
  unfold pathclean.clean_loop0.body body
  by_cases hc : r < n
  · rw [if_pos hc, if_pos hc]
    congr 1
    funext a
    by_cases ha : a = slash
    · simp only [ha, ↓reduceIte]
    · simp only [ha, ↓reduceIte]
      by_cases hd : a = dot
      · simp only [hd, ↓reduceIte]
        rfl
      · simp only [hd, ↓reduceIte]; rfl
  · rw [if_neg hc, if_neg hc]

lemma write_ok {buf b : alloc.vec.Vec U8} {w v : Usize} {a : U8}
    (h : write buf w a = ok (b, v)) :
    v.val = w.val + 1 ∧ v.val ≤ b.val.length ∧
      b.val.take v.val = buf.val.take w.val ++ [a] := by
  unfold write at h
  h5i_invert h
  obtain ⟨x0, back⟩ := x
  change (do let v ← w + 1#usize; ok (back a, v)) = ok (b, v) at h
  h5i_invert h
  obtain ⟨hb, hv⟩ := h
  obtain ⟨hw, hback⟩ := mut_ok hx
  have he := add_ok_val hv_1
  subst b
  subst v_1
  rw [hback]
  simp only [alloc.vec.Vec.set_val_eq]
  refine ⟨by simpa using he, ?_, ?_⟩
  · simp only [List.length_set]; simp at he; omega
  · rw [show v.val = w.val + 1 by simpa using he, set_take_succ _ _ _ hw]

lemma separator_ok (root : Bool) (buf b : alloc.vec.Vec U8) (w v : Usize)
    (hw : w.val ≤ buf.val.length) (hk : (base root).length ≤ w.val)
    (h : separator root buf w = ok (b, v)) :
    v.val ≤ b.val.length ∧
      b.val.take v.val = buf.val.take w.val ++ sep root (buf.val.take w.val) := by
  have hlen : (buf.val.take w.val).length = w.val := by simp [List.length_take, Nat.min_eq_left hw]
  cases root <;> unfold separator at h <;> simp only [Bool.false_eq_true, ↓reduceIte] at h
  all_goals split at h
  case false.isTrue =>
    obtain ⟨hv, hb, he⟩ := write_ok h
    have hn : w.val ≠ 0 := by scalar_tac
    exact ⟨hb, by simpa [sep, base, hlen, hn] using he⟩
  case true.isTrue =>
    obtain ⟨hv, hb, he⟩ := write_ok h
    have hn : w.val ≠ 1 := by scalar_tac
    exact ⟨hb, by simpa [sep, base, hlen, hn] using he⟩
  case false.isFalse =>
    obtain ⟨rfl, rfl⟩ := Prod.mk.inj (result_ok_inj h)
    have hn : w.val = 0 := by scalar_tac
    exact ⟨hw, by simp [sep, base, hlen, hn]⟩
  case true.isFalse =>
    obtain ⟨rfl, rfl⟩ := Prod.mk.inj (result_ok_inj h)
    have hn : w.val = 1 := by scalar_tac
    refine ⟨hw, ?_⟩
    unfold sep
    rw [hlen]
    simp only [base, ↓reduceIte, List.length_cons, List.length_nil]
    rw [if_pos hn, List.append_nil]

def OrdinaryAt (p : List U8) (r : Nat) : Prop :=
  p[r]? ≠ none ∧ p[r]? ≠ some slash ∧
  (p[r]? = some dot → p[r + 1]? ≠ none ∧ p[r + 1]? ≠ some slash) ∧
  (p[r]? = some dot → p[r + 1]? = some dot →
    p[r + 2]? ≠ none ∧ p[r + 2]? ≠ some slash)

lemma copied_segment {p s : List U8} {r t : Nat}
    (ha : OrdinaryAt p r) (hs : s = (p.drop r).take (t - r))
    (hn : slash ∉ s) (hr : r ≤ t) (ht : t ≤ p.length)
    (he : t = p.length ∨ p[t]? = some slash) : Segment s ∧ r < t := by
  have hlen : s.length = t - r := by
    rw [hs]; simp only [List.length_take, List.length_drop]; omega
  have hget : ∀ j, j < s.length → s[j]? = p[r + j]? := by
    intro j hj
    rw [hs, List.getElem?_take]
    simp only [hlen] at hj
    rw [if_pos hj, List.getElem?_drop]
  have hb : ∀ k, t = r + k → p[r + k]? = none ∨ p[r + k]? = some slash := by
    intro k hk
    rcases he with he | he
    · left; rw [← hk, he]; simp
    · right; rwa [hk] at he
  have hpos : r < t := by
    by_contra h
    have ht' : t = r := by omega
    rcases hb 0 (by omega) with he | he
    · exact ha.1 (by simpa using he)
    · exact ha.2.1 (by simpa using he)
  refine ⟨⟨?_, hn, ?_, ?_⟩, hpos⟩
  · intro he; simp [he] at hlen; omega
  · intro hd
    have hp : p[r]? = some dot := by
      have hg := hget 0 (by simp [hd])
      simpa [hd] using hg.symm
    rcases hb 1 (by simp [hd] at hlen; omega) with he | he
    · exact (ha.2.2.1 hp).1 he
    · exact (ha.2.2.1 hp).2 he
  · intro hd
    have hp : p[r]? = some dot := by
      have hg := hget 0 (by simp [hd])
      simpa [hd] using hg.symm
    have hp1 : p[r + 1]? = some dot := by
      have hg := hget 1 (by simp [hd])
      simpa [hd] using hg.symm
    rcases hb 2 (by simp [hd] at hlen; omega) with he | he
    · exact (ha.2.2.2 hp hp1).1 he
    · exact (ha.2.2.2 hp hp1).2 he

def Inv (p : Slice U8) (x : Bool × alloc.vec.Vec U8 × Usize × Usize × Usize) : Prop :=
  x.2.2.2.1.val ≤ p.val.length ∧ x.2.2.1.val ≤ x.2.1.val.length ∧
  Normal x.1 x.2.2.2.2.val (x.2.1.val.take x.2.2.1.val)

lemma ordinary_ok (p : Slice U8) (root : Bool) (buf : alloc.vec.Vec U8)
    (w r d : Usize) (z)
    (hi : Inv p (root, buf, w, r, d)) (ha : OrdinaryAt p.val r.val)
    (h : ordinary p root buf w r d = ok z) :
    match (generalizing := false) z with
    | cont x => Inv p x ∧ r.val < x.2.2.2.1.val
    | done _ => False := by
  rcases hi with ⟨hr, hw, hn⟩
  dsimp only at hr hw hn
  unfold ordinary at h
  h5i_invert h
  obtain ⟨b, v⟩ := x
  change (do let (b', v', t) ← pathclean.copy_element b v p r
             ok (cont (root, b', v', t, d))) = ok z at h
  h5i_invert h
  obtain ⟨b', v', t⟩ := x
  change ok (cont (root, b', v', t, d)) = ok z at h
  have hz := result_ok_inj h
  subst z
  obtain ⟨hb, he⟩ := separator_ok root buf b w v hw (by
    have := normal_bounds hn; simp only [List.length_take] at this; omega) hx
  obtain ⟨s, hbs, hs, hslash, hrt, ht, hv, hvb, hend⟩ := copy_ok p b b' v r v' t hr hb hx_1
  obtain ⟨hseg, hprogress⟩ := copied_segment ha hs hslash hrt ht hend
  refine ⟨⟨ht, hvb, ?_⟩, hprogress⟩
  dsimp [Inv]
  rw [hbs, he]
  exact Normal.part hn hseg

lemma dots_ok (b : alloc.vec.Vec U8) (v t : Usize) (z)
    (h : dots b v t = ok z) :
    ∃ b' v', z = cont (false, b', v', t, v') ∧ v'.val ≤ b'.val.length ∧
      b'.val.take v'.val = b.val.take v.val ++ [dot, dot] := by
  unfold dots at h
  h5i_invert h
  obtain ⟨a, back⟩ := x
  change (do let v' ← v + 1#usize
             let (_, back') ← alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) (back dot) v'
             let v'' ← v' + 1#usize
             ok (cont (false, back' dot, v'', t, v''))) = ok z at h
  h5i_invert h
  obtain ⟨a', back'⟩ := x
  change (do let v'' ← v' + 1#usize
             ok (cont (false, back' dot, v'', t, v''))) = ok z at h
  h5i_invert h
  obtain ⟨hv, hb⟩ := mut_ok hx
  obtain ⟨hbound, hb'⟩ := mut_ok hx_1
  have h1 := add_ok_val hv'
  have h2 := add_ok_val hv''
  refine ⟨back' dot, v'', rfl, ?_, ?_⟩
  · rw [hb']; simp; simp at h2; omega
  · rw [hb']; simp only [alloc.vec.Vec.set_val_eq]
    rw [show v''.val = v'.val + 1 by simpa using h2, set_take_succ _ _ _ hbound, hb]
    simp only [alloc.vec.Vec.set_val_eq]
    rw [show v'.val = v.val + 1 by simpa using h1, set_take_succ _ _ _ hv,
      List.append_assoc]
    rfl

lemma parent_separator_eq (buf : alloc.vec.Vec U8) (w : Usize) :
    (if w > 0#usize then write buf w slash else ok (buf, w)) = separator false buf w := by
  unfold separator
  simp only [Bool.false_eq_true, ↓reduceIte]
  have he : (w > 0#usize) ↔ (w != 0#usize) = true := by
    simp; omega
  simp only [he]

lemma up_ok (p : Slice U8) (root : Bool) (buf : alloc.vec.Vec U8) (w r t d : Usize) (z)
    (hi : Inv p (root, buf, w, r, d)) (ht : t.val ≤ p.val.length)
    (h : up root buf w t d = ok z) :
    match (generalizing := false) z with
    | cont x => Inv p x ∧ x.2.2.2.1 = t
    | done _ => False := by
  rcases hi with ⟨hr, hw, hn⟩
  dsimp only at hr hw hn
  have hd := normal_bounds hn
  simp only [List.length_take, Nat.min_eq_left hw] at hd
  unfold up at h
  h5i_invert h
  all_goals try dsimp only [Inv]
  · have hv := sub_ok_val hv
    simp only [UScalar.ofNatCore_val_eq] at hv
    obtain ⟨hdu, huw, hu⟩ := back_ok buf.deref v d u (by scalar_tac) hu
    refine ⟨⟨ht, by omega, ?_⟩, rfl⟩
    have hcut : (buf.val.take w.val).take u.val = buf.val.take u.val := by
      rw [List.take_take, Nat.min_eq_left (by omega)]
    rw [← hcut]
    rcases hu with hu | hu
    · rw [hu]; exact normal_cut_d hn
    · apply normal_cut_slash hn u.val hdu (by simp [List.length_take, hw]; omega)
      rw [List.getElem?_take]; rw [if_pos (by omega)]
      simpa only [alloc.vec.Vec.deref, alloc.vec.Vec.val, Slice.from_val] using hu
  · have hroot : root = true := by assumption
    subst root
    exact ⟨⟨ht, hw, hn⟩, rfl⟩
  · have hroot : root = false := by cases root <;> simp_all
    subst root
    obtain ⟨b, v⟩ := x
    change dots b v t = ok z at h
    obtain ⟨b', v', rfl, hb', he⟩ := dots_ok b v t z h
    rw [parent_separator_eq] at hx
    obtain ⟨hb, hs⟩ := separator_ok false buf b w v hw (by simp [base]) hx
    have hwd : w.val = d.val := by scalar_tac
    dsimp only [Inv]
    refine ⟨⟨ht, hb', ?_⟩, rfl⟩
    rw [he, hs]
    have hparent : Normal false (buf.val.take w.val).length (buf.val.take w.val) := by
      have hlen : (buf.val.take w.val).length = d.val := by
        rw [List.length_take, Nat.min_eq_left hw]; exact hwd
      rw [hlen]
      exact hn
    have hp := Normal.parent hparent
    have hlen : (b'.val.take v'.val).length = v'.val := by simp [List.length_take, Nat.min_eq_left hb']
    rw [he, hs] at hlen
    rwa [hlen] at hp

lemma body_ok (p : Slice U8) (n : Usize) (hn : n.val = p.val.length)
    (root : Bool) (buf : alloc.vec.Vec U8) (w r d : Usize) (z)
    (hi : Inv p (root, buf, w, r, d))
    (h : pathclean.clean_loop0.body p n root buf w r d = ok z) :
    match (generalizing := false) z with
    | cont x => Inv p x ∧ r.val < x.2.2.2.1.val ∧ x.2.2.2.1.val ≤ p.val.length
    | done (b, v) => v.val ≤ b.val.length ∧ ∃ root d, Normal root d (b.val.take v.val) := by
  rw [body_eq] at h
  unfold body at h
  h5i_invert h
  all_goals h5i_ok_facts
  all_goals simp only [alloc.vec.Vec.val, UScalar.ofNatCore_val_eq,
    UScalar.lt_equiv, Slice.len_val] at *
  all_goals first
    | (have ho := ordinary_ok p root buf w r d z hi (by simp_all [OrdinaryAt]) h
       cases z with
       | done y => exact False.elim ho
       | cont x => exact ⟨ho.1, ho.2, ho.1.1⟩)
    | (have huBound : u.val ≤ p.val.length := by
         first | scalar_tac | (have hb := (slice_index_ok hc_7).1; omega)
       have ho := up_ok p root buf w r u d z hi huBound h
       cases z with
       | done y => exact False.elim ho
       | cont x => exact ⟨ho.1, by rw [ho.2]; omega, by rw [ho.2]; exact huBound⟩)
    | (rcases hi with ⟨hr, hw, hp⟩
       dsimp only at hr hw hp
       dsimp only [Inv]
       exact ⟨⟨by omega, hw, hp⟩, by omega, by omega⟩)
    | (rcases hi with ⟨hr, hw, hp⟩
       dsimp only at hr hw hp
       exact ⟨hw, root, d.val, hp⟩)

lemma scan_ok (p : Slice U8) (n : Usize) (root : Bool) (buf b : alloc.vec.Vec U8)
    (w r d v : Usize) (hn : n.val = p.val.length) (hi : Inv p (root, buf, w, r, d))
    (h : pathclean.clean_loop0 p n root buf w r d = ok (b, v)) :
    v.val ≤ b.val.length ∧ ∃ root d, Normal root d (b.val.take v.val) := by
  unfold pathclean.clean_loop0 at h
  apply loop_idx_ok (fun (root, buf, w, r, d) => pathclean.clean_loop0.body p n root buf w r d)
    (fun x => x.2.2.2.1) p.val.length (Inv p)
    (fun (b, v) => v.val ≤ b.val.length ∧ ∃ root d, Normal root d (b.val.take v.val))
    ?_ (root, buf, w, r, d) (b, v) hi hi.1 h
  rintro ⟨root, buf, w, r, d⟩ z hi hr hz
  have ho := body_ok p n hn root buf w r d z hi hz
  cases z with
  | cont x => exact ho
  | done y => rcases y with ⟨b, v⟩; exact ho

@[step] lemma output_spec (buf : alloc.vec.Vec U8) (w : Usize)
    (hw : w.val ≤ buf.val.length) :
    pathclean.clean_loop1 buf w (alloc.vec.Vec.new U8) 0#usize
      ⦃ out => out.val = buf.val.take w.val ⦄ := by
  unfold pathclean.clean_loop1
  apply loop_idx_spec _ (fun (x : alloc.vec.Vec U8 × Usize) => x.2) w.val
    (fun x => x.1.val = buf.val.take x.2.val)
    (fun (out : alloc.vec.Vec U8) => out.val = buf.val.take w.val) ?_ _ (by simp) (by simp)
  rintro ⟨out, i⟩ hi hb
  dsimp only at hi hb
  unfold pathclean.clean_loop1.body
  dsimp only
  split
  · rename_i hlt
    step*
    all_goals try scalar_tac
    simp only [out1_post, i1_post, i2_post, hi]
    exact ⟨(List.take_succ_eq_append_getElem (by scalar_tac)).symm, by scalar_tac, by scalar_tac⟩
  · simp only [spec_ok]
    have he : i = w := by scalar_tac
    simpa [he] using hi

@[step] lemma to_vec_spec (p : Slice U8) :
    alloc.slice.Slice.to_vec core.clone.CloneU8 p ⦃v => v.val = p.val⦄ := by
  step*
  simpa only [alloc.vec.Vec.val] using congrArg Slice.val p_post.symm

def dotVec : alloc.vec.Vec U8 := vecOf [dot]

lemma dotVec_eq :
    (do let s ← lift (Array.to_slice (Array.make 1#usize [dot]))
        alloc.slice.Slice.to_vec core.clone.CloneU8 s) = ok dotVec := by
  apply eq_ok_of_spec
  step*
  apply alloc.vec.Vec.ext
  simp_all [dotVec]

def initial (a : U8) (buf : alloc.vec.Vec U8) :
    Result (Bool × alloc.vec.Vec U8 × Usize × Usize × Usize) := do
  if a = slash then
    let (_, back) ← alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) buf 0#usize
    let w ← 0#usize + 1#usize
    ok (true, back slash, w, 1#usize, 1#usize)
  else ok (false, buf, 0#usize, 0#usize, 0#usize)

@[step] lemma initial_spec (p : Slice U8) (a : U8) (buf : alloc.vec.Vec U8)
    (hp : p.val ≠ []) (hb : buf.val = p.val) : initial a buf ⦃ x => Inv p x ⦄ := by
  unfold initial
  have hpLen : 0 < p.val.length := by cases he : p.val <;> simp_all
  step*
  all_goals try dsimp only [Inv]
  · simp only [back_post, alloc.vec.Vec.set_val_eq, w_post, UScalar.ofNatCore_val_eq,
      Nat.zero_add, List.length_set]
    refine ⟨by omega, by rw [hb]; omega, ?_⟩
    rw [set_take_succ _ 0 slash (by rw [hb]; omega)]
    exact Normal.start true
  · simp only [UScalar.ofNatCore_val_eq, List.take_zero]
    exact ⟨by omega, by omega, Normal.start false⟩

lemma clean_normal (p : Slice U8) (c : alloc.vec.Vec U8) (h : pathclean.clean p = ok c) :
    c = dotVec ∨ ∃ root d, Normal root d c.val ∧ c.val ≠ [] := by
  unfold pathclean.clean at h
  rw [dotVec_eq] at h
  change (if p.len = 0#usize then ok dotVec else do
    let a ← p.index_usize 0#usize
    let b ← alloc.slice.Slice.to_vec core.clone.CloneU8 p
    let (root, b', w, r, d) ← initial a b
    let (b'', v) ← pathclean.clean_loop0 p p.len root b' w r d
    if v = 0#usize then ok dotVec
    else pathclean.clean_loop1 b'' v (alloc.vec.Vec.new U8) 0#usize) = ok c at h
  h5i_invert h
  · exact Or.inl rfl
  · obtain ⟨root, b', w, r, d⟩ := x
    have hp : p.val ≠ [] := by intro he; simp [he, Slice.len] at hc
    have hbuf := post_of_ok (to_vec_spec p) hb
    have hi := post_of_ok (initial_spec p a b hp hbuf) hx
    change (do let (b'', v) ← pathclean.clean_loop0 p p.len root b' w r d
               if v = 0#usize then ok dotVec
               else pathclean.clean_loop1 b'' v (alloc.vec.Vec.new U8) 0#usize) = ok c at h
    h5i_invert h
    obtain ⟨b'', v⟩ := x
    change (if v = 0#usize then ok dotVec
            else pathclean.clean_loop1 b'' v (alloc.vec.Vec.new U8) 0#usize) = ok c at h
    obtain ⟨hv, root', d', hnormal⟩ := scan_ok p p.len root b' b'' w r d v (by simp) hi hx_1
    split at h
    · have he := result_ok_inj h; exact Or.inl he.symm
    · have he := post_of_ok (output_spec b'' v hv) h
      refine Or.inr ⟨root', d', he.symm ▸ hnormal, ?_⟩
      intro hnil
      have hl := congrArg List.length he
      rw [hnil] at hl
      simp only [List.length_nil, List.length_take, Nat.min_eq_left hv] at hl
      have hzero : v = 0#usize := by scalar_tac
      contradiction

def ix (k : Nat) (h : k ≤ Usize.max) : Usize := Usize.ofNatCore k (by scalar_tac)
@[simp] lemma ix_val (k h) : (ix k h).val = k := by simp [ix]

lemma add_eq (a b c : Usize) (h : c.val = a.val + b.val) : a + b = ok c := by
  apply eq_ok_of_spec
  step*
  all_goals scalar_tac

lemma read_eq (p : Slice U8) (r : Usize) (a : U8) (h : p.val[r.val]? = some a) :
    p.index_usize r = ok a := by simp [Slice.index_usize, h]

lemma mut_eq (buf : alloc.vec.Vec U8) (r : Usize) (a : U8) (h : buf.val[r.val]? = some a) :
    alloc.vec.Vec.index_mut (core.slice.index.SliceIndexUsizeSlice U8) buf r =
      ok (a, buf.set r) := by
  simp [alloc.vec.Vec.index_mut_slice_index, alloc.vec.Vec.index_mut_usize,
    alloc.vec.Vec.index_usize, h]

lemma set_same (buf : alloc.vec.Vec U8) (r : Usize) (a : U8) (h : buf.val[r.val]? = some a) :
    buf.set r a = buf := by
  apply alloc.vec.Vec.ext
  simp only [alloc.vec.Vec.set_val_eq]
  obtain ⟨hb, he⟩ := List.getElem?_eq_some_iff.mp h
  rw [← he]
  simp

lemma write_same_eq (buf : alloc.vec.Vec U8) (r t : Usize) (a : U8)
    (hr : buf.val[r.val]? = some a) (ht : t.val = r.val + 1) :
    write buf r a = ok (buf, t) := by
  simp only [write, mut_eq buf r a hr, bind_tc_ok, bind_ok, uncurry_apply_pair, add_eq r 1#usize t (by simpa using ht),
    set_same buf r a hr]

def Boundary (tail : List U8) : Prop := tail = [] ∨ tail.head? = some slash

lemma at_boundary {pre tail : List U8} (hb : Boundary tail) :
    (pre ++ tail)[pre.length]? = none ∨ (pre ++ tail)[pre.length]? = some slash := by
  rw [List.getElem?_append_right (by omega : pre.length ≤ pre.length)]
  simp only [Nat.sub_self]
  rcases hb with rfl | hb
  · exact Or.inl rfl
  · exact Or.inr (by simpa only [List.head?_eq_getElem?] using hb)

lemma copy_fixed (s : List U8) (hs : slash ∉ s) (tail : List U8) (hb : Boundary tail)
    (p : Slice U8) (buf : alloc.vec.Vec U8) (hbuf : buf.val = p.val)
    (pre : List U8) (hp : p.val = pre ++ s ++ tail) (r e : Usize)
    (hr : r.val = pre.length) (he : e.val = pre.length + s.length) :
    pathclean.copy_element buf r p r = ok (buf, e, e) := by
  induction s generalizing pre r with
  | nil =>
      have hre : r = e := by simp at he; scalar_tac
      have hbound : p.val[r.val]? = none ∨ p.val[r.val]? = some slash := by
        simpa [hp, hr] using (at_boundary (pre := pre) hb)
      unfold pathclean.copy_element pathclean.copy_element_loop
      rw [loop]
      have hbody : pathclean.copy_element_loop.body p buf r r = ok (done (buf, r, r)) := by
        unfold pathclean.copy_element_loop.body
        rcases hbound with hnone | hslash
        · have hn : ¬r < p.len := by
            have hl := List.getElem?_eq_none_iff.mp hnone
            scalar_tac
          rw [if_neg hn]
        · have hl := (List.getElem?_eq_some_iff.mp hslash).1
          have hn : r < p.len := by scalar_tac
          simp [hn, read_eq p r slash hslash]
      subst r
      simp only [hbody, bind_tc_ok, bind_ok]
  | cons a s ih =>
      have hn : a ≠ slash := by intro he; exact hs (by simp [he])
      have hs' : slash ∉ s := fun h => hs (List.mem_cons_of_mem _ h)
      have hlen : pre.length + 1 ≤ Usize.max := by
        have := p.property
        rw [hp] at this
        simp only [List.length_append, List.length_cons] at this
        omega
      let r' := ix (pre.length + 1) hlen
      have hr' : r'.val = pre.length + 1 := by simp [r']
      have hread : p.val[r.val]? = some a := by
        rw [hp, hr, List.append_assoc, List.getElem?_append_right (by omega)]
        simp
      have hmut := mut_eq buf r a (hbuf ▸ hread)
      have hset := set_same buf r a (hbuf ▸ hread)
      have hadd := add_eq r 1#usize r' (by simp only [UScalar.ofNatCore_val_eq]; omega)
      have hlt : r < p.len := by
        have hl := (List.getElem?_eq_some_iff.mp hread).1
        scalar_tac
      have hbody : pathclean.copy_element_loop.body p buf r r = ok (cont (buf, r', r')) := by
        simp only [pathclean.copy_element_loop.body, if_pos hlt, read_eq p r a hread,
          bind_tc_ok, bind_ok, uncurry_apply_pair, bne_iff_ne, if_pos hn, hmut, hadd, hset]
      have hi := ih hs' (pre ++ [a]) (by simpa [List.append_assoc] using hp) r'
        (by simpa using hr') (by simp only [List.length_append, List.length_cons, List.length_nil] at *; omega)
      unfold pathclean.copy_element pathclean.copy_element_loop at hi ⊢
      rw [loop]
      simpa only [hbody, bind_tc_ok, bind_ok, uncurry_apply_pair] using hi

lemma append_get (pre rest : List U8) (j : Nat) :
    (pre ++ rest)[pre.length + j]? = rest[j]? := by
  rw [List.getElem?_append_right (by omega)]
  congr 1; omega

lemma segment_at (pre s tail : List U8) (hs : Segment s) :
    OrdinaryAt (pre ++ s ++ tail) pre.length := by
  rw [List.append_assoc]
  have h0 := append_get pre (s ++ tail) 0
  simp only [Nat.add_zero] at h0
  simp only [OrdinaryAt, h0, append_get]
  rcases hs with ⟨hnil, hn, hdot, hdots⟩
  cases s with
  | nil => exact False.elim (hnil rfl)
  | cons a s =>
      have ha : a ≠ slash := by intro he; exact hn (by simp [he])
      have hns : slash ∉ s := fun h => hn (List.mem_cons_of_mem _ h)
      cases s with
      | nil => simp_all
      | cons b s =>
          have hb : b ≠ slash := by intro he; exact hns (by simp [he])
          cases s with
          | nil => simp_all
          | cons c s =>
              have hc : c ≠ slash := by intro he; exact hns (by simp [he])
              simp_all

lemma body_ordinary_eq (p : Slice U8) (root : Bool) (buf : alloc.vec.Vec U8) (w r d : Usize)
    (ha : OrdinaryAt p.val r.val) :
    pathclean.clean_loop0.body p p.len root buf w r d = ordinary p root buf w r d := by
  rw [body_eq]
  cases hread : p.val[r.val]? with
  | none => exact False.elim (ha.1 hread)
  | some a =>
    have hlt : r < p.len := by
      have := (List.getElem?_eq_some_iff.mp hread).1; scalar_tac
    have hslash : a ≠ slash := by intro he; exact ha.2.1 (he ▸ hread)
    unfold body
    rw [if_pos hlt, read_eq p r a hread]
    simp only [bind_ok, if_neg hslash]
    by_cases hd : a = dot
    · have hat : p.val[r.val]? = some dot := hd ▸ hread
      have hnext := ha.2.2.1 hat
      cases hread1 : p.val[r.val + 1]? with
      | none => exact False.elim (hnext.1 hread1)
      | some b =>
        have hbound : r.val + 1 < p.val.length := (List.getElem?_eq_some_iff.mp hread1).1
        let t := ix (r.val + 1) (by have := p.property; omega)
        have ht : t.val = r.val + 1 := by simp [t]
        have htne : t ≠ p.len := by scalar_tac
        have hsb : b ≠ slash := by intro he; exact hnext.2 (he ▸ hread1)
        rw [if_pos hd, add_eq r 1#usize t (by simpa using ht)]
        simp only [bind_ok, if_neg htne, read_eq p t b (by simpa [ht] using hread1), if_neg hsb]
        by_cases hdb : b = dot
        · have hnext2 := ha.2.2.2 hat (hdb ▸ hread1)
          cases hread2 : p.val[r.val + 2]? with
          | none => exact False.elim (hnext2.1 hread2)
          | some c =>
            have hbound2 : r.val + 2 < p.val.length := (List.getElem?_eq_some_iff.mp hread2).1
            let u := ix (r.val + 2) (by have := p.property; omega)
            have hu : u.val = r.val + 2 := by simp [u]
            have hune : u ≠ p.len := by scalar_tac
            have hsc : c ≠ slash := by intro he; exact hnext2.2 (he ▸ hread2)
            rw [if_pos hdb, add_eq r 2#usize u (by simpa using hu)]
            simp only [bind_ok, if_neg hune, read_eq p u c (by simpa [hu] using hread2), if_neg hsc]
        · simp only [if_neg hdb]
    · simp only [if_neg hd]

def start (root : Bool) : Usize := if root then 1#usize else 0#usize
@[simp] lemma start_val (root) : (start root).val = (base root).length := by
  cases root <;> simp [start, base]

lemma scan_step (p : Slice U8) (root root' : Bool) (buf b : alloc.vec.Vec U8)
    (w r d v t δ : Usize)
    (h : pathclean.clean_loop0.body p p.len root buf w r d = ok (cont (root', b, v, t, δ))) :
    pathclean.clean_loop0 p p.len root buf w r d =
      pathclean.clean_loop0 p p.len root' b v t δ := by
  unfold pathclean.clean_loop0
  rw [loop]
  simp only [h, bind_ok]

lemma separator_same (p : Slice U8) (buf : alloc.vec.Vec U8) (hbuf : buf.val = p.val)
    (root : Bool) (xs rest : List U8) (hp : p.val = xs ++ sep root xs ++ rest)
    (w r : Usize) (hw : w.val = xs.length)
    (hr : r.val = xs.length + (sep root xs).length) :
    separator root buf w = ok (buf, r) := by
  by_cases hk : xs.length = (base root).length
  · have hs : sep root xs = [] := by simp [sep, hk]
    have hwr : w = r := by simp [hs] at hr; scalar_tac
    have hws : w = start root := by have := start_val root; scalar_tac
    rw [← hwr, hws]
    cases root <;> simp [separator, start]
  · have hs : sep root xs = [slash] := by simp [sep, hk]
    have hread : p.val[w.val]? = some slash := by
      rw [hp, hw, List.append_assoc, List.getElem?_append_right (by omega)]
      simp [hs]
    have hr' : r.val = w.val + 1 := by simp [hs, hw] at hr ⊢; exact hr
    have he := write_same_eq buf w r slash (hbuf ▸ hread) hr'
    cases root
    · have hn : w ≠ 0#usize := by
        simp only [base, Bool.false_eq_true, ↓reduceIte, List.length_nil] at hk
        scalar_tac
      simpa only [separator, Bool.false_eq_true, ↓reduceIte, bne_iff_ne, if_pos hn] using he
    · have hn : w ≠ 1#usize := by
        simp only [base, ↓reduceIte, List.length_cons, List.length_nil] at hk
        scalar_tac
      simpa only [separator, ↓reduceIte, bne_iff_ne, if_pos hn] using he

lemma skip_separator (p : Slice U8) (buf : alloc.vec.Vec U8) (root : Bool)
    (xs rest : List U8) (hp : p.val = xs ++ sep root xs ++ rest)
    (w r d : Usize) (hw : w.val = xs.length)
    (hr : r.val = xs.length + (sep root xs).length) :
    pathclean.clean_loop0 p p.len root buf w w d =
      pathclean.clean_loop0 p p.len root buf w r d := by
  by_cases hk : xs.length = (base root).length
  · have hs : sep root xs = [] := by simp [sep, hk]
    have he : w = r := by simp [hs] at hr; scalar_tac
    rw [he]
  · have hs : sep root xs = [slash] := by simp [sep, hk]
    have hread : p.val[w.val]? = some slash := by
      rw [hp, hw, List.append_assoc, List.getElem?_append_right (by omega)]
      simp [hs]
    have hlt : w < p.len := by have := (List.getElem?_eq_some_iff.mp hread).1; scalar_tac
    apply scan_step
    rw [body_eq]
    simp only [body, if_pos hlt, read_eq p w slash hread, bind_ok, ↓reduceIte,
      add_eq w 1#usize r (by simp [hs, hw] at hr; simpa [hw] using hr)]

lemma part_scan (p : Slice U8) (buf : alloc.vec.Vec U8) (hbuf : buf.val = p.val)
    (root : Bool) (xs s tail : List U8) (hs : Segment s) (hb : Boundary tail)
    (hp : p.val = xs ++ sep root xs ++ s ++ tail) (w e d : Usize)
    (hw : w.val = xs.length) (he : e.val = (xs ++ sep root xs ++ s).length) :
    pathclean.clean_loop0 p p.len root buf w w d =
      pathclean.clean_loop0 p p.len root buf e e d := by
  have hrbound : xs.length + (sep root xs).length ≤ Usize.max := by
    have := p.property; rw [hp] at this; simp only [List.length_append] at this; omega
  let r := ix (xs.length + (sep root xs).length) hrbound
  have hr : r.val = xs.length + (sep root xs).length := by simp [r]
  rw [skip_separator p buf root xs (s ++ tail) (by simpa [List.append_assoc] using hp) w r d hw hr]
  have hsep := separator_same p buf hbuf root xs (s ++ tail) (by simpa [List.append_assoc] using hp) w r hw hr
  apply scan_step
  rw [body_ordinary_eq p root buf w r d (by
    rw [hp, hr]; simpa only [List.length_append] using segment_at (xs ++ sep root xs) s tail hs)]
  have hcopy := copy_fixed s hs.2.1 tail hb p buf hbuf (xs ++ sep root xs) hp r e
    (by simpa using hr) (by simpa only [List.length_append] using he)
  simp only [ordinary, hsep, bind_ok, uncurry_apply_pair, hcopy]

lemma body_parent_eq (p : Slice U8) (root : Bool) (buf : alloc.vec.Vec U8)
    (pre tail : List U8) (hb : Boundary tail) (hp : p.val = pre ++ [dot, dot] ++ tail)
    (w r e d : Usize) (hr : r.val = pre.length) (he : e.val = pre.length + 2) :
    pathclean.clean_loop0.body p p.len root buf w r d = up root buf w e d := by
  have hlen : pre.length + 2 ≤ p.val.length := by rw [hp]; simp
  let t := ix (pre.length + 1) (by have := p.property; omega)
  have ht : t.val = pre.length + 1 := by simp [t]
  have hread : p.val[r.val]? = some dot := by rw [hp, hr, List.append_assoc]; simpa using append_get pre ([dot, dot] ++ tail) 0
  have hread1 : p.val[t.val]? = some dot := by rw [hp, ht, List.append_assoc, append_get]; rfl
  have hlt : r < p.len := by scalar_tac
  have htne : t ≠ p.len := by scalar_tac
  have hds : dot ≠ slash := by scalar_tac
  rw [body_eq]
  simp only [body, if_pos hlt, read_eq p r dot hread, bind_ok, if_neg hds, ↓reduceIte,
    add_eq r 1#usize t (by simpa using (show t.val = r.val + 1 by omega)), if_neg htne,
    read_eq p t dot hread1,
    add_eq r 2#usize e (by simpa using (show e.val = r.val + 2 by omega))]
  by_cases hen : e = p.len
  · simp only [if_pos hen]
  · have hread2 : p.val[e.val]? = some slash := by
      have hbd := at_boundary (pre := pre ++ [dot, dot]) hb
      have hbd' : p.val[e.val]? = none ∨ p.val[e.val]? = some slash := by
        simpa only [hp, he, List.length_append, List.length_cons, List.length_nil] using hbd
      rcases hbd' with hnone | hslash
      · have := List.getElem?_eq_none_iff.mp hnone
        exfalso; scalar_tac
      · exact hslash
    simp only [if_neg hen, read_eq p e slash hread2, bind_ok, ↓reduceIte]

lemma dots_same_eq (buf : alloc.vec.Vec U8) (r t e : Usize)
    (h0 : buf.val[r.val]? = some dot) (h1 : buf.val[t.val]? = some dot)
    (ht : t.val = r.val + 1) (he : e.val = t.val + 1) :
    dots buf r e = ok (cont (false, buf, e, e, e)) := by
  simp only [dots, mut_eq buf r dot h0, bind_ok, uncurry_apply_pair,
    add_eq r 1#usize t (by simpa using ht), set_same buf r dot h0,
    mut_eq buf t dot h1, add_eq t 1#usize e (by simpa using he), set_same buf t dot h1]

lemma parent_scan (p : Slice U8) (buf : alloc.vec.Vec U8) (hbuf : buf.val = p.val)
    (xs tail : List U8) (hb : Boundary tail)
    (hp : p.val = xs ++ sep false xs ++ [dot, dot] ++ tail) (w e : Usize)
    (hw : w.val = xs.length) (he : e.val = (xs ++ sep false xs ++ [dot, dot]).length) :
    pathclean.clean_loop0 p p.len false buf w w w =
      pathclean.clean_loop0 p p.len false buf e e e := by
  have hrbound : xs.length + (sep false xs).length + 1 ≤ Usize.max := by
    have := p.property; rw [hp] at this; simp only [List.length_append, List.length_cons, List.length_nil] at this; omega
  let r := ix (xs.length + (sep false xs).length) (by omega)
  let t := ix (xs.length + (sep false xs).length + 1) hrbound
  have hr : r.val = xs.length + (sep false xs).length := by simp [r]
  have ht : t.val = r.val + 1 := by simp [r, t]
  rw [skip_separator p buf false xs ([dot, dot] ++ tail) (by simpa [List.append_assoc] using hp) w r w hw hr]
  apply scan_step
  rw [body_parent_eq p false buf (xs ++ sep false xs) tail hb hp w r e w
    (by simpa using hr) (by simpa only [List.length_append, List.length_cons, List.length_nil] using he)]
  have hsep := separator_same p buf hbuf false xs ([dot, dot] ++ tail) (by simpa [List.append_assoc] using hp) w r hw hr
  have h0 : buf.val[r.val]? = some dot := by
    rw [hbuf, hp, hr, List.append_assoc, List.append_assoc]
    simpa using append_get (xs ++ sep false xs) ([dot, dot] ++ tail) 0
  have h1 : buf.val[t.val]? = some dot := by
    rw [hbuf, hp, ht, hr]
    have hg := append_get (xs ++ sep false xs) ([dot, dot] ++ tail) 1
    simpa [List.length_append, List.append_assoc] using hg
  have hDots := dots_same_eq buf r t e h0 h1 ht (by
    simp only [List.length_append, List.length_cons, List.length_nil] at he; omega)
  simp only [up, gt_iff_lt, lt_self_iff_false, Bool.false_eq_true, ↓reduceIte, parent_separator_eq, hsep,
    bind_ok, uncurry_apply_pair, hDots]

lemma normal_base_eq {root d xs} (hn : Normal root d xs)
    (he : xs.length = (base root).length) : xs = base root := by
  cases hn with
  | start => rfl
  | @part root d xs s hn hs =>
      have hb := normal_bounds hn
      have hp : 0 < s.length := List.length_pos_iff.mpr hs.1
      simp only [List.length_append] at he
      omega
  | @parent xs hn =>
      simp only [base, Bool.false_eq_true, ↓reduceIte, List.length_append,
        List.length_cons, List.length_nil] at he
      omega

lemma extended_nonbase {root d xs} (hn : Normal root d xs) (s : List U8) (hs : s ≠ []) :
    xs ++ sep root xs ++ s ≠ base root := by
  intro he
  have hb := normal_bounds hn
  have hp : 0 < s.length := List.length_pos_iff.mpr hs
  have he := congrArg List.length he
  simp only [List.length_append] at he
  omega

lemma next_admissible {root d xs} (hn : Normal root d xs) (s tail : List U8) :
    xs = base root ∨ Boundary (sep root xs ++ s ++ tail) := by
  by_cases hk : xs.length = (base root).length
  · exact Or.inl (normal_base_eq hn hk)
  · right; right
    simp [sep, hk]

lemma normal_trace {root d xs} (hn : Normal root d xs) :
    ∀ (tail : List U8), (xs = base root ∨ Boundary tail) →
    ∀ (p : Slice U8) (buf : alloc.vec.Vec U8), buf.val = p.val →
    p.val = xs ++ tail → ∀ (e δ : Usize), e.val = xs.length → δ.val = d →
    pathclean.clean_loop0 p p.len root buf (start root) (start root) (start root) =
      pathclean.clean_loop0 p p.len root buf e e δ := by
  induction hn with
  | start root =>
      intro tail hb p buf hbuf hp e δ he hd
      have hes : e = start root := by have := start_val root; scalar_tac
      have hds : δ = start root := by have := start_val root; scalar_tac
      rw [hes, hds]
  | @part root d xs s hn hs ih =>
      intro tail hb p buf hbuf hp e δ he hd
      have htail : Boundary tail := by
        rcases hb with hb | hb
        · exact False.elim (extended_nonbase hn s hs.1 hb)
        · exact hb
      have hwbound : xs.length ≤ Usize.max := by
        have := p.property; rw [hp] at this; simp only [List.length_append] at this; omega
      let w := ix xs.length hwbound
      have hw : w.val = xs.length := by simp [w]
      rw [ih (sep root xs ++ s ++ tail) (next_admissible hn s tail) p buf hbuf
        (by simpa [List.append_assoc] using hp) w δ hw hd]
      exact part_scan p buf hbuf root xs s tail hs htail hp w e δ hw he
  | @parent xs hn ih =>
      intro tail hb p buf hbuf hp e δ he hd
      have htail : Boundary tail := by
        rcases hb with hb | hb
        · exact False.elim (extended_nonbase hn [dot, dot] (by simp) hb)
        · exact hb
      have hwbound : xs.length ≤ Usize.max := by
        have := p.property; rw [hp] at this; simp only [List.length_append] at this; omega
      let w := ix xs.length hwbound
      have hw : w.val = xs.length := by simp [w]
      have hδ : δ = e := by scalar_tac
      rw [hδ]
      rw [ih (sep false xs ++ [dot, dot] ++ tail) (next_admissible hn [dot, dot] tail) p buf hbuf
        (by simpa [List.append_assoc] using hp) w w hw hw]
      exact parent_scan p buf hbuf xs tail htail hp w e hw he

lemma canonical_scan (p : Slice U8) (buf : alloc.vec.Vec U8) (hbuf : buf.val = p.val)
    (root : Bool) (d : Nat) (hn : Normal root d p.val) :
    pathclean.clean_loop0 p p.len root buf (start root) (start root) (start root) = ok (buf, p.len) := by
  let δ := ix d (by have := normal_bounds hn; have := p.property; omega)
  rw [normal_trace hn [] (Or.inr (Or.inl rfl)) p buf hbuf (by simp) p.len δ (by simp) (by simp [δ])]
  unfold pathclean.clean_loop0
  rw [loop]
  have hbody : pathclean.clean_loop0.body p p.len root buf p.len p.len δ = ok (done (buf, p.len)) := by
    rw [body_eq]
    simp [body]
  simp only [hbody, bind_ok]

lemma normal_head {root d xs} (hn : Normal root d xs) :
    xs[0]? = some slash ↔ root = true := by
  induction hn with
  | start root => cases root <;> simp [base]
  | @part root d xs s hn hs ih =>
      by_cases hxs : xs = []
      · have hroot : root = false := by
          have hb := normal_bounds hn
          rw [hxs] at hb
          cases root <;> simp_all [base]
        subst root
        subst xs
        simp only [sep, base, Bool.false_eq_true, ↓reduceIte, List.length_nil,
          List.append_nil, List.nil_append]
        exact ⟨fun h => hs.2.1 (get_mem h), False.elim⟩
      · have hp : 0 < xs.length := List.length_pos_iff.mpr hxs
        rw [List.getElem?_append_left (by simp; omega), List.getElem?_append_left hp]
        exact ih
  | @parent xs hn ih =>
      by_cases hxs : xs = []
      · subst xs; simp [sep, base]
      · have hp : 0 < xs.length := List.length_pos_iff.mpr hxs
        rw [List.getElem?_append_left (by simp; omega), List.getElem?_append_left hp]
        exact ih

lemma initial_same (p : Slice U8) (buf : alloc.vec.Vec U8) (hbuf : buf.val = p.val)
    (root : Bool) (d : Nat) (hn : Normal root d p.val) (a : U8)
    (hread : p.val[0]? = some a) :
    initial a buf = ok (root, buf, start root, start root, start root) := by
  have hroot := normal_head hn
  cases root
  · have hne : a ≠ slash := by intro he; cases hroot.mp (he ▸ hread)
    simp [initial, hne, start]
  · have ha : a = slash := by have := hroot.mpr rfl; rw [hread] at this; exact Option.some.inj this
    subst a
    simp only [initial, ↓reduceIte, mut_eq buf 0#usize slash (by simpa using hbuf ▸ hread),
      bind_ok, uncurry_apply_pair, add_eq 0#usize 1#usize 1#usize (by simp),
      set_same buf 0#usize slash (by simpa using hbuf ▸ hread), start, ↓reduceIte]

lemma canonical_clean (c : alloc.vec.Vec U8) (root : Bool) (d : Nat)
    (hn : Normal root d c.val) (hne : c.val ≠ []) : pathclean.clean c.deref = ok c := by
  let p := c.deref
  have hp : p.val = c.val := by simp [p, alloc.vec.Vec.deref, alloc.vec.Vec.val]
  have hnormal : Normal root d p.val := hp.symm ▸ hn
  have hlen : p.len ≠ 0#usize := by
    intro hz
    have hv := congrArg UScalar.val hz
    have hzero : c.val.length = 0 := by simpa [hp] using hv
    exact hne (List.length_eq_zero_iff.mp hzero)
  unfold pathclean.clean
  rw [if_neg hlen]
  have hr : ∃ a, p.val[0]? = some a := by
    cases hs : p.val with
    | nil => exact False.elim (hne (hp.symm.trans hs))
    | cons a s => exact ⟨a, by simp [hs]⟩
  obtain ⟨a, ha⟩ := hr
  have hclone : alloc.slice.Slice.to_vec core.clone.CloneU8 p = ok c :=
    eq_ok_of_spec (by
      apply spec_mono (to_vec_spec p)
      intro v hv
      exact alloc.vec.Vec.ext _ _ (hv.trans hp))
  change (do let a ← p.index_usize 0#usize
             let b ← alloc.slice.Slice.to_vec core.clone.CloneU8 p
             let (root, b', w, r, d) ← initial a b
             let (b'', v) ← pathclean.clean_loop0 p p.len root b' w r d
             if v = 0#usize then _ else
               pathclean.clean_loop1 b'' v (alloc.vec.Vec.new U8) 0#usize) = ok c
  rw [read_eq p 0#usize a (by simpa using ha), hclone]
  simp only [bind_ok, initial_same p c hp.symm root d hnormal a ha, uncurry_apply_pair,
    canonical_scan p c hp.symm root d hnormal, if_neg hlen]
  apply eq_ok_of_spec
  apply spec_mono (output_spec c p.len (by simp [hp]))
  intro out hout
  apply alloc.vec.Vec.ext
  simpa [hp] using hout

lemma dot_clean : pathclean.clean dotVec.deref = ok dotVec := by
  let p := dotVec.deref
  have hp : p.val = [dot] := by simp [p, dotVec, alloc.vec.Vec.deref]
  have hlen : p.len = 1#usize := by scalar_tac
  have hnzero : p.len ≠ 0#usize := by rw [hlen]; decide
  have ha : p.val[0]? = some dot := by simp [hp]
  have hclone : alloc.slice.Slice.to_vec core.clone.CloneU8 p = ok dotVec :=
    eq_ok_of_spec (by
      apply spec_mono (to_vec_spec p)
      intro v hv
      apply alloc.vec.Vec.ext
      simpa [dotVec] using hv.trans hp)
  have hbody : pathclean.clean_loop0.body p p.len false dotVec 0#usize 0#usize 0#usize =
      ok (cont (false, dotVec, 0#usize, 1#usize, 0#usize)) := by
    rw [body_eq]
    simp only [body, hlen]
    rw [if_pos (by decide : 0#usize < 1#usize), read_eq p 0#usize dot (by simpa using ha)]
    simp only [bind_ok]
    simp only [if_neg (by decide : dot ≠ slash), ↓reduceIte,
      add_eq 0#usize 1#usize 1#usize (by simp), bind_ok]
  have hscan : pathclean.clean_loop0 p p.len false dotVec 0#usize 0#usize 0#usize =
      ok (dotVec, 0#usize) := by
    rw [scan_step p false false dotVec dotVec _ _ _ _ _ _ hbody]
    unfold pathclean.clean_loop0
    rw [loop]
    have hdone : pathclean.clean_loop0.body p p.len false dotVec 0#usize 1#usize 0#usize =
        ok (done (dotVec, 0#usize)) := by
      rw [body_eq]
      simp [body, hlen]
    simp only [hdone, bind_ok]
  unfold pathclean.clean
  rw [dotVec_eq]
  change (if p.len = 0#usize then ok dotVec else do
    let a ← p.index_usize 0#usize
    let b ← alloc.slice.Slice.to_vec core.clone.CloneU8 p
    let (root, b', w, r, d) ← initial a b
    let (b'', v) ← pathclean.clean_loop0 p p.len root b' w r d
    if v = 0#usize then ok dotVec
    else pathclean.clean_loop1 b'' v (alloc.vec.Vec.new U8) 0#usize) = ok dotVec
  rw [if_neg hnzero, read_eq p 0#usize dot (by simpa using ha), hclone]
  simp only [bind_ok, initial, show dot ≠ slash by decide, ↓reduceIte,
    uncurry_apply_pair, hscan]

theorem clean_idempotent (p : Slice U8) (c : alloc.vec.Vec U8) (h : pathclean.clean p = ok c) :
    pathclean.clean c.deref = ok c := by
  rcases clean_normal p c h with rfl | ⟨root, d, hn, hne⟩
  · exact dot_clean
  · exact canonical_clean c root d hn hne

end rustfs_kernel.Solution
