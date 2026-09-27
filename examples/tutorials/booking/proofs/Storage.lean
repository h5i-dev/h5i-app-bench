import Apply
/-!
# What the store holds

The server stores a write set by running the planned statements of the
kernel's `sql_writes`, and loads a tenant by decoding its rows with the
kernel's `decode`. `I5hLib.Store` proves, for any schema, that the database
then holds exactly the encoding of the state `applyAll` computes; this file
gives the booking service's encoding and table writes. Effects make no table
write: they go to the outbox.
-/
open Aeneas Aeneas.Std Result booking_kernel booking_kernel.Spec booking_kernel.Schema I5hLib I5hLib.Sql I5hLib.Store

namespace booking_kernel.Storage

/-- A state's rows, table by table. -/
def enc (s : St) : Tables Val
  | 0 => s.admins.map Admin.row
  | 1 => s.rooms.map Room.row
  | 2 => s.bookings.map Booking.row
  | 3 => [[int s.next]]
  | _ => []

/-- The table writes of one write. -/
def sqlA : Write → List (AWrite Val)
  | .PutAdmin x => [Admin.putA x]
  | .PutRoom x => [Room.putA x]
  | .PutBooking x => [Booking.putA x]
  | .DelBooking id => [Booking.delA id]
  | .SetCounter c => [Counter.putA c]
  | .Emit _ => []

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

end booking_kernel.Storage
