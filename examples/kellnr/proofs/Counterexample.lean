import Theorems
/-!
# PR #1243, machine-checked

A read-only, non-admin user who owns crate 7 changes its ACLs in the kernel
before PR #1243, and is refused after it. Theorem (a) therefore fails for the
old code.
-/
open Aeneas Aeneas.Std Result kellnr_kernel kellnr_kernel.Spec kellnr_kernel.Theorems

namespace kellnr_kernel.Counterexample

def vec {α} (l : List α) (h : l.length ≤ Usize.max := by simp only [List.length_cons, List.length_nil]; scalar_tac) :
    alloc.vec.Vec α := alloc.vec.Vec.from l h

/-- User 1 is read-only and owns crate 7. -/
def s0 : Snapshot where
  settings := ⟨false, false⟩
  users := vec [⟨1#u64, false, true⟩]
  crates := vec [⟨7#u64, false⟩]
  versions := vec []
  owners := vec [⟨7#u64, 1#u64⟩]
  crate_users := vec []
  crate_groups := vec []
  group_members := vec []

def bySession : Principal := ⟨1#u64, .Session⟩
def byToken : Principal := ⟨1#u64, .Token⟩

theorem s0_facts : isReadOnly (Snapshot.toSt s0) 1 = true ∧ isAdmin (Snapshot.toSt s0) 1 = false := by
  decide

/-- Bug 1: a session login ignored the read-only flag. -/
theorem pre1243_session_adds_owner :
    transition_pre1243 bySession s0 (.AddOwner 7#u64 2#u64) ⦃ o =>
      ∃ ws r, o = .Ok (ws, r) ∧ ws.val = [.AddOwner ⟨7#u64, 2#u64⟩] ⦄ := by
  unfold transition_pre1243 run
  step*
  all_goals simp_all [gd, mu, userOf, own, canMod, isOwner, hasPair, s0, bySession, vec, Snapshot.toSt]

/-- Bug 2: the group endpoints skipped `check_can_modify`, even for tokens. -/
theorem pre1243_token_adds_group :
    transition_pre1243 byToken s0 (.AddCrateGroup 7#u64 3#u64) ⦃ o =>
      ∃ ws r, o = .Ok (ws, r) ∧ ws.val = [.AddCrateGroup ⟨7#u64, 3#u64⟩] ⦄ := by
  unfold transition_pre1243 run
  step*
  all_goals simp_all [gd, mu, userOf, own, canMod, isOwner, hasPair, s0, byToken, vec, Snapshot.toSt]

/-- The fixed kernel refuses both. -/
theorem fixed_refuses_session :
    transition bySession s0 (.AddOwner 7#u64 2#u64) ⦃ o => o = .Err .ReadOnlyModify ⦄ := by
  unfold transition run
  step*
  all_goals simp_all [gd, mu, userOf, canMod, s0, bySession, vec, Snapshot.toSt]

theorem fixed_refuses_group :
    transition byToken s0 (.AddCrateGroup 7#u64 3#u64) ⦃ o => o = .Err .ReadOnlyModify ⦄ := by
  unfold transition run
  step*
  all_goals simp_all [gd, mu, userOf, canMod, s0, byToken, vec, Snapshot.toSt]

/-- Theorem (a) is false for the code before PR #1243. -/
theorem pre1243_violates_read_only :
    ¬ ∀ (p : Principal) (s : Snapshot) (c : Command) ws r,
        transition_pre1243 p s c = .ok (.Ok (ws, r)) →
        isReadOnly (Snapshot.toSt s) p.user.val = true →
        isAdmin (Snapshot.toSt s) p.user.val = false → ws.val = [] := by
  intro hall
  obtain ⟨o, ho, ws, r, rfl, hws⟩ := (WP.spec_equiv_exists _ _).1 pre1243_session_adds_owner
  have := hall bySession s0 _ ws r ho s0_facts.1 s0_facts.2
  simp [hws] at this

end kellnr_kernel.Counterexample
