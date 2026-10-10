import Spec
import H5iAppLib
/-! A checked counterexample to TASK.md's unrestricted totality claim.
The input bucket has the maximum permitted vector length. An applicable
deny statement reaches resource construction, which appends `/` and fails.
-/
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit

namespace rustfs_kernel.Counterexample

def emptyBytes : alloc.vec.Vec U8 := alloc.vec.Vec.new U8

def fullBucket : alloc.vec.Vec U8 :=
  alloc.vec.Vec.from (List.replicate Usize.max 0#u8) (by simp)

def action : acts.Action := ⟨.None, emptyBytes⟩

def args : stmts.BucketPolicyArgs :=
  ⟨emptyBytes, action, fullBucket, alloc.vec.Vec.new _, false, emptyBytes⟩

def functions : condfuncs.Functions :=
  ⟨alloc.vec.Vec.new _, alloc.vec.Vec.new _, alloc.vec.Vec.new _⟩

def statement : stmts.BPStatement :=
  ⟨.Deny, ⟨vecOf [emptyBytes], alloc.vec.Vec.new _⟩,
   alloc.vec.Vec.new _, alloc.vec.Vec.new _, alloc.vec.Vec.new _,
   alloc.vec.Vec.new _, functions⟩

def statements : Slice stmts.BPStatement := (vecOf [statement]).slice

@[simp] theorem deref_slice {T : Type} (v : alloc.vec.Vec T) :
    alloc.vec.Vec.deref v = v.slice := by
  apply Slice.ext
  simp [alloc.vec.Vec.deref, alloc.vec.Vec.val]

@[simp] theorem empty_len {T : Type} : (alloc.vec.Vec.new T).slice.len = 0#usize := by
  simp only [Slice.len, alloc.vec.Vec.new, alloc.vec.Vec.from,
    Slice.from_val, List.length_nil]
  scalar_tac

@[simp] theorem empty_vec_len {T : Type} : alloc.vec.Vec.len (alloc.vec.Vec.new T) = 0#usize := by
  simp only [alloc.vec.Vec.len, alloc.vec.Vec.new, alloc.vec.Vec.from_val, List.length_nil]
  scalar_tac

theorem push_full : alloc.vec.Vec.push fullBucket 47#u8 = fail .maximumSizeExceeded := by
  unfold alloc.vec.Vec.push
  have h : U32.max ≤ Usize.max := by
    rw [U32.max_eq]
    exact usize_max_ge
  simp [fullBucket, show ¬ Usize.max + 1 ≤ U32.max from by omega]

theorem copy_bytes (s : Slice U8) :
    alloc.slice.Slice.to_vec core.clone.CloneU8 s = ok ⟨s⟩ := by
  apply eq_ok_of_spec
  apply Aeneas.Std.WP.spec_mono (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 s (by intros; rfl))
  intro v hv
  cases v
  simp_all

theorem build_fails (flag : Bool) :
    stmts.build_resource action fullBucket.slice emptyBytes.slice flag = fail .maximumSizeExceeded := by
  simp [stmts.build_resource, stmts.is_list_bucket, action,
    acts.Family.Insts.CoreCmpPartialEqFamily.eq, acts.Family.read_discriminant,
    emptyBytes, copy_bytes, alloc.vec.Vec.deref, alloc.vec.Vec.from, Slice.len]
  exact push_full

theorem principal_matches :
    stmts.principal_is_match statement.principal emptyBytes.slice = ok true := by
  unfold stmts.principal_is_match
  have h : stmts.any_simple_match (vecOf [emptyBytes]).slice emptyBytes.slice = ok true := by
    unfold stmts.any_simple_match stmts.any_simple_match_loop
    rw [loop]
    simp [stmts.any_simple_match_loop.body, wildmatch.is_simple_match,
      wildmatch.inner_match, emptyBytes, vecOf, alloc.vec.Vec.deref, Slice.index_usize,
      alloc.vec.Vec.from, alloc.vec.Vec.val, Slice.len]
    have hz (hp : 0 < 2 ^ UScalarTy.Usize.numBits) : Usize.ofNatCore 0 hp = 0#usize := by scalar_tac
    simp [hz]
  change (do
    let b ← stmts.any_simple_match (alloc.vec.Vec.deref (vecOf [emptyBytes])) emptyBytes.slice
    if b then ok true else stmts.any_simple_match _ _) = ok true
  simp [h]

theorem covers_empty :
    acts.statement_covers (alloc.vec.Vec.new acts.Action).slice
      (alloc.vec.Vec.new acts.Action).slice action true = ok true := by
  have h : acts.set_is_match_for_effect (alloc.vec.Vec.new acts.Action).slice action true = ok false := by
    unfold acts.set_is_match_for_effect acts.set_is_match_for_effect_loop
    rw [loop]
    simp [acts.set_is_match_for_effect_loop.body, Slice.len, alloc.vec.Vec.from]
  simp [acts.statement_covers, h]

theorem references_empty (key : Slice U8) :
    condfuncs.references_key_name functions key = ok false := by
  have h : condfuncs.any_references (alloc.vec.Vec.new condfuncs.Condition).slice key = ok false := by
    unfold condfuncs.any_references condfuncs.any_references_loop
    rw [loop]
    simp [condfuncs.any_references_loop.body, Slice.len, alloc.vec.Vec.from]
  simp [condfuncs.references_key_name, functions, h]

theorem reaches_fails :
    stmts.bp_reaches_condition_eval statement args = fail .maximumSizeExceeded := by
  unfold stmts.bp_reaches_condition_eval
  simp only [statement, args, empty_vec_len, deref_slice]
  simp only [show ¬ (0#usize : Usize) > 0#usize from by scalar_tac, if_false]
  have hp := principal_matches
  simp only [statement] at hp
  rw [hp]
  simp only [bind_ok, if_true]
  simp only [stmts.Effect.Insts.CoreCmpPartialEqEffect.eq,
    stmts.Effect.read_discriminant, bind_ok, decide_true]
  rw [covers_empty]
  simp only [bind_ok, if_true]
  simp only [lift, bind_ok]
  rw [references_empty]
  simp only [bind_ok]
  rw [build_fails]
  simp

theorem statement_fails (env : condfuncs.Env) :
    stmts.bp_statement_is_allowed statement args env = fail .maximumSizeExceeded := by
  simp [stmts.bp_statement_is_allowed, reaches_fails]

theorem denies_fails (env : condfuncs.Env) :
    policies.bp_denies_pass statements args env = fail .maximumSizeExceeded := by
  unfold policies.bp_denies_pass policies.bp_denies_pass_loop
  rw [loop]
  have hs := statement_fails env
  simp only [statement, vecOf, alloc.vec.Vec.from] at hs
  simp [policies.bp_denies_pass_loop.body, statements, vecOf,
    Slice.index_usize, alloc.vec.Vec.from,
    stmts.Effect.Insts.CoreCmpPartialEqEffect.eq, statement,
    stmts.Effect.read_discriminant, hs]

theorem bucket_policy_fails (env : condfuncs.Env) :
    policies.bucket_policy_is_allowed statements args env = fail .maximumSizeExceeded := by
  simp [policies.bucket_policy_is_allowed, denies_fails]

theorem bucket_policy_not_total (env : condfuncs.Env) :
    ¬ ∃ r, policies.bucket_policy_is_allowed statements args env = ok r := by
  simp [bucket_policy_fails]

theorem requested_statement_is_false :
    ¬ (∀ (sts : Slice stmts.BPStatement) (a : stmts.BucketPolicyArgs) (e : condfuncs.Env),
      ∃ r, policies.bucket_policy_is_allowed sts a e = ok r) := by
  intro h
  let env : condfuncs.Env := ⟨alloc.vec.Vec.new _, emptyBytes, emptyBytes⟩
  exact bucket_policy_not_total env (h statements args env)

#print axioms requested_statement_is_false

end rustfs_kernel.Counterexample
