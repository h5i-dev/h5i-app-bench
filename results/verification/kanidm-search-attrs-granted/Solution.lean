import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP

h5i_derive_all

namespace kanidm_kernel.Solution

macro "literal_bytes" : tactic => `(tactic| (
  simp [lit, ← String.utf8Encode_toList, List.utf8Encode, String.utf8EncodeChar]
  decide +kernel))

@[step] theorem bytes_loop_spec (a b : Slice U8) (i : Usize)
    (hlen : a.val.length = b.val.length) (hi : i.val ≤ a.val.length) :
    bset.bytes_eq_loop a b i ⦃ r => r = decide (a.val.drop i.val = b.val.drop i.val) ⦄ := by
  h5i_measure_induction (a.val.length - i.val) with ih
  unfold bset.bytes_eq_loop
  rw [loop]
  unfold bset.bytes_eq_loop.body
  step*; split
  · rename_i hlt
    step*
    split
    · rename_i hne
      h5i_simp
      have hn : a.val.drop i.val ≠ b.val.drop i.val := by
        intro he
        rw [List.drop_eq_getElem_cons (l := a.val) (i := i.val) (by scalar_tac),
          List.drop_eq_getElem_cons (l := b.val) (i := i.val) (by scalar_tac)] at he
        simp only [List.cons.injEq] at he
        simp_all
      simp [hn]
    · rename_i heq
      step*
      have hj : i.val + 1 ≤ a.val.length := by scalar_tac
      change bset.bytes_eq_loop a b _ ⦃ r => r = decide (a.val.drop i.val = b.val.drop i.val) ⦄
      step with ih _ (by scalar_tac) a b x hlen (by scalar_tac) rfl
      rw [List.drop_eq_getElem_cons (l := a.val) (i := i.val) (by scalar_tac),
        List.drop_eq_getElem_cons (l := b.val) (i := i.val) (by scalar_tac)]
      simp only [List.cons.injEq]
      rw [r_post, x_post]
      congr 1
      apply propext
      exact ⟨fun ht => ⟨by scalar_tac, ht⟩, And.right⟩
  · h5i_simp
    rw [List.drop_eq_nil_of_le (by scalar_tac), List.drop_eq_nil_of_le (by scalar_tac)]
    rfl

@[step] theorem bytes_spec (a b : Slice U8) :
    bset.bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold bset.bytes_eq
  dsimp only
  split
  · rename_i hn
    h5i_simp
    have : a.val ≠ b.val := by intro he; simp_all
    simp [this]
  · step*; simp_all

@[step] theorem contains_uuid_spec (s : Slice U128) (u : U128) :
    bset.contains_uuid s u ⦃ r => r = decide (u ∈ s.val) ⦄ := by
  unfold bset.contains_uuid bset.contains_uuid_loop
  h5i_search_any s.val (fun x => decide (x = u))
  rename_i hr
  rw [← hr]
  apply Bool.eq_iff_iff.mpr
  simp

@[step] theorem intersects_uuid_spec (a b : Slice U128) :
    bset.intersects_uuid a b ⦃ r => r = decide (∃ u ∈ a.val, u ∈ b.val) ⦄ := by
  unfold bset.intersects_uuid bset.intersects_uuid_loop
  h5i_search_any a.val (fun x => decide (x ∈ b.val))
  rename_i hr
  rw [← hr]
  apply Bool.eq_iff_iff.mpr
  simp

@[step] theorem ava_spec (e : Entry) (s : Slice U8) :
    entry_impl.get_ava_set e s ⦃ r => r = ava e (nats s.val) ⦄ := by
  unfold entry_impl.get_ava_set entry_impl.get_ava_set_loop
  apply WP.spec_mono (loop_search e.attrs.val
    (fun a => decide (a.attr.val = s.val)) id (fun _ a => some a.vs) none _ ?_ 0#usize (by simp))
  · intro r hr
    rw [searchFrom_find] at hr
    simp only [id_eq] at hr
    have hn : ∀ (v w : List U8), nats v = nats w ↔ v = w := by
      intro v w
      exact List.map_inj_right (fun x y h => by scalar_tac)
    have hp : (fun a : Ava => nats a.attr.val == nats s.val) =
        (fun a : Ava => decide (a.attr.val = s.val)) := by
      funext a
      apply Bool.eq_iff_iff.mpr
      simp only [beq_iff_eq, decide_eq_true_eq, hn]
    simpa [ava, hp] using hr
  · intro i hi
    unfold entry_impl.get_ava_set_loop.body
    h5i_step
    all_goals (refine ⟨by scalar_tac, ?_⟩; simpa [alloc.vec.Vec.deref] using b_post)

@[step] theorem refer_spec (e : Entry) (s : Slice U8) :
    entry_impl.get_ava_refer e s ⦃ r =>
      r.map (·.val) = (match ava e (nats s.val) with | some (.Refer v) => some v.val | _ => none) ⦄ := by
  unfold entry_impl.get_ava_refer
  step as ⟨o, ho⟩
  cases o with
  | none => rw [← ho]; simp
  | some vs => rw [← ho]; cases vs <;> simp [valueset.as_refer_set]

@[step] theorem memberof_spec (i : Identity) :
    identity_impl.get_memberof i ⦃ r => (r.map (·.val)).getD [] = memberof i ⦄ := by
  unfold identity_impl.get_memberof
  split <;> step* <;> simp_all [memberof, refers, nats]
  all_goals rw [show lit "memberof" = [109, 101, 109, 98, 101, 114, 111, 102] from by
    literal_bytes]
  all_goals rfl

@[step] theorem contains_spec (s : Slice (alloc.vec.Vec U8)) (x : Slice U8) :
    bset.contains s x ⦃ r => r = decide (nats x.val ∈ names s.val) ⦄ := by
  unfold bset.contains bset.contains_loop
  h5i_search_any s.val (fun v => decide (v.val = x.val))
  all_goals try (refine ⟨by scalar_tac, ?_⟩; simpa [alloc.vec.Vec.deref] using b_post)
  all_goals
    rename_i hr
    rw [← hr]
    apply Bool.eq_iff_iff.mpr
    simp only [List.any_eq_true, decide_eq_true_eq, names, List.mem_map]
    have hn : ∀ v w : List U8, nats v = nats w ↔ v = w :=
      fun _ _ => List.map_inj_right (fun _ _ h => by scalar_tac)
    simp only [hn, eq_comm]

theorem push_val {α} {v w : alloc.vec.Vec α} {x : α}
    (h : alloc.vec.Vec.push v x = ok w) : w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  h5i_invert h
  simp

def AllNames (P : List Nat → Prop) (v : alloc.vec.Vec (alloc.vec.Vec U8)) : Prop :=
  ∀ a ∈ v.val, P (nats a.val)

theorem insert_safe (P : List Nat → Prop) (v w : alloc.vec.Vec (alloc.vec.Vec U8))
    (x : Slice U8) (hv : AllNames P v) (hx : P (nats x.val))
    (h : bset.insert v x = ok w) : AllNames P w := by
  unfold bset.insert at h
  h5i_invert h
  · exact hv
  · have he := post_of_ok (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 x (by intros; rfl)) hv_1
    have hp := push_val h
    intro a ha
    rw [hp] at ha
    simp only [List.mem_append, List.mem_singleton] at ha
    rcases ha with ha | rfl
    · exact hv a ha
    · simpa [alloc.vec.Vec.val, ← he] using hx

theorem extend_safe (P : List Nat → Prop) (v w : alloc.vec.Vec (alloc.vec.Vec U8))
    (xs : Slice (alloc.vec.Vec U8)) (hv : AllNames P v)
    (hxs : ∀ a ∈ xs.val, P (nats a.val))
    (h : bset.extend v xs = ok w) : AllNames P w := by
  unfold bset.extend bset.extend_loop at h
  apply loop_idx_ok _ (fun s => s.2) xs.val.length
    (fun s => AllNames P s.1) (AllNames P) ?_ (v, 0#usize) w hv (by simp) h
  rintro ⟨s, i⟩ r hs hi hr
  unfold bset.extend_loop.body at hr
  h5i_invert hr
  · have hs' := insert_safe P s set1 _ hs (by
      simpa [alloc.vec.Vec.deref, alloc.vec.Vec.val] using hxs v_1 (slice_index_ok_mem hv_1)) hset1
    exact ⟨hs', by h5i_arith, by h5i_arith⟩
  · exact hs

theorem intersection_safe (P : List Nat → Prop)
    (a b : Slice (alloc.vec.Vec U8)) (w : alloc.vec.Vec (alloc.vec.Vec U8))
    (hb : ∀ x ∈ b.val, P (nats x.val))
    (h : bset.intersection a b = ok w) : AllNames P w := by
  unfold bset.intersection bset.intersection_loop at h
  apply loop_idx_ok _ (fun s => s.2) a.val.length
    (fun s => AllNames P s.1) (AllNames P) ?_ (_, 0#usize) w (by simp [AllNames]) (by simp) h
  rintro ⟨s, i⟩ r hs hi hr
  unfold bset.intersection_loop.body at hr
  h5i_invert hr
  · have hx := post_of_ok (u8vec_clone_spec v) hx
    subst x
    have hm := post_of_ok (contains_spec b v.deref) hb1
    split at hout1
    · rename_i ht
      have hv' : P (nats v.val) := by
        have hn : nats v.val ∈ names b.val := by simpa [alloc.vec.Vec.deref, alloc.vec.Vec.val, ht] using hm.symm
        obtain ⟨z, hz, he⟩ := List.mem_map.mp hn
        rw [← he]; exact hb z hz
      have hs' := insert_safe P s out1 _ hs (by simpa [alloc.vec.Vec.deref, alloc.vec.Vec.val] using hv') hout1
      exact ⟨hs', by h5i_arith, by h5i_arith⟩
    · have he := result_ok_inj hout1
      subst out1
      exact ⟨hs, by h5i_arith, by h5i_arith⟩
  · exact hs

def moList (mo : Option (alloc.vec.Vec U128)) : List U128 := (mo.map (·.val)).getD []

@[step] theorem receiver_spec (rc : profiles.AccessControlReceiverCondition)
    (mo : Option (alloc.vec.Vec U128)) (uid : U128) (e : Entry) :
    search_acc.receiver_applies rc mo uid e ⦃ b => b = true →
      rc = .GroupChecked ∨ ∃ ms, refers e "entry_managed_by" = some ms ∧
        (uid ∈ ms ∨ ∃ g ∈ moList mo, g ∈ ms) ⦄ := by
  have hlit : lit "entry_managed_by" =
      [101,110,116,114,121,95,109,97,110,97,103,101,100,95,98,121] := by literal_bytes
  unfold search_acc.receiver_applies
  cases rc
  · simp
  · h5i_steps <;> simp_all [refers, hlit, nats, moList, alloc.vec.Vec.deref, alloc.vec.Vec.val]
    all_goals aesop

def UserId (i : Identity) (uid : U128) : Prop :=
  ∃ u, i.origin = .User u ∧ uid = u.entry.uuid

theorem conditions_sound (i : Identity) (mo0 mo : Option (alloc.vec.Vec U128))
    (uid : U128) (p : profiles.AccessControlProfile)
    (rc : profiles.AccessControlReceiverCondition) (tc : profiles.AccessControlTargetCondition)
    (e : Entry) (hmo0 : moList mo0 = memberof i)
    (hmo : moList mo = memberof i) (huid : UserId i uid)
    (h : access.resolve_access_conditions i mo0 p.receiver p.target = ok (some (rc, tc)))
    (ha : search_acc.acp_applies rc tc mo uid e = ok true) : Applies i p e := by
  unfold search_acc.acp_applies at ha
  h5i_invert ha
  have hrc := post_of_ok (receiver_spec rc mo uid e) hb hc
  unfold access.resolve_access_conditions at h
  h5i_invert h
  all_goals
    simp only [Option.some.injEq, Prod.mk.injEq] at h
    obtain ⟨hr, ht⟩ := h
    subst rc; subst tc
    unfold search_acc.target_applies at ha
  · simp only [Applies, hc_1, hc_3, ReceiverHolds, TargetHolds]
    refine ⟨?_, ⟨fi, ho, ha⟩⟩
    subst group_check
    cases mo0 with
    | none => simp at hgroup_check
    | some mo =>
      have hg := post_of_ok (intersects_uuid_spec mo.deref a.deref) hgroup_check
      have hg' : ∃ g ∈ mo.val, g ∈ a.val := by simpa [alloc.vec.Vec.deref, alloc.vec.Vec.val] using hg.symm
      simpa [← hmo0, moList] using hg'
  · simp only [Applies, hc_1, hc_2, ReceiverHolds, TargetHolds]
    refine ⟨?_, ⟨fi, ho, ha⟩⟩
    rcases hrc with hbad | ⟨ms, hm, hu | hg⟩
    · cases hbad
    · obtain ⟨u, hu', he⟩ := huid
      exact ⟨ms, hm, Or.inl ⟨u, hu', he ▸ hu⟩⟩
    · exact ⟨ms, hm, Or.inr (hmo ▸ hg)⟩

def Related (ctl : AccessControlsInner) (i : Identity)
    (a : profiles.AccessControlSearchResolved) : Prop :=
  ∃ p ∈ ctl.acps_search.val, a.attrs = p.attrs ∧
    ∀ mo uid e, moList mo = memberof i → UserId i uid →
      search_acc.acp_applies a.receiver_condition a.target_condition mo uid e = ok true →
      Applies i p.acp e

theorem related_safe (ctl : AccessControlsInner) (i : Identity)
    (attrs : Option (alloc.vec.Vec (alloc.vec.Vec U8)))
    (v : alloc.vec.Vec profiles.AccessControlSearchResolved)
    (h : access.search_related_acp ctl i attrs = ok v) :
    ∀ a ∈ v.val, Related ctl i a := by
  unfold access.search_related_acp at h
  h5i_invert h
  have hmo := post_of_ok (memberof_spec i) hident_memberof
  unfold access.search_related_acp_loop at h
  apply loop_idx_ok _ (fun s => s.2.2) ctl.acps_search.val.length
    (fun s => ∀ a ∈ s.2.1.val, Related ctl i a)
    (fun v => ∀ a ∈ v.val, Related ctl i a) ?_ _ v (by simp) (by simp) h
  rintro ⟨opt, s, j⟩ r hs hj hr
  unfold access.search_related_acp_loop.body at hr
  h5i_invert hr
  · have hxSafe : ∀ a ∈ x.2.val, Related ctl i a := by
      cases o with
      | none => h5i_invert hx; exact hs
      | some p =>
        rcases p with ⟨rc, tc⟩
        change (do
          let keep ← match opt with
            | none => ok true
            | some req => do let b ← bset.is_disjoint acs.attrs.deref req.deref; ok (¬ b)
          let s' ← if keep then do
              let av ← alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) acs.attrs
              alloc.vec.Vec.push s ⟨av, rc, tc⟩
            else ok s
          ok (opt, s')) = ok x at hx
        h5i_invert hx
        h5i_invert hs'
        · have he := post_of_ok
            (CloneLaw.vec_clone_spec (core.clone.CloneallocvecVec core.clone.CloneU8) acs.attrs) hav
          subst av
          have hp := push_val hs'
          intro a ha
          rw [hp] at ha
          simp only [List.mem_append, List.mem_singleton] at ha
          rcases ha with ha | rfl
          · exact hs a ha
          · refine ⟨acs, vec_index_slice_ok_mem hacs, rfl, ?_⟩
            intro mo uid e hm hu ha
            exact conditions_sound i ident_memberof mo uid acs.acp rc tc e hmo hm hu ho ha
        · exact hs
    rcases x with ⟨opt', s'⟩
    change (do let k ← j + 1#usize; ok (ControlFlow.cont (opt', s', k))) = ok r at hr
    h5i_invert hr
    exact ⟨hxSafe, by h5i_arith, by h5i_arith⟩
  · exact hs

def SrchSafe (P : List Nat → Prop) : AccessSrchResult → Prop
  | .Allow v => AllNames P v
  | _ => True

theorem allowed_safe (ctl : AccessControlsInner) (i : Identity)
    (rel : Slice profiles.AccessControlSearchResolved)
    (mo : Option (alloc.vec.Vec U128)) (uid : U128) (e : Entry)
    (w : alloc.vec.Vec (alloc.vec.Vec U8))
    (hrel : ∀ a ∈ rel.val, Related ctl i a)
    (hmo : moList mo = memberof i) (huid : UserId i uid)
    (h : search_acc.search_allowed_attrs rel mo uid e = ok w) :
    AllNames (SearchGrants ctl i e) w := by
  unfold search_acc.search_allowed_attrs search_acc.search_allowed_attrs_loop at h
  apply loop_idx_ok _ (fun s => s.2) rel.val.length
    (fun s => AllNames (SearchGrants ctl i e) s.1)
    (AllNames (SearchGrants ctl i e)) ?_ _ w (by simp [AllNames]) (by simp) h
  rintro ⟨s, j⟩ r hs hj hr
  unfold search_acc.search_allowed_attrs_loop.body at hr
  h5i_invert hr
  · unfold search_acc.extend_if at hallowed_attrs1
    h5i_invert hallowed_attrs1
    · have hh : ∀ a ∈ acs.attrs.val, SearchGrants ctl i e (nats a.val) := by
        obtain ⟨p, hp, he, hap⟩ := hrel acs (slice_index_ok_mem hacs)
        intro a ha
        refine Or.inl ⟨p, hp, ?_, hap mo uid e hmo huid (by simpa [hc_1] using hok1)⟩
        rw [← he]
        exact List.mem_map.mpr ⟨a, ha, rfl⟩
      have hh' := extend_safe (SearchGrants ctl i e) s allowed_attrs1 _ hs
        (by simpa [alloc.vec.Vec.deref, alloc.vec.Vec.val] using hh) hallowed_attrs1
      exact ⟨hh', by h5i_arith, by h5i_arith⟩
    · exact ⟨hs, by h5i_arith, by h5i_arith⟩
  · exact hs

theorem filter_safe (ctl : AccessControlsInner) (i : Identity)
    (rel : Slice profiles.AccessControlSearchResolved) (e : Entry) (r : AccessSrchResult)
    (hi : IsUser i) (hrel : ∀ a ∈ rel.val, Related ctl i a)
    (h : search_acc.search_filter_entry i rel e = ok r) :
    SrchSafe (SearchGrants ctl i e) r := by
  obtain ⟨u, hu⟩ := hi
  unfold search_acc.search_filter_entry at h
  simp only [hu] at h
  h5i_invert h
  all_goals try trivial
  all_goals
    have hmo := post_of_ok (memberof_spec i) hident_memberof
    have he : ident_uuid = u.entry.uuid := by
      simpa [identity_impl.get_uuid, hu] using hident_uuid.symm
    exact allowed_safe ctl i rel ident_memberof ident_uuid e allowed_attrs hrel hmo
      ⟨u, hu, he⟩ hallowed_attrs

macro "fixed_attrs " h:ident : tactic => `(tactic| (
  h5i_invert $h
  all_goals simp only [SrchSafe]
  all_goals try trivial
  all_goals simp only [lift, Result.ok.injEq] at *
  all_goals subst_vars))

theorem insert_fixed {v w : alloc.vec.Vec (alloc.vec.Vec U8)} {x : Slice U8}
    (h : bset.insert v x = ok w) (hv : AllNames (fun a => a ∈ fixedSearchAttrs) v)
    (hx : nats x.val ∈ fixedSearchAttrs) : AllNames (fun a => a ∈ fixedSearchAttrs) w :=
  insert_safe _ _ _ _ hv hx h

theorem oauth_safe (i : Identity) (e : Entry) (r : AccessSrchResult)
    (h : search_acc.search_oauth2_filter_entry i e = ok r) :
    SrchSafe (fun a => a ∈ fixedSearchAttrs) r := by
  unfold search_acc.search_oauth2_filter_entry at h
  fixed_attrs h
  have h0 := insert_fixed hattr (by simp [AllNames]) (by decide +kernel)
  have h1 := insert_fixed hattr1 h0 (by decide +kernel)
  have h2 := insert_fixed hattr2 h1 (by decide +kernel)
  have h3 := insert_fixed hattr3 h2 (by decide +kernel)
  have h4 := insert_fixed hattr4 h3 (by decide +kernel)
  exact insert_fixed hattr5 h4 (by decide +kernel)

theorem application_safe (i : Identity) (e : Entry) (r : AccessSrchResult)
    (h : search_acc.search_applications_filter_entry i e = ok r) :
    SrchSafe (fun a => a ∈ fixedSearchAttrs) r := by
  unfold search_acc.search_applications_filter_entry at h
  fixed_attrs h
  have h0 := insert_fixed hattr (by simp [AllNames]) (by decide +kernel)
  have h1 := insert_fixed hattr1 h0 (by decide +kernel)
  have h2 := insert_fixed hattr2 h1 (by decide +kernel)
  have h3 := insert_fixed hattr3 h2 (by decide +kernel)
  exact insert_fixed hattr4 h3 (by decide +kernel)

theorem sync_safe (i : Identity) (e : Entry) (r : AccessSrchResult)
    (h : search_acc.search_sync_account_filter_entry i e = ok r) :
    SrchSafe (fun a => a ∈ fixedSearchAttrs) r := by
  unfold search_acc.search_sync_account_filter_entry at h
  fixed_attrs h
  have h0 := insert_fixed hattr (by simp [AllNames]) (by decide +kernel)
  have h1 := insert_fixed hattr1 h0 (by decide +kernel)
  exact insert_fixed hattr2 h1 (by decide +kernel)

def accumulate (sr : AccessSrchResult) (d g : Bool)
    (a : alloc.vec.Vec (alloc.vec.Vec U8)) :
    Result (Bool × Bool × alloc.vec.Vec (alloc.vec.Vec U8)) :=
  match sr with
  | .Deny => ok (true, g, a)
  | .Grant => ok (d, true, a)
  | .Ignore => ok (d, g, a)
  | .Allow v => do
    let a' ← bset.extend a v.deref
    ok (d, g, a')

theorem accumulate_safe (P : List Nat → Prop) (sr : AccessSrchResult) (d g : Bool)
    (a : alloc.vec.Vec (alloc.vec.Vec U8))
    (s : Bool × Bool × alloc.vec.Vec (alloc.vec.Vec U8))
    (ha : AllNames P a) (hr : SrchSafe P sr)
    (h : accumulate sr d g a = ok s) : AllNames P s.2.2 := by
  cases sr <;> unfold accumulate at h <;> h5i_invert h
  · exact ha
  · exact ha
  · exact ha
  · exact extend_safe P a a' _ ha
      (by simpa [SrchSafe, AllNames, alloc.vec.Vec.deref, alloc.vec.Vec.val] using hr) ha'

theorem fixed_to_grants (ctl : AccessControlsInner) (i : Identity) (e : Entry)
    (r : AccessSrchResult) (h : SrchSafe (fun a => a ∈ fixedSearchAttrs) r) :
    SrchSafe (SearchGrants ctl i e) r := by
  cases r <;> try trivial
  intro a ha
  exact Or.inr (h a ha)

theorem apply_safe (ctl : AccessControlsInner) (i : Identity)
    (rel : Slice profiles.AccessControlSearchResolved) (e : Entry)
    (w : alloc.vec.Vec (alloc.vec.Vec U8))
    (hi : IsUser i) (hrel : ∀ a ∈ rel.val, Related ctl i a)
    (h : search_acc.apply_search_access i rel e = ok (.Allow w)) :
    AllNames (SearchGrants ctl i e) w := by
  unfold search_acc.apply_search_access at h
  obtain ⟨sr, hsr, h⟩ := bind_tc_eq_ok.mp h
  obtain ⟨s, hs, h⟩ := bind_tc_eq_ok.mp h
  rcases s with ⟨d, g, a⟩
  have ha := accumulate_safe (SearchGrants ctl i e) sr false false _ (d, g, a)
    (by simp [AllNames]) (filter_safe ctl i rel e sr hi hrel hsr) hs
  obtain ⟨sr1, hsr1, h⟩ := bind_tc_eq_ok.mp h
  obtain ⟨s1, hs1, h⟩ := bind_tc_eq_ok.mp h
  rcases s1 with ⟨d1, g1, a1⟩
  have ha1 := accumulate_safe (SearchGrants ctl i e) sr1 d g a (d1, g1, a1) ha
    (fixed_to_grants ctl i e sr1 (oauth_safe i e sr1 hsr1)) hs1
  obtain ⟨sr2, hsr2, h⟩ := bind_tc_eq_ok.mp h
  obtain ⟨s2, hs2, h⟩ := bind_tc_eq_ok.mp h
  rcases s2 with ⟨d2, g2, a2⟩
  have ha2 := accumulate_safe (SearchGrants ctl i e) sr2 d1 g1 a1 (d2, g2, a2) ha1
    (fixed_to_grants ctl i e sr2 (application_safe i e sr2 hsr2)) hs2
  obtain ⟨sr3, hsr3, h⟩ := bind_tc_eq_ok.mp h
  obtain ⟨s3, hs3, h⟩ := bind_tc_eq_ok.mp h
  rcases s3 with ⟨d3, g3, a3⟩
  have ha3 := accumulate_safe (SearchGrants ctl i e) sr3 d2 g2 a2 (d3, g3, a3) ha2
    (fixed_to_grants ctl i e sr3 (sync_safe i e sr3 hsr3)) hs3
  have hn : (alloc.vec.Vec.new (alloc.vec.Vec U8)).len = 0#usize := by
    simp [alloc.vec.Vec.len, alloc.vec.Vec.new]
    scalar_tac
  simp only [hn] at h
  simp at h
  change (if d3 then ok search_acc.SearchResult.Deny
    else if g3 then ok search_acc.SearchResult.Grant
    else ok (search_acc.SearchResult.Allow a3)) = ok (.Allow w) at h
  h5i_invert h
  simp only [search_acc.SearchResult.Allow.injEq] at h
  subst w
  exact ha3

theorem reduce_attrs_safe (P : List Nat → Prop) (e : Entry)
    (allowed : Slice (alloc.vec.Vec U8)) (ea : Option AccessEffectivePermission)
    (r : EntryReduced) (hall : ∀ a ∈ allowed.val, P (nats a.val))
    (h : entry_impl.reduce_attributes e allowed ea = ok r) :
    r.uuid = e.uuid ∧ ∀ x ∈ r.attrs.val, x ∈ e.attrs.val ∧ P (nats x.attr.val) := by
  let Inv := fun s : alloc.vec.Vec Ava => ∀ x ∈ s.val, x ∈ e.attrs.val ∧ P (nats x.attr.val)
  unfold entry_impl.reduce_attributes at h
  obtain ⟨v, hv, h⟩ := bind_tc_eq_ok.mp h
  rcases v with ⟨uid, av⟩
  have hres : uid = e.uuid ∧ Inv av := by
    unfold entry_impl.reduce_attributes_loop at hv
    apply loop_idx_ok _ (fun s => s.2) e.attrs.val.length
      (fun s => Inv s.1) (fun v => v.1 = e.uuid ∧ Inv v.2) ?_ _ (uid, av)
      (by simp [Inv]) (by simp) hv
    rintro ⟨s, j⟩ out hs hj hr
    unfold entry_impl.reduce_attributes_loop.body at hr
    h5i_invert hr
    · have he : a = kv := by simpa using hkv
      subst kv
      have hm := post_of_ok (contains_spec allowed a.attr.deref) hb
      split at hf_attrs1
      · rename_i ht
        have haP : P (nats a.attr.val) := by
          have hn : nats a.attr.val ∈ names allowed.val := by
            simpa [ht, alloc.vec.Vec.deref, alloc.vec.Vec.val] using hm.symm
          obtain ⟨z, hz, he⟩ := List.mem_map.mp hn
          rw [← he]; exact hall z hz
        have hs' : Inv f_attrs1 := by
          intro x hx
          rw [push_val hf_attrs1] at hx
          simp only [List.mem_append, List.mem_singleton] at hx
          rcases hx with hx | rfl
          · exact hs x hx
          · exact ⟨vec_index_slice_ok_mem ha, haP⟩
        exact ⟨hs', by h5i_arith, by h5i_arith⟩
      · have he := result_ok_inj hf_attrs1
        subst f_attrs1
        exact ⟨hs, by h5i_arith, by h5i_arith⟩
    · exact ⟨rfl, hs⟩
  change ok (⟨uid, av, ea⟩ : EntryReduced) = ok r at h
  h5i_invert h
  exact hres

def EntrySafe (ctl : AccessControlsInner) (i : Identity) (es : Slice Entry)
    (r : EntryReduced) : Prop :=
  ∀ x ∈ r.attrs.val, ∃ e ∈ es.val, e.uuid = r.uuid ∧ x ∈ e.attrs.val ∧
    SearchGrants ctl i e (nats x.attr.val)

theorem entries_safe (ctl : AccessControlsInner) (se : SearchEvent)
    (rel : Slice profiles.AccessControlSearchResolved)
    (mods : Slice profiles.AccessControlModifyResolved)
    (dels : Slice profiles.AccessControlDeleteResolved) (es : Slice Entry)
    (rs : alloc.vec.Vec EntryReduced) (hi : IsUser se.ident)
    (hrel : ∀ a ∈ rel.val, Related ctl se.ident a)
    (h : access.reduce_entries_loop ctl se rel mods dels es = ok rs) :
    ∀ r ∈ rs.val, EntrySafe ctl se.ident es r := by
  let Safe := fun v : alloc.vec.Vec EntryReduced => ∀ r ∈ v.val, EntrySafe ctl se.ident es r
  unfold access.reduce_entries_loop access.reduce_entries_loop_loop at h
  apply loop_idx_ok _ (fun s => s.2.2.2) es.val.length
    (fun s => s.1 = ctl ∧ s.2.1.ident = se.ident ∧ Safe s.2.2.1)
    Safe ?_ _ rs (by simp [Safe]) (by simp) h
  rintro ⟨ctl', se', v, j⟩ out ⟨hc, hid, hv⟩ hj ho
  dsimp only at hc hid hv hj ho ⊢
  subst ctl'
  unfold access.reduce_entries_loop_loop.body at ho
  dsimp only at ho
  split at ho
  · rename_i hlt
    obtain ⟨e, he, ho⟩ := bind_tc_eq_ok.mp ho
    obtain ⟨sr, hsr, ho⟩ := bind_tc_eq_ok.mp ho
    obtain ⟨s, hs, ho⟩ := bind_tc_eq_ok.mp ho
    have hsSafe : s.1 = ctl ∧ Safe s.2.2.2 := by
      cases sr with
      | Deny => h5i_invert hs; exact ⟨rfl, hv⟩
      | Grant => h5i_invert hs; exact ⟨rfl, hv⟩
      | Allow allowed =>
        have hall := apply_safe ctl se'.ident rel e allowed
          (hid.symm ▸ hi) (hid.symm ▸ hrel) hsr
        obtain ⟨oa, hoa, hs⟩ := bind_tc_eq_ok.mp hs
        rcases oa with ⟨o, attrs⟩
        have hattrs : AllNames (SearchGrants ctl se.ident e) attrs := by
          rw [hid] at hall
          cases hopt : se'.attrs with
          | none =>
            simp only [hopt] at hoa
            h5i_invert hoa
            rw [← hoa.2]
            exact hall
          | some requested =>
            simp only [hopt] at hoa
            h5i_invert hoa
            rw [← hoa.2]
            exact intersection_safe _ _ _ reduced_attrs1
              (by simpa [alloc.vec.Vec.deref, alloc.vec.Vec.val, AllNames] using hall) hreduced_attrs1
        obtain ⟨ep, hep, hs⟩ := bind_tc_eq_ok.mp hs
        rcases ep with ⟨ctl2, b, effective⟩
        have hc2 : ctl2 = ctl := by
          split at hep <;> h5i_invert hep <;> exact hep.1.symm
        subst ctl2
        obtain ⟨er, her, hs⟩ := bind_tc_eq_ok.mp hs
        obtain ⟨v', hv', hs⟩ := bind_tc_eq_ok.mp hs
        have herSafe := reduce_attrs_safe (SearchGrants ctl se.ident e) e attrs.deref effective er
          (by simpa [alloc.vec.Vec.deref, alloc.vec.Vec.val, AllNames] using hattrs) her
        h5i_invert hs
        refine ⟨rfl, ?_⟩
        intro r hr
        rw [push_val hv'] at hr
        simp only [List.mem_append, List.mem_singleton] at hr
        rcases hr with hr | rfl
        · exact hv r hr
        · intro x hx
          obtain ⟨hx', hg⟩ := herSafe.2 x hx
          exact ⟨e, slice_index_ok_mem he, herSafe.1.symm, hx', hg⟩
    rcases s with ⟨ctl1, o, b, v1⟩
    obtain ⟨hc1, hv1⟩ := hsSafe
    dsimp only at hc1 hv1
    subst ctl1
    change (do
      let k ← j + 1#usize
      ok (ControlFlow.cont (ctl, {se' with attrs := o, effective_access_check := b}, v1, k))) = ok out at ho
    h5i_invert ho
    exact ⟨⟨rfl, hid, hv1⟩, by h5i_arith, by h5i_arith⟩
  · h5i_invert ho; exact hv

theorem search_attrs_granted (ctl : AccessControlsInner) (se : SearchEvent) (es : Slice Entry)
    (rs : alloc.vec.Vec EntryReduced) (r : EntryReduced) (x : Ava)
    (h : access.search_filter_entry_attributes ctl se es = ok (.Ok rs))
    (hr : r ∈ rs.val) (hx : x ∈ r.attrs.val) :
    ∃ e ∈ es.val, e.uuid = r.uuid ∧ x ∈ e.attrs.val ∧ SearchGrants ctl se.ident e (nats x.attr.val) := by
  unfold access.search_filter_entry_attributes at h
  cases horigin : se.ident.origin with
  | Internal u => simp only [horigin] at h; h5i_invert h
  | Synch u => simp only [horigin] at h; h5i_invert h
  | User u =>
    simp only [horigin] at h
    obtain ⟨bm, hbm, h⟩ := bind_tc_eq_ok.mp h
    rcases bm with ⟨b, mods⟩
    obtain ⟨dels, hdels, h⟩ := bind_tc_eq_ok.mp h
    obtain ⟨oa, hoa, h⟩ := bind_tc_eq_ok.mp h
    rcases oa with ⟨o, attrs⟩
    obtain ⟨rel, hrel, h⟩ := bind_tc_eq_ok.mp h
    obtain ⟨v, hv, h⟩ := bind_tc_eq_ok.mp h
    h5i_invert h
    have hrelated := related_safe ctl se.ident attrs rel hrel
    have hsafe := entries_safe ctl {se with attrs := o, effective_access_check := b}
      rel.deref mods.deref dels.deref es rs ⟨u, horigin⟩
      (by simpa [alloc.vec.Vec.deref, alloc.vec.Vec.val] using hrelated) hv
    exact hsafe r hr x hx

end kanidm_kernel.Solution
