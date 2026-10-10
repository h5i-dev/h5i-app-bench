import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec
open H5iAppLib hiding lit
namespace kanidm_kernel.Solution

lemma search_filter_entry_deny (ident : Identity) (related_acp : Slice profiles.AccessControlSearchResolved)
    (entry : Entry) (hs : (IsUser ident ∧ ident.scope = .Synchronise) ∨ ∃ s, ident.origin = .Synch s) :
    search_acc.search_filter_entry ident related_acp entry = ok AccessSrchResult.Deny := by
  unfold search_acc.search_filter_entry
  rcases hs with (⟨⟨u, hu⟩, hscope⟩ | ⟨s, hs⟩)
  · simp [hu, identity_impl.access_scope, hscope]
  · simp [hs]

lemma step_denied (asr : AccessSrchResult) (s s' : Bool × Bool × alloc.vec.Vec (alloc.vec.Vec U8))
    (h_denied : s.1 = true)
    (h : (match asr with
      | AccessSrchResult.Deny => ok (true, s.2.1, s.2.2)
      | AccessSrchResult.Grant => ok (s.1, true, s.2.2)
      | AccessSrchResult.Ignore => ok (s.1, s.2.1, s.2.2)
      | AccessSrchResult.Allow attr => do
        let allow2 ← bset.extend s.2.2 attr.deref
        ok (s.1, s.2.1, allow2)) = ok s') :
    s'.1 = true := by
  cases asr with
  | Deny => simp at h; subst h; rfl
  | Grant => simp at h; subst h; exact h_denied
  | Ignore => simp at h; subst h; exact h_denied
  | Allow attr =>
    obtain ⟨allow2, -, h⟩ := bind_tc_eq_ok.1 h
    simp at h; subst h; exact h_denied

lemma apply_search_access_deny (ident : Identity) (related_acp : Slice profiles.AccessControlSearchResolved)
    (entry : Entry) (sr : search_acc.SearchResult)
    (hs : (IsUser ident ∧ ident.scope = .Synchronise) ∨ ∃ s, ident.origin = .Synch s)
    (h : search_acc.apply_search_access ident related_acp entry = ok sr) :
    sr = search_acc.SearchResult.Deny := by
  unfold search_acc.apply_search_access at h
  rw [search_filter_entry_deny ident related_acp entry hs] at h
  simp at h
  obtain ⟨asr1, -, h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨s1, hs1, h⟩ := bind_tc_eq_ok.1 h
  have hs1_denied : s1.1 = true := step_denied asr1 (true, false, alloc.vec.Vec.new _) s1 rfl hs1
  obtain ⟨asr2, -, h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨s2, hs2, h⟩ := bind_tc_eq_ok.1 h
  have hs2_denied : s2.1 = true := step_denied asr2 s1 s2 hs1_denied hs2
  obtain ⟨asr3, -, h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨s3, hs3, h⟩ := bind_tc_eq_ok.1 h
  have hs3_denied : s3.1 = true := step_denied asr3 s2 s3 hs2_denied hs3
  rcases s3 with ⟨denied3, grant3, allow3⟩
  simp [show denied3 = true from hs3_denied] at h
  exact h.symm

lemma filter_entries_loop_body_step (ident : Identity)
    (related_acp : Slice profiles.AccessControlSearchResolved)
    (requested_attrs : Slice (alloc.vec.Vec Std.U8))
    (entries : Slice Entry)
    (hs : (IsUser ident ∧ ident.scope = .Synchronise) ∨ ∃ s, ident.origin = .Synch s)
    (x : alloc.vec.Vec Entry × Std.Usize)
    (hinv : x.1.val = []) :
    ∀ r, access.filter_entries_loop_loop.body ident related_acp requested_attrs entries x.1 x.2 = ok r →
    match r with
    | .done y => y.val = []
    | .cont x' => x'.1.val = [] ∧ entries.val.length - x'.2.val < entries.val.length - x.2.val := by
  intro r hbody
  cases r with
  | done y =>
    unfold access.filter_entries_loop_loop.body at hbody
    by_cases hlt : (x.2 < entries.len)
    · simp [hlt] at hbody
      obtain ⟨e, -, hbody⟩ := bind_tc_eq_ok.1 hbody
      obtain ⟨e1, -, hbody⟩ := bind_tc_eq_ok.1 hbody
      obtain ⟨sr, hsr, hbody⟩ := bind_tc_eq_ok.1 hbody
      have hsr_deny := apply_search_access_deny ident related_acp e1 sr hs hsr
      subst hsr_deny
      obtain ⟨keep, hkeep, hbody⟩ := bind_tc_eq_ok.1 hbody
      simp at hkeep
      subst hkeep
      obtain ⟨allowed_entries1, hallowed, hbody⟩ := bind_tc_eq_ok.1 hbody
      simp at hallowed
      subst hallowed
      obtain ⟨i2, hi2, hbody⟩ := bind_tc_eq_ok.1 hbody
      simp only [ok.injEq] at hbody
      contradiction
    · simp [hlt] at hbody
      subst hbody
      exact hinv
  | cont x' =>
    unfold access.filter_entries_loop_loop.body at hbody
    by_cases hlt : (x.2 < entries.len)
    · simp [hlt] at hbody
      obtain ⟨e, -, hbody⟩ := bind_tc_eq_ok.1 hbody
      obtain ⟨e1, -, hbody⟩ := bind_tc_eq_ok.1 hbody
      obtain ⟨sr, hsr, hbody⟩ := bind_tc_eq_ok.1 hbody
      have hsr_deny := apply_search_access_deny ident related_acp e1 sr hs hsr
      subst hsr_deny
      obtain ⟨keep, hkeep, hbody⟩ := bind_tc_eq_ok.1 hbody
      simp at hkeep
      subst hkeep
      obtain ⟨allowed_entries1, hallowed, hbody⟩ := bind_tc_eq_ok.1 hbody
      simp at hallowed
      subst hallowed
      obtain ⟨i2, hi2, hbody⟩ := bind_tc_eq_ok.1 hbody
      simp only [ok.injEq] at hbody
      injection hbody with hbody
      subst hbody
      refine ⟨hinv, ?_⟩
      have hadd := @UScalar.add_equiv .Usize x.2 1#usize
      rw [hi2] at hadd
      have : x.2.val < entries.val.length := by scalar_tac
      have : i2.val = x.2.val + 1 := by simp [hadd.2.1]
      dsimp only
      omega
    · simp [hlt] at hbody

theorem synchronise_sees_nothing (ctl : AccessControlsInner) (ident : Identity) (f : FilterComp)
    (es : Slice Entry) (out : alloc.vec.Vec Entry)
    (hs : (IsUser ident ∧ ident.scope = .Synchronise) ∨ ∃ s, ident.origin = .Synch s)
    (h : access.filter_entries ctl ident f es = ok (.Ok out)) :
    out.val = [] := by
  unfold access.filter_entries at h
  obtain ⟨requested_attrs, -, h⟩ := bind_tc_eq_ok.1 h
  by_cases hi : (requested_attrs.len = 0#usize)
  · simp [hi] at h
    subst h
    rfl
  · simp [hi] at h
    obtain ⟨related_acp, -, h⟩ := bind_tc_eq_ok.1 h
    obtain ⟨v, hv, h⟩ := bind_tc_eq_ok.1 h
    simp only [ok.injEq, core.result.Result.Ok.injEq] at h
    subst h
    unfold access.filter_entries_loop access.filter_entries_loop_loop at hv
    refine loop_ok
      (body := fun p => access.filter_entries_loop_loop.body ident related_acp.deref requested_attrs.deref es p.1 p.2)
      (Inv := fun p => p.1.val = [])
      (Q := fun y => y.val = [])
      (μ := fun p => es.val.length - p.2.val)
      ?_
      (alloc.vec.Vec.new Entry, 0#usize)
      v
      rfl
      hv
    intro ⟨ae, i⟩ r hinv hbody
    have hstep := filter_entries_loop_body_step ident related_acp.deref requested_attrs.deref es hs (ae, i) hinv r hbody
    cases r with
    | done y => exact hstep
    | cont x' => exact hstep

end kanidm_kernel.Solution
