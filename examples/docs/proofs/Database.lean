import Scoped
/-!
# The database invariant on PostgreSQL

`Scoped.Served` describes the tenant databases the server produces in terms
of `Lists`, `Sel` and `execAll`. Here the same requests run on a PostgreSQL
database holding every tenant's rows, in terms of the SQL the server sends:
every load is a compiled `SELECT` (`Pg.selectA`, computed by the extracted
`i5h_pgsql::select`), and every write set runs the compiled statements
(`Pg.compileA`, computed by `i5h_pgsql::compile`) of its planned table
writes. Other tenants' statements may run in between. `ts` is the schema the
server passes to `i5h_pgsql` (`schema_spec()`), `tv` the tenant's id.

`db_inv`: the tenant's rows always hold a state satisfying `Inv`, and every
full load decodes to a snapshot satisfying `Inv`. The PostgreSQL model is
`I5hLib.Pg`.
-/
open Aeneas Aeneas.Std Result docs_kernel docs_kernel.Spec I5hLib I5hLib.Sql docs_kernel.Storage
  docs_kernel.Load docs_kernel.Frame docs_kernel.Schema docs_kernel.Scoped

namespace docs_kernel.Database

/-- How the PostgreSQL driver types a value; `none` is `NULL`. -/
def valKind : Val → Option Pg.Kind
  | .Int _ => some .int
  | .Bool _ => some .bool
  | .Text _ => some .text
  | .Bytes _ => some .bytes
  | .Null => none

section
variable (ts : List Pg.Tab) (tv : Val)

/-- `R` is what the compiled `SELECT` of table `t` (with filter `f`) returns
from `db`, in some order. -/
def Selects (db : Pg.PgDb Val) (t : Nat) (f : Option (Nat × Val)) (R : List (List Val)) : Prop :=
  ∃ q ps R0, Pg.selectA valKind ts tv t f = some (q, ps) ∧ Pg.selected valKind db q ps = some R0 ∧ R.Perm R0

/-- A full load: every table. -/
def Loads (db : Pg.PgDb Val) (r : Rows) : Prop := ∀ t, t < 5 → Selects ts tv db t none (rowsOf r t)

/-- The four filtered loads of a project scope. -/
def ProjectLoads (db : Pg.PgDb Val) (p : U64) (r : Rows) : Prop :=
  Selects ts tv db Project.table (some (Project.col_id, int p.val)) (r.projects.val.map (·.val)) ∧
  Selects ts tv db Member.table (some (Member.col_project, int p.val)) (r.members.val.map (·.val)) ∧
  Selects ts tv db Document.table (some (Document.col_project, int p.val)) (r.documents.val.map (·.val)) ∧
  Selects ts tv db Webhook.table (some (Webhook.col_project, int p.val)) (r.webhooks.val.map (·.val))

/-- The databases the server produces, as `Scoped.Served`, on PostgreSQL. -/
inductive PgServed : Pg.PgDb Val → Prop
  | fresh {db : Pg.PgDb Val} :
      Pg.Matches valKind ts db → Pg.view ts tv db = (fun _ _ => none) → PgServed db
  | full {db db' : Pg.PgDb Val} {r : Rows} {snap : Snapshot} {a : Principal} {cmd : Command} {ws reply}
      {v : alloc.vec.Vec i5h_sql.Write} {qs : List (Pg.Sql × List Val)} :
      PgServed db → Loads ts tv db r → decode r = ok (some snap) →
      transition a snap cmd = .ok (.Ok (ws, reply)) → sql_writes ws = ok v →
      ((v.val.map Write.abs).map planA).mapM (Pg.compileA valKind ts tv) = some qs →
      Pg.runAll valKind db qs = some db' → PgServed db'
  | part {db db' : Pg.PgDb Val} {a : Principal} {cmd : Command} {sc : Scope}
      {rd : alloc.vec.Vec (alloc.vec.Vec Val)} {op : Option U64} {r : Rows} {snap : Snapshot} {ws reply}
      {v : alloc.vec.Vec i5h_sql.Write} {qs : List (Pg.Sql × List Val)} :
      PgServed db → (∀ s, Spec.Inv s → Stored (Pg.view ts tv db) s → Fits s) → read_scope cmd = ok sc →
      (∀ d, sc = .Document d →
        Selects ts tv db Document.table (some (Document.col_id, int d.val)) (rd.val.map (·.val))) →
      scoped_project sc rd = ok op → Selects ts tv db Counter.table none (r.counter.val.map (·.val)) →
      (op = none → NoRows r) → (∀ p, op = some p → ProjectLoads ts tv db p r) →
      decode r = ok (some snap) → transition a snap cmd = .ok (.Ok (ws, reply)) → sql_writes ws = ok v →
      ((v.val.map Write.abs).map planA).mapM (Pg.compileA valKind ts tv) = some qs →
      Pg.runAll valKind db qs = some db' → PgServed db'
  | other {db db' : Pg.PgDb Val} {tv' : Val} {ss : List (AStmt Val)} {qs : List (Pg.Sql × List Val)} :
      PgServed db → tv' ≠ tv → valKind tv' = some .int →
      ss.mapM (Pg.compileA valKind ts tv') = some qs → Pg.runAll valKind db qs = some db' → PgServed db'
end

variable {ts : List Pg.Tab} {tv : Val}

/-- A compiled `SELECT` returns what `Scoped.Sel` says. -/
theorem sel_of (hv : Pg.Valid ts) (htv : valKind tv = some .int) (hkl : Pg.klOf ts = kl) {db : Pg.PgDb Val}
    (hm : Pg.Matches valKind ts db) {t : Nat} {f : Option (Nat × Val)} {R : List (List Val)}
    (h : Selects ts tv db t f R) : Scoped.Sel (Pg.view ts tv db) t (Pg.Filter f) R := by
  obtain ⟨q, ps, R0, hq, hs, hp⟩ := h
  obtain ⟨R1, hs1, hR⟩ := Pg.select_sound valKind hv htv hm hq
  rw [hs] at hs1
  cases hs1
  have := hR R hp
  rw [hkl] at this
  exact this

theorem rowsOf_nil (r : Rows) (t : Nat) (h : 5 ≤ t) : rowsOf r t = [] := by
  obtain ⟨k, rfl⟩ := Nat.exists_eq_add_of_le' h
  simp only [rowsOf]

/-- A full load returns what `Load.Lists` says. -/
theorem lists_of (hv : Pg.Valid ts) (htv : valKind tv = some .int) (hkl : Pg.klOf ts = kl)
    (hlen : ts.length = 5) {db : Pg.PgDb Val} (hm : Pg.Matches valKind ts db) {r : Rows}
    (h : Loads ts tv db r) : Load.Lists (Pg.view ts tv db) (rowsOf r) := by
  have := Pg.lists_of_selects valKind hv htv hm (rowsOf r) (fun t ht => rowsOf_nil r t (hlen ▸ ht))
    (fun t ht => by
      obtain ⟨q, ps, R0, hq, hs, hp⟩ := h t (hlen ▸ ht)
      exact ⟨q, ps, R0, hq, hs, hp⟩)
  rw [hkl] at this
  exact this

/-- Every database `PgServed` reaches matches the schema, and the tenant's
part of it is a database `Scoped.Served` reaches. -/
theorem pg_served (hv : Pg.Valid ts) (htv : valKind tv = some .int) (hkl : Pg.klOf ts = kl)
    (hlen : ts.length = 5) {db : Pg.PgDb Val} (h : PgServed ts tv db) :
    Pg.Matches valKind ts db ∧ Scoped.Served (Pg.view ts tv db) := by
  induction h with
  | fresh hm he => exact ⟨hm, he ▸ .fresh⟩
  | full _ hl hd ht hvw hq hr ih =>
    obtain ⟨hm, hS⟩ := ih
    obtain ⟨db2, hr2, hm2, hv2, -, -⟩ := Pg.compileAll_sound valKind hv htv _ _ _ hm hq
    rw [hr] at hr2
    cases hr2
    exact ⟨hm2, hv2 ▸ .full hS (lists_of hv htv hkl hlen hm hl) hd ht hvw⟩
  | part _ hf hsc hdoc hop h3 hn hp hd ht hvw hq hr ih =>
    obtain ⟨hm, hS⟩ := ih
    obtain ⟨db2, hr2, hm2, hv2, -, -⟩ := Pg.compileAll_sound valKind hv htv _ _ _ hm hq
    rw [hr] at hr2
    cases hr2
    refine ⟨hm2, hv2 ▸ .part hS hf hsc (fun d e => sel_of hv htv hkl hm (hdoc d e)) hop
      (sel_of hv htv hkl hm h3) hn (fun p e => ?_) hd ht hvw⟩
    obtain ⟨h0, h1, h2, h4⟩ := hp p e
    exact ⟨sel_of hv htv hkl hm h0, sel_of hv htv hkl hm h1, sel_of hv htv hkl hm h2, sel_of hv htv hkl hm h4⟩
  | other _ hne htv' hq hr ih =>
    obtain ⟨hm, hS⟩ := ih
    obtain ⟨db2, hr2, hm2, -, ho, -⟩ := Pg.compileAll_sound valKind hv htv' _ _ _ hm hq
    rw [hr] at hr2
    cases hr2
    exact ⟨hm2, (ho _ (Ne.symm hne)) ▸ hS⟩

/-- The invariants hold on the database. For the schema the server passes to
`i5h_pgsql` and any tenant, every database the server produces, whichever
load path each request took and among other tenants' commits, holds a state
satisfying `Inv` (`DbInv`), and every full load decodes to a snapshot
satisfying `Inv`. -/
theorem db_inv (hv : Pg.Valid ts) (htv : valKind tv = some .int) (hkl : Pg.klOf ts = kl)
    (hlen : ts.length = 5) {db : Pg.PgDb Val} (h : PgServed ts tv db) :
    DbInv (Pg.view ts tv db) ∧
      ∀ r, Loads ts tv db r → decode r ⦃ o => ∃ snap, o = some snap ∧ Inv (Snapshot.toSt snap) ⦄ := by
  obtain ⟨hm, hS⟩ := pg_served hv htv hkl hlen h
  have hi := served_inv hS
  refine ⟨hi, fun r hr => WP.spec_mono (load_sound _ hi r (lists_of hv htv hkl hlen hm hr)) ?_⟩
  rintro o ⟨snap, rfl, hs, -⟩
  exact ⟨snap, rfl, hs⟩

end docs_kernel.Database
