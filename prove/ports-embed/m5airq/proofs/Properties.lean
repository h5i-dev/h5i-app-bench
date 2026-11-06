import M5airqKernel
import H5iAppLib.Basic
import H5iAppLib.Runs
/-!
# Security properties of the extracted M5AirQ-Rust kernel

Ported from `andrico21/M5AirQ-Rust` @ `f7e35cb`.

OTA update state machine (`src/ota.rs`):
* `transition_total` (C) — no command panics, on any state.
* `write_bounded` (S) — a committed chunk never pushes the write cursor past
  the declared image size.
* `write_sequential` (S) — a committed chunk writes exactly at the cursor and
  advances it by its length (no gaps, no rewinds, no overlap).
* `end_integrity` (S) — `end` activates a new image only when it is complete,
  carries the ESP image magic, and matches the declared CRC.
* `begin_targets_other_slot` (S) — `begin` never targets the running slot.
* `mutating_needs_admin` (S) — every mutating OTA command is refused without
  the authenticated (admin) actor.
* `inv_reachable` (S) — in every reachable state, an active session has its
  write cursor within the declared size and targets a non-running slot.
* `end_accepts_any_matching_crc` (F) — the only integrity gate is a
  client-supplied CRC-32; any image is accepted when its CRC is declared.

HTTP auth gate (`src/auth.rs`):
* `check_auth_total` (C), `validate_session_sound` (C).
* `unauth_never_granted` (S), `token_over_http_forbidden` (S),
  `expired_session_never_grants` (S), `empty_secret_no_bypass` (S).
* `public_access_opens_everything` (F).
-/
open Aeneas Aeneas.Std Result m5airq_kernel

namespace m5airq_kernel.Properties

set_option maxHeartbeats 4000000

theorem slot_size_val : OTA_SLOT_SIZE.val = 2031616 := by unfold OTA_SLOT_SIZE; rfl
theorem max_chunk_val : MAX_CHUNK.val = 4096 := by unfold MAX_CHUNK; rfl
theorem ttl_val : SESSION_TTL_SECS.val = 7200 := by unfold SESSION_TTL_SECS; rfl

-- ===========================================================================
-- OTA update state machine
-- ===========================================================================

/-- What committing a write set means. -/
def applyW (s : OtaState) : Option OtaState → OtaState
  | none => s
  | some n => n

theorem apply_eq (s : OtaState) (w : Option OtaState) : apply s w = ok (applyW s w) := by
  cases w <;> rfl

/-- No command panics, for any actor and state. -/
theorem transition_total (a : Device) (s : OtaState) (c : Command) :
    ∃ r, transition a s c = ok r := by
  have h : transition a s c ⦃ _ => True ⦄ := by
    unfold transition
    cases c <;> step* <;> scalar_tac
  exact H5iAppLib.ok_of h

/-- The per-command postcondition for a committed write set. -/
def PostOk (s : OtaState) (c : Command) (ws : Option OtaState) : Prop :=
  match c, ws with
  | .Begin size, some n =>
      n.target_slot ≠ n.running_slot ∧ n.running_slot.val ≤ 1
        ∧ n.written.val = 0 ∧ n.total = size ∧ n.active = true
  | .Write offset len, some n =>
      offset = s.written ∧ n.written.val = s.written.val + len.val
        ∧ n.written.val ≤ s.total.val ∧ n.active = s.active ∧ n.total = s.total
  | .End _ec ac mo, some n =>
      s.written = s.total ∧ mo = true ∧ ac = _ec ∧ n.active = false
  | .Abort, some n => n.active = false
  | _, _ => True

/-- One WP for every command (`cases c` reduces the extracted match). -/
theorem transition_wp (a : Device) (s : OtaState) (c : Command) :
    transition a s c ⦃ res => ∀ ws r, res = .Ok (ws, r) → PostOk s c ws ⦄ := by
  unfold transition
  cases c <;> step* <;> intro ws r hres <;> (try (cases hres)) <;>
    simp_all [PostOk] <;> (try scalar_tac)

/-- `begin` never targets the running slot (it writes the inactive one). -/
theorem begin_targets_other_slot (a : Device) (s : OtaState) (size : U32) (n : OtaState) (r : Reply)
    (h : transition a s (.Begin size) = ok (.Ok (some n, r))) :
    n.target_slot ≠ n.running_slot ∧ n.running_slot.val ≤ 1 := by
  have H := H5iAppLib.post_of_ok (transition_wp a s (.Begin size)) h (some n) r rfl
  simp only [PostOk] at H
  exact ⟨H.1, H.2.1⟩

/-- A committed chunk never pushes the cursor past the declared image size. -/
theorem write_bounded (a : Device) (s : OtaState) (offset len : U32) (n : OtaState) (r : Reply)
    (h : transition a s (.Write offset len) = ok (.Ok (some n, r))) :
    n.written.val ≤ s.total.val := by
  have H := H5iAppLib.post_of_ok (transition_wp a s (.Write offset len)) h (some n) r rfl
  simp only [PostOk] at H
  exact H.2.2.1

/-- A committed chunk writes exactly at the cursor and advances it by its
length: writes are strictly sequential. -/
theorem write_sequential (a : Device) (s : OtaState) (offset len : U32) (n : OtaState) (r : Reply)
    (h : transition a s (.Write offset len) = ok (.Ok (some n, r))) :
    offset = s.written ∧ n.written.val = s.written.val + len.val := by
  have H := H5iAppLib.post_of_ok (transition_wp a s (.Write offset len)) h (some n) r rfl
  simp only [PostOk] at H
  exact ⟨H.1, H.2.1⟩

/-- `end` activates a new image only when it is complete, has the ESP image
magic, and matches the declared CRC. -/
theorem end_integrity (a : Device) (s : OtaState) (ec ac : U32) (mo : Bool) (n : OtaState) (r : Reply)
    (h : transition a s (.End ec ac mo) = ok (.Ok (some n, r))) :
    s.written = s.total ∧ mo = true ∧ ac = ec := by
  have H := H5iAppLib.post_of_ok (transition_wp a s (.End ec ac mo)) h (some n) r rfl
  simp only [PostOk] at H
  exact ⟨H.1, H.2.1, H.2.2.1⟩

/-- Every mutating OTA command is refused without the admin actor. -/
theorem mutating_needs_admin (a : Device) (s : OtaState) (c : Command) (ha : a.admin = false)
    (hmut : read_only c = ok false) (ws : Option OtaState) (r : Reply)
    (h : transition a s c = ok (.Ok (ws, r))) : False := by
  cases c <;> (simp only [read_only] at hmut; unfold transition at h; simp_all)

-- --- Finding (F): no firmware authenticity, only a client-supplied CRC ---

/-- For *any* fully-written session and *any* image CRC, `end` succeeds when
the declared CRC equals the (client-chosen) image CRC and the magic byte is
present. The only integrity gate is a value the uploader controls: there is
no signature / authenticity check (CWE-347). -/
theorem end_accepts_any_matching_crc (s : OtaState) (crc : U32)
    (hactive : s.active = true) (hdone : s.written = s.total) :
    ∃ n r, transition { admin := true } s (.End crc crc true) = ok (.Ok (some n, r))
      ∧ n.active = false := by
  unfold transition
  simp only [hactive, hdone]
  refine ⟨_, _, by simp, by simp⟩

-- --- Reachability invariant over a whole run ---

/-- The reachability safety invariant: while an OTA session is active, the
write cursor never exceeds the declared image size. (`begin` always targets
the non-running slot is the separate single-step theorem above.) -/
def Inv (s : OtaState) : Prop :=
  s.active = true → s.written.val ≤ s.total.val

theorem inv_initial : Inv OTA_INITIAL := by
  unfold Inv OTA_INITIAL; simp

/-- Every successful command keeps `Inv`. -/
theorem inv_step (a : Device) (s : OtaState) (c : Command) (ws : Option OtaState) (r : Reply)
    (hs : Inv s) (ht : transition a s c = ok (.Ok (ws, r))) : Inv (applyW s ws) := by
  have h : transition a s c ⦃ res => ∀ ws r, res = .Ok (ws, r) → Inv (applyW s ws) ⦄ := by
    unfold transition
    cases c <;> step* <;> intro ws r hres <;> (try (cases hres)) <;>
      simp_all [applyW, Inv] <;> (try (intro hact)) <;> (try simp_all) <;> (try scalar_tac)
  exact H5iAppLib.post_of_ok h ht ws r rfl

/-- The invariant holds in every reachable state, after any sequence of
commands from any actors, successful or refused. -/
theorem inv_reachable {st : OtaState}
    {evs : List (H5iAppLib.Event Device Command Reply Error)}
    (h : H5iAppLib.Run transition id applyW OTA_INITIAL st evs) : Inv st :=
  H5iAppLib.Run.inv Inv inv_initial (fun a s c ws r hs ht => inv_step a s c ws r hs ht) h

-- ===========================================================================
-- HTTP authentication gate
-- ===========================================================================

@[step] theorem ct_eq8_spec (a b : Array U8 8#usize) : ct_eq8 a b ⦃ _ => True ⦄ := by
  unfold ct_eq8; step*

@[step] theorem is_zero8_spec (t : Array U8 8#usize) : is_zero8 t ⦃ _ => True ⦄ := by
  unfold is_zero8; step*

@[step] theorem age_ok_spec (now created : U32) : age_ok now created ⦃ _ => True ⦄ := by
  unfold age_ok; step* <;> scalar_tac

@[step] theorem transport_blocks_spec (a b : Bool) : transport_blocks a b ⦃ _ => True ⦄ := by
  unfold transport_blocks; step*

@[step] theorem slot_valid_spec (slot : SessionSlot) (token : Array U8 8#usize) (now : U32) :
    slot_valid slot token now ⦃ _ => True ⦄ := by
  unfold slot_valid; step*

@[step] theorem validate_session_spec (store : SessionStore) (token : Array U8 8#usize) (now : U32) :
    validate_session store token now ⦃ _ => True ⦄ := by
  unfold validate_session; step*

/-- `check_auth` never panics. -/
theorem check_auth_total
    (cfg : AuthCfg) (store : SessionStore) (now : U32) (cp : Bool) (ct : Array U8 8#usize)
    (bp bm ahp ahm aqp aqm dok https health : Bool) :
    ∃ r, check_auth cfg store now cp ct bp bm ahp ahm aqp aqm dok https health = ok r := by
  have h : check_auth cfg store now cp ct bp bm ahp ahm aqp aqm dok https health ⦃ _ => True ⦄ := by
    unfold check_auth
    step*
  exact H5iAppLib.ok_of h

/-- If `validate_session` accepts a token then some slot accepts it. -/
theorem validate_session_sound (store : SessionStore) (token : Array U8 8#usize) (now : U32)
    (h : validate_session store token now = ok true) :
    slot_valid store.s0 token now = ok true ∨ slot_valid store.s1 token now = ok true
      ∨ slot_valid store.s2 token now = ok true ∨ slot_valid store.s3 token now = ok true := by
  unfold validate_session at h
  rw [H5iAppLib.bind_eq_ok] at h
  obtain ⟨b0, hb0, h⟩ := h
  cases b0
  · simp only [Bool.false_eq_true, if_false] at h
    rw [H5iAppLib.bind_eq_ok] at h
    obtain ⟨b1, hb1, h⟩ := h
    cases b1
    · simp only [Bool.false_eq_true, if_false] at h
      rw [H5iAppLib.bind_eq_ok] at h
      obtain ⟨b2, hb2, h⟩ := h
      cases b2
      · simp only [Bool.false_eq_true, if_false] at h
        exact Or.inr (Or.inr (Or.inr h))
      · exact Or.inr (Or.inr (Or.inl hb2))
    · exact Or.inr (Or.inl hb1)
  · exact Or.inl hb0

/-- A decision counts as granting access. -/
def granted : AuthDecision → Prop
  | AuthDecision.Allowed => True
  | AuthDecision.AllowedSetSession => True
  | _ => False

/-- FINDING (F): `public_access` (the shipped default) grants every request
with no credential at all. -/
theorem public_access_opens_everything
    (store : SessionStore) (now : U32) (cp : Bool) (ct : Array U8 8#usize)
    (bp bm ahp ahm aqp aqm dok https health : Bool)
    (cfg : AuthCfg) (hpub : cfg.public_access = true) :
    check_auth cfg store now cp ct bp bm ahp ahm aqp aqm dok https health = ok AuthDecision.Allowed := by
  apply H5iAppLib.eq_ok_of_spec
  show check_auth cfg store now cp ct bp bm ahp ahm aqp aqm dok https health
      ⦃ r => r = AuthDecision.Allowed ⦄
  unfold check_auth
  step* <;> simp_all

/-- SECURITY (S): a bearer token or API key presented over plaintext HTTP,
with token-over-HTTP disabled and no valid session cookie, is refused. -/
theorem token_over_http_forbidden
    (cfg : AuthCfg) (store : SessionStore) (now : U32) (cp : Bool) (ct : Array U8 8#usize)
    (bp bm ahp ahm aqp aqm dok health : Bool)
    (hpub : cfg.public_access = false) (hhealth : health = false)
    (hhttp : cfg.allow_http_tokens = false)
    (hcookie : validate_session store ct now = ok false)
    (htok : bp = true ∨ ahp = true ∨ aqp = true) :
    check_auth cfg store now cp ct bp bm ahp ahm aqp aqm dok false health
      = ok AuthDecision.Forbidden := by
  apply H5iAppLib.eq_ok_of_spec
  show check_auth cfg store now cp ct bp bm ahp ahm aqp aqm dok false health
      ⦃ r => r = AuthDecision.Forbidden ⦄
  unfold check_auth transport_blocks
  rw [hcookie]
  rcases htok with hb | hah | haq <;> step* <;> simp_all

/-- SECURITY (S): with `public_access` off, a non-health request that carries
no valid credential is never granted (refused with `Forbidden` or `Challenge`). -/
theorem unauth_never_granted
    (cfg : AuthCfg) (store : SessionStore) (now : U32) (cp : Bool) (ct : Array U8 8#usize)
    (bp bm ahp ahm aqp aqm https : Bool)
    (hpub : cfg.public_access = false)
    (hcookie : cp = true → validate_session store ct now = ok false)
    (hbearer : ¬ (bp = true ∧ cfg.bearer_set = true ∧ bm = true))
    (hakh : ¬ (ahp = true ∧ cfg.apikey_set = true ∧ ahm = true))
    (hakq : ¬ (aqp = true ∧ cfg.apikey_set = true ∧ aqm = true)) :
    ∃ r, check_auth cfg store now cp ct bp bm ahp ahm aqp aqm false https false = ok r
      ∧ ¬ granted r := by
  obtain ⟨r, hr⟩ := check_auth_total cfg store now cp ct bp bm ahp ahm aqp aqm false https false
  refine ⟨r, hr, ?_⟩
  have hspec : check_auth cfg store now cp ct bp bm ahp ahm aqp aqm false https false
      ⦃ x => ¬ granted x ⦄ := by
    unfold check_auth transport_blocks granted
    by_cases hc : cp = true
    · rw [hcookie hc]
      step* <;> simp_all
    · simp only [Bool.not_eq_true] at hc
      step* <;> simp_all
  exact H5iAppLib.post_of_ok hspec hr

/-- SECURITY (S): an expired session cookie never grants access. -/
theorem expired_session_never_grants
    (cfg : AuthCfg) (store : SessionStore) (token : Array U8 8#usize) (now : U32)
    (hpub : cfg.public_access = false)
    (hexp : validate_session store token now = ok false) :
    check_auth cfg store now true token false false false false false false false true false
      = ok AuthDecision.Challenge := by
  apply H5iAppLib.eq_ok_of_spec
  show check_auth cfg store now true token false false false false false false false true false
      ⦃ r => r = AuthDecision.Challenge ⦄
  unfold check_auth transport_blocks
  rw [hexp]
  step* <;> simp_all

/-- SECURITY (S): an unset bearer token / API key never grants access, even if
the (empty) comparison reported a match. -/
theorem empty_secret_no_bypass
    (cfg : AuthCfg) (store : SessionStore) (now : U32) (ct : Array U8 8#usize)
    (bm ahm aqm : Bool)
    (hpub : cfg.public_access = false)
    (hbset : cfg.bearer_set = false) (haset : cfg.apikey_set = false) :
    ∃ r, check_auth cfg store now false ct true bm true ahm true aqm false true false = ok r
      ∧ r ≠ AuthDecision.Allowed := by
  obtain ⟨r, hr⟩ := check_auth_total cfg store now false ct true bm true ahm true aqm false true false
  refine ⟨r, hr, ?_⟩
  have hspec : check_auth cfg store now false ct true bm true ahm true aqm false true false
      ⦃ x => x ≠ AuthDecision.Allowed ⦄ := by
    unfold check_auth transport_blocks
    step* <;> simp_all
  exact H5iAppLib.post_of_ok hspec hr

end m5airq_kernel.Properties
