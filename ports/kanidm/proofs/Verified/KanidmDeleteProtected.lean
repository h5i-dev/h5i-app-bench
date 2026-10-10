import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit

namespace kanidm_kernel.Verified.KanidmDeleteProtected

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    bset.bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold bset.bytes_eq
  by_cases hl : a.length = b.length
  · have hl' : a.val.length = b.val.length := by simpa using hl
    simp only [Slice.len, bne_iff_ne, ne_eq]
    split
    · rename_i h; exfalso; apply h; scalar_tac
    · unfold bset.bytes_eq_loop
      apply WP.spec_mono (H5iAppLib.loop_search (List.zip a.val b.val) (fun p => p.1 != p.2) id
        (fun _ _ => false) true _ ?step 0#usize (by simp))
      · intro r hr
        simp only [id] at hr
        have h := H5iAppLib.search_all _ _ _ hr
        rw [h, ← zip_all_eq _ _ hl']
        congr 1; funext p; by_cases hp : p.1 = p.2 <;> simp [hp]
      · intro j hj
        unfold bset.bytes_eq_loop.body
        h5i_step
  · simp only [Slice.len, bne_iff_ne, ne_eq]
    split
    · simp only [WP.spec_ok]
      have : a.val ≠ b.val := fun h => hl (by simp [Slice.length, h])
      simp [this]
    · rename_i h; exfalso; apply hl; simpa using h

@[simp] theorem vec_deref_val {T : Type} (v : alloc.vec.Vec T) : (alloc.vec.Vec.deref v).val = v.val := by
  simp [alloc.vec.Vec.deref]

theorem nats_inj {a b : List U8} : nats a = nats b ↔ a = b := by
  unfold nats
  constructor
  · intro h
    exact List.map_injective_iff.2 (fun x y hxy => by scalar_tac) h
  · rintro rfl; rfl

theorem pec_eq : protectedEntryClasses = [[115, 121, 115, 116, 101, 109],
    [100, 111, 109, 97, 105, 110, 95, 105, 110, 102, 111],
    [115, 121, 115, 116, 101, 109, 95, 105, 110, 102, 111],
    [115, 121, 115, 116, 101, 109, 95, 99, 111, 110, 102, 105, 103],
    [100, 121, 110, 103, 114, 111, 117, 112],
    [115, 121, 110, 99, 95, 111, 98, 106, 101, 99, 116],
    [116, 111, 109, 98, 115, 116, 111, 110, 101],
    [114, 101, 99, 121, 99, 108, 101, 100]] := by
  unfold protectedEntryClasses; decide +kernel

theorem lit_class : lit "class" = [99, 108, 97, 115, 115] := by decide +kernel

@[step] theorem get_ava_set_spec (e : Entry) (attr : Slice U8) :
    entry_impl.get_ava_set e attr ⦃ o =>
      o = (e.attrs.val.find? (fun x => decide (x.attr.val = attr.val))).map (·.vs) ⦄ := by
  unfold entry_impl.get_ava_set entry_impl.get_ava_set_loop
  apply WP.spec_mono (H5iAppLib.loop_search e.attrs.val (fun x => decide (x.attr.val = attr.val)) id
    (fun _ x => some x.vs) none _ ?step 0#usize (by simp))
  · intro r hr
    simp only [id] at hr
    rw [hr, searchFrom_find]; simp
  · intro j hj
    unfold entry_impl.get_ava_set_loop.body
    h5i_step

def iutf8Of : Option ValueSet → Option (alloc.vec.Vec (alloc.vec.Vec U8))
  | some (.Iutf8 s) => some s
  | _ => none

@[step] theorem get_ava_as_iutf8_spec (e : Entry) (attr : Slice U8) :
    entry_impl.get_ava_as_iutf8 e attr ⦃ o =>
      o = iutf8Of ((e.attrs.val.find? (fun x => decide (x.attr.val = attr.val))).map (·.vs)) ⦄ := by
  unfold entry_impl.get_ava_as_iutf8
  obtain ⟨o, ho, hpost⟩ := (WP.spec_equiv_exists _ _).1 (get_ava_set_spec e attr)
  rw [ho]
  rcases o with _ | vs
  · simp [iutf8Of, ← hpost]
  · cases vs <;> simp [valueset.as_iutf8_set, iutf8Of, ← hpost]

theorem lit_slice_eq (c : Slice U8) (n : Usize) (l : List U8) (h : l.length = n.val) :
    (c.val = (Array.make n l h).to_slice.val) ↔ nats c.val = nats l := by
  rw [nats_inj]; simp [Array.to_slice, Array.make]

@[step] theorem protected_entry_classes_spec (c : Slice U8) :
    protected.protected_entry_classes c ⦃ b => b = decide (nats c.val ∈ protectedEntryClasses) ⦄ := by
  unfold protected.protected_entry_classes
  h5i_steps
  all_goals (subst_vars; simp only [lit_slice_eq] at *; simp only [nats, List.map_cons, List.map_nil] at *; rw [pec_eq]; simp_all)

@[step] theorem disjoint_spec (s : Slice (alloc.vec.Vec U8)) :
    protected.disjoint_protected_entry_classes s ⦃ b =>
      b = s.val.all (fun c => !decide (nats c.val ∈ protectedEntryClasses)) ⦄ := by
  unfold protected.disjoint_protected_entry_classes protected.disjoint_protected_entry_classes_loop
  h5i_search_all s.val (fun c : alloc.vec.Vec U8 => decide (nats c.val ∈ protectedEntryClasses))

theorem all_entries_ok (ident : Identity) (acp : Slice profiles.AccessControlDeleteResolved)
    (es : Slice Entry) (h : access.delete_all_entries_loop ident acp es 0#usize = ok true) :
    ∀ k (hk : k < es.val.length), delete_acc.apply_delete_access ident acp es.val[k] = ok .Grant := by
  refine H5iAppLib.loop_idx_ok (access.delete_all_entries_loop.body ident acp es) id es.val.length
    (fun i => ∀ k (hk : k < es.val.length), k < i.val → delete_acc.apply_delete_access ident acp es.val[k] = ok .Grant)
    (fun b => b = true → ∀ k (hk : k < es.val.length), delete_acc.apply_delete_access ident acp es.val[k] = ok .Grant)
    ?_ 0#usize true (by simp) (by simp) h rfl
  intro x r hI hx hr
  unfold access.delete_all_entries_loop.body at hr
  h5i_invert hr
  · simp
  · obtain ⟨hxl, hxe⟩ := slice_index_ok he
    have hi2v := add_ok_val hi2
    simp only [id]
    refine ⟨fun k hk hk2 => ?_, by simp at hi2v ⊢; omega, by simp at hi2v ⊢; omega⟩
    by_cases hkx : k < x.val
    · exact hI k hk hkx
    · have : k = x.val := by simp at hi2v; omega
      subst this
      rw [hxe]; exact hdr
  · simp only [id] at hx
    intro _ k hk
    exact hI k hk (by simp [Slice.len] at hc; scalar_tac)

theorem classes_eq (e : Entry) (s : Slice U8) (L : List U8) (hL : lit "class" = nats L) (hs : s.val = L) :
    classes e = match iutf8Of ((e.attrs.val.find? (fun x => decide (x.attr.val = s.val))).map (·.vs)) with
      | some v => names v.val
      | none => [] := by
  have hp : (fun x : Ava => nats x.attr.val == lit "class") = (fun x => decide (x.attr.val = s.val)) := by
    funext x
    rw [hs, hL, Bool.eq_iff_iff, beq_iff_eq, decide_eq_true_iff, nats_inj]
  unfold classes ava
  rw [hp]
  rcases List.find? _ _ with _ | a
  · simp [iutf8Of]
  · cases h : a.vs <;> simp [iutf8Of, h]

theorem classes_safe (e : Entry) (s : Slice U8) (hs : s.val = [99#u8, 108#u8, 97#u8, 115#u8, 115#u8])
    (o : Option (alloc.vec.Vec (alloc.vec.Vec U8))) (ho : entry_impl.get_ava_as_iutf8 e s = ok o)
    (hd : ∀ v, o = some v → protected.disjoint_protected_entry_classes v.deref = ok true) :
    ∀ c ∈ classes e, c ∉ protectedEntryClasses := by
  have ho' := post_of_ok (get_ava_as_iutf8_spec e s) ho
  rw [classes_eq e s _ (by rw [lit_class]; rfl) hs, ← ho']
  rcases o with _ | v
  · simp
  · have hb := post_of_ok (disjoint_spec v.deref) (hd v rfl)
    simp only [vec_deref_val] at hb
    intro c hc
    simp only [names, List.mem_map] at hc
    obtain ⟨c', hc', rfl⟩ := hc
    have := List.all_eq_true.1 hb.symm c' hc'
    simpa using this

theorem protected_ok (ident : Identity) (e : Entry) (r : delete_acc.IResult)
    (hk : IsUser ident ∨ ident.origin = .Internal .Migration)
    (h : delete_acc.protected_filter_entry ident e = ok r) (hr : r ≠ .Deny) :
    UUID_ANONYMOUS < e.uuid ∧ ∀ c ∈ classes e, c ∉ protectedEntryClasses := by
  unfold delete_acc.protected_filter_entry at h
  h5i_invert h
  all_goals (try exact absurd rfl hr)
  all_goals (try (exfalso; rcases hk with ⟨u, hu⟩ | hu <;> simp_all; done))
  all_goals (have hsv : s.val = [99#u8, 108#u8, 97#u8, 115#u8, 115#u8] := by
               simp only [lift, ok.injEq] at hs; subst hs; simp [Array.to_slice, Array.make])
  all_goals refine ⟨by scalar_tac, classes_safe e s hsv _ ho ?_⟩
  all_goals (intro v hv; simp_all)

theorem delete_protected (ctl : AccessControlsInner) (de : DeleteEvent) (es : Slice Entry) (e : Entry)
    (hk : IsUser de.ident ∨ de.ident.origin = .Internal .Migration)
    (h : access.delete_allow_operation ctl de es = ok (.Ok true)) (he : e ∈ es.val) :
    UUID_ANONYMOUS < e.uuid ∧ ∀ c ∈ classes e, c ∉ protectedEntryClasses := by
  unfold access.delete_allow_operation at h
  h5i_invert h
  obtain ⟨k, hkl, rfl⟩ := List.getElem_of_mem he
  have ha := all_entries_ok _ _ _ hb k hkl
  unfold delete_acc.apply_delete_access at ha
  h5i_invert ha
  refine protected_ok _ _ i hk hi ?_
  rintro rfl
  simp only [ok.injEq] at hdenied
  subst hdenied
  cases i1 <;> simp only [ok.injEq] at hx <;> subst hx <;> simp at ha

end kanidm_kernel.Verified.KanidmDeleteProtected
