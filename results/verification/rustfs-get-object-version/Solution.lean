import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit


deriving instance DecidableEq for acts.Family

namespace rustfs_kernel.Solution
set_option maxHeartbeats 0

theorem glob_star_last (n : List Nat) : globSpec [42] n = true := by
  induction n with
  | nil => simp [globSpec.eq_1, globSpec.eq_2]
  | cons x n ih => simp [globSpec.eq_3, ih]

theorem glob_lit_nil (c : Nat) (p : List Nat) (h1 : c ≠ 42) (h2 : c ≠ 63) :
    globSpec (c :: p) [] = false := by
  rw [globSpec.eq_def]; split <;> simp_all

theorem glob_lit_cons (c x : Nat) (p n : List Nat) (h1 : c ≠ 42) (h2 : c ≠ 63) :
    globSpec (c :: p) (x :: n) = (decide (c = x) && globSpec p n) := by
  rw [globSpec.eq_def]; split <;> simp_all

theorem nats_drop_cons (l : List U8) (i : Nat) (c : U8) (h : i < l.length) (hc : l[i] = c) :
    nats (l.drop i) = c.val :: nats (l.drop (i+1)) := by
  rw [List.drop_eq_getElem_cons h, hc]; rfl

theorem nats_drop_nil (l : List U8) (i : Nat) (h : l.length ≤ i) :
    nats (l.drop i) = [] := by
  rw [List.drop_eq_nil_of_le h]; rfl

theorem glob_star_drop (c : Nat) (hc : c = 42) (r : List Nat) (l : List U8) (i : Nat) (h : i < l.length) :
    globSpec (c :: r) (nats (l.drop i)) = (globSpec r (nats (l.drop i)) || globSpec (c :: r) (nats (l.drop (i+1)))) := by
  subst hc; conv => lhs; rw [nats_drop_cons l i _ h rfl, globSpec.eq_3]
  rw [← nats_drop_cons l i _ h rfl]

theorem deep_spec (p n : Slice U8) (pi ni : Usize) (hp : pi.val ≤ p.length) (hn : ni.val ≤ n.length) :
    wildmatch.deep_match p pi n ni false ⦃ b => b = globSpec (nats (p.val.drop pi.val)) (nats (n.val.drop ni.val)) ⦄ := by
  h5i_measure_induction (p.length - pi.val + (n.length - ni.val)) with ih
  have ih' : ∀ (pi' ni' : Usize), p.length - pi'.val + (n.length - ni'.val) < k → pi'.val ≤ p.length → ni'.val ≤ n.length →
      wildmatch.deep_match p pi' n ni' false ⦃ b => b = globSpec (nats (p.val.drop pi'.val)) (nats (n.val.drop ni'.val)) ⦄ :=
    fun pi' ni' h1 h2 h3 => ih _ h1 p n pi' ni' h2 h3 rfl
  clear ih
  rw [wildmatch.deep_match]
  step*
  · rw [nats_drop_nil _ _ (by scalar_tac), globSpec.eq_1]
    by_cases h : ni.val < n.length
    · rw [nats_drop_cons _ _ _ h rfl]; simp; scalar_tac
    · rw [nats_drop_nil _ _ (by scalar_tac)]; simp; scalar_tac
  · rw [nats_drop_cons _ _ _ (by scalar_tac) c_post.symm, nats_drop_nil (↑n) _ (by scalar_tac)]
    clear c_post; subst_vars; simp [globSpec.eq_4]
  · rw [nats_drop_cons _ _ _ (by scalar_tac) c_post.symm, nats_drop_cons (↑n) _ _ (by scalar_tac) rfl]
    clear c_post; subst_vars; simp [globSpec.eq_5, *]
  · have h1 : pi.val + 1 = p.length := by scalar_tac
    rw [nats_drop_cons _ _ _ (by scalar_tac) c_post.symm, nats_drop_nil (↑p) (pi.val+1) (by scalar_tac)]
    clear c_post; subst_vars; simp [glob_star_last]
  · rw [nats_drop_cons _ _ _ (by scalar_tac) c_post.symm]
    clear c_post; subst_vars
    by_cases h : ni.val < n.length
    · rw [nats_drop_cons (↑n) _ _ h rfl] at *; simp_all [globSpec.eq_3]
    · rw [nats_drop_nil (↑n) _ (by scalar_tac)] at *; simp_all [globSpec.eq_2]
  · rw [nats_drop_cons _ _ _ (by scalar_tac) c_post.symm] at b_post
    rw [nats_drop_cons _ _ _ (by scalar_tac) c_post.symm, glob_star_drop _ (by scalar_tac) _ _ _ (by scalar_tac)]
    clear c_post; subst_vars
    simp_all
  · rw [nats_drop_cons _ _ _ (by scalar_tac) c_post.symm, nats_drop_nil (↑n) _ (by scalar_tac)]
    rw [nats_drop_nil (↑n) _ (by scalar_tac)] at *
    clear c_post; subst_vars
    simp_all [globSpec.eq_2]
  · rw [nats_drop_cons _ _ _ (by scalar_tac) c_post.symm, nats_drop_nil (↑n) _ (by scalar_tac)]
    have : c.val ≠ 42 := by scalar_tac
    have : c.val ≠ 63 := by scalar_tac
    rw [glob_lit_nil _ _ (by assumption) (by assumption)]
  · rw [nats_drop_cons _ _ _ (by scalar_tac) c_post.symm, nats_drop_cons (↑n) _ _ (by scalar_tac) i2_post.symm]
    have : c.val ≠ 42 := by scalar_tac
    have : c.val ≠ 63 := by scalar_tac
    rw [glob_lit_cons _ _ _ _ (by assumption) (by assumption)]
    have hne' : c.val ≠ i2.val := by
      intro h; have : i2 = c := by scalar_tac
      simp_all
    simp [hne']
  · rw [nats_drop_cons _ _ _ (by scalar_tac) c_post.symm, nats_drop_cons (↑n) _ _ (by scalar_tac) i2_post.symm]
    have : c.val ≠ 42 := by scalar_tac
    have : c.val ≠ 63 := by scalar_tac
    rw [glob_lit_cons _ _ _ _ (by assumption) (by assumption)]
    have heq' : i2.val = c.val := by simp_all
    simp [heq', b_post, i3_post, i4_post]

theorem wildcard_is_glob (p n : Slice U8) :
    wildmatch.is_match p n = ok (globSpec (nats p.val) (nats n.val)) := by
  apply eq_ok_of_spec
  unfold wildmatch.is_match wildmatch.inner_match
  have hd := deep_spec p n 0#usize 0#usize (by simp) (by simp)
  simp at hd
  step*
  · have : p.val = [] := by rw [← List.length_eq_zero_iff]; scalar_tac
    rw [this, show nats [] = [] from rfl, globSpec.eq_1, nats]
    simp only [decide_eq_decide, ← List.length_eq_zero_iff]
    scalar_tac
  · obtain ⟨x, hx⟩ : ∃ x, p.val = [x] := List.length_eq_one_iff.mp (by scalar_tac)
    have : x.val = 42 := by subst_vars; simp_all
    rw [hx]; simp only [nats, List.map_cons, List.map_nil, this, glob_star_last]


@[step] theorem bytes_eq_spec (a b : Slice U8) :
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


@[step] theorem match_total (p n : Slice U8) : wildmatch.is_match p n ⦃ _ => True ⦄ := by
  rw [wildcard_is_glob]
  simp

@[step] theorem family_spec (a b : acts.Family) :
    acts.Family.Insts.CoreCmpPartialEqFamily.eq a b ⦃ r => r = decide (a = b) ⦄ := by
  cases a <;> cases b <;> simp [acts.Family.Insts.CoreCmpPartialEqFamily.eq, acts.Family.read_discriminant]

@[step] theorem is_s3_total (a : acts.Action) (nm : Slice U8) : acts.is_s3 a nm ⦃ _ => True ⦄ := by
  unfold acts.is_s3
  step*

@[step] theorem requires_total (a : acts.Action) : acts.action_requires_explicit_grant a ⦃ _ => True ⦄ := by
  unfold acts.action_requires_explicit_grant
  step*

@[step] theorem match_action_deny_total (a b : acts.Action) :
    acts.action_is_match_for_effect a b true ⦃ _ => True ⦄ := by
  unfold acts.action_is_match_for_effect
  step*

@[step] theorem match_set_deny_total (set : Slice acts.Action) (a : acts.Action) :
    acts.set_is_match_for_effect set a true ⦃ _ => True ⦄ := by
  unfold acts.set_is_match_for_effect acts.set_is_match_for_effect_loop
  apply loop_idx_spec _ id set.length (fun _ => True) _ ?_ _ (by simp) (by simp)
  intro i _ hi
  unfold acts.set_is_match_for_effect_loop.body
  step*
  all_goals simp only [id] at *
  all_goals scalar_tac

@[step] theorem match_action_total (a b : acts.Action) (deny : Bool) :
    acts.action_is_match_for_effect a b deny ⦃ _ => True ⦄ := by
  unfold acts.action_is_match_for_effect
  step*

theorem nats_inj {a b : List U8} (h : nats a = nats b) : a = b := by
  unfold nats at h
  exact List.map_injective_iff.2 (fun x y hxy => (u8_eq_iff x y).2 hxy) h

@[step] theorem is_s3_spec (a : acts.Action) (nm : Slice U8) :
    acts.is_s3 a nm ⦃ b => b = decide (a.family = .S3 ∧ a.name.val = nm.val) ⦄ := by
  unfold acts.is_s3
  step*
  all_goals simp_all [alloc.vec.Vec.deref]

theorem get_object_version_covers_get_object (s n : Slice acts.Action) (g o : acts.Action) (deny : Bool)
    (hs : s.val = [g]) (hn : n.val = [])
    (hg : g.family = .S3 ∧ nats g.name.val = lit "s3:GetObjectVersion")
    (hgo : o.family = .S3 ∧ nats o.name.val = lit "s3:GetObject") :
    acts.statement_covers s n o deny = ok true := by
  have lv : lit "s3:GetObjectVersion" =
      [115, 51, 58, 71, 101, 116, 79, 98, 106, 101, 99, 116, 86, 101, 114, 115, 105, 111, 110] := by
    decide +kernel
  have lo : lit "s3:GetObject" = [115, 51, 58, 71, 101, 116, 79, 98, 106, 101, 99, 116] := by
    decide +kernel
  have gv : g.name.val =
      [115#u8, 51#u8, 58#u8, 71#u8, 101#u8, 116#u8, 79#u8, 98#u8, 106#u8, 101#u8, 99#u8, 116#u8,
       86#u8, 101#u8, 114#u8, 115#u8, 105#u8, 111#u8, 110#u8] := by
    apply nats_inj
    simpa [nats, lv] using hg.2
  have ov : o.name.val =
      [115#u8, 51#u8, 58#u8, 71#u8, 101#u8, 116#u8, 79#u8, 98#u8, 106#u8, 101#u8, 99#u8, 116#u8] := by
    apply nats_inj
    simpa [nats, lo] using hgo.2
  have hb : acts.set_is_match_for_effect n o true = ok false := by
    unfold acts.set_is_match_for_effect acts.set_is_match_for_effect_loop
    rw [loop.eq_def]
    simp [acts.set_is_match_for_effect_loop.body, hn, Slice.len]
  unfold acts.statement_covers
  rw [hb]
  h5i_simp
  have hlen : Slice.len s ≠ 0#usize := by
    intro h
    have hv := congrArg UScalar.val h
    simp [Slice.len, hs] at hv
  rw [if_neg hlen]
  apply eq_ok_of_spec
  unfold acts.set_is_match_for_effect acts.set_is_match_for_effect_loop
  apply loop_idx_spec _ id s.length (fun i => i = 0#usize) (fun b => b = true) ?_ _ rfl (by simp)
  intro i hi hle
  subst i
  unfold acts.set_is_match_for_effect_loop.body
  have hidx : (0#usize).val < s.length := by simp [hs]
  step*
  all_goals simp_all [hs, hg.1, hgo.1, gv, ov, Array.make_val, alloc.vec.Vec.deref]

end rustfs_kernel.Solution
