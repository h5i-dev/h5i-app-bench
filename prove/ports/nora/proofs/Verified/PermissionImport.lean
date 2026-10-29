import NoraKernel
import H5iAppLib

open Aeneas Aeneas.Std Result nora_kernel
namespace nora_kernel.Verified.PermissionImport
open permission_import

def rank : Verb → Nat
  | .Read => 0
  | .Write => 1
  | .Admin => 2

def narrow : Verb → Verb
  | .Read => .Read
  | .Write | .Admin => .Write

def proposed (v : Verb) (grant : Bool) : Verb :=
  if grant then narrow v else .Read

theorem stronger_spec (a b : Verb) :
    ∃ v, permission_import.stronger a b = ok v ∧ rank v = max (rank a) (rank b) := by
  cases a <;> cases b <;> simp [permission_import.stronger, rank]

theorem narrow_spec (v : Verb) : permission_import.narrow_admin v = ok (narrow v) := by
  cases v <;> rfl

theorem token_role_spec (v : Verb) (grant : Bool) :
    permission_import.token_role v grant = ok (proposed v grant) := by
  cases v <;> cases grant <;>
    simp [permission_import.token_role, permission_import.narrow_admin, proposed, narrow,
      Verb.Insts.CoreCmpPartialEqVerb.eq, Verb.read_discriminant]

theorem never_admin (v : Verb) (grant : Bool) :
    permission_import.token_role v grant ≠ ok .Admin := by
  rw [token_role_spec]
  cases v <;> cases grant <;> simp [proposed, narrow]

theorem no_write_without_opt_in (v : Verb) :
    permission_import.token_role v false = ok .Read := by
  rw [token_role_spec]
  rfl

open H5iAppLib hiding lit

def safe (grant : Bool) (tokens : alloc.vec.Vec TokenProposal) : Prop :=
  ∀ t ∈ tokens.val, t.role ≠ .Admin ∧ (grant = false → t.role = .Read)

lemma proposed_safe (v : Verb) (grant : Bool) :
    proposed v grant ≠ .Admin ∧ (grant = false → proposed v grant = .Read) := by
  cases v <;> cases grant <;> simp [proposed, narrow]

lemma push_val {α} (v w : alloc.vec.Vec α) (x : α)
    (h : alloc.vec.Vec.push v x = ok w) : w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  h5i_invert h
  simp

lemma loop_safe (grant : Bool) (users : alloc.vec.Vec Acc)
    (n w : alloc.vec.Vec Audit) (tokens : alloc.vec.Vec TokenProposal)
    (warn : Bool) (i : Usize)
    (out : alloc.vec.Vec Audit × alloc.vec.Vec Audit × alloc.vec.Vec TokenProposal × Bool)
    (hs : safe grant tokens) (hi : i.val ≤ users.val.length)
    (h : permission_import.emit_loop grant users n w tokens warn i = ok out) :
    safe grant out.2.2.1 := by
  unfold permission_import.emit_loop at h
  apply loop_idx_ok _ (fun x => x.2.2.2.2) users.val.length
    (fun x => safe grant x.2.2.1) (fun o => safe grant o.2.2.1) ?_
    (n,w,tokens,warn,i) out hs hi h
  rintro ⟨n,w,t,b,k⟩ r hs hn hr
  unfold permission_import.emit_loop.body at hr
  simp only [token_role_spec] at hr
  h5i_invert hr
  · have hk : k1.val = k.val + 1 := by have := add_ok_val hk1; scalar_tac
    refine ⟨?_, ?_, ?_⟩
    · intro tok ht
      rw [push_val _ _ _ hproposed_tokens1] at ht
      simp only [List.mem_append, List.mem_singleton] at ht
      rcases ht with ht | rfl
      · exact hs tok ht
      · exact proposed_safe acc.verb grant
    · dsimp; omega
    · simp only [alloc.vec.Vec.len] at hc
      dsimp
      scalar_tac
  · exact hs

/-- Arbitrary collected permissions emit only least-privilege token roles. -/
theorem emit_safe (c : Collected) (grant : Bool) (out : Report)
    (h : permission_import.emit c grant = ok out) : safe grant out.proposed_tokens := by
  unfold permission_import.emit at h
  h5i_invert h
  rcases x with ⟨n,w,t,b⟩
  have ht : out.proposed_tokens = t := by
    exact (congrArg Report.proposed_tokens (Result.ok_injective h)).symm
  rw [ht]
  exact loop_safe grant c.users c.narrowed (alloc.vec.Vec.new Audit)
    (alloc.vec.Vec.new TokenProposal) false 0#usize _
    (by simp [safe, alloc.vec.Vec.new]) (by simp) hx

/-- Every full mapper result denies Admin and requires opt-in for Write. -/
theorem report_safe (principals : Slice Principal) (grant : Bool) (out : Report)
    (h : permission_import.map_to_proposal principals grant = ok out) :
    ∀ t ∈ out.proposed_tokens.val, t.role ≠ .Admin ∧ (grant = false → t.role = .Read) := by
  unfold permission_import.map_to_proposal at h
  h5i_invert h
  exact emit_safe _ _ _ h

end nora_kernel.Verified.PermissionImport
