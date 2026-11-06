# DEVIATIONS — anova-oven-rs

**Upstream:** `robdimsdale/anova-oven-rs` @ `43ac1a7` (pinned, read-only at
`/mnt/scratch/oss-sec/upstream-embed/anova-oven-rs`). Cited by hash, not vendored.

**Framework:** `picoserve` 0.19 dependent on RP2040 (Pico W) / Embassy. The
verified shell here is `h5i-app-embedded` + `h5i-app-h1`, not picoserve itself.

## What this firmware actually is (and what it is not)

The brief's starting hypotheses for this project (temperature-setpoint bounds, a
heater left on across an error transition, OTA acceptance) assumed the Pico
*controls the oven's heating element*. It does not. After reading the code:

- `crates/anova-oven-pico` is a **display + remote-control panel**. The RP2040
  never drives a heating element, relay, or any actuator. It renders the oven's
  state on a small display and can send three coarse commands
  (`Start{recipe_id}`, `Stop`, `NextStage`) to an intermediary HTTP server
  (`ANOVA_SERVER_URL`), which relays to the oven. There is **no
  temperature-setpoint path in the firmware at all** — setpoints live in `Stage`
  records the firmware fetches read-only for display. (Confirmed: the only
  outbound command enum is `api_client.rs::ApiCommand`, carrying only a
  `recipe_id` string.)
- The only **inbound** network surface is `picoserve` serving two **read-only,
  unauthenticated** GET routes — `/health` and `/metrics` (`health.rs`). No
  inbound control route exists; `picoserve` is referenced from exactly one file.
- **OTA** (`docs/pico-ota.md`) and **transport security** (`docs/pico-transport-security.md`)
  are both explicitly *"Investigation only. No code written, nothing committed."*
  There is no OTA state machine or TLS/Noise code to verify.

So the verifiable, security/safety-relevant **decision logic** in this firmware
is the autonomous control-plane in `anova-oven-pico-core`:

| Area | Upstream source | In kernel |
|---|---|---|
| Command/poll scheduler (dedup-by-kind, `(time,priority)` order, user-command preemption) | `scheduler.rs` (`EventQueue`) | `Queue`, `enqueue`, `consider`, `soonest_due`, `kind_of`, `pop_due` |
| Poll-health backoff + offline flag | `api_client.rs:29-34,161-166`; `fsm.rs::OFFLINE_THRESHOLD/is_offline` | `next_poll_interval`, `is_offline`, `incr_sat` |
| Reset/crash-loop attribution | `reset.rs` (`classify_reset`, `from_u32`) | `classify_reset`, `reset_from_u32`, `reset_to_u32`, `is_init_stage` |

## Deviations from a literal port

1. **`EventQueue` modelled as a 6-slot record, not a `heapless::Vec<_,16>`.**
   Upstream dedups by kind (at most one entry per `EventKind`) and relies on
   "5 distinct kinds < 16 capacity ⇒ overflow impossible" (its own comment).
   The kernel represents the queue as one optional time-slot per kind
   (`status/cook/recipes/start/stop/next`). This is faithful to the *semantics*
   (a kind→time map with dedup) and makes overflow **structurally impossible**
   — the `QueueOverflow` case cannot arise, which is exactly the property
   upstream argues informally. The `difftest/` replays 4000 random
   enqueue/pop sequences against the **real** `EventQueue` and asserts (a) it
   never returns `QueueOverflow`, and (b) with distinct times, every pop takes
   the same kind at the same `(time, priority)`.

2. **Equal-`(time,priority)` tie-break is not reproduced.** Upstream's
   `soonest_index` uses `min_by` over a `Vec` scrambled by `swap_remove`, so the
   choice among entries with *identical* time and priority is unspecified (an
   observation, not a bug — same-priority events are interchangeable; a
   user command vs a poll always differ in priority, so a Stop still wins). The
   kernel's tie-break is deterministic (fixed slot scan order), proved by
   `user_preempts_poll`. The difftest excludes exact ties by using distinct
   enqueue times.

3. **`fail_count` capped at `TIER3_FAILS` (15), not `saturating_add` to
   `u64::MAX`.** Past the top backoff tier the exact count changes **no
   decision** (`next_poll_interval` and `is_offline` are already saturated), so
   the kernel stops counting at the tier. This makes the `+ 1` provably
   overflow-free and keeps the state finite. The difftest confirms
   `next_poll_interval` and the offline flag agree with upstream for all counts.

4. **Time is `u64` whole seconds, not `embassy_time::Instant`.** `Instant`
   is outside the Aeneas subset; only the monotonic ordering of ticks matters
   for the scheduling decisions, and the difftest bridges via
   `Instant::from_ticks`.

5. **Reset classification only does the pure decision.** The watchdog-reason
   MMIO read and the persist-region access stay in the (trusted) firmware bin,
   exactly as upstream splits them (`reset.rs` doc: "the MMIO read … stay in the
   bin; this module does only the classification").

6. **`kind_of` split out of `soonest_due`** (proof engineering): Aeneas reduces
   a tuple-pattern `let` in a match arm cleanly when the scrutinee is a function
   parameter but not a monadic-bind local, so the fold (`soonest_due`) returns
   the full `Option<(u64,Kind)>` and a parameter-taking `kind_of` drops the time.

## Trusted / out of scope

- **`h5i-app-embedded` / `h5i-app-h1`** shell, router, parser: trusted+tested
  upstream of this port (see their READMEs). picoserve itself is not run.
- **`health.rs` handlers, `metrics::render`, `persist` encoding/ring**: the
  `/health`+`/metrics` handlers are read-only and unauthenticated by documented
  design; `render` uses `heapless::String` and is bounded by upstream's own
  `worst_case_fits_in_buffer` test; persist uses chip MMIO. Not ported.
- **`fsm.rs` view/`ViewSpec` logic, recipe/stage/`OvenStatus` parsing**: display
  and JSON (de)serialization using `alloc`/`String`/`f32`/`Arc`; not in the
  Aeneas subset and not safety-relevant (render-only).
- **OTA / transport security**: no code exists upstream (investigation docs).

## Findings (see STATUS.md "F" rows) — none reach a standalone advisory

- Unauthenticated `/health`+`/metrics` on the LAN leak diagnostics (panic
  message, counters). Documented upstream design ("Plain HTTP, no auth … behind
  the user's wifi"); read-only, changes no state. Not exploitable beyond LAN
  info disclosure → not an advisory.
- On comms error/disconnect the firmware **holds** (issues no command; Stop is
  user-confirmed only). This is the brief's fail-safe question: for a
  display/relay panel (not the heater controller) holding mirrors Anova's own
  cloud, and the oven owns thermal safety. A design observation, not a firmware
  bug.
- Unescaped `recipe_id` interpolated into `/api/start` JSON (`api.rs`): ids are
  server-assigned, not attacker-controlled. Latent, unreachable.
