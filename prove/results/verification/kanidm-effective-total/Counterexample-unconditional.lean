import Spec
import H5iAppLib
/-!
The requested unconditional totality theorem is false.

Let M = Usize.max. The first search profile grants the M distinct byte
strings consisting of 0, ..., M-1 zero bytes. The second grants the string
of M zero bytes. Each input vector satisfies its length bound, both
profiles apply, and their union needs M+1 elements. The final insertion
returns `fail maximumSizeExceeded`.

`effective_permission_check_fails` verifies the complete extracted call
path; `counterexample` refutes the requested conclusion for these inputs.
Check with `cd proofs && lake env lean Counterexample.lean`.
-/
open Aeneas Aeneas.Std Result kanidm_kernel
open H5iAppLib hiding lit

namespace kanidm_kernel.Counterexample

@[step] theorem bytes_eq_false (a b : Slice U8)
    (h : a.val.length ≠ b.val.length) :
    bset.bytes_eq a b ⦃ r => r = false ⦄ := by
  unfold bset.bytes_eq
  have hn : Slice.len a ≠ Slice.len b := by
    intro he
    apply h
    exact congrArg UScalar.val he
  simp [hn]

theorem contains_false (s : Slice (alloc.vec.Vec U8)) (x : Slice U8)
    (h : ∀ v ∈ s.val, v.val.length ≠ x.val.length) :
    bset.contains s x = ok false := by
  apply eq_ok_of_spec
  unfold bset.contains bset.contains_loop
  h5i_total (fun i => i) s.val.length
  all_goals
    rename_i j hj hlt
    have hh := h (s.val[j.val]) (List.getElem_mem (by scalar_tac))
    simp only [alloc.vec.Vec.deref, Slice.from_val] at *
    exact hh

def fullNames : alloc.vec.Vec (alloc.vec.Vec U8) :=
  alloc.vec.Vec.from
    ((List.range Usize.max).attach.map fun n =>
      alloc.vec.Vec.from (List.replicate n.val (0#u8)) (by
        simp only [List.length_replicate]
        have := List.mem_range.mp n.property
        omega)) (by simp)

def extraName : alloc.vec.Vec U8 :=
  alloc.vec.Vec.from (List.replicate Usize.max (0#u8)) (by simp)

theorem fullNames_length : fullNames.val.length = Usize.max := by
  simp [fullNames]

theorem fullNames_short (v : alloc.vec.Vec U8) (hv : v ∈ fullNames.val) :
    v.val.length < Usize.max := by
  simp only [fullNames, alloc.vec.Vec.from_val, List.mem_map] at hv
  obtain ⟨n, _, rfl⟩ := hv
  simpa using List.mem_range.mp n.property

theorem push_full_fails {α : Type} (v : alloc.vec.Vec α) (x : α)
    (hv : v.val.length = Usize.max) :
    alloc.vec.Vec.push v x = fail Error.maximumSizeExceeded := by
  have hm : U32.max ≤ Usize.max := by
    simpa [U32.max_def, U32.numBits] using usize_max_ge
  have h32 : ¬(v.val.length + 1 ≤ U32.max) := by omega
  have hs : ¬(v.val.length + 1 ≤ Usize.max) := by omega
  simp [alloc.vec.Vec.push, h32, hs]

theorem insert_full_fails :
    bset.insert fullNames extraName.deref = fail Error.maximumSizeExceeded := by
  have hc : bset.contains fullNames.deref extraName.deref = ok false := by
    apply contains_false
    simp only [alloc.vec.Vec.deref, Slice.from_val, extraName, alloc.vec.Vec.from_val,
      List.length_replicate]
    intro v hv
    exact Nat.ne_of_lt (fullNames_short v hv)
  unfold bset.insert
  dsimp only
  rw [hc]
  have hv := alloc.slice.Slice.to_vec_spec core.clone.CloneU8 extraName.deref (fun _ _ => rfl)
  obtain ⟨v, hv, _⟩ := (WP.spec_equiv_exists _ _).mp hv
  simp [hv, push_full_fails fullNames v fullNames_length]

@[step] theorem insert_absent (set : alloc.vec.Vec (alloc.vec.Vec U8))
    (x : Slice U8) (h : ∀ v ∈ set.val, v.val.length ≠ x.val.length)
    (hlen : set.val.length < Usize.max) :
    bset.insert set x ⦃ r => r.val = set.val ++ [{slice := x}] ⦄ := by
  unfold bset.insert
  dsimp only
  have hc : bset.contains set.deref x = ok false :=
    contains_false _ _ (by simpa only [alloc.vec.Vec.deref, Slice.from_val] using h)
  rw [hc]
  step*
  all_goals simp_all only

theorem fullNames_at (i : Nat) (hi : i < fullNames.val.length) :
    (fullNames.val[i]).val.length = i := by
  simp [fullNames] at hi ⊢

theorem fullNames_prefix (i : Nat) (v : alloc.vec.Vec U8)
    (hv : v ∈ fullNames.val.take i) : v.val.length < i := by
  obtain ⟨j, hj, he⟩ := List.mem_iff_getElem.mp hv
  have hj' : j < fullNames.val.length := by
    simp only [List.length_take] at hj
    omega
  have he' : fullNames.val[j] = v := by simpa using he
  rw [← he', fullNames_at j hj']
  simp only [List.length_take] at hj
  omega

theorem fill_fullNames : bset.extend (alloc.vec.Vec.new _) fullNames.deref = ok fullNames := by
  apply eq_ok_of_spec
  unfold bset.extend bset.extend_loop
  apply WP.spec_mono (loop_idx_spec _ (fun x => x.2) fullNames.val.length
    (fun x => x.1.val = fullNames.val.take x.2.val)
    (fun r => r.val = fullNames.val) ?_ _ ?_ ?_)
  · intro r hr
    exact (alloc.vec.Vec.eq_iff _ _).mpr hr
  · rintro ⟨set, i⟩ hset hi
    unfold bset.extend_loop.body
    dsimp only at *
    have hl : (Slice.len fullNames.deref).val = fullNames.val.length := by
      simp [alloc.vec.Vec.deref]
    h5i_steps
    all_goals simp only [UScalar.lt_equiv, Slice.len_val, alloc.vec.Vec.deref, Slice.from_val] at *
    ·
      intro w hw
      rw [hset] at hw
      have hn := fullNames_prefix i.val w hw
      rw [v_post, fullNames_at i.val (by scalar_tac)]
      exact Nat.ne_of_lt hn
    ·
      refine ⟨?_, by scalar_tac, by scalar_tac⟩
      rw [set1_post, hset, i2_post, List.take_add_one,
        List.getElem?_eq_getElem (by scalar_tac)]
      simp only [Option.toList_some, v_post]
      congr 2
      apply alloc.vec.Vec.ext
      simp [alloc.vec.Vec.val]
    · have hi' : fullNames.val.length ≤ i.val := by
        simp only [Slice.length, Slice.from_val] at *
        omega
      rw [hset, List.take_of_length_le hi']
  · simp
  · simp

theorem extend_full_fails :
    bset.extend fullNames (vecOf [extraName]).deref = fail Error.maximumSizeExceeded := by
  unfold bset.extend bset.extend_loop
  rw [loop]
  have hi := insert_full_fails
  simp only [alloc.vec.Vec.deref] at hi
  simp [bset.extend_loop.body, vecOf, alloc.vec.Vec.deref, Slice.len,
    Slice.index_usize, hi]

def trueFilter : FilterComp := .AndNot (.Invalid (alloc.vec.Vec.new U8))
def trueResolved : FilterResolved := .AndNot (.Invalid (alloc.vec.Vec.new U8))

@[step] theorem true_target_applies (e : Entry) (imo : Option (alloc.vec.Vec U128)) (u : U128) :
    search_acc.acp_applies .GroupChecked (.Scope trueResolved) imo u e
      ⦃ r => r = true ⦄ := by
  simp [search_acc.acp_applies, search_acc.receiver_applies, search_acc.target_applies,
    entry_impl.entry_match_no_index, entry_impl.entry_match_no_index_inner, trueResolved]

def fullProfile : profiles.AccessControlSearchResolved :=
  { attrs := fullNames, receiver_condition := .GroupChecked,
    target_condition := .Scope trueResolved }
def extraProfile : profiles.AccessControlSearchResolved :=
  { attrs := vecOf [extraName], receiver_condition := .GroupChecked,
    target_condition := .Scope trueResolved }

theorem allowed_attrs_fails (e : Entry) (imo : Option (alloc.vec.Vec U128)) (u : U128) :
    search_acc.search_allowed_attrs (vecOf [fullProfile, extraProfile]).deref imo u e =
      fail Error.maximumSizeExceeded := by
  unfold search_acc.search_allowed_attrs search_acc.search_allowed_attrs_loop
  rw [loop]
  have ht := eq_ok_of_spec (true_target_applies e imo u)
  have hf := fill_fullNames
  have hx := extend_full_fails
  simp only [alloc.vec.Vec.deref] at hf hx
  simp only [vecOf, alloc.vec.Vec.from_val] at hx
  have h01 : (0#usize : Usize) + 1#usize = ok 1#usize := by
    apply eq_ok_of_spec
    step*
  simp [search_acc.search_allowed_attrs_loop.body, vecOf, alloc.vec.Vec.deref,
    Slice.len, Slice.index_usize, fullProfile, extraProfile, ht,
    search_acc.extend_if, hf, h01]
  rw [loop]
  simp [ht, hx]

@[step] theorem bytes_eq_refl (s : Slice U8) :
    bset.bytes_eq s s ⦃ r => r = true ⦄ := by
  unfold bset.bytes_eq
  simp
  unfold bset.bytes_eq_loop
  h5i_total (fun i => i) s.val.length

def group : alloc.vec.Vec U128 := vecOf [0#u128]
def memberAttr : alloc.vec.Vec U8 :=
  vecOf [109#u8, 101#u8, 109#u8, 98#u8, 101#u8, 114#u8, 111#u8, 102#u8]
def badIdentity : Identity :=
  { origin := .User { entry := { uuid := 0#u128, attrs := vecOf [{ attr := memberAttr, vs := .Refer group }] } }, scope := .ReadOnly }

theorem badIdentity_memberof : identity_impl.get_memberof badIdentity = ok (some group) := by
  unfold identity_impl.get_memberof
  simp [badIdentity, lift, Array.to_slice, Array.make]
  unfold entry_impl.get_ava_refer entry_impl.get_ava_set entry_impl.get_ava_set_loop
  rw [loop]
  have hb := eq_ok_of_spec (bytes_eq_refl memberAttr.deref)
  simp [entry_impl.get_ava_set_loop.body, vecOf, alloc.vec.Vec.deref,
    alloc.vec.Vec.index,
    Slice.index_usize, memberAttr, valueset.as_refer_set] at hb ⊢
  simp [alloc.vec.Vec.from, alloc.vec.Vec.val, hb]

theorem true_resolve (ident : Identity) :
    filter_impl.resolve trueFilter ident = ok (some trueResolved) := by
  simp [filter_impl.resolve, trueFilter, trueResolved, filter_impl.resolve_no_idx,
    u8vec_clone]

theorem group_intersects : bset.intersects_uuid group.deref group.deref = ok true := by
  unfold bset.intersects_uuid bset.intersects_uuid_loop
  rw [loop]
  simp [bset.intersects_uuid_loop.body, group, vecOf, alloc.vec.Vec.deref,
    Slice.len, Slice.index_usize]
  unfold bset.contains_uuid bset.contains_uuid_loop
  rw [loop]
  simp [bset.contains_uuid_loop.body, Slice.len, Slice.index_usize]

@[step] theorem resolve_group (ident : Identity) :
    access.resolve_access_conditions ident (some group) (.Group group) (.Scope trueFilter)
      ⦃ r => r = some (.GroupChecked, .Scope trueResolved) ⦄ := by
  simp [access.resolve_access_conditions, group_intersects, true_resolve]

def fullSearch : profiles.AccessControlSearch :=
  { acp := { receiver := .Group group, target := .Scope trueFilter }, attrs := fullNames }
def extraSearch : profiles.AccessControlSearch :=
  { acp := { receiver := .Group group, target := .Scope trueFilter }, attrs := vecOf [extraName] }
def badCtl : AccessControlsInner :=
  { acps_search := vecOf [fullSearch, extraSearch], acps_create := alloc.vec.Vec.new _,
    acps_modify := alloc.vec.Vec.new _, acps_delete := alloc.vec.Vec.new _,
    sync_agreements := alloc.vec.Vec.new _ }

@[step] theorem search_body0 (ident : Identity) :
    access.search_related_acp_loop.body ident badCtl.acps_search (some group) none
      (alloc.vec.Vec.new _) 0#usize
      ⦃ r => r = .cont (none, vecOf [fullProfile], 1#usize) ⦄ := by
  unfold access.search_related_acp_loop.body
  simp [badCtl, vecOf, alloc.vec.Vec.index, alloc.vec.Vec.from, alloc.vec.Vec.val, Slice.index_usize,
    fullSearch, extraSearch]
  have hm := usize_max_ge
  h5i_steps
  all_goals simp_all
  all_goals h5i_steps
  all_goals simp_all [fullProfile, alloc.vec.Vec.val]
  · omega
  · constructor
    · apply alloc.vec.Vec.ext
      simpa only [alloc.vec.Vec.val, Slice.from_val] using x_post
    · scalar_tac

@[step] theorem search_body1 (ident : Identity) :
    access.search_related_acp_loop.body ident badCtl.acps_search (some group) none
      (vecOf [fullProfile]) 1#usize
      ⦃ r => r = .cont (none, vecOf [fullProfile, extraProfile], 2#usize) ⦄ := by
  unfold access.search_related_acp_loop.body
  simp [badCtl, vecOf, alloc.vec.Vec.index, alloc.vec.Vec.from, alloc.vec.Vec.val, Slice.index_usize,
    fullSearch, extraSearch]
  have hm := usize_max_ge
  h5i_steps
  all_goals simp_all
  all_goals h5i_steps
  all_goals simp_all [fullProfile, extraProfile, vecOf, alloc.vec.Vec.from, alloc.vec.Vec.val]
  · omega
  · constructor
    · apply alloc.vec.Vec.ext
      simpa only [alloc.vec.Vec.val, Slice.from_val] using x_post
    · scalar_tac

theorem related_search :
    access.search_related_acp badCtl badIdentity none = ok (vecOf [fullProfile, extraProfile]) := by
  unfold access.search_related_acp
  simp only [badIdentity_memberof]
  simp
  unfold access.search_related_acp_loop
  rw [loop]
  dsimp only
  rw [eq_ok_of_spec (search_body0 badIdentity)]
  simp
  rw [loop]
  dsimp only
  rw [eq_ok_of_spec (search_body1 badIdentity)]
  simp
  rw [loop]
  simp [access.search_related_acp_loop.body, badCtl, vecOf, alloc.vec.Vec.val, alloc.vec.Vec.from]

theorem related_modify : access.modify_related_acp badCtl badIdentity = ok (alloc.vec.Vec.new _) := by
  unfold access.modify_related_acp
  simp [badIdentity_memberof]
  unfold access.modify_related_acp_loop
  rw [loop]
  simp [access.modify_related_acp_loop.body, badCtl]

theorem related_delete : access.delete_related_acp badCtl badIdentity = ok (alloc.vec.Vec.new _) := by
  unfold access.delete_related_acp
  simp [badIdentity_memberof]
  unfold access.delete_related_acp_loop
  rw [loop]
  simp [access.delete_related_acp_loop.body, badCtl]

theorem search_fails (e : Entry) :
    search_acc.search_filter_entry badIdentity (vecOf [fullProfile, extraProfile]).deref e =
      fail Error.maximumSizeExceeded := by
  have hm := badIdentity_memberof
  simp only [badIdentity] at hm
  simp [search_acc.search_filter_entry, badIdentity, identity_impl.access_scope,
    hm, identity_impl.get_uuid, allowed_attrs_fails]

theorem effective_permission_check_fails (e : Entry) :
    access.effective_permission_check badCtl badIdentity none (vecOf [e]).deref =
      fail Error.maximumSizeExceeded := by
  simp [access.effective_permission_check, related_search, related_modify, related_delete]
  unfold access.effective_permission_check_loop
  rw [loop]
  have hs := search_fails e
  simp only [alloc.vec.Vec.deref, vecOf, alloc.vec.Vec.from_val] at hs
  simp [access.effective_permission_check_loop.body, vecOf, alloc.vec.Vec.deref,
    Slice.len, Slice.index_usize, access.entry_effective_permission_check,
    search_acc.apply_search_access, hs]

def reportEntry : Entry := { uuid := 0#u128, attrs := alloc.vec.Vec.new _ }

theorem counterexample :
    ¬ ∃ y, access.effective_permission_check badCtl badIdentity none (vecOf [reportEntry]).deref = ok y := by
  rintro ⟨y, hy⟩
  rw [effective_permission_check_fails] at hy
  simp at hy

/-- The exact universally quantified statement requested in TASK.md is false. -/
theorem requested_statement_is_false :
    ¬ (∀ (ctl : AccessControlsInner) (ident : Identity)
      (attrs : Option (alloc.vec.Vec (alloc.vec.Vec U8))) (es : Slice Entry),
      ∃ y, access.effective_permission_check ctl ident attrs es = ok y) := by
  intro h
  exact counterexample (h badCtl badIdentity none (vecOf [reportEntry]).deref)

end kanidm_kernel.Counterexample
