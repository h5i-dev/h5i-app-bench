import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel
open H5iAppLib hiding lit

namespace CapacityCounterexample
set_option maxRecDepth 4096

-- The theorem's assumption permits a profile to grant this many names.
def profileNames : List (List U8) :=
  (List.range (Usize.max - 1)).map (fun n => List.replicate n 0#u8)

def className : List U8 := [99#u8, 108#u8, 97#u8, 115#u8, 115#u8]
def displayName : List U8 :=
  [100#u8, 105#u8, 115#u8, 112#u8, 108#u8, 97#u8, 121#u8, 110#u8, 97#u8, 109#u8, 101#u8]

theorem profileNames_length : profileNames.length = Usize.max - 1 := by
  simp [profileNames]

theorem permitted_capacity : profileNames.length < Usize.max := by
  rw [profileNames_length]
  have := usize_max_ge
  omega

theorem profileNames_nodup : profileNames.Nodup := by
  apply List.Nodup.map _ List.nodup_range
  intro a b h
  have := congrArg List.length h
  simpa using this

theorem class_missing : className ∉ profileNames := by
  simp only [profileNames, List.mem_map]
  rintro ⟨n, _, hn⟩
  have hc : 99#u8 ∈ List.replicate n 0#u8 := by
    rw [hn]
    simp [className]
  have : (99#u8 : U8) = 0#u8 := (List.mem_replicate.mp hc).2
  scalar_tac

theorem display_missing : displayName ∉ profileNames := by
  simp only [profileNames, List.mem_map]
  rintro ⟨n, _, hn⟩
  have hc : 100#u8 ∈ List.replicate n 0#u8 := by
    rw [hn]
    simp [displayName]
  have : (100#u8 : U8) = 0#u8 := (List.mem_replicate.mp hc).2
  scalar_tac

theorem distinct_fixed_names : className ≠ displayName := by
  intro h
  have := congrArg List.length h
  simp [className, displayName] at this

theorem after_class_length : (profileNames ++ [className]).length = Usize.max := by
  simp only [List.length_append, profileNames_length, List.length_singleton]
  have := usize_max_ge
  omega

theorem after_display_overflows :
    Usize.max < (profileNames ++ [className, displayName]).length := by
  simp only [List.length_append, profileNames_length, List.length_cons, List.length_nil]
  have := usize_max_ge
  omega

theorem full_push_fails {α : Type} (v : alloc.vec.Vec α) (x : α)
    (h : v.length = Usize.max) :
    v.push x = fail .maximumSizeExceeded := by
  unfold alloc.vec.Vec.push
  have h32 : U32.max ≤ Usize.max := by
    have := usize_max_ge
    simpa [U32.max_def, U32.numBits] using this
  have hlen : v.val.length = Usize.max := h
  simp only [hlen]
  have hfalse : ¬ (Usize.max + 1 ≤ U32.max || Usize.max + 1 ≤ Usize.max) := by
    simp only [Bool.or_eq_true, decide_eq_true_eq]
    omega
  simp
  exact h32

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    bset.bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold bset.bytes_eq
  dsimp only
  split
  · simp only [WP.spec_ok]
    have : a.val ≠ b.val := by
      intro h
      have := congrArg List.length h
      scalar_tac
    simp [this]
  · rename_i hlen
    have hlen' : a.val.length = b.val.length := by scalar_tac
    unfold bset.bytes_eq_loop
    apply WP.spec_mono (loop_search (a.val.zip b.val)
      (fun p => !decide (p.1 = p.2)) id (fun _ _ => false) true _ ?_ 0#usize (by simp))
    · intro r hr
      have hs := search_all _ _ _ hr
      simpa only [id_eq, Bool.not_not, zip_all_eq a.val b.val hlen'] using hs
    · intro i hi
      unfold bset.bytes_eq_loop.body
      h5i_step [List.getElem_zip, hlen']

@[step] theorem contains_spec (s : Slice (alloc.vec.Vec U8)) (x : Slice U8) :
    bset.contains s x ⦃ r => r = s.val.any (fun v => decide (v.val = x.val)) ⦄ := by
  unfold bset.contains bset.contains_loop
  h5i_search_any s.val (fun v => decide (v.val = x.val))
  all_goals simp_all [alloc.vec.Vec.deref]
  all_goals scalar_tac

theorem insert_full_fails (s : alloc.vec.Vec (alloc.vec.Vec U8)) (x : Slice U8)
    (hfull : s.length = Usize.max) (hmissing : ∀ v ∈ s.val, v.val ≠ x.val) :
    bset.insert s x = fail .maximumSizeExceeded := by
  have hb : bset.contains s.deref x = ok false := by
    apply eq_ok_of_spec
    apply WP.spec_mono (contains_spec s.deref x)
    intro b hb
    have hz : s.val.any (fun v => decide (v.val = x.val)) = false := by
      simp only [List.any_eq_false, decide_eq_true_eq]
      exact hmissing
    simpa [alloc.vec.Vec.deref, hz] using hb
  unfold bset.insert
  dsimp only
  rw [hb]
  have hx : alloc.slice.Slice.to_vec core.clone.CloneU8 x = ok (vecOf x.val (by scalar_tac)) := by
    apply eq_ok_of_spec
    step*
    apply alloc.vec.Vec.ext
    simp_all [alloc.vec.Vec.val, vecOf, alloc.vec.Vec.from]
  rw [hx]
  simp only [bind_ok, Bool.false_eq_true, ↓reduceIte]
  exact full_push_fails s _ hfull

def profileVecs : List (alloc.vec.Vec U8) :=
  (List.range (Usize.max - 1)).attach.map fun n =>
    vecOf (List.replicate n.val 0#u8) (by
      simp only [List.length_replicate]
      have hn := List.mem_range.mp n.property
      omega)

theorem profileVecs_vals : profileVecs.map (·.val) = profileNames := by
  simp [profileVecs, profileNames, List.map_map]

def fullAfterClass : alloc.vec.Vec (alloc.vec.Vec U8) :=
  vecOf (profileVecs ++ [vecOf className (by simp [className]; scalar_tac)]) (by
    simp [profileVecs]
    have := usize_max_ge
    omega)

def displayVec : alloc.vec.Vec U8 := vecOf displayName (by simp [displayName]; scalar_tac)

theorem second_fixed_attribute_fails :
    bset.insert fullAfterClass displayVec.deref = fail .maximumSizeExceeded := by
  apply insert_full_fails
  · simp [fullAfterClass, profileVecs]
    have := usize_max_ge
    omega
  · intro v hv heq
    have hd : v.val = displayName := by simpa [displayVec, alloc.vec.Vec.deref] using heq
    have hv' : v.val ∈ profileNames ++ [className] := by
      have hm : v.val ∈ (fullAfterClass.val.map (·.val)) := List.mem_map.mpr ⟨v, hv, rfl⟩
      simpa [fullAfterClass, List.map_append, profileVecs_vals] using hm
    rw [hd] at hv'
    rcases List.mem_append.mp hv' with hp | hc
    · exact display_missing hp
    · have hc' : displayName = className := by simpa using hc
      exact distinct_fixed_names hc'.symm

@[step] theorem insert_fresh_spec (s : alloc.vec.Vec (alloc.vec.Vec U8)) (v : alloc.vec.Vec U8)
    (hcap : s.length < Usize.max) (hfresh : v ∉ s.val) :
    bset.insert s v.deref ⦃ r => r.val = s.val ++ [v] ⦄ := by
  unfold bset.insert
  dsimp only
  step with contains_spec as ⟨b, hb⟩
  have hz : s.val.any (fun w => decide (w.val = v.val)) = false := by
    simp only [List.any_eq_false, decide_eq_true_eq]
    intro w hw he
    have he' : w = v := alloc.vec.Vec.ext _ _ he
    exact hfresh (he' ▸ hw)
  have hb' : b = false := by simpa [alloc.vec.Vec.deref, hz] using hb
  subst b
  step*
  simp only [r_post, List.append_cancel_left_eq, List.singleton_inj]
  apply alloc.vec.Vec.ext
  have hv := congrArg Slice.val v_post
  simpa [alloc.vec.Vec.deref, alloc.vec.Vec.val] using hv.symm

theorem extend_nodup_spec (xs : Slice (alloc.vec.Vec U8)) (hnd : xs.val.Nodup) :
    bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) xs ⦃ r => r.val = xs.val ⦄ := by
  unfold bset.extend bset.extend_loop
  apply loop_idx_spec _ (fun (x : alloc.vec.Vec (alloc.vec.Vec U8) × Usize) => x.2) xs.length
    (fun x => x.1.val = xs.val.take x.2.val) (fun (r : alloc.vec.Vec (alloc.vec.Vec U8)) => r.val = xs.val) _ _ _ _
  · rintro ⟨s, i⟩ hinv hi
    dsimp only at hinv hi ⊢
    unfold bset.extend_loop.body
    dsimp only
    split
    · rename_i hlt
      have hlt' : i.val < xs.val.length := by scalar_tac
      have hs : s.length = i.val := by
        simp only [alloc.vec.Vec.length, hinv, List.length_take, Nat.min_eq_left hi]
      have hfresh : xs.val[i.val] ∉ s.val := by
        rw [hinv]
        intro hm
        obtain ⟨j, hj, heq⟩ := List.mem_take_iff_getElem.mp hm
        have hji : j = i.val := (hnd.getElem_inj_iff).mp heq
        omega
      step
      step with insert_fresh_spec s v (by scalar_tac) (by simp_all) as ⟨t, ht⟩
      step*
      refine ⟨?_, by scalar_tac, by scalar_tac⟩
      simp_all only [List.take_succ_eq_append_getElem hlt']
    · simp only [WP.spec_ok]
      have heq : i.val = xs.length := by scalar_tac
      simpa [heq] using hinv
  · simp
  · simp

def profileAttrs : alloc.vec.Vec (alloc.vec.Vec U8) :=
  vecOf profileVecs (by simp [profileVecs])

def classVec : alloc.vec.Vec U8 := vecOf className (by simp [className]; scalar_tac)

def control : AccessControlsInner :=
  { acps_search := vecOf [
      { acp := { receiver := .Group (vecOf [1#u128]), target := .Scope (.Pres classVec) },
        attrs := profileAttrs }]
    acps_create := alloc.vec.Vec.new _
    acps_modify := alloc.vec.Vec.new _
    acps_delete := alloc.vec.Vec.new _
    sync_agreements := alloc.vec.Vec.new _ }

theorem control_satisfies_hcap :
    (control.acps_search.val.map (·.attrs.length)).sum +
      (control.acps_modify.val.map (fun m => m.presattrs.length + m.remattrs.length +
        m.pres_classes.length + m.rem_classes.length)).sum +
      (control.sync_agreements.val.map (·.attrs.length)).sum < Usize.max := by
  simp [control, profileAttrs, profileVecs]
  have := usize_max_ge
  omega

theorem profileAttrs_nodup : profileAttrs.val.Nodup := by
  apply List.Nodup.of_map (f := fun v : alloc.vec.Vec U8 => v.val)
  simpa [profileAttrs, profileVecs_vals] using profileNames_nodup

theorem profile_collection :
    bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) profileAttrs.deref = ok profileAttrs := by
  apply eq_ok_of_spec
  apply WP.spec_mono (extend_nodup_spec profileAttrs.deref (by
    simpa [alloc.vec.Vec.deref] using profileAttrs_nodup))
  intro r hr
  apply alloc.vec.Vec.ext
  simpa [alloc.vec.Vec.deref] using hr

theorem first_fixed_attribute :
    bset.insert profileAttrs classVec.deref = ok fullAfterClass := by
  apply eq_ok_of_spec
  apply WP.spec_mono (insert_fresh_spec profileAttrs classVec (by
    simp [profileAttrs, profileVecs]
    have := usize_max_ge
    omega) (by
    intro hm
    have hm' : className ∈ profileNames := by
      have hh : classVec.val ∈ profileAttrs.val.map (·.val) := List.mem_map.mpr ⟨classVec, hm, rfl⟩
      simpa [profileAttrs, profileVecs_vals, classVec] using hh
    exact class_missing hm'))
  intro r hr
  apply alloc.vec.Vec.ext
  simpa [profileAttrs, fullAfterClass, classVec] using hr

-- This is the sequence of set operations used when the profile grants its
-- names and the application module adds its first two fixed attributes.
theorem search_attribute_collection_overflows :
    (do
      let s ← bset.extend (alloc.vec.Vec.new (alloc.vec.Vec U8)) profileAttrs.deref
      let s1 ← bset.insert s classVec.deref
      bset.insert s1 displayVec.deref) = fail .maximumSizeExceeded := by
  rw [profile_collection]
  simp only [bind_ok]
  rw [first_fixed_attribute]
  simp only [bind_ok]
  exact second_fixed_attribute_fails


open Aeneas.Std.WP

@[simp] theorem bytes_eq_eq (a b : Slice U8) :
    bset.bytes_eq a b = ok (decide (a.val = b.val)) := eq_ok_of_spec (bytes_eq_spec a b)

@[simp] theorem contains_eq (s : Slice (alloc.vec.Vec U8)) (x : Slice U8) :
    bset.contains s x = ok (s.val.any (fun v => decide (v.val = x.val))) :=
  eq_ok_of_spec (contains_spec s x)

@[step] theorem get_ava_set_spec (e : Entry) (attr : Slice U8) :
    entry_impl.get_ava_set e attr ⦃ r =>
      r = (e.attrs.val.find? (fun a => decide (a.attr.val = attr.val))).map (·.vs) ⦄ := by
  unfold entry_impl.get_ava_set entry_impl.get_ava_set_loop
  apply WP.spec_mono (loop_search e.attrs.val
    (fun a => decide (a.attr.val = attr.val)) id (fun _ a => some a.vs) none _ ?_ 0#usize (by simp))
  · intro r hr
    simp only [id_eq] at hr
    rw [hr, searchFrom_find]
    simp
  · intro i hi
    unfold entry_impl.get_ava_set_loop.body
    h5i_step [alloc.vec.Vec.deref]

@[simp] theorem get_ava_set_eq (e : Entry) (attr : Slice U8) :
    entry_impl.get_ava_set e attr =
      ok ((e.attrs.val.find? (fun a => decide (a.attr.val = attr.val))).map (·.vs)) :=
  eq_ok_of_spec (get_ava_set_spec e attr)

@[step] theorem contains_uuid_spec (s : Slice U128) (u : U128) :
    bset.contains_uuid s u ⦃ r => r = s.val.any (fun x => decide (x = u)) ⦄ := by
  unfold bset.contains_uuid bset.contains_uuid_loop
  h5i_search_any s.val (fun x => decide (x = u))

@[simp] theorem contains_uuid_eq (s : Slice U128) (u : U128) :
    bset.contains_uuid s u = ok (s.val.any (fun x => decide (x = u))) :=
  eq_ok_of_spec (contains_uuid_spec s u)

@[step] theorem intersects_uuid_spec (a b : Slice U128) :
    bset.intersects_uuid a b ⦃ r =>
      r = a.val.any (fun x => b.val.any (fun y => decide (y = x))) ⦄ := by
  unfold bset.intersects_uuid bset.intersects_uuid_loop
  h5i_search_any a.val (fun x => b.val.any (fun y => decide (y = x)))
  refine ⟨by scalar_tac, ?_⟩
  intro hm
  exact b1_post _ hm rfl

@[simp] theorem intersects_uuid_eq (a b : Slice U128) :
    bset.intersects_uuid a b = ok (a.val.any (fun x => b.val.any (fun y => decide (y = x)))) :=
  eq_ok_of_spec (intersects_uuid_spec a b)

def groups : alloc.vec.Vec U128 := vecOf [1#u128]
def memberName : alloc.vec.Vec U8 :=
  vecOf [109#u8,101#u8,109#u8,98#u8,101#u8,114#u8,111#u8,102#u8]
def linkedName : alloc.vec.Vec U8 :=
  vecOf [108#u8,105#u8,110#u8,107#u8,101#u8,100#u8,95#u8,103#u8,114#u8,111#u8,117#u8,112#u8]
def applicationName : alloc.vec.Vec U8 :=
  vecOf [97#u8,112#u8,112#u8,108#u8,105#u8,99#u8,97#u8,116#u8,105#u8,111#u8,110#u8]
def uuidName : alloc.vec.Vec U8 := vecOf [117#u8,117#u8,105#u8,100#u8]
def nameName : alloc.vec.Vec U8 := vecOf [110#u8,97#u8,109#u8,101#u8]
def userEntry : Entry :=
  { uuid := 2#u128, attrs := vecOf [{ attr := memberName, vs := .Refer groups }] }
def user : Identity := { origin := .User { entry := userEntry }, scope := .ReadOnly }
def targetEntry : Entry :=
  { uuid := 3#u128, attrs := vecOf [
    { attr := classVec, vs := .Iutf8 (vecOf [applicationName]) },
    { attr := linkedName, vs := .Refer groups }] }

@[simp] theorem user_memberof :
    identity_impl.get_memberof user = ok (some groups) := by
  simp [identity_impl.get_memberof, user, userEntry, memberName,
    entry_impl.get_ava_refer, valueset.as_refer_set, groups,
    lift, Array.to_slice, Array.make]


@[simp] theorem user_uuid : identity_impl.get_uuid user = ok 2#u128 := by
  simp [identity_impl.get_uuid, user, userEntry]

@[simp] theorem target_class (x : Slice U8) :
    entry_impl.class_contains targetEntry x = ok (decide (applicationName.val = x.val)) := by
  simp [entry_impl.class_contains, entry_impl.get_ava_as_iutf8, valueset.as_iutf8_set,
    targetEntry, classVec, className, linkedName, lift, Array.to_slice, Array.make,
    alloc.vec.Vec.deref]

@[simp] theorem single_refer (u : U128) :
    valueset.to_refer_single (.Refer (vecOf [u])) = ok (some u) := by
  apply eq_ok_of_spec
  unfold valueset.to_refer_single
  dsimp only
  split
  · step*
    simp_all
  · exfalso
    rename_i hn
    apply hn
    apply UScalar.val_eq_imp
    simp [alloc.vec.Vec.len]

@[simp] theorem target_linked :
    entry_impl.get_ava_single_refer targetEntry linkedName.deref = ok (some 1#u128) := by
  unfold entry_impl.get_ava_single_refer
  simp [targetEntry, classVec, className, linkedName, alloc.vec.Vec.deref]
  simp [groups]

@[simp] theorem target_linked_of_val (s : Slice U8) (h : s.val = linkedName.val) :
    entry_impl.get_ava_single_refer targetEntry s = ok (some 1#u128) := by
  have hs : s = linkedName.deref := by
    apply Slice.ext
    simpa [alloc.vec.Vec.deref] using h
  rw [hs]
  exact target_linked

@[simp] theorem oauth_ignored :
    search_acc.search_oauth2_filter_entry user targetEntry = ok AccessSrchResult.Ignore := by
  unfold search_acc.search_oauth2_filter_entry
  have hu : userEntry.uuid ≠ UUID_ANONYMOUS := by simp [userEntry, UUID_ANONYMOUS]
  simp only [show user.origin = .User { entry := userEntry } from rfl, hu, ↓reduceIte,
    target_class, user_memberof]
  simp [targetEntry, entry_impl.get_ava_as_oauthscopemaps, valueset.as_oauthscopemap,
    search_acc.scope_member, applicationName, classVec, className, linkedName,
    lift, Array.to_slice, Array.make, alloc.vec.Vec.deref]

def applicationAttrs : alloc.vec.Vec (alloc.vec.Vec U8) :=
  vecOf [classVec, displayVec, uuidName, nameName, linkedName]

@[simp] theorem applications_allowed :
    search_acc.search_applications_filter_entry user targetEntry =
      ok (.Allow applicationAttrs) := by
  apply eq_ok_of_spec
  unfold search_acc.search_applications_filter_entry
  have hu : userEntry.uuid ≠ UUID_ANONYMOUS := by simp [userEntry, UUID_ANONYMOUS]
  simp only [show user.origin = .User { entry := userEntry } from rfl, hu, ↓reduceIte]
  simp only [lift, Array.to_slice, Array.make, bind_ok, target_class, user_memberof]
  simp only [applicationName, vecOf_val, Slice.from_val, Array.from_val, decide_true, ↓reduceIte]
  simp [linkedName, search_acc.linked_group_member, groups, alloc.vec.Vec.deref]
  change (do
    let a ← bset.insert (alloc.vec.Vec.new _) classVec.deref
    let b ← bset.insert a displayVec.deref
    let c ← bset.insert b uuidName.deref
    let d ← bset.insert c nameName.deref
    let e ← bset.insert d linkedName.deref
    ok (AccessSrchResult.Allow e)) ⦃ r => r = AccessSrchResult.Allow applicationAttrs ⦄
  have := usize_max_ge
  step* <;> simp_all [applicationAttrs, classVec, className, displayVec, displayName,
    uuidName, nameName, linkedName, alloc.vec.Vec.eq_iff] <;> try scalar_tac

theorem application_extend_fails :
    bset.extend profileAttrs applicationAttrs.deref = fail .maximumSizeExceeded := by
  unfold bset.extend bset.extend_loop
  rw [loop]
  dsimp only
  have h0 : bset.extend_loop.body applicationAttrs.deref profileAttrs 0#usize =
      ok (.cont (fullAfterClass, 1#usize)) := by
    apply eq_ok_of_spec
    unfold bset.extend_loop.body
    simp only [applicationAttrs, alloc.vec.Vec.deref, Slice.len, vecOf_val, Slice.from_val]
    split
    · step*
      simp_all only [Slice.from_val, List.getElem_cons_zero]
      change (do
        let s ← bset.insert profileAttrs classVec.deref
        let i ← 0#usize + 1#usize
        ok (ControlFlow.cont (s, i))) ⦃ r => r = .cont (fullAfterClass, 1#usize) ⦄
      rw [first_fixed_attribute]
      simp only [bind_ok]
      step
      have heq : i = 1#usize := UScalar.val_eq_imp i 1#usize i_post
      exact congrArg (fun j => ControlFlow.cont (fullAfterClass, j)) heq
    · exfalso; scalar_tac
  rw [h0]
  simp only [bind_ok]
  rw [loop]
  dsimp only
  have h1 : bset.extend_loop.body applicationAttrs.deref fullAfterClass 1#usize =
      fail .maximumSizeExceeded := by
    have hi : Slice.index_usize applicationAttrs.deref 1#usize = ok displayVec := by
      apply eq_ok_of_spec
      step
      · simp [applicationAttrs, alloc.vec.Vec.deref, Slice.length]
      · simpa [applicationAttrs, alloc.vec.Vec.deref] using x_post
    have hb : 1#usize < Slice.len applicationAttrs.deref := by
      simp only [applicationAttrs, alloc.vec.Vec.deref, vecOf_val, Slice.len, Slice.from_val]
      scalar_tac
    unfold bset.extend_loop.body
    rw [if_pos hb, hi]
    simp only [bind_ok, second_fixed_attribute_fails, bind_fail]
  rw [h1]
  simp

@[simp] theorem nested_clone (v : alloc.vec.Vec (alloc.vec.Vec U8)) :
    alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) v = ok v :=
  vec_clone_eq _ v u8vec_clone

def resolved : profiles.AccessControlSearchResolved :=
  { attrs := profileAttrs, receiver_condition := .GroupChecked,
    target_condition := .Scope (.Pres classVec) }
def related : alloc.vec.Vec profiles.AccessControlSearchResolved := vecOf [resolved]

@[simp] theorem resolve_conditions :
    access.resolve_access_conditions user (some groups) (.Group groups) (.Scope (.Pres classVec)) =
      ok (some (.GroupChecked, .Scope (.Pres classVec))) := by
  simp [access.resolve_access_conditions, groups, alloc.vec.Vec.deref,
    filter_impl.resolve, filter_impl.resolve_no_idx, u8vec_clone]

theorem search_related : access.search_related_acp control user none = ok related := by
  unfold access.search_related_acp
  rw [user_memberof]
  simp only [bind_ok]
  unfold access.search_related_acp_loop
  rw [loop]
  dsimp only
  have h0 : access.search_related_acp_loop.body user control.acps_search (some groups) none
      (alloc.vec.Vec.new _) 0#usize = ok (.cont (none, related, 1#usize)) := by
    apply eq_ok_of_spec
    unfold access.search_related_acp_loop.body
    have hb : 0#usize < alloc.vec.Vec.len control.acps_search := by
      simp [control, alloc.vec.Vec.len]
    rw [if_pos hb]
    step
    have hx : acs = {acp := {receiver := .Group groups, target := .Scope (.Pres classVec)}, attrs := profileAttrs} := by
        simpa only [control, groups, vecOf_val, List.getElem_cons_zero] using acs_post
    rw [hx]
    simp only [resolve_conditions, bind_ok, nested_clone]
    simp only [ite_true]
    step
    step
    have hi : i2 = 1#usize := UScalar.val_eq_imp _ _ i2_post
    have hv : attrs1 = related := by
      apply alloc.vec.Vec.ext
      simpa only [alloc.vec.Vec.new, alloc.vec.Vec.from_val, vecOf_val, List.nil_append, related, resolved] using related_acp1
    rw [hi, hv]
  rw [h0]
  simp only [bind_ok]
  rw [loop]
  dsimp only
  have h1 : access.search_related_acp_loop.body user control.acps_search (some groups) none
      related 1#usize = ok (.done related) := by
    unfold access.search_related_acp_loop.body
    have hb : ¬1#usize < alloc.vec.Vec.len control.acps_search := by
      simp [control, alloc.vec.Vec.len]
    rw [if_neg hb]
  rw [h1]
  simp only [bind_ok]

@[simp] theorem profile_applies (imo : Option (alloc.vec.Vec U128)) (iu : U128) :
    search_acc.acp_applies resolved.receiver_condition resolved.target_condition imo iu targetEntry = ok true := by
  unfold search_acc.acp_applies search_acc.receiver_applies
  simp only [resolved, bind_ok, ite_true]
  unfold search_acc.target_applies entry_impl.entry_match_no_index
  change entry_impl.entry_match_no_index_inner targetEntry (.Pres classVec) = ok true
  rw [entry_impl.entry_match_no_index_inner.eq_def]
  simp [entry_impl.attribute_pres, targetEntry, alloc.vec.Vec.deref]

theorem allowed_attrs : search_acc.search_allowed_attrs related.deref (some groups) 2#u128 targetEntry = ok profileAttrs := by
  unfold search_acc.search_allowed_attrs search_acc.search_allowed_attrs_loop
  rw [loop]
  dsimp only
  have h0 : search_acc.search_allowed_attrs_loop.body related.deref (some groups) 2#u128 targetEntry
      (alloc.vec.Vec.new _) 0#usize = ok (.cont (profileAttrs, 1#usize)) := by
    apply eq_ok_of_spec
    unfold search_acc.search_allowed_attrs_loop.body
    have hb : 0#usize < Slice.len related.deref := by
      simp [related, alloc.vec.Vec.deref, Slice.len]
    rw [if_pos hb]
    step
    have hx : acs = resolved := by
      simpa only [related, alloc.vec.Vec.deref, vecOf_val, Slice.from_val, List.getElem_cons_zero] using acs_post
    rw [hx, profile_applies]
    simp only [bind_ok, resolved]
    unfold search_acc.extend_if
    simp only [ite_true, profile_collection, bind_ok]
    step
    have hi : i2 = 1#usize := UScalar.val_eq_imp _ _ i2_post
    exact congrArg (fun j => ControlFlow.cont (profileAttrs, j)) hi
  rw [h0]
  simp only [bind_ok]
  rw [loop]
  dsimp only
  have h1 : search_acc.search_allowed_attrs_loop.body related.deref (some groups) 2#u128 targetEntry
      profileAttrs 1#usize = ok (.done profileAttrs) := by
    unfold search_acc.search_allowed_attrs_loop.body
    have hb : ¬1#usize < Slice.len related.deref := by
      simp [related, alloc.vec.Vec.deref, Slice.len]
    rw [if_neg hb]
  rw [h1]
  simp only [bind_ok]

@[simp] theorem filter_entry_allowed :
    search_acc.search_filter_entry user related.deref targetEntry = ok (.Allow profileAttrs) := by
  unfold search_acc.search_filter_entry
  simp only [show user.origin = .User {entry := userEntry} from rfl]
  have hs : identity_impl.access_scope user = ok .ReadOnly := rfl
  simp only [hs, bind_ok, user_memberof, user_uuid, allowed_attrs]

theorem apply_search_fails :
    search_acc.apply_search_access user related.deref targetEntry = fail .maximumSizeExceeded := by
  unfold search_acc.apply_search_access
  simp only [filter_entry_allowed, bind_ok, profile_collection, oauth_ignored,
    applications_allowed]
  simp only [Aeneas.Std.uncurry]
  rw [application_extend_fails]
  simp only [bind_fail]

def entries : alloc.vec.Vec Entry := vecOf [targetEntry]

theorem entry_report_fails
    (ms : Slice profiles.AccessControlModifyResolved)
    (ds : Slice profiles.AccessControlDeleteResolved) (ss : Slice SyncAgreement) :
    access.entry_effective_permission_check user targetEntry related.deref ms ds ss =
      fail .maximumSizeExceeded := by
  unfold access.entry_effective_permission_check
  simp only [apply_search_fails, bind_fail]

theorem report_body_fails
    (ms : alloc.vec.Vec profiles.AccessControlModifyResolved)
    (ds : alloc.vec.Vec profiles.AccessControlDeleteResolved) (ss : alloc.vec.Vec SyncAgreement)
    (ep : alloc.vec.Vec AccessEffectivePermission) :
    access.effective_permission_check_loop.body user entries.deref related ms ds ss ep 0#usize =
      fail .maximumSizeExceeded := by
  have hi : Slice.index_usize entries.deref 0#usize = ok targetEntry := by
    apply eq_ok_of_spec
    step
    · simp [entries, alloc.vec.Vec.deref, Slice.length]
    · simpa only [entries, alloc.vec.Vec.deref, vecOf_val, Slice.from_val, List.getElem_cons_zero] using x_post
  have hb : 0#usize < Slice.len entries.deref := by
    simp [entries, alloc.vec.Vec.deref, Slice.len]
  unfold access.effective_permission_check_loop.body
  rw [if_pos hb, hi]
  simp only [bind_ok, entry_report_fails, bind_fail]

theorem report_loop_fails
    (ms : alloc.vec.Vec profiles.AccessControlModifyResolved)
    (ds : alloc.vec.Vec profiles.AccessControlDeleteResolved) (ss : alloc.vec.Vec SyncAgreement)
    (ep : alloc.vec.Vec AccessEffectivePermission) :
    access.effective_permission_check_loop user entries.deref related ms ds ss ep 0#usize =
      fail .maximumSizeExceeded := by
  unfold access.effective_permission_check_loop
  rw [loop]
  dsimp only
  rw [report_body_fails]
  simp only [bind_fail]

theorem report_cannot_succeed :
    ¬ ∃ y, access.effective_permission_check control user none entries.deref = ok y := by
  rintro ⟨y, hy⟩
  unfold access.effective_permission_check at hy
  rw [search_related] at hy
  simp only [bind_ok] at hy
  h5i_invert hy
  rw [report_loop_fails] at heffective_permissions
  exact fail_ne_ok heffective_permissions

theorem requested_statement_is_false :
    ¬ (∀ (ctl : AccessControlsInner) (ident : Identity)
      (attrs : Option (alloc.vec.Vec (alloc.vec.Vec U8))) (es : Slice Entry),
      (ctl.acps_search.val.map (·.attrs.length)).sum +
        (ctl.acps_modify.val.map (fun m => m.presattrs.length + m.remattrs.length +
          m.pres_classes.length + m.rem_classes.length)).sum +
        (ctl.sync_agreements.val.map (·.attrs.length)).sum < Usize.max →
      ∃ y, access.effective_permission_check ctl ident attrs es = ok y) := by
  intro h
  exact report_cannot_succeed (h control user none entries.deref control_satisfies_hcap)

end CapacityCounterexample

