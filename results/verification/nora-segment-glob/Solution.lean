import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP

set_option maxHeartbeats 0
namespace nora_kernel.Solution

lemma glob_nil (p : List Nat) : segGlobSpec p [] = p.all (· == 42) := by
  induction p with
  | nil => simp [segGlobSpec]
  | cons c p ih =>
    by_cases h : c = 42
    · subst c; simp [segGlobSpec, ih]
    · simp [segGlobSpec, h]

lemma glob_literal (c : Nat) (p v : List Nat) (h : c ≠ 42) :
    segGlobSpec (c :: p) v = match v with
      | [] => false
      | x :: w => decide (c = x) && segGlobSpec p w := by
  cases v <;> simp [segGlobSpec]

lemma glob_star (p : List Nat) (v : List Nat) :
    segGlobSpec (42 :: p) v = true ↔
      ∃ k, k ≤ v.length ∧ segGlobSpec p (v.drop k) = true := by
  induction v with
  | nil => simp [segGlobSpec]
  | cons x v ih =>
    rw [segGlobSpec]
    simp only [Bool.or_eq_true, ih]
    constructor
    · rintro (h | ⟨k, hk, h⟩)
      · exact ⟨0, by simp, h⟩
      · exact ⟨k+1, by simpa using hk, by simpa using h⟩
    · rintro ⟨k, hk, h⟩
      cases k with
      | zero => exact Or.inl h
      | succ k => exact Or.inr ⟨k, by simpa using hk, by simpa using h⟩

lemma glob_star_mono (p v : List Nat) (i j : Nat) (hij : i ≤ j) (hj : j ≤ v.length)
    (h : segGlobSpec (42 :: p) (v.drop j) = true) :
    segGlobSpec (42 :: p) (v.drop i) = true := by
  obtain ⟨k, hk, hg⟩ := (glob_star p _).1 h
  apply (glob_star p _).2
  refine ⟨j-i+k, ?_, ?_⟩
  · simp only [List.length_drop] at *; omega
  · simpa only [List.drop_drop, show i + (j-i+k) = j+k by omega] using hg

lemma glob_prefix (q p v : List Nat) (hq : 42 ∉ q)
    (h : segGlobSpec (q ++ p) v = true) :
    ∃ w, v = q ++ w ∧ segGlobSpec p w = true := by
  induction q generalizing v with
  | nil => exact ⟨v, rfl, h⟩
  | cons c q ih =>
    have hc : c ≠ 42 := by intro he; subst c; simp at hq
    cases v with
    | nil => simp [glob_literal c _ _ hc] at h
    | cons x v =>
      simp only [List.cons_append, glob_literal c _ _ hc, Bool.and_eq_true,
        decide_eq_true_eq] at h
      obtain ⟨rfl, h⟩ := h
      obtain ⟨w, rfl, hw⟩ := ih v (by simp only [List.mem_cons, not_or] at hq; exact hq.2) h
      exact ⟨w, rfl, hw⟩

lemma glob_no_star (p v : List Nat) (hp : 42 ∉ p) :
    segGlobSpec p v = decide (p = v) := by
  induction p generalizing v with
  | nil => simp [segGlobSpec, eq_comm]
  | cons c p ih =>
    have hc : c ≠ 42 := by intro he; subst c; simp at hp
    cases v <;> simp [glob_literal c _ _ hc, ih _ (by simp only [List.mem_cons, not_or] at hp; exact hp.2)]

lemma alternative_dominated (p v q r : List Nat) (s t i j : Nat)
    (hs : p.drop s = 42 :: (q ++ r)) (ht : j = t + q.length)
    (hq : 42 ∉ q) (hr : r = p.drop i)
    (end_or_star : j = v.length ∨ ∃ rest, r = 42 :: rest)
    (h : segGlobSpec (p.drop s) (v.drop (t+1)) = true) :
    segGlobSpec r (v.drop j) = true := by
  rw [hs] at h
  obtain ⟨k, hk, hg⟩ := (glob_star _ _).1 h
  rw [List.drop_drop] at hg
  obtain ⟨w, hw, hg⟩ := glob_prefix q r _ hq hg
  have hlen := congrArg List.length hw
  simp only [List.length_drop, List.length_append] at hlen
  simp only [List.length_drop] at hk
  by_cases hb : t+1+k ≤ v.length
  swap
  · have hw0 : w = [] := by simpa using (show w.length = 0 by omega)
    have hj : v.length ≤ j := by omega
    simpa [hw0, List.drop_eq_nil_of_le hj] using hg
  rcases end_or_star with hend | ⟨rest, rfl⟩
  · omega
  · have he : w = v.drop (t+1+k+q.length) := by
      have := congrArg (List.drop q.length) hw
      simpa using this.symm
    rw [he] at hg
    exact glob_star_mono rest v j _ (by omega) (by omega) hg

def pending (p v : List Nat) : Option (Nat × Nat) → Bool
  | none => false
  | some (s,t) => segGlobSpec (p.drop s) (v.drop (t+1))

/-- The current suffix plus the remaining retries have the original answer.
Between the saved star and the current index, `q` contains only literals;
its length records how far the current attempt has consumed the input. -/
structure ScanInv (p v : List Nat) (b : Bool) (i j : Nat) (bt : Option (Nat × Nat)) : Prop where
  ip : i ≤ p.length
  jv : j ≤ v.length
  hist : match bt with
    | none => True
    | some (s,t) => ∃ q : List Nat,
        s < p.length ∧ t ≤ j ∧ p.drop s = 42 :: (q ++ p.drop i) ∧
        i = s+1+q.length ∧ j = t+q.length ∧ 42 ∉ q
  ans : b = (segGlobSpec (p.drop i) (v.drop j) || pending p v bt)

lemma star_split (p v : List Nat) (s j : Nat) (hs : s < p.length)
    (hstar : p[s] = 42) (hj : j ≤ v.length) :
    segGlobSpec (p.drop s) (v.drop j) =
      (segGlobSpec (p.drop (s+1)) (v.drop j) ||
        segGlobSpec (p.drop s) (v.drop (j+1))) := by
  rw [List.drop_eq_getElem_cons hs, hstar]
  by_cases h : j < v.length
  · rw [List.drop_eq_getElem_cons h, segGlobSpec]
  · have he : j = v.length := by omega
    simp [he, glob_nil]

lemma inv_dominated {p v : List Nat} {b : Bool} {i j : Nat} {bt : Option (Nat × Nat)}
    (h : ScanInv p v b i j bt)
    (hc : j = v.length ∨ ∃ r, p.drop i = 42 :: r) :
    b = segGlobSpec (p.drop i) (v.drop j) := by
  rw [h.ans]
  apply Bool.eq_iff_iff.mpr
  simp only [Bool.or_eq_true]
  constructor
  · rintro (hg | ha)
    · exact hg
    · cases bt with
      | none => simp [pending] at ha
      | some st =>
        obtain ⟨s,t⟩ := st
        obtain ⟨q, _, _, hs, _, ht, hq⟩ := h.hist
        exact alternative_dominated p v q (p.drop i) s t i j hs ht hq rfl hc ha
  · exact Or.inl

lemma inv_star {p v : List Nat} {b : Bool} {i j : Nat} {bt : Option (Nat × Nat)}
    (h : ScanInv p v b i j bt) (hi : i < p.length) (hc : p[i] = 42) :
    ScanInv p v b (i+1) j (some (i,j)) := by
  have hd : p.drop i = 42 :: p.drop (i+1) := by
    rw [List.drop_eq_getElem_cons hi, hc]
  refine ⟨by omega, h.jv, ⟨[], hi, le_refl _, by simpa using hd, by simp, by simp, by simp⟩, ?_⟩
  rw [inv_dominated h (Or.inr ⟨_, hd⟩)]
  exact star_split p v i j hi hc h.jv

lemma inv_literal {p v : List Nat} {b : Bool} {i j : Nat} {bt : Option (Nat × Nat)}
    (h : ScanInv p v b i j bt) (hi : i < p.length) (hj : j < v.length)
    (hc : p[i] ≠ 42) (he : p[i] = v[j]) :
    ScanInv p v b (i+1) (j+1) bt := by
  have hp := List.drop_eq_getElem_cons hi
  have hv := List.drop_eq_getElem_cons hj
  refine ⟨by omega, by omega, ?_, ?_⟩
  · cases bt with
    | none => trivial
    | some st =>
      obtain ⟨s,t⟩ := st
      obtain ⟨q, hs, ht, hd, hiq, hjq, hq⟩ := h.hist
      refine ⟨q ++ [p[i]], hs, by omega, ?_, ?_, ?_, ?_⟩
      · simpa only [List.append_assoc, List.singleton_append] using (hd.trans (by rw [hp]))
      · simp only [List.length_append, List.length_singleton]; omega
      · simp only [List.length_append, List.length_singleton]; omega
      · simp [hq, hc]
  · rw [h.ans, hp, hv, glob_literal _ _ _ hc, he]
    simp

lemma inv_mismatch {p v : List Nat} {b : Bool} {i j : Nat} {bt : Option (Nat × Nat)}
    (_h : ScanInv p v b i j bt) (hj : j < v.length)
    (hm : i = p.length ∨ ∃ hi : i < p.length, p[i] ≠ 42 ∧ p[i] ≠ v[j]) :
    segGlobSpec (p.drop i) (v.drop j) = false := by
  rw [List.drop_eq_getElem_cons hj]
  rcases hm with hi | ⟨hi, hc, he⟩
  · simp [hi, segGlobSpec, hj]
  · rw [List.drop_eq_getElem_cons hi, glob_literal _ _ _ hc]
    simp [he]

lemma inv_retry {p v : List Nat} {b : Bool} {i j s t : Nat}
    (h : ScanInv p v b i j (some (s,t))) (hj : j < v.length)
    (hf : segGlobSpec (p.drop i) (v.drop j) = false) :
    ScanInv p v b (s+1) (t+1) (some (s,t+1)) := by
  obtain ⟨q, hs, ht, hd, hiq, hjq, hq⟩ := h.hist
  have hstar : p[s] = 42 := by
    rw [List.drop_eq_getElem_cons hs] at hd
    exact (List.cons.inj hd).1
  have hd' : p.drop s = 42 :: p.drop (s+1) := by
    rw [List.drop_eq_getElem_cons hs, hstar]
  refine ⟨by omega, by omega, ⟨[], hs, le_refl _, by simpa using hd', by simp, by simp, by simp⟩, ?_⟩
  rw [h.ans, hf]
  simp only [Bool.false_or, pending]
  exact star_split p v s (t+1) hs hstar (by omega)

def pivot : Option (Nat × Nat) → Nat
  | none => 0
  | some (_,t) => t

/-- A retry increases the saved input index; other steps advance the pattern.
The multiplier makes a retry decrease the measure even when it resets `i`. -/
def scanMeasure (p v : List Nat) (i : Nat) (bt : Option (Nat × Nat)) : Nat :=
  (v.length - pivot bt) * (p.length+1) + (p.length-i)

lemma measure_decr {p v : List Nat} {i i' : Nat} {bt bt' : Option (Nat × Nat)}
    (hi : i ≤ p.length) (hi' : i' ≤ p.length)
    (ht : pivot bt ≤ v.length) (ht' : pivot bt' ≤ v.length)
    (h : pivot bt < pivot bt' ∨ pivot bt = pivot bt' ∧ i < i') :
    scanMeasure p v i' bt' < scanMeasure p v i bt := by
  unfold scanMeasure
  rcases h with hh | ⟨hh, hhi⟩
  · have htdec : v.length - pivot bt' + 1 ≤ v.length - pivot bt := by omega
    have hm := Nat.mul_le_mul_right (p.length+1) htdec
    rw [Nat.add_mul, Nat.one_mul] at hm
    omega
  · rw [hh]
    omega

@[step] lemma contains_star_spec (p : Slice U8) :
    contains_star p ⦃ b => b = decide (42 ∈ nats p.val) ⦄ := by
  unfold contains_star contains_star_loop
  apply WP.spec_mono (loop_search p.val (fun x => decide (x = 42#u8)) id
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro b hb
    have hb' := search_any _ _ _ hb
    dsimp only [id] at hb'
    rw [hb']
    apply Bool.eq_iff_iff.mpr
    simp [nats, List.mem_map, u8_eq_iff]
  · intro i hi
    unfold contains_star_loop.body
    h5i_step

@[step] lemma all_stars_spec (p : Slice U8) (i : Usize) (hi : i.val ≤ p.val.length) :
    all_stars_from p i ⦃ b => b = segGlobSpec ((nats p.val).drop i.val) [] ⦄ := by
  unfold all_stars_from all_stars_from_loop
  apply WP.spec_mono (loop_search p.val (fun x => x != 42#u8) id
    (fun _ _ => false) true _ ?_ i hi)
  · intro b hb
    simp only [id] at hb
    rw [hb, searchFrom_const, glob_nil]
    apply Bool.eq_iff_iff.mpr
    simp [nats, ← List.map_drop, List.all_eq_not_any_not, List.any_map, Function.comp_def,
      u8_eq_iff]
  · intro j hj
    unfold all_stars_from_loop.body
    h5i_step

@[step] lemma bytes_eq_spec (p v : Slice U8) :
    bytes_eq p v ⦃ b => b = decide (nats p.val = nats v.val) ⦄ := by
  unfold bytes_eq
  dsimp only
  split
  · rename_i h
    simp only [WP.spec_ok]
    have hn : p.val.length ≠ v.val.length := by scalar_tac
    have hne : nats p.val ≠ nats v.val := by
      intro he
      have := congrArg List.length he
      simp [nats] at this
      contradiction
    simp [hne]
  · rename_i h
    have hlen : p.val.length = v.val.length := by scalar_tac
    unfold bytes_eq_loop
    apply loop.spec_decr_nat (measure := fun i : Usize => p.val.length - i.val)
      (inv := fun i => i.val ≤ p.val.length ∧
        decide (nats p.val = nats v.val) =
          decide (nats (p.val.drop i.val) = nats (v.val.drop i.val)))
    · intro i hi
      obtain ⟨hi, he⟩ := hi
      unfold bytes_eq_loop.body
      dsimp only
      split
      · rename_i hit
        have hit' : i.val < p.val.length := by scalar_tac
        step
        step
        split
        · rename_i hne
          simp only [WP.spec_ok]
          rw [List.drop_eq_getElem_cons hit',
            List.drop_eq_getElem_cons (show i.val < v.val.length by omega)] at he
          simp only [nats, List.map_cons, List.cons.injEq, decide_eq_decide] at he
          simp only [bne_iff_ne] at hne
          have hne' : (p.val[i.val]).val ≠ (v.val[i.val]).val := by
            intro hh
            apply hne
            simpa [i2_post, i3_post, u8_eq_iff] using hh
          have hh : nats p.val ≠ nats v.val := fun hh => hne' ((he.mp hh).1)
          simp [hh]
        · rename_i heq
          step
          have hi4 : i4.val = i.val + 1 := i4_post
          have heq' : (p.val[i.val]).val = (v.val[i.val]).val := by
            simpa [i2_post, i3_post, u8_eq_iff] using heq
          refine ⟨by omega, ?_, by omega⟩
          rw [hi4]
          rw [List.drop_eq_getElem_cons hit',
            List.drop_eq_getElem_cons (show i.val < v.val.length by omega)] at he
          apply decide_eq_decide.mpr
          have he := decide_eq_decide.mp he
          simpa only [nats, List.map_cons, List.cons.injEq, heq', true_and] using he
      · simp only [WP.spec_ok]
        have hie : i.val = p.val.length := by scalar_tac
        simpa [hie, hlen, nats] using he.symm
    · simp [nats]

lemma inv_pivot {p v : List Nat} {b : Bool} {i j : Nat} {bt : Option (Nat × Nat)}
    (h : ScanInv p v b i j bt) : pivot bt ≤ j := by
  cases bt with
  | none => simp [pivot]
  | some st =>
    obtain ⟨s,t⟩ := st
    obtain ⟨q, _, ht, _⟩ := h.hist
    exact ht

lemma continue_star {p v : List Nat} {b : Bool} {i j : Nat} {bt : Option (Nat × Nat)}
    (h : ScanInv p v b i j bt) (hi : i < p.length) (hc : p[i] = 42) :
    ScanInv p v b (i+1) j (some (i,j)) ∧
      scanMeasure p v (i+1) (some (i,j)) < scanMeasure p v i bt := by
  have hn := inv_star h hi hc
  refine ⟨hn, measure_decr h.ip hn.ip (le_trans (inv_pivot h) h.jv)
    (le_trans (inv_pivot hn) hn.jv) ?_⟩
  have ht := inv_pivot h
  change pivot bt < j ∨ pivot bt = j ∧ i < i+1
  omega

lemma continue_literal {p v : List Nat} {b : Bool} {i j : Nat} {bt : Option (Nat × Nat)}
    (h : ScanInv p v b i j bt) (hi : i < p.length) (hj : j < v.length)
    (hc : p[i] ≠ 42) (he : p[i] = v[j]) :
    ScanInv p v b (i+1) (j+1) bt ∧
      scanMeasure p v (i+1) bt < scanMeasure p v i bt := by
  have hn := inv_literal h hi hj hc he
  refine ⟨hn, measure_decr h.ip hn.ip (le_trans (inv_pivot h) h.jv)
    (le_trans (inv_pivot hn) hn.jv) (Or.inr ⟨rfl, by omega⟩)⟩

lemma continue_retry {p v : List Nat} {b : Bool} {i j s t : Nat}
    (h : ScanInv p v b i j (some (s,t))) (hj : j < v.length)
    (hf : segGlobSpec (p.drop i) (v.drop j) = false) :
    ScanInv p v b (s+1) (t+1) (some (s,t+1)) ∧
      scanMeasure p v (s+1) (some (s,t+1)) < scanMeasure p v i (some (s,t)) := by
  have hn := inv_retry h hj hf
  exact ⟨hn, measure_decr h.ip hn.ip (le_trans (inv_pivot h) h.jv)
    (le_trans (inv_pivot hn) hn.jv) (Or.inl (by simp [pivot]))⟩

def btNats (bt : Option (Usize × Usize)) : Option (Nat × Nat) :=
  bt.map (fun st => (st.1.val, st.2.val))

def ScanPost (p : List Nat) (b : Bool) : Option Usize → Prop
  | none => b = false
  | some i => i.val ≤ p.length ∧ b = segGlobSpec (p.drop i.val) []

lemma retry_step_spec (p v : Slice U8) (pi vi : Usize) (bt : Option (Usize × Usize)) (b : Bool)
    (hI : ScanInv (nats p.val) (nats v.val) b pi.val vi.val (btNats bt))
    (hj : vi.val < (nats v.val).length)
    (hf : segGlobSpec ((nats p.val).drop pi.val) ((nats v.val).drop vi.val) = false) :
    (match bt with
      | none => ok (ControlFlow.done none)
      | some st => do
        let vi' ← st.2 + 1#usize
        let pi' ← st.1 + 1#usize
        ok (ControlFlow.cont (pi', vi', some (st.1,vi')))) ⦃ r => match r with
      | .done o => ScanPost (nats p.val) b o
      | .cont st => ScanInv (nats p.val) (nats v.val) b st.1.val st.2.1.val (btNats st.2.2) ∧
          scanMeasure (nats p.val) (nats v.val) st.1.val (btNats st.2.2) <
            scanMeasure (nats p.val) (nats v.val) pi.val (btNats bt) ⦄ := by
  cases bt with
  | none =>
    simp only [WP.spec_ok, ScanPost]
    simpa [btNats, pending, hf] using hI.ans
  | some st =>
    obtain ⟨s,t⟩ := st
    have hI' : ScanInv (nats p.val) (nats v.val) b pi.val vi.val (some (s.val,t.val)) := hI
    obtain ⟨q, hs, ht, hd, hiq, hjq, hq⟩ := hI'.hist
    have hs' : s.val < p.val.length := by simpa [nats] using hs
    have hj' : vi.val < v.val.length := by simpa [nats] using hj
    step as ⟨vi', hv⟩
    step as ⟨pi', hp⟩
    simpa [btNats, hv, hp] using continue_retry hI' hj hf

@[step] lemma glob_scan_spec (p v : Slice U8) :
    glob_scan p v ⦃ ScanPost (nats p.val) (segGlobSpec (nats p.val) (nats v.val)) ⦄ := by
  unfold glob_scan glob_scan_loop
  apply loop.spec_decr_nat
    (measure := fun st => scanMeasure (nats p.val) (nats v.val) st.1.val (btNats st.2.2))
    (inv := fun st => ScanInv (nats p.val) (nats v.val)
      (segGlobSpec (nats p.val) (nats v.val)) st.1.val st.2.1.val (btNats st.2.2))
  · rintro ⟨pi, vi, bt⟩ hI
    dsimp only at hI ⊢
    unfold glob_scan_loop.body
    dsimp only
    split
    · rename_i hvi
      have hj : vi.val < (nats v.val).length := by simpa [nats] using hvi
      split
      · rename_i hpi
        have hi : pi.val < (nats p.val).length := by simpa [nats] using hpi
        step
        subst i2
        split
        · rename_i hc
          step
          have hc' : (nats p.val)[pi.val] = 42 := by simpa [nats, u8_eq_iff] using hc
          simpa [btNats, pi1_post] using continue_star hI hi hc'
        · rename_i hc
          step
          subst i4
          split
          · rename_i he
            step
            step
            have hc' : (nats p.val)[pi.val] ≠ 42 := by simpa [nats, u8_eq_iff] using hc
            have he' : (nats p.val)[pi.val] = (nats v.val)[vi.val] := by
              simpa [nats, u8_eq_iff] using he
            simpa [pi1_post, vi1_post] using continue_literal hI hi hj hc' he'
          · rename_i he
            have hc' : (nats p.val)[pi.val] ≠ 42 := by simpa [nats, u8_eq_iff] using hc
            have he' : (nats p.val)[pi.val] ≠ (nats v.val)[vi.val] := by
              simpa [nats, u8_eq_iff] using he
            have hf := inv_mismatch hI hj (Or.inr ⟨hi, hc', he'⟩)
            cases bt with
            | none =>
              apply WP.spec_mono (retry_step_spec p v pi vi none _ hI hj hf)
              intro r hr
              cases r <;> exact hr
            | some st =>
              obtain ⟨s,t⟩ := st
              apply WP.spec_mono (retry_step_spec p v pi vi (some (s,t)) _ hI hj hf)
              intro r hr
              cases r <;> exact hr
      · rename_i hpi
        have hi : pi.val = (nats p.val).length := by
          have hp' : pi.val ≤ p.val.length := by simpa [nats] using hI.ip
          simpa [nats] using (show pi.val = p.val.length by scalar_tac)
        have hf := inv_mismatch hI hj (Or.inl hi)
        cases bt with
        | none =>
          apply WP.spec_mono (retry_step_spec p v pi vi none _ hI hj hf)
          intro r hr
          cases r <;> exact hr
        | some st =>
          obtain ⟨s,t⟩ := st
          apply WP.spec_mono (retry_step_spec p v pi vi (some (s,t)) _ hI hj hf)
          intro r hr
          cases r <;> exact hr
    · rename_i hvi
      simp only [WP.spec_ok, ScanPost]
      have hj : vi.val = (nats v.val).length := by
        have hv' : vi.val ≤ v.val.length := by simpa [nats] using hI.jv
        simpa [nats] using (show vi.val = v.val.length by scalar_tac)
      refine ⟨hI.ip, ?_⟩
      simpa [hj] using inv_dominated hI (Or.inl hj)
  · exact ⟨by simp [nats], by simp [nats], trivial, by simp [btNats, pending]⟩

theorem segment_glob_spec (pattern v : Slice U8) :
    segment_glob pattern v = ok (segGlobSpec (nats pattern.val) (nats v.val)) := by
  apply eq_ok_of_spec
  unfold segment_glob
  step
  split
  · rename_i hc
    step
    cases o with
    | none =>
      simp only [WP.spec_ok]
      exact (show segGlobSpec (nats pattern.val) (nats v.val) = false from o_post).symm
    | some i =>
      obtain ⟨hi, he⟩ := o_post
      step with all_stars_spec pattern i (by simpa [nats] using hi) as ⟨x, hx⟩
      exact hx.trans he.symm
  · rename_i hc
    step
    have hp : 42 ∉ nats pattern.val := by simp_all
    rw [glob_no_star _ _ hp]
    exact x_post

end nora_kernel.Solution
