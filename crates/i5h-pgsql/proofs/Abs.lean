import I5hPgsql
import I5hLib.Pg
import I5hLib.Basic
/-!
# The extracted types, read as `I5hLib.Pg`'s

Each extracted value is read as the value of the Lean model it stands for:
byte vectors as byte lists, tables and statements field by field.
-/
open Aeneas Aeneas.Std Result I5hLib

namespace i5h_pgsql

/-- A byte vector's bytes. -/
def B (v : alloc.vec.Vec U8) : List Nat := v.val.map (·.val)

def Kind.abs : Kind → Pg.Kind
  | .Int => .int
  | .Bool => .bool
  | .Text => .text
  | .Bytes => .bytes

/-- How the driver types a value; `none` is `NULL`. -/
def valKind : i5h_sql.Val → Option Pg.Kind
  | .Int _ => some .int
  | .Bool _ => some .bool
  | .Text _ => some .text
  | .Bytes _ => some .bytes
  | .Null => none

def Column.abs (c : Column) : Pg.Col := ⟨B c.name, c.kind.abs, c.nullable⟩

def Table.abs (t : Table) : Pg.Tab := ⟨B t.name, t.columns.val.map Column.abs, t.key_len.val⟩

def tabs (ts : alloc.vec.Vec Table) : List Pg.Tab := ts.val.map Table.abs

def ColDef.abs (c : ColDef) : Pg.ColDef := ⟨B c.name, c.kind.abs, c.not_null⟩

def Cond.abs : Cond → Pg.Cond
  | .Eq c p => .eq (B c) p.val
  | .Same c p => .same (B c) p.val

/-- A vector of names. -/
def Bs (v : alloc.vec.Vec (alloc.vec.Vec U8)) : List Pg.Name := v.val.map B

def Sql.abs : Sql → Pg.Sql
  | .Create t cs k => .create (B t) (cs.val.map ColDef.abs) (Bs k)
  | .Select t cs conds ord => .select (B t) (Bs cs) (conds.val.map Cond.abs) (Bs ord)
  | .Insert t cs cf up => .insert (B t) (Bs cs) (Bs cf) (Bs up)
  | .Delete t conds => .delete (B t) (conds.val.map Cond.abs)

def Query.abs (q : Query) : Pg.Sql × List i5h_sql.Val := (q.sql.abs, q.params.val)

def Stmt.abs : i5h_sql.Stmt → Sql.AStmt i5h_sql.Val
  | .Upsert t k r => .up t.val k.val r.val
  | .Delete t k => .del t.val k.val
  | .DeleteWhere t c v => .delWhere t.val c.val v

end i5h_pgsql
