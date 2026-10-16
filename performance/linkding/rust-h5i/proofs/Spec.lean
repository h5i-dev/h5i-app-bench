import LinkdingKernel
import H5iAppLib
/-!
# What linkding's state is

The state as lists, and what a write does to it. The kernel's `apply`
computes `applyAll` (`Apply.lean`), and the store holds what it computes
(`Storage.lean`).
-/
open Aeneas Aeneas.Std linkding_kernel

namespace linkding_kernel.Spec

abbrev Text := alloc.vec.Vec U8

/-- The state as lists; the counters are the last ids handed out. -/
structure St where
  lastBookmark : Nat
  lastTag : Nat
  lastBundle : Nat
  users : List User
  tokens : List Token
  bookmarks : List Bookmark
  tags : List Tag
  links : List Link
  bundles : List Bundle

def Snapshot.toSt (s : Snapshot) : St :=
  ⟨s.counter.last_bookmark.val, s.counter.last_tag.val, s.counter.last_bundle.val,
    s.users.val, s.tokens.val, s.bookmarks.val, s.tags.val, s.links.val, s.bundles.val⟩

/-! ## What a write does

`H5iAppLib.upsert` replaces the row with the same key, or appends it. The
kernel never writes users or tokens. -/

def applyWrite (s : St) : Write → St
  | .PutBookmark b => { s with bookmarks := H5iAppLib.upsert (fun b => (b.owner, b.added, b.id)) b s.bookmarks }
  | .DelBookmark o a id =>
    { s with bookmarks := s.bookmarks.filter (fun b => ¬(b.owner = o ∧ b.added = a ∧ b.id = id)) }
  | .PutTag t => { s with tags := H5iAppLib.upsert (·.id) t s.tags }
  | .DelTag id => { s with tags := s.tags.filter (·.id ≠ id) }
  | .PutLink l => { s with links := H5iAppLib.upsert (fun l => (l.bookmark, l.tag)) l s.links }
  | .DelLinksOf id => { s with links := s.links.filter (·.bookmark ≠ id) }
  | .DelLinksTo id => { s with links := s.links.filter (·.tag ≠ id) }
  | .PutBundle b => { s with bundles := H5iAppLib.upsert (·.id) b s.bundles }
  | .DelBundle id => { s with bundles := s.bundles.filter (·.id ≠ id) }
  | .SetCounter c => { s with lastBookmark := c.last_bookmark.val, lastTag := c.last_tag.val,
                              lastBundle := c.last_bundle.val }

def applyAll (s : St) (ws : List Write) : St := ws.foldl applyWrite s

def init : St := ⟨0, 0, 0, [], [], [], [], [], []⟩

end linkding_kernel.Spec
