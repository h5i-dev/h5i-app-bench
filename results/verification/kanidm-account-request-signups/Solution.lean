import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit

namespace kanidm_kernel.Solution

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    bset.bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold bset.bytes_eq
  dsimp only
  split
  · rename_i hn
    simp only [WP.spec_ok]
    have hn' : a.val.length ≠ b.val.length := by
      scalar_tac
    have : a.val ≠ b.val := fun he => hn' (congrArg List.length he)
    simp [this]
  · rename_i hn
    have hlen : a.val.length = b.val.length := by scalar_tac
    unfold bset.bytes_eq_loop
    apply WP.spec_mono (loop_search (a.val.zip b.val)
      (fun p => !decide (p.1 = p.2)) id (fun _ _ => false) true _ ?_ 0#usize (by simp))
    · intro r hr
      have hh := search_all _ _ _ hr
      simp only [Bool.not_not, id_eq] at hh
      rw [hh, zip_all_eq _ _ hlen]
    · intro i hi
      unfold bset.bytes_eq_loop.body
      h5i_step [List.getElem_zip, hlen]

theorem nats_injective : Function.Injective nats := by
  intro a b h
  induction a generalizing b with
  | nil => cases b <;> simp_all [nats]
  | cons a xs ih =>
    cases b with
    | nil => simp [nats] at h
    | cons b bs =>
      simp only [nats, List.map_cons, List.cons.injEq] at h
      exact congrArg₂ List.cons ((u8_eq_iff a b).mpr h.1) (ih h.2)

@[step] theorem contains_spec (s : Slice (alloc.vec.Vec U8)) (x : Slice U8) :
    bset.contains s x ⦃ r => r = decide (nats x.val ∈ names s.val) ⦄ := by
  unfold bset.contains bset.contains_loop
  apply WP.spec_mono (loop_search s.val (fun v => decide (v.val = x.val))
    id (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr
    have hh := search_any _ _ _ hr
    simp only [id_eq] at hh
    rw [hh, Bool.eq_iff_iff]
    simp only [List.any_eq_true, decide_eq_true_eq, names, List.mem_map]
    constructor
    · rintro ⟨v, hv, he⟩
      exact ⟨v, hv, congrArg nats he⟩
    · rintro ⟨v, hv, he⟩
      exact ⟨v, hv, nats_injective he⟩
  · intro i hi
    unfold bset.contains_loop.body
    h5i_step [alloc.vec.Vec.deref]

@[step] theorem get_ava_set_spec (e : Entry) (attr : Slice U8) :
    entry_impl.get_ava_set e attr ⦃ r => r = ava e (nats attr.val) ⦄ := by
  unfold entry_impl.get_ava_set entry_impl.get_ava_set_loop
  apply WP.spec_mono (loop_search e.attrs.val
    (fun a => decide (a.attr.val = attr.val)) id (fun _ a => some a.vs) none _ ?_ 0#usize (by simp))
  · intro r hr
    simp only [id_eq, searchFrom_find, UScalar.ofNatCore_val_eq, List.drop_zero] at hr
    rw [hr]
    unfold ava
    congr 1
    congr 1
    funext a
    apply Bool.eq_iff_iff.mpr
    simp only [beq_iff_eq, decide_eq_true_eq]
    exact ⟨congrArg nats, fun he => nats_injective he⟩
  · intro i hi
    unfold entry_impl.get_ava_set_loop.body
    h5i_step [alloc.vec.Vec.deref]

@[step] theorem insert_spec (s : alloc.vec.Vec (alloc.vec.Vec U8)) (x : Slice U8)
    (hlen : s.val.length < Usize.max) :
    bset.insert s x ⦃ r => r.val.length ≤ s.val.length + 1 ∧
      names r.val = if nats x.val ∈ names s.val then names s.val
        else names s.val ++ [nats x.val] ⦄ := by
  unfold bset.insert
  step* <;> simp_all [names, nats, alloc.vec.Vec.deref]
  split
  · rename_i he
    obtain ⟨v, hv, he⟩ := he
    exact False.elim ((b_post v hv) he)
  · rfl

@[step] theorem get_ava_names_spec (e : Entry) :
    entry_impl.get_ava_names e ⦃ r => r.val = e.attrs.val.map (·.attr) ⦄ := by
  unfold entry_impl.get_ava_names entry_impl.get_ava_names_loop
  apply WP.spec_mono (loop_fold e.attrs.val (fun s => s.val)
    (fun acc a => acc ++ [a.attr]) (fun s i => s.val.length = i) _ ?_
    (alloc.vec.Vec.new (alloc.vec.Vec U8)) 0#usize (by simp) (by rfl))
  · intro r hr
    simpa only [UScalar.ofNatCore_val_eq, List.drop_zero, vec_new_val,
      foldl_map, List.nil_append] using hr
  · intro s i hi hI
    unfold entry_impl.get_ava_names_loop.body
    h5i_step

@[step] theorem is_subset_spec (a b : Slice (alloc.vec.Vec U8)) :
    bset.is_subset a b ⦃ r => r = true → names a.val ⊆ names b.val ⦄ := by
  unfold bset.is_subset bset.is_subset_loop
  apply WP.spec_mono (loop_search a.val
    (fun v => !decide (nats v.val ∈ names b.val)) id (fun _ _ => false) true _ ?_ 0#usize (by simp))
  · intro r hr ht
    have hh := search_all _ _ _ hr
    simp only [id_eq, Bool.not_not] at hh
    rw [ht] at hh
    have hall := List.all_eq_true.mp hh.symm
    intro c hc
    obtain ⟨v, hv, rfl⟩ := List.mem_map.mp hc
    exact of_decide_eq_true (hall v hv)
  · intro i hi
    unfold bset.is_subset_loop.body
    h5i_step [alloc.vec.Vec.deref]

theorem iutf8_classes (e : Entry) (attr : Slice U8)
    (ha : nats attr.val = lit "class") (s : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : entry_impl.get_ava_as_iutf8 e attr = ok (some s)) :
    classes e = names s.val := by
  unfold entry_impl.get_ava_as_iutf8 at h
  h5i_invert h
  have hv := post_of_ok (get_ava_set_spec e attr) ho
  rw [ha] at hv
  unfold valueset.as_iutf8_set at h
  h5i_invert h
  simp only [Option.some.injEq] at h
  subst h
  simp [classes, ← hv]

def signupAttrs : List (List Nat) :=
  ["class", "delete_after", "displayname", "mail", "name", "uuid"].map lit

def signupClasses : List (List Nat) := ["object", "account_signup_request"].map lit

@[simp] theorem names_nil : names [] = [] := rfl
@[simp] theorem names_cons (x : alloc.vec.Vec U8) (xs : List (alloc.vec.Vec U8)) :
    names (x :: xs) = nats x.val :: names xs := rfl
@[simp] theorem names_append (xs ys : List (alloc.vec.Vec U8)) :
    names (xs ++ ys) = names xs ++ names ys := List.map_append

set_option maxHeartbeats 2000000 in
@[step] theorem create_filter_account_spec (ident : Identity)
    (acp : Slice profiles.AccessControlCreateResolved) (e : Entry)
    (hr : ident.origin = .Internal .AccountRequest) :
    create_acc.create_filter_entry ident acp e ⦃ r =>
      match r with
      | .Allow a c => names a.val = signupAttrs ∧ names c.val = signupClasses
      | _ => False ⦄ := by
  have hmax := usize_max_ge
  unfold create_acc.create_filter_entry
  rw [hr]
  step*
  all_goals simp_all [nats, lit, signupAttrs, signupClasses,
    alloc.vec.Vec.new]
  all_goals decide +kernel

theorem push_val {α} (s r : alloc.vec.Vec α) (x : α)
    (h : alloc.vec.Vec.push s x = ok r) : r.val = s.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  dsimp only at h
  h5i_invert h
  simp only [alloc.vec.Vec.from_val, List.concat_eq_append]

theorem insert_subset (s : alloc.vec.Vec (alloc.vec.Vec U8)) (x : Slice U8)
    (r : alloc.vec.Vec (alloc.vec.Vec U8)) (h : bset.insert s x = ok r) :
    names r.val ⊆ names s.val ++ [nats x.val] := by
  unfold bset.insert at h
  h5i_invert h
  · simp
  · have hx := post_of_ok (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 x (by intros; rfl)) hv
    have hp := push_val s r v h
    simp only [names, hp, List.map_append, List.map_cons, List.map_nil]
    rw [hx]
    exact List.Subset.refl _

theorem extend_subset (s : alloc.vec.Vec (alloc.vec.Vec U8))
    (xs : Slice (alloc.vec.Vec U8)) (r : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : bset.extend s xs = ok r) : names r.val ⊆ names s.val ++ names xs.val := by
  unfold bset.extend bset.extend_loop at h
  apply loop_idx_ok _ (fun x => x.2) xs.val.length
    (fun x => names x.1.val ⊆ names s.val ++ names xs.val)
    (fun r => names r.val ⊆ names s.val ++ names xs.val) ?_ (s, 0#usize) r
    (by simp) (by simp) h
  rintro ⟨out, i⟩ res hI hi hs
  unfold bset.extend_loop.body at hs
  h5i_invert hs
  · have hv' := slice_index_ok_mem hv
    have hins := insert_subset out v.deref set1 hset1
    refine ⟨?_, ?_, ?_⟩
    · intro c hc
      have hh := hins hc
      simp only [List.mem_append, List.mem_singleton] at hh
      rcases hh with hh | rfl
      · exact hI hh
      · exact List.mem_append_right _ (List.mem_map.mpr ⟨v, hv', by simp [alloc.vec.Vec.deref]⟩)
    · h5i_arith
    · h5i_arith
  · exact hI

theorem remove_protected_subset (xs : Slice (alloc.vec.Vec U8))
    (r : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : protected.remove_protected_mod_pres xs = ok r) : names r.val ⊆ names xs.val := by
  unfold protected.remove_protected_mod_pres protected.remove_protected_mod_pres_loop at h
  apply loop_idx_ok _ (fun x => x.2) xs.val.length
    (fun x => names x.1.val ⊆ names xs.val) (fun r => names r.val ⊆ names xs.val)
    ?_ (alloc.vec.Vec.new _, 0#usize) r (by simp [names, alloc.vec.Vec.new]) (by simp) h
  rintro ⟨out, i⟩ res hI hi hs
  unfold protected.remove_protected_mod_pres_loop.body at hs
  h5i_invert hs
  · have hc' := post_of_ok (u8vec_clone_spec v) hc_1
    subst c
    h5i_invert hout1
    · exact ⟨hI, by h5i_arith, by h5i_arith⟩
    · have hp := push_val out out1 v hout1
      refine ⟨?_, by h5i_arith, by h5i_arith⟩
      intro c hc
      simp only [names, hp, List.map_append, List.map_cons, List.map_nil,
        List.mem_append, List.mem_singleton] at hc
      rcases hc with hc | rfl
      · exact hI hc
      · exact List.mem_map.mpr ⟨v, slice_index_ok_mem hv, rfl⟩
  · exact hI

def AccountCreateResult (r : create_acc.CreateResult) : Prop :=
  match r with
  | .Allow a c => names a.val ⊆ signupAttrs ∧ names c.val ⊆ signupClasses
  | _ => False

theorem apply_create_account (ident : Identity)
    (acp : Slice profiles.AccessControlCreateResolved) (e : Entry)
    (hr : ident.origin = .Internal .AccountRequest) (r : create_acc.CreateResult)
    (h : create_acc.apply_create_access ident acp e = ok r) : AccountCreateResult r := by
  unfold create_acc.apply_create_access at h
  simp only [create_acc.protected_filter_entry, create_acc.message_queue,
    create_acc.migration_filter_entry, hr, bind_ok] at h
  simp only [uncurry] at h
  simp [alloc.vec.Vec.len, alloc.vec.Vec.new] at h
  h5i_invert h
  have hf := post_of_ok (create_filter_account_spec ident acp e hr) hi3
  cases i3 with
  | Deny => simp at hf
  | Grant => simp at hf
  | Ignore => simp at hf
  | Allow a c =>
    simp only at hf
    h5i_invert hx
    simp only [uncurry] at h
    h5i_invert h
    have ha := extend_subset _ _ _ hallow_pres3
    have hc := extend_subset _ _ _ hallow_pres_cls3
    have hp := remove_protected_subset _ _ hallowed_pres_cls1
    simp [alloc.vec.Vec.deref, hf.1, hf.2] at ha hc hp
    exact ⟨ha, hp.trans hc⟩

def SignupEntry (e : Entry) : Prop :=
  (∀ x ∈ e.attrs.val, nats x.attr.val ∈ signupAttrs) ∧ classes e ⊆ signupClasses

theorem create_allow_account (ident : Identity)
    (acp : Slice profiles.AccessControlCreateResolved) (e : Entry)
    (hr : ident.origin = .Internal .AccountRequest)
    (h : access.create_allow_entry ident acp e = ok true) : SignupEntry e := by
  unfold access.create_allow_entry at h
  h5i_invert h
  all_goals have hf := apply_create_account ident acp e hr _ (by assumption)
  all_goals simp only [AccountCreateResult] at hf
  h5i_invert hdecision
  have ha := post_of_ok (is_subset_spec requested_pres.deref a.deref) hb hc_1
  have hcls := post_of_ok (is_subset_spec r_attrs.deref a_1.deref) hb1 hc
  have hnames := post_of_ok (get_ava_names_spec e) hrequested_pres
  have hs' : nats s.val = lit "class" := by
    simp only [lift, Result.ok.injEq] at hs
    rw [← hs]
    simp [nats]
    decide +kernel
  have hclasses := iutf8_classes e s hs' r_attrs ho
  simp [alloc.vec.Vec.deref] at ha hcls
  constructor
  · intro x hx
    apply hf.1
    apply ha
    simp only [names, hnames, List.map_map]
    exact List.mem_map.mpr ⟨x, hx, rfl⟩
  · rw [hclasses]
    exact hcls.trans hf.2

theorem create_all_entries_property (ident : Identity)
    (acp : Slice profiles.AccessControlCreateResolved) (entries : Slice Entry)
    (P : Entry → Prop)
    (hp : ∀ e, access.create_allow_entry ident acp e = ok true → P e)
    (h : access.create_all_entries ident acp entries = ok true) : ∀ e ∈ entries.val, P e := by
  unfold access.create_all_entries access.create_all_entries_loop at h
  have hall := loop_idx_ok _ (fun i => i) entries.val.length
    (fun i => ∀ k (hk : k < entries.val.length), k < i.val → P entries.val[k])
    (fun b => b = true → ∀ e ∈ entries.val, P e) ?_
    0#usize true (by simp) (by simp) h
  · exact hall rfl
  · intro i res hI hi hs
    unfold access.create_all_entries_loop.body at hs
    h5i_invert hs
    · have he := slice_index_ok he
      obtain ⟨hei, heq⟩ := he
      have hP := hp e (by simpa [hc_1] using hb)
      refine ⟨?_, by h5i_arith, by h5i_arith⟩
      intro k hk hki
      have hinc : i2.val = i.val + 1 := by simpa using add_ok_val hi2
      by_cases hki' : k < i.val
      · exact hI k hk hki'
      · have : k = i.val := by omega
        subst this
        simpa only [heq] using hP
    · simp
    · intro _ e he
      obtain ⟨k, hk, rfl⟩ := List.mem_iff_getElem.mp he
      apply hI k hk
      h5i_arith

theorem account_request_creates_signups (ctl : AccessControlsInner) (ce : CreateEvent) (es : Slice Entry)
    (e : Entry)
    (hr : ce.ident.origin = .Internal .AccountRequest)
    (h : access.create_allow_operation ctl ce es = ok (.Ok true)) (he : e ∈ es.val) :
    (∀ x ∈ e.attrs.val,
      nats x.attr.val ∈ ["class", "delete_after", "displayname", "mail", "name", "uuid"].map lit) ∧
    ∀ c ∈ classes e, c ∈ ["object", "account_signup_request"].map lit := by
  unfold access.create_allow_operation at h
  h5i_invert h
  exact create_all_entries_property ce.ident related_acp.deref es SignupEntry
    (fun e h => create_allow_account ce.ident related_acp.deref e hr h) hb e he

end kanidm_kernel.Solution
