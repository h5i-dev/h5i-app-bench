import Verified.RustfsActionSets
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsCondData (all_loop)
open rustfs_kernel.Verified.RustfsValids (any_loop)
open rustfs_kernel.Verified.RustfsForceDelete (effect_eq_ok)
namespace rustfs_kernel.Verified.RustfsManagementDecisions

theorem denies_ok (p : manage.Policy) (a : stmts.Args) (e : condfuncs.Env) (b : Bool)
    (h : manage.denies_clear p a e = ok b) :
    (b = true ↔ ∀ st ∈ p.statements.val, st.effect = .Deny → manage.statement_is_allowed st a e = ok true) := by
  unfold manage.denies_clear manage.denies_clear_loop at h
  refine all_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold manage.denies_clear_loop.body at hr
  simp only [effect_eq_ok,bind_ok] at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := vec_index_ok hst
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]
    intro _
    simpa [hc_2] using hb1
  · obtain ⟨hlt,he⟩ := vec_index_ok hst
    refine .inl ⟨hlt, ?_, rfl⟩
    rw [he]
    intro hh
    have hh1 := hh (by simpa using hc_1)
    rw [hh1] at hb1
    simp only [Result.ok.injEq] at hb1
    exact hc_2 hb1.symm
  · obtain ⟨hlt,he⟩ := vec_index_ok hst
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]
    intro hh
    exact False.elim (hc_1 (by simpa using hh))
  · exact .inr ⟨by scalar_tac,rfl⟩

theorem allows_ok (p : manage.Policy) (a : stmts.Args) (e : condfuncs.Env) (b : Bool)
    (h : manage.allows_match p a e = ok b) :
    (b = true ↔ ∃ st ∈ p.statements.val, st.effect = .Allow ∧ manage.statement_is_allowed st a e = ok true) := by
  unfold manage.allows_match manage.allows_match_loop at h
  refine any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold manage.allows_match_loop.body at hr
  simp only [effect_eq_ok,bind_ok] at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := vec_index_ok hst
    refine .inl ⟨hlt, ?_, rfl⟩
    rw [he]
    exact ⟨by simpa using hc_1, by simpa [hc_2] using hb1⟩
  · obtain ⟨hlt,he⟩ := vec_index_ok hst
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]
    rintro ⟨_,hh⟩
    rw [hh] at hb1
    simp only [Result.ok.injEq] at hb1
    exact hc_2 hb1.symm
  · obtain ⟨hlt,he⟩ := vec_index_ok hst
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]
    rintro ⟨hh,_⟩
    exact hc_1 (by simpa using hh)
  · exact .inr ⟨by scalar_tac,rfl⟩

theorem bucket_denies_ok (p : manage.BucketPolicy) (a : stmts.BucketPolicyArgs) (e : condfuncs.Env) (b : Bool)
    (h : manage.bucket_denies_clear p a e = ok b) :
    (b = true ↔ ∀ st ∈ p.statements.val, st.effect = .Deny → manage.bp_statement_is_allowed st a e = ok true) := by
  unfold manage.bucket_denies_clear manage.bucket_denies_clear_loop at h
  refine all_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold manage.bucket_denies_clear_loop.body at hr
  simp only [effect_eq_ok,bind_ok] at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := vec_index_ok hst
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]
    intro _
    simpa [hc_2] using hb1
  · obtain ⟨hlt,he⟩ := vec_index_ok hst
    refine .inl ⟨hlt, ?_, rfl⟩
    rw [he]
    intro hh
    have hh1 := hh (by simpa using hc_1)
    rw [hh1] at hb1
    simp only [Result.ok.injEq] at hb1
    exact hc_2 hb1.symm
  · obtain ⟨hlt,he⟩ := vec_index_ok hst
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]
    intro hh
    exact False.elim (hc_1 (by simpa using hh))
  · exact .inr ⟨by scalar_tac,rfl⟩

theorem bucket_allows_ok (p : manage.BucketPolicy) (a : stmts.BucketPolicyArgs) (e : condfuncs.Env) (b : Bool)
    (h : manage.bucket_allows_match p a e = ok b) :
    (b = true ↔ ∃ st ∈ p.statements.val, st.effect = .Allow ∧ manage.bp_statement_is_allowed st a e = ok true) := by
  unfold manage.bucket_allows_match manage.bucket_allows_match_loop at h
  refine any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold manage.bucket_allows_match_loop.body at hr
  simp only [effect_eq_ok,bind_ok] at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := vec_index_ok hst
    refine .inl ⟨hlt, ?_, rfl⟩
    rw [he]
    exact ⟨by simpa using hc_1, by simpa [hc_2] using hb1⟩
  · obtain ⟨hlt,he⟩ := vec_index_ok hst
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]
    rintro ⟨_,hh⟩
    rw [hh] at hb1
    simp only [Result.ok.injEq] at hb1
    exact hc_2 hb1.symm
  · obtain ⟨hlt,he⟩ := vec_index_ok hst
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]
    rintro ⟨hh,_⟩
    exact hc_1 (by simpa using hh)
  · exact .inr ⟨by scalar_tac,rfl⟩

theorem decision_ok (p : manage.Policy) (a : stmts.Args) (e : condfuncs.Env) (b : Bool)
    (h : manage.policy_is_allowed p a e = ok b) :
    (b = true ↔
      (∀ st ∈ p.statements.val, st.effect = .Deny → manage.statement_is_allowed st a e = ok true) ∧
      (a.deny_only = true ∨ a.is_owner = true ∨
        ∃ st ∈ p.statements.val, st.effect = .Allow ∧ manage.statement_is_allowed st a e = ok true)) := by
  unfold manage.policy_is_allowed at h
  h5i_invert h
  all_goals have hd := denies_ok p a e _ (by assumption)
  all_goals first
    | (have ha := allows_ok p a e b h; simp_all)
    | simp_all

theorem bucket_decision_ok (p : manage.BucketPolicy) (a : stmts.BucketPolicyArgs)
    (e : condfuncs.Env) (b : Bool) (h : manage.bucket_policy_is_allowed p a e = ok b) :
    (b = true ↔
      (∀ st ∈ p.statements.val, st.effect = .Deny → manage.bp_statement_is_allowed st a e = ok true) ∧
      (a.is_owner = true ∨
        ∃ st ∈ p.statements.val, st.effect = .Allow ∧ manage.bp_statement_is_allowed st a e = ok true)) := by
  unfold manage.bucket_policy_is_allowed at h
  h5i_invert h
  all_goals have hd := bucket_denies_ok p a e _ (by assumption)
  all_goals first
    | (have ha := bucket_allows_ok p a e b h; simp_all)
    | simp_all
end rustfs_kernel.Verified.RustfsManagementDecisions
