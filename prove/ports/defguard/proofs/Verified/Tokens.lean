import Verified.Lockout
/-!
# Enrollment tokens
-/
open Aeneas Aeneas.Std Result defguard_kernel defguard_kernel.Spec
open H5iAppLib

namespace defguard_kernel.Verified

theorem iadd_ok_val {ty} {x y z : IScalar ty} (h : x + y = ok z) : z.val = x.val + y.val := by
  have := IScalar.add_equiv x y; rw [h] at this; simp at this; omega

theorem same_eq (t : token.Token) : token.same t = ok t := by
  unfold token.same; cases t; rename_i a b c d; cases c <;> rfl

theorem is_session_valid_ok {t : token.Token} {now timeout : I64} {b : Bool}
    (h : token.is_session_valid t now timeout = ok b) : b = true ↔ SessionOpen t now.val timeout.val := by
  unfold token.is_session_valid at h
  unfold SessionOpen
  split at h
  · rename_i hn; have := (H5iAppLib.Result.ok.inj h).symm; subst this; simp [hn]
  · rename_i u hu
    obtain ⟨x, hx, h'⟩ := H5iAppLib.bind_tc_eq_ok.1 h
    have := (H5iAppLib.Result.ok.inj h').symm; subst this
    have hv := iadd_ok_val hx
    simp only [hu, Option.some.injEq, exists_eq_left', decide_eq_true_eq]
    constructor <;> intro hh <;> scalar_tac

/-- An expired token never starts a session, and is left as it was. -/
theorem expired_never_starts {t t' : token.Token} {now timeout : I64} {r : core.result.Result I64 token.TokenError}
    (hexp : t.expires_at.val < now.val) (h : token.start_session t now timeout = ok (t', r)) :
    t' = t ∧ r = .Err .TokenExpired := by
  unfold token.start_session at h
  have he : token.is_expired t now = ok true := by
    unfold token.is_expired; simp; scalar_tac
  rw [he] at h
  simp only [bind_ok, same_eq] at h
  simp only [↓reduceIte, bind_tc_ok] at h
  have := H5iAppLib.Result.ok.inj h; simp only [Prod.mk.injEq] at this
  exact ⟨this.1.symm, this.2.symm⟩

/-- A started session: the token had not expired; it is now marked used at
its first use (which a later call never moves); the deadline is that first
use plus the timeout, and a repeat call is accepted only inside it. -/
theorem start_session_ok {t t' : token.Token} {now timeout d : I64}
    (h : token.start_session t now timeout = ok (t', .Ok d)) :
    now.val ≤ t.expires_at.val ∧ t'.user_id = t.user_id ∧ t'.expires_at = t.expires_at ∧
    t'.enrollment_type = t.enrollment_type ∧
    ∃ u, t'.used_at = some u ∧ d.val = u.val + timeout.val ∧
      (t.used_at = none → u = now) ∧ (t.used_at ≠ none → t.used_at = some u ∧ now.val < u.val + timeout.val) := by
  unfold token.start_session at h
  h5i_invert h
  all_goals (try (simp at h; done))
  all_goals (have hexp : b = decide (t.expires_at < now) := (by unfold token.is_expired at hb; exact (H5iAppLib.Result.ok.inj hb).symm))
  · obtain ⟨rfl, rfl⟩ := h
    have hv := iadd_ok_val hi
    refine ⟨?_, rfl, rfl, rfl, now, rfl, hv, ⟨fun _ => rfl, fun hn => absurd hc_1 hn⟩⟩
    simp_all
  · obtain ⟨rfl, rfl⟩ := h
    rw [same_eq] at ht1; have := (H5iAppLib.Result.ok.inj ht1); subst this
    have hv := iadd_ok_val hi
    have hs := (is_session_valid_ok hb1).1 hc_2
    obtain ⟨u', hu', hlt⟩ := hs
    rw [hc_1] at hu'; cases hu'
    refine ⟨?_, rfl, rfl, rfl, u, hc_1, hv, ⟨fun hn => (by rw [hc_1] at hn; cases hn), fun _ => ⟨hc_1, hlt⟩⟩⟩
    simp_all

/-- `validate_session`: an enrollment token with an open session; the
request then acts for the token's user. -/
theorem validate_session_ok {t : token.Token} {now timeout : I64} {uid : U64}
    (h : token.validate_session t now timeout = ok (.Ok uid)) :
    t.enrollment_type = true ∧ SessionOpen t now.val timeout.val ∧ uid = t.user_id := by
  unfold token.validate_session at h
  h5i_invert h
  exact ⟨hc, (is_session_valid_ok hb).1 hc_1, rfl⟩

/-- Finding: `validate_session` never looks at `expires_at`. A session that
was opened before the token expired stays usable after it expires, until
`used_at + timeout`. -/
theorem session_outlives_token {t : token.Token} {now timeout u : I64}
    (he : t.enrollment_type = true) (hu : t.used_at = some u)
    (hin : now.val < u.val + timeout.val) (hb : u.val + timeout.val ≤ I64.max) (hb' : I64.min ≤ u.val + timeout.val) :
    token.validate_session t now timeout = ok (.Ok t.user_id) := by
  unfold token.validate_session token.is_session_valid
  have hs : (u + timeout) ⦃ z => z.val = u.val + timeout.val ⦄ := by step*
  obtain ⟨z, hz⟩ := ok_of hs
  have hzv := post_of_ok hs hz
  simp only [he, ↓reduceIte, hu, hz, bind_ok]
  have : now < z := by scalar_tac
  simp [this]

end defguard_kernel.Verified
