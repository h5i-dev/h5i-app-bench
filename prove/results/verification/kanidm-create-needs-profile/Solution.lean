import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit

namespace kanidm_kernel.Solution

open Aeneas.Std.WP
set_option maxHeartbeats 2000000

lemma bytes_eq_sound (a b : Slice U8) (r : Bool)
    (h : bset.bytes_eq a b = ok r) : r = decide (a.val = b.val) := by
  unfold bset.bytes_eq at h
  h5i_invert h
  · have hne : a.val ≠ b.val := by
      intro heq
      simp [Slice.len, heq] at hc
    simp [hne]
  ·
    have hlen : a.val.length = b.val.length := by
      simp only [Slice.len] at hc
      scalar_tac
    unfold bset.bytes_eq_loop at h
    refine loop_idx_ok _ id a.val.length
      (fun i => ∀ j, j < i.val → a.val[j]? = b.val[j]?)
      (fun r => r = decide (a.val = b.val)) ?_ 0#usize r
      (by simp) (by simp) h
    intro i res hi hn hs
    unfold bset.bytes_eq_loop.body at hs
    h5i_invert hs
    · have ⟨hxlt, hxeq⟩ := slice_index_ok hi2
      have ⟨hylt, hyeq⟩ := slice_index_ok hi3
      have hne' : a.val ≠ b.val := by
        intro heq
        have : i2 = i3 := by
          have hh := congrArg (fun l : List U8 => l[i.val]?) heq
          rw [List.getElem?_eq_getElem hxlt, List.getElem?_eq_getElem hylt, hxeq, hyeq] at hh
          exact Option.some.inj hh
        simp_all
      simp [hne']
    · have hjv := add_ok_val hi4
      refine ⟨?_, ?_, ?_⟩
      · intro k hk
        by_cases hki : k < i.val
        · exact hi k hki
        · have hki : k = i.val := by scalar_tac
          subst k
          have ⟨hxlt, hxeq⟩ := slice_index_ok hi2
          have ⟨hylt, hyeq⟩ := slice_index_ok hi3
          simp_all
          scalar_tac
      · simp only [id_eq] at *; scalar_tac
      · simp only [id_eq, Slice.len] at *; scalar_tac
    ·
      have heq : a.val = b.val := by
        apply List.ext_getElem?
        intro j
        by_cases hj : j < a.val.length
        · exact hi j (by simp only [Slice.len] at hc_1; scalar_tac)
        · simp [List.getElem?_eq_none (by omega : a.val.length ≤ j), List.getElem?_eq_none (by omega : b.val.length ≤ j)]
      simp [heq]

lemma nats_inj (a b : List U8) : nats a = nats b ↔ a = b := by
  induction a generalizing b with
  | nil => cases b <;> simp [nats]
  | cons x xs ih =>
    cases b with
    | nil => simp [nats]
    | cons y ys => simp only [nats, List.map_cons, List.cons.injEq] at *; rw [← u8_eq_iff, ih]

lemma get_ava_sound (e : Entry) (a : Slice U8) (o : Option ValueSet)
    (h : entry_impl.get_ava_set e a = ok o) : o = ava e (nats a.val) := by
  unfold entry_impl.get_ava_set entry_impl.get_ava_set_loop at h
  let P := fun x : Ava => nats x.attr.val == nats a.val
  have hm : searchFrom e.attrs.val P (fun _ x => some x.vs) none 0 = ava e (nats a.val) := by
    rw [searchFrom_find, List.drop_zero]
    rfl
  refine loop_idx_ok _ id e.attrs.val.length
    (fun i => searchFrom e.attrs.val P (fun _ x => some x.vs) none i.val = ava e (nats a.val))
    (fun o => o = ava e (nats a.val)) ?_ 0#usize o hm (by simp) h
  intro i r hi hn hs
  unfold entry_impl.get_ava_set_loop.body at hs
  h5i_invert hs
  · have hb := bytes_eq_sound _ _ _ hb
    obtain ⟨hlt, heq⟩ := vec_index_ok (by rwa [alloc.vec.Vec.index_slice_index] at ha_1)
    have hp : P e.attrs.val[i.val] = true := by
      simp_all [P, alloc.vec.Vec.deref]
    rw [← hi, searchFrom_found hlt hp]
    simp [heq]
  · have hb := bytes_eq_sound _ _ _ hb
    obtain ⟨hlt, heq⟩ := vec_index_ok (by rwa [alloc.vec.Vec.index_slice_index] at ha_1)
    have hp : ¬ P e.attrs.val[i.val] = true := by
      simp_all [P, alloc.vec.Vec.deref, nats_inj]
    have hv : i2.val = i.val + 1 := by simpa using add_ok_val hi2
    refine ⟨?_, ?_, ?_⟩
    · rw [hv, ← searchFrom_skip hlt hp]; exact hi
    · simp only [id_eq]; scalar_tac
    · simp only [id_eq]; omega
  · rw [← hi, searchFrom_end (by simp only [alloc.vec.Vec.len] at hc; scalar_tac)]

lemma contains_sound (s : Slice (alloc.vec.Vec U8)) (a : Slice U8)
    (h : bset.contains s a = ok true) : ∃ v ∈ s.val, v.val = a.val := by
  unfold bset.contains bset.contains_loop at h
  refine loop_idx_ok _ id s.val.length (fun _ => True)
    (fun b => b = true → ∃ v ∈ s.val, v.val = a.val) ?_ 0#usize true trivial (by simp) h rfl
  intro i r _ hn hs
  unfold bset.contains_loop.body at hs
  h5i_invert hs
  · intro _
    have hb := bytes_eq_sound _ _ _ hb
    exact ⟨v, slice_index_ok_mem hv, by simpa [hc_1, alloc.vec.Vec.deref] using hb.symm⟩
  · have hv := add_ok_val hi2
    simp only [id_eq, Slice.len] at *
    exact ⟨trivial, by scalar_tac, by scalar_tac⟩
  · simp

lemma contains_uuid_sound (s : Slice U128) (u : U128)
    (h : bset.contains_uuid s u = ok true) : u ∈ s.val := by
  unfold bset.contains_uuid bset.contains_uuid_loop at h
  refine loop_idx_ok _ id s.val.length (fun _ => True)
    (fun b => b = true → u ∈ s.val) ?_ 0#usize true trivial (by simp) h rfl
  intro i r _ hn hs
  unfold bset.contains_uuid_loop.body at hs
  h5i_invert hs
  · intro _; simpa [hc_1] using slice_index_ok_mem hi2
  · have hv := add_ok_val hi3
    simp only [id_eq, Slice.len] at *
    exact ⟨trivial, by scalar_tac, by scalar_tac⟩
  · simp

lemma intersects_uuid_sound (a b : Slice U128)
    (h : bset.intersects_uuid a b = ok true) : ∃ u ∈ a.val, u ∈ b.val := by
  unfold bset.intersects_uuid bset.intersects_uuid_loop at h
  refine loop_idx_ok _ id a.val.length (fun _ => True)
    (fun r => r = true → ∃ u ∈ a.val, u ∈ b.val) ?_ 0#usize true trivial (by simp) h rfl
  intro i r _ hn hs
  unfold bset.intersects_uuid_loop.body at hs
  h5i_invert hs
  · intro _
    exact ⟨i2, slice_index_ok_mem hi2, contains_uuid_sound _ _ (by simpa [hc_1] using hb1)⟩
  · have hv := add_ok_val hi3
    simp only [id_eq, Slice.len] at *
    exact ⟨trivial, by scalar_tac, by scalar_tac⟩
  · simp

lemma subset_sound (a b : Slice (alloc.vec.Vec U8))
    (h : bset.is_subset a b = ok true) : ∀ v ∈ a.val, v ∈ b.val := by
  unfold bset.is_subset bset.is_subset_loop at h
  refine loop_idx_ok _ id a.val.length
    (fun i => ∀ k, k < i.val → ∀ hk : k < a.val.length, a.val[k] ∈ b.val)
    (fun r => r = true → ∀ v ∈ a.val, v ∈ b.val) ?_ 0#usize true (by simp) (by simp) h rfl
  intro i r hi hn hs
  unfold bset.is_subset_loop.body at hs
  h5i_invert hs
  · obtain ⟨v', hv', heq⟩ := contains_sound _ _ (by simpa [hc_1] using hb1)
    have hvv : v' = v := (alloc.vec.Vec.eq_iff _ _).2 (by simpa [alloc.vec.Vec.deref] using heq)
    obtain ⟨hlt, hveq⟩ := slice_index_ok hv
    have hv2 : i2.val = i.val + 1 := by simpa using add_ok_val hi2
    refine ⟨?_, ?_, ?_⟩
    · intro k hk hka
      by_cases hki : k < i.val
      · exact hi k hki hka
      · have : k = i.val := by omega
        subst k; simpa [hveq, hvv] using hv'
    · simp only [id_eq]; omega
    · simp only [id_eq]; omega
  · simp
  · intro _ v hv
    obtain ⟨k, hk, rfl⟩ := List.mem_iff_getElem.1 hv
    exact hi k (by simp only [Slice.len] at hc; scalar_tac) hk

lemma get_iutf8_sound (e : Entry) (a : Slice U8) (s : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : entry_impl.get_ava_as_iutf8 e a = ok (some s)) :
    ava e (nats a.val) = some (.Iutf8 s) := by
  unfold entry_impl.get_ava_as_iutf8 at h
  h5i_invert h
  unfold valueset.as_iutf8_set at h
  h5i_invert h
  simp only [Option.some.injEq] at h
  subst s
  exact (get_ava_sound _ _ _ ho).symm

-- Relate the policy's UTF-8 literals to the explicit byte arrays in the kernel.
lemma byteArray_loop (b : ByteArray) (i : Nat) (acc : List UInt8) :
    ByteArray.toList.loop b i acc = acc.reverse ++ b.data.toList.drop i := by
  rw [ByteArray.toList.loop]
  split
  · rename_i hc
    have hlt : i < b.data.toList.length := by simpa only [Array.length_toList, ByteArray.size_data] using hc
    have hg : b.get! i = b.data.toList[i] := by
      cases b with
      | mk data =>
        have hd : i < data.size := hc
        simp only [ByteArray.get!, Array.getElem_toList]
        exact getElem!_pos data i hd
    rw [byteArray_loop b (i + 1) (b.get! i :: acc)]
    rw [List.drop_eq_getElem_cons hlt, List.reverse_cons, hg]
    simp [List.append_assoc]
  · rename_i hc
    have hle : b.data.toList.length ≤ i := by simp only [Array.length_toList, ByteArray.size_data]; omega
    simp [List.drop_eq_nil_of_le hle]
termination_by b.size - i

lemma byteArray_list (b : ByteArray) : b.toList = b.data.toList := by
  rw [ByteArray.toList, byteArray_loop]
  simp

lemma lit_bytes (s : String) :
    lit s = (s.toList.flatMap String.utf8EncodeChar).map (·.toNat) := by
  unfold lit
  rw [String.toUTF8_eq_toByteArray, ← String.utf8Encode_toList]
  simp only [List.utf8Encode, byteArray_list, List.toList_data_toByteArray]

lemma get_memberof_sound (i : Identity) (o : Option (alloc.vec.Vec U128))
    (hu : IsUser i) (h : identity_impl.get_memberof i = ok o) :
    memberof i = (o.map (·.val)).getD [] := by
  obtain ⟨u, hu⟩ := hu
  unfold identity_impl.get_memberof at h
  simp only [hu] at h
  h5i_invert h
  have hs' := result_ok_inj hs
  subst s
  unfold entry_impl.get_ava_refer at h
  h5i_invert h
  · have ho' := get_ava_sound _ _ _ ho_1
    have hlit : nats (Array.to_slice
        (Array.make 8#usize [109#u8, 101#u8, 109#u8, 98#u8, 101#u8, 114#u8, 111#u8, 102#u8])).val = lit "memberof" := by
      simp [Array.make, nats, lit_bytes, String.utf8EncodeChar]
    rw [hlit] at ho'
    simp [memberof, hu, refers, ← ho']
  · have ho' := get_ava_sound _ _ _ ho_1
    have hlit : nats (Array.to_slice
        (Array.make 8#usize [109#u8, 101#u8, 109#u8, 98#u8, 101#u8, 114#u8, 111#u8, 102#u8])).val = lit "memberof" := by
      simp [Array.make, nats, lit_bytes, String.utf8EncodeChar]
    rw [hlit] at ho'
    unfold valueset.as_refer_set at h
    h5i_invert h <;> simp [memberof, hu, refers, ← ho']

lemma push_sound {α : Type} (v : alloc.vec.Vec α) (x : α) (w : alloc.vec.Vec α)
    (h : alloc.vec.Vec.push v x = ok w) : w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  h5i_invert h
  simp [List.concat_eq_append]

lemma names_clone (v : alloc.vec.Vec (alloc.vec.Vec U8)) :
    alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) v = ok v :=
  vec_clone_eq _ _ u8vec_clone

lemma get_names_sound (e : Entry) (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : entry_impl.get_ava_names e = ok out) : out.val = e.attrs.val.map (·.attr) := by
  unfold entry_impl.get_ava_names entry_impl.get_ava_names_loop at h
  refine loop_idx_ok _ Prod.snd e.attrs.val.length
    (fun p => p.1.val ++ (e.attrs.val.drop p.2.val).map (·.attr) = e.attrs.val.map (·.attr))
    (fun out => out.val = e.attrs.val.map (·.attr)) ?_
    (_, 0#usize) out (by simp [alloc.vec.Vec.new]) (by simp) h
  rintro ⟨acc, i⟩ r hi hn hs
  unfold entry_impl.get_ava_names_loop.body at hs
  simp only [u8vec_clone] at hs
  h5i_invert hs
  · have hp := push_sound _ _ _ hout1
    obtain ⟨hlt, heq⟩ := vec_index_ok (by rwa [alloc.vec.Vec.index_slice_index] at ha)
    have hv : i2.val = i.val + 1 := by simpa using add_ok_val hi2
    refine ⟨?_, ?_, ?_⟩
    · simp only at hi ⊢
      rw [List.drop_eq_getElem_cons hlt, List.map_cons, heq] at hi
      simpa [hp, hv, List.append_assoc] using hi
    · simp only; omega
    · simp only; omega
  · have hle : e.attrs.val.length ≤ i.val := by
      simp only [alloc.vec.Vec.len] at hc; scalar_tac
    simpa [List.drop_eq_nil_of_le hle] using hi

def ConditionsOrigin (i : Identity) (p : profiles.AccessControlProfile)
    (rc : profiles.AccessControlReceiverCondition) (tc : profiles.AccessControlTargetCondition) : Prop :=
  (rc = .GroupChecked → ∃ gs, p.receiver = .Group gs ∧ ∃ g ∈ memberof i, g ∈ gs.val) ∧
  ∃ f fr, p.target = .Scope f ∧ tc = .Scope fr ∧ filter_impl.resolve f i = ok (some fr)

lemma resolve_conditions_sound (i : Identity) (imo : Option (alloc.vec.Vec U128))
    (p : profiles.AccessControlProfile) (rc : profiles.AccessControlReceiverCondition)
    (tc : profiles.AccessControlTargetCondition)
    (hm : memberof i = (imo.map (·.val)).getD [])
    (h : access.resolve_access_conditions i imo p.receiver p.target = ok (some (rc, tc))) :
    ConditionsOrigin i p rc tc := by
  unfold access.resolve_access_conditions at h
  h5i_invert h
  all_goals simp only [Option.some.injEq, Prod.mk.injEq] at h
  all_goals obtain ⟨rfl, rfl⟩ := h
  · refine ⟨?_, a_1, fi, hc_2, rfl, ho⟩
    intro _
    cases imo with
    | none => simp_all
    | some imo =>
      simp only at hgroup_check
      obtain ⟨g, hga, hgb⟩ := intersects_uuid_sound _ _ (by simpa [hc_1] using hgroup_check)
      exact ⟨a, hc, g, by simpa [hm, alloc.vec.Vec.deref, alloc.vec.Vec.val] using hga,
        by simpa [alloc.vec.Vec.deref, alloc.vec.Vec.val] using hgb⟩
  · exact ⟨by simp, a, fi, hc_1, rfl, ho⟩

-- Every resolved profile retains an original profile and its resolution evidence.
def ResolvedOrigin (ctl : AccessControlsInner) (i : Identity)
    (r : profiles.AccessControlCreateResolved) : Prop :=
  ∃ acc ∈ ctl.acps_create.val, r.attrs = acc.attrs ∧ r.classes = acc.classes ∧
    ConditionsOrigin i acc.acp r.receiver_condition r.target_condition

lemma related_sound (ctl : AccessControlsInner) (i : Identity)
    (out : alloc.vec.Vec profiles.AccessControlCreateResolved)
    (hu : IsUser i) (h : access.create_related_acp ctl i = ok out) :
    ∀ r ∈ out.val, ResolvedOrigin ctl i r := by
  unfold access.create_related_acp at h
  h5i_invert h
  have hm := get_memberof_sound _ _ hu hident_memberof
  unfold access.create_related_acp_loop at h
  refine loop_idx_ok _ Prod.snd ctl.acps_create.val.length
    (fun p => ∀ r ∈ p.1.val, ResolvedOrigin ctl i r)
    (fun out => ∀ r ∈ out.val, ResolvedOrigin ctl i r) ?_
    (_, 0#usize) out (by simp [alloc.vec.Vec.new]) (by simp) h
  rintro ⟨acc, idx⟩ res hi hn hs
  unfold access.create_related_acp_loop.body at hs
  simp only [names_clone] at hs
  h5i_invert hs
  · have hv : i2.val = idx.val + 1 := by simpa using add_ok_val hi2
    refine ⟨?_, ?_, ?_⟩
    · h5i_invert hrelated_acp1
      · exact hi
      · obtain ⟨rc, tc⟩ := p
        have hp := push_sound _ _ _ hrelated_acp1
        intro r hr
        rw [hp] at hr
        rcases List.mem_append.1 hr with hr | hr
        · exact hi r hr
        · have heq := List.mem_singleton.1 hr
          subst r
          exact ⟨acs, vec_index_slice_ok_mem hacs, rfl, rfl,
            resolve_conditions_sound _ _ _ _ _ hm ho⟩
    · simp only; omega
    · simp only [alloc.vec.Vec.len] at hc; simp only; scalar_tac
  · exact hi

lemma create_acp_sound (r : profiles.AccessControlCreateResolved) (e : Entry)
    (attrs cls : Slice (alloc.vec.Vec U8))
    (h : create_acc.create_acp_allows r e attrs cls = ok true) :
    r.receiver_condition = .GroupChecked ∧ search_acc.target_applies r.target_condition e = ok true ∧
    (∀ a ∈ attrs.val, a ∈ r.attrs.val) ∧ (∀ c ∈ cls.val, c ∈ r.classes.val) := by
  unfold create_acc.create_acp_allows at h
  h5i_invert h
  exact ⟨hc, by simpa [hc_1] using hb,
    by simpa [alloc.vec.Vec.deref] using subset_sound attrs r.attrs.deref (by simpa [hc_2] using hb1),
    by simpa [alloc.vec.Vec.deref] using subset_sound cls r.classes.deref (by simpa [hc_3] using hb2)⟩

lemma create_any_sound (rs : Slice profiles.AccessControlCreateResolved) (e : Entry)
    (attrs cls : Slice (alloc.vec.Vec U8))
    (h : create_acc.create_any_acp rs e attrs cls = ok true) :
    ∃ r ∈ rs.val, create_acc.create_acp_allows r e attrs cls = ok true := by
  unfold create_acc.create_any_acp create_acc.create_any_acp_loop at h
  refine loop_idx_ok _ id rs.val.length (fun _ => True)
    (fun b => b = true → ∃ r ∈ rs.val, create_acc.create_acp_allows r e attrs cls = ok true)
    ?_ 0#usize true trivial (by simp) h rfl
  intro idx res _ hn hs
  unfold create_acc.create_any_acp_loop.body at hs
  h5i_invert hs
  · intro _; exact ⟨accr, slice_index_ok_mem haccr, by simpa [hc_1] using hb⟩
  · have hv := add_ok_val hi2
    simp only [id_eq, Slice.len] at *
    exact ⟨trivial, by scalar_tac, by scalar_tac⟩
  · simp

lemma class_literal : nats (Array.to_slice
    (Array.make 5#usize [99#u8, 108#u8, 97#u8, 115#u8, 115#u8])).val = lit "class" := by
  simp [Array.make, nats, lit_bytes, String.utf8EncodeChar]

def ResolvedAllows (r : profiles.AccessControlCreateResolved) (e : Entry) : Prop :=
  r.receiver_condition = .GroupChecked ∧ search_acc.target_applies r.target_condition e = ok true ∧
    (∀ a ∈ e.attrs.val, a.attr ∈ r.attrs.val) ∧
    (∀ c ∈ classes e, c ∈ names r.classes.val)

lemma filter_grant_sound (i : Identity) (rs : Slice profiles.AccessControlCreateResolved) (e : Entry)
    (hu : IsUser i) (h : create_acc.create_filter_entry i rs e = ok .Grant) :
    ∃ r ∈ rs.val, ResolvedAllows r e := by
  obtain ⟨u, hu⟩ := hu
  unfold create_acc.create_filter_entry at h
  simp only [hu] at h
  h5i_invert h
  have hs' := result_ok_inj hs
  subst s
  obtain ⟨r, hr, ha⟩ := create_any_sound _ _ _ _ (by simpa [hc] using hallow)
  obtain ⟨hrc, ht, hattrs, hclasses⟩ := create_acp_sound _ _ _ _ ha
  refine ⟨r, hr, hrc, ht, ?_, ?_⟩
  · intro a ha
    apply hattrs a.attr
    simp only [alloc.vec.Vec.deref, Slice.from_val]
    rw [get_names_sound _ _ hcreate_attrs]
    exact List.mem_map.2 ⟨a, ha, rfl⟩
  · have hc := get_iutf8_sound _ _ _ ho
    rw [class_literal] at hc
    have hcls : classes e = names r_attrs.val := by simp [classes, hc]
    intro c hc'
    rw [hcls] at hc'
    obtain ⟨v, hv, rfl⟩ := List.mem_map.1 hc'
    apply List.mem_map.2
    exact ⟨v, hclasses v (by simpa [alloc.vec.Vec.deref] using hv), rfl⟩

lemma filter_user_cases (i : Identity) (rs : Slice profiles.AccessControlCreateResolved) (e : Entry)
    (r : create_acc.IResult) (hu : IsUser i) (h : create_acc.create_filter_entry i rs e = ok r) :
    r = .Deny ∨ r = .Grant ∨ r = .Ignore := by
  obtain ⟨u, hu⟩ := hu
  unfold create_acc.create_filter_entry at h
  simp only [hu] at h
  h5i_invert h <;> simp

-- A user's fallback allowance is empty; a grant comes from the profile check.
lemma apply_user_sound (i : Identity) (rs : Slice profiles.AccessControlCreateResolved) (e : Entry)
    (r : create_acc.CreateResult) (hu : IsUser i) (h : create_acc.apply_create_access i rs e = ok r) :
    (r = .Grant → create_acc.create_filter_entry i rs e = ok .Grant) ∧
    (∀ attrs cls, r = .Allow attrs cls → attrs.val = []) := by
  obtain ⟨u, hu'⟩ := hu
  unfold create_acc.apply_create_access at h
  simp only [create_acc.message_queue, create_acc.migration_filter_entry, hu',
    alloc.vec.Vec.len, alloc.vec.Vec.from_val, List.length_nil] at h
  simp only [show (Usize.ofNatCore 0 (by scalar_tac) != 0#usize) = false from rfl,
    Bool.false_eq_true, if_false] at h
  try dsimp at h
  h5i_invert h
  obtain ⟨cr, hfilter, h⟩ := bind_tc_eq_ok.1 h
  rcases filter_user_cases _ _ _ _ ⟨u, hu'⟩ hfilter with he | he | he
  all_goals subst cr
  all_goals simp only [bind_ok] at h
  · change ok create_acc.CreateResult.Deny = ok r at h
    have hr := result_ok_inj h
    subst r
    simp
  · change (if denied = true then ok create_acc.CreateResult.Deny
      else ok create_acc.CreateResult.Grant) = ok r at h
    split at h <;> have hr := result_ok_inj h <;> subst r <;> simp_all
  · change (if denied = true then ok create_acc.CreateResult.Deny
      else do
        let cls ← protected.remove_protected_mod_pres (alloc.vec.Vec.new (alloc.vec.Vec U8)).deref
        ok (create_acc.CreateResult.Allow (alloc.vec.Vec.new (alloc.vec.Vec U8)) cls)) = ok r at h
    split at h
    · have hr := result_ok_inj h
      subst r
      simp
    · obtain ⟨cls, hcls, hr⟩ := bind_tc_eq_ok.1 h
      have hr' := result_ok_inj hr
      subst r
      constructor
      · simp
      · intro attrs cls' heq
        simp only [create_acc.CreateResult.Allow.injEq] at heq
        rw [← heq.1]
        rfl

lemma allow_entry_sound (i : Identity) (rs : Slice profiles.AccessControlCreateResolved) (e : Entry)
    (hu : IsUser i) (h : access.create_allow_entry i rs e = ok true) :
    ∃ r ∈ rs.val, ResolvedAllows r e := by
  unfold access.create_allow_entry at h
  h5i_invert h
  · exact filter_grant_sound _ _ _ hu ((apply_user_sound _ _ _ _ hu hcr).1 rfl)
  · have hpres := (apply_user_sound _ _ _ _ hu hcr).2 a a_1 rfl
    h5i_invert hdecision
    have hsubset := subset_sound requested_pres.deref a.deref (by simpa [hc_1] using hb)
    have hnames := get_names_sound _ _ hrequested_pres
    have hempty : e.attrs.val = [] := by
      apply List.eq_nil_iff_forall_not_mem.2
      intro a ha
      have ha' : a.attr ∈ requested_pres.deref.val := by
        simp only [alloc.vec.Vec.deref, Slice.from_val, hnames]
        exact List.mem_map.2 ⟨a, ha, rfl⟩
      have hh := hsubset a.attr ha'
      simp [alloc.vec.Vec.deref, hpres] at hh
    have hc := get_iutf8_sound _ _ _ ho
    simp [ava, hempty] at hc

lemma all_entries_sound (i : Identity) (rs : Slice profiles.AccessControlCreateResolved)
    (es : Slice Entry) (hu : IsUser i) (h : access.create_all_entries i rs es = ok true) :
    ∀ e ∈ es.val, ∃ r ∈ rs.val, ResolvedAllows r e := by
  unfold access.create_all_entries access.create_all_entries_loop at h
  refine loop_idx_ok _ id es.val.length
    (fun idx => ∀ k, k < idx.val → ∀ hk : k < es.val.length,
      ∃ r ∈ rs.val, ResolvedAllows r es.val[k])
    (fun b => b = true → ∀ e ∈ es.val, ∃ r ∈ rs.val, ResolvedAllows r e)
    ?_ 0#usize true (by simp) (by simp) h rfl
  intro idx res hi hn hs
  unfold access.create_all_entries_loop.body at hs
  h5i_invert hs
  · have ha := allow_entry_sound _ _ _ hu (by simpa [hc_1] using hb)
    obtain ⟨hlt, heq⟩ := slice_index_ok he
    have hv : i2.val = idx.val + 1 := by simpa using add_ok_val hi2
    refine ⟨?_, ?_, ?_⟩
    · intro k hk hke
      by_cases hki : k < idx.val
      · exact hi k hki hke
      · have : k = idx.val := by omega
        subst k; simpa [heq] using ha
    · simp only [id_eq]; omega
    · simp only [id_eq]; omega
  · simp
  · intro _ e he
    obtain ⟨k, hk, rfl⟩ := List.mem_iff_getElem.1 he
    exact hi k (by simp only [Slice.len] at hc; scalar_tac) hk

theorem create_needs_profile (ctl : AccessControlsInner) (ce : CreateEvent) (es : Slice Entry) (e : Entry)
    (hu : IsUser ce.ident) (h : access.create_allow_operation ctl ce es = ok (.Ok true)) (he : e ∈ es.val) :
    ∃ acc ∈ ctl.acps_create.val,
      (∃ gs, acc.acp.receiver = .Group gs) ∧ Applies ce.ident acc.acp e ∧
      (∀ a ∈ e.attrs.val, a.attr ∈ acc.attrs.val) ∧ (∀ c ∈ classes e, c ∈ names acc.classes.val) := by
  unfold access.create_allow_operation at h
  h5i_invert h
  have horigin := related_sound _ _ _ hu hrelated_acp
  have hall := all_entries_sound _ _ _ hu hb
  obtain ⟨r, hr, hrc, ht, hattrs, hclasses⟩ := hall e he
  have hr' : r ∈ related_acp.val := by simpa [alloc.vec.Vec.deref] using hr
  obtain ⟨acc, hacc, hattrs_eq, hclasses_eq, hreceiver, htarget⟩ := horigin r hr'
  obtain ⟨gs, hgs, g, hgi, hggs⟩ := hreceiver hrc
  obtain ⟨f, fr, hfilter, hresolved, hresolve⟩ := htarget
  refine ⟨acc, hacc, ⟨gs, hgs⟩, ⟨?_, ?_⟩, ?_, ?_⟩
  · simp only [ReceiverHolds, hgs]
    exact ⟨g, hgi, hggs⟩
  · simp only [TargetHolds, hfilter]
    refine ⟨fr, hresolve, ?_⟩
    simpa [hresolved, search_acc.target_applies] using ht
  · simpa [hattrs_eq] using hattrs
  · simpa [hclasses_eq] using hclasses

end kanidm_kernel.Solution
