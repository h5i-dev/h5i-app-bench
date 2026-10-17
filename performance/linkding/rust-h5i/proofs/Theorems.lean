import ReadOnly
import Helpers
/-!
# Who may do what

Stated over the extracted `transition`, for every state and command.

* `guest_writes_nothing`: without a token, no accepted command writes.
* `unknown_token_refused`: a token no user holds is refused, whatever the
  command, before anything is read or written.
-/
open Aeneas Aeneas.Std Result linkding_kernel linkding_kernel.Spec linkding_kernel.Helpers H5iAppLib

namespace linkding_kernel.Theorems

theorem signed_in_guest (s : Snapshot) (t : alloc.vec.Vec U8) (h : t.val = []) :
    signed_in s t = ok (.Err .Unauthenticated) := by
  have ha : actor s t = ok (.Ok 0#u64) := by
    have := actor_spec s t
    rw [show actorOf s t = .Ok 0#u64 by simp [actorOf, h]] at this
    exact eq_ok_of_spec this
  unfold signed_in; simp [ha]

theorem actor_unknown (s : Snapshot) (t : alloc.vec.Vec U8) (ht : t.val ≠ [])
    (hk : ∀ k ∈ s.tokens.val, k.key ≠ t) : actor s t = ok (.Err .BadToken) := by
  have := actor_spec s t
  have hn : s.tokens.val.find? (·.key = t) = none := by
    rw [List.find?_eq_none]; intro k hk'; simpa using hk k hk'
  rw [show actorOf s t = .Err .BadToken by simp [actorOf, ht, tokenOf, hn]] at this
  exact eq_ok_of_spec this

theorem signed_in_unknown (s : Snapshot) (t : alloc.vec.Vec U8) (ht : t.val ≠ [])
    (hk : ∀ k ∈ s.tokens.val, k.key ≠ t) : signed_in s t = ok (.Err .BadToken) := by
  unfold signed_in; simp [actor_unknown s t ht hk]

/-- Without a token, no accepted command writes anything. -/
theorem guest_writes_nothing (o : U64) (s : Snapshot) (c : Command) (ws : alloc.vec.Vec Write) (r : Reply)
    (t : alloc.vec.Vec U8) (ht : t.val = []) (h : transition ⟨o, t⟩ s c = ok (.Ok (ws, r))) : ws.val = [] := by
  have g := signed_in_guest s t ht
  cases c <;> simp only [transition] at h
  · exact ReadOnly.profile_ws _ _ _ _ h
  · exact ReadOnly.list_ws _ _ _ _ _ _ _ h
  · exact ReadOnly.check_ws _ _ _ _ _ _ h
  · exact ReadOnly.get_bookmark_ws _ _ _ _ _ h
  all_goals first
    | exact ReadOnly.list_tags_ws _ _ _ _ _ _ h
    | exact ReadOnly.get_tag_ws _ _ _ _ _ h
    | exact ReadOnly.list_bundles_ws _ _ _ _ _ _ h
    | exact ReadOnly.get_bundle_ws _ _ _ _ _ h
    | (first | unfold create_bookmark at h | unfold update_bookmark at h | unfold delete_bookmark at h
             | unfold archive at h | unfold create_tag at h | unfold delete_tag at h
             | unfold create_bundle at h | unfold update_bundle at h | unfold delete_bundle at h);
      simp [g] at h

/-- A token that no user holds is refused for every command. -/
theorem unknown_token_refused (o : U64) (s : Snapshot) (c : Command) (t : alloc.vec.Vec U8) (ht : t.val ≠ [])
    (hk : ∀ k ∈ s.tokens.val, k.key ≠ t) : transition ⟨o, t⟩ s c = ok (.Err .BadToken) := by
  have g := signed_in_unknown s t ht hk
  have a := actor_unknown s t ht hk
  cases c <;> simp only [transition]
  case List f l off =>
    unfold list list_reply; simp [a]
  all_goals simp [profile, check, get_bookmark, create_bookmark, update_bookmark, delete_bookmark, archive,
    list_tags, create_tag, get_tag, delete_tag, list_bundles, create_bundle, get_bundle, update_bundle,
    delete_bundle, g]

end linkding_kernel.Theorems
