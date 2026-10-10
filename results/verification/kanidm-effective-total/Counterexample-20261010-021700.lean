import Spec
import H5iAppLib
/-!
The requested totality statement is false: its capacity hypothesis omits sync
agreement attributes. This file gives a checked counterexample without importing
Solution, so its proof does not depend on the unfinished theorem there.

Run: `cd proofs && lake env lean Counterexample.lean`.
-/
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP

namespace kanidm_kernel.Counterexample

set_option maxHeartbeats 1000000

@[step] theorem bytes_loop_spec (a b : Slice U8) (i : Usize)
    (hlen : a.val.length = b.val.length) :
    bset.bytes_eq_loop a b i ⦃ r => r = decide (a.val.drop i.val = b.val.drop i.val) ⦄ := by
  h5i_measure_induction (a.val.length - i.val) with ih
  unfold bset.bytes_eq_loop
  rw [loop]
  unfold bset.bytes_eq_loop.body
  h5i_steps
  · rename_i hi x0 call0 h0 hn
    have ha : i.val < a.val.length := by scalar_tac
    have hb : i.val < b.val.length := by omega
    have hn' : a.val[i.val] ≠ b.val[i.val] := by scalar_tac
    rw [List.drop_eq_getElem_cons ha, List.drop_eq_getElem_cons hb]
    simp only [List.cons.injEq, hn', false_and, decide_false]
  · rename_i hi x0 call0 h0 x1 call1 h1 hn
    have ha : i.val < a.val.length := by scalar_tac
    have hb : i.val < b.val.length := by omega
    have heq : a.val[i.val] = b.val[i.val] := by scalar_tac
    change bset.bytes_eq_loop a b x ⦃ r => r = decide (a.val.drop i.val = b.val.drop i.val) ⦄
    apply WP.spec_mono (ih _ (by omega) a b x hlen rfl)
    intro r hr
    rw [List.drop_eq_getElem_cons ha, List.drop_eq_getElem_cons hb]
    simpa only [List.cons.injEq, heq, true_and, x_post, and_self] using hr
  · have ha : a.val.length ≤ i.val := by scalar_tac
    simp [List.drop_eq_nil_of_le ha, List.drop_eq_nil_of_le (by omega : b.val.length ≤ i.val)]

@[step] theorem bytes_spec (a b : Slice U8) :
    bset.bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold bset.bytes_eq
  h5i_steps
  simp_all

@[step] theorem contains_spec (s : Slice (alloc.vec.Vec U8)) (x : Slice U8) :
    bset.contains s x ⦃ r => r = decide (∃ v ∈ s.val, v.val = x.val) ⦄ := by
  unfold bset.contains bset.contains_loop
  h5i_search_any s.val (fun v => decide (v.val = x.val))
  all_goals try simp_all [alloc.vec.Vec.deref, searchFrom_const]
  all_goals try scalar_tac

@[step] theorem insert_spec (s : alloc.vec.Vec (alloc.vec.Vec U8)) (x : Slice U8)
    (hcap : s.val.length < Usize.max) :
    bset.insert s x ⦃ r => s.val ⊆ r.val ∧ ∃ v ∈ r.val, v.val = x.val ⦄ := by
  unfold bset.insert
  h5i_steps
  all_goals simp_all [alloc.vec.Vec.deref, alloc.vec.Vec.val]

theorem insert_mem (s r : alloc.vec.Vec (alloc.vec.Vec U8)) (x : Slice U8)
    (h : bset.insert s x = ok r) :
    s.val ⊆ r.val ∧ ∃ v ∈ r.val, v.val = x.val := by
  unfold bset.insert at h
  h5i_invert h
  · have hm := post_of_ok (contains_spec r.deref x) hb
    simpa [hc, alloc.vec.Vec.deref] using And.intro (List.Subset.refl r.val) hm
  · unfold alloc.vec.Vec.push at h
    dsimp only at h
    split at h <;> h5i_invert h
    have hx := post_of_ok (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 x (by intros; rfl)) hv
    simp only [alloc.vec.Vec.from_val, List.concat_eq_append]
    exact ⟨List.subset_append_left _ _, v, by simp, by simp [alloc.vec.Vec.val, hx]⟩

theorem extend_mem (s r : alloc.vec.Vec (alloc.vec.Vec U8))
    (xs : Slice (alloc.vec.Vec U8)) (h : bset.extend s xs = ok r) :
    s.val ⊆ r.val ∧ xs.val ⊆ r.val := by
  unfold bset.extend bset.extend_loop at h
  have H : ∀ (t : alloc.vec.Vec (alloc.vec.Vec U8)) (i : Usize),
      (s.val ⊆ t.val ∧ xs.val.take i.val ⊆ t.val) → i.val ≤ xs.val.length →
      loop (fun (t, i) => bset.extend_loop.body xs t i) (t, i) = ok r →
      s.val ⊆ r.val ∧ xs.val ⊆ r.val := by
    intro t i hinv hbound hh
    apply loop_idx_ok (idx := Prod.snd) (n := xs.val.length)
      (Inv := fun p => s.val ⊆ p.1.val ∧ xs.val.take p.2.val ⊆ p.1.val)
      (Q := fun r => s.val ⊆ r.val ∧ xs.val ⊆ r.val) _ ?_ (t, i) r hinv hbound hh
    rintro ⟨t, i⟩ cf hi hb hs
    unfold bset.extend_loop.body at hs
    h5i_invert hs
    · dsimp only at hi hb ⊢
      have hlt : i.val < xs.val.length := by scalar_tac
      have hnext := add_ok_val hi2
      simp only [UScalar.ofNatCore_val_eq] at hnext
      have hm := insert_mem t set1 v.deref hset1
      obtain ⟨w, hw, heq⟩ := hm.2
      have hwv : w = v := alloc.vec.Vec.ext _ _ (by simpa [alloc.vec.Vec.deref] using heq)
      subst w
      obtain ⟨_, hvv⟩ := slice_index_ok hv
      refine ⟨⟨hi.1.trans hm.1, ?_⟩, by omega, by omega⟩
      rw [hnext, List.take_add_one, List.getElem?_eq_getElem hlt]
      simp only [Option.toList_some, List.append_subset]
      exact ⟨hi.2.trans hm.1, by simpa [hvv]⟩
    · dsimp only at hi hb ⊢
      have hle : xs.val.length ≤ i.val := by scalar_tac
      simpa [List.take_of_length_le hle] using hi
  exact H s 0#usize ⟨List.Subset.refl _, by simp⟩ (by simp) h

def zeroName (i : Fin Usize.max) : alloc.vec.Vec U8 :=
  vecOf (List.replicate i.val 0#u8) (by simp)

def fullNames : alloc.vec.Vec (alloc.vec.Vec U8) :=
  vecOf (List.ofFn zeroName) (by simp)

theorem fullNames_length : fullNames.val.length = Usize.max := by
  simp [fullNames]

theorem fullNames_nodup : fullNames.val.Nodup := by
  simp only [fullNames, vecOf_val, List.nodup_ofFn]
  intro i j h
  apply Fin.ext
  have hl := congrArg (fun v : alloc.vec.Vec U8 => v.val.length) h
  simpa [zeroName] using hl

theorem fullNames_zero (x : alloc.vec.Vec U8) (h : x ∈ fullNames.val) :
    ∀ b ∈ x.val, b = 0#u8 := by
  simp only [fullNames, vecOf_val, List.mem_ofFn] at h
  obtain ⟨i, rfl⟩ := h
  simp [zeroName]

theorem cannot_extend_full (s r : alloc.vec.Vec (alloc.vec.Vec U8))
    (x : alloc.vec.Vec U8) (hx : x ∈ s.val) (hn : x ∉ fullNames.val) :
    bset.extend s fullNames.deref ≠ ok r := by
  intro h
  have hm := extend_mem s r fullNames.deref h
  have hsub : x :: fullNames.val ⊆ r.val := by
    simp only [List.cons_subset]
    exact ⟨hm.1 hx, by simpa [alloc.vec.Vec.deref] using hm.2⟩
  have hnodup : (x :: fullNames.val).Nodup := List.nodup_cons.mpr ⟨hn, fullNames_nodup⟩
  have hlen := (List.subperm_of_subset hnodup hsub).length_le
  have hbound := r.property
  simp only [List.length_cons, fullNames_length] at hlen
  omega

@[step] theorem get_ava_spec (e : Entry) (a : Slice U8) :
    entry_impl.get_ava_set e a ⦃ r => r = (e.attrs.val.find? (fun v => decide (v.attr.val = a.val))).map (·.vs) ⦄ := by
  unfold entry_impl.get_ava_set entry_impl.get_ava_set_loop
  apply WP.spec_mono (loop_search e.attrs.val (fun v => decide (v.attr.val = a.val))
    id (fun _ v => some v.vs) none _ ?_ 0#usize (by simp))
  · intro r hr
    simpa [searchFrom_find] using hr
  · intro i hi
    unfold entry_impl.get_ava_set_loop.body
    h5i_step [alloc.vec.Vec.deref]

def className : alloc.vec.Vec U8 := vecOf [99#u8,108#u8,97#u8,115#u8,115#u8]
def syncClass : alloc.vec.Vec U8 :=
  vecOf [115#u8,121#u8,110#u8,99#u8,95#u8,111#u8,98#u8,106#u8,101#u8,99#u8,116#u8]
def syncParent : alloc.vec.Vec U8 :=
  vecOf [115#u8,121#u8,110#u8,99#u8,95#u8,112#u8,97#u8,114#u8,
    101#u8,110#u8,116#u8,95#u8,117#u8,117#u8,105#u8,100#u8]

def targetEntry : Entry := {
  uuid := 281474976710656#u128
  attrs := vecOf [
    {attr := className, vs := .Iutf8 (vecOf [syncClass])},
    {attr := syncParent, vs := .Refer (vecOf [1#u128])}]
}

def user : Identity := {
  origin := .User {entry := {uuid := 2#u128, attrs := alloc.vec.Vec.new Ava}}
  scope := .ReadWrite
}

def agreement : SyncAgreement := {uuid := 1#u128, attrs := fullNames}
def control : AccessControlsInner := {
  acps_search := alloc.vec.Vec.new _
  acps_modify := alloc.vec.Vec.new _
  acps_delete := alloc.vec.Vec.new _
  acps_create := alloc.vec.Vec.new _
  sync_agreements := vecOf [agreement]
}

theorem target_is_sync :
    modify_acc.class_set_contains targetEntry (.Iutf8 syncClass) = ok true := by
  apply eq_ok_of_spec
  unfold modify_acc.class_set_contains
  step*
  all_goals simp_all [targetEntry, className, Array.to_slice, Array.make]
  unfold valueset.vs_contains
  step*
  all_goals simp_all [alloc.vec.Vec.deref]

@[simp] theorem to_vec_u8 (s : Slice U8) :
    alloc.slice.Slice.to_vec core.clone.CloneU8 s = ok ⟨s⟩ := by
  apply eq_ok_of_spec
  apply WP.spec_mono (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 s (by intros; rfl))
  intro v hv
  cases v
  simp_all

@[step] theorem target_parent :
    entry_impl.get_ava_single_refer targetEntry syncParent.deref ⦃ r => r = some 1#u128 ⦄ := by
  unfold entry_impl.get_ava_single_refer
  step*
  all_goals simp_all [targetEntry, className, syncParent, alloc.vec.Vec.deref]
  unfold valueset.to_refer_single
  step* <;> simp_all

@[step] theorem sync_lookup (s : Slice SyncAgreement) (u : U128) :
    modify_acc.sync_agreement_get s u ⦃ r => r = (s.val.find? (fun a => decide (a.uuid = u))).map (·.attrs) ⦄ := by
  unfold modify_acc.sync_agreement_get modify_acc.sync_agreement_get_loop
  apply WP.spec_mono (loop_search s.val (fun a => decide (a.uuid = u))
    id (fun _ a => some a.attrs) none _ ?_ 0#usize (by simp))
  · intro r hr
    simpa [searchFrom_find] using hr
  · intro i hi
    unfold modify_acc.sync_agreement_get_loop.body
    h5i_step

theorem sync_fails (r : AccessModResult) :
    modify_acc.modify_sync_constrain user targetEntry control.sync_agreements.deref ≠ ok r := by
  intro h
  unfold modify_acc.modify_sync_constrain at h
  simp only [user, Array.to_slice, Array.make, lift, to_vec_u8] at h
  h5i_invert h
  · change entry_impl.get_ava_single_refer targetEntry syncParent.deref = ok none at ho
    have hp := post_of_ok target_parent ho
    contradiction
  · change entry_impl.get_ava_single_refer targetEntry syncParent.deref = ok (some sync_parent_uuid) at ho
    have hp := post_of_ok target_parent ho
    simp only [Option.some.injEq] at hp
    subst sync_parent_uuid
    have hm1 := (insert_mem _ _ _ hset1).1
    have hm2 := (insert_mem _ _ _ hset2).1
    have hm3 := (insert_mem _ _ _ hset3).1
    obtain ⟨x, hx, hbytes⟩ := (insert_mem _ _ _ hset).2
    have hx3 := hm3 (hm2 (hm1 hx))
    have hnx : x ∉ fullNames.val := by
      intro hm
      have hz := fullNames_zero x hm 117#u8 (by rw [hbytes]; simp)
      scalar_tac
    unfold modify_acc.extend_sync_yield_authority at hset4
    h5i_invert hset4
    · have hlu := post_of_ok (sync_lookup _ _) ho_1
      simp [control, agreement, alloc.vec.Vec.deref] at hlu
    · have hlu := post_of_ok (sync_lookup _ _) ho_1
      have heq : r_attrs = fullNames := by
        simpa [control, agreement, alloc.vec.Vec.deref] using hlu
      subst r_attrs
      exact cannot_extend_full set3 set4 x hx3 hnx hset4
  · change modify_acc.class_set_contains targetEntry (.Iutf8 syncClass) = ok is_sync at his_sync
    rw [target_is_sync, Result.ok.injEq] at his_sync
    simp_all

@[step] theorem protected_sync_class :
    protected.protected_mod_entry_classes syncClass.deref ⦃ r => r = false ⦄ := by
  unfold protected.protected_mod_entry_classes
  h5i_steps
  all_goals simp_all [syncClass, alloc.vec.Vec.deref, Array.to_slice, Array.make]

theorem protected_sync_classes :
    protected.disjoint_protected_mod_entry_classes (vecOf [syncClass]).deref = ok true := by
  apply eq_ok_of_spec
  unfold protected.disjoint_protected_mod_entry_classes protected.disjoint_protected_mod_entry_classes_loop
  h5i_total (fun i => i) 1
  rename_i i hi hc
  have hlt : i.val < 1 := by
    have hlt : i.val < (vecOf [syncClass]).deref.val.length := by scalar_tac
    simpa [alloc.vec.Vec.deref] using hlt
  have hz : i.val = 0 := by omega
  simp only [alloc.vec.Vec.deref, vecOf_val, Slice.from_val, hz, List.getElem_cons_zero]
  change (do let b ← protected.protected_mod_entry_classes syncClass.deref; _) ⦃ _ ⦄
  step*
  scalar_tac

@[step] theorem get_iutf8_spec (e : Entry) (a : Slice U8) :
    entry_impl.get_ava_as_iutf8 e a ⦃ r =>
      r = ((e.attrs.val.find? (fun v => decide (v.attr.val = a.val))).map (·.vs)).bind
        (fun vs => match vs with | .Iutf8 v => some v | _ => none) ⦄ := by
  unfold entry_impl.get_ava_as_iutf8
  step*
  · rw [← o_post]
    simp_all
  · rw [← o_post]
    unfold valueset.as_iutf8_set
    h5i_steps <;> simp_all

theorem protected_ignores :
    modify_acc.modify_protected_attrs user targetEntry = ok AccessModResult.Ignore := by
  apply eq_ok_of_spec
  unfold modify_acc.modify_protected_attrs
  simp only [user]
  step*
  all_goals simp_all [targetEntry, className, Array.to_slice, Array.make, UUID_ANONYMOUS]
  simp only [protected_sync_classes]
  h5i_simp

theorem modify_fails (acp : Slice profiles.AccessControlModifyResolved)
    (r : modify_acc.ModifyResult) :
    modify_acc.apply_modify_access user acp control.sync_agreements.deref targetEntry ≠ ok r := by
  intro h
  unfold modify_acc.apply_modify_access at h
  have hid : modify_acc.modify_ident_test user = ok AccessBasicResult.Ignore := by
    simp [modify_acc.modify_ident_test, user, identity_impl.access_scope]
  have hmig : modify_acc.modify_migration_attrs user targetEntry = ok AccessModResult.Ignore := by
    simp [modify_acc.modify_migration_attrs, user]
  rw [hid, hmig, protected_ignores] at h
  h5i_invert h
  obtain ⟨x, hx, _⟩ := bind_tc_eq_ok.mp h
  obtain ⟨amr, hamr, _⟩ := bind_tc_eq_ok.mp hx
  exact sync_fails amr hamr

theorem entry_fails (s : Slice profiles.AccessControlSearchResolved)
    (m : Slice profiles.AccessControlModifyResolved)
    (d : Slice profiles.AccessControlDeleteResolved) (r : AccessEffectivePermission) :
    access.entry_effective_permission_check user targetEntry s m d control.sync_agreements.deref ≠ ok r := by
  intro h
  unfold access.entry_effective_permission_check at h
  obtain ⟨sr, hsr, hrest⟩ := bind_tc_eq_ok.mp h
  h5i_invert hrest
  exact modify_fails m mr hmr

theorem report_loop_fails (s : alloc.vec.Vec profiles.AccessControlSearchResolved)
    (m : alloc.vec.Vec profiles.AccessControlModifyResolved)
    (d : alloc.vec.Vec profiles.AccessControlDeleteResolved)
    (eps r : alloc.vec.Vec AccessEffectivePermission) :
    access.effective_permission_check_loop user (vecOf [targetEntry]).deref s m d
      control.sync_agreements eps 0#usize ≠ ok r := by
  intro h
  unfold access.effective_permission_check_loop at h
  rw [loop] at h
  obtain ⟨cf, hcf, _⟩ := bind_tc_eq_ok.mp h
  unfold access.effective_permission_check_loop.body at hcf
  have hc : (0#usize : Usize) < Slice.len (vecOf [targetEntry]).deref := by
    simp only [alloc.vec.Vec.deref, Slice.len, Slice.from_val, vecOf_val]
    scalar_tac
  simp only [if_pos hc] at hcf
  h5i_invert hcf
  obtain ⟨_, heq⟩ := slice_index_ok he
  have he' : e = targetEntry := by
    simpa [alloc.vec.Vec.deref] using heq.symm
  subst e
  exact entry_fails _ _ _ aep haep

theorem report_fails (r : core.result.Result (alloc.vec.Vec AccessEffectivePermission) OperationError) :
    access.effective_permission_check control user none (vecOf [targetEntry]).deref ≠ ok r := by
  intro h
  unfold access.effective_permission_check at h
  h5i_invert h
  exact report_loop_fails _ _ _ _ _ heffective_permissions

/-- The input satisfies the stated hypothesis, but its report has no successful result. -/
theorem counterexample :
    (control.acps_search.val.map (·.attrs.length)).sum +
      (control.acps_modify.val.map (fun m => m.presattrs.length + m.remattrs.length +
        m.pres_classes.length + m.rem_classes.length)).sum < Usize.max ∧
    ¬ ∃ y, access.effective_permission_check control user none (vecOf [targetEntry]).deref = ok y := by
  constructor
  · simp only [control, alloc.vec.Vec.from_val, List.map_nil, List.sum_nil, Nat.zero_add]
    exact usize_lt_max (by decide)
  · rintro ⟨y, hy⟩
    exact report_fails y hy

theorem proposed_statement_is_false :
    ¬ (∀ (ctl : AccessControlsInner) (ident : Identity)
      (attrs : Option (alloc.vec.Vec (alloc.vec.Vec U8))) (es : Slice Entry),
      (ctl.acps_search.val.map (·.attrs.length)).sum +
        (ctl.acps_modify.val.map (fun m => m.presattrs.length + m.remattrs.length +
          m.pres_classes.length + m.rem_classes.length)).sum < Usize.max →
      ∃ y, access.effective_permission_check ctl ident attrs es = ok y) := by
  intro h
  exact counterexample.2 (h control user none (vecOf [targetEntry]).deref counterexample.1)

#print axioms proposed_statement_is_false

end kanidm_kernel.Counterexample
