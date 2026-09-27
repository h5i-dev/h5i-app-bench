import Apply
/-!
# What the store holds

The server stores a write set by running the planned statements of the
kernel's `sql_writes`, and loads the registry by decoding its rows with the
kernel's `decode`. `I5hLib.Store` proves, for any schema, that the database
then holds exactly the encoding of the state `applyAll` computes; this file
gives the registry's encoding and table writes. Deleting a crate deletes its
rows in the child tables by column value, which the store runs as a `SELECT`
and keyed deletes.
-/
open Aeneas Aeneas.Std Result cratesio_kernel cratesio_kernel.Spec cratesio_kernel.Schema I5hLib I5hLib.Sql I5hLib.Store

namespace cratesio_kernel.Storage

/-- A state's rows, table by table. -/
def enc (s : St) : Tables Val
  | 0 => s.users.map User.row
  | 1 => s.sessions.map Session.row
  | 2 => s.tokens.map Token.row
  | 3 => s.crates.map Krate.row
  | 4 => s.versions.map Version.row
  | 5 => s.owners.map Owner.row
  | 6 => s.invites.map Invite.row
  | 7 => s.deps.map Dep.row
  | 8 => [Counter.row s.counter]
  | _ => []

/-- The table writes of one write. -/
def sqlA : Write → List (AWrite Val)
  | .PutUser x => [User.putA x]
  | .PutSession x => [Session.putA x]
  | .PutToken x => [Token.putA x]
  | .PutCrate x => [Krate.putA x]
  | .PutVersion x => [Version.putA x]
  | .PutOwner x => [Owner.putA x]
  | .DelOwner x => [Owner.delA x.krate x.owner x.team]
  | .PutInvite x => [Invite.putA x]
  | .DelInvite k u => [Invite.delA k u]
  | .PutDep x => [Dep.putA x]
  | .DelCrate k => [Krate.delA k, Version.delWhereA 0 (int k.val), Owner.delWhereA 0 (int k.val),
      Invite.delWhereA 0 (int k.val), Dep.delWhereA 0 (int k.val)]
  | .SetCounter c => [Counter.putA c]

set_option maxHeartbeats 2000000 in
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
  unfold sql_write; cases w <;> simp only [app, sqlA, List.length_singleton, List.length_cons] at h ⊢ <;>
    step* <;> simp_all [KRATE] <;> omega

/-- The store holds what `apply` computes: every database the server produces
from an empty registry reads back exactly the rows of the state `applyAll`
gives for its commits, and loading it decodes to that state, up to row order. -/
theorem stored {db : Db Val} {s : St} (h : Served app Snapshot.toSt db s) :
    app.Holds db (enc s) ∧
      ∀ r, Lists kl db (Rows.tabs r) → decode r ⦃ o => ∃ snap, o = some snap ∧ app.Equiv (Snapshot.toSt snap) s ⦄ :=
  Schema.stored fits sql_fits h

end cratesio_kernel.Storage
