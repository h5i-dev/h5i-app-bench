import Load
import Frame
/-!
# Scoped loads (A4 with partial snapshots)

`DocsStore::load_for` loads the counter plus one project's rows with
`WHERE column = value` queries, picks the project with the kernel's
`scoped_project`, and decodes with `decode`. We prove the result is
`Frame.slice snap sc` for a full snapshot `snap` that the tenant's rows hold
and that satisfies `Inv`. With `transition_frame` and `store_sound`, running
a command on the scoped load and storing its writes keeps `DbInv`.
-/
open Aeneas Aeneas.Std Result docs_kernel docs_kernel.Spec I5hLib I5hLib.Sql docs_kernel.Storage
  docs_kernel.Load docs_kernel.Frame docs_kernel.Schema

namespace docs_kernel.Scoped

open Classical

/-- Trusted (a tenant-filtered `SELECT ... WHERE`): the loader returns every
stored row of table `t` satisfying `Q`, once. -/
def Sel (db : Db Val) (t : Nat) (Q : List Val → Prop) (R : List (List Val)) : Prop :=
  R.Nodup ∧ ∀ row, row ∈ R ↔ db t (row.take (kl t)) = some row ∧ Q row

/-- Column `i` holds `v`. -/
def ColIs (i : Nat) (v : Val) (row : List Val) : Prop := row[i]? = some v

/-- Each table fits in a `Vec` (at most `usize::MAX` rows). -/
def Fits (s : St) : Prop :=
  s.projects.length ≤ Usize.max ∧ s.members.length ≤ Usize.max ∧
  s.docs.length ≤ Usize.max ∧ s.webhooks.length ≤ Usize.max

theorem sel_perm (db : Db Val) (s : St) (c : Bool) (hi : Inv s) (hdb : db = readBack kl (encC c s))
    (t : Nat) (Q : List Val → Prop) (R : List (List Val)) (h : Sel db t Q R) :
    R.Perm ((encC c s t).filter (fun r => decide (Q r))) := by
  have hk := (wellKeyedC c s hi t).1
  rw [List.perm_ext_iff_of_nodup h.1 ((List.Nodup.of_map _ hk).filter _)]
  intro row
  rw [h.2, hdb, List.mem_filter]
  simp only [readBack, decide_eq_true_eq]
  rw [find_key_iff (fun r : List Val => r.take (kl t)) (encC c s t) hk _ row]
  simp

/-- Rows of one table selected by `Q` decode to a reordering of the kernel
rows selected by `F`, when `Q` on an encoded row is `F`. -/
theorem sel_decoded {α : Type} (f : α → List Val) (hf : Function.Injective f) (l : List α)
    (F : α → Bool) (Q : List Val → Prop) (hQ : ∀ x, Q (f x) ↔ F x = true)
    (R : List (List Val)) (h : R.Perm ((l.map f).filter (fun r => decide (Q r)))) :
    ∃ l' : List α, R = l'.map f ∧ l'.Perm (l.filter F) := by
  have e : (l.map f).filter (fun r => decide (Q r)) = (l.filter F).map f := by
    rw [List.filter_map]
    congr 1
    apply List.filter_congr
    intro x _
    simp [hQ x]
  rw [e] at h
  exact perm_of_map_inj f hf R _ h

/-- Put back the unselected rows: the result reorders `l`, and selecting
from it gives exactly the loaded rows. -/
theorem restore {α : Type} (l l' : List α) (F : α → Bool) (h : l'.Perm (l.filter F)) :
    (l' ++ l.filter (fun x => !F x)).Perm l ∧ (l' ++ l.filter (fun x => !F x)).filter F = l' := by
  refine ⟨(h.append_right _).trans (List.filter_append_perm F l), ?_⟩
  rw [List.filter_append, List.filter_filter]
  have h1 : l'.filter F = l' := List.filter_eq_self.2 (fun x hx => by
    have := h.subset hx; simp only [List.mem_filter] at this; exact this.2)
  have h2 : l.filter (fun x => F x && !F x) = [] := by simp
  rw [h1, h2, List.append_nil]

/-- Loading the counter plus the rows each table's filter selects decodes to
that filter applied to a full snapshot the rows hold. -/
theorem decode_filtered (db : Db Val) (s : St) (c : Bool) (hi : Inv s) (hdb : db = readBack kl (encC c s))
    (hc : c = false → s.next = 0) (hb : s.next < 2 ^ 64) (hf : Fits s) (r : Rows)
    (h3 : Sel db 3 (fun _ => True) (r.counter.val.map (·.val)))
    (Fp : Project → Bool) (Qp : List Val → Prop) (hQp : ∀ x, Qp (Project.row x) ↔ Fp x = true)
    (h0 : Sel db 0 Qp (r.projects.val.map (·.val)))
    (Fm : Member → Bool) (Qm : List Val → Prop) (hQm : ∀ x, Qm (Member.row x) ↔ Fm x = true)
    (h1 : Sel db 1 Qm (r.members.val.map (·.val)))
    (Fd : Document → Bool) (Qd : List Val → Prop) (hQd : ∀ x, Qd (Document.row x) ↔ Fd x = true)
    (h2 : Sel db 2 Qd (r.documents.val.map (·.val)))
    (Fw : Webhook → Bool) (Qw : List Val → Prop) (hQw : ∀ x, Qw (Webhook.row x) ↔ Fw x = true)
    (h4 : Sel db 4 Qw (r.webhooks.val.map (·.val))) :
    decode r ⦃ o => ∃ snap : Snapshot, Equiv s (Snapshot.toSt snap) ∧
      o = some (⟨snap.counter, filterV Fp snap.projects, filterV Fm snap.members,
        filterV Fd snap.documents, filterV Fw snap.webhooks⟩ : Snapshot) ⦄ := by
  have h3' : (r.counter.val.map (·.val)).Perm (if c then [counterRow s.next] else []) := by
    simpa [encC] using sel_perm db s c hi hdb 3 _ _ h3
  obtain ⟨lp, ep, pp⟩ := sel_decoded _ Project.row_inj s.projects Fp Qp hQp _
    (by simpa [encC, enc] using sel_perm db s c hi hdb 0 _ _ h0)
  obtain ⟨lm, em, pm⟩ := sel_decoded _ Member.row_inj s.members Fm Qm hQm _
    (by simpa [encC, enc] using sel_perm db s c hi hdb 1 _ _ h1)
  obtain ⟨ld, ed, pd⟩ := sel_decoded _ Document.row_inj s.docs Fd Qd hQd _
    (by simpa [encC, enc] using sel_perm db s c hi hdb 2 _ _ h2)
  obtain ⟨lw, ew, pw⟩ := sel_decoded _ Webhook.row_inj s.webhooks Fw Qw hQw _
    (by simpa [encC, enc] using sel_perm db s c hi hdb 4 _ _ h4)
  apply WP.spec_mono (decode_lists r s c hc hb h3' lp ep lm em ld ed lw ew)
  rintro o ⟨d, rfl, hk, hvp, hvm, hvd, hvw⟩
  obtain ⟨rp1, rp2⟩ := restore _ _ _ pp
  obtain ⟨rm1, rm2⟩ := restore _ _ _ pm
  obtain ⟨rd1, rd2⟩ := restore _ _ _ pd
  obtain ⟨rw1, rw2⟩ := restore _ _ _ pw
  let snap : Snapshot :=
    { counter := d.counter
      projects := alloc.vec.Vec.from _ (by rw [rp1.length_eq]; exact hf.1)
      members := alloc.vec.Vec.from _ (by rw [rm1.length_eq]; exact hf.2.1)
      documents := alloc.vec.Vec.from _ (by rw [rd1.length_eq]; exact hf.2.2.1)
      webhooks := alloc.vec.Vec.from _ (by rw [rw1.length_eq]; exact hf.2.2.2) }
  have e : Equiv s (Snapshot.toSt snap) :=
    ⟨hk, by simpa [snap, Snapshot.toSt] using rp1, by simpa [snap, Snapshot.toSt] using rm1,
      by simpa [snap, Snapshot.toSt] using rd1, by simpa [snap, Snapshot.toSt] using rw1⟩
  refine ⟨snap, e, ?_⟩
  obtain ⟨dc, dp, dm, dd, dw⟩ := d
  simp only at hvp hvm hvd hvw
  simp only [Option.some.injEq, Snapshot.mk.injEq]
  refine ⟨rfl, alloc.vec.Vec.ext _ _ ?_, alloc.vec.Vec.ext _ _ ?_, alloc.vec.Vec.ext _ _ ?_,
    alloc.vec.Vec.ext _ _ ?_⟩ <;> simp [snap, alloc.vec.Vec.from_val, *]

theorem col_proj (p : U64) (x : Project) : ColIs 0 (int p.val) (Project.row x) ↔ decide (x.id.val = p.val) = true := by
  simp [ColIs, Project.row, int_u64]
theorem col_member (p : U64) (x : Member) : ColIs 0 (int p.val) (Member.row x) ↔ decide (x.project.val = p.val) = true := by
  simp [ColIs, Member.row, int_u64]
theorem col_doc (p : U64) (x : Document) : ColIs 1 (int p.val) (Document.row x) ↔ decide (x.project.val = p.val) = true := by
  simp [ColIs, Document.row, int_u64]
theorem col_hook (p : U64) (x : Webhook) : ColIs 0 (int p.val) (Webhook.row x) ↔ decide (x.project.val = p.val) = true := by
  simp [ColIs, Webhook.row, int_u64]
theorem col_doc_id (d : U64) (x : Document) : ColIs 0 (int d.val) (Document.row x) ↔ decide (x.id.val = d.val) = true := by
  simp [ColIs, Document.row, int_u64]

theorem sel_empty (db : Db Val) (t : Nat) : Sel db t (fun _ => False) [] := by simp [Sel]

/-- The four `WHERE ... = p` queries of a project scope. -/
def ProjectRows (db : Db Val) (p : U64) (r : Rows) : Prop :=
  Sel db 0 (ColIs 0 (int p.val)) (r.projects.val.map (·.val)) ∧
  Sel db 1 (ColIs 0 (int p.val)) (r.members.val.map (·.val)) ∧
  Sel db 2 (ColIs 1 (int p.val)) (r.documents.val.map (·.val)) ∧
  Sel db 4 (ColIs 0 (int p.val)) (r.webhooks.val.map (·.val))

def NoRows (r : Rows) : Prop :=
  r.projects.val = [] ∧ r.members.val = [] ∧ r.documents.val = [] ∧ r.webhooks.val = []

theorem load_keep (db : Db Val) (s : St) (c : Bool) (hi : Inv s) (hdb : db = readBack kl (encC c s))
    (hc : c = false → s.next = 0) (hb : s.next < 2 ^ 64) (hf : Fits s) (r : Rows)
    (h3 : Sel db 3 (fun _ => True) (r.counter.val.map (·.val))) (p : U64) (hp : ProjectRows db p r) :
    decode r ⦃ o => ∃ snap : Snapshot, Equiv s (Snapshot.toSt snap) ∧ o = some (keep p.val snap) ⦄ :=
  decode_filtered db s c hi hdb hc hb hf r h3 _ _ (col_proj p) hp.1 _ _ (col_member p) hp.2.1
    _ _ (col_doc p) hp.2.2.1 _ _ (col_hook p) hp.2.2.2

theorem load_counter (db : Db Val) (s : St) (c : Bool) (hi : Inv s) (hdb : db = readBack kl (encC c s))
    (hc : c = false → s.next = 0) (hb : s.next < 2 ^ 64) (hf : Fits s) (r : Rows)
    (h3 : Sel db 3 (fun _ => True) (r.counter.val.map (·.val))) (hn : NoRows r) :
    decode r ⦃ o => ∃ snap : Snapshot, Equiv s (Snapshot.toSt snap) ∧ o = some (counterOnly snap) ⦄ := by
  obtain ⟨h0, h1, h2, h4⟩ := hn
  exact decode_filtered db s c hi hdb hc hb hf r h3 (fun _ => false) (fun _ => False) (by simp)
    (by rw [h0]; exact sel_empty _ _) (fun _ => false) (fun _ => False) (by simp) (by rw [h1]; exact sel_empty _ _)
    (fun _ => false) (fun _ => False) (by simp) (by rw [h2]; exact sel_empty _ _)
    (fun _ => false) (fun _ => False) (by simp) (by rw [h4]; exact sel_empty _ _)

theorem doc_ids_nodup (l : List Document) (h : (l.map (·.id)).Nodup) : (l.map (fun x => x.id.val)).Nodup := by
  have e : l.map (fun x => x.id.val) = (l.map (·.id)).map (·.val) := by simp
  rw [e]
  exact h.map (fun a b hab => (u64_val_eq a b).1 hab)

theorem findDoc_equiv (s : St) (hi : Inv s) (snap : Snapshot) (e : Equiv s (Snapshot.toSt snap))
    (d : Nat) (doc : Document) :
    findDoc snap.documents.val d = some doc ↔ doc ∈ s.docs ∧ doc.id.val = d := by
  have hn := doc_ids_nodup _ (inv_equiv e hi).doc_keys
  simp only [Snapshot.toSt] at hn
  rw [findDoc, find_key_iff (fun x : Document => x.id.val) _ hn d doc]
  have := e.docs
  simp only [Snapshot.toSt] at this
  rw [this.mem_iff]

/-- A scoped load: the counter, the rows of the document the command names
(if any), then the four queries of the project `scoped_project` picks. The
result is `slice snap sc` for a snapshot `snap` the tenant's rows hold. -/
theorem scoped_sound (db : Db Val) (s : St) (c : Bool) (hi : Inv s) (hdb : db = readBack kl (encC c s))
    (hc : c = false → s.next = 0) (hb : s.next < 2 ^ 64) (hf : Fits s) (sc : Scope)
    (rd : alloc.vec.Vec (alloc.vec.Vec Val))
    (hd : ∀ d, sc = .Document d → Sel db 2 (ColIs 0 (int d.val)) (rd.val.map (·.val))) :
    scoped_project sc rd ⦃ op => ∀ r : Rows, Sel db 3 (fun _ => True) (r.counter.val.map (·.val)) →
      (op = none → NoRows r) → (∀ p, op = some p → ProjectRows db p r) →
      decode r ⦃ o => ∃ snap : Snapshot, Equiv s (Snapshot.toSt snap) ∧ o = some (slice snap sc) ⦄ ⦄ := by
  cases sc with
  | Counter =>
    simp only [scoped_project, WP.spec_ok]
    intro r h3 hn _
    exact load_counter db s c hi hdb hc hb hf r h3 (hn trivial)
  | Project p =>
    simp only [scoped_project, WP.spec_ok]
    intro r h3 _ hp
    exact load_keep db s c hi hdb hc hb hf r h3 p (hp p rfl)
  | Document d =>
    obtain ⟨ld, ed, pd⟩ := sel_decoded _ Document.row_inj s.docs (fun x => decide (x.id.val = d.val)) _
      (col_doc_id d) _ (by simpa [encC, enc] using sel_perm db s c hi hdb 2 _ _ (hd d rfl))
    unfold scoped_project
    step with document_from_rows rd ld ed as ⟨ o, v, ho, hv ⟩
    subst ho
    simp only
    split
    · rename_i hlen
      step as ⟨ doc, hdoc ⟩
      intro r h3 _ hp
      have hmem : doc ∈ s.docs ∧ doc.id.val = d.val := by
        have : doc ∈ ld := by rw [hdoc, ← hv]; exact List.getElem_mem _
        have := pd.subset this
        simpa using this
      apply WP.spec_mono (load_keep db s c hi hdb hc hb hf r h3 doc.project (hp _ rfl))
      rintro o ⟨snap, e, rfl⟩
      refine ⟨snap, e, ?_⟩
      simp only [slice, (findDoc_equiv s hi snap e d.val doc).2 hmem]
    · rename_i hlen
      simp only [WP.spec_ok]
      intro r h3 hn _
      have hnil : ld = [] := by
        have : o.val.length = 0 := by scalar_tac
        rw [← hv]; exact List.eq_nil_of_length_eq_zero this
      apply WP.spec_mono (load_counter db s c hi hdb hc hb hf r h3 (hn trivial))
      rintro o ⟨snap, e, rfl⟩
      refine ⟨snap, e, ?_⟩
      have : findDoc snap.documents.val d.val = none := by
        cases h : findDoc snap.documents.val d.val with
        | none => rfl
        | some doc =>
          have hm := (findDoc_equiv s hi snap e d.val doc).1 h
          have : doc ∈ s.docs.filter (fun x => decide (x.id.val = d.val)) := by simpa using hm
          rw [← pd.mem_iff, hnil] at this
          cases this
      simp only [slice, this]

/-- End to end, for the server's scoped path: load the counter, the named
document's rows, and the rows of the project `scoped_project` picks; decode;
run the command; store its writes. If the tenant's rows held a state
satisfying `Inv`, they still do. -/
theorem scoped_command (db : Db Val) (s : St) (hi : Inv s) (hs : Stored db s) (hf : Fits s)
    (a : Principal) (cmd : Command) (sc : Scope) (hsc : read_scope cmd = ok sc)
    (rd : alloc.vec.Vec (alloc.vec.Vec Val))
    (hd : ∀ d, sc = .Document d → Sel db 2 (ColIs 0 (int d.val)) (rd.val.map (·.val)))
    (op : Option U64) (hop : scoped_project sc rd = ok op)
    (r : Rows) (h3 : Sel db 3 (fun _ => True) (r.counter.val.map (·.val)))
    (hn : op = none → NoRows r) (hp : ∀ p, op = some p → ProjectRows db p r)
    (snap' : Snapshot) (hdec : decode r = ok (some snap')) ws reply
    (ht : transition a snap' cmd = .ok (.Ok (ws, reply))) :
    sql_writes ws ⦃ v => DbInv (execAll db ((v.val.map Write.abs).map planA)) ⦄ := by
  obtain ⟨c, hc, hb, hdb⟩ := hs
  have h1 := post_of_ok (scoped_sound db s c hi hdb hc hb hf sc rd hd) hop r h3 hn hp
  obtain ⟨snap, e, hsnap⟩ := post_of_ok h1 hdec
  cases hsnap
  have hi' := inv_equiv e hi
  rw [transition_frame a snap cmd hi' sc hsc] at ht
  exact store_sound db snap hi' (stored_equiv e hi ⟨c, hc, hb, hdb⟩) a cmd ws reply ht

end docs_kernel.Scoped
