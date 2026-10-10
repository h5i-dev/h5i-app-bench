import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP
set_option maxRecDepth 2048

namespace kanidm_kernel.Solution

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    bset.bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold bset.bytes_eq
  dsimp only
  split
  · step*
  · rename_i hlen
    have hlen' : a.val.length = b.val.length := by scalar_tac
    unfold bset.bytes_eq_loop
    apply loop_idx_spec _ id a.val.length
      (fun i => ∀ k < i.val, a.val[k]? = b.val[k]?) _ ?_ 0#usize
      (by simp) (by simp)
    intro i hi hn
    unfold bset.bytes_eq_loop.body
    step* <;> simp only [id_eq] at *
    · refine ⟨?_, by scalar_tac, by scalar_tac⟩
      intro k hk
      by_cases hki : k < i.val
      · exact hi k hki
      · have hki' : k = i.val := by scalar_tac
        subst k
        have heq : i2 = i3 := by scalar_tac
        have ha : i.val < a.val.length := by scalar_tac
        have hb : i.val < b.val.length := by scalar_tac
        simp_all
    · have heq : a.val = b.val := by
        apply List.ext_getElem?'
        intro k hk
        apply hi k
        scalar_tac
      simp [heq]

@[step] theorem ava_set_spec (e : Entry) (attr : Slice U8) :
    entry_impl.get_ava_set e attr ⦃ r =>
      r = (e.attrs.val.find? (fun a => decide (a.attr.val = attr.val))).map (·.vs) ⦄ := by
  unfold entry_impl.get_ava_set entry_impl.get_ava_set_loop
  apply WP.spec_mono (loop_search e.attrs.val (fun a => decide (a.attr.val = attr.val))
    id (fun _ a => some a.vs) none _ ?_ 0#usize (by simp))
  · intro r hr
    simpa [searchFrom_find] using hr
  · intro i hi
    unfold entry_impl.get_ava_set_loop.body
    h5i_step [alloc.vec.Vec.deref]

theorem nats_eq_iff (a b : List U8) : nats a = nats b ↔ a = b := by
  constructor
  · intro h
    exact (List.map_injective_iff.mpr (fun _ _ h => (u8_eq_iff _ _).mpr h)) h
  · rintro rfl; rfl

theorem ava_eq (e : Entry) (attr : Slice U8) :
    ava e (nats attr.val) =
      (e.attrs.val.find? (fun a => decide (a.attr.val = attr.val))).map (·.vs) := by
  simp only [ava, beq_eq_decide, nats_eq_iff]

@[step] theorem ava_refer_spec (e : Entry) (attr : Slice U8) :
    entry_impl.get_ava_refer e attr ⦃ r => r.map (·.val) =
      (match ava e (nats attr.val) with | some (.Refer s) => some s.val | _ => none) ⦄ := by
  rw [ava_eq]
  unfold entry_impl.get_ava_refer
  rw [eq_ok_of_spec (ava_set_spec e attr)]
  simp only [bind_ok]
  generalize (e.attrs.val.find? (fun a => decide (a.attr.val = attr.val))).map (·.vs) = o
  cases o with
  | none => simp
  | some vs => cases vs <;> simp [valueset.as_refer_set]

@[step] theorem contains_uuid_spec (s : Slice U128) (u : U128) :
    bset.contains_uuid s u ⦃ r => r = s.val.any (fun x => decide (x = u)) ⦄ := by
  unfold bset.contains_uuid bset.contains_uuid_loop
  h5i_search_any s.val (fun x => decide (x = u))

@[step] theorem intersects_uuid_spec (a b : Slice U128) :
    bset.intersects_uuid a b ⦃ r => r = a.val.any (fun x => decide (x ∈ b.val)) ⦄ := by
  unfold bset.intersects_uuid bset.intersects_uuid_loop
  h5i_search_any a.val (fun x => decide (x ∈ b.val))
  refine ⟨by scalar_tac, ?_⟩
  intro hm
  exact b1_post _ hm rfl

@[step] theorem memberof_spec (ident : Identity) :
    identity_impl.get_memberof ident ⦃ r => (r.map (·.val)).getD [] = memberof ident ⦄ := by
  unfold identity_impl.get_memberof memberof
  cases ho : ident.origin with
  | User u =>
    step*
    have hl : lit "memberof" = [109, 101, 109, 98, 101, 114, 111, 102] := by
      unfold lit
      rw [String.toUTF8_eq_toByteArray, ← String.utf8Encode_toList]
      simp [List.utf8Encode, String.utf8EncodeChar]
      decide +kernel
    simp_all [refers, nats, Array.to_slice, Array.make]
    rfl
  | Synch u => simp
  | Internal ir => simp

theorem memberof_of_ok {ident : Identity} {mo : Option (alloc.vec.Vec U128)}
    (h : identity_impl.get_memberof ident = ok mo) :
    (mo.map (·.val)).getD [] = memberof ident :=
  H5iAppLib.post_of_ok (P := fun r : Option (alloc.vec.Vec U128) =>
    (r.map (·.val)).getD [] = memberof ident) (memberof_spec ident) h

/-- A resolved delete profile retains its original configured profile. -/
def HasSource (ident : Identity) (ds : alloc.vec.Vec profiles.AccessControlDelete)
    (mo : Option (alloc.vec.Vec U128)) (rd : profiles.AccessControlDeleteResolved) : Prop :=
  ∃ acd ∈ ds.val, access.resolve_access_conditions ident mo acd.acp.receiver acd.acp.target =
    ok (some (rd.receiver_condition, rd.target_condition))

theorem push_val_of_ok {α} {v w : alloc.vec.Vec α} {x : α}
    (h : alloc.vec.Vec.push v x = ok w) : w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  h5i_invert h
  simp

theorem related_has_source (ctl : AccessControlsInner) (ident : Identity)
    (out : alloc.vec.Vec profiles.AccessControlDeleteResolved)
    (h : access.delete_related_acp ctl ident = ok out) :
    ∃ mo, identity_impl.get_memberof ident = ok mo ∧
      ∀ rd ∈ out.val, HasSource ident ctl.acps_delete mo rd := by
  unfold access.delete_related_acp at h
  h5i_invert h
  refine ⟨ident_memberof, hident_memberof, ?_⟩
  unfold access.delete_related_acp_loop at h
  apply loop_idx_ok _ Prod.snd ctl.acps_delete.val.length
    (fun st => ∀ rd ∈ st.1.val, HasSource ident ctl.acps_delete ident_memberof rd)
    (fun out => ∀ rd ∈ out.val, HasSource ident ctl.acps_delete ident_memberof rd)
    ?_ _ _ (by simp [alloc.vec.Vec.new]) (by simp) h
  rintro ⟨acc, i⟩ r hinv hn hr
  unfold access.delete_related_acp_loop.body at hr
  h5i_invert hr
  · refine ⟨?_, by h5i_arith, by h5i_arith⟩
    cases o with
    | none =>
      have heq := Result.ok.inj hrelated_acp1
      subst related_acp1
      exact hinv
    | some p =>
      obtain ⟨rc, tc⟩ := p
      simp only at hrelated_acp1
      have hp := push_val_of_ok hrelated_acp1
      intro rd hrd
      rw [hp] at hrd
      simp only [List.mem_append, List.mem_singleton] at hrd
      rcases hrd with hrd | rfl
      · exact hinv rd hrd
      · exact ⟨acs, vec_index_slice_ok_mem hacs, ho⟩
  · exact hinv

theorem any_acp_witness (rs : Slice profiles.AccessControlDeleteResolved)
    (mo : Option (alloc.vec.Vec U128)) (uid : U128) (e : Entry)
    (h : delete_acc.delete_any_acp rs mo uid e = ok true) :
    ∃ rd ∈ rs.val, search_acc.acp_applies rd.receiver_condition rd.target_condition mo uid e = ok true := by
  unfold delete_acc.delete_any_acp delete_acc.delete_any_acp_loop at h
  apply loop_idx_ok _ id rs.val.length (fun _ => True)
    (fun b => b = true → ∃ rd ∈ rs.val,
      search_acc.acp_applies rd.receiver_condition rd.target_condition mo uid e = ok true)
    ?_ _ _ trivial (by simp) h rfl
  intro i r _ hn hr
  unfold delete_acc.delete_any_acp_loop.body at hr
  h5i_invert hr
  · intro _
    exact ⟨acd, slice_index_ok_mem hacd, by simpa [hc_1] using hb⟩
  · simp only [id_eq] at *
    exact ⟨trivial, by h5i_arith, by h5i_arith⟩
  · simp

/-- A successful all-entry scan grants every entry in the input slice. -/
theorem all_entries_granted (ident : Identity) (rs : Slice profiles.AccessControlDeleteResolved)
    (es : Slice Entry) (e : Entry) (he : e ∈ es.val)
    (h : access.delete_all_entries ident rs es = ok true) :
    delete_acc.apply_delete_access ident rs e = ok .Grant := by
  unfold access.delete_all_entries access.delete_all_entries_loop at h
  have hall := loop_idx_ok _ id es.val.length
    (fun i => ∀ k < i.val, ∀ ek, es.val[k]? = some ek → delete_acc.apply_delete_access ident rs ek = ok .Grant)
    (fun b => b = true → ∀ ek ∈ es.val, delete_acc.apply_delete_access ident rs ek = ok .Grant)
    (x := 0#usize) (y := true) ?_ (by simp) (by simp) h
  · exact hall rfl e he
  · intro i r hinv hn hr
    unfold access.delete_all_entries_loop.body at hr
    h5i_invert hr
    · simp
    · simp only [id_eq] at *
      refine ⟨?_, by h5i_arith, by h5i_arith⟩
      intro k hk ek hek
      by_cases hki : k < i.val
      · exact hinv k hki ek hek
      · have hki' : k = i.val := by h5i_arith
        subst k
        obtain ⟨hlt, heq⟩ := slice_index_ok he_1
        have hei : es.val[i.val]? = some e_1 := by
          rw [List.getElem?_eq_getElem hlt, heq]
        have : e_1 = ek := by simpa [hei] using hek
        subst ek
        exact hdr
    · intro _ ek hek
      obtain ⟨k, hk, hke⟩ := List.getElem_of_mem hek
      apply hinv k (by scalar_tac) ek
      rw [List.getElem?_eq_getElem hk, hke]

theorem grant_filter (ident : Identity) (rs : Slice profiles.AccessControlDeleteResolved)
    (e : Entry) (h : delete_acc.apply_delete_access ident rs e = ok .Grant) :
    delete_acc.delete_filter_entry ident rs e = ok .Grant := by
  unfold delete_acc.apply_delete_access at h
  h5i_invert h
  cases i1
  all_goals h5i_invert hx
  all_goals cases denied <;> simp_all

theorem user_grant_witness (ident : Identity) (u : IdentUser)
    (hu : ident.origin = .User u) (rs : Slice profiles.AccessControlDeleteResolved)
    (e : Entry) (h : delete_acc.apply_delete_access ident rs e = ok .Grant) :
    ∃ mo, identity_impl.get_memberof ident = ok mo ∧
      ∃ rd ∈ rs.val, search_acc.acp_applies rd.receiver_condition rd.target_condition mo u.entry.uuid e = ok true := by
  have hf := grant_filter ident rs e h
  unfold delete_acc.delete_filter_entry at hf
  simp only [hu] at hf
  h5i_invert hf
  simp only [identity_impl.get_uuid, hu] at hident_uuid
  h5i_invert hident_uuid
  refine ⟨ident_memberof, hident_memberof, ?_⟩
  apply any_acp_witness
  simpa [hc] using hallow

theorem refer_of_ok (e : Entry) (attr : Slice U8) (v : alloc.vec.Vec U128)
    (h : entry_impl.get_ava_refer e attr = ok (some v)) :
    (match ava e (nats attr.val) with | some (.Refer s) => some s.val | _ => none) = some v.val := by
  exact (H5iAppLib.post_of_ok (P := fun r : Option (alloc.vec.Vec U128) => r.map (·.val) =
    (match ava e (nats attr.val) with | some (.Refer s) => some s.val | _ => none))
    (ava_refer_spec e attr) h).symm

theorem contains_uuid_of_ok (s : Slice U128) (uid : U128)
    (h : bset.contains_uuid s uid = ok true) : uid ∈ s.val := by
  have hr := H5iAppLib.post_of_ok (P := fun r => r = s.val.any (fun x => decide (x = uid)))
    (contains_uuid_spec s uid) h
  obtain ⟨x, hx, heq⟩ := List.any_eq_true.mp hr.symm
  have heq' : x = uid := of_decide_eq_true heq
  simpa only [heq'] using hx

theorem intersects_uuid_of_ok (a b : Slice U128)
    (h : bset.intersects_uuid a b = ok true) : ∃ g ∈ a.val, g ∈ b.val := by
  have hr := H5iAppLib.post_of_ok (P := fun r => r = a.val.any (fun x => decide (x ∈ b.val)))
    (intersects_uuid_spec a b) h
  simpa using hr.symm

theorem manager_receiver (ident : Identity) (u : IdentUser) (hu : ident.origin = .User u)
    (mo : Option (alloc.vec.Vec U128)) (hmo : identity_impl.get_memberof ident = ok mo)
    (e : Entry) (h : search_acc.receiver_applies .EntryManager mo u.entry.uuid e = ok true) :
    ReceiverHolds ident .EntryManager e := by
  unfold search_acc.receiver_applies at h
  simp only [lift, bind_ok] at h
  h5i_invert h
  all_goals
    have hl : lit "entry_managed_by" =
        [101, 110, 116, 114, 121, 95, 109, 97, 110, 97, 103, 101, 100, 95, 98, 121] := by
      unfold lit
      rw [String.toUTF8_eq_toByteArray, ← String.utf8Encode_toList]
      simp [List.utf8Encode, String.utf8EncodeChar]
      decide +kernel
    have href : refers e "entry_managed_by" = some imo.val := by
      have hr := refer_of_ok _ _ _ ho
      unfold refers
      rw [hl]
      convert hr using 1
      simp [nats, Array.to_slice, Array.make]
      rfl
    refine ⟨imo.val, href, ?_⟩
  · rw [hc] at hgroup_check
    h5i_invert hgroup_check
    obtain ⟨g, hg, hgm⟩ := intersects_uuid_of_ok _ _ hgroup_check
    simp only [vec_deref_val] at hg hgm
    right
    refine ⟨g, ?_, hgm⟩
    have hmem := memberof_of_ok hmo
    simpa [← hmem, alloc.vec.Vec.deref] using hg
  · left
    refine ⟨u, hu, ?_⟩
    simpa only [vec_deref_val] using contains_uuid_of_ok (alloc.vec.Vec.deref imo) _ huser_check

/-- Resolution and a successful match establish the original profile's policy. -/
theorem resolved_applies (ident : Identity) (u : IdentUser) (hu : ident.origin = .User u)
    (mo : Option (alloc.vec.Vec U128)) (hmo : identity_impl.get_memberof ident = ok mo)
    (p : profiles.AccessControlProfile)
    (rc : profiles.AccessControlReceiverCondition) (tc : profiles.AccessControlTargetCondition)
    (e : Entry)
    (hres : access.resolve_access_conditions ident mo p.receiver p.target = ok (some (rc, tc)))
    (happ : search_acc.acp_applies rc tc mo u.entry.uuid e = ok true) : Applies ident p e := by
  obtain ⟨receiver, target⟩ := p
  cases receiver <;> cases target
  all_goals unfold access.resolve_access_conditions at hres
  all_goals h5i_invert hres
  all_goals
    obtain ⟨rfl, rfl⟩ := Prod.mk.inj (Option.some.inj hres)
  · rw [hc] at hgroup_check
    h5i_invert hgroup_check
    unfold search_acc.acp_applies search_acc.receiver_applies search_acc.target_applies at happ
    simp only [bind_ok, reduceIte] at happ
    obtain ⟨g, hg, hgroups⟩ := intersects_uuid_of_ok _ _ hgroup_check
    refine ⟨?_, fi, ho, happ⟩
    refine ⟨g, ?_, ?_⟩
    · have hmem := memberof_of_ok hmo
      simpa [← hmem, vec_deref_val] using hg
    · simpa only [vec_deref_val] using hgroups
  · unfold search_acc.acp_applies at happ
    h5i_invert happ
    refine ⟨manager_receiver ident u hu mo hmo e ?_, fi, ho, ?_⟩
    · simpa [hc] using hb
    · simpa only [search_acc.target_applies] using happ

theorem delete_needs_profile (ctl : AccessControlsInner) (de : DeleteEvent) (es : Slice Entry) (e : Entry)
    (hu : IsUser de.ident) (h : access.delete_allow_operation ctl de es = ok (.Ok true)) (he : e ∈ es.val) :
    ∃ acd ∈ ctl.acps_delete.val, Applies de.ident acd.acp e := by
  rcases hu with ⟨u, hu⟩
  unfold access.delete_allow_operation at h
  h5i_invert h
  have hg := all_entries_granted de.ident (alloc.vec.Vec.deref related_acp) es e he hb
  obtain ⟨mo, hmo, rd, hrd, happ⟩ := user_grant_witness de.ident u hu _ e hg
  obtain ⟨mo', hmo', hs⟩ := related_has_source ctl de.ident related_acp hrelated_acp
  have heq : mo' = mo := Result.ok.inj (hmo'.symm.trans hmo)
  subst mo'
  simp only [vec_deref_val] at hrd
  obtain ⟨acd, hacd, hres⟩ := hs rd hrd
  exact ⟨acd, hacd, resolved_applies de.ident u hu mo hmo acd.acp
    rd.receiver_condition rd.target_condition e hres happ⟩

end kanidm_kernel.Solution
