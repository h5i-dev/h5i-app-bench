import Proofs
/-!
# What the store holds

The server stores a write set by running the planned statements of the
kernel's `sql_writes`, and loads a tenant by decoding its rows with the
kernel's `decode`. `I5hLib.Store` proves, for any schema, that the database
then holds exactly what committing the writes computes; here the state is the
list of memories and a write is at most one memory.
-/
open Aeneas Aeneas.Std Result calculator_kernel calculator_kernel.Schema I5hLib I5hLib.Sql I5hLib.Store

namespace calculator_kernel.Storage

/-- The memories' rows. -/
def enc (l : List Memory) : Tables Val
  | 0 => l.map Memory.row
  | _ => []

/-- The table writes of a write set. -/
def sqlA : Option Memory → List (AWrite Val)
  | none => []
  | some m => [Memory.putA m]

/-- What committing a write set does to the memories, as `apply_spec` says. -/
def step (l : List Memory) : Option Memory → List Memory
  | none => l
  | some m => upsert (·.user) m l

def app : App (List Memory) (Option Memory) Val where
  kl := kl
  enc := enc
  sql := sqlA
  step := step
  init := []
  IsRow := IsRow
  enc_step := by schema_step [enc, sqlA, step]
  sql_ok := by schema_ok [sqlA]
  init_ok := by schema_init [enc]
  init_rows := by schema_rows [enc]

theorem fits : Fits app (fun s => s.memories.val) where
  kl := rfl
  rows := rfl
  enc s := by funext t; cases_table t <;> rfl
  init := by funext t; cases_table t <;> rfl
  nil s t h := by cases_table t <;> first | omega | rfl

theorem sql_writes_spec (w : Option Memory) : sql_writes w ⦃ v => v.val.map sqlW = sqlA w ⦄ := by
  unfold sql_writes; cases w <;> step* <;> simp_all [sqlA]

/-- The databases the server produces from an empty tenant, and the memories
each holds. Each request loads the rows (the trusted `SELECT`, `Lists`),
decodes them, and stores the command's write by running the plan of
`sql_writes`. -/
inductive Served : Db Val → List Memory → Prop
  | fresh : Served (fun _ _ => none) []
  | commit {db db' : Db Val} {l : List Memory} {r : Rows} {snap : Snapshot} {w : Option Memory}
      {v : alloc.vec.Vec i5h_sql.Write} :
      Served db l → Lists kl db (Rows.tabs r) → decode r = ok (some snap) → sql_writes w = ok v →
      Runs kl db ((v.val.map sqlW).map planA) db' → Served db' (step snap.memories.val w)

theorem served_app {db : Db Val} {l : List Memory} (h : Served db l) : app.Served db l := by
  induction h with
  | fresh => exact .fresh
  | @commit db db' l r snap w v _ hl hd hv hr ih =>
    obtain ⟨snap', he, hq⟩ := post_of_ok (loaded fits ih _ hl) hd
    cases he
    have e : (v.val.map sqlW).map planA = (app.sqlAll [w]).map planA := by
      rw [post_of_ok (sql_writes_spec w) hv]; simp [App.sqlAll, app]
    rw [e] at hr
    exact .commit (ws := [w]) ih hq hr

/-- The store holds what `apply` computes: every database the server produces
reads back exactly the rows of the memories its commits computed, and loading
it decodes to those memories, up to row order. -/
theorem stored {db : Db Val} {l : List Memory} (h : Served db l) :
    app.Holds db (enc l) ∧
      ∀ r, Lists kl db (Rows.tabs r) → decode r ⦃ o => ∃ snap, o = some snap ∧ app.Equiv snap.memories.val l ⦄ :=
  ⟨(app.served_holds (served_app h)).1, loaded fits (served_app h)⟩

end calculator_kernel.Storage
