import Spec
import H5iAppLib
/-!
The requested totality theorem is false for unrestricted condition keys.
`bucket_policy_not_total` supplies a policy and a request satisfying both
length assumptions for which no successful evaluation exists.
-/
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP

namespace rustfs_kernel.Counterexample

@[step] theorem slice_length (s : Slice U8) :
    bytes.slice s 0#usize (Slice.len s) ⦃ out => out.length = s.length ⦄ := by
  unfold bytes.slice bytes.slice_loop
  apply loop_idx_spec _ (fun x => x.2) s.length
    (fun x => x.1.length = x.2.val) _ ?_ _ (by simp) (by simp)
  rintro ⟨out, i⟩ hinv hi
  unfold bytes.slice_loop.body
  split
  all_goals (step*; scalar_tac)

lemma u32_le_usize : U32.max ≤ Usize.max := by
  have h := usize_max_ge
  simpa [U32.max_def, U32.numBits] using h

lemma push_full (v : alloc.vec.Vec U8) (h : v.length = Usize.max) (c : U8) :
    alloc.vec.Vec.push v c = fail .maximumSizeExceeded := by
  unfold alloc.vec.Vec.push
  dsimp only
  have hu := u32_le_usize
  split
  · rename_i hh
    simp only [Bool.or_eq_true, decide_eq_true_eq] at hh
    change v.length + 1 ≤ U32.max ∨ v.length + 1 ≤ Usize.max at hh
    omega
  · rfl

lemma concat_full (s : Slice U8) (h : s.length = Usize.max) :
    bytes.concat s (Slice.from [47#u8] (by simp; scalar_tac)) = fail .maximumSizeExceeded := by
  unfold bytes.concat
  obtain ⟨out, ho, hlen⟩ := (WP.spec_equiv_exists _ _).mp (slice_length s)
  dsimp only
  rw [ho]
  unfold bytes.concat_loop
  simp only [bind_ok]
  rw [loop]
  simp only [bytes.concat_loop.body, Slice.len, Slice.index_usize]
  simp [push_full out (hlen.trans h) 47#u8]

def badKey (v : alloc.vec.Vec U8) : condfuncs.Key :=
  ⟨alloc.vec.Vec.new _, v, some (alloc.vec.Vec.new _)⟩

lemma key_fails (v : alloc.vec.Vec U8) (h : v.length = Usize.max) :
    condfuncs.key_lookup_name (badKey v) = fail .maximumSizeExceeded := by
  unfold condfuncs.key_lookup_name badKey
  simp only
  have hc := concat_full (alloc.vec.Vec.deref v) (by simpa [alloc.vec.Vec.deref] using h)
  simp [lift, Array.to_slice, Array.make, hc]

def badCondition (v : alloc.vec.Vec U8) : condfuncs.Condition :=
  ⟨false, .Bool (vecOf [(badKey v, true)])⟩

def badFunctions (v : alloc.vec.Vec U8) : condfuncs.Functions :=
  ⟨alloc.vec.Vec.new _, alloc.vec.Vec.new _, vecOf [badCondition v]⟩

lemma functions_fail (v : alloc.vec.Vec U8) (h : v.length = Usize.max)
    (e : condfuncs.Env) :
    condfuncs.functions_evaluate (badFunctions v) (alloc.vec.Vec.new _) none e =
      fail .maximumSizeExceeded := by
  have hf : condfuncs.first_value (alloc.vec.Vec.new _) (badKey v) =
      fail .maximumSizeExceeded := by
    simp [condfuncs.first_value, key_fails v h]
  have hb : condfuncs.bool_func (alloc.vec.Vec.deref (vecOf [(badKey v, true)]))
      (alloc.vec.Vec.new _) = fail .maximumSizeExceeded := by
    unfold condfuncs.bool_func condfuncs.bool_func_loop
    rw [loop]
    simp [condfuncs.bool_func_loop.body, vecOf, alloc.vec.Vec.deref,
      Slice.index_usize, Slice.len, hf]
  have hc : ∀ q, condfuncs.condition_evaluate (badCondition v) q
      (alloc.vec.Vec.new _) none e = fail .maximumSizeExceeded := by
    intro q
    simp [badCondition, condfuncs.condition_evaluate, condfuncs.eval_cond, hb]
  have he : ∀ q, condfuncs.all_hold (alloc.vec.Vec.deref (alloc.vec.Vec.new _)) q
      (alloc.vec.Vec.new _) none e = ok true := by
    intro q
    unfold condfuncs.all_hold condfuncs.all_hold_loop
    rw [loop]
    simp [condfuncs.all_hold_loop.body, alloc.vec.Vec.deref, Slice.len]
  have hn : ∀ q, condfuncs.all_hold (alloc.vec.Vec.deref (vecOf [badCondition v])) q
      (alloc.vec.Vec.new _) none e = fail .maximumSizeExceeded := by
    intro q
    unfold condfuncs.all_hold condfuncs.all_hold_loop
    rw [loop]
    simp [condfuncs.all_hold_loop.body, vecOf, alloc.vec.Vec.deref,
      Slice.index_usize, Slice.len, hc]
  simp only [condfuncs.functions_evaluate, badFunctions, he, hn, bind_ok, ite_true]

def request : stmts.BucketPolicyArgs :=
  ⟨alloc.vec.Vec.new _, ⟨.Admin, alloc.vec.Vec.new _⟩,
    alloc.vec.Vec.new _, alloc.vec.Vec.new _, false, alloc.vec.Vec.new _⟩

def badStatement (v : alloc.vec.Vec U8) : stmts.BPStatement :=
  ⟨.Deny, ⟨vecOf [vecOf [42#u8]], alloc.vec.Vec.new _⟩,
    alloc.vec.Vec.new _, alloc.vec.Vec.new _, alloc.vec.Vec.new _,
    alloc.vec.Vec.new _, badFunctions v⟩

lemma principal_matches (v : alloc.vec.Vec U8) :
    stmts.principal_is_match (badStatement v).principal
      (alloc.vec.Vec.deref request.account) = ok true := by
  unfold stmts.principal_is_match
  have ha : stmts.any_simple_match
      (alloc.vec.Vec.deref (vecOf [vecOf [42#u8]]))
      (alloc.vec.Vec.deref request.account) = ok true := by
    unfold stmts.any_simple_match stmts.any_simple_match_loop
    rw [loop]
    simp [stmts.any_simple_match_loop.body, wildmatch.is_simple_match,
      wildmatch.inner_match, request, vecOf, alloc.vec.Vec.deref,
      Slice.len, Slice.index_usize, UScalar.eq_equiv]
  simp only [badStatement, ha, bind_ok, ite_true]

lemma empty_actions_cover : acts.statement_covers
    (alloc.vec.Vec.deref (alloc.vec.Vec.new _))
    (alloc.vec.Vec.deref (alloc.vec.Vec.new _)) request.action true = ok true := by
  have hs : acts.set_is_match_for_effect (alloc.vec.Vec.deref (alloc.vec.Vec.new _))
      request.action true = ok false := by
    unfold acts.set_is_match_for_effect acts.set_is_match_for_effect_loop
    rw [loop]
    simp [acts.set_is_match_for_effect_loop.body, alloc.vec.Vec.deref, Slice.len]
  simp only [acts.statement_covers, hs, bind_ok, ite_true]
  simp [alloc.vec.Vec.deref, Slice.len, UScalar.eq_equiv]

lemma reaches_true (v : alloc.vec.Vec U8) (r : Bool)
    (h : stmts.bp_reaches_condition_eval (badStatement v) request = ok r) : r = true := by
  unfold stmts.bp_reaches_condition_eval at h
  have hz (T : Type) : alloc.vec.Vec.len (alloc.vec.Vec.new T) = 0#usize := by
    simp [alloc.vec.Vec.len, UScalar.eq_equiv]
  have hd : stmts.Effect.Insts.CoreCmpPartialEqEffect.eq .Deny .Deny = ok true := by
    simp [stmts.Effect.Insts.CoreCmpPartialEqEffect.eq, stmts.Effect.read_discriminant]
  have hp := principal_matches v
  simp only [badStatement] at hp
  simp only [badStatement, hz, gt_iff_lt, lt_self_iff_false, ite_false,
    hp, hd, bind_ok, ite_true, empty_actions_cover] at h
  h5i_invert h
  rfl

lemma statement_ne_ok (v : alloc.vec.Vec U8) (hv : v.length = Usize.max)
    (e : condfuncs.Env) (r : Bool) :
    stmts.bp_statement_is_allowed (badStatement v) request e ≠ ok r := by
  intro h
  unfold stmts.bp_statement_is_allowed at h
  obtain ⟨b, hb, hk⟩ := bind_eq_ok.mp h
  have ht := reaches_true v b hb
  subst b
  simp only [ite_true, badStatement, request, functions_fail v hv e, bind_fail] at hk
  exact fail_ne_ok hk

lemma policy_ne_ok (v : alloc.vec.Vec U8) (hv : v.length = Usize.max)
    (e : condfuncs.Env) (r : Bool) :
    policies.bucket_policy_is_allowed (alloc.vec.Vec.deref (vecOf [badStatement v]))
      request e ≠ ok r := by
  intro h
  unfold policies.bucket_policy_is_allowed at h
  obtain ⟨b, hb, _⟩ := bind_eq_ok.mp h
  unfold policies.bp_denies_pass policies.bp_denies_pass_loop at hb
  rw [loop] at hb
  have hd : stmts.Effect.Insts.CoreCmpPartialEqEffect.eq .Deny .Deny = ok true := by
    simp [stmts.Effect.Insts.CoreCmpPartialEqEffect.eq, stmts.Effect.read_discriminant]
  simp only [policies.bp_denies_pass_loop.body] at hb
  simp [vecOf, alloc.vec.Vec.deref, Slice.len, Slice.index_usize,
    hd, badStatement] at hb
  h5i_invert hb
  all_goals exact statement_ne_ok v hv e _ hx

def fullName : alloc.vec.Vec U8 :=
  alloc.vec.Vec.from (List.replicate Usize.max 0#u8) (by simp)

/-- A counterexample satisfying both size assumptions of the requested theorem. -/
theorem bucket_policy_not_total :
    ∃ (sts : Slice stmts.BPStatement) (a : stmts.BucketPolicyArgs) (e : condfuncs.Env),
      a.bucket.length ≤ 63 ∧ a.object.length ≤ 1024 ∧
      ¬ ∃ r, policies.bucket_policy_is_allowed sts a e = ok r := by
  refine ⟨alloc.vec.Vec.deref (vecOf [badStatement fullName]), request,
    ⟨alloc.vec.Vec.new _, alloc.vec.Vec.new _, alloc.vec.Vec.new _⟩,
    by simp [request], by simp [request], ?_⟩
  rintro ⟨r, hr⟩
  exact policy_ne_ok fullName (by simp [fullName]) _ r hr

/-- The negation of the universally quantified statement in `Solution.lean`. -/
theorem requested_statement_false :
    ¬ (∀ (sts : Slice stmts.BPStatement) (a : stmts.BucketPolicyArgs) (e : condfuncs.Env),
      a.bucket.length ≤ 63 → a.object.length ≤ 1024 →
      ∃ r, policies.bucket_policy_is_allowed sts a e = ok r) := by
  intro total
  obtain ⟨sts, a, e, hb, ho, hfail⟩ := bucket_policy_not_total
  exact hfail (total sts a e hb ho)

end rustfs_kernel.Counterexample

#print axioms rustfs_kernel.Counterexample.bucket_policy_not_total
#print axioms rustfs_kernel.Counterexample.requested_statement_false
