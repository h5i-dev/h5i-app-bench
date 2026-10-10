import Verified.Derived
import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit


namespace rustfs_kernel.Verified.RustfsWildcard

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

end rustfs_kernel.Verified.RustfsWildcard
