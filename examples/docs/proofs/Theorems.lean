import Spec
/-!
# Main theorems, about the extracted kernel

Each theorem quantifies over every actor and every command, so a faulty JSON
decoder cannot produce a command these theorems do not cover.
-/
open Aeneas Aeneas.Std docs_kernel docs_kernel.Spec

namespace docs_kernel.Theorems

/-- The kernel's permission table is the spec's. -/
theorem allows_eq (r : Role) (a : Action) : allows r a = .ok (policy r a) := by
  cases r <;> cases a <;> rfl

/-- No input makes the kernel fail: no panic, overflow, or bad index. -/
theorem transition_total (a : Principal) (s : Snapshot) (c : Command) :
    ∃ r, transition a s c = .ok r := by
  sorry

/-- `apply` computes the list semantics of a write set, as long as no vector
overflows `usize`. -/
theorem apply_eq (s : Snapshot) (ws : alloc.vec.Vec Write)
    (h : s.projects.length + s.members.length + s.documents.length + ws.length < Usize.max) :
    ∃ s', apply s ws = .ok s' ∧ Snapshot.toSt s' = applyAll (Snapshot.toSt s) ws.val := by
  sorry

/-- Every write of a successful transition is permitted by the policy. -/
theorem authorized (a : Principal) (s : Snapshot) (c : Command) ws r
    (hinv : Inv (Snapshot.toSt s)) (h : transition a s c = .ok (.Ok (ws, r))) :
    ∀ w ∈ ws.val, writeAllowed (Snapshot.toSt s) a.user.val w := by
  sorry

/-- Replies contain only documents the caller may read. -/
theorem reply_confined (a : Principal) (s : Snapshot) (c : Command) ws r
    (h : transition a s c = .ok (.Ok (ws, r))) :
    replyAllowed (Snapshot.toSt s) a.user.val r := by
  sorry

/-- Successful transitions preserve the invariants. -/
theorem inv_preserved (a : Principal) (s : Snapshot) (c : Command) ws r
    (hinv : Inv (Snapshot.toSt s)) (h : transition a s c = .ok (.Ok (ws, r))) :
    Inv (applyAll (Snapshot.toSt s) ws.val) := by
  sorry

theorem init_inv : Inv init := by
  constructor <;> simp [init]

/-- Every state the database can reach satisfies the invariants. -/
theorem reachable_inv {s : St} (h : Reachable s) : Inv s := by
  induction h with
  | init => exact init_inv
  | step _ ht ih => exact inv_preserved _ _ _ _ _ ih ht

/-- A user's result depends only on what that user may see. In particular,
error codes do not reveal hidden documents. -/
theorem noninterference (a : Principal) (s₁ s₂ : Snapshot) (c : Command)
    (h₁ : Inv (Snapshot.toSt s₁)) (h₂ : Inv (Snapshot.toSt s₂))
    (hv : view (Snapshot.toSt s₁) a.user.val = view (Snapshot.toSt s₂) a.user.val) :
    transition a s₁ c = transition a s₂ c := by
  sorry

end docs_kernel.Theorems
