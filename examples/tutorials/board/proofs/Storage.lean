import Apply
/-!
# What the store holds (A4)

The server stores a write set by running the planned statements of the
kernel's `sql_writes`, and loads a tenant by decoding its rows with the
kernel's `decode`. `I5hLib.Store` proves, for any schema, that the database
then holds exactly the encoding of the state `applyAll` computes. This file
instantiates it: the encoding of a state, the table writes of each write, and
that they agree with `applyWrite`.

`stored`: every database the server produces from an empty tenant reads back
exactly the rows of the state its commits computed, and loading it decodes to
that state, up to row order.
-/
open Aeneas Aeneas.Std Result board_kernel board_kernel.Spec board_kernel.Schema I5hLib I5hLib.Sql I5hLib.Store

namespace board_kernel.Storage

/-- A state's rows, table by table. -/
def enc (s : St) : Tables Val
  | 0 => s.posts.map Post.row
  | 1 => s.mods.map Moderator.row
  | 2 => [[int s.next]]
  | _ => []

/-- The table writes of one write. -/
def sqlA : Write → List (AWrite Val)
  | .PutPost p => [Post.putA p]
  | .DelPost id => [Post.delA id]
  | .PutModerator m => [Moderator.putA m]
  | .DelModerator u => [Moderator.delA u]
  | .SetCounter c => [Counter.putA c]

def app : App St Write Val where
  kl := kl
  enc := enc
  sql := sqlA
  step := applyWrite
  init := init
  IsRow := IsRow
  enc_step := by schema_step [enc, sqlA, applyWrite]
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
  unfold sql_write; cases w <;> simp only [app, sqlA, List.length_singleton] at h ⊢ <;> step* <;> simp_all

/-- The store holds what `apply` computes: every database the server produces
from an empty tenant reads back exactly the rows of the state `applyAll` gives
for its commits, and loading it decodes to that state, up to row order. -/
theorem stored {db : Db Val} {s : St} (h : Served app Snapshot.toSt db s) :
    app.Holds db (enc s) ∧
      ∀ r, Lists kl db (Rows.tabs r) → decode r ⦃ o => ∃ snap, o = some snap ∧ app.Equiv (Snapshot.toSt snap) s ⦄ :=
  Schema.stored fits sql_fits h

end board_kernel.Storage
