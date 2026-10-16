import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit

namespace kanidm_kernel.Solution

set_option maxRecDepth 4096
set_option maxHeartbeats 2000000

lemma bytes_list (b : ByteArray) : b.toList = b.data.toList := by
  have hh : ∀ i acc, ByteArray.toList.loop b i acc = acc.reverse ++ b.data.toList.drop i := by
    intro i acc
    fun_induction ByteArray.toList.loop b i acc with
    | case1 i acc h ih =>
      rw [ih]
      have hi : i < b.data.toList.length := by simpa only [Array.length_toList, ByteArray.size] using h
      rw [List.drop_eq_getElem_cons hi]
      simp only [List.reverse_cons, ByteArray.get!, Array.getElem_toList, List.append_assoc, List.cons_append, List.nil_append, List.append_cancel_left_eq, List.cons.injEq, and_true]
      rw [Array.getElem!_eq_getD]; simp [Array.getD, h]
    | case2 i acc h =>
      have hi : b.data.toList.length ≤ i := by simpa only [Array.length_toList, ByteArray.size] using Nat.le_of_not_lt h
      simp [List.drop_eq_nil_of_le hi]
  simpa [ByteArray.toList] using hh 0 []
open kanidm_kernel.Spec

lemma lit_eq (s : String) : lit s = (s.toList.flatMap String.utf8EncodeChar).map (·.toNat) := by
  simp [lit, bytes_list, String.toUTF8, ← String.utf8Encode_toList, List.utf8Encode]

lemma nats_inj (a b : List U8) : nats a = nats b ↔ a = b := by
  unfold nats
  exact List.map_inj_right (fun x y h => UScalar.eq_of_val_eq h)

@[step] lemma bytes_eq_spec (a b : Slice U8) :
    bset.bytes_eq a b ⦃ r => r = decide (nats a.val = nats b.val) ⦄ := by
  unfold bset.bytes_eq
  dsimp only
  split
  · rename_i h
    simp only [WP.spec_ok]
    have hn : nats a.val ≠ nats b.val := by
      intro he
      have he := (nats_inj _ _).mp he
      have : a.len = b.len := by simp [Slice.len, he]
      scalar_tac
    simp [hn]
  · rename_i h
    have hl : a.val.length = b.val.length := by scalar_tac
    unfold bset.bytes_eq_loop
    apply WP.spec_mono (loop_search (a.val.zip b.val) (fun p => decide (p.1 ≠ p.2))
      id (fun _ _ => false) true _ ?_ 0#usize (by simp))
    · intro r hr
      have hh := search_all _ _ _ hr
      simp only [id_eq, decide_not, Bool.not_not] at hh
      rw [hh, zip_all_eq _ _ hl]
      simp [nats_inj]
    · intro i hi
      unfold bset.bytes_eq_loop.body
      h5i_step [List.length_zip, hl, List.getElem_zip]
      all_goals scalar_tac

@[step] lemma contains_spec (s : Slice (alloc.vec.Vec U8)) (a : Slice U8) :
    bset.contains s a ⦃ r => r = decide (nats a.val ∈ names s.val) ⦄ := by
  unfold bset.contains bset.contains_loop
  apply WP.spec_mono (loop_search s.val (fun v => decide (nats v.val = nats a.val))
    id (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr
    have hh := search_any _ _ _ hr
    simp only [id_eq] at hh
    rw [hh]
    apply Bool.eq_iff_iff.mpr
    simp only [decide_eq_true_eq, List.any_eq_true, names, List.mem_map]
  · intro i hi
    unfold bset.contains_loop.body
    h5i_step [vec_deref_val]
    all_goals refine ⟨by scalar_tac, ?_⟩ <;> trivial

lemma insert_inv (s r : alloc.vec.Vec (alloc.vec.Vec U8)) (a : Slice U8)
    (h : bset.insert s a = ok r) :
    ∀ x, x ∈ names r.val ↔ x ∈ names s.val ∨ x = nats a.val := by
  unfold bset.insert at h
  h5i_invert h
  all_goals first
    | (have hb := post_of_ok (contains_spec _ _) ‹bset.contains _ _ = ok _›
       simp_all [vec_deref_val])
    | skip
  · have hv' := post_of_ok (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 a (by
      intro x hx; simp)) ‹alloc.slice.Slice.to_vec _ _ = ok _›
    have hr := ‹alloc.vec.Vec.push _ _ = ok _›
    unfold alloc.vec.Vec.push at hr
    h5i_invert hr
    simp_all [names]
    intro x; rfl

@[step] lemma ava_spec (e : Entry) (a : Slice U8) :
    entry_impl.get_ava_set e a ⦃ r => r = ava e (nats a.val) ⦄ := by
  unfold entry_impl.get_ava_set entry_impl.get_ava_set_loop
  apply WP.spec_mono (loop_search e.attrs.val (fun v => decide (nats v.attr.val = nats a.val))
    id (fun _ v => some v.vs) none _ ?_ 0#usize (by simp))
  · intro r hr
    simpa [ava, searchFrom_find, List.drop_zero, beq_eq_decide] using hr
  · intro i hi
    unfold entry_impl.get_ava_set_loop.body
    h5i_step [vec_deref_val]

lemma extend_inv (s r : alloc.vec.Vec (alloc.vec.Vec U8)) (xs : Slice (alloc.vec.Vec U8))
    (h : bset.extend s xs = ok r) :
    ∀ x, x ∈ names r.val ↔ x ∈ names s.val ∨ x ∈ names xs.val := by
  unfold bset.extend bset.extend_loop at h
  refine loop_idx_ok _ Prod.snd xs.val.length
    (fun st => ∀ x, x ∈ names st.1.val ↔ x ∈ names s.val ∨ x ∈ names (xs.val.take st.2.val))
    (fun r => ∀ x, x ∈ names r.val ↔ x ∈ names s.val ∨ x ∈ names xs.val) ?_ _ _ ?_ (by simp) h
  · rintro ⟨t, i⟩ res hi hle hr
    dsimp only at hi hle
    unfold bset.extend_loop.body at hr
    h5i_invert hr
    · have hv := slice_index_ok ‹xs.index_usize i = ok _›
      have ht := insert_inv _ _ _ ‹bset.insert _ _ = ok _›
      have hj := add_ok_val ‹i + 1#usize = ok _›
      norm_num only [UScalar.ofNatCore_val_eq] at hj
      obtain ⟨_, hv⟩ := hv
      have hlt : i.val < xs.val.length := by scalar_tac
      refine ⟨?_, by dsimp; omega, by dsimp; omega⟩
      intro x
      dsimp at hi ⊢
      rw [ht, hi]
      rw [hj]
      rw [List.take_add_one, List.getElem?_eq_getElem hlt]
      simp [names, vec_deref_val, hv, or_assoc]
    · have he : xs.val.length ≤ i.val := by scalar_tac
      simpa [List.take_of_length_le he] using hi
  · simp [names]

lemma intersection_inv (a b : Slice (alloc.vec.Vec U8)) (r : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : bset.intersection a b = ok r) : names r.val ⊆ names a.val := by
  unfold bset.intersection bset.intersection_loop at h
  refine loop_idx_ok _ Prod.snd a.val.length
    (fun st => names st.1.val ⊆ names a.val) (fun r => names r.val ⊆ names a.val)
    ?_ _ _ (by simp [names]) (by simp) h
  rintro ⟨t, i⟩ res hi hle hr
  dsimp only at hi hle
  unfold bset.intersection_loop.body at hr
  h5i_invert hr
  all_goals try (split at hout1 <;> h5i_invert hout1)
  all_goals try exact hi
  all_goals have hj := add_ok_val ‹i + 1#usize = ok _›
  all_goals norm_num only [UScalar.ofNatCore_val_eq] at hj
  all_goals have hlt : i.val < a.val.length := by scalar_tac
  all_goals refine ⟨?_, by dsimp; omega, by dsimp; omega⟩
  · have ht := insert_inv _ _ _ ‹bset.insert _ _ = ok _›
    have hv := slice_index_ok_mem ‹a.index_usize i = ok _›
    have hc := post_of_ok (CloneLaw.vec_clone_spec core.clone.CloneU8 _) ‹alloc.vec.CloneVec.clone _ _ = ok _›
    intro x hx
    rcases (ht x).mp hx with hx | hx
    · exact hi hx
    · subst hx; simp only [hc, vec_deref_val]; exact List.mem_map.mpr ⟨_, hv, rfl⟩
  · exact hi

@[step] lemma subset_spec (a b : Slice (alloc.vec.Vec U8)) :
    bset.is_subset a b ⦃ r => r = decide (names a.val ⊆ names b.val) ⦄ := by
  unfold bset.is_subset bset.is_subset_loop
  apply WP.spec_mono (loop_search a.val (fun v => !decide (nats v.val ∈ names b.val))
    id (fun _ _ => false) true _ ?_ 0#usize (by simp))
  · intro r hr
    have hh := search_all _ _ _ hr
    simp only [id_eq, Bool.not_not] at hh
    rw [hh]
    apply Bool.eq_iff_iff.mpr
    simp [names, List.subset_def]
  · intro i hi
    unfold bset.is_subset_loop.body
    h5i_step [vec_deref_val]

lemma class_ava (e : Entry) (hs : HasClass e "sync_object") :
    ∃ cs, ava e (lit "class") = some (.Iutf8 cs) ∧ lit "sync_object" ∈ names cs.val := by
  unfold HasClass classes at hs
  cases he : ava e (lit "class") with
  | none => simp [he] at hs
  | some vs => cases vs <;> simp_all

@[step] lemma protected_class_spec (a : Slice U8) :
    protected.protected_mod_entry_classes a ⦃ r => r = decide (nats a.val ∈ protectedModEntryClasses) ⦄ := by
  unfold protected.protected_mod_entry_classes
  step* <;> simp_all [protectedModEntryClasses, lit_eq, String.utf8EncodeChar, nats]

@[step] lemma protected_disjoint_spec (cs : Slice (alloc.vec.Vec U8)) :
    protected.disjoint_protected_mod_entry_classes cs ⦃ r =>
      r = decide (∀ c ∈ names cs.val, c ∉ protectedModEntryClasses) ⦄ := by
  unfold protected.disjoint_protected_mod_entry_classes protected.disjoint_protected_mod_entry_classes_loop
  apply WP.spec_mono (loop_search cs.val (fun v => decide (nats v.val ∈ protectedModEntryClasses))
    id (fun _ _ => false) true _ ?_ 0#usize (by simp))
  · intro r hr
    have hh := search_all _ _ _ hr
    simp only [id_eq] at hh
    rw [hh]
    apply Bool.eq_iff_iff.mpr
    simp [names]
  · intro i hi
    unfold protected.disjoint_protected_mod_entry_classes_loop.body
    h5i_step [vec_deref_val]

lemma protected_ignore (i : Identity) (e : Entry) (hu : IsUser i)
    (hb : UUID_ANONYMOUS < e.uuid) (hp : ∀ c ∈ classes e, c ∉ protectedModEntryClasses) :
    modify_acc.modify_protected_attrs i e = ok .Ignore := by
  obtain ⟨u, hu⟩ := hu
  apply eq_ok_of_spec
  unfold modify_acc.modify_protected_attrs entry_impl.get_ava_as_iutf8
  simp only [hu]
  step*
  have he : nats [99#u8, 108#u8, 97#u8, 115#u8, 115#u8] = lit "class" := by simp [nats, lit_eq, String.utf8EncodeChar]
  subst_vars
  simp only [array_to_slice_val, Array.make_val, he]
  cases hv : ava e (lit "class") with
  | none => simp [hv]
  | some vs =>
    cases vs <;> simp only [hv, valueset.as_iutf8_set, bind_tc_ok, bind_ok, WP.spec_ok]
    all_goals try rfl
    rename_i cs
    have hc : ∀ c ∈ names cs.val, c ∉ protectedModEntryClasses := by
      simpa [classes, hv] using hp
    simp only [hb, if_true]
    step*
    simp_all [vec_deref_val]

@[step] lemma sync_agreement_spec (sa : Slice SyncAgreement) (p : U128) :
    modify_acc.sync_agreement_get sa p ⦃ r => r = (sa.val.find? (fun a => a.uuid == p)).map (·.attrs) ⦄ := by
  unfold modify_acc.sync_agreement_get modify_acc.sync_agreement_get_loop
  apply WP.spec_mono (loop_search sa.val (fun a => decide (a.uuid = p))
    id (fun _ a => some a.attrs) none _ ?_ 0#usize (by simp))
  · intro r hr
    simpa [searchFrom_find, List.drop_zero, beq_eq_decide] using hr
  · intro i hi
    unfold modify_acc.sync_agreement_get_loop.body
    h5i_step

lemma yield_inv (s r : alloc.vec.Vec (alloc.vec.Vec U8)) (sa : Slice SyncAgreement) (p : U128)
    (h : modify_acc.extend_sync_yield_authority s sa p = ok r) :
    ∀ a, a ∈ names r.val ↔ a ∈ names s.val ∨ a ∈ agreementAttrs sa.val p := by
  unfold modify_acc.extend_sync_yield_authority at h
  h5i_invert h
  all_goals have hs := post_of_ok (sync_agreement_spec _ _) ‹modify_acc.sync_agreement_get _ _ = ok _›
  · cases hf : sa.val.find? (fun a => a.uuid == p) with
    | none => simp [agreementAttrs, hf]
    | some sa => simp [hf] at hs
  · have he := extend_inv _ _ _ ‹bset.extend _ _ = ok _›
    cases hf : sa.val.find? (fun a => a.uuid == p) with
    | none => simp [hf] at hs
    | some sa =>
      simp only [hf, Option.map_some, Option.some.injEq] at hs
      simpa only [agreementAttrs, hf, hs, vec_deref_val] using he

lemma single_refer_inv (e : Entry) (a : Slice U8) (p : U128)
    (hn : nats a.val = lit "sync_parent_uuid")
    (h : entry_impl.get_ava_single_refer e a = ok (some p)) :
    refers e "sync_parent_uuid" = some [p] := by
  unfold entry_impl.get_ava_single_refer at h
  h5i_invert h
  have ha := post_of_ok (ava_spec _ _) ‹entry_impl.get_ava_set _ _ = ok _›
  cases vs <;> unfold valueset.to_refer_single at h <;> h5i_invert h
  rename_i rs
  have hl : rs.val.length = 1 := by scalar_tac
  obtain ⟨q, hq⟩ := List.length_eq_one_iff.mp hl
  have hi := vec_index_slice_ok_get? ‹alloc.vec.Vec.index _ _ _ = ok _›
  simp only [hq] at hi
  simp at hi
  subst_vars
  simp only [hn] at ha
  simp [refers, ← ha, hq]
  exact Option.some.inj h

@[step] lemma class_iutf8_spec (e : Entry) (v : alloc.vec.Vec U8) :
    modify_acc.class_set_contains e (.Iutf8 v) ⦃ r => r = decide (nats v.val ∈ classes e) ⦄ := by
  unfold modify_acc.class_set_contains
  step
  step
  subst_vars
  have hn : nats [99#u8, 108#u8, 97#u8, 115#u8, 115#u8] = lit "class" := by
    simp [nats, lit_eq, String.utf8EncodeChar]
  try simp only [array_to_slice_val, Array.make_val, hn]
  cases ha : ava e (lit "class") with
  | none => simp [classes, ha]
  | some vs =>
    cases vs <;> simp only [valueset.vs_contains]
    all_goals try simp [classes, ha]
    step*
    simp_all [classes, ha, vec_deref_val]

def SyncConstrained (sa : List SyncAgreement) (e : Entry) (r : AccessModResult) : Prop :=
  r = .Deny ∨ ∃ p s, r = .Constrain s s none none ∧
    refers e "sync_parent_uuid" = some [p] ∧
    lit "user_auth_token_session" ∈ names s.val ∧
    ∀ a, a ∈ names s.val → a ∈ syncAttrs ∨ a ∈ agreementAttrs sa p

lemma sync_constrain_inv (i : Identity) (e : Entry) (sa : Slice SyncAgreement) (r : AccessModResult)
    (hu : IsUser i) (hs : HasClass e "sync_object")
    (h : modify_acc.modify_sync_constrain i e sa = ok r) : SyncConstrained sa.val e r := by
  obtain ⟨u, hu⟩ := hu
  unfold modify_acc.modify_sync_constrain at h
  simp only [hu] at h
  h5i_invert h
  all_goals have ht := post_of_ok (class_iutf8_spec _ _) ‹modify_acc.class_set_contains _ _ = ok _›
  all_goals have hv' := post_of_ok (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 _ (by intro x hx; simp)) ‹alloc.slice.Slice.to_vec _ _ = ok _›
  all_goals
    have hvn : nats v.val = lit "sync_object" := by
      rw [alloc.vec.Vec.val, ← hv']
      have hsval := Result.ok.inj (by simpa only [lift] using hs_1)
      rw [← hsval]
      simp [nats, lit_eq, String.utf8EncodeChar]
  all_goals simp only [hvn, show lit "sync_object" ∈ classes e from hs, decide_true] at ht
  all_goals try exact Or.inl rfl
  all_goals try (exact False.elim (hc ht))
  simp only [lift, Result.ok.injEq] at *
  have hc := post_of_ok (CloneLaw.vec_clone_spec (core.clone.CloneallocvecVec core.clone.CloneU8) _)
    ‹alloc.vec.CloneVec.clone _ _ = ok _›
  have hp := single_refer_inv e s1 sync_parent_uuid (by rw [← hs1]; simp [nats, lit_eq, String.utf8EncodeChar]) ho
  have h1 := insert_inv _ _ _ hset
  have h2 := insert_inv _ _ _ hset1
  have h3 := insert_inv _ _ _ hset2
  have h4 := insert_inv _ _ _ hset3
  have hy := yield_inv _ _ _ _ hset4
  subst_vars
  refine Or.inr ⟨_, _, rfl, hp, ?_, ?_⟩
  · rw [hy, h4, h3, h2, h1]
    simp [names, nats, lit_eq, String.utf8EncodeChar]
  · intro a ha
    rw [hy, h4, h3, h2, h1] at ha
    simpa [names, nats, syncAttrs, lit_eq, String.utf8EncodeChar, or_assoc] using ha

def SyncAllowed (sa : List SyncAgreement) (e : Entry) (r : modify_acc.ModifyResult) : Prop :=
  r = .Deny ∨ ∃ pres rem pc rc p, r = .Allow pres rem pc rc ∧
    refers e "sync_parent_uuid" = some [p] ∧
    ∀ a, a ∈ names pres.val → a ∈ syncAttrs ∨ a ∈ agreementAttrs sa p

lemma apply_sync_inv (i : Identity) (e : Entry) (sa : Slice SyncAgreement)
    (acp : Slice profiles.AccessControlModifyResolved) (r : modify_acc.ModifyResult)
    (hu : IsUser i) (hs : HasClass e "sync_object")
    (hb : UUID_ANONYMOUS < e.uuid) (hp : ∀ c ∈ classes e, c ∉ protectedModEntryClasses)
    (h : modify_acc.apply_modify_access i acp sa e = ok r) : SyncAllowed sa.val e r := by
  have hprot := protected_ignore i e hu hb hp
  obtain ⟨u, hu⟩ := hu
  unfold modify_acc.apply_modify_access at h
  simp only [modify_acc.modify_migration_attrs, hu, hprot, bind_tc_ok, bind_ok, uncurry] at h
  unfold modify_acc.modify_ident_test identity_impl.access_scope at h
  simp only [hu] at h
  cases hc : i.scope <;> simp only [hc, bind_tc_ok, bind_ok, uncurry] at h
  all_goals h5i_invert h
  all_goals try simp only [uncurry, reduceIte] at h
  all_goals try (have hr := Result.ok.inj h; subst r; exact Or.inl rfl)
  all_goals h5i_invert hx
  all_goals try simp only [uncurry, reduceIte] at h
  all_goals have hsync := sync_constrain_inv i e sa amr2 ⟨u, hu⟩ hs hamr2
  all_goals rcases hsync with heq | ⟨p, s, heq, hparent, hsession, hbound⟩
  all_goals subst amr2
  all_goals h5i_invert hx_1
  all_goals simp only [uncurry, reduceIte] at hx
  all_goals h5i_invert hx
  all_goals cases amr3
  all_goals h5i_invert hx_1
  all_goals simp only [uncurry] at hx
  all_goals h5i_invert hx
  all_goals simp only [reduceIte, Prod.fst, Prod.snd] at h
  all_goals try (have hr := Result.ok.inj h; subst r; exact Or.inl rfl)
  all_goals have hext := extend_inv _ _ _ hconstrain_pres3
  all_goals
    have hn : constrain_pres3.len ≠ 0#usize := by
      intro hz
      have hl : constrain_pres3.val = [] := List.eq_nil_of_length_eq_zero (by scalar_tac)
      have hm := (hext (lit "user_auth_token_session")).mpr (Or.inr (by simpa only [vec_deref_val] using hsession))
      simp [hl, names] at hm
  all_goals simp only [bne_iff_ne, hn, if_true] at h
  all_goals h5i_invert h
  all_goals try (split at hallowed_rem <;> h5i_invert hallowed_rem)
  all_goals split at hallowed_pres
  all_goals try contradiction
  all_goals have hinter := intersection_inv _ _ _ hallowed_pres
  all_goals refine Or.inr ⟨_, _, _, _, p, rfl, hparent, ?_⟩
  all_goals intro a ha
  all_goals have hc := (hext a).mp (by simpa only [vec_deref_val] using hinter ha)
  all_goals apply hbound a
  all_goals simpa only [vec_new_val, names, List.map_nil, List.not_mem_nil, false_or, vec_deref_val] using hc

lemma requested_pres_inv (ms : Slice Modify) (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : access.requested_pres ms = ok out) :
    ∀ m ∈ ms.val, ∀ a, presAttr m = some a → a ∈ names out.val := by
  unfold access.requested_pres access.requested_pres_loop at h
  refine loop_idx_ok _ Prod.snd ms.val.length
    (fun st => ∀ m ∈ ms.val.take st.2.val, ∀ a, presAttr m = some a → a ∈ names st.1.val)
    (fun out => ∀ m ∈ ms.val, ∀ a, presAttr m = some a → a ∈ names out.val)
    ?_ _ _ (by simp) (by simp) h
  rintro ⟨t, i⟩ res hi hle hr
  dsimp only at hi hle
  unfold access.requested_pres_loop.body at hr
  h5i_invert hr
  · have hlt : i.val < ms.val.length := by scalar_tac
    obtain ⟨_, hv⟩ := slice_index_ok ‹ms.index_usize i = ok _›
    have hj := add_ok_val ‹i + 1#usize = ok _›
    norm_num only [UScalar.ofNatCore_val_eq] at hj
    have hstep : ∀ m' ∈ ms.val.take (i.val + 1), ∀ a, presAttr m' = some a → a ∈ names out1.val := by
      rw [List.take_add_one, List.getElem?_eq_getElem hlt]
      intro m' hmem a ha
      simp only [Option.toList_some, List.mem_append, List.mem_singleton] at hmem
      cases m <;> simp only [presAttr, vec_deref_val] at hout1
      all_goals h5i_invert hout1
      all_goals try (solve | (rcases hmem with hm | rfl; exact hi _ hm _ ha; simp [hv, presAttr] at ha))
      all_goals have ht := insert_inv _ _ _ ‹bset.insert _ _ = ok _›
      all_goals rw [ht]
      all_goals rcases hmem with hm | rfl
      all_goals first
        | exact Or.inl (hi _ hm _ ha)
        | (right; simpa [hv, presAttr, vec_deref_val] using ha.symm)
    refine ⟨?_, by dsimp; omega, by dsimp; omega⟩
    simpa only [hj] using hstep
  · have he : ms.val.length ≤ i.val := by scalar_tac
    simpa [List.take_of_length_le he] using hi

lemma per_entry_inv (ctl : AccessControlsInner) (i : Identity)
    (acp : Slice profiles.AccessControlModifyResolved) (e : Entry) (ms : Slice Modify)
    (m : Modify) (a : List Nat) (hu : IsUser i) (hs : HasClass e "sync_object")
    (hb : UUID_ANONYMOUS < e.uuid) (hp : ∀ c ∈ classes e, c ∉ protectedModEntryClasses)
    (hm : m ∈ ms.val) (ha : presAttr m = some a)
    (h : access.modify_allow_operation_per_entry ctl i acp e ms = ok true) :
    ∃ p, refers e "sync_parent_uuid" = some [p] ∧
      (a ∈ syncAttrs ∨ a ∈ agreementAttrs ctl.sync_agreements.val p) := by
  unfold access.modify_allow_operation_per_entry at h
  h5i_invert h
  all_goals try simp only [uncurry] at h
  all_goals have hmem := requested_pres_inv ms requested_pres hrequested_pres m hm a ha
  all_goals h5i_invert h
  all_goals have hsync := apply_sync_inv i e ctl.sync_agreements.deref acp _ hu hs hb hp hmr
  all_goals rcases hsync with hd | ⟨pres, rem, pc, rc, parent, heq, hparent, hbound⟩
  all_goals try cases hd
  all_goals cases heq
  all_goals h5i_invert hdecision2
  all_goals h5i_invert hdecision1
  all_goals h5i_invert hdecision
  all_goals have htrue : b = true := by assumption
  all_goals have hsubset := post_of_ok (subset_spec _ _) hb_1
  all_goals have hsub := of_decide_eq_true (hsubset.symm.trans htrue)
  all_goals simp only [vec_deref_val] at hsub hbound
  all_goals exact ⟨parent, hparent, hbound a (hsub hmem)⟩

lemma all_entries_inv (ctl : AccessControlsInner) (i : Identity)
    (acp : Slice profiles.AccessControlModifyResolved) (es : Slice Entry) (ms : Slice Modify)
    (h : access.modify_all_entries ctl i acp es ms = ok true) :
    ∀ e ∈ es.val, access.modify_allow_operation_per_entry ctl i acp e ms = ok true := by
  unfold access.modify_all_entries access.modify_all_entries_loop at h
  have hh := loop_idx_ok _ id es.val.length
    (fun j => ∀ e ∈ es.val.take j.val, access.modify_allow_operation_per_entry ctl i acp e ms = ok true)
    (fun b => b = true → ∀ e ∈ es.val, access.modify_allow_operation_per_entry ctl i acp e ms = ok true)
    ?_ 0#usize true (by simp) (by simp) h
  · exact hh rfl
  · intro j res hinv hle hr
    unfold access.modify_all_entries_loop.body at hr
    h5i_invert hr
    · have hj := add_ok_val ‹j + 1#usize = ok _›
      norm_num only [UScalar.ofNatCore_val_eq] at hj
      have hlt : j.val < es.val.length := by scalar_tac
      obtain ⟨_, hv⟩ := slice_index_ok ‹es.index_usize j = ok _›
      refine ⟨?_, by dsimp; omega, by dsimp; omega⟩
      simp only [hj, List.take_add_one, List.getElem?_eq_getElem hlt, Option.toList_some,
        List.mem_append, List.mem_singleton]
      intro e he
      rcases he with he | rfl
      · exact hinv _ he
      · have htrue : b = true := by assumption
        simpa only [hv, htrue] using hb
    · simp
    · have he : es.val.length ≤ j.val := by scalar_tac
      simpa [List.take_of_length_le he] using hinv

theorem sync_object_constrained (ctl : AccessControlsInner) (me : ModifyEvent) (es : Slice Entry) (e : Entry)
    (m : Modify) (a : List Nat)
    (hu : IsUser me.ident) (h : access.modify_allow_operation ctl me es = ok (.Ok true))
    (he : e ∈ es.val) (hs : HasClass e "sync_object")
    (hb : UUID_ANONYMOUS < e.uuid) (hp : ∀ c ∈ classes e, c ∉ protectedModEntryClasses)
    (hm : m ∈ me.modlist.val) (ha : presAttr m = some a) :
    ∃ p, refers e "sync_parent_uuid" = some [p] ∧ (a ∈ syncAttrs ∨ a ∈ agreementAttrs ctl.sync_agreements.val p) := by
  unfold access.modify_allow_operation at h
  h5i_invert h
  have heok := all_entries_inv ctl me.ident related_acp.deref es me.modlist.deref hb_1 e he
  exact per_entry_inv ctl me.ident related_acp.deref e me.modlist.deref m a hu hs hb hp
    (by simpa only [vec_deref_val] using hm) ha heok

end kanidm_kernel.Solution
