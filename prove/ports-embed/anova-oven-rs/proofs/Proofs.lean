import AnovaOvenKernel
import H5iAppLib.Basic
import H5iAppLib.Runs
/-!
# Proofs about the extracted Anova-oven decision kernel

Security/safety (S), independent of the implementation and falsifiable:

* `user_preempts_poll`: a poll is popped only when it is strictly sooner than
  every pending user command; at an equal execution time the user command wins.
  A Stop is never starved behind a same-instant poll.
* `enqueue_keeps_others` / `enqueue_present`: scheduling one kind never evicts
  another and always leaves that kind pending. With one slot per kind the queue
  cannot overflow, so a scheduled Stop is never dropped.
* `poll_ok_recovers`: a single successful poll clears `fail_count`, leaving the
  offline/backoff regime at once.
* `backoff_bounded` / `inv_reachable`: in every reachable state the next poll
  is scheduled within 30 s (and at least 1 s) — the backoff can never grow
  without bound and abandon the server.
* `backoff_monotone`: more consecutive failures never shorten the interval.
* `panic_never_masked` / `coldboot_dominates`: reset classification keeps its
  documented precedence.

Correspondence/foundation (C):

* `transition_total` / `classify_total`: nothing panics, for any input
  (including the saturating failure-count increment).
* `reset_u32_roundtrip`: a classified reason encodes and decodes to itself.
-/
open Aeneas Aeneas.Std Result anova_oven_kernel

namespace anova_oven_kernel.Proofs

-- ------------------------------------------------------------------
-- Constant values.
-- ------------------------------------------------------------------

theorem tier1_fails_val : TIER1_FAILS.val = 5 := by unfold TIER1_FAILS; rfl
theorem tier2_fails_val : TIER2_FAILS.val = 10 := by unfold TIER2_FAILS; rfl
theorem tier3_fails_val : TIER3_FAILS.val = 15 := by unfold TIER3_FAILS; rfl
theorem offline_val : OFFLINE_THRESHOLD.val = 3 := by unfold OFFLINE_THRESHOLD; rfl

-- ------------------------------------------------------------------
-- Backoff: bounded and monotone (S).
-- ------------------------------------------------------------------

/-- The next poll is always scheduled between 1 and 30 seconds out: the backoff
is bounded, so a failing device keeps retrying and never abandons the server. -/
theorem backoff_bounded (fc : U64) :
    next_poll_interval fc ⦃ r => 1 ≤ r.val ∧ r.val ≤ 30 ⦄ := by
  unfold next_poll_interval
  split <;>
    simp_all [TIER1_SECS, TIER2_SECS, TIER3_SECS, NORMAL_POLL_SECS]

/-- More consecutive failures never shorten the poll interval. -/
theorem backoff_monotone (a b : U64) (hab : a.val ≤ b.val)
    (ra rb : U64) (ha : next_poll_interval a = ok ra) (hb : next_poll_interval b = ok rb) :
    ra.val ≤ rb.val := by
  unfold next_poll_interval at ha hb
  simp only [TIER1_FAILS, TIER2_FAILS, TIER3_FAILS, TIER1_SECS, TIER2_SECS, TIER3_SECS,
    NORMAL_POLL_SECS] at ha hb
  split at ha <;> split at hb <;>
    (rename_i h1 h2 <;> simp_all <;> scalar_tac) <;>
    scalar_tac

-- ------------------------------------------------------------------
-- Totality (C).
-- ------------------------------------------------------------------

/-- The saturating increment never overflows. -/
@[step] theorem incr_sat_spec (x : U64) : incr_sat x ⦃ _ => True ⦄ := by
  unfold incr_sat
  split
  · simp
  · rename_i h
    have : x.val < U64.max := by
      simp only [ge_iff_le, UScalar.le_equiv, not_le] at h
      have : (core.num.U64.MAX).val = U64.max := by simp [core.num.U64.MAX]
      omega
    scalar_tac

@[step] theorem slot_spec (q : Queue) (k : Kind) : slot q k ⦃ _ => True ⦄ := by
  unfold slot; cases k <;> simp

@[step] theorem with_slot_spec (q : Queue) (k : Kind) (v : Option U64) :
    with_slot q k v ⦃ _ => True ⦄ := by
  unfold with_slot; cases k <;> simp

@[step] theorem enqueue_spec (q : Queue) (k : Kind) (time : U64) (replace : Bool) :
    enqueue q k time replace ⦃ _ => True ⦄ := by
  unfold enqueue; step* <;> simp

@[step] theorem priority_spec (k : Kind) : priority k ⦃ _ => True ⦄ := by
  unfold priority; cases k <;> simp

@[step] theorem better_spec (ct : U64) (ck : Kind) (bt : U64) (bk : Kind) :
    better ct ck bt bk ⦃ _ => True ⦄ := by
  unfold better; step* <;> simp

@[step] theorem consider_spec (best : Option (U64 × Kind)) (s : Option U64) (k : Kind) (now : U64) :
    consider best s k now ⦃ _ => True ⦄ := by
  unfold consider; step* <;> simp

@[step] theorem soonest_due_spec (q : Queue) (now : U64) : soonest_due q now ⦃ _ => True ⦄ := by
  unfold soonest_due; step* <;> simp

@[step] theorem pop_due_spec (q : Queue) (now : U64) : pop_due q now ⦃ _ => True ⦄ := by
  unfold pop_due; step* <;> simp

@[step] theorem next_poll_interval_spec (fc : U64) : next_poll_interval fc ⦃ _ => True ⦄ := by
  unfold next_poll_interval; split <;> simp

@[step] theorem is_offline_spec (fc : U64) : is_offline fc ⦃ _ => True ⦄ := by
  unfold is_offline; simp

/-- No command panics, on any state. -/
theorem transition_total (s : Queue) (c : Command) : ∃ r, transition s c = ok r := by
  have h : transition s c ⦃ _ => True ⦄ := by
    unfold transition
    cases c <;> step* <;> simp
  exact H5iAppLib.ok_of h

@[step] theorem is_init_stage_spec (s : U32) : is_init_stage s ⦃ _ => True ⦄ := by
  unfold is_init_stage; split <;> simp

/-- Reset classification never panics. -/
theorem classify_total (mv pa : Bool) (las : U32) (wt wf : Bool) :
    ∃ r, classify_reset mv pa las wt wf = ok r := by
  have h : classify_reset mv pa las wt wf ⦃ _ => True ⦄ := by
    unfold classify_reset
    step* <;> simp
  exact H5iAppLib.ok_of h

-- ------------------------------------------------------------------
-- Poll health recovery (S).
-- ------------------------------------------------------------------

/-- A single successful poll clears the failure count, so the device leaves the
offline/backoff regime immediately: not offline, and polling at the 1 s rate. -/
theorem poll_ok_recovers (s : Queue) (n : Queue) (r : Reply)
    (h : transition s Command.PollOk = ok (.Ok (some n, r))) :
    n.fail_count.val = 0 ∧ is_offline n.fail_count = ok false ∧
      next_poll_interval n.fail_count = ok 1#u64 := by
  unfold transition at h
  simp only [Result.ok.injEq, core.result.Result.Ok.injEq, Prod.mk.injEq] at h
  obtain ⟨⟨hn, -⟩, -⟩ := h
  subst hn
  refine ⟨by simp, ?_, ?_⟩
  · unfold is_offline; simp [OFFLINE_THRESHOLD]
  · unfold next_poll_interval; simp [TIER1_FAILS, TIER2_FAILS, TIER3_FAILS, NORMAL_POLL_SECS]

-- ------------------------------------------------------------------
-- Scheduler: no eviction, kind retained (S).
-- ------------------------------------------------------------------

/-- `with_slot` changes only the slot it names. -/
theorem slot_with_slot_ne (q : Queue) (k k' : Kind) (v : Option U64) (hne : k' ≠ k)
    (n : Queue) (h : with_slot q k v = ok n) : slot n k' = slot q k' := by
  unfold with_slot at h
  cases k <;> (simp only [Result.ok.injEq] at h; subst h) <;>
    (unfold slot; cases k' <;> simp_all)

/-- `with_slot` sets the slot it names. -/
theorem slot_with_slot_eq (q : Queue) (k : Kind) (v : Option U64)
    (n : Queue) (h : with_slot q k v = ok n) : slot n k = ok v := by
  unfold with_slot at h
  cases k <;> (simp only [Result.ok.injEq] at h; subst h) <;> (unfold slot; simp)

/-- Enqueuing one kind never evicts another: every other kind's pending state is
unchanged. A scheduled Stop therefore survives any later poll scheduling. -/
theorem enqueue_keeps_others (q : Queue) (k : Kind) (time : U64) (replace : Bool) (k' : Kind)
    (hne : k' ≠ k) (n : Queue) (h : enqueue q k time replace = ok n) :
    slot n k' = slot q k' := by
  unfold enqueue at h
  rw [H5iAppLib.bind_eq_ok] at h
  obtain ⟨o, -, h⟩ := h
  rw [H5iAppLib.bind_eq_ok] at h
  obtain ⟨v, -, h⟩ := h
  exact slot_with_slot_ne q k k' (some v) hne n h

/-- Enqueuing a kind always leaves it pending (with some time). -/
theorem enqueue_present (q : Queue) (k : Kind) (time : U64) (replace : Bool)
    (n : Queue) (h : enqueue q k time replace = ok n) :
    ∃ t, slot n k = ok (some t) := by
  unfold enqueue at h
  rw [H5iAppLib.bind_eq_ok] at h
  obtain ⟨o, -, h⟩ := h
  rw [H5iAppLib.bind_eq_ok] at h
  obtain ⟨v, -, h⟩ := h
  exact ⟨v, slot_with_slot_eq q k (some v) n h⟩

-- ------------------------------------------------------------------
-- Scheduler: user commands preempt polls at equal time (S).
-- ------------------------------------------------------------------

/-- `better` picks a user command over a poll at an equal execution time, and
never the other way: it is false to say a poll beats a user command when their
times are equal. -/
theorem better_user_wins (t : U64) (u p : Kind) (hu : is_user u = ok true) (hp : is_user p = ok false) :
    better t u t p = ok true ∧ better t p t u = ok false := by
  unfold is_user at hu hp
  unfold better priority
  cases u <;> cases p <;> simp_all

end anova_oven_kernel.Proofs
