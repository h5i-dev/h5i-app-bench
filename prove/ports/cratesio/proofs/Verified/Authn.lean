import Verified.Check
/-!
# What a successful authentication implies
-/
open Aeneas Aeneas.Std Result cratesio_kernel cratesio_kernel.Spec
open H5iAppLib hiding Covers
open Aeneas.Std.WP
open cratesio_kernel.Verified.Bytes cratesio_kernel.Verified.Auth cratesio_kernel.Verified.Scopes
  cratesio_kernel.Verified.Check

namespace cratesio_kernel.Verified.Authn

theorem vec_index_get? {α} {v : alloc.vec.Vec α} {i : Usize} {x : α}
    (h : alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice α) v i = ok x) : v.val[i.val]? = some x :=
  vec_index_ok_get? h

theorem find_user_some {users : Slice auth.User} {id : I32} {u : auth.User}
    (h : auth.find_user users id = ok (some u)) : u ∈ users.val ∧ u.id = id := by
  have := post_of_ok (find_user_spec users id) h
  exact ⟨List.mem_of_find?_eq_some this, by simpa using List.find?_some this⟩

theorem is_locked_false {u : auth.User} {now : I64} {b : Bool} (h : auth.is_locked u now = ok b)
    (hb : ¬ b = true) : ¬ Locked u now.val := by
  have := post_of_ok (is_locked_spec u now) h
  intro hl; apply hb; rw [← this]; simpa using hl

theorem find_token_some {tokens : alloc.vec.Vec auth.ApiToken} {s : Slice U8} {now : I64} {i : Usize}
    (h : auth.find_token tokens s now = ok (some i)) :
    ∃ hi : i.val < tokens.val.length, Live (tokens.val[i.val]) s.val now.val := by
  have hp := post_of_ok (find_token_spec tokens s now) h
  obtain ⟨h1, h2⟩ := hp
  have hi := h2 i rfl
  refine ⟨hi, ?_⟩
  simp only [Option.map_some] at h1
  have := (List.findIdx?_eq_some_iff_getElem.1 h1).2.1
  simpa using this

/-- A cookie authentication: the session names an existing, unlocked user and
carries that user's current session epoch. -/
theorem cookie_user_ok {users : Slice auth.User} {uid : I32} {e : auth.Epoch} {now : I64} {u : auth.User}
    (h : auth.cookie_user users uid e now = ok (.Ok u)) :
    u ∈ users.val ∧ u.id = uid ∧ ¬ Locked u now.val ∧ epochOf e = some u.session_epoch.val := by
  unfold auth.cookie_user at h
  h5i_invert h
  all_goals
    obtain ⟨hm, hid⟩ := find_user_some ‹_›
    refine ⟨hm, hid, is_locked_false ‹_› ‹_›, ?_⟩
    simp_all [epochOf]

/-- A token authentication: the header carries a `cio` secret that a live
token row accepts, owned by an existing, unlocked user. -/
theorem token_user_ok {users : Slice auth.User} {tokens : alloc.vec.Vec auth.ApiToken} {hd : Slice U8}
    {now : I64} {i : Usize} {u : auth.User}
    (h : auth.token_user users tokens hd now = ok (.Ok (.Token i u))) :
    ∃ s, auth.parse_auth_header hd = ok (.Ok s) ∧ [99#u8, 105#u8, 111#u8] <+: s.val ∧
      ∃ hi : i.val < tokens.val.length, Live (tokens.val[i.val]) s.val now.val ∧
        u ∈ users.val ∧ u.id = (tokens.val[i.val]).user_id ∧ ¬ Locked u now.val := by
  unfold auth.token_user at h
  h5i_invert h
  simp only [auth.Authentication.Token.injEq] at h
  obtain ⟨h1, h2⟩ := h
  subst h1 h2
  obtain ⟨hi, hlive⟩ := find_token_some ho
  obtain ⟨hidx, hat'⟩ := vec_index_ok hat
  have hpre := post_of_ok (starts_with_spec _ _) hb
  have hs2v : s2.val = [99#u8, 105#u8, 111#u8] := by
    simp [auth.TOKEN_PREFIX, Array.to_slice, lift, Array.make] at hs2
    rw [← hs2]; rfl
  obtain ⟨hm, hid⟩ := find_user_some ho1
  refine ⟨s, hr, ?_, hidx, by simpa using hlive, hm, by rw [hid, ← hat'], is_locked_false hb1 hc_1⟩
  rw [← hs2v]
  have : decide (s2.val <+: s.val) = true := by rw [hc] at hpre; simpa using hpre
  simpa using this

theorem origins_true {o a : Slice U64} {b : Bool} (h : auth.origins_ok o a = ok b) (hb : b = true) :
    ∀ x ∈ o.val, x ∈ a.val := by
  have := post_of_ok (origins_ok_spec o a) h
  rw [hb] at this; simpa using this

theorem origins_false {o a : Slice U64} {b : Bool} (h : auth.origins_ok o a = ok b) (hb : ¬ b = true) :
    ¬ ∀ x ∈ o.val, x ∈ a.val := by
  have := post_of_ok (origins_ok_spec o a) h
  intro hall; apply hb; rw [← this]; simpa using hall

theorem token_user_not_cookie (users : Slice auth.User) (tokens : alloc.vec.Vec auth.ApiToken) (hd : Slice U8)
    (now : I64) (u : auth.User) : auth.token_user users tokens hd now ≠ ok (.Ok (.Cookie u)) := by
  intro h
  unfold auth.token_user at h
  h5i_invert h

/-- What a successful `authenticate` establishes. -/
theorem authenticate_ok {allowed : Slice U64} {users : Slice auth.User} {tokens : alloc.vec.Vec auth.ApiToken}
    {req : auth.Request} {now : I64} {a : auth.Authentication}
    (h : auth.authenticate allowed users tokens req now = ok (.Ok a)) :
    (∀ x ∈ req.origins.val, x ∈ allowed.val) ∧
    match a with
    | .Cookie u => req.session_uid = some u.id ∧ u ∈ users.val ∧ ¬ Locked u now.val ∧
        epochOf req.session_epoch = some u.session_epoch.val
    | .Token i u => req.session_uid = none ∧ ∃ hd s, req.authorization = some hd ∧
        auth.parse_auth_header hd.deref = ok (.Ok s) ∧ [99#u8, 105#u8, 111#u8] <+: s.val ∧
        ∃ hi : i.val < tokens.val.length, Live (tokens.val[i.val]) s.val now.val ∧
          u ∈ users.val ∧ u.id = (tokens.val[i.val]).user_id ∧ ¬ Locked u now.val := by
  unfold auth.authenticate at h
  h5i_invert h
  all_goals
    have ho := origins_true hb hc
    simp only [deref_val] at ho
    refine ⟨ho, ?_⟩
  · rcases a with u | ⟨i, u⟩
    · exact absurd h (token_user_not_cookie users tokens _ now u)
    · obtain ⟨s, hp, hpre, hi, hlive, hm, hid, hl⟩ := token_user_ok h
      exact ⟨hc_1, _, s, hc_2, hp, hpre, hi, hlive, hm, hid, hl⟩
  · obtain ⟨hm, hid, hl, he⟩ := cookie_user_ok ‹_›
    exact ⟨by rw [hc_1, hid], hm, hl, he⟩

/-- What a successful `AuthCheck::check` establishes on top of
`authenticate`. -/
theorem check_ok {ac : auth.AuthCheck} {allowed : Slice U64} {users : Slice auth.User}
    {tokens : alloc.vec.Vec auth.ApiToken} {req : auth.Request} {now : I64} {a : auth.Authentication}
    (h : auth.check ac allowed users tokens req now = ok (.Ok a)) :
    auth.authenticate allowed users tokens req now = ok (.Ok a) ∧
    ∀ i u, a = .Token i u → ac.allow_token = true ∧ ∃ hi : i.val < tokens.val.length,
      ((tokens.val[i.val]).endpoint_scopes = none ∨ ∃ v s, (tokens.val[i.val]).endpoint_scopes = some v ∧
        ac.endpoint_scope = some s ∧ s ∈ v.val) ∧
      ((tokens.val[i.val]).crate_scopes = none ∨ (∃ v, (tokens.val[i.val]).crate_scopes = some v ∧ v.val = []) ∨
        (∃ v, (tokens.val[i.val]).crate_scopes = some v ∧ ac.crate_name = none ∧ ac.allow_any_crate_scope = true) ∨
        (∃ v n, (tokens.val[i.val]).crate_scopes = some v ∧ ac.crate_name = some n ∧
          ∃ p ∈ v.val, Spec.Covers p.val n.val)) := by
  unfold auth.check at h
  h5i_invert h
  · refine ⟨‹_›, fun i' u' he => ?_⟩
    cases he
  · refine ⟨‹_›, fun i' u' he => ?_⟩
    simp only [auth.Authentication.Token.injEq] at he
    obtain ⟨rfl, rfl⟩ := he
    obtain ⟨hidx, hte⟩ := vec_index_ok ht
    have h1 := post_of_ok (endpoint_scope_matches_spec ac _) hb
    have h2 := post_of_ok (crate_scope_matches_spec ac _) hb1
    refine ⟨hc, hidx, ?_, ?_⟩
    · rw [hte]; exact h1.1 hc_1
    · rw [hte]; exact h2.1 hc_2

end cratesio_kernel.Verified.Authn
