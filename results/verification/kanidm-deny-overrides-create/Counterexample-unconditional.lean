import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel
open H5iAppLib hiding lit
open ControlFlow

namespace kanidm_kernel.Counterexample

@[simp] theorem deref_slice {T} (v : alloc.vec.Vec T) : v.deref = v.slice := by
  apply Slice.ext
  simp [alloc.vec.Vec.deref, alloc.vec.Vec.val]

@[simp] theorem vec_slice_val {T} (l : List T) (h : l.length ≤ Usize.max) :
    (vecOf l h).slice.val = l := by
  change (vecOf l h).val = _
  simp

def long (b : U8) : alloc.vec.Vec U8 :=
  vecOf (List.replicate Usize.max b) (by simp)

@[simp, scalar_tac_simps] theorem long_slice_val (b : U8) :
    (long b).slice.val = List.replicate Usize.max b := by
  change (long b).val = _
  simp [long]

@[simp] theorem long_length (b : U8) : (long b).val.length = Usize.max := by
  simp [long]

@[simp] theorem long_first (b : U8) : (long b).val[0]? = some b := by
  have hm : 0 < Usize.max := lt_of_lt_of_le (by decide : 0 < 2 ^ 32 - 1) usize_max_ge
  simp [long, hm]

-- Even a scan with only one failed comparison can overflow on its next iteration.
theorem substring_failure :
    valueset.str_contains (long 1#u8).slice (long 0#u8).slice =
      fail .integerOverflow := by
  have zadd (x : Usize) : 0#usize + x = ok x := by
    apply eq_ok_of_spec
    step*
  have oadd : 0#usize + 1#usize = ok 1#usize := zadd _
  have ov (x : Usize) (hx : x.val = Usize.max) :
      1#usize + x = fail .integerOverflow := by
    have hb : ¬ UScalar.check_bounds .Usize (1 + x.val) := by
      rw [UScalar.check_bounds_eq_inBounds]
      simp only [UScalar.inBounds]
      have hp : 0 < 2 ^ UScalarTy.Usize.numBits := Nat.two_pow_pos _
      rw [Usize.max_def] at hx
      simp only [Usize.numBits, UScalarTy.numBits] at *
      omega
    change UScalar.tryMk .Usize (1 + x.val) = _
    simp only [UScalar.tryMk, UScalar.tryMkOpt, dif_neg hb, Result.ofOption]
  have first : valueset.starts_at_loop.body (long 1#u8).slice 0#usize
      (long 0#u8).slice 0#usize = ok (done false) := by
    apply eq_ok_of_spec
    unfold valueset.starts_at_loop.body
    have hm := usize_max_ge
    step* <;> simp_all
  have start : valueset.starts_at (long 1#u8).slice 0#usize
      (long 0#u8).slice = ok false := by
    rw [valueset.starts_at, valueset.starts_at_loop, loop, first]
    simp
  have second : valueset.str_contains_loop.body (long 1#u8).slice
      (long 0#u8).slice 1#usize = fail .integerOverflow := by
    unfold valueset.str_contains_loop.body
    dsimp only
    rw [ov _ (by simp)]
    simp
  have first_scan : valueset.str_contains_loop.body (long 1#u8).slice
      (long 0#u8).slice 0#usize = ok (cont 1#usize) := by
    apply eq_ok_of_spec
    unfold valueset.str_contains_loop.body
    have st : valueset.starts_at (long 1#u8).slice 0#usize (long 0#u8).slice
        ⦃ r => r = false ⦄ := by simp [start]
    step*; simp_all; scalar_tac
  unfold valueset.str_contains
  dsimp only
  have hlen : ¬ Slice.len (long 0#u8).slice > Slice.len (long 1#u8).slice := by
    scalar_tac
  simp only [hlen, ↓reduceIte]
  rw [valueset.str_contains_loop, loop, first_scan]
  simp only [bind_ok]
  rw [loop, second]
  simp

@[step] theorem bytes_self (a : Slice U8) :
    bset.bytes_eq a a ⦃ r => r = true ⦄ := by
  unfold bset.bytes_eq
  dsimp only
  simp only [bne_self_eq_false, Bool.false_eq_true, ↓reduceIte]
  unfold bset.bytes_eq_loop
  h5i_search_all a.val (fun _ => false)
  simp_all [searchFrom_const]

def uuidAttr : alloc.vec.Vec U8 := vecOf [117#u8, 117#u8, 105#u8, 100#u8]
def classAttr : alloc.vec.Vec U8 := vecOf [99#u8, 108#u8, 97#u8, 115#u8, 115#u8]

def entry : Entry := ⟨0#u128, vecOf
  [⟨uuidAttr, .Uuid (vecOf [0#u128])⟩,
   ⟨classAttr, .Iutf8 (vecOf [long 1#u8])⟩]⟩

def ident : Identity := ⟨.User ⟨entry⟩, .ReadWrite⟩

def profile : profiles.AccessControlCreateResolved :=
  { receiver_condition := .GroupChecked
    target_condition := .Scope (.Cnt classAttr (.Iutf8 (long 0#u8)))
    attrs := vecOf []
    classes := vecOf [] }

def related : Slice profiles.AccessControlCreateResolved := (vecOf [profile]).slice

theorem uuid_lookup : entry_impl.get_ava_set entry uuidAttr.slice =
    ok (some (.Uuid (vecOf [0#u128]))) := by
  have hb : entry_impl.get_ava_set_loop.body entry uuidAttr.slice 0#usize =
      ok (done (some (.Uuid (vecOf [0#u128])))) := by
    apply eq_ok_of_spec
    unfold entry_impl.get_ava_set_loop.body
    simp only [entry]
    step* <;> simp_all [vecOf_val]
    all_goals step*
  unfold entry_impl.get_ava_set entry_impl.get_ava_set_loop
  rw [loop, hb]
  simp

theorem class_lookup : entry_impl.get_ava_set entry classAttr.slice =
    ok (some (.Iutf8 (vecOf [long 1#u8]))) := by
  have bd : bset.bytes_eq uuidAttr.slice classAttr.slice = ok false := by
    simp [bset.bytes_eq, uuidAttr, classAttr, Slice.len]
  have hb0 : entry_impl.get_ava_set_loop.body entry classAttr.slice 0#usize =
      ok (cont 1#usize) := by
    apply eq_ok_of_spec
    unfold entry_impl.get_ava_set_loop.body
    simp only [entry]
    step* <;> simp_all [vecOf_val]
    all_goals step* <;> simp_all <;> scalar_tac
  have hb1 : entry_impl.get_ava_set_loop.body entry classAttr.slice 1#usize =
      ok (done (some (.Iutf8 (vecOf [long 1#u8])))) := by
    apply eq_ok_of_spec
    unfold entry_impl.get_ava_set_loop.body
    simp only [entry]
    step* <;> simp_all [vecOf_val]
    all_goals step*
  unfold entry_impl.get_ava_set entry_impl.get_ava_set_loop
  rw [loop, hb0]
  simp only [bind_ok]
  rw [loop, hb1]
  simp

theorem uuid_literal : Array.to_slice (Array.make 4#usize
    [117#u8, 117#u8, 105#u8, 100#u8]) = uuidAttr.slice := by
  apply Slice.ext
  simp [uuidAttr, Array.make, vecOf, alloc.vec.Vec.from]

theorem class_literal : Array.to_slice (Array.make 5#usize
    [99#u8, 108#u8, 97#u8, 115#u8, 115#u8]) = classAttr.slice := by
  apply Slice.ext
  simp [classAttr, Array.make, vecOf, alloc.vec.Vec.from]

theorem uuid_init : entry_impl.get_uuid_init entry = ok (some 0#u128) := by
  unfold entry_impl.get_uuid_init
  simp only [lift, bind_ok, uuid_literal]
  rw [uuid_lookup]
  simp only [bind_ok]
  apply eq_ok_of_spec
  unfold valueset.to_uuid_single
  step* <;> simp_all

theorem classes : entry_impl.get_ava_as_iutf8 entry classAttr.slice =
    ok (some (vecOf [long 1#u8])) := by
  simp [entry_impl.get_ava_as_iutf8, class_lookup, valueset.as_iutf8_set]

theorem protected_denies : create_acc.protected_filter_entry ident entry = ok .Deny := by
  simp [create_acc.protected_filter_entry, ident, uuid_init, UUID_ANONYMOUS]

theorem target_fails : search_acc.target_applies profile.target_condition entry =
    fail .integerOverflow := by
  have hb : valueset.any_contains_loop.body (vecOf [long 1#u8]).slice
      (long 0#u8).slice 0#usize = fail .integerOverflow := by
    simp [valueset.any_contains_loop.body, Slice.index_usize, Slice.len,
      substring_failure]
  have ha : valueset.any_contains (vecOf [long 1#u8]).slice
      (long 0#u8).slice = fail .integerOverflow := by
    rw [valueset.any_contains, valueset.any_contains_loop, loop, hb]
    simp
  simp only [search_acc.target_applies, profile, entry_impl.entry_match_no_index,
    entry_impl.entry_match_no_index_inner, entry_impl.attribute_substring, deref_slice]
  rw [class_lookup]
  simp only [bind_ok, valueset.vs_substring, deref_slice, ha]

theorem create_fails : create_acc.create_filter_entry ident related entry =
    fail .integerOverflow := by
  have hp (ca cc : Slice (alloc.vec.Vec U8)) :
      create_acc.create_acp_allows profile entry ca cc = fail .integerOverflow := by
    unfold create_acc.create_acp_allows
    have ht := target_fails
    simp only [profile] at ht
    simp only [profile]
    rw [ht]
    simp
  have ha (ca cc : Slice (alloc.vec.Vec U8)) :
      create_acc.create_any_acp related entry ca cc = fail .integerOverflow := by
    have hb : create_acc.create_any_acp_loop.body related entry ca cc 0#usize =
        fail .integerOverflow := by
      simp only [create_acc.create_any_acp_loop.body, related, Slice.len,
        vec_slice_val, List.length_cons, List.length_nil]
      simp [Slice.index_usize, hp]
    unfold create_acc.create_any_acp create_acc.create_any_acp_loop
    rw [loop, hb]
    simp
  have hn : entry_impl.get_ava_names entry ⦃ _ => True ⦄ := by
    unfold entry_impl.get_ava_names entry_impl.get_ava_names_loop
    apply loop_idx_spec _ Prod.snd entry.attrs.val.length
      (fun s => s.1.val.length ≤ s.2.val) (fun _ => True) ?_ _ (by simp) (by simp)
    rintro ⟨out, i⟩ hi hi'
    unfold entry_impl.get_ava_names_loop.body
    step*; simp_all; scalar_tac
  obtain ⟨ns, hns⟩ := ok_of hn
  unfold create_acc.create_filter_entry
  simp only [ident, identity_impl.access_scope, bind_ok]
  rw [hns]
  simp only [bind_ok, lift, class_literal]
  rw [classes]
  simp only [bind_ok, ha, bind_fail]

theorem apply_fails : create_acc.apply_create_access ident related entry =
    fail .integerOverflow := by
  unfold create_acc.apply_create_access
  rw [protected_denies]
  simp only [bind_ok]
  have hm : create_acc.message_queue ident entry = ok .Ignore := by
    simp [create_acc.message_queue, ident]
  have hmi : create_acc.migration_filter_entry ident entry = ok .Ignore := by
    simp [create_acc.migration_filter_entry, ident]
  rw [hm]
  simp only [bind_ok]
  rw [hmi]
  simp only [bind_ok]
  rw [create_fails]
  simp

theorem task_is_false : ¬ (∀ (i : Identity)
    (r : Slice profiles.AccessControlCreateResolved) (e : Entry),
    create_acc.protected_filter_entry i e = ok .Deny →
      create_acc.apply_create_access i r e = ok .Deny) := by
  intro h
  have hc := h ident related entry protected_denies
  rw [apply_fails] at hc
  exact fail_ne_ok hc

end kanidm_kernel.Counterexample

#print axioms kanidm_kernel.Counterexample.task_is_false
