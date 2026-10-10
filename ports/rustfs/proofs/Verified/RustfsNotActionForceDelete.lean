import Verified.Derived
import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit



namespace rustfs_kernel.Verified.RustfsNotActionForceDelete
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

theorem eq_loop_ok (a b : Slice U8) (hl : a.val.length = b.val.length) (i : Usize) (r : Bool)
    (hi : ∀ j < i.val, a.val[j]? = b.val[j]?) (h : bytes.eq_loop a b i = ok r) :
    (r = true ↔ a.val = b.val) := by
  unfold bytes.eq_loop at h
  refine loop_ok _ (fun i : Usize => ∀ j < i.val, a.val[j]? = b.val[j]?) (fun r => r = true ↔ a.val = b.val)
    (fun i : Usize => a.val.length - i.val) ?_ i r hi h
  intro x r hx hr
  unfold bytes.eq_loop.body at hr
  h5i_invert hr
  · obtain ⟨h1, h2⟩ := slice_index_ok hi2
    obtain ⟨h3, h4⟩ := slice_index_ok hi3
    simp only [Bool.false_eq_true, false_iff]
    intro he
    simp only [he] at h2
    simp_all
  · obtain ⟨h1, h2⟩ := slice_index_ok hi2
    obtain ⟨h3, h4⟩ := slice_index_ok hi3
    have := add_ok_val hi4
    simp only
    refine ⟨fun j hj => ?_, by scalar_tac⟩
    by_cases hjx : j < x.val
    · exact hx j hjx
    · have : j = x.val := by scalar_tac
      subst this
      have : i2 = i3 := (u8_eq_iff _ _).2 (by simpa using hc_1)
      simp_all
  · simp only [true_iff]
    apply List.ext_getElem?
    intro j
    by_cases hjx : j < x.val
    · exact hx j hjx
    · have : a.val.length ≤ j := by scalar_tac
      rw [List.getElem?_eq_none this, List.getElem?_eq_none (by omega)]

theorem bytes_eq_ok (a b : Slice U8) (r : Bool) (h : bytes.eq a b = ok r) :
    (r = true ↔ a.val = b.val) := by
  unfold bytes.eq at h
  h5i_invert h
  · simp only [Bool.false_eq_true, false_iff]
    intro he; simp_all
  · exact eq_loop_ok a b (by simp_all) _ r (by simp) h

theorem family_eq_ok (f g : acts.Family) :
    acts.Family.Insts.CoreCmpPartialEqFamily.eq f g = ok (decide (f = g)) := by
  unfold acts.Family.Insts.CoreCmpPartialEqFamily.eq
  cases f <;> cases g <;> simp [acts.Family.read_discriminant]

theorem nats_inj {a b : List U8} (h : nats a = nats b) : a = b := by
  unfold nats at h
  exact List.map_injective_iff.2 (fun x y hxy => (u8_eq_iff x y).2 hxy) h

theorem deref_val {T} (v : alloc.vec.Vec T) : (alloc.vec.Vec.deref v).val = v.val := by
  simp [alloc.vec.Vec.deref]

theorem lift_slice {n : Usize} {l : List U8} {hl} {s : Slice U8}
    (h : lift (Array.make n l hl).to_slice = ok s) : nats s.val = l.map (·.val) := by
  simp only [lift, Result.ok.injEq] at h
  subst h
  simp [Array.make_val, nats]

theorem lit_FDB : lit "s3:ForceDeleteBucket" =
    [115, 51, 58, 70, 111, 114, 99, 101, 68, 101, 108, 101, 116, 101, 66, 117, 99, 107, 101, 116] := by
  decide +kernel
theorem lit_FDO : lit "s3:ForceDeleteObject" =
    [115, 51, 58, 70, 111, 114, 99, 101, 68, 101, 108, 101, 116, 101, 79, 98, 106, 101, 99, 116] := by
  decide +kernel
theorem lit_star : lit "*" = [42] := by decide +kernel
theorem lit_s3 : lit "s3:" = [115, 51, 58] := by decide +kernel
theorem lit_admin : lit "admin:" = [97, 100, 109, 105, 110, 58] := by decide +kernel
theorem lit_sts : lit "sts:" = [115, 116, 115, 58] := by decide +kernel
theorem lit_kms : lit "kms:" = [107, 109, 115, 58] := by decide +kernel

theorem is_s3_ok (x : acts.Action) (s : Slice U8) (r : Bool) (h : acts.is_s3 x s = ok r) :
    (r = true ↔ x.family = .S3 ∧ nats x.name.val = nats s.val) := by
  unfold acts.is_s3 at h
  rw [family_eq_ok] at h
  h5i_invert h
  · have := bytes_eq_ok _ _ _ h
    rw [deref_val] at this
    have hc' : x.family = .S3 := of_decide_eq_true hc
    simp only [hc', true_and, this]
    exact ⟨fun h => by rw [h], nats_inj⟩
  · simp_all

theorem requires_ok (a : acts.Action) (r : Bool) (h : acts.action_requires_explicit_grant a = ok r) :
    (r = true ↔ IsForceDelete a) := by
  unfold acts.action_requires_explicit_grant at h
  h5i_invert h
  · have h1 := is_s3_ok _ _ _ hb
    have h2 := lift_slice hs
    simp only [hc, true_iff] at h1 ⊢
    refine ⟨h1.1, Or.inl ?_⟩
    rw [h1.2, h2, lit_FDB]; rfl
  · have h1 := is_s3_ok _ _ _ hb
    have h2 := lift_slice hs
    have h3 := is_s3_ok _ _ _ h
    have h4 := lift_slice hs1
    rw [h3, h4]
    rw [h2] at h1
    unfold IsForceDelete
    rw [lit_FDB, lit_FDO]
    simp_all

theorem not_action_never_grants_force_delete (none not : Slice acts.Action) (x : acts.Action)
    (hn : none.val = []) (hf : IsForceDelete x) :
    acts.statement_covers none not x false = ok false := by
  obtain ⟨b, hb⟩ := ok_of (match_set_deny_total not x)
  have hr : acts.action_requires_explicit_grant x = ok true := by
    obtain ⟨r, hr⟩ := ok_of (requires_total x)
    have ht := (requires_ok x r hr).2 hf
    simpa [ht] using hr
  unfold acts.statement_covers
  rw [hb]
  cases b <;> simp [hn, Slice.len, hr]

end rustfs_kernel.Verified.RustfsNotActionForceDelete
