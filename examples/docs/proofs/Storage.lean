import Spec
import I5hLib
/-!
# What the store writes (A4)

The server stores a write set by running `i5h_sql::plan` on the kernel's own
`sql_writes`. We prove:

- `sql_writes_spec`: the extracted `sql_writes` computes `sqlA` on each write.
- `encode_applyAll`: applying those table writes to the rows of a state gives
  the rows of `applyAll`, the state every other theorem talks about.
- `stored`: running the planned statements on a database that holds a valid
  state leaves exactly the rows of the new state.

`I5hLib.Sql` gives statements their PostgreSQL meaning (trusted), and the
`i5h-sql` proofs show the extracted `plan` computes `planA`.
-/
open Aeneas Aeneas.Std Result docs_kernel docs_kernel.Spec I5hLib I5hLib.Sql

namespace docs_kernel.Storage

abbrev Val := i5h_sql.Val

/-- A `u64` column: its bits as a `BIGINT`. -/
def int (n : Nat) : Val := .Int ⟨BitVec.ofNat _ n⟩

def roleV : Role → Val
  | .Viewer => .Int 0#i64
  | .Editor => .Int 1#i64
  | .Owner => .Int 2#i64

def statusV : Status → Val
  | .Draft => .Int 0#i64
  | .InReview => .Int 1#i64
  | .Approved => .Int 2#i64
  | .Published => .Int 3#i64

def optV : Option U64 → Val
  | some x => int x.val
  | none => .Null

/-! ## Rows, key columns first (tables numbered as declared in `schema!`) -/

def projRow (p : Project) : List Val := [int p.id.val, .Bytes p.name]
def memberRow (m : Member) : List Val := [int m.project.val, int m.user.val, roleV m.role]
def docRow (d : Document) : List Val :=
  [int d.id.val, int d.project.val, int d.author.val, .Bytes d.title, .Bytes d.body,
    statusV d.status, optV d.approver, int d.version.val]
def counterRow (n : Nat) : List Val := [int n]
def hookRow (h : Webhook) : List Val := [int h.project.val, int h.dest.val]

/-- Key length per table. -/
def kl : Nat → Nat
  | 0 => 1 | 1 => 2 | 2 => 1 | 3 => 0 | 4 => 1 | _ => 0

/-- The rows a state is stored as. -/
def enc (s : St) : Tables Val
  | 0 => s.projects.map projRow
  | 1 => s.members.map memberRow
  | 2 => s.docs.map docRow
  | 3 => [counterRow s.next]
  | 4 => s.webhooks.map hookRow
  | _ => []

/-- The table write for one kernel write; effects go to the outbox instead. -/
def sqlA : Write → Option (AWrite Val)
  | .PutProject p => some (.put 0 1 (projRow p))
  | .PutMember m => some (.put 1 2 (memberRow m))
  | .DelMember p u => some (.del 1 [int p.val, int u.val])
  | .PutDocument d => some (.put 2 1 (docRow d))
  | .DelDocument i => some (.del 2 [int i.val])
  | .SetCounter c => some (.put 3 0 (counterRow c.next_id.val))
  | .PutWebhook h => some (.put 4 1 (hookRow h))
  | .DelWebhook p => some (.del 4 [int p.val])
  | .Emit _ => none

/-! ## Keys are encoded injectively -/

theorem int_inj {a b : Nat} (ha : a < 2 ^ 64) (hb : b < 2 ^ 64) (h : int a = int b) : a = b := by
  simp only [int, i5h_sql.Val.Int.injEq, IScalar.mk.injEq] at h
  have := congrArg BitVec.toNat h
  simp only [BitVec.toNat_ofNat] at this
  rwa [Nat.mod_eq_of_lt (by simpa using ha), Nat.mod_eq_of_lt (by simpa using hb)] at this

@[simp] theorem u64_val_eq (x y : U64) : x.val = y.val ↔ x = y :=
  ⟨fun h => by scalar_tac, fun h => h ▸ rfl⟩

theorem int_u64 (x y : U64) : int x.val = int y.val ↔ x = y := by
  refine ⟨fun h => ?_, fun h => h ▸ rfl⟩
  have := int_inj (by scalar_tac) (by scalar_tac) h
  scalar_tac

/-! ## Row writes commute with encoding -/

theorem map_upsert {α β κ : Type} [DecidableEq κ] {_ : DecidableEq (List β)} (key : α → κ)
    (f : α → List β) (n : Nat) (x : α) (l : List α)
    (h : ∀ y, (f y).take n = (f x).take n ↔ key y = key x) :
    (upsert key x l).map f = upsert (·.take n) (f x) (l.map f) := by
  induction l with
  | nil => rfl
  | cons y ys ih =>
    by_cases hk : key y = key x
    · simp [upsert, hk, (h y).2 hk]
    · have : ¬ (f y).take n = (f x).take n := fun e => hk ((h y).1 e)
      simp [upsert, hk, this, ih]

theorem map_filter {α β : Type} {_ : DecidableEq (List β)} (q : α → Bool) (f : α → List β)
    (n : Nat) (k : List β) (l : List α) (h : ∀ y, q y = !decide ((f y).take n = k)) :
    (l.filter q).map f = (l.map f).filter (fun r => ¬ r.take n = k) := by
  rw [List.filter_map]
  congr 1
  apply List.filter_congr
  intro y _
  simp [h y]

theorem encode_step (s : St) (w : Write) :
    enc (applyWrite s w) = match sqlA w with
      | some a => applyW kl (enc s) a
      | none => enc s := by
  funext t
  cases w with
  | PutProject p =>
    simp only [sqlA, applyW, applyWrite]
    split
    · subst_vars
      exact map_upsert _ _ 1 _ _ (fun y => by simp [projRow, int_u64])
    · rename_i ht; rcases t with _ | _ | _ | _ | _ | t <;> simp_all [enc]
  | PutMember m =>
    simp only [sqlA, applyW, applyWrite]
    split
    · subst_vars
      exact map_upsert _ _ 2 _ _ (fun y => by simp [memberRow, int_u64])
    · rename_i ht; rcases t with _ | _ | _ | _ | _ | t <;> simp_all [enc]
  | DelMember p u =>
    simp only [sqlA, applyW, applyWrite]
    split
    · subst_vars
      exact map_filter _ _ 2 _ _ (fun y => by simp [memberRow, int_u64])
    · rename_i ht; rcases t with _ | _ | _ | _ | _ | t <;> simp_all [enc]
  | PutDocument d =>
    simp only [sqlA, applyW, applyWrite]
    split
    · subst_vars
      exact map_upsert _ _ 1 _ _ (fun y => by simp [docRow, int_u64])
    · rename_i ht; rcases t with _ | _ | _ | _ | _ | t <;> simp_all [enc]
  | DelDocument i =>
    simp only [sqlA, applyW, applyWrite]
    split
    · subst_vars
      exact map_filter _ _ 1 _ _ (fun y => by simp [docRow, int_u64])
    · rename_i ht; rcases t with _ | _ | _ | _ | _ | t <;> simp_all [enc]
  | SetCounter c =>
    simp only [sqlA, applyW, applyWrite]
    split
    · subst_vars; simp [enc, upsert, kl]
    · rename_i ht; rcases t with _ | _ | _ | _ | _ | t <;> simp_all [enc]
  | PutWebhook h =>
    simp only [sqlA, applyW, applyWrite]
    split
    · subst_vars
      exact map_upsert _ _ 1 _ _ (fun y => by simp [hookRow, int_u64])
    · rename_i ht; rcases t with _ | _ | _ | _ | _ | t <;> simp_all [enc]
  | DelWebhook p =>
    simp only [sqlA, applyW, applyWrite]
    split
    · subst_vars
      exact map_filter _ _ 1 _ _ (fun y => by simp [hookRow, int_u64])
    · rename_i ht; rcases t with _ | _ | _ | _ | _ | t <;> simp_all [enc]
  | Emit e => simp [sqlA, applyWrite]

/-- The table writes of a write set turn the rows of `s` into the rows of
`applyAll s ws`. No invariant needed. -/
theorem encode_applyAll (s : St) (ws : List Write) :
    enc (applyAll s ws) = applyAllW kl (enc s) (ws.filterMap sqlA) := by
  induction ws generalizing s with
  | nil => rfl
  | cons w ws ih =>
    simp only [applyAll, List.foldl_cons] at ih ⊢
    rw [ih, List.filterMap_cons]
    have := encode_step s w
    split <;> rename_i h <;> simp only [h] at this <;> simp [applyAllW, this]

/-! ## Valid states are well keyed -/

theorem nodup_keys {α κ : Type} (l : List α) (key : α → List Val) (id : α → κ)
    (hid : ∀ x y, key x = key y → id x = id y) (h : (l.map id).Nodup) : (l.map key).Nodup := by
  induction l with
  | nil => simp
  | cons x xs ih =>
    simp only [List.map_cons, List.nodup_cons, List.mem_map] at h ⊢
    exact ⟨fun ⟨y, hy, e⟩ => h.1 ⟨y, hy, hid _ _ e⟩, ih h.2⟩

theorem wellKeyed (s : St) (h : Inv s) : WellKeyed kl (enc s) := by
  intro t
  rcases t with _ | _ | _ | _ | _ | t
  · refine ⟨?_, by simp [enc, kl, projRow]⟩
    simp only [enc, kl, List.map_map]
    exact nodup_keys _ _ (·.id) (fun x y e => by simpa [projRow, int_u64] using e) h.proj_keys
  · refine ⟨?_, by simp [enc, kl, memberRow]⟩
    simp only [enc, kl, List.map_map]
    exact nodup_keys _ _ (fun m => (m.project, m.user))
      (fun x y e => by simp [memberRow, int_u64] at e; simp [e]) h.member_keys
  · refine ⟨?_, by simp [enc, kl, docRow]⟩
    simp only [enc, kl, List.map_map]
    exact nodup_keys _ _ (·.id) (fun x y e => by simpa [docRow, int_u64] using e) h.doc_keys
  · simp [enc, kl, counterRow]
  · refine ⟨?_, by simp [enc, kl, hookRow]⟩
    simp only [enc, kl, List.map_map]
    exact nodup_keys _ _ (·.project) (fun x y e => by simpa [hookRow, int_u64] using e) h.hook_keys
  · simp [enc]

theorem writeOk (w : Write) (a : AWrite Val) (h : sqlA w = some a) : WriteOk kl a := by
  cases w <;> simp only [sqlA, Option.some.injEq, reduceCtorEq] at h
  all_goals (subst h; simp [WriteOk, kl, projRow, memberRow, docRow, counterRow, hookRow])

/-- Storing a write set: if the tenant's rows hold a valid state `s`, running
the planned statements leaves exactly the rows of `applyAll s ws`. -/
theorem stored (s : St) (ws : List Write) (h : Inv s) :
    execAll (readBack kl (enc s)) ((ws.filterMap sqlA).map planA) = readBack kl (enc (applyAll s ws)) := by
  rw [encode_applyAll]
  refine (plan_sound kl _ _ (wellKeyed s h) ?_).1.symm
  intro a ha
  obtain ⟨w, _, hw⟩ := List.mem_filterMap.1 ha
  exact writeOk w a hw


/-! ## The extracted encoder computes `sqlA` -/

def Write.abs : i5h_sql.Write → AWrite Val
  | .Put t n row => .put t.val n.val row.val
  | .Del t k => .del t.val k.val

theorem u64_to_val_eq (x : U64) : U64.Insts.I5h_sqlColumn.to_val x = ok (int x.val) := by
  unfold U64.Insts.I5h_sqlColumn.to_val int
  simp only [lift, UScalar.hcast]
  rw [← UScalar.bv_toNat, BitVec.ofNat_toNat]
  simp [BitVec.zeroExtend]

@[step]
theorem u64_to_val (x : U64) : U64.Insts.I5h_sqlColumn.to_val x ⦃ v => v = int x.val ⦄ := by
  simp [u64_to_val_eq]

theorem u8vec_clone (v : alloc.vec.Vec U8) : alloc.vec.CloneVec.clone core.clone.CloneU8 v = ok v :=
  vec_clone_eq _ v (fun _ => rfl)

@[step]
theorem bytes_to_val (v : alloc.vec.Vec U8) :
    alloc.vec.VecU8.Insts.I5h_sqlColumn.to_val v ⦃ x => x = .Bytes v ⦄ := by
  simp [alloc.vec.VecU8.Insts.I5h_sqlColumn.to_val, u8vec_clone]

@[step]
theorem role_to_val (r : Role) : Role.Insts.I5h_sqlColumn.to_val r ⦃ x => x = roleV r ⦄ := by
  cases r <;> simp [Role.Insts.I5h_sqlColumn.to_val, roleV]

@[step]
theorem status_to_val (r : Status) : Status.Insts.I5h_sqlColumn.to_val r ⦃ x => x = statusV r ⦄ := by
  cases r <;> simp [Status.Insts.I5h_sqlColumn.to_val, statusV]

@[step]
theorem opt_to_val (o : Option U64) :
    core.option.Option.Insts.I5h_sqlColumn.to_val U64.Insts.I5h_sqlColumn o ⦃ x => x = optV o ⦄ := by
  cases o with
  | none => simp [core.option.Option.Insts.I5h_sqlColumn.to_val, optV]
  | some x => simpa [core.option.Option.Insts.I5h_sqlColumn.to_val, optV] using u64_to_val x

@[step] theorem project_row (p : Project) : Project.to_row p ⦃ v => v.val = projRow p ⦄ := by
  unfold Project.to_row; step* <;> simp_all [projRow]
@[step] theorem member_row (m : Member) : Member.to_row m ⦃ v => v.val = memberRow m ⦄ := by
  unfold Member.to_row; step* <;> simp_all [memberRow]
@[step] theorem document_row (d : Document) : Document.to_row d ⦃ v => v.val = docRow d ⦄ := by
  have := usize_max_le
  unfold Document.to_row; step* <;> simp_all [docRow] <;> scalar_tac
@[step] theorem counter_row (c : Counter) : Counter.to_row c ⦃ v => v.val = counterRow c.next_id.val ⦄ := by
  unfold Counter.to_row; step* <;> simp_all [counterRow]
@[step] theorem webhook_row (h : Webhook) : Webhook.to_row h ⦃ v => v.val = hookRow h ⦄ := by
  unfold Webhook.to_row; step* <;> simp_all [hookRow]

@[step] theorem key1_spec (a : U64) : key1 a ⦃ v => v.val = [int a.val] ⦄ := by
  unfold key1; step* <;> simp_all
@[step] theorem key2_spec (a b : U64) : key2 a b ⦃ v => v.val = [int a.val, int b.val] ⦄ := by
  unfold key2; step* <;> simp_all

@[step]
theorem sql_write_spec (w : Write) : sql_write w ⦃ o => o.map Write.abs = sqlA w ⦄ := by
  unfold sql_write put
  simp only [Project.TABLE, Project.KEY_LEN, Member.TABLE, Member.KEY_LEN, Document.TABLE,
    Document.KEY_LEN, Counter.TABLE, Counter.KEY_LEN, Webhook.TABLE, Webhook.KEY_LEN]
  cases w <;> simp only <;> step* <;> simp_all [Write.abs, sqlA]


theorem filterMap_fold (l : List Write) (acc : List (AWrite Val)) :
    l.foldl (fun acc w => match sqlA w with | some a => acc ++ [a] | none => acc) acc =
      acc ++ l.filterMap sqlA := by
  induction l generalizing acc with
  | nil => simp
  | cons w ws ih => cases h : sqlA w <;> simp [h, ih, List.filterMap_cons]

@[step]
theorem sql_writes_spec (ws : alloc.vec.Vec Write) :
    sql_writes ws ⦃ v => v.val.map Write.abs = ws.val.filterMap sqlA ⦄ := by
  unfold sql_writes sql_writes_loop
  apply WP.spec_mono (loop_fold ws.val (fun v : alloc.vec.Vec i5h_sql.Write => v.val.map Write.abs)
    (fun acc w => match sqlA w with | some a => acc ++ [a] | none => acc)
    (fun v k => v.length ≤ k) (fun x => sql_writes_loop.body ws x.1 x.2) ?_ _ 0#usize (by simp) (by simp))
  · intro r hr; rw [hr, filterMap_fold]; simp
  · intro o j hj ho; have := ws.len_ineq; unfold sql_writes_loop.body; i5h_step
    · refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
      rw [← o_post]
    · refine ⟨by scalar_tac, ?_⟩
      rw [← o_post]

/-- End to end, on the extracted encoder: if the tenant's rows hold a valid
state, running the plan of `sql_writes ws` leaves exactly the rows of
`applyAll s ws`. Valid means `Inv`, which holds in every reachable state
(`reachable_inv`). -/
theorem sql_writes_stored (s : St) (h : Inv s) (ws : alloc.vec.Vec Write) :
    sql_writes ws ⦃ v =>
      execAll (readBack kl (enc s)) ((v.val.map Write.abs).map planA) =
        readBack kl (enc (applyAll s ws.val)) ⦄ := by
  apply WP.spec_mono (sql_writes_spec ws)
  intro v hv
  rw [hv]
  exact stored s ws.val h

end docs_kernel.Storage
