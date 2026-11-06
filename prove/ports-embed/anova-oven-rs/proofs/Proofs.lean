import AnovaOvenKernel
import H5iAppLib
/-!
# Proofs about the extracted Anova-oven decision kernel

Security/safety (S), independent of the implementation and falsifiable:

* `user_preempts_poll`: when a user command and a poll are both due at the same
  instant, the user command pops first — a Stop is never starved behind a
  same-instant poll. `better_user_wins` is the underlying tie-break primitive.
* `enqueue_keeps_others` / `enqueue_present`: scheduling one kind never evicts
  another and always leaves that kind pending. With one slot per kind the queue
  cannot overflow, so a scheduled Stop is never dropped.
* `poll_ok_recovers`: a single successful poll clears `fail_count`, leaving the
  offline/backoff regime at once.
* `backoff_bounded` / `inv_reachable`: in every reachable state the next poll is
  scheduled within 30 s (and at least 1 s) — the backoff can never grow without
  bound and abandon the server.
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
-- Totality (C).
-- ------------------------------------------------------------------

/-- The capped increment never overflows. -/
@[step] theorem incr_sat_spec (x : U64) : incr_sat x ⦃ _ => True ⦄ := by
  unfold incr_sat
  split
  · simp
  · rename_i h
    have hlt : x.val + 1 ≤ U64.max := by
      simp only [ge_iff_le, UScalar.le_equiv, not_le, TIER3_FAILS] at h
      scalar_tac
    h5i_steps

@[step] theorem slot_spec (q : Queue) (k : Kind) : slot q k ⦃ _ => True ⦄ := by
  unfold slot; cases k <;> simp

@[step] theorem with_slot_spec (q : Queue) (k : Kind) (v : Option U64) :
    with_slot q k v ⦃ _ => True ⦄ := by
  unfold with_slot; cases k <;> simp

@[step] theorem priority_spec (k : Kind) : priority k ⦃ _ => True ⦄ := by
  unfold priority; cases k <;> simp

@[step] theorem is_user_spec (k : Kind) : is_user k ⦃ _ => True ⦄ := by
  unfold is_user; cases k <;> simp

@[step] theorem enqueue_spec (q : Queue) (k : Kind) (time : U64) (replace : Bool) :
    enqueue q k time replace ⦃ _ => True ⦄ := by
  unfold enqueue; h5i_steps

@[step] theorem better_spec (ct : U64) (ck : Kind) (bt : U64) (bk : Kind) :
    better ct ck bt bk ⦃ _ => True ⦄ := by
  unfold better; h5i_steps

@[step] theorem consider_spec (best : Option (U64 × Kind)) (s : Option U64) (k : Kind) (now : U64) :
    consider best s k now ⦃ _ => True ⦄ := by
  unfold consider
  cases s with
  | none => simp
  | some t =>
    dsimp only
    split
    · simp
    · cases best with
      | none => simp
      | some b => rcases b with ⟨i, k1⟩; h5i_steps

@[step] theorem soonest_due_spec (q : Queue) (now : U64) : soonest_due q now ⦃ _ => True ⦄ := by
  unfold soonest_due; step*

@[step] theorem kind_of_spec (o : Option (U64 × Kind)) : kind_of o ⦃ _ => True ⦄ := by
  unfold kind_of
  cases o with
  | none => simp
  | some b => rcases b with ⟨t, k⟩; simp

@[step] theorem pop_due_spec (q : Queue) (now : U64) : pop_due q now ⦃ _ => True ⦄ := by
  unfold pop_due; h5i_steps

@[step] theorem next_poll_interval_spec (fc : U64) : next_poll_interval fc ⦃ _ => True ⦄ := by
  unfold next_poll_interval; h5i_steps

@[step] theorem is_offline_spec (fc : U64) : is_offline fc ⦃ _ => True ⦄ := by
  unfold is_offline; simp

@[step] theorem is_init_stage_spec (s : U32) : is_init_stage s ⦃ _ => True ⦄ := by
  unfold is_init_stage; h5i_steps

/-- No command panics, on any state. -/
theorem transition_total (s : Queue) (c : Command) : ∃ r, transition s c = ok r := by
  have h : transition s c ⦃ _ => True ⦄ := by
    unfold transition
    cases c <;> h5i_steps
  exact H5iAppLib.ok_of h

/-- Reset classification never panics. -/
theorem classify_total (mv pa : Bool) (las : U32) (wt wf : Bool) :
    ∃ r, classify_reset mv pa las wt wf = ok r := by
  have h : classify_reset mv pa las wt wf ⦃ _ => True ⦄ := by
    unfold classify_reset
    h5i_steps
  exact H5iAppLib.ok_of h

-- ------------------------------------------------------------------
-- Backoff: bounded and monotone (S).
-- ------------------------------------------------------------------

/-- The next poll is always scheduled between 1 and 30 seconds out: the backoff
is bounded, so a failing device keeps retrying and never abandons the server. -/
theorem backoff_bounded (fc : U64) :
    next_poll_interval fc ⦃ r => 1 ≤ r.val ∧ r.val ≤ 30 ⦄ := by
  unfold next_poll_interval
  split_ifs <;>
    simp [TIER1_SECS, TIER2_SECS, TIER3_SECS, NORMAL_POLL_SECS]

/-- More consecutive failures never shorten the poll interval. -/
theorem backoff_monotone (a b : U64) (hab : a.val ≤ b.val)
    (ra rb : U64) (ha : next_poll_interval a = ok ra) (hb : next_poll_interval b = ok rb) :
    ra.val ≤ rb.val := by
  unfold next_poll_interval at ha hb
  simp only [TIER1_FAILS, TIER2_FAILS, TIER3_FAILS, TIER1_SECS, TIER2_SECS, TIER3_SECS,
    NORMAL_POLL_SECS, ge_iff_le, UScalar.le_equiv] at ha hb
  split_ifs at ha <;> split_ifs at hb <;>
    simp_all <;> scalar_tac

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
  simp only [Result.ok.injEq, core.result.Result.Ok.injEq, Prod.mk.injEq,
    Option.some.injEq] at h
  obtain ⟨rfl, -⟩ := h
  refine ⟨by simp, ?_, ?_⟩
  · unfold is_offline; simp [OFFLINE_THRESHOLD]
  · unfold next_poll_interval
    simp [TIER1_FAILS, TIER2_FAILS, TIER3_FAILS, NORMAL_POLL_SECS]

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

/-- A `PreferEarlier` re-enqueue never *delays* a command already pending: if
`k` was due at `e`, after the enqueue it is due at some time `≤ e`. So
re-scheduling a Stop can only move it earlier, never later. -/
theorem enqueue_never_delays (q : Queue) (k : Kind) (time e : U64) (n : Queue)
    (hpre : slot q k = ok (some e)) (h : enqueue q k time false = ok n) :
    ∃ t, slot n k = ok (some t) ∧ t.val ≤ e.val := by
  unfold enqueue at h
  rw [H5iAppLib.bind_eq_ok] at h
  obtain ⟨o, ho, h⟩ := h
  rw [hpre] at ho
  simp only [Result.ok.injEq] at ho
  subst ho
  rw [H5iAppLib.bind_eq_ok] at h
  obtain ⟨v, hv, h⟩ := h
  refine ⟨v, slot_with_slot_eq q k (some v) n h, ?_⟩
  simp only [Bool.false_eq_true, if_false] at hv
  split at hv <;> (simp only [Result.ok.injEq] at hv; subst hv) <;> scalar_tac

/-- A popped event's slot is cleared: after `pop_due` returns a kind, that kind
is no longer pending, so the same scheduled event is never executed twice. -/
theorem pop_clears (q : Queue) (now : U64) (n : Queue) (k : Kind)
    (h : pop_due q now = ok (n, some k)) : slot n k = ok none := by
  unfold pop_due at h
  rw [H5iAppLib.bind_eq_ok] at h
  obtain ⟨o, -, h⟩ := h
  rw [H5iAppLib.bind_eq_ok] at h
  obtain ⟨o1, -, h⟩ := h
  cases o1 with
  | none => simp at h
  | some k' =>
    rw [H5iAppLib.bind_eq_ok] at h
    obtain ⟨q1, hq1, h⟩ := h
    simp only [Result.ok.injEq, Prod.mk.injEq, Option.some.injEq] at h
    obtain ⟨hn, hk⟩ := h
    rw [← hn, ← hk]
    exact slot_with_slot_eq q k' none q1 hq1

-- ------------------------------------------------------------------
-- Scheduler: user commands preempt polls at equal time (S).
-- ------------------------------------------------------------------

/-- `better` picks a user command over a poll at an equal execution time, and
never the other way. This is the tie-break the whole preemption guarantee rests
on. -/
theorem better_user_wins (t : U64) (u p : Kind)
    (hu : is_user u = ok true) (hp : is_user p = ok false) :
    better t u t p = ok true ∧ better t p t u = ok false := by
  unfold is_user at hu hp
  unfold better priority
  cases u <;> cases p <;> simp_all

/-- A representative preemption: a status poll and a Stop both due at the same
instant `t` — the Stop pops first. The `user_loses_priority` mutant (swapping
the tie-break) makes this pop the poll instead. -/
theorem user_preempts_poll (t now : U64) (ht : t.val ≤ now.val) :
    pop_due
      { status := some t, cook := none, recipes := none,
        start := none, stop := some t, next := none, fail_count := 0#u64 } now
      ⦃ res => res.2 = some Kind.UserStop ⦄ := by
  have hnd : ¬ (t > now) := by scalar_tac
  unfold pop_due kind_of soonest_due consider better priority with_slot
  simp only [hnd, if_false, gt_iff_lt]
  simp

-- ------------------------------------------------------------------
-- Reset classification precedence (S) and round-trip (C).
-- ------------------------------------------------------------------

/-- With RAM lost (invalid magic) the boot is always a cold boot, whatever the
other breadcrumbs say. -/
theorem coldboot_dominates (pa : Bool) (las : U32) (wt wf : Bool) :
    classify_reset false pa las wt wf = ok ResetReason.ColdBoot := by
  unfold classify_reset; simp

/-- A panic is attributed to the panic even when the watchdog also fired: the
root cause is never masked as a plain watchdog timeout. -/
theorem panic_never_masked (las : U32) (wt wf : Bool) :
    classify_reset true true las wt wf = ok ResetReason.Panic := by
  unfold classify_reset; simp

/-- A classified reason encodes to a `u32` and decodes back to itself. -/
theorem reset_u32_roundtrip (r : ResetReason) (v : U32) (h : reset_to_u32 r = ok v) :
    reset_from_u32 v = ok r := by
  unfold reset_to_u32 at h
  cases r <;> (simp only [Result.ok.injEq] at h; subst h) <;> (unfold reset_from_u32; rfl)

-- ------------------------------------------------------------------
-- Whole-run invariant: backoff stays bounded (S).
-- ------------------------------------------------------------------

/-- The reachability invariant: the next poll is always scheduled within 30 s
(and at least 1 s). Because it is a fact about `next_poll_interval` for any
failure count, it holds of every state. -/
def Inv (q : Queue) : Prop :=
  ∀ r, next_poll_interval q.fail_count = ok r → 1 ≤ r.val ∧ r.val ≤ 30

theorem inv_all (q : Queue) : Inv q := by
  intro r h
  exact H5iAppLib.post_of_ok (P := fun r => 1 ≤ r.val ∧ r.val ≤ 30)
    (backoff_bounded q.fail_count) h

/-- Committing a scheduler write set. -/
def applyW (s : Queue) : Option Queue → Queue
  | none => s
  | some n => n

/-- The actorless `transition`, wrapped with a trivial principal for the run
machinery. -/
def tr (_a : Unit) (s : Queue) (c : Command) :
    Result (core.result.Result ((Option Queue) × Reply) Error) :=
  transition s c

def INIT : Queue :=
  { status := none, cook := none, recipes := none, start := none, stop := none,
    next := none, fail_count := 0#u64 }

/-- In every reachable scheduler state — after any sequence of commands,
successful or refused — the next poll is scheduled within 30 s. -/
theorem inv_reachable {st : Queue} {evs : List (H5iAppLib.Event Unit Command Reply Error)}
    (h : H5iAppLib.Run tr (id : Queue → Queue) applyW INIT st evs) : Inv st :=
  H5iAppLib.Run.inv Inv (inv_all INIT) (fun _ s _ ws _ _ _ => inv_all (applyW s ws)) h

end anova_oven_kernel.Proofs
