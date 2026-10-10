import Spec
open Aeneas Aeneas.Std Result rustfs_kernel
open H5iAppLib hiding lit
set_option linter.unusedSimpArgs false
namespace BucketCounterexample

-- Eight successive common-key substitutions, each introducing 200 copies
-- of the next key's reference. This file certifies the input bounds and
-- the output-size calculation, not a full symbolic execution of the kernel.
def marker0 : alloc.vec.Vec U8 := vecOf [36#u8, 123#u8, 115#u8, 51#u8, 58#u8, 115#u8, 51#u8, 58#u8, 115#u8, 105#u8, 103#u8, 110#u8, 97#u8, 116#u8, 117#u8, 114#u8, 101#u8, 118#u8, 101#u8, 114#u8, 115#u8, 105#u8, 111#u8, 110#u8, 125#u8]
def marker1 : alloc.vec.Vec U8 := vecOf [36#u8, 123#u8, 115#u8, 51#u8, 58#u8, 115#u8, 51#u8, 58#u8, 97#u8, 117#u8, 116#u8, 104#u8, 84#u8, 121#u8, 112#u8, 101#u8, 125#u8]
def marker2 : alloc.vec.Vec U8 := vecOf [36#u8, 123#u8, 115#u8, 51#u8, 58#u8, 115#u8, 51#u8, 58#u8, 115#u8, 105#u8, 103#u8, 110#u8, 97#u8, 116#u8, 117#u8, 114#u8, 101#u8, 65#u8, 103#u8, 101#u8, 125#u8]
def marker3 : alloc.vec.Vec U8 := vecOf [36#u8, 123#u8, 115#u8, 51#u8, 58#u8, 115#u8, 51#u8, 58#u8, 120#u8, 45#u8, 97#u8, 109#u8, 122#u8, 45#u8, 99#u8, 111#u8, 110#u8, 116#u8, 101#u8, 110#u8, 116#u8, 45#u8, 115#u8, 104#u8, 97#u8, 50#u8, 53#u8, 54#u8, 125#u8]
def marker4 : alloc.vec.Vec U8 := vecOf [36#u8, 123#u8, 115#u8, 51#u8, 58#u8, 115#u8, 51#u8, 58#u8, 76#u8, 111#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 67#u8, 111#u8, 110#u8, 115#u8, 116#u8, 114#u8, 97#u8, 105#u8, 110#u8, 116#u8, 125#u8]
def marker5 : alloc.vec.Vec U8 := vecOf [36#u8, 123#u8, 115#u8, 51#u8, 58#u8, 115#u8, 51#u8, 58#u8, 118#u8, 101#u8, 114#u8, 115#u8, 105#u8, 111#u8, 110#u8, 105#u8, 100#u8, 125#u8]
def marker6 : alloc.vec.Vec U8 := vecOf [36#u8, 123#u8, 97#u8, 119#u8, 115#u8, 58#u8, 97#u8, 119#u8, 115#u8, 58#u8, 82#u8, 101#u8, 102#u8, 101#u8, 114#u8, 101#u8, 114#u8, 125#u8]
def marker7 : alloc.vec.Vec U8 := vecOf [36#u8, 123#u8, 97#u8, 119#u8, 115#u8, 58#u8, 97#u8, 119#u8, 115#u8, 58#u8, 83#u8, 111#u8, 117#u8, 114#u8, 99#u8, 101#u8, 73#u8, 112#u8, 125#u8]
def marker8 : alloc.vec.Vec U8 := vecOf [36#u8, 123#u8, 97#u8, 119#u8, 115#u8, 58#u8, 97#u8, 119#u8, 115#u8, 58#u8, 85#u8, 115#u8, 101#u8, 114#u8, 65#u8, 103#u8, 101#u8, 110#u8, 116#u8, 125#u8]
def name0 : alloc.vec.Vec U8 := vecOf [115#u8, 105#u8, 103#u8, 110#u8, 97#u8, 116#u8, 117#u8, 114#u8, 101#u8, 118#u8, 101#u8, 114#u8, 115#u8, 105#u8, 111#u8, 110#u8]
def value0 : alloc.vec.Vec U8 := vecOf ((List.replicate 200 marker1.val).flatten) (by
  simp only [List.length_flatten, List.map_replicate, List.sum_replicate]
  simp [marker1]
  scalar_tac)
def name1 : alloc.vec.Vec U8 := vecOf [97#u8, 117#u8, 116#u8, 104#u8, 84#u8, 121#u8, 112#u8, 101#u8]
def value1 : alloc.vec.Vec U8 := vecOf ((List.replicate 200 marker2.val).flatten) (by
  simp only [List.length_flatten, List.map_replicate, List.sum_replicate]
  simp [marker2]
  scalar_tac)
def name2 : alloc.vec.Vec U8 := vecOf [115#u8, 105#u8, 103#u8, 110#u8, 97#u8, 116#u8, 117#u8, 114#u8, 101#u8, 65#u8, 103#u8, 101#u8]
def value2 : alloc.vec.Vec U8 := vecOf ((List.replicate 200 marker3.val).flatten) (by
  simp only [List.length_flatten, List.map_replicate, List.sum_replicate]
  simp [marker3]
  scalar_tac)
def name3 : alloc.vec.Vec U8 := vecOf [120#u8, 45#u8, 97#u8, 109#u8, 122#u8, 45#u8, 99#u8, 111#u8, 110#u8, 116#u8, 101#u8, 110#u8, 116#u8, 45#u8, 115#u8, 104#u8, 97#u8, 50#u8, 53#u8, 54#u8]
def value3 : alloc.vec.Vec U8 := vecOf ((List.replicate 200 marker4.val).flatten) (by
  simp only [List.length_flatten, List.map_replicate, List.sum_replicate]
  simp [marker4]
  scalar_tac)
def name4 : alloc.vec.Vec U8 := vecOf [76#u8, 111#u8, 99#u8, 97#u8, 116#u8, 105#u8, 111#u8, 110#u8, 67#u8, 111#u8, 110#u8, 115#u8, 116#u8, 114#u8, 97#u8, 105#u8, 110#u8, 116#u8]
def value4 : alloc.vec.Vec U8 := vecOf ((List.replicate 200 marker5.val).flatten) (by
  simp only [List.length_flatten, List.map_replicate, List.sum_replicate]
  simp [marker5]
  scalar_tac)
def name5 : alloc.vec.Vec U8 := vecOf [118#u8, 101#u8, 114#u8, 115#u8, 105#u8, 111#u8, 110#u8, 105#u8, 100#u8]
def value5 : alloc.vec.Vec U8 := vecOf ((List.replicate 200 marker6.val).flatten) (by
  simp only [List.length_flatten, List.map_replicate, List.sum_replicate]
  simp [marker6]
  scalar_tac)
def name6 : alloc.vec.Vec U8 := vecOf [82#u8, 101#u8, 102#u8, 101#u8, 114#u8, 101#u8, 114#u8]
def value6 : alloc.vec.Vec U8 := vecOf ((List.replicate 200 marker7.val).flatten) (by
  simp only [List.length_flatten, List.map_replicate, List.sum_replicate]
  simp [marker7]
  scalar_tac)
def name7 : alloc.vec.Vec U8 := vecOf [83#u8, 111#u8, 117#u8, 114#u8, 99#u8, 101#u8, 73#u8, 112#u8]
def value7 : alloc.vec.Vec U8 := vecOf ((List.replicate 200 marker8.val).flatten) (by
  simp only [List.length_flatten, List.map_replicate, List.sum_replicate]
  simp [marker8]
  scalar_tac)
@[simp] theorem deref_vecOf_val {T : Type} (l : List T) (h : l.length ≤ Usize.max) :
    (alloc.vec.Vec.deref (vecOf l h)).val = l := by simp [alloc.vec.Vec.deref]

@[simp] theorem value0_length : value0.length = 3400 := by
  unfold value0
  simp only [alloc.vec.Vec.length, vecOf_val, List.length_flatten, List.map_replicate, List.sum_replicate]
  norm_num [marker1]

@[simp] theorem value1_length : value1.length = 4200 := by
  unfold value1
  simp only [alloc.vec.Vec.length, vecOf_val, List.length_flatten, List.map_replicate, List.sum_replicate]
  norm_num [marker2]

@[simp] theorem value2_length : value2.length = 5800 := by
  unfold value2
  simp only [alloc.vec.Vec.length, vecOf_val, List.length_flatten, List.map_replicate, List.sum_replicate]
  norm_num [marker3]

@[simp] theorem value3_length : value3.length = 5400 := by
  unfold value3
  simp only [alloc.vec.Vec.length, vecOf_val, List.length_flatten, List.map_replicate, List.sum_replicate]
  norm_num [marker4]

@[simp] theorem value4_length : value4.length = 3600 := by
  unfold value4
  simp only [alloc.vec.Vec.length, vecOf_val, List.length_flatten, List.map_replicate, List.sum_replicate]
  norm_num [marker5]

@[simp] theorem value5_length : value5.length = 3600 := by
  unfold value5
  simp only [alloc.vec.Vec.length, vecOf_val, List.length_flatten, List.map_replicate, List.sum_replicate]
  norm_num [marker6]

@[simp] theorem value6_length : value6.length = 3800 := by
  unfold value6
  simp only [alloc.vec.Vec.length, vecOf_val, List.length_flatten, List.map_replicate, List.sum_replicate]
  norm_num [marker7]

@[simp] theorem value7_length : value7.length = 4000 := by
  unfold value7
  simp only [alloc.vec.Vec.length, vecOf_val, List.length_flatten, List.map_replicate, List.sum_replicate]
  norm_num [marker8]

theorem common_key0_matches : keynames.common_key 0#usize ⦃ r => r = (name0, marker0) ⦄ := by
  unfold keynames.common_key
  simp -failIfUnchanged only [UScalar.ofNatCore_val_eq]
  step*
  simp_all [name0, marker0, vecOf, alloc.vec.Vec.from, alloc.vec.Vec.eq_iff, alloc.vec.Vec.val, Slice.eq_iff, Array.to_slice, Array.make]

theorem common_key1_matches : keynames.common_key 1#usize ⦃ r => r = (name1, marker1) ⦄ := by
  unfold keynames.common_key
  simp -failIfUnchanged only [UScalar.ofNatCore_val_eq]
  step*
  simp_all [name1, marker1, vecOf, alloc.vec.Vec.from, alloc.vec.Vec.eq_iff, alloc.vec.Vec.val, Slice.eq_iff, Array.to_slice, Array.make]

theorem common_key2_matches : keynames.common_key 2#usize ⦃ r => r = (name2, marker2) ⦄ := by
  unfold keynames.common_key
  simp -failIfUnchanged only [UScalar.ofNatCore_val_eq]
  step*
  simp_all [name2, marker2, vecOf, alloc.vec.Vec.from, alloc.vec.Vec.eq_iff, alloc.vec.Vec.val, Slice.eq_iff, Array.to_slice, Array.make]

theorem common_key3_matches : keynames.common_key 3#usize ⦃ r => r = (name3, marker3) ⦄ := by
  unfold keynames.common_key
  simp -failIfUnchanged only [UScalar.ofNatCore_val_eq]
  step*
  simp_all [name3, marker3, vecOf, alloc.vec.Vec.from, alloc.vec.Vec.eq_iff, alloc.vec.Vec.val, Slice.eq_iff, Array.to_slice, Array.make]

theorem common_key4_matches : keynames.common_key 4#usize ⦃ r => r = (name4, marker4) ⦄ := by
  unfold keynames.common_key
  simp -failIfUnchanged only [UScalar.ofNatCore_val_eq]
  step*
  simp_all [name4, marker4, vecOf, alloc.vec.Vec.from, alloc.vec.Vec.eq_iff, alloc.vec.Vec.val, Slice.eq_iff, Array.to_slice, Array.make]

theorem common_key5_matches : keynames.common_key 5#usize ⦃ r => r = (name5, marker5) ⦄ := by
  unfold keynames.common_key
  simp -failIfUnchanged only [UScalar.ofNatCore_val_eq]
  step*
  simp_all [name5, marker5, vecOf, alloc.vec.Vec.from, alloc.vec.Vec.eq_iff, alloc.vec.Vec.val, Slice.eq_iff, Array.to_slice, Array.make]

theorem common_key6_matches : keynames.common_key 6#usize ⦃ r => r = (name6, marker6) ⦄ := by
  unfold keynames.common_key
  simp -failIfUnchanged only [UScalar.ofNatCore_val_eq]
  step*
  simp_all [name6, marker6, vecOf, alloc.vec.Vec.from, alloc.vec.Vec.eq_iff, alloc.vec.Vec.val, Slice.eq_iff, Array.to_slice, Array.make]

theorem common_key7_matches : keynames.common_key 7#usize ⦃ r => r = (name7, marker7) ⦄ := by
  unfold keynames.common_key
  simp -failIfUnchanged only [UScalar.ofNatCore_val_eq]
  step*
  simp_all [name7, marker7, vecOf, alloc.vec.Vec.from, alloc.vec.Vec.eq_iff, alloc.vec.Vec.val, Slice.eq_iff, Array.to_slice, Array.make]

def values := vecOf [(name0, vecOf [value0]), (name1, vecOf [value1]), (name2, vecOf [value2]), (name3, vecOf [value3]), (name4, vecOf [value4]), (name5, vecOf [value5]), (name6, vecOf [value6]), (name7, vecOf [value7])]

def st : stmts.BPStatement := {
  effect := .Deny
  principal := { aws := vecOf [vecOf [42#u8]], service := vecOf [] }
  actions := vecOf []
  not_actions := vecOf []
  resources := vecOf [.S3 marker0]
  not_resources := vecOf []
  conditions := { for_any_value := vecOf [], for_all_values := vecOf [], for_normal := vecOf [] }
}
def args : stmts.BucketPolicyArgs := {
  account := vecOf []
  action := { family := .None, «name» := vecOf [] }
  bucket := vecOf [98#u8]
  object := vecOf []
  conditions := values
  is_owner := false
}
def sts : Slice stmts.BPStatement := alloc.vec.Vec.deref (vecOf [st])

theorem input_bounds :
    args.bucket.length ≤ 63 ∧ args.object.length ≤ 1024 ∧
    (∀ s ∈ sts.val, ∀ c ∈ s.conditions.for_any_value.val ++ s.conditions.for_all_values.val ++
        s.conditions.for_normal.val,
      ∀ k ∈ (match c.cond with
        | .Str _ l => l.val.map Prod.fst | .Ip _ l => l.val.map Prod.fst | .Null l => l.val.map Prod.fst
        | .Bool l => l.val.map Prod.fst | .Num _ _ l => l.val.map Prod.fst),
      ∀ v, k.variable = some v → k.name.length + v.length < Usize.max) ∧
    (∀ kv ∈ args.conditions.val, ∀ v ∈ kv.2.val, v.length ≤ 8192) ∧
    (∀ s ∈ sts.val, ∀ r ∈ s.resources.val ++ s.not_resources.val,
      (match r with | .S3 p => p.length | .Kms p => p.length) ≤ 20480) := by
  simp [args, sts, st, values, marker0]

theorem eighth_output_size : 200 ^ 8 * marker8.length = 51200000000000000000 := by
  norm_num [marker8]

theorem eighth_output_exceeds_usize : Usize.max < 200 ^ 8 * marker8.length := by
  rw [eighth_output_size]
  rcases Usize.bounds_eq with h | h <;> rw [h] <;> norm_num [U32.max, U64.max, U32.numBits, U64.numBits]

theorem push_at_capacity_fails (v : alloc.vec.Vec U8) (x : U8)
    (h : v.length = Usize.max) :
    alloc.vec.Vec.push v x = fail .maximumSizeExceeded := by
  have hm : U32.max ≤ Usize.max := by
    rcases Usize.bounds_eq with h | h <;> rw [h] <;> norm_num [U32.max, U64.max, U32.numBits, U64.numBits]
  unfold alloc.vec.Vec.push
  simp [h, show ¬ (Usize.max + 1 ≤ U32.max) by omega]



-- The top-level evaluator cannot bypass the failing resource substitution.
@[step] theorem star_match (p account : Slice U8) (hp : p.val = [42#u8]) :
    wildmatch.is_simple_match p account
      ⦃ r => r = true ⦄ := by
  unfold wildmatch.is_simple_match wildmatch.inner_match
  simp only [Slice.len, hp, List.length_cons, List.length_nil, UScalar.ofNatCore_val_eq]
  h5i_steps
  all_goals simp_all [hp]

@[step] theorem principal_matches :
    stmts.principal_is_match st.principal (alloc.vec.Vec.deref args.account)
      ⦃ r => r = true ⦄ := by
  unfold stmts.principal_is_match stmts.any_simple_match stmts.any_simple_match_loop
  simp only [st, args, alloc.vec.Vec.deref, vecOf_val, Slice.len]
  rw [loop]
  unfold stmts.any_simple_match_loop.body
  simp only [alloc.vec.Vec.deref, vecOf_val, Slice.len, UScalar.ofNatCore_val_eq]
  h5i_steps
  all_goals simp_all [vecOf, alloc.vec.Vec.from, alloc.vec.Vec.deref, alloc.vec.Vec.val,
    Slice.len, alloc.vec.Vec.eq_iff, Slice.eq_iff]
  all_goals h5i_steps

h5i_derive_eq acts.Family acts.Family.Insts.CoreCmpPartialEqFamily.eq
h5i_derive_eq stmts.Effect stmts.Effect.Insts.CoreCmpPartialEqEffect.eq

@[step] theorem empty_actions (a : acts.Action) (deny : Bool) :
    acts.set_is_match_for_effect (alloc.vec.Vec.deref (vecOf [])) a deny
      ⦃ r => r = false ⦄ := by
  unfold acts.set_is_match_for_effect acts.set_is_match_for_effect_loop
  rw [loop]
  unfold acts.set_is_match_for_effect_loop.body
  simp only [alloc.vec.Vec.deref, vecOf_val, Slice.len, UScalar.lt_equiv,
    UScalar.ofNatCore_val_eq]
  simp

@[step] theorem actions_cover :
    acts.statement_covers (alloc.vec.Vec.deref st.actions)
      (alloc.vec.Vec.deref st.not_actions) args.action true ⦃ r => r = true ⦄ := by
  unfold acts.statement_covers
  simp only [st]
  h5i_steps
  all_goals simp_all [alloc.vec.Vec.deref, vecOf_val, Slice.len]
  all_goals scalar_tac

@[step] theorem empty_references (kn : Slice U8) :
    condfuncs.any_references (alloc.vec.Vec.deref (vecOf [])) kn
      ⦃ r => r = false ⦄ := by
  unfold condfuncs.any_references condfuncs.any_references_loop
  rw [loop]
  unfold condfuncs.any_references_loop.body
  simp only [alloc.vec.Vec.deref, vecOf_val, Slice.len, UScalar.lt_equiv,
    UScalar.ofNatCore_val_eq]
  simp

@[step] theorem no_references (kn : Slice U8) :
    condfuncs.references_key_name st.conditions kn ⦃ r => r = false ⦄ := by
  unfold condfuncs.references_key_name
  simp only [st]
  h5i_steps
  all_goals simp_all

@[step] theorem built_resource (b : Bool) :
    stmts.build_resource args.action (alloc.vec.Vec.deref args.bucket)
      (alloc.vec.Vec.deref args.object) b ⦃ r => r.val = [98#u8, 47#u8] ⦄ := by
  unfold stmts.build_resource stmts.is_list_bucket
  simp only [args]
  have he : (alloc.vec.Vec.deref (vecOf ([] : List U8))).len = 0#usize := by
    apply UScalar.eq_of_val_eq
    simp [alloc.vec.Vec.deref]
  simp only [he]
  h5i_steps
  all_goals simp_all [alloc.vec.Vec.deref, vecOf, alloc.vec.Vec.from,
    alloc.vec.Vec.val, Slice.eq_iff, Slice.len]
  all_goals rw [← resource_post]
  all_goals first | (apply usize_lt_max; norm_num) | rfl

theorem successful_evaluation_reaches_resource (env : condfuncs.Env) (result : Bool)
    (h : policies.bucket_policy_is_allowed sts args env = ok result) :
    ∃ resource answer,
      rsrc.set_is_match (alloc.vec.Vec.deref st.resources)
        (alloc.vec.Vec.deref resource) args.conditions none = ok answer := by
  have heff : stmts.Effect.Insts.CoreCmpPartialEqEffect.eq st.effect .Deny = ok true := by
    apply eq_ok_of_spec
    simpa [st] using stmts.Effect.Insts.CoreCmpPartialEqEffect.eq.spec .Deny .Deny
  unfold policies.bucket_policy_is_allowed at h
  obtain ⟨deny, hd, _⟩ := bind_tc_eq_ok.mp h
  unfold policies.bp_denies_pass policies.bp_denies_pass_loop at hd
  rw [loop] at hd
  obtain ⟨first, hf, _⟩ := bind_tc_eq_ok.mp hd
  unfold policies.bp_denies_pass_loop.body at hf
  have hz : (0#usize : Usize) < sts.len := by
    simp [sts, alloc.vec.Vec.deref, UScalar.lt_equiv]
  simp only [hz, if_pos] at hf
  obtain ⟨statement, hi, hf⟩ := bind_tc_eq_ok.mp hf
  have hs : statement = st := by
    have hi' := slice_index_ok hi
    simpa [sts, alloc.vec.Vec.deref] using hi'.2.symm
  subst statement
  rw [heff] at hf
  simp only [bind_tc_ok, bind_ok, decide_true, if_true] at hf
  obtain ⟨answer, ha, _⟩ := bind_tc_eq_ok.mp hf
  unfold stmts.bp_statement_is_allowed at ha
  obtain ⟨reaches, hr, _⟩ := bind_tc_eq_ok.mp ha
  unfold stmts.bp_reaches_condition_eval at hr
  have hacts : ¬ (alloc.vec.Vec.len st.actions > 0#usize) := by
    simp [st, UScalar.lt_equiv]
  simp only [hacts, if_neg] at hr
  rw [eq_ok_of_spec principal_matches] at hr
  simp only [bind_tc_ok, bind_ok, if_true] at hr
  rw [heff] at hr
  simp only [bind_tc_ok, bind_ok, decide_true, if_true] at hr
  rw [eq_ok_of_spec actions_cover] at hr
  simp only [bind_tc_ok, bind_ok, if_true] at hr
  obtain ⟨prefix_name, _, hr⟩ := bind_tc_eq_ok.mp hr
  rw [eq_ok_of_spec (no_references prefix_name)] at hr
  simp only [bind_tc_ok, bind_ok] at hr
  obtain ⟨resource, _, hr⟩ := bind_tc_eq_ok.mp hr
  have hres : alloc.vec.Vec.len st.resources > 0#usize := by
    simp [st, UScalar.lt_equiv]
  simp only [hres, if_pos] at hr
  obtain ⟨answer, hmatch, _⟩ := bind_tc_eq_ok.mp hr
  exact ⟨resource, answer, hmatch⟩

theorem successful_resource_reaches_substitution (resource : Slice U8) (answer : Bool)
    (h : rsrc.set_is_match (alloc.vec.Vec.deref st.resources)
      resource args.conditions none = ok answer) :
    ∃ resolved, rsrc.substitute_common (alloc.vec.Vec.deref marker0) values = ok resolved := by
  unfold rsrc.set_is_match rsrc.set_is_match_loop at h
  rw [loop] at h
  obtain ⟨first, hf, _⟩ := bind_tc_eq_ok.mp h
  unfold rsrc.set_is_match_loop.body at hf
  have hz : (0#usize : Usize) < (alloc.vec.Vec.deref st.resources).len := by
    simp [st, alloc.vec.Vec.deref, UScalar.lt_equiv]
  simp only [hz, if_pos] at hf
  obtain ⟨r, hi, hf⟩ := bind_tc_eq_ok.mp hf
  have hs : r = .S3 marker0 := by
    have hi' := slice_index_ok hi
    simpa [st, alloc.vec.Vec.deref] using hi'.2.symm
  subst r
  obtain ⟨match_result, hm, _⟩ := bind_tc_eq_ok.mp hf
  unfold rsrc.resource_is_match at hm
  simp only [u8vec_clone, bind_tc_ok, bind_ok] at hm
  obtain ⟨patterns, hp, hm⟩ := bind_tc_eq_ok.mp hm
  have hpush : (alloc.vec.Vec.new (alloc.vec.Vec U8)).val.length < Usize.max := by
    apply usize_lt_max
    norm_num
  have hpv := post_of_ok (alloc.vec.Vec.push_spec
    (alloc.vec.Vec.new (alloc.vec.Vec U8)) marker0 hpush) hp
  simp only [alloc.vec.Vec.new, alloc.vec.Vec.from_val, List.nil_append] at hpv
  unfold rsrc.resource_is_match_loop at hm
  rw [loop] at hm
  obtain ⟨first, hf, _⟩ := bind_tc_eq_ok.mp hm
  unfold rsrc.resource_is_match_loop.body at hf
  have hz : (0#usize : Usize) < patterns.len := by
    simp [UScalar.lt_equiv, hpv]
  simp only [hz, if_pos] at hf
  obtain ⟨pattern, hi, hf⟩ := bind_tc_eq_ok.mp hf
  have hi' : pattern = marker0 := by
    have hi' := vec_index_slice_ok_get? hi
    simpa [hpv] using hi'.symm
  subst pattern
  obtain ⟨matched, hm, _⟩ := bind_tc_eq_ok.mp hf
  unfold rsrc.pattern_matches at hm
  have hv : alloc.vec.Vec.len args.conditions > 0#usize := by
    simp [args, values, UScalar.lt_equiv]
  simp only [hv, if_pos] at hm
  obtain ⟨resolved, hr, _⟩ := bind_tc_eq_ok.mp hm
  exact ⟨resolved, hr⟩

theorem successful_evaluation_reaches_substitution (env : condfuncs.Env) (result : Bool)
    (h : policies.bucket_policy_is_allowed sts args env = ok result) :
    ∃ resolved, rsrc.substitute_common (alloc.vec.Vec.deref marker0) values = ok resolved := by
  obtain ⟨resource, answer, hr⟩ := successful_evaluation_reaches_resource env result h
  exact successful_resource_reaches_substitution _ answer hr

@[step] theorem starts_loop_prefix (s p : Slice U8) (base i : Usize)
    (suffix : List U8) (hp : s.val.drop base.val = p.val ++ suffix)
    (hb : base.val ≤ s.val.length) (hi : i.val ≤ p.val.length) :
    bytes.starts_with_at_loop s base p i ⦃ r => r = true ⦄ := by
  have hl := congrArg List.length hp
  simp only [List.length_drop, List.length_append] at hl
  unfold bytes.starts_with_at_loop
  apply loop_idx_spec _ id p.val.length (fun _ => True) (fun r => r = true) _ i trivial hi
  intro j _ hj
  unfold bytes.starts_with_at_loop.body
  h5i_steps
  all_goals simp_all
  all_goals try scalar_tac
  have hjlt : j.val < p.val.length := by scalar_tac
  have hget := congrArg (fun l : List U8 => l[j.val]?) hp
  simp only [List.getElem?_drop, List.getElem?_append_left hjlt] at hget
  have hsi : base.val + j.val < s.val.length := by omega
  simp only [List.getElem?_eq_getElem hsi, List.getElem?_eq_getElem hjlt,
    Option.some.injEq] at hget
  have heq := congrArg UScalar.val hget
  simp_all [Nat.add_comm]
  all_goals scalar_tac

@[step] theorem starts_at_prefix (s p : Slice U8) (base : Usize)
    (suffix : List U8) (hp : s.val.drop base.val = p.val ++ suffix)
    (hb : base.val ≤ s.val.length) :
    bytes.starts_with_at s base p ⦃ r => r = true ⦄ := by
  have hl := congrArg List.length hp
  simp only [List.length_drop, List.length_append] at hl
  unfold bytes.starts_with_at
  h5i_steps
  all_goals try scalar_tac

theorem push_success_val {T : Type} {out result : alloc.vec.Vec T} {b : T}
    (h : alloc.vec.Vec.push out b = ok result) : result.val = out.val ++ [b] := by
  unfold alloc.vec.Vec.push at h
  dsimp only at h
  split at h
  · simp only [ok.injEq] at h
    subst result
    simp
  · simp at h

theorem copy_success_val («to» : Slice U8) (initial : alloc.vec.Vec U8)
    (start : Usize) (result : alloc.vec.Vec U8) (hbound : start.val ≤ «to».val.length)
    (h : bytes.replace_loop0_loop0 «to» initial start = ok result) :
    result.val = initial.val ++ «to».val.drop start.val := by
  unfold bytes.replace_loop0_loop0 at h
  refine loop_idx_ok _ Prod.snd «to».val.length
    (fun x => x.1.val ++ «to».val.drop x.2.val = initial.val ++ «to».val.drop start.val)
    (fun r => r.val = initial.val ++ «to».val.drop start.val) ?_
    (initial, start) result rfl hbound h
  rintro ⟨out, j⟩ next hin hj hs
  unfold bytes.replace_loop0_loop0.body at hs
  by_cases hlt : j < «to».len
  · simp only [hlt, if_pos] at hs
    obtain ⟨b, hb, hs⟩ := bind_tc_eq_ok.mp hs
    obtain ⟨out', ho, hs⟩ := bind_tc_eq_ok.mp hs
    obtain ⟨j', hinc, hs⟩ := bind_tc_eq_ok.mp hs
    have hb' := (slice_index_ok hb).2
    have ho' := push_success_val ho
    have hinc' := add_ok_val hinc
    simp only [ok.injEq] at hs
    subst next
    have hjlt : j.val < «to».val.length := by scalar_tac
    refine ⟨?_, ?_, ?_⟩
    · simp only [ho', hinc', UScalar.ofNatCore_val_eq, ← hb', List.append_assoc]
      rw [List.drop_eq_getElem_cons hjlt] at hin
      simpa only [List.cons_append, List.nil_append] using hin
    · simp only [hinc', UScalar.ofNatCore_val_eq]
      omega
    · simp only [hinc', UScalar.ofNatCore_val_eq]
      omega
  · simp only [hlt, if_neg, if_false, ok.injEq] at hs
    subst next
    have hjend : «to».val.length ≤ j.val := by scalar_tac
    simpa only [List.drop_eq_nil_of_le hjend, List.append_nil] using hin

def repeated (l : List U8) (n : Nat) : List U8 := (List.replicate n l).flatten

@[simp] theorem repeated_zero (l : List U8) : repeated l 0 = [] := rfl

@[simp] theorem repeated_one (l : List U8) : repeated l 1 = l := by simp [repeated]

@[simp] theorem repeated_length (l : List U8) (n : Nat) :
    (repeated l n).length = n * l.length := by
  simp [repeated, List.length_flatten, List.map_replicate, List.sum_replicate]

theorem repeated_add (l : List U8) (n m : Nat) :
    repeated l (n + m) = repeated l n ++ repeated l m := by
  simp only [repeated, List.replicate_add, List.flatten_append]

theorem repeated_succ (l : List U8) (n : Nat) :
    repeated l (n + 1) = l ++ repeated l n := by
  simp [repeated, List.replicate_succ]

theorem repeated_drop (l : List U8) (n k : Nat) (hk : k ≤ n) :
    (repeated l n).drop (k * l.length) = repeated l (n - k) := by
  have he : repeated l n = repeated l k ++ repeated l (n - k) := by
    rw [← repeated_add]
    congr 1
    omega
  rw [he, ← repeated_length l k]
  simp

theorem repeated_nested (l : List U8) (n m : Nat) :
    repeated (repeated l m) n = repeated l (n * m) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [repeated_succ, ih, Nat.succ_mul, Nat.add_comm, repeated_add]

theorem replace_repeated_success (s «from» «to» : Slice U8) (n : Nat)
    (result : alloc.vec.Vec U8) (hs : s.val = repeated «from».val n)
    (hpos : 0 < «from».val.length)
    (h : bytes.replace s «from» «to» = ok result) :
    result.val = repeated «to».val n := by
  have hlen : s.val.length = n * «from».val.length := by simp [hs]
  unfold bytes.replace bytes.replace_loop0 at h
  refine loop_idx_ok _ Prod.snd s.val.length
    (fun x => ∃ k, k ≤ n ∧ x.2.val = k * «from».val.length ∧ x.1.val = repeated «to».val k)
    (fun r => r.val = repeated «to».val n) ?_
    (alloc.vec.Vec.new U8, 0#usize) result ?_ (by simp) h
  · rintro ⟨out, i⟩ next ⟨k, hk, hi, hout⟩ hib hstep
    dsimp only at hi hout hib
    unfold bytes.replace_loop0.body at hstep
    by_cases hlt : i < s.len
    · have hkn : k < n := by
        have hh : k * «from».val.length < n * «from».val.length := by
          simpa only [← hi, ← hlen, UScalar.lt_equiv, Slice.len_val] using hlt
        exact (Nat.mul_lt_mul_right hpos).mp hh
      have hfp : «from».len > 0#usize := by scalar_tac
      simp only [hlt, hfp, if_pos] at hstep
      have hpre : s.val.drop i.val = «from».val ++ repeated «from».val (n - k - 1) := by
        rw [hs, hi, repeated_drop _ _ _ hk]
        have hn : n - k = (n - k - 1) + 1 := by omega
        rw [hn, repeated_succ]
        simp
      have hm := eq_ok_of_spec (starts_at_prefix s «from» i _ hpre hib)
      rw [hm] at hstep
      simp only [bind_tc_ok, bind_ok, if_true] at hstep
      obtain ⟨out', ho, hstep⟩ := bind_tc_eq_ok.mp hstep
      obtain ⟨i', hinc, hstep⟩ := bind_tc_eq_ok.mp hstep
      have ho' := copy_success_val «to» out 0#usize out' (by simp) ho
      have hinc' := add_ok_val hinc
      simp only [ok.injEq] at hstep
      subst next
      have hi' : i'.val = (k + 1) * «from».val.length := by
        simp only [hinc', hi, Slice.len_val, Nat.add_mul, Nat.one_mul]
      refine ⟨⟨k + 1, by omega, hi', ?_⟩, ?_, ?_⟩
      · simp only [ho', UScalar.ofNatCore_val_eq, List.drop_zero, hout]
        rw [repeated_add, repeated_one]
      · simp only [hi', hi, Nat.add_mul, Nat.one_mul]
        omega
      · rw [hi', hlen]
        exact Nat.mul_le_mul_right _ (by omega)
    · simp only [hlt, if_neg, if_false, ok.injEq] at hstep
      subst next
      have hiend : s.val.length ≤ i.val := by scalar_tac
      have hkn : k = n := by
        by_contra hneq
        have hklt : k < n := by omega
        have hh := Nat.mul_lt_mul_of_pos_right hklt hpos
        omega
      simpa [hkn] using hout
  · exact ⟨0, Nat.zero_le _, by simp, by simp⟩

@[step] theorem bytes_equal_spec (a b : Slice U8) :
    bytes.eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold bytes.eq
  dsimp only
  split
  · step*
    all_goals simp_all
    all_goals scalar_tac
  · have hlen : a.val.length = b.val.length := by scalar_tac
    unfold bytes.eq_loop
    h5i_search_all (a.val.zip b.val) (fun p => p.1 != p.2)
    all_goals simp_all -failIfUnchanged [List.length_zip, List.getElem_zip, zip_all_eq, SearchStep]
    rename_i hr
    rw [← hr]
    calc
      _ = (a.val.zip b.val).all (fun p => decide (p.1 = p.2)) := by
        congr 1
        funext p
        simp [bne]
        apply Bool.eq_iff_iff.mpr
        simp
      _ = decide (a.val = b.val) := zip_all_eq _ _ hlen

@[step] theorem get_value_spec
    (ctx : alloc.vec.Vec ((alloc.vec.Vec U8) × (alloc.vec.Vec (alloc.vec.Vec U8))))
    («name» : Slice U8) :
    condfuncs.get_value ctx «name»
      ⦃ r => r = (ctx.val.find? (fun p => decide (p.1.val = «name».val))).map Prod.snd ⦄ := by
  unfold condfuncs.get_value condfuncs.get_value_loop
  apply WP.spec_mono (loop_search ctx.val (fun p => decide (p.1.val = «name».val)) id
    (fun _ p => some p.2) none _ ?_ 0#usize (by simp))
  · intro r hr
    simpa [searchFrom_find] using hr
  · intro j hj
    unfold condfuncs.get_value_loop.body
    h5i_step [alloc.vec.Vec.deref]
    all_goals have hlt : j.val < ctx.val.length := by scalar_tac
    all_goals refine ⟨hlt, ?_⟩
    all_goals rw [← v_post]
    all_goals simp_all

theorem get_value0 : condfuncs.get_value values name0.deref = ok (some (vecOf [value0])) := by
  apply eq_ok_of_spec
  have h := get_value_spec values name0.deref
  simpa [values, alloc.vec.Vec.deref, name0, name1, name2, name3, name4, name5, name6, name7] using h

theorem get_value1 : condfuncs.get_value values name1.deref = ok (some (vecOf [value1])) := by
  apply eq_ok_of_spec
  have h := get_value_spec values name1.deref
  simpa [values, alloc.vec.Vec.deref, name0, name1, name2, name3, name4, name5, name6, name7] using h

theorem get_value2 : condfuncs.get_value values name2.deref = ok (some (vecOf [value2])) := by
  apply eq_ok_of_spec
  have h := get_value_spec values name2.deref
  simpa [values, alloc.vec.Vec.deref, name0, name1, name2, name3, name4, name5, name6, name7] using h

theorem get_value3 : condfuncs.get_value values name3.deref = ok (some (vecOf [value3])) := by
  apply eq_ok_of_spec
  have h := get_value_spec values name3.deref
  simpa [values, alloc.vec.Vec.deref, name0, name1, name2, name3, name4, name5, name6, name7] using h

theorem get_value4 : condfuncs.get_value values name4.deref = ok (some (vecOf [value4])) := by
  apply eq_ok_of_spec
  have h := get_value_spec values name4.deref
  simpa [values, alloc.vec.Vec.deref, name0, name1, name2, name3, name4, name5, name6, name7] using h

theorem get_value5 : condfuncs.get_value values name5.deref = ok (some (vecOf [value5])) := by
  apply eq_ok_of_spec
  have h := get_value_spec values name5.deref
  simpa [values, alloc.vec.Vec.deref, name0, name1, name2, name3, name4, name5, name6, name7] using h

theorem get_value6 : condfuncs.get_value values name6.deref = ok (some (vecOf [value6])) := by
  apply eq_ok_of_spec
  have h := get_value_spec values name6.deref
  simpa [values, alloc.vec.Vec.deref, name0, name1, name2, name3, name4, name5, name6, name7] using h

theorem get_value7 : condfuncs.get_value values name7.deref = ok (some (vecOf [value7])) := by
  apply eq_ok_of_spec
  have h := get_value_spec values name7.deref
  simpa [values, alloc.vec.Vec.deref, name0, name1, name2, name3, name4, name5, name6, name7] using h

theorem common_step_success (k next : Usize) («name» marker value : alloc.vec.Vec U8)
    (out result : alloc.vec.Vec U8) (count : Nat)
    (hk : k < keynames.COMMON_KEYS_LEN) (hn : next.val = k.val + 1)
    (hkey : keynames.common_key k = ok («name», marker))
    (hget : condfuncs.get_value values «name».deref = ok (some (vecOf [value])))
    (hmarker : 0 < marker.length) (hvalue : 0 < value.length)
    (hout : out.val = repeated marker.val count)
    (h : rsrc.substitute_common_loop values out k = ok result) :
    ∃ out', out'.val = repeated value.val count ∧
      rsrc.substitute_common_loop values out' next = ok result := by
  unfold rsrc.substitute_common_loop at h
  rw [loop] at h
  obtain ⟨first, hf, hrest⟩ := bind_tc_eq_ok.mp h
  unfold rsrc.substitute_common_loop.body at hf
  have hsingle : alloc.vec.Vec.len (vecOf [value]) > 0#usize := by simp [UScalar.lt_equiv]
  have hv : alloc.vec.Vec.len value > 0#usize := by scalar_tac
  have hi : alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice (alloc.vec.Vec U8))
      (vecOf [value]) 0#usize = ok value := by
    simp [alloc.vec.Vec.index_slice_index, alloc.vec.Vec.index_usize]
  simp only [hk, if_pos, hkey, bind_ok, bind_tc_ok] at hf
  try dsimp only at hf
  simp only [hget, bind_ok, bind_tc_ok, hsingle, hi, hv, if_pos] at hf
  obtain ⟨out', hr, hf⟩ := bind_tc_eq_ok.mp hf
  obtain ⟨k', hinc, hf⟩ := bind_tc_eq_ok.mp hf
  have hk' : k' = next := by
    apply UScalar.eq_of_val_eq
    have hinc' := add_ok_val hinc
    simpa only [hn, UScalar.ofNatCore_val_eq] using hinc'
  subst k'
  simp only [ok.injEq] at hf
  subst first
  refine ⟨out', ?_, hrest⟩
  apply replace_repeated_success out.deref marker.deref value.deref count out'
  · simpa only [alloc.vec.Vec.deref, Slice.from_val] using hout
  · simpa [alloc.vec.Vec.deref] using hmarker
  · exact hr

theorem common_step_next (k next : Usize) («name» marker value nextmarker : alloc.vec.Vec U8)
    (out result : alloc.vec.Vec U8) (count : Nat)
    (hk : k < keynames.COMMON_KEYS_LEN) (hn : next.val = k.val + 1)
    (hkey : keynames.common_key k = ok («name», marker))
    (hget : condfuncs.get_value values «name».deref = ok (some (vecOf [value])))
    (hmarker : 0 < marker.length) (hvalue : 0 < value.length)
    (hv : value.val = repeated nextmarker.val 200)
    (hout : out.val = repeated marker.val count)
    (h : rsrc.substitute_common_loop values out k = ok result) :
    ∃ out', out'.val = repeated nextmarker.val (count * 200) ∧
      rsrc.substitute_common_loop values out' next = ok result := by
  obtain ⟨out', ho, hr⟩ := common_step_success k next «name» marker value out result count
    hk hn hkey hget hmarker hvalue hout h
  refine ⟨out', ?_, hr⟩
  simpa only [hv, repeated_nested] using ho

theorem substitution_cannot_succeed :
    ¬ ∃ result, rsrc.substitute_common marker0.deref values = ok result := by
  rintro ⟨result, h⟩
  unfold rsrc.substitute_common at h
  obtain ⟨out0, hc, h0⟩ := bind_tc_eq_ok.mp h
  have hcs := post_of_ok (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 marker0.deref
    (fun _ _ => rfl)) hc
  have ho0 : out0.val = repeated marker0.val 1 := by
    simp only [repeated_one]
    have hv := congrArg Slice.val hcs
    simpa [alloc.vec.Vec.deref, alloc.vec.Vec.val] using hv.symm
  obtain ⟨out1, ho1, h1⟩ := common_step_next 0#usize 1#usize name0 marker0 value0 marker1
    out0 result 1 (by simp [keynames.COMMON_KEYS_LEN, UScalar.lt_equiv]) (by simp)
    (eq_ok_of_spec common_key0_matches) get_value0 (by norm_num [marker0]) (by simp)
    (by simp only [value0, vecOf_val, repeated]) ho0 h0
  obtain ⟨out2, ho2, h2⟩ := common_step_next 1#usize 2#usize name1 marker1 value1 marker2
    out1 result 200 (by simp [keynames.COMMON_KEYS_LEN, UScalar.lt_equiv]) (by simp)
    (eq_ok_of_spec common_key1_matches) get_value1 (by norm_num [marker1]) (by simp)
    (by simp only [value1, vecOf_val, repeated]) ho1 h1
  obtain ⟨out3, ho3, h3⟩ := common_step_next 2#usize 3#usize name2 marker2 value2 marker3
    out2 result 40000 (by simp [keynames.COMMON_KEYS_LEN, UScalar.lt_equiv]) (by simp)
    (eq_ok_of_spec common_key2_matches) get_value2 (by norm_num [marker2]) (by simp)
    (by simp only [value2, vecOf_val, repeated]) ho2 h2
  obtain ⟨out4, ho4, h4⟩ := common_step_next 3#usize 4#usize name3 marker3 value3 marker4
    out3 result 8000000 (by simp [keynames.COMMON_KEYS_LEN, UScalar.lt_equiv]) (by simp)
    (eq_ok_of_spec common_key3_matches) get_value3 (by norm_num [marker3]) (by simp)
    (by simp only [value3, vecOf_val, repeated]) ho3 h3
  obtain ⟨out5, ho5, h5⟩ := common_step_next 4#usize 5#usize name4 marker4 value4 marker5
    out4 result 1600000000 (by simp [keynames.COMMON_KEYS_LEN, UScalar.lt_equiv]) (by simp)
    (eq_ok_of_spec common_key4_matches) get_value4 (by norm_num [marker4]) (by simp)
    (by simp only [value4, vecOf_val, repeated]) ho4 h4
  obtain ⟨out6, ho6, h6⟩ := common_step_next 5#usize 6#usize name5 marker5 value5 marker6
    out5 result 320000000000 (by simp [keynames.COMMON_KEYS_LEN, UScalar.lt_equiv]) (by simp)
    (eq_ok_of_spec common_key5_matches) get_value5 (by norm_num [marker5]) (by simp)
    (by simp only [value5, vecOf_val, repeated]) ho5 h5
  obtain ⟨out7, ho7, h7⟩ := common_step_next 6#usize 7#usize name6 marker6 value6 marker7
    out6 result 64000000000000 (by simp [keynames.COMMON_KEYS_LEN, UScalar.lt_equiv]) (by simp)
    (eq_ok_of_spec common_key6_matches) get_value6 (by norm_num [marker6]) (by simp)
    (by simp only [value6, vecOf_val, repeated]) ho6 h6
  obtain ⟨out8, ho8, _⟩ := common_step_next 7#usize 8#usize name7 marker7 value7 marker8
    out7 result 12800000000000000 (by simp [keynames.COMMON_KEYS_LEN, UScalar.lt_equiv]) (by simp)
    (eq_ok_of_spec common_key7_matches) get_value7 (by norm_num [marker7]) (by simp)
    (by simp only [value7, vecOf_val, repeated]) ho7 h7
  have hbound := out8.property
  rw [ho8, repeated_length] at hbound
  have hover := eighth_output_exceeds_usize
  norm_num [marker8] at hbound hover
  omega

theorem bucket_policy_counterexample (env : condfuncs.Env) :
    ¬ ∃ result, policies.bucket_policy_is_allowed sts args env = ok result := by
  rintro ⟨result, h⟩
  exact substitution_cannot_succeed (successful_evaluation_reaches_substitution env result h)
end BucketCounterexample
