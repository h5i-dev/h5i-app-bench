import LinkdingKernel
import H5iAppLib
open Aeneas Aeneas.Std Result Aeneas.Std.WP H5iAppLib

h5i_derive_all

namespace linkding_kernel

set_option maxHeartbeats 40000000

abbrev R := core.result.Result Reply Error

def errAuth : R := .Err .Unauthenticated
def allow : R := .Ok .Allow

/-- Every command except the public shared list. Guests are refused. -/
def Mutating : Command → Prop
  | .ListShared => False
  | _ => True

theorem guest_cannot_mutate (v : View) (c : Command) (ha : v.actor = 0#u64) (hm : Mutating c) :
    transition v c ⦃ r => r = errAuth ⦄ := by
  cases c
  case ListShared => simp [Mutating] at hm
  all_goals (unfold transition authed; simp [ha, errAuth])

theorem only_owner_updates_bookmark (v : View) :
    transition v .UpdateBookmark ⦃ r =>
      r = allow → v.actor ≠ 0#u64 ∧ v.bookmark_exists = true ∧ v.bookmark_owner = v.actor ⦄ := by
  unfold transition authed owner_only can_see_own
  h5i_steps
  all_goals (simp_all [allow])

theorem only_owner_deletes_bookmark (v : View) :
    transition v .DeleteBookmark ⦃ r =>
      r = allow → v.actor ≠ 0#u64 ∧ v.bookmark_exists = true ∧ v.bookmark_owner = v.actor ⦄ := by
  unfold transition authed owner_only can_see_own
  h5i_steps
  all_goals (simp_all [allow])

theorem only_owner_archives_bookmark (v : View) :
    transition v .ArchiveBookmark ⦃ r =>
      r = allow → v.actor ≠ 0#u64 ∧ v.bookmark_exists = true ∧ v.bookmark_owner = v.actor ⦄ := by
  unfold transition authed owner_only can_see_own
  h5i_steps
  all_goals (simp_all [allow])

theorem guest_may_list_shared (v : View) (ha : v.actor = 0#u64) :
    transition v .ListShared ⦃ r => r = allow ⦄ := by
  unfold transition authed
  simp [ha, allow]

theorem guest_cannot_read_bookmark (v : View) (ha : v.actor = 0#u64) :
    transition v .ReadBookmark ⦃ r => r = errAuth ⦄ := by
  unfold transition authed
  simp [ha, errAuth]

theorem can_see_own_spec (actor owner : Std.U64) :
    can_see_own actor owner ⦃ r =>
      (r = true → actor ≠ 0#u64 ∧ actor = owner) ∧
      (actor ≠ 0#u64 → actor = owner → r = true) ∧
      (actor = 0#u64 → r = false) ⦄ := by
  unfold can_see_own
  h5i_steps

theorem can_see_shared_spec
    (actor : Std.U64) (shared owner_sharing owner_public : Bool) :
    can_see_shared actor shared owner_sharing owner_public ⦃ r =>
      (r = true → shared = true ∧ owner_sharing = true ∧
        (actor ≠ 0#u64 ∨ owner_public = true)) ∧
      (shared = true → owner_sharing = true → actor ≠ 0#u64 → r = true) ∧
      (shared = true → owner_sharing = true → actor = 0#u64 → r = owner_public) ∧
      (shared = false → r = false) ∧
      (shared = true → owner_sharing = false → r = false) ⦄ := by
  unfold can_see_shared
  h5i_steps
  all_goals simp_all

/-- An empty parse matches every bookmark. `failed` is tested first. -/
theorem empty_query_matches_all (lax : Bool) (bm : BookmarkFacts) (p : Parsed)
    (hf : p.failed = false) (he : p.empty = true) :
    bookmark_matches p lax bm ⦃ r => r = true ⦄ := by
  unfold bookmark_matches
  simp [hf, he]

/-- A failed parse matches nothing, before the node list is read. -/
theorem failed_query_matches_nothing (lax : Bool) (bm : BookmarkFacts) (p : Parsed)
    (hf : p.failed = true) :
    bookmark_matches p lax bm ⦃ r => r = false ⦄ := by
  unfold bookmark_matches
  simp [hf]

/-- A bad or zero limit becomes 100. A bad offset becomes 0. -/
theorem page_falls_back :
    (page_of true 5#u64 true 9#u64 50#u64 ⦃ p =>
      p.limit = 100#u64 ∧ p.offset = 0#u64 ∧ p.has_prev = false ⦄) ∧
    (page_of false 0#u64 false 4#u64 50#u64 ⦃ p =>
      p.limit = 100#u64 ∧ p.offset = 4#u64 ⦄) := by
  refine ⟨?_, ?_⟩ <;> (unfold page_of; h5i_steps)

/-- `has_next` is `offset + limit < count` at the boundaries the server uses.
`prev_drop_offset` is set when the previous page would start at 0. -/
theorem page_has_next_iff :
    (page_of false 10#u64 false 0#u64 11#u64 ⦃ p => p.has_next = true ∧ p.has_prev = false ⦄) ∧
    (page_of false 10#u64 false 0#u64 10#u64 ⦃ p => p.has_next = false ∧ p.has_prev = false ⦄) ∧
    (page_of false 10#u64 false 15#u64 40#u64 ⦃ p =>
      p.has_next = true ∧ p.has_prev = true ∧ p.prev_drop_offset = false ∧
        p.prev_offset = 5#u64 ⦄) ∧
    (page_of false 10#u64 false 8#u64 30#u64 ⦃ p =>
      p.has_next = true ∧ p.has_prev = true ∧ p.prev_drop_offset = true ∧
        p.prev_offset = 0#u64 ⦄) ∧
    (page_of false 10#u64 false 30#u64 30#u64 ⦃ p =>
      p.has_next = false ∧ p.has_prev = true ⦄) := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> (unfold page_of; h5i_steps)

end linkding_kernel
