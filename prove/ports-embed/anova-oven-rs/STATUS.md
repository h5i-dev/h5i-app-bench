# STATUS — anova-oven-rs (session k)

**Upstream:** `robdimsdale/anova-oven-rs` @ `43ac1a7`.
**State:** stable, gated, pushed. Proofs pass `h5i app check` (54 theorems, only
`propext`/`Classical.choice`/`Quot.sound`); 4/4 mutants caught; difftest green
against the real upstream `anova-oven-pico-core`.

Read `DEVIATIONS.md` first — this firmware is a display/remote-control **panel**,
not the oven's heater controller, which reshapes every property below.

## Theorem table (S / C / F)

| # | Theorem (`anova_oven_kernel.…`) | Class | Says |
|---|---|---|---|
| 1 | `Proofs.user_preempts_poll` | **S** | A Stop due at the same instant as a status poll pops first — a user command is never starved behind a same-instant poll. |
| 2 | `Proofs.better_user_wins` | **S** | The underlying tie-break: a user command (priority 0) beats a poll (priority 1) at equal time, never the reverse. |
| 3 | `Proofs.enqueue_keeps_others` | **S** | Scheduling one kind never evicts another — a scheduled Stop survives any later poll scheduling. |
| 4 | `Proofs.enqueue_present` | **S** | Scheduling a kind always leaves it pending (so, with no overflow, never silently dropped). |
| 5 | `Proofs.poll_ok_recovers` | **S** | A single successful poll clears `fail_count` → not offline, back to the 1 s poll rate. No recovery hysteresis. |
| 6 | `Proofs.backoff_bounded` | **S** | The next poll is always scheduled in 1–30 s; the backoff can never grow unbounded and abandon the server/oven. |
| 7 | `Proofs.backoff_monotone` | **S** | More consecutive failures never *shorten* the interval. |
| 8 | `Proofs.inv_reachable` | **S** | Whole-run: in every reachable scheduler state (any command sequence) the next poll is within 30 s. |
| 9 | `Proofs.panic_never_masked` | **S** | A panic is attributed to the panic even when the watchdog also fired — the crash-loop cause is never masked. |
| 10 | `Proofs.coldboot_dominates` | **S** | A lost-RAM boot is always classified `ColdBoot`, whatever the other breadcrumbs say. |
| 11 | `Proofs.transition_total` | **C** | No scheduler command panics, on any state (incl. the capped `fail_count` increment). |
| 12 | `Proofs.classify_total` | **C** | Reset classification never panics, for any breadcrumbs. |
| 13 | `Proofs.reset_u32_roundtrip` | **C** | A classified reason encodes to `u32` and decodes back to itself. |
| 14 | `ReadOnly.sound` | **C** | Every accepted `Peek` (health read) writes nothing, for all states. |

Supporting `@[step]` totality lemmas (`slot/with_slot/priority/is_user/enqueue/
better/consider/soonest_due/kind_of/pop_due/next_poll_interval/is_offline/
incr_sat/is_init_stage`) are foundation (C) and gated with the rest.

**Counts: S = 10, C = 4** (named), plus 15 gated foundation lemmas. 0 `sorry`,
0 abandoned, 0 axioms beyond the standard three.

### F — properties that are false or upstream observations (no advisory)

| # | Attempted property | Verdict |
|---|---|---|
| F1 | "No inbound write command succeeds without a bearer key." | **Unstatable / N/A.** The firmware exposes no inbound control route — only read-only `/health`+`/metrics`. Nothing to gate. |
| F2 | "The oven is commanded off (fail-safe) on comms error/disconnect." | **False.** The firmware *holds*: it issues no command on error; `Stop` is user-confirmed only (`state.rs` sole `api.stop()`). For a display/relay panel (not the heater controller) this mirrors Anova's own cloud; the oven owns thermal safety. Design observation, not a firmware bug. |
| F3 | "Diagnostics are not exposed to an unauthenticated LAN peer." | **False but benign.** `/health`+`/metrics` are unauthenticated by documented design ("Plain HTTP, no auth … behind the user's wifi"); read-only, leak counters + last panic-message string. Info disclosure on the LAN only, no state change → not an advisory. |
| F4 | "Pop order is fully determined by `(time, priority)`." | **False (benign).** Upstream `EventQueue` ties on equal `(time,priority)` are resolved by `swap_remove` vector order (nondeterministic). Harmless: same-priority events are interchangeable; user-vs-poll always differ in priority. Kernel's own tie-break is deterministic (`user_preempts_poll`). |

No finding reaches an exploitable-against-upstream bug, so **nothing was filed to
h5i-app-audit** (per the brief's "if not confirmed, do NOT write a finding").

## Benchmark measurements (this round's explicit goal)

1. **Fraction of upstream decision logic extracted.** The security/safety-relevant,
   Aeneas-subset decision logic I identified in scope — `scheduler.rs`
   (~100 code lines), `reset.rs` (~70), the backoff/offline tiers
   (`api_client.rs` ~15) ≈ **185 lines** — is ported essentially **1:1** (the
   `EventQueue` as its dedup-semantics model; `classify_reset`/`from_u32` nearly
   verbatim; backoff + `is_offline` verbatim), into a ~290-line kernel (the
   extra lines are the `Command`/`Reply`/`transition`/`apply` h5i-app wrapper and
   slot accessors). Of the firmware's *total* decision surface (add `fsm.rs`
   ~260, `state.rs`, `metrics.rs`, `persist*.rs`, `view_plan.rs`, `lcd_plan.rs`,
   `scheduler` ≈ 1000+ lines), the remainder is display/`ViewSpec` rendering,
   Prometheus/JSON serialization, and recipe/`OvenStatus` parsing — `alloc`/
   `String`/`f32`/`Arc`, out of the subset and render-only (not safety-critical).
   So: **~100% of the in-scope safety-relevant decision logic; a minority of the
   whole firmware, by design.**
2. **Specs attempted vs proved.** 14 named theorems + 15 foundation lemmas
   attempted, **all 29 proved, 0 `sorry`, 0 abandoned.** Two were *reshaped*
   (recorded, not dropped): (a) `incr_sat` saturates at `TIER3_FAILS` instead of
   `u64::MAX` — decision-equivalent, provably overflow-free (DEVIATIONS §3);
   (b) preemption proved as a representative case (`user_preempts_poll`) plus the
   general tie-break primitive (`better_user_wins`), with the full pop-ordering
   differentially tested against upstream — the fully-general fold-argmin lemma
   over 6 slots was judged not worth the proof weight for the marginal assurance.

   **Mutation coverage.** The 4 hand-authored, security-targeted mutants in
   `h5i-app.toml` are **4/4 caught** (`user_loses_priority`, `backoff_unbounded`,
   `poll_ok_keeps_fail`, `watchdog_masks_panic`). `h5i app mutate --auto`
   generated 48 mutants: **28 caught, 20 survived**. The survivors are, by
   construction, *functional-detail* mutations the security properties
   intentionally do **not** pin down — exact backoff tier boundaries
   (`next_poll_interval` `>=`→`>`: `backoff_bounded`/`backoff_monotone` stay true
   under a boundary shift), the dedup time chosen by `enqueue`/`better`
   (`enqueue_keeps_others`/`enqueue_present` fix *which slot*, not *which time*),
   the `is_offline`/`is_init_stage` thresholds, and the lower `classify_reset`
   arms (WatchdogTimeout/Forced/InitTimeout — only the Panic-precedence and
   ColdBoot-dominance arms carry S theorems). Per the campaign's "a handful of
   real security properties over many correspondence lemmas," these functional
   details are covered by the **exhaustive difftest** against the real upstream
   (classify_reset over every breadcrumb combination; backoff over fail_count
   0..40; 4000 scheduler sequences), not by extra correspondence theorems. The
   gate is `h5i app check` + the hand-authored mutants, not `--auto`.
3. **Bugs reproduced against real upstream.** **None.** The `difftest/` replays
   4000 random enqueue/pop sequences against the *real* `scheduler::EventQueue`,
   exhaustively checks `reset::classify_reset` over all boolean breadcrumbs ×10
   app-state values, and checks the backoff oracle + `fsm::OFFLINE_THRESHOLD` —
   **zero divergences**. (The construction surfaced upstream's tie
   nondeterminism, F4, which is benign.) No exploitable behavior found.
4. **RAM/flash footprint.** Not rebuilt for `thumbv6m` (no bare-metal toolchain
   installed here; `h5i-app-embedded` firmware-sizing skipped — see note). What
   is structural: the kernel is `#![no_std]`, **no alloc**, fixed-size — `Queue`
   is six `Option<u64>` + one `u64` (≈ 56–104 B depending on `Option` niche),
   `Command`/`Reply` are small enums; per-decision work is loop-free and
   constant. Upstream's own measured image (`docs/pico-ota.md` §2, 2026-05-26):
   **~542 KB flash** (27% of 2 MB), **~128 KB static RAM + 32 KB heap** of 264 KB;
   the inbound `picoserve` path uses 1 KB TCP buffers + 2 KB HTTP buffer, pool=1.
   h5i-app-embedded's model (caller-provided `rx`/`tx`, no heap) is strictly
   lighter than the alloc-using upstream path. Not independently re-measured.
5. **Target / HAL / Embassy compatibility.** RP2040 (Cortex-M0+),
   `thumbv6m-none-eabi`. Upstream pins embassy-executor 0.10 / embassy-rp 0.10 /
   embassy-net 0.9.1 / embassy-sync 0.8 / embassy-time 0.5, picoserve 0.19,
   cyw43 0.7, `embedded-io-async 0.7`. **h5i-app-embedded is `embedded-io-async`-
   generic (0.7), which matches upstream's pin and picoserve's own I/O shape**, so
   the shell's `Read`/`Write` bound fits this target as-is; it would replace
   picoserve on the inbound path and run the kernel via `respond`. The kernel/
   proofs are target-independent (pure `no_std`).

## Layout

```
kernel/    anova-oven-kernel: the no_std decision core (scheduler, poll-health, reset)
proofs/    Proofs.lean (S+C), ReadOnly.lean (C), generated/AnovaOvenKernel.lean
difftest/  host-side comparison vs the REAL anova-oven-pico-core@43ac1a7
h5i-app.toml  extract roots, gated theorems, 4 mutants (all caught)
DEVIATIONS.md
```

## Resumption notes

- `h5i app check` (gate) and `cargo test -p anova-oven-kernel` are the fast gates;
  `cargo test` in `difftest/` needs the pinned upstream checkout present.
- `difftest/Cargo.toml` hardcodes the absolute path to the read-only upstream
  checkout (not vendored, per the brief).
- Possible next strengthening: an `app/` wiring the kernel under
  `h5i-app-embedded`'s `Router`/`Api`/`respond` (mirroring the thermostat
  example) to exercise the kernel over real HTTP; a fully-general fold-argmin
  preemption lemma; a `thumbv6m` size measurement if a toolchain is added.
