import Verified.LoginGate
import Verified.Guards
import Verified.Tokens
import Verified.IpAlloc
import Verified.Ranges
/-!
# defguard: the security properties

Each theorem is about the extracted kernel and is stated with the
definitions of `Spec.lean`. The proofs are in `Verified/`.
-/
open Aeneas Aeneas.Std Result defguard_kernel defguard_kernel.Spec
open H5iAppLib

namespace defguard_kernel.Properties

/-! ## Login lockout (`auth/failed_login.rs`, `handlers/auth.rs` `authenticate`) -/

/-- A name with five or more recorded failures, the last at most five
minutes ago, is refused without looking at the password. -/
theorem locked_name_blocked (map m : alloc.vec.Vec lockout.FailedLogin) (us : alloc.vec.Vec lockout.Account)
    (input : Slice U8) (pw : alloc.vec.Vec Bool) (now : I64) (out : lockout.LoginOutcome)
    (hl : Locked map.val input.val now.val) (h : lockout.authenticate map us input pw now = ok (m, out)) :
    out = .Blocked :=
  Verified.locked_name_blocked hl h

/-- A login succeeds only when the password verifies and the name is not
locked out. -/
theorem verified_needs_password (map m : alloc.vec.Vec lockout.FailedLogin) (us : alloc.vec.Vec lockout.Account)
    (input : Slice U8) (pw : alloc.vec.Vec Bool) (now : I64) (i : Usize)
    (h : lockout.authenticate map us input pw now = ok (m, .Verified i)) :
    ¬ Locked map.val input.val now.val ∧ ∃ hi : i.val < pw.val.length, pw.val[i.val] = true :=
  Verified.verified_needs_password h

/-- A wrong password typed with a username is recorded under that name. -/
theorem failure_recorded (map m : alloc.vec.Vec lockout.FailedLogin) (us : alloc.vec.Vec lockout.Account)
    (input : Slice U8) (pw : alloc.vec.Vec Bool) (now : I64)
    (hu : IsUsername us.val input.val) (h : lockout.authenticate map us input pw now = ok (m, .WrongPassword)) :
    ∃ f, entryFor m.val input.val = some f ∧ f.last_attempt = now :=
  Verified.failure_recorded hu h

/-- The fifth wrong password within the window locks the username out for
the following five minutes. -/
theorem fifth_failure_locks (map m : alloc.vec.Vec lockout.FailedLogin) (us : alloc.vec.Vec lockout.Account)
    (input : Slice U8) (pw : alloc.vec.Vec Bool) (now : I64) (f : lockout.FailedLogin)
    (hu : IsUsername us.val input.val) (he : entryFor map.val input.val = some f) (h4 : f.attempt_count.val = 4)
    (hr : ¬ Verified.ResetCond f now.val)
    (h : lockout.authenticate map us input pw now = ok (m, .WrongPassword)) (later : Int)
    (hlater : later - now.val ≤ 300000000000) :
    Locked m.val input.val later :=
  Verified.fifth_failure_locks hu he h4 hr h later hlater

/-- Finding: logging in with the account's email address (in any letter
case) is never locked out. The tracker is checked under the typed name but
failures are recorded under the username, so the typed email never gains an
entry and every guess reaches the password check. -/
theorem email_login_never_locked (map m : alloc.vec.Vec lockout.FailedLogin) (us : alloc.vec.Vec lockout.Account)
    (input : Slice U8) (pw : alloc.vec.Vec Bool) (now : I64) (out : lockout.LoginOutcome)
    (hnone : entryFor map.val input.val = none) (hnu : ¬ IsUsername us.val input.val)
    (hem : ∃ a ∈ us.val, LowerEq a.email.val input.val)
    (h : lockout.authenticate map us input pw now = ok (m, out)) :
    out ≠ .Blocked ∧ entryFor m.val input.val = none :=
  Verified.email_login_never_locked hnone hnu hem h

/-! ## API guards (`auth/mod.rs`, `handlers/mod.rs`) -/

/-- `SessionInfo` stands on a stored, unexpired session (or an API token of
an active user, with a business licence); an MFA user's session must be
MFA-verified; API tokens work only for admins; `is_admin` is membership of
an admin group. -/
theorem session_info_sound (lic : Bool) (cred : auth.Credential) (us : alloc.vec.Vec auth.User)
    (ag : alloc.vec.Vec (alloc.vec.Vec U8)) (now : I64) (info : auth.Info)
    (h : auth.session_info lic cred us ag now = ok (.Ok info)) :
    Presents lic cred now.val info.session ∧ info.user ∈ us.val ∧ info.user.id = info.session.user_id ∧
    (info.is_admin = true ↔ IsAdmin info.user ag.val) ∧
    (info.user.mfa_enabled = true →
      info.session.state = .MultiFactorVerified ∨ info.session.state = .ApiTokenVerified) ∧
    (info.session.state = .ApiTokenVerified → IsAdmin info.user ag.val) :=
  Verified.session_info_ok h

/-- An expired session cookie authorizes nothing. -/
theorem expired_session_rejected (lic : Bool) (row : auth.Session) (us : alloc.vec.Vec auth.User)
    (ag : alloc.vec.Vec (alloc.vec.Vec U8)) (now : I64) (info : auth.Info)
    (hexp : row.expires.val < now.val) :
    auth.session_info lic (.Cookie (some row)) us ag now ≠ ok (.Ok info) := by
  intro h
  have := (Verified.session_info_ok h).1
  simp only [Presents] at this
  omega

/-- `AdminRole` admits only an active member of an admin group. -/
theorem admin_role_sound (lic : Bool) (cred : auth.Credential) (us : alloc.vec.Vec auth.User)
    (ag : alloc.vec.Vec (alloc.vec.Vec U8)) (now : I64) (info : auth.Info)
    (h : auth.admin_role lic cred us ag now = ok (.Ok info)) :
    info.user.is_active = true ∧ IsAdmin info.user ag.val ∧ Presents lic cred now.val info.session :=
  let h' := Verified.admin_role_ok h
  ⟨h'.2.1, h'.2.2, (Verified.session_info_ok h'.1).1⟩

/-- `user_for_admin_or_self` hands out another user's account only to an admin. -/
theorem other_user_needs_admin (info : auth.Info) (us : alloc.vec.Vec auth.User) (n : Slice U8) (u : auth.User)
    (h : auth.user_for_admin_or_self info us n = ok (.Ok u)) (hother : u.username.val ≠ info.user.username.val) :
    info.is_admin = true := by
  obtain ⟨_, hn, hor⟩ := Verified.user_for_admin_or_self_ok h
  rcases hor with e | e
  · exact absurd (hn.trans e) hother
  · exact e

/-- `device_for_admin_or_self` hands out another user's device only to an admin. -/
theorem other_device_needs_admin (info : auth.Info) (ds : alloc.vec.Vec auth.Device) (id : U64) (d : auth.Device)
    (h : auth.device_for_admin_or_self info ds id = ok (.Ok d)) (hother : d.user_id ≠ info.user.id) :
    info.is_admin = true ∧ d.id = id := by
  obtain ⟨_, hid, hor⟩ := Verified.device_for_admin_or_self_ok h
  rcases hor with e | e
  · exact absurd e hother
  · exact ⟨e, hid⟩

/-! ## Enrollment tokens (`db/models/enrollment.rs`, `servers/enrollment.rs`) -/

/-- An expired token never opens an enrollment session. -/
theorem expired_token_never_starts (t t' : token.Token) (now timeout : I64)
    (r : core.result.Result I64 token.TokenError)
    (hexp : t.expires_at.val < now.val) (h : token.start_session t now timeout = ok (t', r)) :
    t' = t ∧ r = .Err .TokenExpired :=
  Verified.expired_never_starts hexp h

/-- A token is used once: its first use is recorded and never moved, the
deadline is the first use plus the timeout, and a repeat start is accepted
only before that deadline. -/
theorem token_single_session (t t' : token.Token) (now timeout d : I64)
    (h : token.start_session t now timeout = ok (t', .Ok d)) :
    now.val ≤ t.expires_at.val ∧ t'.user_id = t.user_id ∧
    ∃ u, t'.used_at = some u ∧ d.val = u.val + timeout.val ∧
      (t.used_at = none → u = now) ∧ (t.used_at ≠ none → t.used_at = some u ∧ now.val < u.val + timeout.val) := by
  obtain ⟨h1, h2, _, _, h5⟩ := Verified.start_session_ok h
  exact ⟨h1, h2, h5⟩

/-- An enrollment request is served only on an enrollment token whose
session is open, and acts for the token's own user. -/
theorem enrollment_session_sound (t : token.Token) (now timeout : I64) (uid : U64)
    (h : token.validate_session t now timeout = ok (.Ok uid)) :
    t.enrollment_type = true ∧ SessionOpen t now.val timeout.val ∧ uid = t.user_id :=
  Verified.validate_session_ok h

/-- Finding: the enrollment session outlives the token. `validate_session`
never reads `expires_at`, so a session opened just before the token expired
is served until `used_at + timeout`. -/
theorem session_outlives_token (t : token.Token) (now timeout u : I64)
    (he : t.enrollment_type = true) (hu : t.used_at = some u) (hexp : t.expires_at.val < now.val)
    (hin : now.val < u.val + timeout.val) (hb : u.val + timeout.val ≤ I64.max) (hb' : I64.min ≤ u.val + timeout.val) :
    token.validate_session t now timeout = ok (.Ok t.user_id) :=
  Verified.session_outlives_token he hu hin hb hb'

/-! ## Device addresses (`db/models/device.rs` `assign_next_network_ip`) -/

/-- A fresh assignment gives each subnet of the location an address inside
it that is not its network, broadcast or gateway address and is neither
used nor reserved, and it is the lowest such address. -/
theorem fresh_addresses_valid (nets : alloc.vec.Vec ipalloc.Net) (used reserved ips : alloc.vec.Vec ipalloc.Ip)
    (h : ipalloc.assign_next_network_ip nets used reserved none = ok (.Ok ips)) :
    ips.val.length = nets.val.length ∧ ∀ k (h1 : k < nets.val.length) (h2 : k < ips.val.length),
      Assignable nets.val[k] used.val reserved.val ips.val[k] ∧
      ∀ ip', Assignable nets.val[k] used.val reserved.val ip' → ips.val[k].bits.val ≤ ip'.bits.val :=
  Verified.fresh_addresses_valid h

/-- `NetworkFull` is reported only for a subnet with no assignable address. -/
theorem full_only_when_full (nets : alloc.vec.Vec ipalloc.Net) (used reserved : alloc.vec.Vec ipalloc.Ip) (k : Usize)
    (h : ipalloc.assign_next_network_ip nets used reserved none = ok (.Err k)) :
    ∃ hk : k.val < nets.val.length, ∀ ip, ¬ Assignable nets.val[k.val] used.val reserved.val ip :=
  Verified.full_only_when_full h

/-- Finding: on reassignment, an address the device already has inside a
subnet is kept without any of the checks a fresh address gets. -/
theorem kept_address_unchecked (nets : alloc.vec.Vec ipalloc.Net) (used reserved c ips : alloc.vec.Vec ipalloc.Ip)
    (ip : ipalloc.Ip) (k : Nat) (h1 : k < nets.val.length) (h2 : k < ips.val.length)
    (h : ipalloc.assign_next_network_ip nets used reserved (some c) = ok (.Ok ips))
    (hc : c.val.find? (fun x => decide (InNet nets.val[k] x)) = some ip) :
    ips.val[k] = ip :=
  Verified.kept_address_unchecked k h1 h2 h hc

/-- Finding, concretely: a device whose address is now the subnet's gateway
keeps it, an address no fresh assignment would give. -/
theorem keeps_gateway_address (nets : alloc.vec.Vec ipalloc.Net) (used reserved c ips : alloc.vec.Vec ipalloc.Ip)
    (k : Nat) (h1 : k < nets.val.length) (h2 : k < ips.val.length)
    (hc : c.val = [⟨nets.val[k].v4, nets.val[k].ip⟩])
    (h : ipalloc.assign_next_network_ip nets used reserved (some c) = ok (.Ok ips)) :
    ips.val[k] = ⟨nets.val[k].v4, nets.val[k].ip⟩ ∧ ¬ Assignable nets.val[k] used.val reserved.val ips.val[k] :=
  Verified.keeps_gateway_address k h1 h2 hc h

/-! ## Firewall ranges (`enterprise/utils.rs` `merge_ranges`) -/

/-- Merging the port or address ranges of a firewall rule neither opens nor
closes any value: the result covers exactly what the input covers. -/
theorem merge_ranges_exact (input out : alloc.vec.Vec ranges.Range) (max : U128)
    (hwf : ∀ r ∈ input.val, r.start.val ≤ r.end.val ∧ r.end.val ≤ max.val)
    (h : ranges.merge_ranges input max = ok out) :
    ∀ x, InRanges out.val x ↔ InRanges input.val x :=
  Verified.merge_ranges_ok input out max hwf h

/-- Finding: the merged ranges can overlap. With ports `1024-65535` and
`2000`, `next(65535)` wraps to 0, so `2000` is not merged in. -/
theorem merge_ranges_overlap :
    ∃ input out : alloc.vec.Vec ranges.Range,
      input.val = [⟨1024#u128, 65535#u128⟩, ⟨2000#u128, 2000#u128⟩] ∧
      ranges.merge_ranges input 65535#u128 = ok out ∧ out.val = input.val ∧ ¬ PairwiseDisjoint out.val := by
  refine ⟨Verified.ex_in, Verified.ex_in, Verified.ex_in_val, Verified.merge_ex_in, rfl, ?_⟩
  rw [Verified.ex_in_val]
  simp [PairwiseDisjoint]

end defguard_kernel.Properties
