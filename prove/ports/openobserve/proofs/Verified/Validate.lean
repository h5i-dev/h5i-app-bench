import Verified.Routes
/-! `validate_delegated` and its store lookups: what a successful run establishes. -/
open Aeneas Aeneas.Std Result openobserve_kernel openobserve_kernel.Spec openobserve_kernel.Verified
open H5iAppLib hiding lit
open openobserve_kernel.delegation

namespace openobserve_kernel.Verified

h5i_derive_clone UserRole UserRole.Insts.CoreCloneClone.clone
h5i_derive_clone LinkRow LinkRow.Insts.CoreCloneClone.clone
h5i_derive_clone Installation Installation.Insts.CoreCloneClone.clone
h5i_derive_clone Member Member.Insts.CoreCloneClone.clone

@[step] theorem find_link_spec (links : Slice LinkRow) (id : Slice U8) :
    find_link links id ⦃ o => o = links.val.find? (fun l => decide (nats l.id.val = nats id.val)) ⦄ := by
  unfold find_link find_link_loop
  apply WP.spec_mono (loop_search links.val (fun l => decide (nats l.id.val = nats id.val)) _root_.id
    (fun _ x => some x) none _ ?_ 0#usize (by simp))
  · intro r hr
    exact search_find _ _ _ hr
  · intro i hi
    unfold find_link_loop.body; simp only []
    step*
    · left; exact ⟨by scalar_tac, by simp_all [alloc.vec.Vec.deref], by simp_all⟩
    · exact ⟨by scalar_tac, by simp_all [alloc.vec.Vec.deref], by scalar_tac⟩
    · right; exact ⟨by scalar_tac, rfl⟩

@[step] theorem find_installation_spec (insts : Slice Installation) (id : Slice U8) :
    find_installation insts id ⦃ o => o = insts.val.find? (fun l => decide (nats l.id.val = nats id.val)) ⦄ := by
  unfold find_installation find_installation_loop
  apply WP.spec_mono (loop_search insts.val (fun l => decide (nats l.id.val = nats id.val)) _root_.id
    (fun _ x => some x) none _ ?_ 0#usize (by simp))
  · intro r hr
    exact search_find _ _ _ hr
  · intro i hi
    unfold find_installation_loop.body; simp only []
    step*
    · left; exact ⟨by scalar_tac, by simp_all [alloc.vec.Vec.deref], by simp_all⟩
    · exact ⟨by scalar_tac, by simp_all [alloc.vec.Vec.deref], by scalar_tac⟩
    · right; exact ⟨by scalar_tac, rfl⟩

@[step] theorem find_member_spec (ms : Slice Member) (org email : Slice U8) :
    find_member ms org email ⦃ o => o = ms.val.find?
      (fun m => decide (nats m.org.val = nats org.val) && decide (nats m.email.val = nats email.val)) ⦄ := by
  unfold find_member find_member_loop
  apply WP.spec_mono (loop_search ms.val
    (fun m => decide (nats m.org.val = nats org.val) && decide (nats m.email.val = nats email.val)) _root_.id
    (fun _ x => some x) none _ ?_ 0#usize (by simp))
  · intro r hr
    exact search_find _ _ _ hr
  · intro i hi
    unfold find_member_loop.body; simp only []
    step*
    · left; exact ⟨by scalar_tac, by simp_all [alloc.vec.Vec.deref], by simp_all⟩
    · exact ⟨by scalar_tac, by simp_all [alloc.vec.Vec.deref], by scalar_tac⟩
    · exact ⟨by scalar_tac, by simp_all [alloc.vec.Vec.deref], by scalar_tac⟩
    · right; exact ⟨by scalar_tac, rfl⟩

theorem verified_claims_ok {t : Slice U8} {s k : Bool} {o : VerifyOracle} {now : I64}
    {dis : Slice (alloc.vec.Vec U8)} {c : Claims}
    (h : verified_claims t s k o now dis = ok (.Ok c)) :
    s = true ∧ k = true ∧ verify t o now = ok (.Ok c) ∧ nats c.org.val ∉ dis.val.map (fun v => nats v.val) := by
  unfold verified_claims at h
  h5i_invert h
  have := post_of_ok (contains_spec _ _) ‹bytes.contains _ _ = ok _›
  simp_all [alloc.vec.Vec.deref]

theorem admit_ok {f : LinkFacts} {c : Claims} (h : admit f c = ok (.Ok ())) :
    f.refusal = none ∧ nats f.user_email.val = nats c.sub.val ∧
      nats c.org.val ∈ f.orgs.val.map (fun v => nats v.val) := by
  unfold admit at h
  h5i_invert h
  have h1 := post_of_ok (bytes_eq_spec _ _) ‹bytes.bytes_eq _ _ = ok _›
  have h2 := post_of_ok (contains_spec _ _) ‹bytes.contains _ _ = ok _›
  simp_all [alloc.vec.Vec.deref]

theorem load_link_facts_ok {env : DelegationEnv} {lid : Slice U8} {f : LinkFacts}
    (h : load_link_facts env lid = ok f) (hr : f.refusal = none) :
    ∃ l ∈ env.links.val, nats l.id.val = nats lid.val ∧ l.revoked = false ∧
      f.user_email = l.user_email ∧ f.installation_id = l.installation_id ∧
      ∃ i ∈ env.installations.val, nats i.id.val = nats l.installation_id.val ∧ i.revoked = false ∧
        f.orgs = i.served_orgs := by
  unfold load_link_facts at h
  h5i_invert h
  · simp [from_rows, refused] at h; subst h; simp at hr
  · have hf := post_of_ok (find_link_spec _ _) ho
    have hm := List.mem_of_find?_eq_some hf.symm
    have hp := List.find?_some hf.symm
    simp only [alloc.vec.Vec.deref, decide_eq_true_eq] at hm hp
    refine ⟨link1, by simpa using hm, by simpa using hp, ?_⟩
    have hi := post_of_ok (find_installation_spec _ _) hinstallation
    rcases installation with _ | i
    · simp at hx; subst hx
      simp only [from_rows] at h
      split at h <;> (simp at h; subst h; simp at hr)
    · simp only at hx
      have hc : ∀ v, alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) i.served_orgs = ok v →
          v = i.served_orgs := by
        intro v hv
        rw [vec_clone_ok _ _ (fun x => u8vec_clone x)] at hv
        simpa using hv.symm
      h5i_invert hx
      have ho1 := hc _ horgs1; subst ho1
      have him := List.mem_of_find?_eq_some hi.symm
      have hip := List.find?_some hi.symm
      simp only [alloc.vec.Vec.deref, decide_eq_true_eq] at him hip
      simp only [from_rows] at h
      by_cases h1 : link1.revoked = true
      · simp [h1] at h; subst h; simp at hr
      · by_cases h2 : i.revoked = true
        · simp [h1, h2] at h; subst h; simp at hr
        · simp [h1, h2] at h; subst h
          refine ⟨by simpa using h1, rfl, rfl, i, by simpa using him, by simpa using hip, by simpa using h2, rfl⟩


theorem validate_delegated_ok {env : DelegationEnv} {o : VerifyOracle} {now : I64} {t path pfx : Slice U8}
    {m : Method} {d : Delegated} (h : validate_delegated env o now t path pfx m = ok (.Ok d)) :
    ∃ c, verify t o now = ok (.Ok c) ∧ env.slack_on = true ∧ env.keys_ok = true ∧
      nats c.org.val ∉ env.disabled_orgs.val.map (fun v => nats v.val) ∧
      check_route path pfx m c = ok (.Ok ()) ∧
      (∃ l ∈ env.links.val, nats l.id.val = nats c.lid.val ∧ l.revoked = false ∧
        nats l.user_email.val = nats c.sub.val ∧
        ∃ i ∈ env.installations.val, nats i.id.val = nats l.installation_id.val ∧ i.revoked = false ∧
          nats c.org.val ∈ i.served_orgs.val.map (fun v => nats v.val)) ∧
      (∃ u ∈ env.members.val, nats u.org.val = nats c.org.val ∧ nats u.email.val = nats c.sub.val ∧
        d.user_role = u.role ∧ d.is_internal_user = !u.is_external ∧
        ¬ (u.is_external = true ∧ nats u.email.val ∈ env.denied.val.map (fun v => nats v.val))) ∧
      d.user_email = c.sub ∧ d.org = c.org ∧ d.link_id = c.lid ∧ d.scope = c.scope := by
  unfold validate_delegated at h
  h5i_invert h

  all_goals
    obtain ⟨h1, h2, h3, h4⟩ := verified_claims_ok hr
    obtain ⟨hr0, hue, horg⟩ := admit_ok hr2
    obtain ⟨l, hl, hlid, hlr, hfe, hfi, i, hi, hiid, hir, hfo⟩ := load_link_facts_ok hfacts hr0
    have hm := post_of_ok (find_member_spec _ _ _) ho1
    have hum := List.mem_of_find?_eq_some hm.symm
    have hup := List.find?_some hm.symm
    simp only [alloc.vec.Vec.deref, Bool.and_eq_true, decide_eq_true_eq] at hum hup h4 hlid
    refine ⟨c, h3, h1, h2, by simpa using h4, by cases a; exact hr1,
      ⟨l, hl, by simpa using hlid, hlr, by rw [← hfe]; exact hue, i, hi, by simpa using hiid, hir,
        by rw [← hfo]; exact horg⟩, ⟨u, by simpa using hum, by simpa using hup.1, by simpa using hup.2, rfl, ?_, ?_⟩,
      rfl, rfl, rfl, rfl⟩
  · simp [hc_1]
  · have := post_of_ok (contains_spec _ _) hb
    simp_all [alloc.vec.Vec.deref]
  · simp_all
  · simp_all

end openobserve_kernel.Verified
