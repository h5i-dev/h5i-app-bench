import Spec
/-!
# Bit-level lemmas about the extracted permission code

Every permission constant is a power of two; `map_bit` is the `if bits & from != 0`
step of upstream's bitspace tables. From these, each table function gets a spec
saying which permission bits it sets, in terms of `Spec.names`.
-/
open Aeneas Aeneas.Std Result synctv_kernel synctv_kernel.Spec

set_option linter.unusedSimpArgs false

namespace synctv_kernel.Lemmas



theorem M_SEND_CHAT_MESSAGES_val : perms.M_SEND_CHAT_MESSAGES.val = 2 ^ 0 := by unfold perms.M_SEND_CHAT_MESSAGES; rfl
theorem M_MANAGE_OWN_MEDIA_val : perms.M_MANAGE_OWN_MEDIA.val = 2 ^ 1 := by unfold perms.M_MANAGE_OWN_MEDIA; rfl
theorem M_BROWSE_LIBRARY_val : perms.M_BROWSE_LIBRARY.val = 2 ^ 2 := by unfold perms.M_BROWSE_LIBRARY; rfl
theorem M_VIEW_MEMBERS_val : perms.M_VIEW_MEMBERS.val = 2 ^ 3 := by unfold perms.M_VIEW_MEMBERS; rfl
theorem M_VIEW_CHAT_HISTORY_val : perms.M_VIEW_CHAT_HISTORY.val = 2 ^ 4 := by unfold perms.M_VIEW_CHAT_HISTORY; rfl
theorem M_USE_VOICE_CHAT_val : perms.M_USE_VOICE_CHAT.val = 2 ^ 5 := by unfold perms.M_USE_VOICE_CHAT; rfl
theorem M_USE_P2P_MEDIA_val : perms.M_USE_P2P_MEDIA.val = 2 ^ 6 := by unfold perms.M_USE_P2P_MEDIA; rfl
theorem A_SEND_CHAT_MESSAGES_val : perms.A_SEND_CHAT_MESSAGES.val = 2 ^ 0 := by unfold perms.A_SEND_CHAT_MESSAGES; rfl
theorem A_MANAGE_OWN_MEDIA_val : perms.A_MANAGE_OWN_MEDIA.val = 2 ^ 1 := by unfold perms.A_MANAGE_OWN_MEDIA; rfl
theorem A_BROWSE_LIBRARY_val : perms.A_BROWSE_LIBRARY.val = 2 ^ 2 := by unfold perms.A_BROWSE_LIBRARY; rfl
theorem A_VIEW_MEMBERS_val : perms.A_VIEW_MEMBERS.val = 2 ^ 3 := by unfold perms.A_VIEW_MEMBERS; rfl
theorem A_VIEW_CHAT_HISTORY_val : perms.A_VIEW_CHAT_HISTORY.val = 2 ^ 4 := by unfold perms.A_VIEW_CHAT_HISTORY; rfl
theorem A_USE_VOICE_CHAT_val : perms.A_USE_VOICE_CHAT.val = 2 ^ 5 := by unfold perms.A_USE_VOICE_CHAT; rfl
theorem A_DELETE_MEDIA_val : perms.A_DELETE_MEDIA.val = 2 ^ 6 := by unfold perms.A_DELETE_MEDIA; rfl
theorem A_REORDER_MEDIA_val : perms.A_REORDER_MEDIA.val = 2 ^ 7 := by unfold perms.A_REORDER_MEDIA; rfl
theorem A_CLEAR_MEDIA_val : perms.A_CLEAR_MEDIA.val = 2 ^ 8 := by unfold perms.A_CLEAR_MEDIA; rfl
theorem A_MANAGE_LIVE_STREAMS_val : perms.A_MANAGE_LIVE_STREAMS.val = 2 ^ 9 := by unfold perms.A_MANAGE_LIVE_STREAMS; rfl
theorem A_CONTROL_PLAYBACK_STATE_val : perms.A_CONTROL_PLAYBACK_STATE.val = 2 ^ 10 := by unfold perms.A_CONTROL_PLAYBACK_STATE; rfl
theorem A_NAVIGATE_PLAYBACK_val : perms.A_NAVIGATE_PLAYBACK.val = 2 ^ 11 := by unfold perms.A_NAVIGATE_PLAYBACK; rfl
theorem A_REVIEW_JOIN_REQUESTS_val : perms.A_REVIEW_JOIN_REQUESTS.val = 2 ^ 12 := by unfold perms.A_REVIEW_JOIN_REQUESTS; rfl
theorem A_REMOVE_MEMBERS_val : perms.A_REMOVE_MEMBERS.val = 2 ^ 13 := by unfold perms.A_REMOVE_MEMBERS; rfl
theorem A_MANAGE_MEMBER_PERMISSIONS_val : perms.A_MANAGE_MEMBER_PERMISSIONS.val = 2 ^ 14 := by unfold perms.A_MANAGE_MEMBER_PERMISSIONS; rfl
theorem A_ADD_MEMBERS_val : perms.A_ADD_MEMBERS.val = 2 ^ 15 := by unfold perms.A_ADD_MEMBERS; rfl
theorem A_MANAGE_ROOM_SETTINGS_val : perms.A_MANAGE_ROOM_SETTINGS.val = 2 ^ 16 := by unfold perms.A_MANAGE_ROOM_SETTINGS; rfl
theorem A_DELETE_CHAT_MESSAGES_val : perms.A_DELETE_CHAT_MESSAGES.val = 2 ^ 17 := by unfold perms.A_DELETE_CHAT_MESSAGES; rfl
theorem A_DELETE_ROOM_val : perms.A_DELETE_ROOM.val = 2 ^ 18 := by unfold perms.A_DELETE_ROOM; rfl
theorem A_VIEW_PLAYBACK_HISTORY_val : perms.A_VIEW_PLAYBACK_HISTORY.val = 2 ^ 19 := by unfold perms.A_VIEW_PLAYBACK_HISTORY; rfl
theorem A_USE_P2P_MEDIA_val : perms.A_USE_P2P_MEDIA.val = 2 ^ 20 := by unfold perms.A_USE_P2P_MEDIA; rfl
theorem G_VIEW_MEMBERS_val : perms.G_VIEW_MEMBERS.val = 2 ^ 32 := by unfold perms.G_VIEW_MEMBERS; rfl
theorem G_VIEW_CHAT_HISTORY_val : perms.G_VIEW_CHAT_HISTORY.val = 2 ^ 33 := by unfold perms.G_VIEW_CHAT_HISTORY; rfl
theorem G_USE_VOICE_CHAT_val : perms.G_USE_VOICE_CHAT.val = 2 ^ 34 := by unfold perms.G_USE_VOICE_CHAT; rfl
theorem G_USE_P2P_MEDIA_val : perms.G_USE_P2P_MEDIA.val = 2 ^ 35 := by unfold perms.G_USE_P2P_MEDIA; rfl

theorem A_ALL_val : perms.A_ALL.val = 2 ^ 21 - 1 := by unfold perms.A_ALL; rfl
theorem M_ALL_val : perms.M_ALL.val = 2 ^ 7 - 1 := by unfold perms.M_ALL; rfl
theorem G_ALL_val : perms.G_ALL.val = 2 ^ 36 - 2 ^ 32 := by unfold perms.G_ALL; rfl
theorem A_DEFAULT_val : perms.A_DEFAULT.val = 2 ^ 21 - 1 - 2 ^ 18 := by unfold perms.A_DEFAULT; rfl
theorem G_DEFAULT_val : perms.G_DEFAULT.val = 0 := by unfold perms.G_DEFAULT; rfl

theorem and_pow_eq_zero (x j : Nat) : (x &&& 2 ^ j = 0) ↔ x.testBit j = false := by
  constructor
  · intro h0
    have := congrArg (fun n => n.testBit j) h0
    simpa [Nat.testBit_two_pow] using this
  · intro h
    apply Nat.eq_of_testBit_eq
    intro i
    simp only [Nat.testBit_and, Nat.testBit_two_pow, Nat.zero_testBit]
    by_cases hij : j = i
    · subst hij; simp [h]
    · simp [hij]

theorem bit_not (x : U64) (i : Nat) :
    (~~~x).val.testBit i = (decide (i < 64) && !x.val.testBit i) := by
  have : (~~~x).val = (~~~x.bv).toNat := rfl
  rw [this, BitVec.testBit_toNat, BitVec.getLsbD_not]
  rfl

theorem testBit_low_mask (k i : Nat) : (2 ^ k - 1).testBit i = decide (i < k) := by
  rw [Nat.testBit_two_pow_sub_one]

theorem map_bit_ok (b f t : U64) :
    perms.map_bit b f t = ok (if b.val &&& f.val = 0 then 0#u64 else t) := by
  unfold perms.map_bit
  simp only [lift, bind_ok]
  split <;> rename_i h <;> split <;> rename_i h' <;> simp_all

theorem ite_val_testBit (c : Prop) [Decidable c] (t : U64) (i : Nat) :
    (if c then 0#u64 else t).val.testBit i = (!decide c && t.val.testBit i) := by
  by_cases h : c <;> simp [h]

theorem adminBit_lt (p : perms.RoomPermission) : adminBit p < 21 := by
  cases p <;> decide

/-- Rewrites the bit tables into bit tests on their arguments. -/
macro "bits_simp" : tactic => `(tactic| simp only [UScalar.val_or, UScalar.val_and, Nat.testBit_or,
  Nat.testBit_and, ite_val_testBit, bit_not, and_pow_eq_zero, Nat.testBit_two_pow, M_SEND_CHAT_MESSAGES_val, M_MANAGE_OWN_MEDIA_val, M_BROWSE_LIBRARY_val, M_VIEW_MEMBERS_val, M_VIEW_CHAT_HISTORY_val, M_USE_VOICE_CHAT_val, M_USE_P2P_MEDIA_val, A_SEND_CHAT_MESSAGES_val, A_MANAGE_OWN_MEDIA_val, A_BROWSE_LIBRARY_val, A_VIEW_MEMBERS_val, A_VIEW_CHAT_HISTORY_val, A_USE_VOICE_CHAT_val, A_DELETE_MEDIA_val, A_REORDER_MEDIA_val, A_CLEAR_MEDIA_val, A_MANAGE_LIVE_STREAMS_val, A_CONTROL_PLAYBACK_STATE_val, A_NAVIGATE_PLAYBACK_val, A_REVIEW_JOIN_REQUESTS_val, A_REMOVE_MEMBERS_val, A_MANAGE_MEMBER_PERMISSIONS_val, A_ADD_MEMBERS_val, A_MANAGE_ROOM_SETTINGS_val, A_DELETE_CHAT_MESSAGES_val, A_DELETE_ROOM_val, A_VIEW_PLAYBACK_HISTORY_val, A_USE_P2P_MEDIA_val, G_VIEW_MEMBERS_val, G_VIEW_CHAT_HISTORY_val, G_USE_VOICE_CHAT_val, G_USE_P2P_MEDIA_val])

theorem member_to_spec (b : U64) : ∃ r, perms.member_to_permissions b = ok r ∧
    ∀ p, (r.val.testBit (adminBit p) = true ↔ names memberBit b.val p) := by
  simp only [perms.member_to_permissions, map_bit_ok, lift, bind_ok]
  refine ⟨_, rfl, ?_⟩
  intro p
  bits_simp
  cases p <;> simp [names, memberBit, adminBit]

theorem admin_to_spec (b : U64) : ∃ r, perms.admin_to_permissions b = ok r ∧
    ∀ p, (r.val.testBit (adminBit p) = true ↔ names adminSpace b.val p) := by
  simp only [perms.admin_to_permissions, map_bit_ok, lift, bind_ok]
  refine ⟨_, rfl, ?_⟩
  intro p
  bits_simp
  cases p <;> simp [names, adminSpace, adminBit]

theorem guest_to_spec (b : U64) : ∃ r, perms.guest_to_permissions b = ok r ∧
    ∀ p, (r.val.testBit (adminBit p) = true ↔ names guestBit b.val p) := by
  simp only [perms.guest_to_permissions, map_bit_ok, lift, bind_ok]
  refine ⟨_, rfl, ?_⟩
  intro p
  bits_simp
  cases p <;> simp [names, guestBit, adminBit]


theorem guest_assignable_spec : ∃ r, perms.guest_assignable = ok r ∧
    ∀ p, (r.val.testBit (adminBit p) = true ↔ guestAssignable p) := by
  obtain ⟨r, hr, h⟩ := guest_to_spec perms.G_ALL
  refine ⟨r, by simp only [perms.guest_assignable, hr], fun p => ?_⟩
  rw [h p]
  cases p <;> simp [names, guestBit, guestAssignable, G_ALL_val] <;> decide

theorem bne_zero (x : U64) : (x != 0#u64) = !decide (x.val = 0) := by
  by_cases h : x.val = 0
  · have : x = 0#u64 := by apply UScalar.eq_of_val_eq; simpa using h
    subst this; simp
  · have : x ≠ 0#u64 := by intro e; apply h; rw [e]; rfl
    simp [h, this]

theorem has_eq (s : U64) (p : perms.RoomPermission) :
    perms.has s p = ok (s.val.testBit (adminBit p)) := by
  cases p <;> simp only [perms.has, perms.bit_for, lift, bind_ok, bne_zero, UScalar.val_and, M_SEND_CHAT_MESSAGES_val, M_MANAGE_OWN_MEDIA_val, M_BROWSE_LIBRARY_val, M_VIEW_MEMBERS_val, M_VIEW_CHAT_HISTORY_val, M_USE_VOICE_CHAT_val, M_USE_P2P_MEDIA_val, A_SEND_CHAT_MESSAGES_val, A_MANAGE_OWN_MEDIA_val, A_BROWSE_LIBRARY_val, A_VIEW_MEMBERS_val, A_VIEW_CHAT_HISTORY_val, A_USE_VOICE_CHAT_val, A_DELETE_MEDIA_val, A_REORDER_MEDIA_val, A_CLEAR_MEDIA_val, A_MANAGE_LIVE_STREAMS_val, A_CONTROL_PLAYBACK_STATE_val, A_NAVIGATE_PLAYBACK_val, A_REVIEW_JOIN_REQUESTS_val, A_REMOVE_MEMBERS_val, A_MANAGE_MEMBER_PERMISSIONS_val, A_ADD_MEMBERS_val, A_MANAGE_ROOM_SETTINGS_val, A_DELETE_CHAT_MESSAGES_val, A_DELETE_ROOM_val, A_VIEW_PLAYBACK_HISTORY_val, A_USE_P2P_MEDIA_val, G_VIEW_MEMBERS_val, G_VIEW_CHAT_HISTORY_val, G_USE_VOICE_CHAT_val, G_USE_P2P_MEDIA_val, and_pow_eq_zero] <;> simp [adminBit]

theorem has_spec (s : U64) (p : perms.RoomPermission) :
    ∃ b, perms.has s p = ok b ∧ (b = true ↔ grants s.val p) :=
  ⟨_, has_eq s p, Iff.rfl⟩

theorem all_eq : perms.all = ok perms.A_ALL := rfl

theorem A_ALL_grants (p : perms.RoomPermission) : grants perms.A_ALL.val p := by
  unfold grants
  rw [A_ALL_val, testBit_low_mask]
  simpa using adminBit_lt p

/-- The allow/deny step on bits: `(base | add) & !rem`. -/
theorem allow_deny_grants (base add rem : U64)
    (B : Prop) (p : perms.RoomPermission)
    (hb : base.val.testBit (adminBit p) = true ↔ B)
    (A R : Prop)
    (ha : add.val.testBit (adminBit p) = true ↔ A)
    (hr : rem.val.testBit (adminBit p) = true ↔ R) :
    grants ((base ||| add) &&& ~~~rem).val p ↔ (B ∨ A) ∧ ¬ R := by
  unfold grants
  have hlt : adminBit p < 64 := by have := adminBit_lt p; omega
  simp only [UScalar.val_and, UScalar.val_or, Nat.testBit_and, Nat.testBit_or, bit_not,
    hlt, decide_true, Bool.true_and, Bool.and_eq_true, Bool.or_eq_true, Bool.not_eq_true',
    hb, ha]
  rw [← Bool.not_eq_true, hr]

theorem effective_spec (m : perms.MemberPerms) (d : U64) :
    ∃ e, perms.effective_permissions m d = ok e ∧
      ∀ p, (grants e.val p ↔ effective m (grants d.val) p) := by
  cases hrole : m.role
  · refine ⟨perms.A_ALL, by simp [perms.effective_permissions, hrole, all_eq], fun p => ?_⟩
    simp [effective, hrole, A_ALL_grants]
  · obtain ⟨a, ha, hA⟩ := admin_to_spec m.admin_added_permissions
    obtain ⟨r, hr, hR⟩ := admin_to_spec m.admin_removed_permissions
    refine ⟨_, by simp only [perms.effective_permissions, hrole, ha, hr, lift, bind_ok]; rfl, fun p => ?_⟩
    simp only [effective, hrole, allowDeny]
    exact allow_deny_grants d a r _ p Iff.rfl _ _ (hA p) (hR p)
  · obtain ⟨a, ha, hA⟩ := member_to_spec m.added_permissions
    obtain ⟨r, hr, hR⟩ := member_to_spec m.removed_permissions
    refine ⟨_, by simp only [perms.effective_permissions, hrole, ha, hr, lift, bind_ok]; rfl, fun p => ?_⟩
    simp only [effective, hrole, allowDeny]
    exact allow_deny_grants d a r _ p Iff.rfl _ _ (hA p) (hR p)
  · obtain ⟨g, hg, hG⟩ := guest_assignable_spec
    obtain ⟨a, ha, hA⟩ := guest_to_spec m.added_permissions
    obtain ⟨r, hr, hR⟩ := guest_to_spec m.removed_permissions
    refine ⟨_, by simp only [perms.effective_permissions, hrole, hg, ha, hr, lift, bind_ok]; rfl, fun p => ?_⟩
    simp only [effective, hrole, allowDeny]
    refine allow_deny_grants (d &&& g) a r _ p ?_ _ _ (hA p) (hR p)
    simp only [UScalar.val_and, Nat.testBit_and, Bool.and_eq_true]
    exact and_congr Iff.rfl (hG p)

theorem role_default_spec (d : perms.Defaults) (r : perms.Role) (s : perms.SettingsPerms) :
    ∃ x, perms.role_default d r s = ok x ∧ ∀ p, (grants x.val p ↔ roleDefault d s r p) := by
  cases r
  · exact ⟨perms.A_ALL, by simp [perms.role_default, all_eq], fun p => by simp [roleDefault, A_ALL_grants]⟩
  · obtain ⟨a, ha, hA⟩ := admin_to_spec s.admin_added_permissions
    obtain ⟨r, hr, hR⟩ := admin_to_spec s.admin_removed_permissions
    refine ⟨_, by simp only [perms.role_default, perms.settings_admin_permissions, ha, hr, lift, bind_ok]; rfl,
      fun p => ?_⟩
    exact allow_deny_grants d.admin a r _ p Iff.rfl _ _ (hA p) (hR p)
  · obtain ⟨a, ha, hA⟩ := member_to_spec s.member_added_permissions
    obtain ⟨r, hr, hR⟩ := member_to_spec s.member_removed_permissions
    refine ⟨_, by simp only [perms.role_default, perms.settings_member_permissions, ha, hr, lift, bind_ok]; rfl,
      fun p => ?_⟩
    exact allow_deny_grants d.member a r _ p Iff.rfl _ _ (hA p) (hR p)
  · obtain ⟨g, hg, hG⟩ := guest_assignable_spec
    obtain ⟨a, ha, hA⟩ := guest_to_spec s.guest_added_permissions
    obtain ⟨r, hr, hR⟩ := guest_to_spec s.guest_removed_permissions
    refine ⟨_, by simp only [perms.role_default, perms.settings_guest_permissions, hg, ha, hr, lift, bind_ok]; rfl,
      fun p => ?_⟩
    refine allow_deny_grants (d.guest &&& g) a r _ p ?_ _ _ (hA p) (hR p)
    simp only [UScalar.val_and, Nat.testBit_and, Bool.and_eq_true]
    exact and_congr Iff.rfl (hG p)

theorem effective_for_member_spec (d : perms.Defaults) (m : perms.MemberPerms) (s : perms.SettingsPerms) :
    ∃ e, perms.effective_for_member d m s = ok e ∧
      ∀ p, (grants e.val p ↔ effective m (roleDefault d s m.role) p) := by
  obtain ⟨x, hx, hX⟩ := role_default_spec d m.role s
  obtain ⟨e, he, hE⟩ := effective_spec m x
  refine ⟨e, by simp only [perms.effective_for_member, hx, he, bind_ok], fun p => ?_⟩
  rw [hE p]
  unfold effective
  have hx' : grants x.val = roleDefault d s m.role := funext fun q => propext (hX q)
  rw [hx']

theorem effective_full_default (m : perms.MemberPerms) :
    ∃ e, perms.effective_permissions m perms.A_ALL = ok e ∧
      ∀ p, (grants e.val p ↔ effective m (fun _ => True) p) := by
  obtain ⟨e, he, hE⟩ := effective_spec m perms.A_ALL
  refine ⟨e, he, fun p => ?_⟩
  rw [hE p]
  have : grants perms.A_ALL.val = fun _ => True := funext fun q => propext ⟨fun _ => trivial, fun _ => A_ALL_grants q⟩
  rw [this]

theorem calculator_spec (d : perms.Defaults) (m : perms.MemberPerms) (s : perms.SettingsPerms)
    (p : perms.RoomPermission) :
    ∃ b, perms.calculator_has_permission d m s p = ok b ∧ (b = true ↔ calcHas d s m p) := by
  obtain ⟨e0, he0, hE0⟩ := effective_full_default m
  obtain ⟨e, he, hE⟩ := effective_for_member_spec d m s
  unfold calcHas
  by_cases h0 : grants e0.val p
  · refine ⟨e.val.testBit (adminBit p), ?_, ?_⟩
    · have hb : e0.val.testBit (adminBit p) = true := h0
      simp only [perms.calculator_has_permission, all_eq, perms.member_has_permission, he0, has_eq, hb,
        bind_ok, if_true, he]
    · exact ⟨fun h => ⟨(hE0 p).1 h0, (hE p).1 h⟩, fun h => (hE p).2 h.2⟩
  · refine ⟨false, ?_, ?_⟩
    · have hb : e0.val.testBit (adminBit p) = false := by simpa [grants] using h0
      simp only [perms.calculator_has_permission, all_eq, perms.member_has_permission, he0, has_eq, hb,
        bind_ok]
      rfl
    · simp only [Bool.false_eq_true, false_iff, not_and]
      exact fun h => absurd ((hE0 p).2 h) h0

end synctv_kernel.Lemmas
