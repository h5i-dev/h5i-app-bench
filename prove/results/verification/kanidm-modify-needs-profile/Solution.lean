import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP

namespace kanidm_kernel.Solution

h5i_derive_clone profiles.ModifyGrants profiles.ModifyGrants.Insts.CoreCloneClone.clone

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    bset.bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold bset.bytes_eq
  dsimp only
  split
  · rename_i hn
    have hn' : a.val.length ≠ b.val.length := by simpa using hn
    simp only [spec_ok]
    have hneq : a.val ≠ b.val := fun h => hn' (congrArg List.length h)
    simp [hneq]
  · rename_i hn
    have hlen : a.val.length = b.val.length := by simpa using hn
    unfold bset.bytes_eq_loop
    apply loop_idx_spec _ id a.val.length
      (fun i => ∀ j < i.val, a.val[j]? = b.val[j]?) _ ?_ _ (by simp) (by simp)
    intro i hi hbound
    unfold bset.bytes_eq_loop.body
    step*
    · rename_i hlt heq
      refine ⟨?_, ?_, ?_⟩
      · intro k hk
        by_cases hki : k < i.val
        · exact hi k hki
        · have hkv : k = i.val := by omega
          subst k
          have hia : i.val < a.val.length := by scalar_tac
          have hib : i.val < b.val.length := by omega
          rw [List.getElem?_eq_getElem hia, List.getElem?_eq_getElem hib]
          congr 1
          scalar_tac
      · simp only [id_eq]; omega
      · simp only [id_eq]; scalar_tac
    · rename_i hend
      have heq : a.val = b.val := by
        apply List.ext_getElem?
        intro j
        by_cases hj : j < i.val
        · exact hi j hj
        · have ha : a.val.length ≤ j := by scalar_tac
          have hb : b.val.length ≤ j := by omega
          simp [List.getElem?_eq_none ha, List.getElem?_eq_none hb]
      simp [heq]

@[step] theorem contains_spec (s : Slice (alloc.vec.Vec U8)) (x : Slice U8) :
    bset.contains s x ⦃ r => r = s.val.any (fun v => decide (v.val = x.val)) ⦄ := by
  unfold bset.contains bset.contains_loop
  h5i_search_any s.val (fun v => decide (v.val = x.val))
  all_goals simp_all [alloc.vec.Vec.deref]
  all_goals scalar_tac

@[step] theorem contains_uuid_spec (s : Slice U128) (u : U128) :
    bset.contains_uuid s u ⦃ r => r = decide (u ∈ s.val) ⦄ := by
  unfold bset.contains_uuid bset.contains_uuid_loop
  h5i_search_any s.val (fun v => decide (v = u))
  rename_i hr
  rw [← hr]
  apply Bool.eq_iff_iff.mpr
  simp only [List.any_eq_true, decide_eq_true_eq]
  exact ⟨fun ⟨v, hv, he⟩ => he ▸ hv, fun hu => ⟨u, hu, rfl⟩⟩

@[step] theorem intersects_uuid_spec (a b : Slice U128) :
    bset.intersects_uuid a b ⦃ r => r = decide (∃ u ∈ a.val, u ∈ b.val) ⦄ := by
  unfold bset.intersects_uuid bset.intersects_uuid_loop
  h5i_search_any a.val (fun u => decide (u ∈ b.val))
  rename_i hr
  rw [← hr]
  apply Bool.eq_iff_iff.mpr
  simp [List.any_eq_true]

@[step] theorem get_ava_spec (e : Entry) (a : Slice U8) :
    entry_impl.get_ava_set e a ⦃ r => r = (e.attrs.val.find? (fun p => decide (p.attr.val = a.val))).map (·.vs) ⦄ := by
  unfold entry_impl.get_ava_set entry_impl.get_ava_set_loop
  apply spec_mono (loop_search e.attrs.val (fun p => decide (p.attr.val = a.val)) id
    (fun _ p => some p.vs) none _ ?_ 0#usize (by simp))
  · intro r hr
    simpa [searchFrom_find] using hr
  · intro i hi
    unfold entry_impl.get_ava_set_loop.body
    h5i_step [alloc.vec.Vec.deref]
    all_goals scalar_tac

theorem nats_injective : Function.Injective nats := by
  intro xs ys h
  induction xs generalizing ys with
  | nil => cases ys <;> simp_all [nats]
  | cons x xs ih =>
    cases ys with
    | nil => simp [nats] at h
    | cons y ys =>
      have hh : x.val = y.val ∧ nats xs = nats ys := by simpa [nats] using h
      rw [(u8_eq_iff x y).mpr hh.1, ih hh.2]

@[simp] theorem nats_eq_iff (xs ys : List U8) : nats xs = nats ys ↔ xs = ys :=
  nats_injective.eq_iff

@[simp] theorem nats_beq (xs ys : List U8) :
    (nats xs == nats ys) = decide (xs = ys) := by
  apply Bool.eq_iff_iff.mpr
  simp only [beq_iff_eq, decide_eq_true_eq, nats_eq_iff]

theorem contains_names {s : Slice (alloc.vec.Vec U8)} {x : Slice U8}
    (h : bset.contains s x = ok true) : nats x.val ∈ names s.val := by
  have hs := (post_of_ok (contains_spec s x) h).symm
  simp only [List.any_eq_true, decide_eq_true_eq] at hs
  obtain ⟨v, hv, he⟩ := hs
  exact List.mem_map.mpr ⟨v, hv, by simp [he]⟩

@[step] theorem refer_spec (e : Entry) (a : Slice U8) :
    entry_impl.get_ava_refer e a ⦃ r => r.map (·.val) =
      match ava e (nats a.val) with | some (.Refer s) => some s.val | _ => none ⦄ := by
  unfold entry_impl.get_ava_refer
  apply spec_bind (get_ava_spec e a)
  intro o ho
  have hva : ava e (nats a.val) = o := by simpa only [ava, nats_beq] using ho.symm
  rw [hva]
  cases o with
  | none => simp
  | some vs => cases vs <;> simp [valueset.as_refer_set]

theorem lit_memberof : lit "memberof" = [109,101,109,98,101,114,111,102] := by
  unfold lit
  decide +kernel

theorem lit_manager : lit "entry_managed_by" = [101,110,116,114,121,95,109,97,110,97,103,101,100,95,98,121] := by
  unfold lit
  decide +kernel

@[step] theorem memberof_spec (i : Identity) :
    identity_impl.get_memberof i ⦃ r => (r.map (·.val)).getD [] = memberof i ⦄ := by
  unfold identity_impl.get_memberof
  cases ho : i.origin <;> step*
  all_goals simp_all [memberof, refers, lit_memberof, nats]
  all_goals rfl

theorem push_val {α} {v w : alloc.vec.Vec α} {x : α}
    (h : alloc.vec.Vec.push v x = ok w) : w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  h5i_invert h
  simp [List.concat_eq_append]

theorem insert_mem {s t : alloc.vec.Vec (alloc.vec.Vec U8)} {x : Slice U8}
    (h : bset.insert s x = ok t) (a : List Nat) :
    a ∈ names t.val ↔ a ∈ names s.val ∨ a = nats x.val := by
  unfold bset.insert at h
  h5i_invert h
  · have hx := contains_names (by simpa only [hc] using hb)
    simp only [vec_deref_val] at hx
    constructor
    · exact Or.inl
    · rintro (ha | rfl) <;> assumption
  · have hv := post_of_ok (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 x (by intros; rfl)) hv
    have hp := push_val h
    rw [hp]
    have hev : v.val = x.val := by exact congrArg Slice.val hv.symm
    simp [names, hev]

theorem extend_valid {s t : alloc.vec.Vec (alloc.vec.Vec U8)} {xs : Slice (alloc.vec.Vec U8)}
    (P : List Nat → Prop) (hs : ∀ a ∈ names s.val, P a) (hx : ∀ a ∈ names xs.val, P a)
    (h : bset.extend s xs = ok t) : ∀ a ∈ names t.val, P a := by
  unfold bset.extend bset.extend_loop at h
  refine loop_idx_ok _ (·.2) xs.val.length
    (fun st => ∀ a ∈ names st.1.val, P a) (fun t => ∀ a ∈ names t.val, P a)
    ?_ (s, 0#usize) t hs (by simp) h
  rintro ⟨s, i⟩ r hs hi hr
  unfold bset.extend_loop.body at hr
  h5i_invert hr
  · refine ⟨?_, ?_, ?_⟩
    · intro a ha
      rcases (insert_mem hset1 a).mp ha with ha | rfl
      · exact hs a ha
      · apply hx
        exact List.mem_map.mpr ⟨v, slice_index_ok_mem hv, by simp [alloc.vec.Vec.deref]⟩
    · dsimp only; h5i_arith
    · dsimp only; h5i_arith
  · exact hs

theorem intersection_valid {xs ys : Slice (alloc.vec.Vec U8)} {t : alloc.vec.Vec (alloc.vec.Vec U8)}
    (P : List Nat → Prop) (hy : ∀ a ∈ names ys.val, P a)
    (h : bset.intersection xs ys = ok t) : ∀ a ∈ names t.val, P a := by
  unfold bset.intersection bset.intersection_loop at h
  refine loop_idx_ok _ (·.2) xs.val.length
    (fun st => ∀ a ∈ names st.1.val, P a) (fun t => ∀ a ∈ names t.val, P a)
    ?_ (_, 0#usize) t (by simp [names, vec_new_val]) (by simp) h
  rintro ⟨s, i⟩ r hs hi hr
  unfold bset.intersection_loop.body at hr
  simp only [u8vec_clone] at hr
  h5i_invert hr
  · h5i_invert hout1
    · refine ⟨?_, ?_, ?_⟩
      · intro a ha
        rcases (insert_mem hout1 a).mp ha with ha | rfl
        · exact hs a ha
        · exact hy _ (contains_names (by simpa only [hc_1] using hb1))
      · dsimp only; h5i_arith
      · dsimp only; h5i_arith
    · refine ⟨hs, ?_, ?_⟩ <;> dsimp only <;> h5i_arith
  · exact hs

theorem subset_names {xs ys : Slice (alloc.vec.Vec U8)}
    (h : bset.is_subset xs ys = ok true) : ∀ a ∈ names xs.val, a ∈ names ys.val := by
  unfold bset.is_subset bset.is_subset_loop at h
  have hh := loop_idx_ok _ id xs.val.length
    (fun i => ∀ j < i.val, ∀ v, xs.val[j]? = some v → nats v.val ∈ names ys.val)
    (fun b => b = true → ∀ a ∈ names xs.val, a ∈ names ys.val)
    ?_ 0#usize true (by simp) (by simp) h
  · exact hh rfl
  · intro i r hinv hi hr
    unfold bset.is_subset_loop.body at hr
    h5i_invert hr
    · refine ⟨?_, ?_, ?_⟩
      · intro j hj w hw
        have hadd := add_ok_val hi2
        have hj' : j < i.val ∨ j = i.val := by scalar_tac
        rcases hj' with hj' | rfl
        · exact hinv j hj' w hw
        · have hv' := slice_index_ok (h := hv)
          obtain ⟨hlt, heq⟩ := hv'
          have he : v = w := by simpa [List.getElem?_eq_getElem hlt, heq] using hw
          subst w
          have hh := contains_names (by simpa only [hc_1] using hb1)
          simpa only [vec_deref_val] using hh
      · simp only [id_eq]; h5i_arith
      · simp only [id_eq]; h5i_arith
    · simp
    · intro _ a ha
      obtain ⟨v, hv, rfl⟩ := List.mem_map.mp ha
      obtain ⟨j, hj, he⟩ := List.mem_iff_getElem.mp hv
      apply hinv j (by scalar_tac) v
      simp [List.getElem?_eq_getElem hj, he]

theorem requested_mem {ms : Slice Modify} {t : alloc.vec.Vec (alloc.vec.Vec U8)}
    (h : access.requested_pres ms = ok t) {m : Modify} {a : List Nat}
    (hm : m ∈ ms.val) (ha : presAttr m = some a) : a ∈ names t.val := by
  unfold access.requested_pres access.requested_pres_loop at h
  have hh := loop_idx_ok _ (·.2) ms.val.length
    (fun st => ∀ j < st.2.val, ∀ a, (ms.val[j]?).bind presAttr = some a → a ∈ names st.1.val)
    (fun t => ∀ j : Nat, ∀ a, (ms.val[j]?).bind presAttr = some a → a ∈ names t.val)
    ?_ (_, 0#usize) t (by simp) (by simp) h
  · obtain ⟨j, hj, he⟩ := List.mem_iff_getElem.mp hm
    apply hh j a
    simp [List.getElem?_eq_getElem hj, he, ha]
  · rintro ⟨s, i⟩ r hinv hi hr
    unfold access.requested_pres_loop.body at hr
    h5i_invert hr
    all_goals try (h5i_invert hout1)
    all_goals try
      intro j a hj
      have hj' : j < i.val := by
        by_contra hn
        have hnone : ms.val[j]? = none := List.getElem?_eq_none (by scalar_tac)
        simp [hnone] at hj
      exact hinv j hj' a hj
    all_goals refine ⟨?_, ?_, ?_⟩
    all_goals try (dsimp only; h5i_arith)
    all_goals intro j hj a ha
    all_goals have hadd := add_ok_val hi2
    all_goals have hj' : j < i.val ∨ j = i.val := by scalar_tac
    all_goals rcases hj' with hj' | rfl
    all_goals try (exact (insert_mem hout1 a).mpr (Or.inl (hinv j hj' a ha)))
    all_goals try (exact hinv j hj' a ha)
    all_goals have hmi := slice_index_ok hm_1
    all_goals obtain ⟨hmi_lt, hmi_eq⟩ := hmi
    all_goals rw [List.getElem?_eq_getElem hmi_lt, hmi_eq] at ha
    all_goals simp_all [presAttr]
    all_goals exact (insert_mem hout1 a).mpr (Or.inr (by simpa only [vec_deref_val] using ha.symm))

theorem manager_sound (i : Identity) (e : Entry) (imo : Option (alloc.vec.Vec U128)) (uid : U128)
    (hu : IsUser i) (hmo : identity_impl.get_memberof i = ok imo)
    (huid : identity_impl.get_uuid i = ok uid)
    (h : search_acc.receiver_applies .EntryManager imo uid e = ok true) :
    ReceiverHolds i .EntryManager e := by
  obtain ⟨u, ho⟩ := hu
  have hmem := post_of_ok (memberof_spec i) hmo
  have hid : u.entry.uuid = uid := by simpa [identity_impl.get_uuid, ho] using huid
  unfold search_acc.receiver_applies at h
  h5i_invert h
  all_goals have href := post_of_ok (refer_spec e s) ho_1
  all_goals simp only [lift, ok.injEq] at hs
  all_goals
    have hl : nats s.val = lit "entry_managed_by" := by rw [← hs, lit_manager]; simp [nats]
    have hrefer : refers e "entry_managed_by" = some imo_1.val := by
      unfold refers
      rw [← hl]
      cases hv : ava e (nats s.val) with
      | none => simp [hv] at href
      | some vs => cases vs <;> simp_all
    refine ⟨imo_1.val, hrefer, ?_⟩
  · right
    simp only [hc] at hgroup_check
    h5i_invert hgroup_check
    have hh := (post_of_ok (intersects_uuid_spec _ _) hgroup_check).symm
    simp only [decide_eq_true_eq, vec_deref_val] at hh
    obtain ⟨g, hg, hgs⟩ := hh
    exact ⟨g, by simpa [← hmem] using hg, hgs⟩
  · left
    have hh := (post_of_ok (contains_uuid_spec _ _) huser_check).symm
    simp only [decide_eq_true_eq, vec_deref_val] at hh
    exact ⟨u, ho, by simpa [hid] using hh⟩

theorem conditions_sound (i : Identity) (p : profiles.AccessControlProfile)
    (imo : Option (alloc.vec.Vec U128)) (uid : U128) (e : Entry)
    (rc : profiles.AccessControlReceiverCondition) (tc : profiles.AccessControlTargetCondition)
    (hu : IsUser i) (hmo : identity_impl.get_memberof i = ok imo)
    (huid : identity_impl.get_uuid i = ok uid)
    (hr : access.resolve_access_conditions i imo p.receiver p.target = ok (some (rc, tc)))
    (ht : search_acc.acp_applies rc tc imo uid e = ok true) : Applies i p e := by
  have hmem := post_of_ok (memberof_spec i) hmo
  unfold access.resolve_access_conditions at hr
  h5i_invert hr
  all_goals simp only [Option.some.injEq, Prod.mk.injEq] at hr
  all_goals obtain ⟨rfl, rfl⟩ := hr
  all_goals unfold search_acc.acp_applies search_acc.target_applies at ht
  all_goals h5i_invert ht
  · refine ⟨?_, ?_⟩
    · simp only [Applies, ReceiverHolds, hc]
      simp only [hc_1] at hgroup_check
      h5i_invert hgroup_check
      have hh := (post_of_ok (intersects_uuid_spec _ _) hgroup_check).symm
      simp only [decide_eq_true_eq, vec_deref_val] at hh
      obtain ⟨g, hg, hgs⟩ := hh
      exact ⟨g, by simpa [← hmem] using hg, hgs⟩
    · simp only [TargetHolds, hc_2]
      exact ⟨fi, ho, ht⟩
  · refine ⟨?_, ?_⟩
    · simp only [ReceiverHolds, hc]
      exact manager_sound i e imo uid hu hmo huid (by simpa only [hc_2] using hb)
    · simp only [TargetHolds, hc_1]
      exact ⟨fi, ho, ht⟩

@[simp] theorem attrs_clone (v : alloc.vec.Vec (alloc.vec.Vec U8)) :
    alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) v = ok v :=
  vec_clone_ok _ v (fun x => u8vec_clone x)

def Related (ctl : AccessControlsInner) (i : Identity) (q : profiles.AccessControlModifyResolved) : Prop :=
  ∃ p ∈ ctl.acps_modify.val, q.acp.presattrs = p.presattrs ∧
    ∃ imo, identity_impl.get_memberof i = ok imo ∧
      access.resolve_access_conditions i imo p.acp.receiver p.acp.target =
        ok (some (q.receiver_condition, q.target_condition))

theorem related_valid (ctl : AccessControlsInner) (i : Identity)
    (r : alloc.vec.Vec profiles.AccessControlModifyResolved)
    (h : access.modify_related_acp ctl i = ok r) : ∀ q ∈ r.val, Related ctl i q := by
  unfold access.modify_related_acp at h
  obtain ⟨imo, hmo, h⟩ := bind_tc_eq_ok.mp h
  unfold access.modify_related_acp_loop at h
  refine loop_idx_ok _ (·.2) ctl.acps_modify.val.length
    (fun st => ∀ q ∈ st.1.val, Related ctl i q) (fun r => ∀ q ∈ r.val, Related ctl i q)
    ?_ (_, 0#usize) r (by simp [vec_new_val]) (by simp) h
  rintro ⟨rs, j⟩ cf hinv hj hc
  unfold access.modify_related_acp_loop.body at hc
  h5i_invert hc
  · simp only [attrs_clone] at hrelated_acp1
    h5i_invert hrelated_acp1
    · refine ⟨hinv, ?_, ?_⟩ <;> dsimp only <;> h5i_arith
    · refine ⟨?_, ?_, ?_⟩
      · intro q hq
        rw [push_val hrelated_acp1] at hq
        simp only [List.mem_append, List.mem_singleton] at hq
        rcases hq with hq | rfl
        · exact hinv q hq
        · exact ⟨acs, vec_index_slice_ok_mem hacs, rfl, imo, hmo, ho⟩
      · dsimp only; h5i_arith
      · dsimp only; h5i_arith
  · exact hinv

def Scoped (rs : Slice profiles.AccessControlModifyResolved)
    (imo : Option (alloc.vec.Vec U128)) (uid : U128) (e : Entry) (g : profiles.ModifyGrants) : Prop :=
  ∃ q ∈ rs.val, g = q.acp ∧ search_acc.acp_applies q.receiver_condition q.target_condition imo uid e = ok true

theorem scoped_valid (rs : Slice profiles.AccessControlModifyResolved)
    (imo : Option (alloc.vec.Vec U128)) (uid : U128) (e : Entry)
    (ss : alloc.vec.Vec profiles.ModifyGrants)
    (h : modify_acc.modify_scoped_acp rs imo uid e = ok ss) : ∀ g ∈ ss.val, Scoped rs imo uid e g := by
  unfold modify_acc.modify_scoped_acp modify_acc.modify_scoped_acp_loop at h
  refine loop_idx_ok _ (·.2) rs.val.length
    (fun st => ∀ g ∈ st.1.val, Scoped rs imo uid e g) (fun ss => ∀ g ∈ ss.val, Scoped rs imo uid e g)
    ?_ (_, 0#usize) ss (by simp [vec_new_val]) (by simp) h
  rintro ⟨ss, j⟩ cf hinv hj hc
  unfold modify_acc.modify_scoped_acp_loop.body at hc
  h5i_invert hc
  · unfold modify_acc.push_if at hscoped_acp1
    simp only [profiles.ModifyGrants.Insts.CoreCloneClone.clone.ok_eq] at hscoped_acp1
    h5i_invert hscoped_acp1
    · refine ⟨?_, ?_, ?_⟩
      · intro g hg
        rw [push_val hscoped_acp1] at hg
        simp only [List.mem_append, List.mem_singleton] at hg
        rcases hg with hg | rfl
        · exact hinv g hg
        · exact ⟨acm, slice_index_ok_mem hacm, rfl, by simpa only [‹ok1 = true›] using hok1⟩
      · dsimp only; h5i_arith
      · dsimp only; h5i_arith
    · refine ⟨hinv, ?_, ?_⟩ <;> dsimp only <;> h5i_arith
  · exact hinv

theorem pres_loop_valid (ss : Slice profiles.ModifyGrants) (P : List Nat → Prop)
    (hss : ∀ g ∈ ss.val, ∀ a ∈ names g.presattrs.val, P a)
    (p r pc rc : alloc.vec.Vec (alloc.vec.Vec U8)) (j : Usize)
    (hp : ∀ a ∈ names p.val, P a) (hj : j.val ≤ ss.val.length)
    (out : alloc.vec.Vec (alloc.vec.Vec U8) × alloc.vec.Vec (alloc.vec.Vec U8) ×
      alloc.vec.Vec (alloc.vec.Vec U8) × alloc.vec.Vec (alloc.vec.Vec U8))
    (h : modify_acc.modify_pres_test_loop ss p r pc rc j = ok out) : ∀ a ∈ names out.1.val, P a := by
  unfold modify_acc.modify_pres_test_loop at h
  refine loop_idx_ok _ (fun st => st.2.2.2.2) ss.val.length
    (fun st => ∀ a ∈ names st.1.val, P a) (fun out => ∀ a ∈ names out.1.val, P a)
    ?_ (p, r, pc, rc, j) out hp hj h
  rintro ⟨p, r, pc, rc, j⟩ cf hinv hj hc
  unfold modify_acc.modify_pres_test_loop.body at hc
  h5i_invert hc
  · refine ⟨?_, ?_, ?_⟩
    · exact extend_valid P hinv (by simpa only [vec_deref_val] using hss mg (slice_index_ok_mem hmg)) hpres_attr1
    · dsimp only; h5i_arith
    · dsimp only; h5i_arith
  · exact hinv

theorem pres_test_valid (ss : Slice profiles.ModifyGrants) (P : List Nat → Prop)
    (hss : ∀ g ∈ ss.val, ∀ a ∈ names g.presattrs.val, P a) (out : AccessModResult)
    (h : modify_acc.modify_pres_test ss = ok out) :
    ∃ p r pc rc, out = .Allow p r pc rc ∧ ∀ a ∈ names p.val, P a := by
  unfold modify_acc.modify_pres_test at h
  h5i_invert h
  obtain ⟨p, r, pc, rc⟩ := x
  try dsimp only at h
  have he := result_ok_inj h
  subst out
  exact ⟨p, r, pc, rc, rfl, pres_loop_valid ss P hss _ _ _ _ _ (by simp [names]) (by simp) _ hx⟩

def Policy (ctl : AccessControlsInner) (i : Identity) (e : Entry) (a : List Nat) : Prop :=
  ∃ p ∈ ctl.acps_modify.val, a ∈ names p.presattrs.val ∧ Applies i p.acp e

theorem scoped_policy (ctl : AccessControlsInner) (i : Identity) (e : Entry)
    (rs : Slice profiles.AccessControlModifyResolved) (imo : Option (alloc.vec.Vec U128)) (uid : U128)
    (hu : IsUser i) (hmo : identity_impl.get_memberof i = ok imo) (huid : identity_impl.get_uuid i = ok uid)
    (hrel : ∀ q ∈ rs.val, Related ctl i q) (ss : alloc.vec.Vec profiles.ModifyGrants)
    (hss : modify_acc.modify_scoped_acp rs imo uid e = ok ss) :
    ∀ g ∈ ss.val, ∀ a ∈ names g.presattrs.val, Policy ctl i e a := by
  intro g hg a ha
  obtain ⟨q, hq, rfl, happ⟩ := scoped_valid rs imo uid e ss hss g hg
  obtain ⟨p, hp, heq, imo', hmo', hr⟩ := hrel q hq
  have he : imo' = imo := result_ok_inj (hmo'.symm.trans hmo)
  subst imo'
  exact ⟨p, hp, heq ▸ ha, conditions_sound i p.acp imo uid e q.receiver_condition q.target_condition hu hmo huid hr happ⟩

def UserResultValid (ctl : AccessControlsInner) (i : Identity) (e : Entry) : modify_acc.ModifyResult → Prop
  | .Deny => True
  | .Grant => False
  | .Allow p _ _ _ => ∀ a ∈ names p.val, Policy ctl i e a

theorem apply_policy (ctl : AccessControlsInner) (i : Identity) (e : Entry)
    (rs : Slice profiles.AccessControlModifyResolved) (sa : Slice SyncAgreement)
    (hu : IsUser i) (hrel : ∀ q ∈ rs.val, Related ctl i q) (out : modify_acc.ModifyResult)
    (h : modify_acc.apply_modify_access i rs sa e = ok out) : UserResultValid ctl i e out := by
  obtain ⟨u, ho⟩ := hu
  unfold modify_acc.apply_modify_access at h
  simp only [modify_acc.modify_ident_test, identity_impl.access_scope, modify_acc.modify_migration_attrs, ho] at h
  cases hs : i.scope
  all_goals simp only [hs, bind_tc_ok, bind_ok] at h
  all_goals try dsimp only at h
  all_goals h5i_invert h
  all_goals simp! only [bind_tc_ok, bind_ok] at h
  all_goals h5i_invert h
  all_goals rcases x with ⟨denied2, cp, cr, cpc, crc⟩
  all_goals simp! only [bind_tc_ok, bind_ok] at h
  all_goals h5i_invert h
  all_goals rcases x with ⟨denied3, cp1, ap, cr1, ar, apc, arc⟩
  all_goals simp! only [bind_tc_ok, bind_ok] at h
  all_goals h5i_invert h
  all_goals try trivial
  all_goals h5i_invert hx_1
  all_goals try (rcases hx_1 with ⟨hd, hcp, hap, hcr, har, hapc, harc⟩; simp_all)
  all_goals rcases x with ⟨denied4, cp2, cr2⟩
  all_goals simp! only [bind_tc_ok, bind_ok] at hx_1
  all_goals h5i_invert hx_1
  all_goals have hpol := scoped_policy ctl i e rs ident_memberof ident_uuid ⟨u, ho⟩ hident_memberof hident_uuid hrel scoped_acp hscoped_acp
  all_goals have hpres := pres_test_valid scoped_acp.deref (Policy ctl i e) (by simpa only [vec_deref_val] using hpol) amr3 hamr3
  all_goals obtain ⟨pres, rem, presc, remc, rfl, hp⟩ := hpres
  all_goals h5i_invert hx_3
  all_goals simp! only [bind_tc_ok, bind_ok] at hx_1
  all_goals h5i_invert hx_1
  all_goals obtain ⟨hd, hcp, hap, hcr, har, hapc, harc⟩ := hx_1
  all_goals have hAp := extend_valid (Policy ctl i e) (by simp [names]) (by simpa only [vec_deref_val] using hp) hallow_pres2
  all_goals rw [← hap] at hallowed_pres
  all_goals change ∀ a ∈ names allowed_pres.val, Policy ctl i e a
  all_goals h5i_invert hallowed_pres
  all_goals try (exact intersection_valid (Policy ctl i e) (by simpa only [vec_deref_val] using hAp) hallowed_pres)
  all_goals exact hallowed_pres ▸ hAp

theorem per_entry_policy (ctl : AccessControlsInner) (i : Identity) (e : Entry)
    (rs : Slice profiles.AccessControlModifyResolved) (ms : Slice Modify)
    (hu : IsUser i) (hrel : ∀ q ∈ rs.val, Related ctl i q)
    (h : access.modify_allow_operation_per_entry ctl i rs e ms = ok true)
    (m : Modify) (a : List Nat) (hm : m ∈ ms.val) (ha : presAttr m = some a) : Policy ctl i e a := by
  unfold access.modify_allow_operation_per_entry at h
  h5i_invert h
  all_goals rcases p with ⟨pc, rc⟩
  all_goals simp! only [bind_tc_ok, bind_ok] at h
  all_goals h5i_invert h
  all_goals have hv := apply_policy ctl i e rs _ hu hrel _ hmr
  all_goals simp only [UserResultValid] at hv
  all_goals try contradiction
  all_goals h5i_invert hdecision2
  all_goals h5i_invert hdecision1
  all_goals h5i_invert hdecision
  all_goals have hsub := subset_names (by simpa only [‹b = true›] using hb)
  all_goals simp only [vec_deref_val] at hsub
  all_goals apply hv a
  all_goals apply hsub a
  all_goals simpa only [vec_deref_val] using requested_mem hrequested_pres hm ha

theorem all_entries_pass (ctl : AccessControlsInner) (i : Identity)
    (rs : Slice profiles.AccessControlModifyResolved) (es : Slice Entry) (ms : Slice Modify)
    (h : access.modify_all_entries ctl i rs es ms = ok true) :
    ∀ e ∈ es.val, access.modify_allow_operation_per_entry ctl i rs e ms = ok true := by
  unfold access.modify_all_entries access.modify_all_entries_loop at h
  have hh := loop_idx_ok _ id es.val.length
    (fun j => ∀ k < j.val, ∀ e, es.val[k]? = some e → access.modify_allow_operation_per_entry ctl i rs e ms = ok true)
    (fun b => b = true → ∀ e ∈ es.val, access.modify_allow_operation_per_entry ctl i rs e ms = ok true)
    ?_ 0#usize true (by simp) (by simp) h
  · exact hh rfl
  · intro j cf hinv hj hc
    unfold access.modify_all_entries_loop.body at hc
    h5i_invert hc
    · refine ⟨?_, ?_, ?_⟩
      · intro k hk en hen
        have hadd := add_ok_val hi2
        have hk' : k < j.val ∨ k = j.val := by scalar_tac
        rcases hk' with hk' | rfl
        · exact hinv k hk' en hen
        · obtain ⟨hlt, heq⟩ := slice_index_ok he
          have heqn : e = en := by simpa [List.getElem?_eq_getElem hlt, heq] using hen
          subst en
          simpa only [‹b = true›] using hb
      · simp only [id_eq]; h5i_arith
      · simp only [id_eq]; h5i_arith
    · simp
    · intro _ e he
      obtain ⟨k, hk, heq⟩ := List.mem_iff_getElem.mp he
      apply hinv k (by scalar_tac) e
      simp [List.getElem?_eq_getElem hk, heq]

theorem modify_needs_profile (ctl : AccessControlsInner) (me : ModifyEvent) (es : Slice Entry) (e : Entry)
    (m : Modify) (a : List Nat)
    (hu : IsUser me.ident) (h : access.modify_allow_operation ctl me es = ok (.Ok true))
    (he : e ∈ es.val) (hm : m ∈ me.modlist.val) (ha : presAttr m = some a) :
    ∃ acm ∈ ctl.acps_modify.val, a ∈ names acm.presattrs.val ∧ Applies me.ident acm.acp e := by
  unfold access.modify_allow_operation at h
  h5i_invert h
  have hrel := related_valid ctl me.ident related_acp hrelated_acp
  have hpass := all_entries_pass ctl me.ident related_acp.deref es me.modlist.deref hb
  apply per_entry_policy ctl me.ident e related_acp.deref me.modlist.deref hu
    (by simpa only [vec_deref_val] using hrel) (hpass e he) m a
  · simpa only [vec_deref_val] using hm
  · exact ha

end kanidm_kernel.Solution
