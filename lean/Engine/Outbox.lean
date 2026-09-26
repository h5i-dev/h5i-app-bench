/-!
# The outbox dispatcher (`i5h_pg::outbox`)

A request's transaction inserts effects into `i5h_outbox`; dispatchers send
them later. Modeled actions:

- `enqueue`: a committed request adds a row (fresh id).
- `claim`: a dispatcher leases a pending row (`FOR UPDATE SKIP LOCKED`) and
  counts an attempt.
- `unknown`: the row's destination is not in the operator's registry; the row
  is marked dead, nothing is sent.
- `send`: the dispatcher calls the registry's endpoint with key
  `(tenant, id)`; the call succeeds or fails.
- `recordOk` / `recordFail`: the result is written back; after `max`
  attempts a failing row is marked dead.
- `crash`: a dispatcher loses everything it held, at any time.
- `expire`: a lease runs out, so another dispatcher may claim the row, even
  while a slow one still holds it.

Properties, for every reachable state:
- `sent_committed`: every send comes from a row, carries its payload, and goes
  to the endpoint the registry gives its destination.
- `key_fixes_content`: sends with the same key have the same endpoint and
  payload, so a receiver that drops duplicates by key sees each effect once.
- `delivered_sent`: a row recorded as delivered was sent.
- `dead_reason`: a row is given up only for an unknown destination or after
  `max` attempts.
-/

namespace Outbox

structure Row (P : Type) where
  id : Nat
  tenant : Nat
  dest : Nat
  payload : P
  attempts : Nat
  leased : Bool
  delivered : Bool
  dead : Bool

/-- A call to an endpoint, as the receiver sees it. -/
structure Sent (E P : Type) where
  key : Nat × Nat
  endpoint : E
  payload : P

inductive Stage where
  | claimed
  | sent (ok : Bool)
  deriving DecidableEq

/-- A row a dispatcher is working on. -/
structure Held where
  worker : Nat
  id : Nat
  stage : Stage
  deriving DecidableEq

structure Sys (E P : Type) where
  next : Nat
  rows : List (Row P)
  held : List Held
  sent : List (Sent E P)

variable {E P : Type}

def Row.pending (r : Row P) : Bool := !r.delivered && !r.dead && !r.leased

def find (rows : List (Row P)) (id : Nat) : Option (Row P) := rows.find? (·.id = id)

/-- Update the row with `id`. -/
def upd (rows : List (Row P)) (id : Nat) (f : Row P → Row P) : List (Row P) :=
  rows.map fun r => if r.id = id then f r else r

section
variable (reg : Nat → Option E) (max : Nat)

inductive Step : Sys E P → Sys E P → Prop
  | enqueue {s t d p} :
      Step s { s with next := s.next + 1, rows := s.rows ++ [⟨s.next, t, d, p, 0, false, false, false⟩] }
  | claim {s w r} : r ∈ s.rows → r.pending →
      Step s { s with rows := upd s.rows r.id (fun x => { x with leased := true, attempts := x.attempts + 1 }),
                      held := s.held ++ [⟨w, r.id, .claimed⟩] }
  | unknown {s h r} : h ∈ s.held → h.stage = .claimed → find s.rows h.id = some r → reg r.dest = none →
      Step s { s with rows := upd s.rows h.id (fun x => { x with dead := true }), held := s.held.erase h }
  | send {s h r e ok} : h ∈ s.held → h.stage = .claimed → find s.rows h.id = some r → reg r.dest = some e →
      Step s { s with held := (s.held.erase h) ++ [{ h with stage := .sent ok }],
                      sent := s.sent ++ [⟨(r.tenant, r.id), e, r.payload⟩] }
  | recordOk {s h} : h ∈ s.held → h.stage = .sent true →
      Step s { s with rows := upd s.rows h.id (fun x => { x with delivered := true }), held := s.held.erase h }
  | recordFail {s h} : h ∈ s.held → h.stage = .sent false →
      Step s { s with rows := upd s.rows h.id (fun x =>
                        if max ≤ x.attempts then { x with dead := true } else { x with leased := false }),
                      held := s.held.erase h }
  | crash {s w} : Step s { s with held := s.held.filter (·.worker ≠ w) }
  | expire {s id} : Step s { s with rows := upd s.rows id (fun x => { x with leased := false }) }

inductive Reachable : Sys E P → Prop
  | init : Reachable ⟨0, [], [], []⟩
  | step {a b} : Reachable a → Step reg max a b → Reachable b
end

/-! ## Row updates keep what the proofs rely on -/

theorem mem_upd {rows : List (Row P)} {id f r} (h : r ∈ upd rows id f) :
    ∃ r₀ ∈ rows, r = (if r₀.id = id then f r₀ else r₀) := by
  simp only [upd, List.mem_map] at h
  obtain ⟨a, ha, e⟩ := h
  exact ⟨a, ha, e.symm⟩

theorem inj_of_nodup_map {α β} {f : α → β} {l : List α} (h : (l.map f).Nodup) {x y : α}
    (hx : x ∈ l) (hy : y ∈ l) (e : f x = f y) : x = y := by
  induction l with
  | nil => cases hx
  | cons a as ih =>
    simp only [List.map_cons, List.nodup_cons, List.mem_map] at h
    simp only [List.mem_cons] at hx hy
    rcases hx with rfl | hx <;> rcases hy with rfl | hy
    · rfl
    · exact absurd ⟨y, hy, e.symm⟩ h.1
    · exact absurd ⟨x, hx, e⟩ h.1
    · exact ih h.2 hx hy

theorem upd_ids (rows : List (Row P)) (id : Nat) (f : Row P → Row P) (hf : ∀ x, (f x).id = x.id) :
    (upd rows id f).map (·.id) = rows.map (·.id) := by
  simp only [upd, List.map_map]
  congr 1; funext r; simp only [Function.comp]; split <;> simp_all

/-- A row keeps its identity, destination and payload under an update. -/
def Keeps (f : Row P → Row P) : Prop :=
  ∀ x, (f x).id = x.id ∧ (f x).tenant = x.tenant ∧ (f x).dest = x.dest ∧ (f x).payload = x.payload

theorem find_upd {rows : List (Row P)} {id id' f} (hf : Keeps f) {r} (h : find (upd rows id f) id' = some r) :
    ∃ r₀, find rows id' = some r₀ ∧ r.id = r₀.id ∧ r.tenant = r₀.tenant ∧ r.dest = r₀.dest ∧
      r.payload = r₀.payload := by
  induction rows with
  | nil => simp [find, upd] at h
  | cons x xs ih =>
    simp only [find, upd, List.map_cons, List.find?_cons] at h ih ⊢
    have hx := hf x
    by_cases hxi : x.id = id
    · simp only [hxi, if_true] at h
      by_cases hk : (f x).id = id'
      · simp only [hk, decide_true] at h
        cases h
        have : x.id = id' := hx.1 ▸ hk
        simp [this, hx]
      · simp only [hk, decide_false] at h
        have : ¬ x.id = id' := fun e => hk (hx.1.trans e)
        simpa [this] using ih h
    · simp only [hxi, if_false] at h
      by_cases hk : x.id = id'
      · simp only [hk, decide_true, Option.some.injEq] at h
        subst h; simp [hk]
      · simp only [hk, decide_false] at h
        simpa [hk] using ih h

theorem find_mem {rows : List (Row P)} {id r} (h : find rows id = some r) : r ∈ rows ∧ r.id = id := by
  exact ⟨List.mem_of_find?_eq_some h, by simpa using List.find?_some h⟩

/-! ## The invariant -/

section
variable {reg : Nat → Option E} {max : Nat}

structure Good (reg : Nat → Option E) (max : Nat) (s : Sys E P) : Prop where
  ids : (s.rows.map (·.id)).Nodup
  fresh : ∀ r ∈ s.rows, r.id < s.next
  sent : ∀ m ∈ s.sent, ∃ r ∈ s.rows, m.key = (r.tenant, r.id) ∧ reg r.dest = some m.endpoint ∧
    m.payload = r.payload
  held_sent : ∀ h ∈ s.held, h.stage = .sent true → ∃ r ∈ s.rows, r.id = h.id ∧ ∃ m ∈ s.sent, m.key = (r.tenant, r.id)
  delivered : ∀ r ∈ s.rows, r.delivered → ∃ m ∈ s.sent, m.key = (r.tenant, r.id)
  dead : ∀ r ∈ s.rows, r.dead → reg r.dest = none ∨ max ≤ r.attempts

theorem good_init : Good reg max (⟨0, [], [], []⟩ : Sys E P) := by
  constructor <;> simp

/-- Rows in `upd rows id f` correspond one to one with rows of `rows`. -/
theorem mem_upd_of_mem {rows : List (Row P)} {id f r₀} (h : r₀ ∈ rows) :
    (if r₀.id = id then f r₀ else r₀) ∈ upd rows id f := by
  simp only [upd, List.mem_map]; exact ⟨r₀, h, rfl⟩

theorem good_upd {s : Sys E P} (g : Good reg max s) (id : Nat) (f : Row P → Row P) (hf : Keeps f)
    (hdel : ∀ x ∈ s.rows, x.id = id → (f x).delivered → x.delivered ∨ ∃ m ∈ s.sent, m.key = (x.tenant, x.id))
    (hdead : ∀ x ∈ s.rows, x.id = id → (f x).dead → x.dead ∨ reg x.dest = none ∨ max ≤ (f x).attempts)
    (hatt : ∀ x, x.attempts ≤ (f x).attempts)
    (held : List Held) (hh : ∀ h ∈ held, h.stage = .sent true → ∃ r ∈ s.rows, r.id = h.id ∧ ∃ m ∈ s.sent, m.key = (r.tenant, r.id)) :
    Good reg max { s with rows := upd s.rows id f, held := held } := by
  have hmap : ∀ r₀ ∈ s.rows, ∀ r, r = (if r₀.id = id then f r₀ else r₀) →
      r.id = r₀.id ∧ r.tenant = r₀.tenant ∧ r.dest = r₀.dest ∧ r.payload = r₀.payload := by
    intro r₀ _ r hr; subst hr; split
    · exact hf r₀
    · exact ⟨rfl, rfl, rfl, rfl⟩
  constructor
  · simpa [upd_ids s.rows id f (fun x => (hf x).1)] using g.ids
  · intro r hr
    obtain ⟨r₀, h₀, rfl⟩ := mem_upd hr
    rw [(hmap r₀ h₀ _ rfl).1]; exact g.fresh r₀ h₀
  · intro m hm
    obtain ⟨r₀, h₀, hk, he, hp⟩ := g.sent m hm
    obtain ⟨e1, e2, e3, e4⟩ := hmap r₀ h₀ _ rfl
    exact ⟨_, mem_upd_of_mem h₀, by rw [e1, e2]; exact hk, by rw [e3]; exact he, by rw [e4]; exact hp⟩
  · intro h hh' hst
    obtain ⟨r₀, h₀, hid, m, hm, hk⟩ := hh h hh' hst
    obtain ⟨e1, e2, -, -⟩ := hmap r₀ h₀ _ rfl
    exact ⟨_, mem_upd_of_mem h₀, by rw [e1]; exact hid, m, hm, by rw [e1, e2]; exact hk⟩
  · intro r hr hd
    obtain ⟨r₀, h₀, rfl⟩ := mem_upd hr
    obtain ⟨e1, e2, -, -⟩ := hmap r₀ h₀ _ rfl
    rw [e1, e2]
    split at hd
    · rcases hdel r₀ h₀ (by assumption) hd with h | h
      · exact g.delivered r₀ h₀ h
      · exact h
    · exact g.delivered r₀ h₀ hd
  · intro r hr hd
    obtain ⟨r₀, h₀, rfl⟩ := mem_upd hr
    obtain ⟨-, -, e3, -⟩ := hmap r₀ h₀ _ rfl
    rw [e3]
    split at hd
    · rename_i hid
      rcases hdead r₀ h₀ hid hd with h | h | h
      · rcases g.dead r₀ h₀ h with h' | h'
        · exact .inl h'
        · simp only [hid, if_true]; exact .inr (Nat.le_trans h' (hatt r₀))
      · exact .inl h
      · simp only [hid, if_true]; exact .inr h
    · rename_i hid
      simp only [hid, if_false]
      exact g.dead r₀ h₀ hd

theorem erase_sub {l : List Held} {h x : Held} (hx : x ∈ l.erase h) : x ∈ l := List.mem_of_mem_erase hx

theorem good_step {a b : Sys E P} (g : Good reg max a) (hs : Step reg max a b) : Good reg max b := by
  cases hs with
  | @enqueue t d p =>
    constructor
    · simp only [List.map_append, List.map_cons, List.map_nil]
      refine List.nodup_append.2 ⟨g.ids, by simp, ?_⟩
      intro x hx y hy hxy
      simp only [List.mem_singleton] at hy
      obtain ⟨r, hr, rfl⟩ := List.mem_map.1 hx
      have := g.fresh r hr
      omega
    · intro r hr; simp only [List.mem_append, List.mem_singleton] at hr
      rcases hr with hr | rfl
      · exact Nat.lt_succ_of_lt (g.fresh r hr)
      · exact Nat.lt_succ_self _
    · intro m hm; obtain ⟨r, hr, h⟩ := g.sent m hm; exact ⟨r, List.mem_append_left _ hr, h⟩
    · intro h hh hst; obtain ⟨r, hr, h'⟩ := g.held_sent h hh hst; exact ⟨r, List.mem_append_left _ hr, h'⟩
    · intro r hr hd; simp only [List.mem_append, List.mem_singleton] at hr
      rcases hr with hr | rfl
      · exact g.delivered r hr hd
      · simp at hd
    · intro r hr hd; simp only [List.mem_append, List.mem_singleton] at hr
      rcases hr with hr | rfl
      · exact g.dead r hr hd
      · simp at hd
  | @claim w r hr hp =>
    refine good_upd g r.id (fun x => { x with leased := true, attempts := x.attempts + 1 })
      (fun x => ⟨rfl, rfl, rfl, rfl⟩) (fun x _ _ hd => .inl hd)
      (fun x _ _ hd => .inl hd) (fun x => Nat.le_succ _) _ ?_
    intro h hh hst; simp only [List.mem_append, List.mem_singleton] at hh
    rcases hh with hh | rfl
    · exact g.held_sent h hh hst
    · simp at hst
  | @unknown h r hh hst hf hreg =>
    obtain ⟨hr, hid⟩ := find_mem hf
    refine good_upd g h.id (fun x => { x with dead := true }) (fun x => ⟨rfl, rfl, rfl, rfl⟩)
      (fun x _ _ hd => .inl hd) (fun x hx hxid _ => ?_) (fun x => Nat.le_refl _) _
      (fun h' hh' hst => g.held_sent h' (erase_sub hh') hst)
    have : x = r := inj_of_nodup_map g.ids hx hr (hxid.trans hid.symm)
    subst this; exact .inr (.inl hreg)
  | @send h r e ok hh hst hf hreg =>
    obtain ⟨hr, hid⟩ := find_mem hf
    constructor
    · exact g.ids
    · exact g.fresh
    · intro m hm; simp only [List.mem_append, List.mem_singleton] at hm
      rcases hm with hm | rfl
      · obtain ⟨r', hr', h'⟩ := g.sent m hm; exact ⟨r', hr', h'⟩
      · exact ⟨r, hr, rfl, hreg, rfl⟩
    · intro h' hh' hst'; simp only [List.mem_append, List.mem_singleton] at hh'
      rcases hh' with hh' | rfl
      · obtain ⟨r', hr', hid', m, hm, hk⟩ := g.held_sent h' (erase_sub hh') hst'
        exact ⟨r', hr', hid', m, List.mem_append_left _ hm, hk⟩
      · exact ⟨r, hr, hid, _, List.mem_append_right _ (List.mem_singleton_self _), rfl⟩
    · intro r' hr' hd; obtain ⟨m, hm, hk⟩ := g.delivered r' hr' hd
      exact ⟨m, List.mem_append_left _ hm, hk⟩
    · exact g.dead
  | @recordOk h hh hst =>
    obtain ⟨r, hr, hid, m, hm, hk⟩ := g.held_sent h hh hst
    refine good_upd g h.id (fun x => { x with delivered := true }) (fun x => ⟨rfl, rfl, rfl, rfl⟩)
      (fun x hx hxid _ => ?_) (fun x _ _ hd => .inl hd) (fun x => Nat.le_refl _) _
      (fun h' hh' hst => g.held_sent h' (erase_sub hh') hst)
    have : x = r := inj_of_nodup_map g.ids hx hr (hxid.trans hid.symm)
    subst this; exact .inr ⟨m, hm, hk⟩
  | @recordFail h hh hst =>
    refine good_upd g h.id _ (fun x => by split <;> exact ⟨rfl, rfl, rfl, rfl⟩)
      (fun x _ _ hd => by split at hd <;> exact .inl hd)
      (fun x _ _ hd => by
        split at hd
        · rename_i hm; exact .inr (.inr (by simp [hm]))
        · exact .inl hd)
      (fun x => by split <;> exact Nat.le_refl _) _ (fun h' hh' hst => g.held_sent h' (erase_sub hh') hst)
  | @crash w =>
    exact ⟨g.ids, g.fresh, g.sent, fun h hh hst => g.held_sent h (List.mem_filter.1 hh).1 hst,
      g.delivered, g.dead⟩
  | @expire id =>
    exact good_upd g id (fun x => { x with leased := false }) (fun x => ⟨rfl, rfl, rfl, rfl⟩)
      (fun x _ _ hd => .inl hd) (fun x _ _ hd => .inl hd) (fun x => Nat.le_refl _) _ g.held_sent

theorem good_reachable {s : Sys E P} (h : Reachable reg max s) : Good reg max s := by
  induction h with
  | init => exact good_init
  | step _ hs ih => exact good_step ih hs

/-! ## Main theorems -/

/-- Every send comes from a committed row, carries its payload, and goes to
the endpoint the operator's registry gives its destination. -/
theorem sent_committed {s : Sys E P} (h : Reachable reg max s) :
    ∀ m ∈ s.sent, ∃ r ∈ s.rows, m.key = (r.tenant, r.id) ∧ reg r.dest = some m.endpoint ∧ m.payload = r.payload :=
  (good_reachable h).sent

/-- A key fixes what is sent: a receiver that drops duplicate keys sees each
effect once, with the committed payload. -/
theorem key_fixes_content {s : Sys E P} (h : Reachable reg max s) :
    ∀ m ∈ s.sent, ∀ m' ∈ s.sent, m.key = m'.key → m.endpoint = m'.endpoint ∧ m.payload = m'.payload := by
  have g := good_reachable h
  intro m hm m' hm' hk
  obtain ⟨r, hr, hk1, he1, hp1⟩ := g.sent m hm
  obtain ⟨r', hr', hk2, he2, hp2⟩ := g.sent m' hm'
  have hid : r.id = r'.id := by rw [hk1, hk2] at hk; exact (Prod.mk.inj hk).2
  have : r = r' := inj_of_nodup_map g.ids hr hr' hid
  subst this
  rw [he1] at he2
  exact ⟨Option.some.inj he2, hp1.trans hp2.symm⟩

/-- A row recorded as delivered was sent. -/
theorem delivered_sent {s : Sys E P} (h : Reachable reg max s) :
    ∀ r ∈ s.rows, r.delivered → ∃ m ∈ s.sent, m.key = (r.tenant, r.id) :=
  (good_reachable h).delivered

/-- A row is given up only when its destination is not registered, or after
`max` attempts. -/
theorem dead_reason {s : Sys E P} (h : Reachable reg max s) :
    ∀ r ∈ s.rows, r.dead → reg r.dest = none ∨ max ≤ r.attempts :=
  (good_reachable h).dead

end

end Outbox
