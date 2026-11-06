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
  There is no firmware authenticity (signature) check.

HTTP auth gate (`src/auth.rs`):
* `check_auth_total` (C), `validate_session_sound` (C).
* `unauth_never_granted` (S) — with `public_access` off and no valid
  credential, no request is granted.
* `token_over_http_forbidden` (S) — a bearer/API-key over plaintext HTTP is
  refused unless explicitly allowed.
* `expired_session_never_grants` (S) — an expired session cookie is rejected.
* `empty_secret_no_bypass` (S) — an unset bearer/API-key never grants.
* `public_access_opens_everything` (F) — with `public_access` on (the
  shipped default) every request, including mutating ones, is granted with no
  credential.
-/
open Aeneas Aeneas.Std Result m5airq_kernel

namespace m5airq_kernel.Properties

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
  obtain ⟨r, hr, -⟩ := (WP.spec_equiv_exists _ _).1 h
  exact ⟨r, hr⟩

/-- A committed chunk never pushes the cursor past the declared size. -/
theorem write_bounded (a : Device) (s : OtaState) (offset len : U32) (n : OtaState) (r : Reply)
    (h : transition a s (.Write offset len) = ok (.Ok (some n, r))) :
    n.written.val ≤ s.total.val := by
  unfold transition at h
  simp only at h
  split at h <;> try (simp_all; done)
  rename_i hadmin
  split at h <;> try (simp_all; done)
  split at h <;> try (simp_all; done)
  split at h <;> try (simp_all; done)
  split at h <;> try (simp_all; done)
  -- offset < written (retry) vs offset >= written
  split at h
  · -- offset < written
    split at h <;> try (simp_all; done)
    split at h <;> try (simp_all; done)
    split at h <;> try (simp_all; done)
    split at h <;> try (simp_all; done)
    rename_i hle
    rename_i heq _ _ _ _
    simp only [bind, Result.bind] at h
    split at h <;> simp_all
    rename_i hnw
    obtain ⟨_, _⟩ := h
    subst_vars
    scalar_tac
  · -- offset >= written
    split at h <;> try (simp_all; done)
    split at h <;> try (simp_all; done)
    rename_i hle
    simp only [bind, Result.bind] at h
    split at h <;> simp_all
    rename_i hnw
    obtain ⟨_, _⟩ := h
    subst_vars
    scalar_tac

/-- A committed chunk writes exactly at the cursor and advances it by its
length: writes are strictly sequential (upstream's `offset == OTA_WRITTEN`). -/
theorem write_sequential (a : Device) (s : OtaState) (offset len : U32) (n : OtaState) (r : Reply)
    (h : transition a s (.Write offset len) = ok (.Ok (some n, r))) :
    offset = s.written ∧ n.written.val = s.written.val + len.val := by
  have htot : ∃ rr, transition a s (.Write offset len) = ok rr := ⟨_, h⟩
  unfold transition at h
  simp only at h
  split at h <;> try (simp_all; done)
  split at h <;> try (simp_all; done)
  split at h <;> try (simp_all; done)
  split at h <;> try (simp_all; done)
  split at h <;> try (simp_all; done)
  split at h
  · split at h <;> try (simp_all; done)
    split at h <;> try (simp_all; done)
    split at h <;> try (simp_all; done)
    split at h <;> try (simp_all; done)
    simp only [bind, Result.bind] at h
    split at h <;> simp_all
    rename_i hnw
    obtain ⟨he, _⟩ := h
    subst_vars
    constructor
    · assumption
    · scalar_tac
  · split at h <;> try (simp_all; done)
    split at h <;> try (simp_all; done)
    simp only [bind, Result.bind] at h
    split at h <;> simp_all
    rename_i hnw
    obtain ⟨he, _⟩ := h
    subst_vars
    constructor
    · assumption
    · scalar_tac

/-- `end` activates a new image only when it is complete, has the ESP image
magic, and matches the declared CRC. -/
theorem end_integrity (a : Device) (s : OtaState) (ec ac : U32) (mo : Bool) (n : OtaState) (r : Reply)
    (h : transition a s (.End ec ac mo) = ok (.Ok (some n, r))) :
    s.written = s.total ∧ mo = true ∧ ac = ec := by
  unfold transition at h
  simp only at h
  split at h <;> try (simp_all; done)
  split at h <;> try (simp_all; done)
  split at h <;> try (simp_all; done)
  rename_i hneq
  split at h <;> try (simp_all; done)
  rename_i hmo
  split at h <;> try (simp_all; done)
  rename_i hcrc
  refine ⟨?_, hmo, ?_⟩
  · have := hneq; simp_all
  · have := hcrc; simp_all

/-- `begin` never targets the running slot (it writes the inactive one). -/
theorem begin_targets_other_slot (a : Device) (s : OtaState) (size : U32) (n : OtaState) (r : Reply)
    (h : transition a s (.Begin size) = ok (.Ok (some n, r))) :
    n.target_slot ≠ n.running_slot ∧ n.running_slot.val ≤ 1 := by
  unfold transition at h
  simp only at h
  split at h <;> try (simp_all; done)
  split at h <;> try (simp_all; done)
  split at h <;> try (simp_all; done)
  split at h <;> try (simp_all; done)
  split at h <;> try (simp_all; done)
  rename_i hru
  simp only [bind, Result.bind] at h
  split at h <;> simp_all
  rename_i tgt htgt
  obtain ⟨he, _⟩ := h
  subst_vars
  have hru' : s.running_slot.val ≤ 1 := by scalar_tac
  constructor
  · -- target = 1 - running, running <= 1, so they differ
    intro hc
    scalar_tac
  · scalar_tac

/-- Every mutating OTA command is refused without the admin actor. -/
theorem mutating_needs_admin (a : Device) (s : OtaState) (c : Command) (ha : a.admin = false)
    (hmut : read_only c = ok false) (n : OtaState) (r : Reply) (ws : Option OtaState)
    (h : transition a s c = ok (.Ok (ws, r))) : False := by
  cases c <;> (unfold transition at h; simp_all)

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
  exact ⟨_, _, by simp, by simp⟩

-- --- Reachability invariant over a whole run ---

/-- The safety invariant: while an OTA session is active, the write cursor is
within the declared size and the target slot is not the running slot. -/
def Inv (s : OtaState) : Prop :=
  s.active = true →
    (s.written.val ≤ s.total.val ∧ s.target_slot ≠ s.running_slot ∧ s.running_slot.val ≤ 1)

theorem inv_initial : Inv OTA_INITIAL := by
  unfold Inv OTA_INITIAL; simp

/-- Every successful command keeps `Inv`. -/
theorem inv_step (a : Device) (s : OtaState) (c : Command) (ws : Option OtaState) (r : Reply)
    (hs : Inv s) (ht : transition a s c = ok (.Ok (ws, r))) : Inv (applyW s ws) := by
  cases c <;> unfold transition at ht <;> simp only at ht
  · -- Begin
    split at ht <;> try (simp_all [applyW, Inv]; done)
    split at ht <;> try (simp_all [applyW, Inv]; done)
    split at ht <;> try (simp_all [applyW, Inv]; done)
    split at ht <;> try (simp_all [applyW, Inv]; done)
    split at ht <;> try (simp_all [applyW, Inv]; done)
    simp only [bind, Result.bind] at ht
    split at ht <;> simp_all
    rename_i size hru tgt htgt
    obtain ⟨he, _⟩ := ht
    subst_vars
    intro _
    refine ⟨by scalar_tac, by intro hc; scalar_tac, by scalar_tac⟩
  · -- Write
    split at ht <;> try (simp_all [applyW, Inv]; done)
    split at ht <;> try (simp_all [applyW, Inv]; done)
    split at ht <;> try (simp_all [applyW, Inv]; done)
    split at ht <;> try (simp_all [applyW, Inv]; done)
    split at ht <;> try (simp_all [applyW, Inv]; done)
    split at ht
    · -- offset < written
      split at ht <;> try (simp_all [applyW, Inv]; done)
      split at ht <;> try (simp_all [applyW, Inv]; done)
      split at ht <;> try (simp_all [applyW, Inv]; done)
      split at ht <;> try (simp_all [applyW, Inv]; done)
      simp only [bind, Result.bind] at ht
      split at ht <;> simp_all
      rename_i hactive _ _ _ _ _ nw hnw
      obtain ⟨he, _⟩ := ht
      subst_vars
      intro hact
      obtain ⟨_, ht2, ht3⟩ := hs hact
      refine ⟨by scalar_tac, by simpa using ht2, by simpa using ht3⟩
    · -- offset >= written
      split at ht <;> try (simp_all [applyW, Inv]; done)
      split at ht <;> try (simp_all [applyW, Inv]; done)
      simp only [bind, Result.bind] at ht
      split at ht <;> simp_all
      rename_i hactive _ _ _ nw hnw
      obtain ⟨he, _⟩ := ht
      subst_vars
      intro hact
      obtain ⟨_, ht2, ht3⟩ := hs hact
      refine ⟨by scalar_tac, by simpa using ht2, by simpa using ht3⟩
  · -- End
    split at ht <;> try (simp_all [applyW, Inv]; done)
    split at ht <;> try (simp_all [applyW, Inv]; done)
    split at ht <;> try (simp_all [applyW, Inv]; done)
    split at ht <;> try (simp_all [applyW, Inv]; done)
    split at ht <;> simp_all [applyW, Inv]
  · -- Abort
    split at ht <;> try (simp_all [applyW, Inv]; done)
    split at ht <;> simp_all [applyW, Inv]
  · -- Status
    simp_all [applyW, Inv]

/-- The invariant holds in every reachable state, after any sequence of
commands from any actors, successful or refused. -/
theorem inv_reachable {st : OtaState}
    {evs : List (H5iAppLib.Event Device Command Reply Error)}
    (h : H5iAppLib.Run transition id applyW OTA_INITIAL st evs) : Inv st :=
  H5iAppLib.Run.inv Inv inv_initial (fun a s c ws r hs ht => inv_step a s c ws r hs ht) h

-- ===========================================================================
-- HTTP authentication gate
-- ===========================================================================

/-- `check_auth` never panics. -/
theorem check_auth_total
    (cfg : AuthCfg) (store : SessionStore) (now : U32) (cp : Bool) (ct : Array U8 8#usize)
    (bp bm ahp ahm aqp aqm dok https health : Bool) :
    ∃ r, check_auth cfg store now cp ct bp bm ahp ahm aqp aqm dok https health = ok r := by
  have h : check_auth cfg store now cp ct bp bm ahp ahm aqp aqm dok https health ⦃ _ => True ⦄ := by
    unfold check_auth
    step*
  obtain ⟨r, hr, -⟩ := (WP.spec_equiv_exists _ _).1 h
  exact ⟨r, hr⟩

/-- If `validate_session` accepts a token then some slot holds exactly that
non-zero token and is within its TTL. -/
theorem validate_session_sound (store : SessionStore) (token : Array U8 8#usize) (now : U32)
    (h : validate_session store token now = ok true) :
    slot_valid store.s0 token now = ok true ∨ slot_valid store.s1 token now = ok true
      ∨ slot_valid store.s2 token now = ok true ∨ slot_valid store.s3 token now = ok true := by
  unfold validate_session at h
  simp only [bind, Result.bind] at h
  split at h <;> rename_i h0
  · exact Or.inl h0
  · split at h <;> rename_i h1
    · exact Or.inr (Or.inl h1)
    · split at h <;> rename_i h2
      · exact Or.inr (Or.inr (Or.inl h2))
      · exact Or.inr (Or.inr (Or.inr h))

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
  unfold check_auth
  simp [hpub]

/-- SECURITY (S): a bearer token or API key presented over plaintext HTTP,
with token-over-HTTP disabled and no valid session cookie, is refused. -/
theorem token_over_http_forbidden
    (cfg : AuthCfg) (store : SessionStore) (now : U32) (cp : Bool) (ct : Array U8 8#usize)
    (bp bm ahp ahm aqp aqm dok health : Bool)
    (hpub : cfg.public_access = false) (hhealth : health = false)
    (hhttp : cfg.allow_http_tokens = false)
    (hcookie : cp = true → validate_session store ct now = ok false)
    (htok : bp = true ∨ ahp = true ∨ aqp = true) :
    check_auth cfg store now cp ct bp bm ahp ahm aqp aqm dok false health
      = ok AuthDecision.Forbidden := by
  unfold check_auth
  simp only [hpub, hhealth, hhttp, Bool.false_eq_true, if_false, if_true,
             Bool.not_false, Bool.not_true, Bool.and_true]
  -- Resolve the cookie branch.
  by_cases hc : cp = true
  · simp only [hc, if_true]
    rw [hcookie hc]
    simp only [bind, Result.bind]
    simp only [Bool.false_eq_true, if_false]
    rcases htok with hb | hah | haq
    · simp [hb]
    · by_cases hb : bp = true
      · simp [hb]
      · simp only [Bool.not_eq_true] at hb; simp [hb, hah]
    · by_cases hb : bp = true
      · simp [hb]
      · simp only [Bool.not_eq_true] at hb
        by_cases hah2 : ahp = true
        · simp [hb, hah2]
        · simp only [Bool.not_eq_true] at hah2; simp [hb, hah2, haq]
  · simp only [Bool.not_eq_true] at hc
    simp only [hc, Bool.false_eq_true, if_false]
    rcases htok with hb | hah | haq
    · simp [hb]
    · by_cases hb : bp = true
      · simp [hb]
      · simp only [Bool.not_eq_true] at hb; simp [hb, hah]
    · by_cases hb : bp = true
      · simp [hb]
      · simp only [Bool.not_eq_true] at hb
        by_cases hah2 : ahp = true
        · simp [hb, hah2]
        · simp only [Bool.not_eq_true] at hah2; simp [hb, hah2, haq]

/-- SECURITY (S): with `public_access` off, a non-health request that carries
no valid credential (invalid/absent cookie, no matching token, no Digest) is
never granted — it is refused with `Forbidden` or `Challenge`. -/
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
  have key :
      check_auth cfg store now cp ct bp bm ahp ahm aqp aqm false https false = ok AuthDecision.Forbidden
      ∨ check_auth cfg store now cp ct bp bm ahp ahm aqp aqm false https false = ok AuthDecision.Challenge := by
    unfold check_auth
    simp only [hpub, Bool.false_eq_true, if_false]
    by_cases hcp : cp = true
    · simp only [hcp, if_true, hcookie hcp, bind, Result.bind, Bool.false_eq_true, if_false]
      by_cases hbp : bp = true <;> by_cases hahp : ahp = true <;> by_cases haqp : aqp = true <;>
        by_cases hhs : https = true <;> by_cases hht : cfg.allow_http_tokens = true <;>
        by_cases hbs : cfg.bearer_set = true <;> by_cases has : cfg.apikey_set = true <;>
        simp_all [granted]
    · simp only [Bool.not_eq_true] at hcp
      simp only [hcp, Bool.false_eq_true, if_false]
      by_cases hbp : bp = true <;> by_cases hahp : ahp = true <;> by_cases haqp : aqp = true <;>
        by_cases hhs : https = true <;> by_cases hht : cfg.allow_http_tokens = true <;>
        by_cases hbs : cfg.bearer_set = true <;> by_cases has : cfg.apikey_set = true <;>
        simp_all [granted]
  rcases key with h | h
  · exact ⟨_, h, by simp [granted]⟩
  · exact ⟨_, h, by simp [granted]⟩

/-- SECURITY (S): an expired session cookie never grants access (its only
matching slot is past its TTL). -/
theorem expired_session_never_grants
    (cfg : AuthCfg) (store : SessionStore) (token : Array U8 8#usize) (now : U32)
    (hpub : cfg.public_access = false)
    (hexp : validate_session store token now = ok false) :
    check_auth cfg store now true token false false false false false false false true false
      = ok AuthDecision.Challenge := by
  unfold check_auth
  simp only [hpub, Bool.false_eq_true, if_false, if_true]
  rw [hexp]
  simp

/-- SECURITY (S): an unset bearer token / API key never grants access, even
if the (empty) comparison reported a match. -/
theorem empty_secret_no_bypass
    (cfg : AuthCfg) (store : SessionStore) (now : U32) (ct : Array U8 8#usize)
    (bm ahm aqm : Bool)
    (hpub : cfg.public_access = false)
    (hbset : cfg.bearer_set = false) (haset : cfg.apikey_set = false) :
    ∃ r, check_auth cfg store now false ct true bm true ahm true aqm false true false = ok r
      ∧ r ≠ AuthDecision.Allowed := by
  unfold check_auth
  simp [hpub, hbset, haset]

end m5airq_kernel.Properties
