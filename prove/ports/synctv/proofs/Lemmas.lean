import Spec
/-!
# Bit-level lemmas about the extracted permission code

Every permission constant is a power of two; `map_bit` is the `if bits & from != 0`
step of upstream's bitspace tables. From these, each table function gets a spec
saying which permission bits it sets, in terms of `Spec.names`.
-/
open Aeneas Aeneas.Std Result Aeneas.Std.WP synctv_kernel synctv_kernel.Spec H5iAppLib

set_option linter.unusedSimpArgs false

h5i_derive_all

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

/-! ## Policy validators -/

theorem u64_eq_zero_iff (x : U64) : x = 0#u64 ↔ x.val = 0 := by
  constructor
  · intro h; subst h; rfl
  · intro h; apply UScalar.eq_of_val_eq; simpa using h

theorem and_not_zero_iff (b m : U64) :
    (b &&& ~~~m).val = 0 ↔ ∀ i, b.val.testBit i = true → m.val.testBit i = true := by
  constructor
  · intro h i hi
    have := congrArg (fun n => n.testBit i) h
    simp only [UScalar.val_and, Nat.testBit_and, bit_not, Nat.zero_testBit, hi, Bool.true_and] at this
    have hlt : i < 64 := by
      by_contra hge
      have : b.val < 2 ^ i := lt_of_lt_of_le b.hBounds (Nat.pow_le_pow_right (by decide) (by simp at hge ⊢; omega))
      rw [Nat.testBit_eq_false_of_lt this] at hi; exact absurd hi (by simp)
    simpa [hlt] using this
  · intro h
    apply Nat.eq_of_testBit_eq
    intro i
    simp only [UScalar.val_and, Nat.testBit_and, bit_not, Nat.zero_testBit]
    cases hb : b.val.testBit i
    · simp
    · simp [h i hb]

theorem guest_mask_testBit (i : Nat) : (2 ^ 36 - 2 ^ 32).testBit i = decide (32 ≤ i ∧ i < 36) := by
  have : 2 ^ 36 - 2 ^ 32 = (2 ^ 4 - 1) <<< 32 := by decide
  rw [this, Nat.testBit_shiftLeft, testBit_low_mask]
  by_cases h : 32 ≤ i <;> simp [h]; omega

theorem admin_iod_spec (b : U64) : ∃ x, perms.admin_includes_only_defined b = ok x ∧
    (x = true ↔ withinSpace 0 21 b.val) := by
  refine ⟨decide (b &&& ~~~perms.A_ALL = 0#u64), by simp [perms.admin_includes_only_defined, lift], ?_⟩
  simp only [decide_eq_true_eq, u64_eq_zero_iff, and_not_zero_iff, A_ALL_val, testBit_low_mask, withinSpace]
  simp

theorem member_iod_spec (b : U64) : ∃ x, perms.member_includes_only_defined b = ok x ∧
    (x = true ↔ withinSpace 0 7 b.val) := by
  refine ⟨decide (b &&& ~~~perms.M_ALL = 0#u64), by simp [perms.member_includes_only_defined, lift], ?_⟩
  simp only [decide_eq_true_eq, u64_eq_zero_iff, and_not_zero_iff, M_ALL_val, testBit_low_mask, withinSpace]
  simp

theorem guest_iod_spec (b : U64) : ∃ x, perms.guest_includes_only_defined b = ok x ∧
    (x = true ↔ withinSpace 32 4 b.val) := by
  refine ⟨decide (b &&& ~~~perms.G_ALL = 0#u64), by simp [perms.guest_includes_only_defined, lift], ?_⟩
  simp only [decide_eq_true_eq, u64_eq_zero_iff, and_not_zero_iff, G_ALL_val, guest_mask_testBit, withinSpace]

theorem role_eq (a b : perms.Role) : perms.Role.Insts.CoreCmpPartialEqRole.eq a b = ok (decide (a = b)) := by
  cases a <;> cases b <;> simp [perms.Role.Insts.CoreCmpPartialEqRole.eq, perms.Role.read_discriminant]

theorem role_assignable_iff (r : perms.Role) :
    policy.validate_role_can_be_assigned r = ok (.Ok ()) ↔ r ≠ .Creator := by
  cases r <;> simp [policy.validate_role_can_be_assigned, role_eq]

theorem add_member_role_iff (c a : I64) (r : perms.Role) :
    policy.validate_add_member_role c a r = ok (.Ok ()) ↔ r ≠ .Creator ∧ (r = .Admin → a = c) := by
  cases r <;> simp [policy.validate_add_member_role, policy.validate_role_can_be_assigned, role_eq,
    core.result.Result.Insts.CoreOpsTry.branch]
  exact ⟨fun h => (IScalar.eq_of_val_eq h).symm, fun h => by rw [h]⟩

theorem creator_update_iff (c a t : I64) :
    policy.validate_creator_member_role_update c a t = ok (.Ok ()) ↔ a = c ∧ t ≠ c := by
  simp only [policy.validate_creator_member_role_update, policy.validate_admin_member_role_update]
  by_cases h1 : c = a <;> by_cases h2 : t = c <;> simp [h1, h2, bne]
  exact fun e => h1 (IScalar.eq_of_val_eq e).symm

theorem admin_override_iff (a r : U64) :
    policy.validate_admin_override_bits a r = ok (.Ok ()) ↔ withinSpace 0 21 a.val ∧ withinSpace 0 21 r.val := by
  obtain ⟨x, hx, hX⟩ := admin_iod_spec a
  obtain ⟨y, hy, hY⟩ := admin_iod_spec r
  unfold policy.validate_admin_override_bits
  rw [hx, ← hX, ← hY]
  cases x <;> cases y <;> simp [hy]

theorem roleSpace_within (r : perms.Role) (b : U64) (x : Bool)
    (h : (match r with
      | .Creator => perms.admin_includes_only_defined b
      | .Admin => perms.admin_includes_only_defined b
      | .Member => perms.member_includes_only_defined b
      | .Guest => perms.guest_includes_only_defined b) = ok x) :
    x = true ↔ withinSpace (roleSpace r).1 (roleSpace r).2 b.val := by
  cases r
  · obtain ⟨y, hy, hY⟩ := admin_iod_spec b; rw [hy, Result.ok.injEq] at h; subst h; exact hY
  · obtain ⟨y, hy, hY⟩ := admin_iod_spec b; rw [hy, Result.ok.injEq] at h; subst h; exact hY
  · obtain ⟨y, hy, hY⟩ := member_iod_spec b; rw [hy, Result.ok.injEq] at h; subst h; exact hY
  · obtain ⟨y, hy, hY⟩ := guest_iod_spec b; rw [hy, Result.ok.injEq] at h; subst h; exact hY

theorem override_bits_iff (r : perms.Role) (a b : U64) :
    policy.validate_override_bits_for_role r a b = ok (.Ok ()) ↔
      withinSpace (roleSpace r).1 (roleSpace r).2 a.val ∧ withinSpace (roleSpace r).1 (roleSpace r).2 b.val := by
  cases r <;> simp only [policy.validate_override_bits_for_role, roleSpace]
  · obtain ⟨x, hx, hX⟩ := admin_iod_spec a
    obtain ⟨y, hy, hY⟩ := admin_iod_spec b
    rw [hx, ← hX, ← hY]; cases x <;> cases y <;> simp [hy]
  · obtain ⟨x, hx, hX⟩ := admin_iod_spec a
    obtain ⟨y, hy, hY⟩ := admin_iod_spec b
    rw [hx, ← hX, ← hY]; cases x <;> cases y <;> simp [hy]
  · obtain ⟨x, hx, hX⟩ := member_iod_spec a
    obtain ⟨y, hy, hY⟩ := member_iod_spec b
    rw [hx, ← hX, ← hY]; cases x <;> cases y <;> simp [hy]
  · obtain ⟨x, hx, hX⟩ := guest_iod_spec a
    obtain ⟨y, hy, hY⟩ := guest_iod_spec b
    rw [hx, ← hX, ← hY]; cases x <;> cases y <;> simp [hy]

theorem channel_iff (adm : Bool) (a r aa ar : U64) :
    policy.validate_member_permission_override_channel adm a r aa ar = ok (.Ok ()) ↔
      (adm = true → a.val = 0 ∧ r.val = 0) ∧ (adm = false → aa.val = 0 ∧ ar.val = 0) := by
  unfold policy.validate_member_permission_override_channel
  cases adm <;> simp <;> split_ifs <;> simp_all <;> scalar_tac

theorem kick_cooldown_iff (c : I64) :
    policy.validate_kick_cooldown_seconds c = ok (.Ok ()) ↔ 0 < c.val ∧ c.val ≤ 2592000 := by
  unfold policy.validate_kick_cooldown_seconds
  have : policy.MAX_KICK_COOLDOWN_SECONDS.val = 2592000 := by unfold policy.MAX_KICK_COOLDOWN_SECONDS; rfl
  split_ifs <;> simp <;> scalar_tac

theorem plan_sound (u : policy.MemberUpdate) (ce : Bool) (cr : perms.Role) (re : Bool) (c : I64)
    (plan : policy.MemberUpdatePlan)
    (h : policy.plan_member_update u ce cr re c = ok (.Ok plan)) :
    ce = true ∧ withinSpace 0 21 u.admin_added_permissions.val ∧ withinSpace 0 21 u.admin_removed_permissions.val ∧
    plan.effective_role = (if u.has_role then u.role else cr) ∧
    (u.has_role = true → u.role ≠ .Creator ∧ u.actor_id = c ∧ u.target_user_id ≠ c) ∧
    (u.apply_permission_update = true → plan.needs_manage_member_permissions = true ∧
      withinSpace (roleSpace plan.effective_role).1 (roleSpace plan.effective_role).2 u.added_permissions.val ∧
      withinSpace (roleSpace plan.effective_role).1 (roleSpace plan.effective_role).2 u.removed_permissions.val ∧
      (plan.effective_role = .Admin → u.added_permissions.val = 0 ∧ u.removed_permissions.val = 0) ∧
      (plan.effective_role ≠ .Admin → u.admin_added_permissions.val = 0 ∧ u.admin_removed_permissions.val = 0)) := by
  unfold policy.plan_member_update at h
  h5i_invert h
  all_goals
    simp only [show ∀ x : Unit, x = () from fun _ => rfl, admin_override_iff, override_bits_iff, channel_iff,
      creator_update_iff, role_assignable_iff, policy.effective_role_of, role_eq] at *
  all_goals
    simp only [Result.ok.injEq] at heffective_is_admin
    subst heffective_is_admin
    split at heffective_role <;> simp only [Result.ok.injEq] at heffective_role <;> subst heffective_role <;>
      simp_all

/-! ## Token and role decisions -/

theorem leeway_spec (l : U64) : auth.leeway_to_i64 l ⦃ x => x.val = min (l.val : Int) (2 ^ 63 - 1) ⦄ := by
  unfold auth.leeway_to_i64
  split
  · simp only [WP.spec_ok, UScalar.hcast_val_eq]
    rename_i h
    have : l.val ≤ 9223372036854775807 := by scalar_tac
    rw [Int.bmod_eq_of_le] <;> simp <;> omega
  · rename_i h
    have : ¬ l.val ≤ 9223372036854775807 := by scalar_tac
    simp; omega

theorem sat_spec (e l : I64) (hl : 0 ≤ l.val) :
    auth.saturating_add_nonneg e l ⦃ x => x.val = min (e.val + l.val) (2 ^ 63 - 1) ⦄ := by
  unfold auth.saturating_add_nonneg
  step*

theorem expiration_spec (now exp : I64) (l : U64) :
    auth.validate_expiration now exp l ⦃ r => (r = .Ok () ↔ notExpired now.val exp.val l.val) ∧
      (r = .Ok () ∨ r = .Err .Authentication) ⦄ := by
  unfold auth.validate_expiration
  obtain ⟨x, hx, hxv⟩ := WP.spec_imp_exists (leeway_spec l)
  have hx0 : 0 ≤ x.val := by rw [hxv]; omega
  obtain ⟨y, hy, hyv⟩ := WP.spec_imp_exists (sat_spec exp x hx0)
  simp only [hx, hy, bind_ok]
  split <;> simp [notExpired] <;> rename_i h <;> scalar_tac

theorem expiration_eq (now exp : I64) (l : U64) : ∃ r, auth.validate_expiration now exp l = ok r ∧
    (r = .Ok () ↔ notExpired now.val exp.val l.val) ∧ (r = .Ok () ∨ r = .Err .Authentication) :=
  WP.spec_imp_exists (expiration_spec now exp l)

theorem tt_ne (a b : auth.TokenType) :
    core.cmp.PartialEq.ne.trait_default auth.TokenType.Insts.CoreCmpPartialEqTokenType a b = ok (decide (a ≠ b)) := by
  cases a <;> cases b <;> simp [core.cmp.PartialEq.ne.trait_default, core.cmp.PartialEq.ne.default,
    auth.TokenType.Insts.CoreCmpPartialEqTokenType.eq, auth.TokenType.read_discriminant]

theorem user_token_accepted (now exp : I64) (l : U64) (typ expected : auth.TokenType)
    (h : auth.accept_user_token now exp l typ expected = ok (.Ok ())) :
    typ = expected ∧ notExpired now.val exp.val l.val := by
  obtain ⟨r, hr, hiff, hor⟩ := expiration_eq now exp l
  unfold auth.accept_user_token at h
  rcases hor with rfl | rfl
  · simp only [hr, bind_ok, core.result.Result.Insts.CoreOpsTry.branch, tt_ne] at h
    by_cases he : typ = expected <;> simp [he] at h
    exact ⟨he, hiff.1 rfl⟩
  · simp [hr, core.result.Result.Insts.CoreOpsTry.branch,
      core.result.Result.Insts.CoreOpsTry_traitFromResidualResult.from_residual] at h

theorem calc_true {d m s p} (h : perms.calculator_has_permission d m s p = ok true) :
    calcHas d s m p := by
  obtain ⟨b, hb, hiff⟩ := calculator_spec d m s p
  rw [hb, Result.ok.injEq] at h
  exact hiff.1 h

theorem names_guest_assignable {bits : Nat} {p : perms.RoomPermission} (h : names guestBit bits p) :
    guestAssignable p := by
  obtain ⟨j, hj, _⟩ := h
  simp [guestAssignable, hj]

theorem names_none {space : perms.RoomPermission → Option Nat} {bits p} (h : space p = none) :
    ¬ names space bits p := by
  rintro ⟨j, hj, _⟩
  simp [h] at hj

/-! ## Bearer header parsing -/

@[step] theorem is_ascii_ws_spec (b : U8) : auth.is_ascii_ws b ⦃ _ => True ⦄ := by
  unfold auth.is_ascii_ws; split <;> simp; split <;> simp

theorem loop0_spec (v : Slice U8) (s : Usize) (hs : s.val ≤ v.length) :
    auth.extract_bearer_token_loop0 v s ⦃ r => s.val ≤ r.val ∧ r.val ≤ v.length ⦄ := by
  unfold auth.extract_bearer_token_loop0
  apply loop.spec_decr_nat (measure := fun (j : Usize) => v.length - j.val)
    (inv := fun j => s.val ≤ j.val ∧ j.val ≤ v.length)
  · rintro j ⟨h1, h2⟩
    unfold auth.extract_bearer_token_loop0.body
    step*
    all_goals scalar_tac
  · exact ⟨le_refl _, hs⟩

theorem loop1_spec (v : Slice U8) (s e : Usize) (hs : s.val ≤ e.val) (he : e.val ≤ v.length) :
    auth.extract_bearer_token_loop1 v s e ⦃ r => s.val ≤ r.val ∧ r.val ≤ e.val ⦄ := by
  unfold auth.extract_bearer_token_loop1
  apply loop.spec_decr_nat (measure := fun (j : Usize) => j.val)
    (inv := fun j => s.val ≤ j.val ∧ j.val ≤ e.val)
  · rintro j ⟨h1, h2⟩
    unfold auth.extract_bearer_token_loop1.body
    step*
    all_goals scalar_tac
  · exact ⟨hs, le_refl _⟩

theorem ascii_lower_eq (b : U8) : auth.ascii_lower b = ok (lowerB b) := by
  unfold auth.ascii_lower lowerB
  split_ifs with h1 h2 h3 <;> first | (simp_all; done) | skip
  obtain ⟨z, hz, hzv⟩ := WP.spec_imp_exists (UScalar.add_spec (x := b) (y := 32#u8) (by scalar_tac))
  rw [hz]
  congr 1
  apply UScalar.eq_of_val_eq
  simp [hzv]

theorem slice_get? {s : Slice U8} {i : Usize} {x : U8} (h : s.index_usize i = ok x) :
    s.val[i.val]? = some x := by
  obtain ⟨hi, e⟩ := slice_index_ok h
  rw [List.getElem?_eq_getElem hi, e]

theorem bearer_prefix_true (v : Slice U8) (h : auth.bearer_prefix v = ok true) :
    (v.val.take 7).map lowerB = [98#u8, 101#u8, 97#u8, 114#u8, 101#u8, 114#u8, 32#u8] := by
  unfold auth.bearer_prefix at h
  simp only [ascii_lower_eq] at h
  h5i_invert h
  have g0 := slice_get? hi
  have g1 := slice_get? hi2
  have g2 := slice_get? hi4
  have g3 := slice_get? hi6
  have g4 := slice_get? hi8
  have g5 := slice_get? hi10
  have g6 := slice_get? hi12
  simp only [UScalar.ofNatCore_val_eq] at g0 g1 g2 g3 g4 g5 g6
  simp only [decide_eq_true_eq] at h
  subst h
  match hv : v.val, g0, g1, g2, g3, g4, g5, g6 with
  | a0 :: a1 :: a2 :: a3 :: a4 :: a5 :: a6 :: rest, g0, g1, g2, g3, g4, g5, g6 =>
    simp only [List.getElem?_cons_zero, List.getElem?_cons_succ, Option.some.injEq] at g0 g1 g2 g3 g4 g5 g6
    subst g0 g1 g2 g3 g4 g5 g6
    simp [hc, hc_1, hc_2, hc_3, hc_4, hc_5]
    simp [lowerB]


end synctv_kernel.Lemmas
