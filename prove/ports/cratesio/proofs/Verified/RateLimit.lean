import Verified.Derived
import Spec
/-!
# The publish rate limit (`RateLimiter::take_token`)
-/
open Aeneas Aeneas.Std Result cratesio_kernel cratesio_kernel.Spec
open H5iAppLib hiding Covers
open Aeneas.Std.WP

namespace cratesio_kernel.Verified.RateLimit

/-- `take_token` on an existing bucket, over integers. -/
def takeM (t l now rate burst : Int) : Int × Int :=
  let add := (now - l) / rate
  let kept := max (t - 1) 0
  (if burst - kept ≤ add then burst else kept + add, l + rate * add)

/-- Times and sizes small enough that no step overflows. -/
def Small (x : Int) : Prop := 0 ≤ x ∧ x < 2 ^ 61

theorem take_some_spec (b : rate_limit.Bucket) (now rate burst : I64)
    (hb : 0 ≤ b.tokens.val ∧ b.tokens.val ≤ burst.val) (hl : Small b.last_refill.val) (hn : Small now.val)
    (hle : b.last_refill.val ≤ now.val) (hr : 0 < rate.val) (hbu : Small burst.val) :
    rate_limit.take_token (some b) now rate burst ⦃ b' =>
      (b'.tokens.val, b'.last_refill.val) = takeM b.tokens.val b.last_refill.val now.val rate.val burst.val ⦄ := by
  unfold rate_limit.take_token
  simp only [Small] at *
  step*
  have hadd : add.val = (now.val - b.last_refill.val) / rate.val := by
    rw [add_post, i_post, Int.tdiv_eq_ediv_of_nonneg (by omega)]
  have h0 : 0 ≤ add.val := by rw [hadd]; exact Int.ediv_nonneg (by omega) (by omega)
  have hmul : rate.val * add.val ≤ now.val - b.last_refill.val := by
    rw [hadd]; exact Int.mul_ediv_self_le (by omega)
  have hle' : add.val ≤ now.val - b.last_refill.val := by
    have : 1 * add.val ≤ rate.val * add.val := Int.mul_le_mul_of_nonneg_right (by omega) h0
    omega
  have hkept : ∀ kept : I64, kept.val = max (b.tokens.val - 1) 0 →
      (do
        let i2 ← burst - kept
        let tokens ← if add ≥ i2 then ok burst else kept + add
        let i3 ← rate * add
        let i4 ← b.last_refill + i3
        ok ({ tokens := tokens, last_refill := i4 } : rate_limit.Bucket)) ⦃ b' =>
      (b'.tokens.val, b'.last_refill.val) = takeM b.tokens.val b.last_refill.val now.val rate.val burst.val ⦄ := by
    intro kept hk
    have hk0 : 0 ≤ kept.val := by rw [hk]; omega
    have hk1 : kept.val ≤ burst.val := by rw [hk]; omega
    have hpos : 0 ≤ rate.val * add.val := Int.mul_nonneg (by omega) h0
    h5i_steps
    all_goals first
      | scalar_tac
      | (simp only [takeM, Prod.mk.injEq]; rw [← hk, ← hadd]
         refine ⟨?_, by rw [i4_post, i3_post]⟩
         split <;> scalar_tac)
  by_cases hk : i1 > 0#i64
  · simp only [hk, if_true, bind_tc_ok, bind_ok]
    exact hkept i1 (by have : 0 < i1.val := by scalar_tac
                       omega)
  · simp only [hk, if_false, bind_tc_ok, bind_ok]
    exact hkept 0#i64 (by have : i1.val ≤ 0 := by scalar_tac
                          simp only [show ((0#i64 : I64) : Int) = 0 from rfl]; omega)

/-- One step of the counting invariant. -/
theorem step_inv (A k t0 l t rate burst : Int) (pass : Bool)
    (hr : 0 < rate) (hb : 0 ≤ burst) (ht0 : 0 ≤ t0 ∧ t0 ≤ burst) (hlt : l ≤ t)
    (hinv : A + max t0 1 ≤ burst + 1 + k)
    (hpass : pass = true ↔ 1 ≤ (takeM t0 l t rate burst).1) :
    (if pass then A + 1 else A) + max (takeM t0 l t rate burst).1 1 ≤ burst + 1 + (k + (t - l) / rate) ∧
      0 ≤ (takeM t0 l t rate burst).1 ∧ (takeM t0 l t rate burst).1 ≤ burst ∧ 0 ≤ (t - l) / rate := by
  have h0 : 0 ≤ (t - l) / rate := Int.ediv_nonneg (by omega) (by omega)
  simp only [takeM] at hpass ⊢
  have hK : (max (t0 - 1) 0 = t0 - 1 ∧ 1 ≤ t0) ∨ (max (t0 - 1) 0 = 0 ∧ t0 ≤ 1) := by
    rcases le_total 1 t0 with h | h
    · left; exact ⟨max_eq_left (by omega), h⟩
    · right; exact ⟨max_eq_right (by omega), h⟩
  have hM : (max t0 1 = t0 ∧ 1 ≤ t0) ∨ (max t0 1 = 1 ∧ t0 ≤ 1) := by
    rcases le_total 1 t0 with h | h
    · left; exact ⟨max_eq_left h, h⟩
    · right; exact ⟨max_eq_right h, h⟩
  generalize max (t0 - 1) 0 = K at hpass hK ⊢
  generalize (t - l) / rate = D at hpass h0 ⊢
  rw [show max t0 1 = max t0 1 from rfl] at hinv
  generalize max t0 1 = M at hinv hM
  by_cases hc : burst - K ≤ D
  · simp only [hc, if_true] at hpass ⊢
    have hX : (max burst 1 = burst ∧ 1 ≤ burst) ∨ (max burst 1 = 1 ∧ burst ≤ 1) := by
      rcases le_total 1 burst with h | h
      · left; exact ⟨max_eq_left h, h⟩
      · right; exact ⟨max_eq_right h, h⟩
    generalize max burst 1 = X at hX ⊢
    cases pass <;> simp at hpass ⊢ <;> omega
  · simp only [hc, if_false] at hpass ⊢
    have hX : (max (K + D) 1 = K + D ∧ 1 ≤ K + D) ∨ (max (K + D) 1 = 1 ∧ K + D ≤ 1) := by
      rcases le_total 1 (K + D) with h | h
      · left; exact ⟨max_eq_left h, h⟩
      · right; exact ⟨max_eq_right h, h⟩
    generalize max (K + D) 1 = X at hX ⊢
    cases pass <;> simp at hpass ⊢ <;> omega

theorem check_some (b : rate_limit.Bucket) (now rate burst : I64)
    (hb : 0 ≤ b.tokens.val ∧ b.tokens.val ≤ burst.val) (hl : Small b.last_refill.val) (hn : Small now.val)
    (hle : b.last_refill.val ≤ now.val) (hr : 0 < rate.val) (hbu : Small burst.val) :
    ∃ b', rate_limit.check_rate_limit (some b) now rate burst = ok (b', decide (1 ≤ b'.tokens.val)) ∧
      (b'.tokens.val, b'.last_refill.val) = takeM b.tokens.val b.last_refill.val now.val rate.val burst.val := by
  obtain ⟨b', hb'⟩ := ok_of (take_some_spec b now rate burst hb hl hn hle hr hbu)
  have := post_of_ok (take_some_spec b now rate burst hb hl hn hle hr hbu) hb'
  refine ⟨b', ?_, this⟩
  have hiff : (1#i64 ≤ b'.tokens) ↔ 1 ≤ b'.tokens.val := by scalar_tac
  simp only [rate_limit.check_rate_limit, hb', bind_tc_ok, bind_ok, ge_iff_le, decide_eq_decide.2 hiff]

theorem run_bound (rate burst : I64) (t1 : Int) (hr : 0 < rate.val) (hbu : Small burst.val) :
    ∀ (rest : List I64) (b : rate_limit.Bucket) (A k : Int) (cur : I64),
      (0 ≤ b.tokens.val ∧ b.tokens.val ≤ burst.val) → Small b.last_refill.val →
      b.last_refill.val = t1 + rate.val * k → 0 ≤ k → b.last_refill.val ≤ cur.val → Small cur.val →
      A + max b.tokens.val 1 ≤ burst.val + 1 + k →
      (∀ t ∈ rest, Small t.val) → List.Pairwise (fun a b : I64 => a.val ≤ b.val) (cur :: rest) →
      ∃ bs, rateRun rate burst rest (some b) = ok bs ∧
        A + bs.count true ≤ burst.val + (((cur :: rest).getLast (by simp)).val - t1) / rate.val := by
  intro rest
  induction rest with
  | nil =>
    intro b A k cur hb hl hk hk0 hlc hc hinv _ _
    refine ⟨[], rfl, ?_⟩
    simp only [List.count_nil, List.getLast_singleton, Nat.cast_zero, add_zero]
    have : k ≤ (cur.val - t1) / rate.val := by
      apply Int.le_ediv_of_mul_le hr
      have : rate.val * k = k * rate.val := Int.mul_comm _ _
      omega
    have : 1 ≤ max b.tokens.val 1 := le_max_right _ _
    omega
  | cons t rest ih =>
    intro b A k cur hb hl hk hk0 hlc hc hinv hsm hch
    have ht := hsm t (by simp)
    have hct : cur.val ≤ t.val := (List.pairwise_cons.1 hch).1 t (by simp)
    obtain ⟨b', hcheck, hm⟩ := check_some b t rate burst hb hl ht (by omega) hr hbu
    have h1 : (takeM b.tokens.val b.last_refill.val t.val rate.val burst.val).1 = b'.tokens.val := by rw [← hm]
    have hstep := step_inv A k b.tokens.val b.last_refill.val t.val rate.val burst.val
      (decide (1 ≤ b'.tokens.val)) hr hbu.1 hb (by omega) hinv (by rw [h1]; simp)
    have hm2 : b'.last_refill.val = (takeM b.tokens.val b.last_refill.val t.val rate.val burst.val).2 := by
      rw [← hm]
    rw [h1] at hstep
    obtain ⟨hI, hT0, hT1, hD⟩ := hstep
    have hmul : rate.val * ((t.val - b.last_refill.val) / rate.val) ≤ t.val - b.last_refill.val :=
      Int.mul_ediv_self_le (by omega)
    have hlast : b'.last_refill.val = t1 + rate.val * (k + (t.val - b.last_refill.val) / rate.val) := by
      rw [hm2]; simp only [takeM]; rw [hk]; ring
    have hlast_le : b'.last_refill.val ≤ t.val := by
      rw [hm2]; simp only [takeM]; omega
    have hpos : 0 ≤ rate.val * ((t.val - b.last_refill.val) / rate.val) := Int.mul_nonneg (by omega) hD
    obtain ⟨bs, hrun, hcount⟩ := ih b' (if decide (1 ≤ b'.tokens.val) then A + 1 else A)
      (k + (t.val - b.last_refill.val) / rate.val) t ⟨hT0, hT1⟩
      (by constructor <;> (rw [hm2]; simp only [takeM]; simp only [Small] at hl ht; omega))
      hlast (by omega) hlast_le ht hI (fun x hx => hsm x (by simp [hx]))
      (by
        have h2 := (List.pairwise_cons.1 hch).2
        exact h2)
    refine ⟨decide (1 ≤ b'.tokens.val) :: bs, ?_, ?_⟩
    · simp [rateRun, hcheck, hrun]
    · simp only [List.getLast_cons_cons] at hcount ⊢
      rw [List.count_cons]
      split_ifs at hcount <;> simp_all <;> omega

/-- From no bucket: the requests at nondecreasing times `t1, …, tn` that pass
number at most `burst + (tn - t1) / rate`. -/
theorem rate_limit_bounded (rate burst t1 : I64) (rest : List I64) (hr : 0 < rate.val) (hbu : Small burst.val)
    (hsm : ∀ t ∈ t1 :: rest, Small t.val) (hs : List.Pairwise (fun a b : I64 => a.val ≤ b.val) (t1 :: rest)) :
    ∃ bs, rateRun rate burst (t1 :: rest) none = ok bs ∧
      (bs.count true : Int) ≤ burst.val + (((t1 :: rest).getLast (by simp)).val - t1.val) / rate.val := by
  have h1 := hsm t1 (by simp)
  obtain ⟨bs, hrun, hcount⟩ := run_bound rate burst t1.val hr hbu rest ⟨burst, t1⟩
    (if decide (1 ≤ burst.val) then 1 else 0) 0 t1 ⟨hbu.1, le_refl _⟩ h1 (by simp) (le_refl _) (le_refl _) h1
    (by have := hbu.1; show _ + max burst.val 1 ≤ _; rw [max_def]; split_ifs with h1 h2 <;> simp at h1 <;> omega)
    (fun x hx => hsm x (by simp [hx])) hs
  have hiff : (1#i64 ≤ burst) ↔ 1 ≤ burst.val := by scalar_tac
  refine ⟨decide (1 ≤ burst.val) :: bs, ?_, ?_⟩
  · simp [rateRun, rate_limit.check_rate_limit, rate_limit.take_token, hrun, hiff]
  · have hb0 := hbu.1
    rw [List.count_cons]
    by_cases hb1 : 1 ≤ burst.val
    · simp only [hb1, decide_true, if_true] at hcount ⊢
      simp; omega
    · simp only [hb1, decide_false, Bool.false_eq_true, if_false] at hcount ⊢
      simp; omega

end cratesio_kernel.Verified.RateLimit
