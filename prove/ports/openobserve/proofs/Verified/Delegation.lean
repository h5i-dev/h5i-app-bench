import Verified.Bytes
/-! Specs for `kernel/src/delegation.rs`: delegated-token verification and route scopes. -/
open Aeneas Aeneas.Std Result openobserve_kernel openobserve_kernel.Spec openobserve_kernel.Verified
open H5iAppLib hiding lit
open openobserve_kernel.delegation

namespace openobserve_kernel.Verified

theorem i64_add_ok {x y z : I64} (h : x + y = ok z) :
    z.val = x.val + y.val ∧ I64.min ≤ x.val + y.val ∧ x.val + y.val ≤ I64.max := by
  have := IScalar.add_equiv x y; rw [h] at this
  simp [IScalar.inBounds] at this
  refine ⟨this.2.2.1, ?_, ?_⟩ <;> scalar_tac

theorem i64_sub_ok {x y z : I64} (h : x - y = ok z) :
    z.val = x.val - y.val ∧ I64.min ≤ x.val - y.val ∧ x.val - y.val ≤ I64.max := by
  have := IScalar.sub_equiv x y; rw [h] at this
  simp [IScalar.inBounds] at this
  refine ⟨this.2.2.1, ?_, ?_⟩ <;> scalar_tac

/-- No panic when `now + 60` and `exp - iat` fit in an `i64`; then
`check_claims` is `checkClaims`. -/
theorem check_claims_spec (c : Claims) (now : I64)
    (h1 : now.val + 60 ≤ I64.max) (h2 : c.exp.val - c.iat.val ≤ I64.max) :
    check_claims c now ⦃ r => r = checkClaims c now.val ⦄ := by
  unfold check_claims checkClaims
  simp only [TOKEN_VERSION, MAX_IAT_SKEW_SECS, MAX_LIFETIME_SECS]
  step*

  all_goals (split_ifs <;> first | rfl | (exfalso; simp_all; try scalar_tac))

/-- Without any bound: a token `check_claims` accepts is fresh in exact
integer arithmetic (an overflow fails instead of wrapping). -/
theorem check_claims_ok (c c' : Claims) (now : I64) (h : check_claims c now = ok (.Ok c')) :
    c' = c ∧ ClaimsFresh c now.val := by
  unfold check_claims at h
  simp only [TOKEN_VERSION, MAX_IAT_SKEW_SECS, MAX_LIFETIME_SECS] at h
  h5i_invert h
  have := i64_add_ok hi; have := i64_sub_ok hi1
  refine ⟨rfl, ?_⟩
  simp only [ClaimsFresh]
  simp_all
  try scalar_tac


/-- The bound is needed: for a signed-looking `exp = i64::MAX, iat = -10`,
`exp - iat` overflows. The kernel fails here; upstream wraps in release builds
and accepts (difftest `upstream_release_wraps_lifetime_check`). -/
theorem check_claims_overflow (c : Claims) (hv : c.v = 1#u8) (he : c.exp.val = I64.max)
    (hi : c.iat.val = -10) (r) :
    check_claims c 1791937000#i64 ≠ ok r := by
  intro h
  unfold check_claims at h
  simp only [TOKEN_VERSION, MAX_IAT_SKEW_SECS, MAX_LIFETIME_SECS] at h
  h5i_invert h
  all_goals (try have := i64_add_ok hi_1); all_goals (try have := i64_sub_ok hi1)
  all_goals (simp_all; try scalar_tac)

h5i_derive_clone Claims Claims.Insts.CoreCloneClone.clone

theorem mem_nats_iff (l : List U8) (x : U8) : x.val ∈ nats l ↔ x ∈ l := by
  simp only [nats, List.mem_map]
  exact ⟨fun ⟨y, hy, he⟩ => (UScalar.eq_of_val_eq he) ▸ hy, fun h => ⟨x, h, rfl⟩⟩

theorem o2dt_slice (s : Slice U8)
    (h : s = (Array.make 5#usize [111#u8, 50#u8, 100#u8, 116#u8, 46#u8] (by simp)).to_slice) :
    nats s.val = [111, 50, 100, 116, 46] ∧ s.val.length = 5 := by
  subst h; simp [nats, Array.to_slice, Array.make]

/-- The branches past the shape check: the token has the `o2dt.<c>.<m>` shape. -/
theorem shape_of (t : Slice U8) (s : Slice U8) (hs : nats s.val = [111, 50, 100, 116, 46] ∧ s.val.length = 5)
    (o1 : Option (alloc.vec.Vec U8)) (rest : alloc.vec.Vec U8)
    (o1_post : Option.map (fun v => v.val) o1 = if nats s.val <+: nats t.val then some (List.drop s.val.length t.val) else none)
    (h1 : o1 = some rest) (h2 : decide (46#u8 ∈ rest.val) = true) :
    [111, 50, 100, 116, 46] <+: nats t.val ∧ 46 ∈ (nats t.val).drop 5 := by
  rw [hs.1] at o1_post
  split at o1_post
  · rename_i hp
    simp only [h1, Option.map_some, Option.some.injEq] at o1_post
    refine ⟨hp, ?_⟩
    rw [nats, ← List.map_drop, ← nats, show (46 : Nat) = (46#u8 : U8).val from rfl, mem_nats_iff,
      ← hs.2, ← o1_post]
    simpa using h2
  · simp_all

theorem verify_spec (t : Slice U8) (o : VerifyOracle) (now : I64)
    (hb : ∀ c, o.claims = some c → now.val + 60 ≤ I64.max ∧ c.exp.val - c.iat.val ≤ I64.max) :
    verify t o now ⦃ r => r = verifySpec (nats t.val) o now.val ⦄ := by
  unfold verify
  step*
  · have hs := o2dt_slice s s_post
    rw [hs.1] at o1_post
    split at o1_post
    · simp_all
    · rw [verifySpec, if_pos (by tauto)]
  · have hs := o2dt_slice s s_post
    rw [hs.1] at o1_post
    split at o1_post
    · rename_i hp
      simp only [‹o1 = some rest›, Option.map_some, Option.some.injEq] at o1_post
      have hn : ¬ 46 ∈ (nats t.val).drop 5 := by
        rw [nats, ← List.map_drop, ← nats, show (46 : Nat) = (46#u8 : U8).val from rfl, mem_nats_iff,
          ← hs.2, ← o1_post]
        simpa [alloc.vec.Vec.deref, ‹o2 = none›] using o2_post
      rw [verifySpec, if_pos (by tauto)]
    · simp_all
  · have hsh := shape_of t s (o2dt_slice s s_post) o1 rest o1_post ‹_›
      (by simpa [alloc.vec.Vec.deref, ‹o2 = some _›] using o2_post.symm)
    rw [verifySpec, if_neg (by tauto), ‹o.given_mac = none›]
  · have hsh := shape_of t s (o2dt_slice s s_post) o1 rest o1_post ‹_›
      (by simpa [alloc.vec.Vec.deref, ‹o2 = some _›] using o2_post.symm)
    have hv : verifySpec (nats t.val) o now.val =
        (if nats o.mac_current.val = nats given.val ∨ previousMatches o (nats given.val) then
          match o.claims with
          | none => .Err (.Malformed .ClaimsEncoding)
          | some c => checkClaims c now.val
        else .Err .BadSignature) := by
      rw [verifySpec, if_neg (by tauto), ‹o.given_mac = some given›]; rfl
    rw [hv]
    h5i_steps
    all_goals (simp_all [previousMatches, alloc.vec.Vec.deref])
    all_goals (exact check_claims_spec _ _ hb.1 (by scalar_tac))

/-- Without any bound on the claims: an accepted token has the shape, a
matching MAC, and fresh claims in exact integer arithmetic. -/
theorem verify_ok (t : Slice U8) (o : VerifyOracle) (now : I64) (c : Claims)
    (h : verify t o now = ok (.Ok c)) :
    TokenShape (nats t.val) ∧ SignatureOk o ∧ o.claims = some c ∧ ClaimsFresh c now.val := by
  unfold verify at h
  h5i_invert h

  all_goals
    have hs' := o2dt_slice s (by simpa [lift] using hs.symm)
    have h1 := post_of_ok (strip_prefix_spec t s) ho1
    have h2 := post_of_ok (split_once_spec _ 46#u8) ho2
    have h3 := post_of_ok (constant_time_eq_spec _ _) hcurrent_ok
    obtain ⟨hcc, hf⟩ := check_claims_ok _ _ _ h
    subst hcc
    have hcl : c = claims := by simpa using hc_1_1.symm
    subst hcl
    have hsh := shape_of t s hs' (some rest) rest h1 rfl (by simpa [alloc.vec.Vec.deref] using h2.symm)
    refine ⟨hsh, ⟨rest_1, hc, ?_⟩, ‹o.claims = some _›, hf⟩
  · left; simpa [alloc.vec.Vec.deref, hc_1] using h3.symm
  · right
    split at hprevious_ok
    · simp_all
    · rename_i m hm
      have h4 := post_of_ok (constant_time_eq_spec _ _) hprevious_ok
      exact ⟨m, hm, by simpa [alloc.vec.Vec.deref, hc_2] using h4.symm⟩

end openobserve_kernel.Verified
