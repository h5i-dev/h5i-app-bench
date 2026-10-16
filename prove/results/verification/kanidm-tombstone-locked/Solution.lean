import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit

namespace kanidm_kernel.Solution

@[simp] theorem lit_class : lit "class" = [99, 108, 97, 115, 115] := by decide +kernel
@[simp] theorem lit_system : lit "system" = [115, 121, 115, 116, 101, 109] := by decide +kernel
@[simp] theorem lit_domain_info : lit "domain_info" = [100, 111, 109, 97, 105, 110, 95, 105, 110, 102, 111] := by decide +kernel
@[simp] theorem lit_system_info : lit "system_info" = [115, 121, 115, 116, 101, 109, 95, 105, 110, 102, 111] := by decide +kernel
@[simp] theorem lit_system_config : lit "system_config" = [115, 121, 115, 116, 101, 109, 95, 99, 111, 110, 102, 105, 103] := by decide +kernel
@[simp] theorem lit_dyngroup : lit "dyngroup" = [100, 121, 110, 103, 114, 111, 117, 112] := by decide +kernel
@[simp] theorem lit_tombstone : lit "tombstone" = [116, 111, 109, 98, 115, 116, 111, 110, 101] := by decide +kernel
@[simp] theorem lit_recycled : lit "recycled" = [114, 101, 99, 121, 99, 108, 101, 100] := by decide +kernel

theorem nats_eq_iff (a b : List U8) : nats a = nats b ↔ a = b := by
  constructor
  · intro h
    exact List.map_injective_iff.2 (fun x y h => (u8_eq_iff x y).2 h) h
  · rintro rfl; rfl

theorem bytes_loop_spec (a b : Slice U8) (i : Usize)
    (hlen : a.val.length = b.val.length) (hi : i.val ≤ a.val.length) :
    bset.bytes_eq_loop a b i ⦃ r => r = decide (a.val.drop i.val = b.val.drop i.val) ⦄ := by
  generalize hm : a.val.length - i.val = n
  induction n using Nat.strong_induction_on generalizing i with
  | h n ih =>
    unfold bset.bytes_eq_loop
    rw [loop]
    rw [bset.bytes_eq_loop.body]
    h5i_steps
    · have ha : i.val < a.val.length := by scalar_tac
      have hb : i.val < b.val.length := by omega
      rw [List.drop_eq_getElem_cons ha, List.drop_eq_getElem_cons hb]
      symm
      apply decide_eq_false
      simp only [List.cons.injEq]
      intro heq
      have : a.val[i.val] = b.val[i.val] := heq.1
      simp_all
    ·
      have hia : i.val < a.val.length := by scalar_tac
      have hib : i.val < b.val.length := by omega
      change bset.bytes_eq_loop a b _ ⦃ _ ⦄
      apply WP.spec_mono (ih _ (by omega) _ (by omega) rfl)
      intro r hr
      rw [List.drop_eq_getElem_cons hia, List.drop_eq_getElem_cons hib]
      have hab : a.val[i.val] = b.val[i.val] := by scalar_tac
      simpa only [List.cons.injEq, hab, true_and, x_post] using hr
    · have ha : a.val.length ≤ i.val := by scalar_tac
      have hb : b.val.length ≤ i.val := by omega
      simp [List.drop_eq_nil_of_le ha, List.drop_eq_nil_of_le hb]

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    bset.bytes_eq a b ⦃ r => r = decide (nats a.val = nats b.val) ⦄ := by
  unfold bset.bytes_eq
  step*
  · have hlen : a.val.length ≠ b.val.length := by scalar_tac
    simp only [nats_eq_iff]
    symm
    apply decide_eq_false
    exact fun h => hlen (congrArg List.length h)
  · have hlen : a.val.length = b.val.length := by scalar_tac
    apply WP.spec_mono (bytes_loop_spec a b 0#usize hlen (by simp))
    intro r hr
    simpa [nats_eq_iff] using hr

@[step] theorem ava_spec (e : Entry) (attr : Slice U8) :
    entry_impl.get_ava_set e attr ⦃ r => r = ava e (nats attr.val) ⦄ := by
  unfold entry_impl.get_ava_set entry_impl.get_ava_set_loop
  apply WP.spec_mono (loop_search e.attrs.val
    (fun a => nats a.attr.val == nats attr.val) id (fun _ a => some a.vs) none _ ?_ 0#usize (by simp))
  · intro r hr
    simpa [ava, searchFrom_find] using hr
  · intro i hi
    unfold entry_impl.get_ava_set_loop.body
    h5i_step
    all_goals refine ⟨by scalar_tac, ?_⟩
    all_goals simpa [alloc.vec.Vec.deref] using b_post

@[step] theorem iutf8_spec (e : Entry) (attr : Slice U8) :
    entry_impl.get_ava_as_iutf8 e attr ⦃ r =>
      (match ava e (nats attr.val) with | some (.Iutf8 s) => some s | _ => none) = r ⦄ := by
  unfold entry_impl.get_ava_as_iutf8
  step*
  rw [← o_post]
  rename_i ho
  rw [ho]
  cases vs <;> simp [valueset.as_iutf8_set]

@[step] theorem protected_class_spec (c : Slice U8) :
    protected.protected_mod_entry_classes c ⦃ r =>
      r = decide (nats c.val ∈ protectedModEntryClasses) ⦄ := by
  unfold protected.protected_mod_entry_classes
  step* <;> simp_all [protectedModEntryClasses, nats, Array.to_slice, Array.make]

@[step] theorem locked_class_spec (c : Slice U8) :
    protected.locked_entry_classes c ⦃ r => r = decide (nats c.val = lit "tombstone") ⦄ := by
  unfold protected.locked_entry_classes
  step* <;> simp_all [nats, Array.to_slice, Array.make]

@[step] theorem disjoint_protected_spec (cs : Slice (alloc.vec.Vec U8)) :
    protected.disjoint_protected_mod_entry_classes cs ⦃ r =>
      r = cs.val.all (fun c => !decide (nats c.val ∈ protectedModEntryClasses)) ⦄ := by
  unfold protected.disjoint_protected_mod_entry_classes protected.disjoint_protected_mod_entry_classes_loop
  h5i_search_all cs.val (fun c => decide (nats c.val ∈ protectedModEntryClasses))
  all_goals refine ⟨by scalar_tac, ?_⟩
  all_goals simpa [alloc.vec.Vec.deref] using b_post

@[step] theorem disjoint_locked_spec (cs : Slice (alloc.vec.Vec U8)) :
    protected.disjoint_locked_entry_classes cs ⦃ r =>
      r = cs.val.all (fun c => !decide (nats c.val = lit "tombstone")) ⦄ := by
  unfold protected.disjoint_locked_entry_classes protected.disjoint_locked_entry_classes_loop
  h5i_search_all cs.val (fun c => decide (nats c.val = lit "tombstone"))
  all_goals refine ⟨by scalar_tac, ?_⟩
  all_goals simpa [alloc.vec.Vec.deref] using b_post

theorem tombstone_classes (e : Entry) (ht : HasClass e "tombstone") :
    ∃ cs, ava e (lit "class") = some (.Iutf8 cs) ∧ lit "tombstone" ∈ names cs.val := by
  unfold HasClass classes at ht
  cases ha : ava e (lit "class") with
  | none => simp only [ha, List.not_mem_nil] at ht
  | some vs =>
    cases vs <;> simp only [ha, List.not_mem_nil] at ht
    exact ⟨_, rfl, ht⟩

theorem tombstone_disjoint (cs : Slice (alloc.vec.Vec U8))
    (ht : lit "tombstone" ∈ names cs.val) :
    protected.disjoint_protected_mod_entry_classes cs = ok false ∧
      protected.disjoint_locked_entry_classes cs = ok false := by
  have hp : cs.val.all (fun c => !decide (nats c.val ∈ protectedModEntryClasses)) = false := by
    rw [Bool.eq_false_iff]
    intro h
    obtain ⟨c, hc, heq⟩ := List.mem_map.1 ht
    have hallow := (List.all_eq_true.1 h) c hc
    simp only [Bool.not_eq_true', decide_eq_false_iff_not] at hallow
    apply hallow
    rw [heq]
    simp [protectedModEntryClasses]
  have hl : cs.val.all (fun c => !decide (nats c.val = lit "tombstone")) = false := by
    rw [Bool.eq_false_iff]
    intro h
    obtain ⟨c, hc, heq⟩ := List.mem_map.1 ht
    have hallow := (List.all_eq_true.1 h) c hc
    simp [heq] at hallow
  constructor
  · exact eq_ok_of_spec (WP.spec_mono (disjoint_protected_spec cs) (by intro r hr; exact hr.trans hp))
  · exact eq_ok_of_spec (WP.spec_mono (disjoint_locked_spec cs) (by intro r hr; exact hr.trans hl))

theorem protected_tombstone (ident : Identity) (e : Entry)
    (hn : ident.origin ≠ .Internal .System) (hs : ∀ u, ident.origin ≠ .Synch u)
    (ht : HasClass e "tombstone") :
    modify_acc.modify_protected_attrs ident e ⦃ r => r = .Deny ⦄ := by
  obtain ⟨cs, ha, hc⟩ := tombstone_classes e ht
  have hd := tombstone_disjoint cs.deref (by simpa [alloc.vec.Vec.deref] using hc)
  have hp := post_of_ok (disjoint_protected_spec cs.deref) hd.1
  have he : modify_acc.modify_protected_entry_attrs cs.deref = ok .Deny := by
    simp [modify_acc.modify_protected_entry_attrs, hd.2]
  unfold modify_acc.modify_protected_attrs
  split <;> try contradiction
  all_goals try (rename_i u hu; exact False.elim (hs u hu))
  all_goals try (split <;> try contradiction)
  all_goals step*
  all_goals simp only [s_post] at o_post
  all_goals change (match ava e [99, 108, 97, 115, 115] with
    | some (.Iutf8 s) => some s | _ => none) = o at o_post
  all_goals rw [← lit_class, ha] at o_post
  all_goals simp_all only [Option.some.injEq, reduceCtorEq, WP.spec_ok]
  all_goals first
    | exact Bool.noConfusion (b_post.trans hp.symm)
    | simpa only [he] using (show ok AccessModResult.Deny ⦃ r => r = .Deny ⦄ from by simp)

theorem apply_denied (ident : Identity) (acp : Slice profiles.AccessControlModifyResolved)
    (sa : Slice SyncAgreement) (e : Entry) (r : modify_acc.ModifyResult)
    (hd : modify_acc.modify_ident_test ident = ok .Deny ∨ modify_acc.modify_protected_attrs ident e = ok .Deny)
    (h : modify_acc.apply_modify_access ident acp sa e = ok r) : r = .Deny := by
  unfold modify_acc.apply_modify_access at h
  rcases hd with hd | hd
  · simp only [hd] at h
    iterate 6 (all_goals (h5i_invert h; try h5i_invert hx; try simp only [uncurry] at h))
    all_goals simpa [uncurry] using h.symm
  · simp only [hd] at h
    iterate 6 (all_goals (h5i_invert h; try h5i_invert hx; try simp only [uncurry] at h))
    all_goals first | rfl | simpa [uncurry] using h.symm

theorem apply_tombstone (ident : Identity) (acp : Slice profiles.AccessControlModifyResolved)
    (sa : Slice SyncAgreement) (e : Entry) (r : modify_acc.ModifyResult)
    (hn : ident.origin ≠ .Internal .System) (ht : HasClass e "tombstone")
    (h : modify_acc.apply_modify_access ident acp sa e = ok r) : r = .Deny := by
  apply apply_denied ident acp sa e r ?_ h
  by_cases hs : ∃ u, ident.origin = .Synch u
  · obtain ⟨u, hu⟩ := hs
    exact Or.inl (by simp [modify_acc.modify_ident_test, hu])
  · exact Or.inr (eq_ok_of_spec (protected_tombstone ident e hn (by simpa using hs) ht))

theorem entry_tombstone (ctl : AccessControlsInner) (ident : Identity)
    (acp : Slice profiles.AccessControlModifyResolved) (mods : Slice Modify)
    (e : Entry) (b : Bool) (hn : ident.origin ≠ .Internal .System) (ht : HasClass e "tombstone")
    (h : access.modify_allow_operation_per_entry ctl ident acp e mods = ok b) : b = false := by
  unfold access.modify_allow_operation_per_entry at h
  h5i_invert h
  all_goals try rfl
  all_goals rcases p with ⟨cp, cr⟩
  all_goals simp only [uncurry] at h
  all_goals try (simpa only [Result.ok.injEq] using h.symm)
  all_goals obtain ⟨mr, hmr, h⟩ := bind_eq_ok.1 h
  all_goals have hd := apply_tombstone ident acp ctl.sync_agreements.deref e mr hn ht hmr
  all_goals subst mr
  all_goals simpa using h.symm

theorem entries_tombstone (ctl : AccessControlsInner) (ident : Identity)
    (acp : Slice profiles.AccessControlModifyResolved) (mods : Slice Modify)
    (es : Slice Entry) (e : Entry) (b : Bool)
    (hn : ident.origin ≠ .Internal .System) (ht : HasClass e "tombstone") (he : e ∈ es.val)
    (h : access.modify_all_entries ctl ident acp es mods = ok b) : b = false := by
  unfold access.modify_all_entries access.modify_all_entries_loop at h
  apply loop_idx_ok _ id es.val.length (fun i => e ∈ es.val.drop i.val) (fun b => b = false)
    ?_ 0#usize b (by simpa using he) (by simp) h
  intro i r hmem hle hr
  unfold access.modify_all_entries_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt, hentry⟩ := slice_index_ok he_1
    have hj : i2.val = i.val + 1 := by h5i_arith
    simp only [List.drop_eq_getElem_cons hlt, List.mem_cons] at hmem
    rcases hmem with heq | htail
    · have hes : e = e_1 := heq.trans hentry
      rw [← hes] at hb_1
      have hd := entry_tombstone ctl ident acp mods e b_1 hn ht hb_1
      simp_all
    · exact ⟨by simpa only [hj] using htail, by simp only [id]; omega, by simp only [id]; omega⟩
  · rfl
  · have hend : es.val.length ≤ i.val := by scalar_tac
    simp [List.drop_eq_nil_of_le hend] at hmem


theorem tombstone_locked (ctl : AccessControlsInner) (me : ModifyEvent) (es : Slice Entry) (e : Entry) (b : Bool)
    (hn : me.ident.origin ≠ .Internal .System) (he : e ∈ es.val) (ht : HasClass e "tombstone")
    (h : access.modify_allow_operation ctl me es = ok (.Ok b)) :
    b = false := by
  unfold access.modify_allow_operation at h
  h5i_invert h
  exact entries_tombstone ctl me.ident related_acp.deref me.modlist.deref es e b hn ht he hb_1

end kanidm_kernel.Solution
