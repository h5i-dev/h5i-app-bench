import Lemmas
open Aeneas Aeneas.Std Result Aeneas.Std.WP synctv_kernel synctv_kernel.Spec synctv_kernel.Lemmas H5iAppLib

theorem leeway_spec (l : U64) : auth.leeway_to_i64 l ⦃ x => x.val = min (l.val : Int) (2 ^ 63 - 1) ⦄ := by
  unfold auth.leeway_to_i64
  split
  · simp only [WP.spec_ok, UScalar.hcast_val_eq]
    rename_i h
    have : l.val ≤ 9223372036854775807 := by scalar_tac
    rw [Int.bmod_eq_of_le] <;> simp <;> omega
  · rename_i h
    have : ¬ l.val ≤ 9223372036854775807 := by scalar_tac
    simp; omega

theorem sat_spec (e l : I64) (hl : 0 ≤ l.val) :
    auth.saturating_add_nonneg e l ⦃ x => x.val = min (e.val + l.val) (2 ^ 63 - 1) ⦄ := by
  unfold auth.saturating_add_nonneg
  step*

theorem expiration_spec (now exp : I64) (l : U64) :
    auth.validate_expiration now exp l ⦃ r => (r = .Ok () ↔ notExpired now.val exp.val l.val) ∧
      (r = .Ok () ∨ r = .Err .Authentication) ⦄ := by
  unfold auth.validate_expiration
  obtain ⟨x, hx, hxv⟩ := WP.spec_imp_exists (leeway_spec l)
  have hx0 : 0 ≤ x.val := by rw [hxv]; omega
  obtain ⟨y, hy, hyv⟩ := WP.spec_imp_exists (sat_spec exp x hx0)
  simp only [hx, hy, bind_ok]
  split <;> simp [notExpired] <;> rename_i h <;> scalar_tac

theorem expiration_eq (now exp : I64) (l : U64) : ∃ r, auth.validate_expiration now exp l = ok r ∧
    (r = .Ok () ↔ notExpired now.val exp.val l.val) ∧ (r = .Ok () ∨ r = .Err .Authentication) :=
  WP.spec_imp_exists (expiration_spec now exp l)

theorem tt_ne (a b : auth.TokenType) :
    core.cmp.PartialEq.ne.trait_default auth.TokenType.Insts.CoreCmpPartialEqTokenType a b = ok (decide (a ≠ b)) := by
  cases a <;> cases b <;> simp [core.cmp.PartialEq.ne.trait_default, core.cmp.PartialEq.ne.default,
    auth.TokenType.Insts.CoreCmpPartialEqTokenType.eq, auth.TokenType.read_discriminant]

theorem user_token_accepted (now exp : I64) (l : U64) (typ expected : auth.TokenType)
    (h : auth.accept_user_token now exp l typ expected = ok (.Ok ())) :
    typ = expected ∧ notExpired now.val exp.val l.val := by
  obtain ⟨r, hr, hiff, hor⟩ := expiration_eq now exp l
  unfold auth.accept_user_token at h
  rcases hor with rfl | rfl
  · simp only [hr, bind_ok, core.result.Result.Insts.CoreOpsTry.branch, tt_ne] at h
    by_cases he : typ = expected <;> simp [he] at h
    exact ⟨he, hiff.1 rfl⟩
  · simp [hr, core.result.Result.Insts.CoreOpsTry.branch,
      core.result.Result.Insts.CoreOpsTry_traitFromResidualResult.from_residual] at h
