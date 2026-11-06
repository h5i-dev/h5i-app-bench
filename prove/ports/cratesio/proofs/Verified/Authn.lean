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
  all_goals scalar_tac

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
  done

end cratesio_kernel.Verified.Authn
