import Spec
open Aeneas Aeneas.Std Result windmill_kernel windmill_kernel.Spec H5iAppLib

set_option linter.unusedSimpArgs false

namespace windmill_kernel.Lemmas

h5i_derive_all

@[step] theorem starts_with_spec (s p : Slice U8) :
    bytes.starts_with s p ⦃ b => b = decide (p.val <+: s.val) ⦄ := by
  unfold bytes.starts_with; simp only []
  split
  · simp only [WP.spec_ok]
    have : ¬ p.val <+: s.val := fun h => by have := h.length_le; scalar_tac
    simp [this]
  · unfold bytes.starts_with_loop
    apply loop.spec_decr_nat (measure := fun (j : Usize) => p.length - j.val)
      (inv := fun j => j.val ≤ p.length ∧ ∀ k < j.val, s.val[k]! = p.val[k]!)
    · rintro j ⟨hj, hk⟩
      unfold bytes.starts_with_loop.body; simp only []
      step*
      · have : ¬ p.val <+: s.val := fun h => by
          have := h.getElem (i := j.val) (by scalar_tac); simp_all; contradiction
        simp [this]
      · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
        intro k hk'
        rcases Nat.lt_succ_iff_lt_or_eq.1 (show k < j.val + 1 by scalar_tac) with h1 | h1
        · exact hk k h1
        · subst h1
          rw [List.getElem!_eq_getElem?_getD, List.getElem!_eq_getElem?_getD,
            List.getElem?_eq_getElem (by scalar_tac), List.getElem?_eq_getElem (by scalar_tac)]
          simp only [Option.getD_some]
          apply UScalar.eq_of_val_eq
          simp_all
      · have hl : (p.val).length ≤ (s.val).length := by scalar_tac
        have : p.val <+: s.val := by
          rw [prefix_iff_take]; refine ⟨hl, ?_⟩
          apply List.ext_getElem (by simp; omega)
          intro n h1 h2
          have := hk n (by scalar_tac)
          simp at this
          rw [List.getElem?_eq_getElem (by omega)] at this
          simpa [List.getElem?_eq_getElem h2] using this
        simp [this]
    · simp
@[step] theorem eq_spec (a b : Slice U8) :
    bytes.eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold bytes.eq; simp only []
  split
  · simp only [WP.spec_ok]
    have : a.val ≠ b.val := fun h => by simp_all
    simp [this]
  · unfold bytes.eq_loop
    apply loop.spec_decr_nat (measure := fun (j : Usize) => a.length - j.val)
      (inv := fun j => j.val ≤ a.length ∧ ∀ k < j.val, a.val[k]! = b.val[k]!)
    · rintro j ⟨hj, hk⟩
      unfold bytes.eq_loop.body; simp only []
      step*
      · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
        intro k hk'
        rcases Nat.lt_succ_iff_lt_or_eq.1 (show k < j.val + 1 by scalar_tac) with h1 | h1
        · exact hk k h1
        · subst h1
          rw [List.getElem!_eq_getElem?_getD, List.getElem!_eq_getElem?_getD,
            List.getElem?_eq_getElem (by scalar_tac), List.getElem?_eq_getElem (by scalar_tac)]
          simp only [Option.getD_some]
          apply UScalar.eq_of_val_eq
          simp_all
      · have hl : (a.val).length = (b.val).length := by scalar_tac
        have : a.val = b.val := by
          apply List.ext_getElem hl
          intro n h1 h2
          have := hk n (by scalar_tac)
          simp at this
          rw [List.getElem?_eq_getElem (by omega)] at this
          simpa [List.getElem?_eq_getElem h2] using this
        simp [this]
    · simp


/-- `split` returns `Spec.segments` (for inputs shorter than `usize::MAX`). -/
@[step] theorem split_spec (s : Slice U8) (sep : U8) (hs : s.length < Usize.max) :
    bytes.split s sep ⦃ r => r.val.map (·.val) = segments sep s.val ⦄ := by
  unfold bytes.split bytes.split_loop
  have h := loop_fold2 (l := s.val) (abs := fun (o : alloc.vec.Vec (alloc.vec.Vec U8)) (c : alloc.vec.Vec U8) =>
      (o.val.map (·.val), c.val)) (g := H5iAppLib.splitStep sep)
    (Inv := fun o c i => o.length + c.length ≤ i)
    (body := fun x => bytes.split_loop.body s sep x.1 x.2.1 x.2.2) ?_
    (alloc.vec.Vec.new _) (alloc.vec.Vec.new _) 0#usize (by simp) (by simp)
  · apply WP.spec_bind (Pₘ := fun r => _) (by simpa using h)
    rintro ⟨o, c⟩ ⟨habs, hinv⟩
    have hlen : o.length < Usize.max := by scalar_tac
    apply WP.spec_mono (alloc.vec.Vec.push_spec o c hlen)
    intro r hr
    rw [hr, List.map_append]
    have := H5iAppLib.foldl_splitStep sep s.val [] []
    rw [← habs] at this
    simp only [List.nil_append, List.reverse_nil] at this
    simp only [List.map_cons, List.map_nil]
    rw [this]
    rfl
  · intro o c i hi hinv
    unfold bytes.split_loop.body
    simp only []
    split
    · step*
      split
      · step*
        refine ⟨by scalar_tac, ?_, by scalar_tac, by simp; scalar_tac⟩
        simp_all [H5iAppLib.splitStep]
      · step*
        refine ⟨by scalar_tac, ?_, by scalar_tac, by simp; scalar_tac⟩
        simp_all [H5iAppLib.splitStep]
    · simp only [WP.spec_ok]
      exact ⟨by scalar_tac, rfl, rfl⟩

@[step] theorem is_owner_loop_spec (v : alloc.vec.Vec authz.Folder) (n : Slice U8) :
    authz.is_owner_loop v n 0#usize ⦃ b => b = v.val.any (fun f => decide (f.name.val = n.val) && f.is_owner) ⦄ := by
  unfold authz.is_owner_loop
  h5i_search_any v.val (fun f => decide (f.name.val = n.val) && f.is_owner)
  all_goals simp_all [vec_deref_val]
  all_goals scalar_tac

@[step] theorem has_folder_loop_spec (a : authz.Authed) (n : Slice U8) :
    authz.has_folder_loop a n 0#usize ⦃ b => b = a.folders.val.any (fun f => decide (f.name.val = n.val)) ⦄ := by
  unfold authz.has_folder_loop
  h5i_search_any a.folders.val (fun f => decide (f.name.val = n.val))
  all_goals simp_all [vec_deref_val]
  all_goals scalar_tac

theorem dotdot_iff (l : List U8) : l = dotdot ↔ l.length = 2 ∧ l[0]? = some 46#u8 ∧ l[1]? = some 46#u8 := by
  constructor
  · rintro rfl; simp [dotdot]
  · rintro ⟨h2, h0, h1⟩
    match l, h2 with
    | [x, y], _ => simp_all [dotdot]

@[step] theorem is_dotdot_spec (s : Slice U8) : authz.is_dotdot s ⦃ b => b = decide (s.val = dotdot) ⦄ := by
  unfold authz.is_dotdot
  step*
  all_goals simp only [dotdot_iff]
  all_goals simp_all
  all_goals
    have hl : s.val.length = 2 := by scalar_tac
    simp [hl, List.getElem?_eq_getElem (show 1 < s.val.length by omega)]

@[step] theorem has_dotdot_spec (parts : Slice (alloc.vec.Vec U8)) :
    authz.has_dotdot_segment parts ⦃ b => b = parts.val.any (fun p => decide (p.val = dotdot)) ⦄ := by
  unfold authz.has_dotdot_segment authz.has_dotdot_segment_loop
  h5i_search_any parts.val (fun p => decide (p.val = dotdot))
  all_goals simp_all [vec_deref_val]
  all_goals scalar_tac

@[step] theorem has_nul_spec (s : Slice U8) :
    authz.has_nul s ⦃ b => b = s.val.any (fun c => decide (c = 0#u8)) ⦄ := by
  unfold authz.has_nul authz.has_nul_loop
  h5i_search_any s.val (fun c => decide (c = 0#u8))
  all_goals simp_all
  all_goals scalar_tac

@[step] theorem is_owner_spec (a : authz.Authed) (n : Slice U8) :
    authz.is_owner a n ⦃ b => (b = true ↔ ownsFolder a n.val) ⦄ := by
  unfold authz.is_owner
  split
  · simp_all [ownsFolder]
  · step*
    simp_all [ownsFolder]

theorem U_val : authz.U.val = uB := by simp [authz.U, uB, array_to_slice_val]
theorem F_val : authz.F.val = fB := by simp [authz.F, fB, array_to_slice_val]

/-- Reading the `i`-th piece of a split. -/
theorem seg_of {parts : alloc.vec.Vec (alloc.vec.Vec U8)} {segs : List Bytes}
    (hs : parts.val.map (·.val) = segs) {i : Usize} {v : alloc.vec.Vec U8}
    (hv : alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice (alloc.vec.Vec U8)) parts i = ok v) :
    segs[i.val]! = v.val := by
  have hg := vec_index_slice_ok_get? hv
  rw [← hs, List.getElem!_eq_getElem?_getD, List.getElem?_map, hg]
  rfl

theorem eq_true {a b : Slice U8} {r : Bool} (h : bytes.eq a b = ok r) (hr : r = true) : a.val = b.val := by
  have := post_of_ok (eq_spec a b) h
  subst hr
  simpa using this

theorem eq_false {a b : Slice U8} {r : Bool} (h : bytes.eq a b = ok r) (hr : ¬ r = true) : a.val ≠ b.val := by
  have := post_of_ok (eq_spec a b) h
  intro e; apply hr; rw [this]; simpa using e

theorem require_is_owner_ok {a : authz.Authed} {n : Slice U8}
    (h : authz.require_is_owner a n = ok (.Ok ())) : ownsFolder a n.val := by
  unfold authz.require_is_owner at h
  h5i_invert h
  exact (post_of_ok (is_owner_spec a n) (by assumption)).1 (by assumption)

@[step] theorem prefix_spec (s : Slice U8) (n : Usize) :
    bytes.prefix s n ⦃ r => r.val = s.val.take n.val ⦄ := by
  unfold bytes.prefix bytes.prefix_loop
  have h := loop_fold (l := s.val.take n.val) (abs := fun (o : alloc.vec.Vec U8) => o.val)
    (g := fun acc x => acc ++ [x]) (Inv := fun o i => o.length = i)
    (body := fun x => bytes.prefix_loop.body s n x.1 x.2) ?_ (alloc.vec.Vec.new _) 0#usize (by simp) (by simp)
  · apply WP.spec_mono (by simpa using h)
    intro r hr
    rw [hr]
    clear h hr
    generalize s.val = l
    generalize n.val = k
    induction l generalizing k with
    | nil => simp
    | cons x xs ih => cases k <;> simp [ih]
  · intro o i hi hinv
    unfold bytes.prefix_loop.body
    simp only []
    split
    · split
      · step*
        refine ⟨by simp; scalar_tac, ?_, by scalar_tac, by simp; scalar_tac⟩
        simp_all [List.getElem_take]
      · simp only [WP.spec_ok]
        exact ⟨by simp; scalar_tac, rfl⟩
    · simp only [WP.spec_ok]
      exact ⟨by simp; scalar_tac, rfl⟩

/-- `s.ends_with("/*")`. -/
def endsSS (s : Bytes) : Prop := ∃ q, s = q ++ [slashB, starB]

theorem endsSS_iff (l : Bytes) :
    endsSS l ↔ ∃ h : 2 ≤ l.length, l[l.length - 2] = slashB ∧ l[l.length - 1] = starB := by
  constructor
  · rintro ⟨q, rfl⟩
    refine ⟨by simp, ?_, ?_⟩
    · rw [List.getElem_append_right (by simp)]; simp
    · rw [List.getElem_append_right (by simp)]; simp
  · rintro ⟨h2, ha, hb⟩
    refine ⟨l.take (l.length - 2), ?_⟩
    have hd : l.drop (l.length - 2) = [slashB, starB] := by
      rw [List.drop_eq_getElem_cons (by omega), List.drop_eq_getElem_cons (by omega)]
      rw [List.drop_eq_nil_of_le (by omega)]
      simp only [ha, show l.length - 2 + 1 = l.length - 1 by omega, hb]
    conv_lhs => rw [← List.take_append_drop (l.length - 2) l]
    rw [hd]

@[step] theorem ends_with_slash_star_spec (s : Slice U8) :
    bytes.ends_with_slash_star s ⦃ b => (b = true ↔ endsSS s.val) ⦄ := by
  unfold bytes.ends_with_slash_star
  step*
  all_goals simp only [endsSS_iff]
  all_goals simp_all [slashB, starB]

theorem prefix_slash {q t : Bytes} (h1 : q <+: t) (h2 : q.length < t.length) (h3 : t[q.length]? = some slashB) :
    q ++ [slashB] <+: t := by
  obtain ⟨rest, rfl⟩ := h1
  cases rest with
  | nil => simp at h2
  | cons y ys =>
    simp only [List.getElem?_append_right (le_refl _), Nat.sub_self, List.getElem?_cons_zero,
      Option.some.injEq] at h3
    subst h3
    exact ⟨ys, by simp⟩

theorem names_wild {q x : Bytes} : names (q ++ [slashB, starB]) x ↔ x = q ++ [slashB, starB] ∨ inSubtree q x := by
  unfold names
  constructor
  · rintro (h | ⟨p, hp, hs⟩)
    · exact Or.inl h
    · have : q = p := by
        have := congrArg (fun l => l.take (l.length - 2)) hp
        simpa using this
      subst this; exact Or.inr hs
  · rintro (h | h)
    · exact Or.inl h
    · exact Or.inr ⟨q, rfl, h⟩

theorem names_exact {r x : Bytes} (hr : ¬ endsSS r) : names r x ↔ x = r := by
  unfold names
  constructor
  · rintro (h | ⟨p, hp, _⟩)
    · exact h
    · exact absurd ⟨p, hp⟩ hr
  · exact Or.inl

theorem inSubtree_of_prefix {q x : Bytes} (h : q ++ [slashB] <+: x) : inSubtree q x := Or.inr h

theorem covers_core {c r pre base : Bytes} (hc : endsSS c) (hpre : pre = c.take (c.length - 2))
    (hbase : (endsSS r ∧ base = r.take (r.length - 2)) ∨ (¬ endsSS r ∧ base = r))
    (h : base = pre ∨ (pre <+: base ∧ pre.length < base.length ∧ base[pre.length]? = some slashB)) :
    coversSem c r := by
  obtain ⟨q, rfl⟩ := hc
  have hq : pre = q := by rw [hpre]; simp
  subst hq
  intro x hx
  rw [names_wild]
  rcases hbase with ⟨⟨t, rfl⟩, hb⟩ | ⟨hnr, rfl⟩
  · have hb' : base = t := by rw [hb]; simp
    subst hb'
    rw [names_wild] at hx
    rcases h with rfl | ⟨h1, h2, h3⟩
    · exact hx
    · have hs := prefix_slash h1 h2 h3
      rcases hx with rfl | (rfl | hx)
      · exact Or.inr (Or.inr (hs.trans (List.prefix_append _ _)))
      · exact Or.inr (Or.inr hs)
      · exact Or.inr (Or.inr (hs.trans ((List.prefix_append _ _).trans hx)))
  · rw [names_exact hnr] at hx
    subst hx
    rcases h with rfl | ⟨h1, h2, h3⟩
    · exact Or.inr (Or.inl rfl)
    · exact Or.inr (Or.inr (prefix_slash h1 h2 h3))

/-- A UTF-8 character starts at every byte that is not a continuation byte. -/
def isLead (b : U8) : Bool := decide (b.val < 128) || decide (192 ≤ b.val)

/-- The first byte of every character, in order. -/
def leads (s : Bytes) : Bytes := s.filter isLead

theorem leads_take_succ (s : Bytes) (i : Nat) (h : i < s.length) :
    leads (s.take (i + 1)) = leads (s.take i) ++ (if isLead s[i] then [s[i]] else []) := by
  unfold leads
  rw [List.take_add_one, List.filter_append, List.getElem?_eq_getElem h]
  cases hl : isLead s[i] <;> simp [hl]

theorem leads_take_length (s : Bytes) : leads (s.take s.length) = leads s := by simp

theorem leads_at (s : Bytes) (i : Nat) (h : i < s.length) (hl : isLead s[i] = true) :
    (leads s)[(leads (s.take i)).length]? = some s[i] := by
  have hs : s = s.take i ++ s[i] :: s.drop (i + 1) := by
    conv_lhs => rw [← List.take_append_drop i s]
    rw [List.drop_eq_getElem_cons h]
  have : leads s = leads (s.take i) ++ s[i] :: leads (s.drop (i + 1)) := by
    conv_lhs => rw [hs]
    simp [leads, List.filter_append, List.filter_cons, hl]
  rw [this, List.getElem?_append_right (le_refl _)]
  simp

/-- `s.chars().nth(n) == Some('/')`, as the `n`-th character-start byte being `/`. -/
@[step] theorem nth_char_spec (s : Slice U8) (n : Usize) :
    bytes.nth_char_is_slash s n ⦃ b => b = decide ((leads s.val)[n.val]? = some 47#u8) ⦄ := by
  unfold bytes.nth_char_is_slash bytes.nth_char_is_slash_loop
  apply loop.spec_decr_nat (measure := fun (x : Usize × Usize) => s.length - x.2.val)
    (inv := fun x => x.2.val ≤ s.length ∧ x.1.val = (leads (s.val.take x.2.val)).length ∧ x.1.val ≤ n.val)
  · rintro ⟨cnt, i⟩ ⟨hi, hc, hn⟩
    unfold bytes.nth_char_is_slash_loop.body
    simp only []
    step*
    -- done at a character start with `count = n`
    all_goals first
      | (have hlead : isLead s.val[i.val] = true := by simp only [isLead]; simp_all; omega
         have e := leads_at s.val i.val (by scalar_tac) hlead
         have hn' : (leads (s.val.take i.val)).length = n.val := by simp_all
         rw [hn'] at e
         rw [e]; simp_all)
      | skip
    -- continue past a character start
    all_goals first
      | (have hlead : isLead s.val[i.val] = true := by simp only [isLead]; simp_all; omega
         refine ⟨by scalar_tac, ?_, ?_, by scalar_tac⟩
         · rw [show i2.val = i.val + 1 by scalar_tac, leads_take_succ _ _ (by scalar_tac)]
           simp only [hlead, if_true, List.length_append, List.length_singleton]
           scalar_tac
         · have : cnt.val ≠ n.val := fun e => ‹¬cnt = n› (UScalar.eq_of_val_eq e)
           scalar_tac)
      | skip
    -- continue past a continuation byte
    all_goals first
      | (have hnl : isLead s.val[i.val] = false := by simp only [isLead]; simp_all
         refine ⟨by scalar_tac, ?_, by scalar_tac, by scalar_tac⟩
         rw [show i2.val = i.val + 1 by scalar_tac, leads_take_succ _ _ (by scalar_tac)]
         simp only [hnl, Bool.false_eq_true, if_false, List.append_nil]
         exact hc)
      | skip
    -- end of the string
    all_goals
      have hi' : i.val = s.val.length := by scalar_tac
      rw [hi', leads_take_length] at hc
      rw [List.getElem?_eq_none (by scalar_tac)]
      simp
  · simp [leads]

end windmill_kernel.Lemmas
