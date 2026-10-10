import Spec
import H5iAppLib

/-!
This file disproves the requested totality statement. The policy below has empty
bucket and object names and no statement conditions, so all hypotheses hold.
Its Deny statement matches the wildcard principal and tests the resource pattern
`x${s3:s3:signatureversion}`. The request maps `signatureversion` to a byte string
of length Usize.max. Substitution would need Usize.max + 1 output bytes.

The final theorem proves the hypotheses and the absence of any successful result.
Check independently with: lake env lean Counterexample.lean
-/

open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP
namespace Counterexample

lemma push_len {α} (v w : alloc.vec.Vec α) (x : α)
    (h : alloc.vec.Vec.push v x = ok w) : w.val.length = v.val.length + 1 := by
  unfold alloc.vec.Vec.push at h
  dsimp only at h
  split at h
  · h5i_invert h
    simp
  · simp at h

lemma copy_len (t : Slice U8) (v w : alloc.vec.Vec U8) (j : Usize)
    (hj : j.val ≤ t.length)
    (h : bytes.replace_loop0_loop0 t v j = ok w) :
    w.val.length + j.val = v.val.length + t.length := by
  unfold bytes.replace_loop0_loop0 at h
  have H := loop_idx_ok
    (fun (x : alloc.vec.Vec U8 × Usize) => bytes.replace_loop0_loop0.body t x.1 x.2)
    Prod.snd t.length
    (fun x => x.1.val.length + j.val = v.val.length + x.2.val)
    (fun out => out.val.length + j.val = v.val.length + t.length)
    ?_ (v, j) w (by simp) hj h
  · exact H
  · rintro ⟨out, i⟩ r hi hn hr
    unfold bytes.replace_loop0_loop0.body at hr
    h5i_invert hr
    · have hp := push_len _ _ _ hout1
      h5i_arith
    · scalar_tac

lemma copy_impossible (t : Slice U8) (v w : alloc.vec.Vec U8)
    (hsize : Usize.max < v.val.length + t.length) :
    bytes.replace_loop0_loop0 t v 0#usize ≠ ok w := by
  intro h
  have hl := copy_len t v w 0#usize (by scalar_tac) h
  have hw := w.property
  simp only [Slice.length] at hl hsize
  scalar_tac

lemma starts_true (s p : Slice U8) (k : Usize)
    (hb : k.val + p.length ≤ s.length)
    (he : ∀ i : Nat, ∀ hi : i < p.length, s.val[k.val + i]'(by dsimp only [Slice.length] at *; omega) = p.val[i]'hi) :
    bytes.starts_with_at s k p ⦃ b => b = true ⦄ := by
  unfold bytes.starts_with_at
  step*
  unfold bytes.starts_with_at_loop
  h5i_total (fun i => i) p.length

def varBytes : List U8 := [36#u8, 123#u8, 115#u8, 51#u8, 58#u8, 115#u8, 51#u8, 58#u8, 115#u8, 105#u8, 103#u8, 110#u8, 97#u8, 116#u8, 117#u8, 114#u8, 101#u8, 118#u8, 101#u8, 114#u8, 115#u8, 105#u8, 111#u8, 110#u8, 125#u8]
def pv : alloc.vec.Vec U8 := vecOf varBytes (by apply Nat.le_of_lt; apply usize_lt_max; decide)
def sv : alloc.vec.Vec U8 := vecOf (120#u8 :: varBytes) (by apply Nat.le_of_lt; apply usize_lt_max; decide)
def huge : alloc.vec.Vec U8 := vecOf (List.replicate Usize.max 120#u8) (by simp)

lemma starts_one : bytes.starts_with_at sv.slice 1#usize pv.slice = ok true := by
  apply eq_ok_of_spec
  refine starts_true _ _ _ ?_ ?_
  · simp [sv, pv, vecOf, alloc.vec.Vec.from, Slice.length, varBytes]
  · intro i hi
    simp [sv, pv, vecOf, alloc.vec.Vec.from, Slice.length, Nat.add_comm] at *

lemma starts_zero : bytes.starts_with_at sv.slice 0#usize pv.slice = ok false := by
  apply eq_ok_of_spec
  unfold bytes.starts_with_at
  step*
  unfold bytes.starts_with_at_loop
  rw [loop]
  unfold bytes.starts_with_at_loop.body
  h5i_steps
  all_goals simp_all [sv, pv, vecOf, alloc.vec.Vec.from, Slice.length, varBytes]
  all_goals scalar_tac

lemma replacement_impossible (w : alloc.vec.Vec U8) :
    bytes.replace sv.slice pv.slice huge.slice ≠ ok w := by
  intro h
  have hpv : pv.slice.length = 25 := by simp [pv, vecOf, alloc.vec.Vec.from, varBytes]
  have hsv : sv.slice.length = 26 := by simp [sv, vecOf, alloc.vec.Vec.from, varBytes]
  unfold bytes.replace bytes.replace_loop0 at h
  rw [loop] at h
  obtain ⟨r, hr, h⟩ := bind_eq_ok.1 h
  unfold bytes.replace_loop0.body at hr
  simp only [starts_zero, bind_tc_ok] at hr
  h5i_invert hr
  all_goals try { scalar_tac }
  · have houtlen := push_len _ _ _ hout1
    have hi : i4 = 1#usize := by h5i_arith
    subst hi
    simp only [bind_ok] at h
    rw [loop] at h
    obtain ⟨r, hr, h⟩ := bind_eq_ok.1 h
    unfold bytes.replace_loop0.body at hr
    simp only [starts_one, bind_tc_ok] at hr
    h5i_invert hr
    all_goals try { scalar_tac }
    · apply copy_impossible _ _ _ ?_ hout1_1
      simp only [huge, vecOf, alloc.vec.Vec.from, Slice.length, Slice.from_val, List.length_replicate]
      simp [alloc.vec.Vec.new] at houtlen
      omega

def nameBytes : List U8 := [115#u8,105#u8,103#u8,110#u8,97#u8,116#u8,117#u8,114#u8,101#u8,118#u8,101#u8,114#u8,115#u8,105#u8,111#u8,110#u8]
def nv : alloc.vec.Vec U8 := vecOf nameBytes (by apply Nat.le_of_lt; apply usize_lt_max; decide)
def vals : alloc.vec.Vec (alloc.vec.Vec U8) := vecOf [huge] (by apply Nat.le_of_lt; apply usize_lt_max; decide)
def cv : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)) := vecOf [(nv, vals)] (by apply Nat.le_of_lt; apply usize_lt_max; decide)

@[step] lemma bytes_refl (s : Slice U8) : bytes.eq s s ⦃ b => b = true ⦄ := by
  unfold bytes.eq bytes.eq_loop
  step*
  h5i_total (fun i => i) s.length

@[step] lemma clone_vecs (v : alloc.vec.Vec (alloc.vec.Vec U8)) :
    alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) v ⦃ w => w = v ⦄ := by
  rw [vec_clone_ok]
  · simp
  · intro x
    exact vec_clone_ok _ _ u8_clone

lemma common_zero : keynames.common_key 0#usize = ok (nv, pv) := by
  apply eq_ok_of_spec
  unfold keynames.common_key
  rw [show (0#usize).val = 0 by scalar_tac]
  step*
  constructor <;> apply (alloc.vec.Vec.eq_iff _ _).mpr <;> simp_all [alloc.vec.Vec.val, nv, pv, vecOf, alloc.vec.Vec.from, nameBytes, varBytes, Array.to_slice]

lemma get_first : condfuncs.get_value cv nv.slice = ok (some vals) := by
  apply eq_ok_of_spec
  unfold condfuncs.get_value condfuncs.get_value_loop
  rw [loop]
  unfold condfuncs.get_value_loop.body
  h5i_steps
  all_goals simp_all [cv, vecOf, alloc.vec.Vec.from, alloc.vec.Vec.deref, alloc.vec.Vec.val]
  all_goals h5i_steps

@[simp] lemma to_vec_eq (v : alloc.vec.Vec U8) : alloc.slice.Slice.to_vec core.clone.CloneU8 v.slice = ok v := by
  apply eq_ok_of_spec
  step*
  cases v
  simp_all

@[simp] lemma deref_eq {α} (v : alloc.vec.Vec α) : alloc.vec.Vec.deref v = v.slice := by simp [alloc.vec.Vec.deref, alloc.vec.Vec.val]

lemma substitute_impossible (w : alloc.vec.Vec U8) : rsrc.substitute_common sv.slice cv ≠ ok w := by
  intro h
  unfold rsrc.substitute_common at h
  rw [to_vec_eq] at h
  simp only [bind_tc_ok, bind_ok] at h
  unfold rsrc.substitute_common_loop at h
  rw [loop] at h
  obtain ⟨r, hr, h⟩ := bind_eq_ok.1 h
  unfold rsrc.substitute_common_loop.body at hr
  simp only [common_zero, bind_tc_ok, bind_ok] at hr
  simp only [deref_eq, get_first, bind_ok, bind_tc_ok] at hr
  have hk0 : 0#usize < keynames.COMMON_KEYS_LEN := by unfold keynames.COMMON_KEYS_LEN; scalar_tac
  simp only [if_pos hk0] at hr
  change (do
    let o ← condfuncs.get_value cv nv.slice
    let out1 ← match o with
      | none => ok sv
      | some vs =>
        if vs.len > 0#usize then (do
          let v ← alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice _) vs 0#usize
          if v.len > 0#usize then bytes.replace sv.slice pv.slice v.slice else ok sv)
        else ok sv
    let k1 ← 0#usize + 1#usize
    ok (ControlFlow.cont (out1, k1))) = ok r at hr
  simp only [get_first, bind_ok, bind_tc_ok] at hr
  h5i_invert hr
  h5i_invert hout1
  all_goals h5i_ok_facts
  · h5i_ok_facts
    have hv : v = huge := by simpa [vals, vecOf] using hv_val_3
    subst hv
    exact replacement_impossible _ hout1
  · have hvv : v = huge := by simpa [vals, vecOf] using hv_val_1
    subst hvv
    have hh := usize_max_ge
    have hl : huge.length = Usize.max := by simp [huge, vecOf]
    scalar_tac
  · have hl : vals.length = 1 := by simp [vals, vecOf]
    scalar_tac

lemma pattern_impossible (resource : Slice U8) (b : Bool) : rsrc.pattern_matches sv.slice resource cv ≠ ok b := by
  intro h
  unfold rsrc.pattern_matches at h
  have hc : cv.len > 0#usize := by
    have hl : cv.length = 1 := by simp [cv, vecOf]
    scalar_tac
  simp only [if_pos hc] at h
  obtain ⟨r, hr, h⟩ := bind_eq_ok.1 h
  exact substitute_impossible _ hr

lemma push_new {α} (x : α) : alloc.vec.Vec.push (alloc.vec.Vec.new α) x = ok (vecOf [x] (by simp only [List.length_cons, List.length_nil]; have := usize_max_ge; omega)) := by
  apply eq_ok_of_spec
  step*
  apply (alloc.vec.Vec.eq_iff _ _).mpr
  simp_all [vecOf, alloc.vec.Vec.new]

lemma index_single {α} (x : α) :
    alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice α) (vecOf [x] (by simp only [List.length_cons, List.length_nil]; have := usize_max_ge; omega)) 0#usize = ok x := by
  apply eq_ok_of_spec
  step*
  have hz : (0#usize).val = 0 := by scalar_tac
  all_goals simp_all [vecOf, alloc.vec.Vec.from, alloc.vec.Vec.val]

lemma resource_impossible (resource : Slice U8) (b : Bool) :
    rsrc.resource_is_match (.S3 sv) resource cv none ≠ ok b := by
  intro h
  simp only [rsrc.resource_is_match] at h
  rw [vec_clone_ok _ _ u8_clone] at h
  simp only [bind_ok, bind_tc_ok, push_new] at h
  unfold rsrc.resource_is_match_loop at h
  rw [loop] at h
  obtain ⟨r, hr, h⟩ := bind_eq_ok.1 h
  unfold rsrc.resource_is_match_loop.body at hr
  have hl : (vecOf [sv] (by simp only [List.length_cons, List.length_nil]; have := usize_max_ge; omega)).length = 1 := by simp [vecOf]
  have hc : 0#usize < (vecOf [sv] (by simp only [List.length_cons, List.length_nil]; have := usize_max_ge; omega)).len := by scalar_tac
  simp only [if_pos hc, index_single, bind_ok, bind_tc_ok, deref_eq] at hr
  obtain ⟨r, hr, h⟩ := bind_eq_ok.1 hr
  exact pattern_impossible _ _ hr

lemma set_impossible (resource : Slice U8) (b : Bool) :
    rsrc.set_is_match (vecOf [rsrc.Resource.S3 sv] (by simp only [List.length_cons, List.length_nil]; have := usize_max_ge; omega)).slice resource cv none ≠ ok b := by
  intro h
  unfold rsrc.set_is_match rsrc.set_is_match_loop at h
  rw [loop] at h
  obtain ⟨r, hr, h⟩ := bind_eq_ok.1 h
  unfold rsrc.set_is_match_loop.body at hr
  h5i_invert hr
  all_goals h5i_ok_facts
  · have hv : r_1 = rsrc.Resource.S3 sv := by simpa [vecOf, alloc.vec.Vec.from] using hr_1_val
    subst hv
    exact resource_impossible _ _ hb_1
  · have hv : r_1 = rsrc.Resource.S3 sv := by simpa [vecOf, alloc.vec.Vec.from] using hr_1_val
    subst hv
    exact resource_impossible _ _ hb_1
  · have hl : (vecOf [rsrc.Resource.S3 sv] (by simp only [List.length_cons, List.length_nil]; have := usize_max_ge; omega)).slice.length = 1 := by simp [vecOf, alloc.vec.Vec.from]
    scalar_tac

h5i_derive_eq acts.Family acts.Family.Insts.CoreCmpPartialEqFamily.eq
h5i_derive_eq stmts.Effect stmts.Effect.Insts.CoreCmpPartialEqEffect.eq

def empty {α : Type} : alloc.vec.Vec α := alloc.vec.Vec.new α
def one {α : Type} (x : α) : alloc.vec.Vec α := vecOf [x] (by simp only [List.length_cons, List.length_nil]; have := usize_max_ge; omega)
def star : alloc.vec.Vec U8 := one 42#u8
def functions : condfuncs.Functions := ⟨empty, empty, empty⟩
def st : stmts.BPStatement := ⟨.Deny, ⟨one star, empty⟩, empty, empty, one (.S3 sv), empty, functions⟩
def args : stmts.BucketPolicyArgs := ⟨empty, ⟨.None, empty⟩, empty, cv, false, empty⟩
def env : condfuncs.Env := ⟨empty, empty, empty⟩

@[step] lemma star_match (account : Slice U8) : wildmatch.is_simple_match star.slice account ⦃ b => b = true ⦄ := by
  unfold wildmatch.is_simple_match wildmatch.inner_match
  h5i_steps
  all_goals simp_all [star, one, vecOf, alloc.vec.Vec.from, alloc.vec.Vec.val]
  all_goals scalar_tac

lemma principal_match (account : Slice U8) : stmts.principal_is_match st.principal account = ok true := by
  have ha : stmts.any_simple_match (one star).slice account = ok true := by
    apply eq_ok_of_spec
    unfold stmts.any_simple_match stmts.any_simple_match_loop
    rw [loop]
    unfold stmts.any_simple_match_loop.body
    h5i_steps
    all_goals simp_all [one, vecOf, alloc.vec.Vec.from, deref_eq]
    all_goals h5i_steps
  simp only [stmts.principal_is_match, st, deref_eq, ha, bind_ok, bind_tc_ok]
  rfl


@[simp] lemma empty_len {α : Type} : (empty : alloc.vec.Vec α).len = 0#usize := by
  have hl : (empty : alloc.vec.Vec α).length = 0 := by simp [empty, alloc.vec.Vec.new]
  scalar_tac
@[simp] lemma empty_slicelen {α : Type} : (empty : alloc.vec.Vec α).slice.len = 0#usize := by
  have hl : (empty : alloc.vec.Vec α).slice.length = 0 := by simp [empty, alloc.vec.Vec.new, alloc.vec.Vec.from]
  scalar_tac

lemma actionset_empty (a : acts.Action) (d : Bool) : acts.set_is_match_for_effect empty.slice a d = ok false := by
  unfold acts.set_is_match_for_effect acts.set_is_match_for_effect_loop
  rw [loop]
  simp [acts.set_is_match_for_effect_loop.body]

lemma covers_empty : acts.statement_covers empty.slice empty.slice args.action true = ok true := by
  simp [acts.statement_covers, actionset_empty]

lemma anyrefs_empty (key : Slice U8) : condfuncs.any_references empty.slice key = ok false := by
  unfold condfuncs.any_references condfuncs.any_references_loop
  rw [loop]
  simp [condfuncs.any_references_loop.body]

lemma refs_empty (key : Slice U8) : condfuncs.references_key_name functions key = ok false := by
  simp [condfuncs.references_key_name, functions, anyrefs_empty]

lemma effect_deny : stmts.Effect.Insts.CoreCmpPartialEqEffect.eq .Deny .Deny = ok true := by
  exact eq_ok_of_spec (stmts.Effect.Insts.CoreCmpPartialEqEffect.eq.spec _ _)

lemma reaches_impossible (b : Bool) : stmts.bp_reaches_condition_eval st args ≠ ok b := by
  intro h
  have hprincipal := principal_match args.account.slice
  simp only [st] at hprincipal
  have hlen : (one (rsrc.Resource.S3 sv)).len > 0#usize := by
    have hl : (one (rsrc.Resource.S3 sv)).length = 1 := by simp [one, vecOf]
    scalar_tac
  simp only [stmts.bp_reaches_condition_eval, st, empty_len, deref_eq, hprincipal, effect_deny, covers_empty, refs_empty, bind_ok, bind_tc_ok] at h
  h5i_invert h
  all_goals try { exact set_impossible _ _ hb4 }
  all_goals try { exact set_impossible _ _ hb5 }
  all_goals try { scalar_tac }

lemma statement_impossible (b : Bool) : stmts.bp_statement_is_allowed st args env ≠ ok b := by
  intro h
  unfold stmts.bp_statement_is_allowed at h
  obtain ⟨r, hr, h⟩ := bind_eq_ok.1 h
  exact reaches_impossible _ hr

lemma denies_impossible (b : Bool) : policies.bp_denies_pass (one st).slice args env ≠ ok b := by
  intro h
  unfold policies.bp_denies_pass policies.bp_denies_pass_loop at h
  rw [loop] at h
  obtain ⟨r, hr, h⟩ := bind_eq_ok.1 h
  unfold policies.bp_denies_pass_loop.body at hr
  have hc : 0#usize < (one st).slice.len := by
    have hl : (one st).slice.length = 1 := by simp [one, vecOf, alloc.vec.Vec.from]
    scalar_tac
  have hs : Slice.index_usize (one st).slice 0#usize = ok st := by
    apply eq_ok_of_spec
    step*
    all_goals simp_all [one, vecOf, alloc.vec.Vec.from, alloc.vec.Vec.val]
  simp only [if_pos hc, hs, bind_ok, bind_tc_ok] at hr
  simp only [st, effect_deny, bind_ok, bind_tc_ok] at hr
  obtain ⟨r, hr, h⟩ := bind_eq_ok.1 hr
  exact statement_impossible _ hr

lemma bucket_impossible : ¬ ∃ b, policies.bucket_policy_is_allowed (one st).slice args env = ok b := by
  rintro ⟨b, h⟩
  unfold policies.bucket_policy_is_allowed at h
  obtain ⟨r, hr, h⟩ := bind_eq_ok.1 h
  exact denies_impossible _ hr

theorem bucket_counterexample :
    args.bucket.length ≤ 63 ∧ args.object.length ≤ 1024 ∧
    (∀ stmt ∈ (one st).slice.val, ∀ c ∈ stmt.conditions.for_any_value.val ++ stmt.conditions.for_all_values.val ++ stmt.conditions.for_normal.val,
      ∀ k ∈ (match c.cond with
        | .Str _ l => l.val.map Prod.fst | .Ip _ l => l.val.map Prod.fst | .Null l => l.val.map Prod.fst
        | .Bool l => l.val.map Prod.fst | .Num _ _ l => l.val.map Prod.fst),
      ∀ v, k.variable = some v → k.name.length + v.length < Usize.max) ∧
    ¬ ∃ r, policies.bucket_policy_is_allowed (one st).slice args env = ok r := by
  refine ⟨?_, ?_, ?_, bucket_impossible⟩
  · simp [args, empty, alloc.vec.Vec.new]
  · simp [args, empty, alloc.vec.Vec.new]
  · simp [one, vecOf, alloc.vec.Vec.from, st, functions, empty, alloc.vec.Vec.new, alloc.vec.Vec.val]

-- This is the negation of the exact universally quantified statement required
-- in Solution.lean; it does not import that file or its unfinished proof.
theorem requested_totality_is_false :
    ¬ (∀ (sts : Slice stmts.BPStatement) (a : stmts.BucketPolicyArgs) (e : condfuncs.Env),
      a.bucket.length ≤ 63 → a.object.length ≤ 1024 →
      (∀ st ∈ sts.val, ∀ c ∈ st.conditions.for_any_value.val ++ st.conditions.for_all_values.val ++
          st.conditions.for_normal.val,
        ∀ k ∈ (match c.cond with
          | .Str _ l => l.val.map Prod.fst | .Ip _ l => l.val.map Prod.fst | .Null l => l.val.map Prod.fst
          | .Bool l => l.val.map Prod.fst | .Num _ _ l => l.val.map Prod.fst),
        ∀ v, k.variable = some v → k.name.length + v.length < Usize.max) →
      ∃ r, policies.bucket_policy_is_allowed sts a e = ok r) := by
  intro total
  obtain ⟨hb, ho, hk, failure⟩ := bucket_counterexample
  exact failure (total (one st).slice args env hb ho hk)

end Counterexample

#print axioms Counterexample.bucket_counterexample
#print axioms Counterexample.requested_totality_is_false
