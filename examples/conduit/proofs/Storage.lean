import Apply
/-!
# What the store holds

The server stores a write set by running the planned statements of the
kernel's `sql_writes`, and loads the site by decoding its rows with the
kernel's `decode`. `I5hLib.Store` proves, for any schema, that the database
then holds exactly the encoding of the state `applyAll` computes; this file
gives Conduit's encoding and table writes. The cascades are deletes by
column value, which the store runs as a `SELECT` and keyed deletes.
-/
open Aeneas Aeneas.Std Result conduit_kernel conduit_kernel.Spec conduit_kernel.Schema I5hLib I5hLib.Sql I5hLib.Store

namespace conduit_kernel.Storage

/-- A state's rows, table by table. -/
def enc (s : St) : Tables Val
  | 0 => s.users.map User.row
  | 1 => s.follows.map Follow.row
  | 2 => s.articles.map Article.row
  | 3 => s.tags.map Tag.row
  | 4 => s.favs.map Favorite.row
  | 5 => s.comments.map Comment.row
  | 6 => [[int s.lastUser, int s.lastArticle, int s.lastComment]]
  | _ => []

/-- The table writes of one write. -/
def sqlA : Write → List (AWrite Val)
  | .PutUser x => [User.putA x]
  | .PutFollow f => [Follow.putA f]
  | .DelFollow f => [Follow.delA f.follower f.followed]
  | .PutArticle a => [Article.putA a]
  | .DelArticle id => [Article.delA id]
  | .PutTag t => [Tag.putA t]
  | .DelTagsOf id => [Tag.delWhereA 0 (int id.val)]
  | .PutFavorite f => [Favorite.putA f]
  | .DelFavorite f => [Favorite.delA f.article f.user]
  | .DelFavoritesOf id => [Favorite.delWhereA 0 (int id.val)]
  | .PutComment c => [Comment.putA c]
  | .DelComment id => [Comment.delA id]
  | .DelCommentsOf id => [Comment.delWhereA 1 (int id.val)]
  | .SetCounter c => [Counter.putA c]

set_option maxHeartbeats 1000000 in
theorem enc_step : ∀ s w, applyAllW kl (enc s) (sqlA w) = enc (applyWrite s w) := by
  schema_step [enc, sqlA, applyWrite]

def app : App St Write Val where
  kl := kl
  enc := enc
  sql := sqlA
  step := applyWrite
  init := init
  IsRow := IsRow
  enc_step := enc_step
  sql_ok := by schema_ok [sqlA]
  init_ok := by schema_init [enc, init]
  init_rows := by schema_rows [enc, init]

theorem fits : Fits app Snapshot.toSt where
  kl := rfl
  rows := rfl
  enc s := by funext t; cases_table t <;> rfl
  init := by funext t; cases_table t <;> rfl
  nil s t h := by cases_table t <;> first | omega | rfl

theorem sql_fits : SqlFits app := by
  intro w out h
  unfold sql_write; cases w <;> simp only [app, sqlA, List.length_singleton] at h ⊢ <;> step* <;>
    simp_all [TAG_ARTICLE, FAVORITE_ARTICLE, COMMENT_ARTICLE]

/-- The store holds what `apply` computes: every database the server produces
from an empty site reads back exactly the rows of the state `applyAll` gives
for its commits, and loading it decodes to that state, up to row order. -/
theorem stored {db : Db Val} {s : St} (h : Served app Snapshot.toSt db s) :
    app.Holds db (enc s) ∧
      ∀ r, Lists kl db (Rows.tabs r) → decode r ⦃ o => ∃ snap, o = some snap ∧ app.Equiv (Snapshot.toSt snap) s ⦄ :=
  Schema.stored fits sql_fits h

end conduit_kernel.Storage
