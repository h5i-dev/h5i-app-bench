import Lemmas
/-! Specs for the non-loop helpers of `transition`. -/
open Aeneas Aeneas.Std Result docs_kernel docs_kernel.Spec

namespace docs_kernel.TransitionLemmas

@[step]
theorem status_eq_spec (x y : Status) :
    Status.Insts.CoreCmpPartialEqStatus.eq x y ⦃ b => b = true ↔ x = y ⦄ := by
  cases x <;> cases y <;> simp [Status.Insts.CoreCmpPartialEqStatus.eq, Status.read_discriminant]

@[step]
theorem role_ne_spec (x y : Role) :
    core.cmp.PartialEq.ne.trait_default Role.Insts.CoreCmpPartialEqRole x y ⦃ b => b = true ↔ x ≠ y ⦄ := by
  unfold core.cmp.PartialEq.ne.trait_default core.cmp.PartialEq.ne.default
  cases x <;> cases y <;> simp [Role.Insts.CoreCmpPartialEqRole.eq, Role.read_discriminant]

@[step]
theorem status_ne_spec (x y : Status) :
    core.cmp.PartialEq.ne.trait_default Status.Insts.CoreCmpPartialEqStatus x y ⦃ b => b = true ↔ x ≠ y ⦄ := by
  unfold core.cmp.PartialEq.ne.trait_default core.cmp.PartialEq.ne.default
  cases x <;> cases y <;> simp [Status.Insts.CoreCmpPartialEqStatus.eq, Status.read_discriminant]

@[step]
theorem one_spec (w : Write) : one w ⦃ v => v.val = [w] ⦄ := by
  unfold one
  step*

@[step]
theorem vec_u8_clone_spec (v : alloc.vec.Vec U8) :
    alloc.vec.CloneVec.clone core.clone.CloneU8 v ⦃ v' => v' = v ⦄ := by
  unfold alloc.vec.CloneVec.clone
  step*
  subst_vars; rfl

/-- `authorized_doc` as a list function: hidden and missing documents both
give `NotFound`. -/
def authDoc (s : St) (u id : Nat) (a : Action) : core.result.Result Document Error :=
  match findDoc s.docs id with
  | none => .Err .NotFound
  | some d =>
    if allowed s u d.project.val .Read then
      if allowed s u d.project.val a then .Ok d else .Err .Forbidden
    else .Err .NotFound

theorem findDoc_some {ds : List Document} {id : Nat} {d : Document} (h : findDoc ds id = some d) :
    d ∈ ds ∧ d.id.val = id := by
  unfold findDoc at h
  exact ⟨List.mem_of_find?_eq_some h, by simpa using List.find?_some h⟩

theorem authDoc_ok {s : St} {u id : Nat} {a : Action} {d : Document} (h : authDoc s u id a = .Ok d) :
    findDoc s.docs id = some d ∧ allowed s u d.project.val .Read ∧ allowed s u d.project.val a := by
  unfold authDoc at h
  split at h
  · cases h
  · rename_i d' hd
    split at h <;> [split at h; cases h] <;> cases h
    exact ⟨hd, by assumption, by assumption⟩

@[step]
theorem authorized_doc_spec (s : Snapshot) (u id : U64) (a : Action) :
    authorized_doc s u id a ⦃ r => r = authDoc (Snapshot.toSt s) u.val id.val a ⦄ := by
  unfold authorized_doc
  step as ⟨o, ho⟩
  simp only [authDoc, Snapshot.toSt, ← ho]
  cases o <;> step* <;> simp_all [Snapshot.toSt]

@[step]
theorem fresh_id_spec (s : Snapshot) :
    fresh_id s ⦃ r => match r with
      | .Err e => e = .Overflow ∧ s.counter.next_id.val = U64.max
      | .Ok (id, c) => id = s.counter.next_id ∧ c.next_id.val = s.counter.next_id.val + 1 ⦄ := by
  unfold fresh_id
  step*
  all_goals (simp_all [U64.rMax, U64.max_eq]; try scalar_tac)

@[step]
theorem with_status_spec (d : Document) (st : Status) (ap : Option U64) :
    with_status d st ap ⦃ r =>
      (d.version.val = U64.max ∧ r = .Err .Overflow) ∨
      (∃ v : U64, v.val = d.version.val + 1 ∧
        r = .Ok { d with status := st, approver := ap, version := v }) ⦄ := by
  unfold with_status
  step*
  all_goals (simp_all [U64.rMax, U64.max_eq]; try scalar_tac)

/-- Lift a property of successful results to a postcondition. -/
def OnOk (P : alloc.vec.Vec Write → Reply → Prop) : core.result.Result (alloc.vec.Vec Write × Reply) Error → Prop
  | .Ok (ws, r) => P ws r
  | .Err _ => True

theorem of_spec {a s c P} (hs : transition a s c ⦃ OnOk P ⦄) {ws r}
    (h : transition a s c = .ok (.Ok (ws, r))) : P ws r := by
  obtain ⟨o, ho, hp⟩ := (WP.spec_equiv_exists _ _).1 hs
  rw [h, Result.ok.injEq] at ho
  subst ho
  exact hp

/-- Only owners may approve or manage, and owners may also write. -/
theorem allowed_write_of {s : St} {u p : Nat} {a : Action}
    (ha : a = .Approve ∨ a = .Manage) (h : allowed s u p a) : allowed s u p .Write := by
  unfold allowed at *
  split at h <;> rename_i r _ <;> [cases r <;> rcases ha with rfl | rfl <;> simp_all [policy]; simp at h]

/-- Symbolically execute `transition`, leaving one goal per path. -/
macro "walk" : tactic => `(tactic| (
  unfold transition
  split <;> step* <;> (repeat' (first | step | split | simp only [WP.spec_ok, bind_tc_ok, bind_ok]))
  all_goals (try (rename_i v _; cases v))
  all_goals (try (first | dsimp only | (split; dsimp only)))
  all_goals (repeat' (first | step | split | simp only [WP.spec_ok, bind_tc_ok, bind_ok]))))

end docs_kernel.TransitionLemmas
