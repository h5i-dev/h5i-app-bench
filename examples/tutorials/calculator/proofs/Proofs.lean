import Spec
import I5hLib
/-!
# Proofs about the extracted calculator
-/
open Aeneas Aeneas.Std Result calculator_kernel calculator_kernel.Spec I5hLib

namespace calculator_kernel.Proofs

@[simp] theorem u64_val_eq (x y : U64) : x.val = y.val ↔ x = y :=
  ⟨fun h => by scalar_tac, fun h => h ▸ rfl⟩

/-- The Rust overflow check for `a * b`, in plain arithmetic. -/
theorem mul_check (a b : Nat) (hb : 0 < b) : (2 ^ 64 - 1) / b < a ↔ 2 ^ 64 ≤ a * b := by
  rw [Nat.div_lt_iff_lt_mul hb]; omega

@[step]
theorem compute_spec (op : Op) (a b : U64) :
    compute op a b ⦃ r => match r with
      | .Ok v => eval op a.val b.val = .ok v.val
      | .Err e => eval op a.val b.val = .error e ⦄ := by
  unfold compute
  cases op <;> simp only [eval]
  case Add =>
    step*
    · simp [U64.rMax]; scalar_tac                -- `MAX - b` does not underflow
    · simp only [U64.rMax] at *                   -- `a > MAX - b` means a + b ≥ 2^64
      rw [if_neg (by scalar_tac)]
    · simp only [U64.rMax] at *; scalar_tac       -- otherwise a + b fits
  case Sub => step*
  case Mul =>
    step*
    · rename_i hb ha                              -- `a > MAX / b` means a * b ≥ 2^64
      have hb : 0 < b.val := by simp at hb; scalar_tac
      have : (2 ^ 64 - 1) / b.val < a.val := by simp only [U64.rMax] at *; scalar_tac
      rw [if_neg (Nat.not_lt.2 ((mul_check _ _ hb).1 this))]
    · rename_i hb ha                              -- otherwise a * b fits
      have hb : 0 < b.val := by simp at hb; scalar_tac
      have : a.val ≤ (2 ^ 64 - 1) / b.val := by simp only [U64.rMax] at *; scalar_tac
      have := (Nat.le_div_iff_mul_le hb).1 this
      scalar_tac
  case Div =>
    step*
    rw [if_neg (by scalar_tac), i_post]

@[step]
theorem memory_of_spec (ms : alloc.vec.Vec Memory) (u : U64) :
    memory_of ms u ⦃ v => v.val = memOf ms.val u.val ⦄ := by
  unfold memory_of memory_of_loop
  apply WP.spec_mono (loop_search ms.val (fun m => decide (m.user = u)) (fun v : U64 => v.val)
    (fun _ m => m.value.val) 0 _ ?_ 0#usize (by simp))
  · intro r hr
    rw [hr, searchFrom_findD]
    simp [memOf]
  · intro j hj; unfold memory_of_loop.body; i5h_step

/-! ## What a command does -/

/-- The kernel never fails: no panic, overflow or bad index, for any input. -/
theorem transition_total (a : Principal) (s : Snapshot) (c : Command) :
    ∃ r, transition a s c = ok r := by
  have h : transition a s c ⦃ _ => True ⦄ := by
    unfold transition; cases c <;> step*
  obtain ⟨r, hr, -⟩ := (WP.spec_equiv_exists _ _).1 h
  exact ⟨r, hr⟩

/-- `apply` computes exactly `eval` on my memory: the new value when there is
one, the same refusal when there is not. -/
theorem apply_correct (a : Principal) (s : Snapshot) (op : Op) (arg : U64) :
    transition a s (.Apply op arg) ⦃ r => match r with
      | .Ok (w, .Value v) =>
        eval op (memOf s.memories.val a.user.val) arg.val = .ok v.val ∧ w = some ⟨a.user, v⟩
      | .Err e => eval op (memOf s.memories.val a.user.val) arg.val = .error e ⦄ := by
  unfold transition
  step with memory_of_spec as ⟨ m, hm ⟩
  step with compute_spec as ⟨ r, hr ⟩
  cases r <;> simp_all

/-- A command writes only the caller's own memory. -/
theorem writes_own_memory (a : Principal) (s : Snapshot) (c : Command) :
    transition a s c ⦃ r => ∀ w reply, r = .Ok (w, reply) → ∀ m, w = some m → m.user = a.user ⦄ := by
  unfold transition
  cases c <;> step* <;> (try split) <;> simp_all

/-! ## What committing does -/

theorem memory_clone (m : Memory) : Memory.Insts.CoreCloneClone.clone m = ok m := by
  simp [Memory.Insts.CoreCloneClone.clone]

theorem snapshot_clone (s : Snapshot) : Snapshot.Insts.CoreCloneClone.clone s = ok s := by
  simp [Snapshot.Insts.CoreCloneClone.clone, vec_clone_eq Memory.Insts.CoreCloneClone s.memories memory_clone]

theorem put_memory_spec (ms : alloc.vec.Vec Memory) (m : Memory) (hroom : ms.length < Usize.max) :
    put_memory ms m ⦃ v => v.val = upsert (·.user) m ms.val ⦄ := by
  unfold put_memory put_memory_loop
  apply WP.spec_mono (loop_search ms.val (fun q => decide (q.user = m.user))
    (fun x : alloc.vec.Vec Memory => x.val) (fun j _ => ms.val.set j m) (ms.val ++ [m]) _ ?_ 0#usize (by simp))
  · intro r hr
    rw [hr, show ((0#usize : Usize) : Nat) = 0 from rfl]
    exact upsert_loop_result (·.user) m ms.val 0 (Nat.zero_le _) (by simp)
  · intro j hj; unfold put_memory_loop.body; i5h_step

/-- Committing a write replaces (or adds) that user's row. -/
theorem apply_spec (s : Snapshot) (w : Option Memory) (hroom : s.memories.length < Usize.max) :
    apply s w ⦃ s' => s'.memories.val = match w with
      | none => s.memories.val
      | some m => upsert (·.user) m s.memories.val ⦄ := by
  unfold apply
  rw [snapshot_clone]
  cases w with
  | none => simp
  | some m => step with put_memory_spec _ m hroom; simp_all

theorem memOf_upsert_self (l : List Memory) (m : Memory) : memOf (upsert (·.user) m l) m.user.val = m.value.val := by
  induction l with
  | nil => simp [upsert, memOf]
  | cons x xs ih =>
    by_cases h : x.user = m.user
    · simp [upsert, h, memOf]
    · simp only [upsert, h, if_false]; simpa [memOf, h] using ih

/-- Any successful command either reads my memory and writes nothing, or
writes its result to my memory. -/
theorem shape (a : Principal) (s : Snapshot) (c : Command) :
    transition a s c ⦃ r => ∀ w v, r = .Ok (w, .Value v) →
      (w = none ∧ v.val = memOf s.memories.val a.user.val) ∨ w = some ⟨a.user, v⟩ ⦄ := by
  unfold transition
  cases c <;> step* <;> (try split) <;> simp_all

theorem get_spec (a : Principal) (s : Snapshot) :
    transition a s .Get ⦃ r => ∃ x, r = .Ok (none, .Value x) ∧ x.val = memOf s.memories.val a.user.val ⦄ := by
  unfold transition; step*

/-- The whole round trip: after any successful command, a `get` by the same
user returns that command's result. -/
theorem get_after (a : Principal) (s s' : Snapshot) (c : Command) (w : Option Memory) (v : U64)
    (hroom : s.memories.length < Usize.max)
    (ht : transition a s c = ok (.Ok (w, .Value v))) (hs : apply s w = ok s') :
    transition a s' .Get = ok (.Ok (none, .Value v)) := by
  have hw := post_of_ok (shape a s c) ht w v rfl
  have hs' := post_of_ok (apply_spec s w hroom) hs
  obtain ⟨r, hr⟩ := transition_total a s' .Get
  obtain ⟨x, rfl, hxv⟩ := post_of_ok (get_spec a s') hr
  rw [hr]
  have : x.val = v.val := by
    rcases hw with ⟨rfl, hv⟩ | rfl
    · simp only at hs'; rw [hxv, hs', hv]
    · simp only at hs'; rw [hxv, hs']; exact memOf_upsert_self _ ⟨a.user, v⟩
  simp [(u64_val_eq x v).1 this]

end calculator_kernel.Proofs