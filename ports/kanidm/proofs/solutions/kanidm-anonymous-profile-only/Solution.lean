import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit

namespace kanidm_kernel.Solution

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    bset.bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold bset.bytes_eq
  step*
  have hlen : a.val.length = b.val.length := by scalar_tac
  unfold bset.bytes_eq_loop
  apply loop_idx_spec _ id a.val.length
      (fun i => ∀ k, k < i.val → a.val[k]? = b.val[k]?)
      (fun r => r = decide (a.val = b.val))
  · intro i hinv hi
    unfold bset.bytes_eq_loop.body
    step*
    · have hlt : i.val < a.val.length := by scalar_tac
      have hlt' : i.val < b.val.length := by omega
      have heq : i2 = i3 := by scalar_tac
      refine ⟨?_, by simp only [id_eq]; omega, by simp only [id_eq]; omega⟩
      intro k hk
      by_cases hki : k < i.val
      · exact hinv k hki
      · have hk' : k = i.val := by omega
        subst k
        simp only [List.getElem?_eq_getElem hlt, List.getElem?_eq_getElem hlt']
        rw [← i2_post, ← i3_post, heq]
    · have hi' : a.val.length ≤ i.val := by scalar_tac
      have heq : a.val = b.val := by
        apply List.ext_getElem?
        intro k
        by_cases hk : k < i.val
        · exact hinv k hk
        · have hka : a.val.length ≤ k := by omega
          have hkb : b.val.length ≤ k := by omega
          simp [List.getElem?_eq_none hka, List.getElem?_eq_none hkb]
      simp [heq]
  · simp
  · simp

@[step] theorem get_ava_set_spec (e : Entry) (a : Slice U8) :
    entry_impl.get_ava_set e a ⦃ r =>
      r = (e.attrs.val.find? (fun v => decide (v.attr.val = a.val))).map (·.vs) ⦄ := by
  unfold entry_impl.get_ava_set entry_impl.get_ava_set_loop
  apply WP.spec_mono (loop_search e.attrs.val
    (fun v => decide (v.attr.val = a.val)) id (fun _ v => some v.vs) none _ ?_ 0#usize (by simp))
  · intro r hr
    simpa [searchFrom_find] using hr
  · intro i hi
    unfold entry_impl.get_ava_set_loop.body
    h5i_step
    all_goals (refine ⟨by scalar_tac, ?_⟩; simpa [alloc.vec.Vec.deref] using b_post)

@[step] theorem contains_spec (s : Slice (alloc.vec.Vec U8)) (x : Slice U8) :
    bset.contains s x ⦃ r => r = s.val.any (fun v => decide (v.val = x.val)) ⦄ := by
  unfold bset.contains bset.contains_loop
  h5i_search_any s.val (fun v => decide (v.val = x.val))
  all_goals (refine ⟨by scalar_tac, ?_⟩; simpa [alloc.vec.Vec.deref] using b_post)

theorem nats_eq_iff (a b : List U8) : nats a = nats b ↔ a = b := by
  constructor
  · intro h
    apply List.map_injective_iff.mpr (fun x y hxy => UScalar.eq_of_val_eq hxy)
    exact h
  · rintro rfl; rfl

@[step] theorem class_contains_spec (e : Entry) (c : Slice U8) :
    entry_impl.class_contains e c ⦃ r => r = decide (nats c.val ∈ classes e) ⦄ := by
  unfold entry_impl.class_contains entry_impl.get_ava_as_iutf8
  step*
  have hsval : nats s.val = lit "class" := by
    subst s
    simp [Array.make, nats, lit, String.toUTF8, ← String.utf8Encode_toList]
    cbv
  have hx : x = ava e (lit "class") := by
    rw [x_post]
    unfold ava
    congr 2
    funext v
    apply Bool.eq_iff_iff.mpr
    simp [← hsval, nats_eq_iff]
  unfold valueset.as_iutf8_set
  h5i_steps
  all_goals simp only [classes, ← hx]
  all_goals try simp
  rw [r_post]
  apply Bool.eq_iff_iff.mpr
  simp only [List.any_eq_true, decide_eq_true_eq, names, List.mem_map,
    alloc.vec.Vec.deref, nats_eq_iff]
  simp

@[step] theorem not_sync_user_spec (e : Entry) (hs : ¬ HasClass e "sync_object") :
    search_acc.is_sync_account_user e ⦃ r => r = false ⦄ := by
  unfold search_acc.is_sync_account_user
  step*
  have hn : nats s.val = lit "sync_object" := by
    subst s
    simp [Array.make, nats, lit, String.toUTF8, ← String.utf8Encode_toList]
    cbv
  simp only [hn] at b_post
  simp [HasClass] at hs
  simp_all

theorem insert_mem (set out : alloc.vec.Vec (alloc.vec.Vec U8)) (v : alloc.vec.Vec U8)
    (h : bset.insert set v.deref = ok out) :
    ∀ x ∈ out.val, x ∈ set.val ∨ x = v := by
  unfold bset.insert at h
  h5i_invert h
  · intro x hx; exact Or.inl hx
  · have hv := post_of_ok (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 v.deref
      (by intro a; simp)) hv_1
    have hvval : v_1.val = v.val := by
      have := congrArg Slice.val hv
      simpa [alloc.vec.Vec.deref, alloc.vec.Vec.val] using this.symm
    have hv' : v_1 = v := (alloc.vec.Vec.eq_iff _ _).mpr hvval
    subst v_1
    unfold alloc.vec.Vec.push at h
    h5i_invert h
    simp [List.concat_eq_append]

theorem extend_mem (set out : alloc.vec.Vec (alloc.vec.Vec U8))
    (xs : Slice (alloc.vec.Vec U8)) (h : bset.extend set xs = ok out) :
    ∀ x ∈ out.val, x ∈ set.val ∨ x ∈ xs.val := by
  unfold bset.extend bset.extend_loop at h
  apply loop_idx_ok _ Prod.snd xs.val.length
    (fun si => ∀ x ∈ si.1.val, x ∈ set.val ∨ x ∈ xs.val)
    (fun out => ∀ x ∈ out.val, x ∈ set.val ∨ x ∈ xs.val) _
    (set, 0#usize) out (by intro x hx; exact Or.inl hx) (by simp) h
  rintro ⟨acc, i⟩ r hinv hi hr
  unfold bset.extend_loop.body at hr
  h5i_invert hr
  · have hv := slice_index_ok_mem hv
    have hm := insert_mem acc set1 v hset1
    refine ⟨?_, ?_, ?_⟩
    · intro x hx
      rcases hm x hx with hx | rfl
      · exact hinv x hx
      · exact Or.inr hv
    · have := add_ok_val hi2; simp only at *; scalar_tac
    · have := add_ok_val hi2; simp only at *; scalar_tac
  · exact hinv

theorem extend_if_mem (set out : alloc.vec.Vec (alloc.vec.Vec U8))
    (xs : Slice (alloc.vec.Vec U8)) (b : Bool)
    (h : search_acc.extend_if set b xs = ok out) :
    ∀ x ∈ out.val, x ∈ set.val ∨ x ∈ xs.val := by
  unfold search_acc.extend_if at h
  split at h
  · exact extend_mem set out xs h
  · h5i_invert h
    intro x hx; exact Or.inl hx

theorem allowed_attrs_mem (related : Slice profiles.AccessControlSearchResolved)
    (mo : Option (alloc.vec.Vec U128)) (uuid : U128) (e : Entry)
    (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : search_acc.search_allowed_attrs related mo uuid e = ok out) :
    ∀ x ∈ out.val, ∃ acs ∈ related.val, x ∈ acs.attrs.val := by
  unfold search_acc.search_allowed_attrs search_acc.search_allowed_attrs_loop at h
  apply loop_idx_ok _ Prod.snd related.val.length
    (fun si => ∀ x ∈ si.1.val, ∃ acs ∈ related.val, x ∈ acs.attrs.val)
    (fun out => ∀ x ∈ out.val, ∃ acs ∈ related.val, x ∈ acs.attrs.val) _
    (alloc.vec.Vec.new _, 0#usize) out (by simp) (by simp) h
  rintro ⟨acc, i⟩ r hinv hi hr
  unfold search_acc.search_allowed_attrs_loop.body at hr
  h5i_invert hr
  · have hacs := slice_index_ok_mem hacs
    have hm := extend_if_mem acc allowed_attrs1 acs.attrs.deref ok1 hallowed_attrs1
    refine ⟨?_, ?_, ?_⟩
    · intro x hx
      rcases hm x hx with hx | hx
      · exact hinv x hx
      · exact ⟨acs, hacs, by simpa [alloc.vec.Vec.deref] using hx⟩
    · have := add_ok_val hi2; simp only at *; scalar_tac
    · have := add_ok_val hi2; simp only at *; scalar_tac
  · exact hinv

theorem profile_result (ident : Identity) (u : IdentUser)
    (related : Slice profiles.AccessControlSearchResolved) (e : Entry)
    (r : AccessSrchResult) (hu : ident.origin = .User u)
    (h : search_acc.search_filter_entry ident related e = ok r) :
    match r with
    | .Deny => True
    | .Allow attrs => ∀ x ∈ attrs.val, ∃ acs ∈ related.val, x ∈ acs.attrs.val
    | _ => False := by
  unfold search_acc.search_filter_entry identity_impl.access_scope at h
  rw [hu] at h
  h5i_invert h
  all_goals first
    | exact allowed_attrs_mem related ident_memberof ident_uuid e allowed_attrs hallowed_attrs
    | trivial

theorem sync_ignore (ident : Identity) (u : IdentUser) (e : Entry)
    (hu : ident.origin = .User u) (hs : ¬ HasClass u.entry "sync_object") :
    search_acc.search_sync_account_filter_entry ident e = ok .Ignore := by
  apply eq_ok_of_spec
  unfold search_acc.search_sync_account_filter_entry
  rw [hu]
  step*

theorem anonymous_reads_by_profile_only (ident : Identity) (u : IdentUser)
    (related : Slice profiles.AccessControlSearchResolved) (e : Entry)
    (attrs : alloc.vec.Vec (alloc.vec.Vec U8)) (x : alloc.vec.Vec U8)
    (hu : ident.origin = .User u) (ha : u.entry.uuid = UUID_ANONYMOUS)
    (hs : ¬ HasClass u.entry "sync_object")
    (h : search_acc.apply_search_access ident related e = ok (.Allow attrs)) (hx : x ∈ attrs.val) :
    ∃ acs ∈ related.val, x ∈ acs.attrs.val := by
  have ho : search_acc.search_oauth2_filter_entry ident e = ok .Ignore := by
    simp [search_acc.search_oauth2_filter_entry, hu, ha]
  have hap : search_acc.search_applications_filter_entry ident e = ok .Ignore := by
    simp [search_acc.search_applications_filter_entry, hu, ha]
  have hsync := sync_ignore ident u e hu hs
  have hl : ((alloc.vec.Vec.new (alloc.vec.Vec U8)).len != 0#usize) = false := by
    simp [alloc.vec.Vec.len, alloc.vec.Vec.new]
    scalar_tac
  unfold search_acc.apply_search_access at h
  simp only [ho, hap, hsync, hl, Bool.false_eq_true, if_false] at h
  h5i_invert h
  have hp := profile_result ident u related e asr hu hasr
  cases asr with
  | Deny =>
    h5i_invert hx_1
    simp at h
  | Grant => exact False.elim hp
  | Ignore => exact False.elim hp
  | Allow attr =>
    h5i_invert hx_1
    simp at h
    subst allow1
    have hm := extend_mem (alloc.vec.Vec.new _) attrs attr.deref hallow1
    have hm' := hm x hx
    simp only [alloc.vec.Vec.new, alloc.vec.Vec.from_val, List.not_mem_nil, false_or] at hm'
    exact hp x (by simpa [alloc.vec.Vec.deref] using hm')

end kanidm_kernel.Solution
