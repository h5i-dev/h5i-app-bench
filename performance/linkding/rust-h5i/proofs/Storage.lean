import Apply
/-!
# What the store holds

The server writes with the kernel's `sql_writes` and loads with `decode`.
`H5iAppLib.Store` proves for any schema that the database then holds the
encoding of `applyAll`; this file supplies linkding's encoding and table
writes.
-/
open Aeneas Aeneas.Std Result linkding_kernel linkding_kernel.Spec linkding_kernel.Schema H5iAppLib H5iAppLib.Sql H5iAppLib.Store

namespace linkding_kernel.Storage

/-- A state's rows, table by table. -/
def enc (s : St) : Tables Val
  | 0 => s.users.map User.row
  | 1 => s.tokens.map Token.row
  | 2 => s.bookmarks.map Bookmark.row
  | 3 => s.tags.map Tag.row
  | 4 => s.links.map Link.row
  | 5 => s.bundles.map Bundle.row
  | 6 => [[int s.lastBookmark, int s.lastTag, int s.lastBundle]]
  | _ => []

/-- The table writes of one write. -/
def sqlA : Write → List (AWrite Val)
  | .PutBookmark x => [Bookmark.putA x]
  | .DelBookmark o a id => [Bookmark.delA o a id]
  | .PutTag t => [Tag.putA t]
  | .DelTag id => [Tag.delA id]
  | .PutLink l => [Link.putA l]
  | .DelLinksOf id => [Link.delWhereA 0 (int id.val)]
  | .DelLinksTo id => [Link.delWhereA 1 (int id.val)]
  | .PutBundle b => [Bundle.putA b]
  | .DelBundle id => [Bundle.delA id]
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
    simp_all [LINK_BOOKMARK, LINK_TAG]

/-- The store holds what `apply` computes: every database the server produces
from an empty site reads back exactly the rows of the state `applyAll` gives
for its commits, and loading it decodes to that state, up to row order. -/
theorem stored {db : Db Val} {s : St} (h : Served app Snapshot.toSt db s) :
    app.Holds db (enc s) ∧
      ∀ r, Lists kl db (Rows.tabs r) → decode r ⦃ o => ∃ snap, o = some snap ∧ app.Equiv (Snapshot.toSt snap) s ⦄ :=
  Schema.stored fits sql_fits h

end linkding_kernel.Storage
