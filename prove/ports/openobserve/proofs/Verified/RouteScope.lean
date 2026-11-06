import Verified.Validate
/-! `seg_matches`, `segments_match`, `in_scope` and `check_route` equal their `Spec` models. -/
open Aeneas Aeneas.Std Result openobserve_kernel openobserve_kernel.Spec openobserve_kernel.Verified
open H5iAppLib hiding lit
open openobserve_kernel.delegation

namespace openobserve_kernel.Verified

@[step] theorem seg_matches_spec (p : Seg) (col : Slice U8) :
    seg_matches p col ⦃ b => b = segOk (toSSeg p) (nats col.val) ⦄ := by
  unfold seg_matches
  cases p <;> simp only [] <;> step*
  all_goals (simp_all [toSSeg, segOk, alloc.vec.Vec.deref, nats, List.length_pos_iff_ne_nil]; try scalar_tac)
  all_goals (intro _ h; simp_all)

theorem zip_all_iff {α β} (l₁ : List α) (l₂ : List β) (f : α × β → Bool) (h : l₁.length = l₂.length) :
    (l₁.zip l₂).all f = true ↔ ∀ k (h1 : k < l₁.length), f (l₁[k], l₂[k]'(h ▸ h1)) = true := by
  rw [List.all_eq_true]
  constructor
  · intro H k hk
    apply H
    rw [List.mem_iff_getElem]
    exact ⟨k, by simp [List.length_zip, h] at *; omega, by simp⟩
  · intro H x hx
    rw [List.mem_iff_getElem] at hx
    obtain ⟨k, hk, rfl⟩ := hx
    simp only [List.length_zip] at hk
    simpa using H k (by omega)

theorem segsMatch_map_iff (ps : List Seg) (cs : List (alloc.vec.Vec U8)) (h : ps.length = cs.length) :
    segsMatch (ps.map toSSeg) (cs.map (fun c => nats c.val)) = true ↔
      ∀ k (h1 : k < ps.length) (h2 : k < cs.length), segOk (toSSeg ps[k]) (nats cs[k].val) = true := by
  unfold segsMatch
  simp only [List.length_map, h, true_and, decide_eq_true_eq, Bool.decide_and, Bool.and_eq_true, decide_true]
  rw [zip_all_iff _ _ _ (by simp [h])]
  simp only [List.length_map, List.getElem_map]
  constructor
  · intro H k h1 h2; exact H k (by omega)
  · intro H k h1; exact H k (by omega) (by omega)

@[step] theorem segments_match_spec (ps : Slice Seg) (cs : Slice (alloc.vec.Vec U8)) :
    segments_match ps cs ⦃ b => b = segsMatch (ps.val.map toSSeg) (cs.val.map (fun c => nats c.val)) ⦄ := by
  unfold segments_match
  simp only []
  split
  · simp only [WP.spec_ok, segsMatch]
    have : ps.val.length ≠ cs.val.length := by scalar_tac
    simp [this]
  · rename_i hl
    have hl' : ps.val.length = cs.val.length := by scalar_tac
    unfold segments_match_loop
    apply loop.spec_decr_nat (measure := fun (j : Usize) => ps.length - j.val)
      (inv := fun j => j.val ≤ ps.length ∧ ∀ k (hk : k < j.val) (h1 : k < ps.val.length) (h2 : k < cs.val.length),
        segOk (toSSeg ps.val[k]) (nats cs.val[k].val) = true)
    · rintro j ⟨hj, hk⟩
      unfold segments_match_loop.body; simp only []
      step*
      · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
        intro k hk' h1 h2
        rcases Nat.lt_succ_iff_lt_or_eq.1 (show k < j.val + 1 by scalar_tac) with h3 | h3
        · exact hk k h3 h1 h2
        · subst h3; simp_all [alloc.vec.Vec.deref]
      · symm; rw [Bool.eq_false_iff]; intro H
        rw [segsMatch_map_iff _ _ hl'] at H
        have := H j.val (by scalar_tac) (by scalar_tac)
        simp_all [alloc.vec.Vec.deref]
      · symm; rw [segsMatch_map_iff _ _ hl']
        intro k h1 h2; exact hk k (by scalar_tac) h1 h2
    · simp

def routeOk (v2 : Bool) (m : Method) (cols : List (List Nat)) (r : ScopeRoute) : Bool :=
  decide (r.v2 = v2) && decide (m ∈ r.methods.val) && segsMatch (r.segments.val.map toSSeg) cols

@[step] theorem in_scope_loop_spec (rs : Slice ScopeRoute) (m : Method) (v2 : Bool) (cols : alloc.vec.Vec (alloc.vec.Vec U8)) :
    in_scope_loop rs m v2 cols 0#usize ⦃ b => b = rs.val.any (routeOk v2 m (cols.val.map (fun c => nats c.val))) ⦄ := by
  unfold in_scope_loop
  apply WP.spec_mono (loop_search rs.val (routeOk v2 m (cols.val.map (fun c => nats c.val))) _root_.id
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro b hb
    rw [_root_.id, searchFrom_const] at hb
    simp only [UScalar.ofNatCore_val_eq, List.drop_zero] at hb
    rw [hb]; cases rs.val.any _ <;> rfl
  · intro i hi
    unfold in_scope_loop.body; simp only []
    step*
    all_goals first
      | (left; exact ⟨by scalar_tac, by simp_all [routeOk, alloc.vec.Vec.deref], rfl⟩)
      | (exact ⟨by scalar_tac, by simp_all [routeOk, alloc.vec.Vec.deref], by scalar_tac⟩)
      | (right; exact ⟨by scalar_tac, rfl⟩)

theorem any_routeOk (rs : List ScopeRoute) (v2 : Bool) (m : Method) (L : List (List Nat)) :
    rs.any (routeOk v2 m L) =
      (rs.map toSRoute).any (fun r => decide (r.v2 = v2) && decide (m ∈ r.methods) && segsMatch r.segs L) := by
  rw [List.any_map]; rfl

@[step] theorem in_scope_spec (rs : Slice ScopeRoute) (m : Method) (p : Slice U8) (hp : p.length < Usize.max) :
    in_scope rs m p ⦃ b => b = inScope (rs.val.map toSRoute) m (nats p.val) ⦄ := by
  unfold in_scope
  step*
  · simp_all [inScope]
  · have hs := lit_slice s s_post
    rw [hs, show nats [118#u8, 50#u8, 47#u8] = [118, 50, 47] from rfl] at o_post
    have hnb : m ≠ Method.Delete := by simp_all
    rcases o with _ | rest
    · simp only []
      step*
      · simp_all [alloc.vec.Vec.deref]
      · have hnp : ¬ [118, 50, 47] <+: nats p.val := by
          intro h; simp [h] at o_post
        rw [b_post, any_routeOk, columns_post]
        simp [inScope, hnp, hnb, x_post, alloc.vec.Vec.deref]
    · simp only []
      have hpp : [118, 50, 47] <+: nats p.val ∧ rest.val = p.val.drop 3 := by
        by_cases h : [118, 50, 47] <+: nats p.val
        · simp [h] at o_post; exact ⟨h, o_post⟩
        · simp [h] at o_post
      step*
      · simp [alloc.vec.Vec.deref, hpp.2]; scalar_tac
      · rw [b_post, any_routeOk, columns_post]
        simp only [inScope, if_pos hpp.1]
        simp [hnb, hpp.2, alloc.vec.Vec.deref, nats, List.map_drop]

theorem relativePath_len (l : List Nat) : (relativePath l).length ≤ l.length := by
  rw [relativePath_eq]; split <;> simp

@[step] theorem check_route_spec (path pfx : Slice U8) (m : Method) (c : Claims) (hp : path.length < Usize.max) :
    check_route path pfx m c ⦃ r => r = checkRoute (nats path.val) (nats pfx.val) m (nats c.org.val) (nats c.scope.val) ⦄ := by
  unfold check_route
  step*
  case hs | hp => (
    have hl : relative.val.length ≤ path.val.length := by
      have h := congrArg List.length relative_post
      simp only [nats, List.length_map] at h
      rw [h]; have := relativePath_len (nats path.val); simp only [nats, List.length_map] at this; exact this
    have : (relative.deref).length = relative.val.length := by simp [alloc.vec.Vec.deref, Slice.length]
    scalar_tac)
  all_goals (
    have hs := lit_slice s ‹_›
    simp only [checkRoute]
    (try simp only [alloc.vec.Vec.deref, nats, hs] at *)
    (try replace o_post := o_post.symm); (try replace o1_post := o1_post.symm)
    (try replace relative_post := relative_post.symm)
    simp_all)

theorem checkRoute_ok {path pfx : List Nat} {m : Method} {org scope : List Nat}
    (h : checkRoute path pfx m org scope = .Ok ()) :
    pfx ≠ [47, 112, 114, 111, 120, 121, 47] ∧ pathOrg (relativePath path) = some org ∧
      ∃ routes, scopeRoutes scope = some routes ∧ inScope routes m (relativePath path) = true := by
  unfold checkRoute at h
  split at h; · cases h
  rename_i hpfx
  split at h; · cases h
  rename_i routes hr
  split at h; · cases h
  rename_i o ho
  split at h; · cases h
  rename_i hor
  split at h; · cases h
  rename_i hin
  simp only [not_not] at hor
  subst hor
  exact ⟨hpfx, ho, routes, hr, by simpa using hin⟩

theorem inScope_true {routes : List SRoute} {m : Method} {p : List Nat} (h : inScope routes m p = true) :
    m ≠ .Delete ∧ ∃ r ∈ routes, m ∈ r.methods ∧
      r.v2 = ([118, 50, 47] <+: p) ∧
      segsMatch r.segs (splitSlash (if [118, 50, 47] <+: p then p.drop 3 else p)) = true := by
  unfold inScope at h
  by_cases hv : [118, 50, 47] <+: p
  · simp only [hv, if_true, Bool.and_eq_true, decide_eq_true_eq, List.any_eq_true] at h
    obtain ⟨hd, r, hr, ⟨⟨h1, h2⟩, h3⟩⟩ := h
    exact ⟨hd, r, hr, h2, by simpa [hv] using h1, by simpa [hv] using h3⟩
  · simp only [hv, if_false, Bool.and_eq_true, decide_eq_true_eq, List.any_eq_true] at h
    obtain ⟨hd, r, hr, ⟨⟨h1, h2⟩, h3⟩⟩ := h
    exact ⟨hd, r, hr, h2, by simpa [hv] using h1, by simpa [hv] using h3⟩

theorem scope_methods : ∀ r ∈ assistantScope ++ slackActionScope, ∀ x ∈ r.methods,
    x = .Get ∨ x = .Post ∨ x = .Patch := by decide

theorem scopeRoutes_sub {s : List Nat} {routes : List SRoute} (h : scopeRoutes s = some routes) :
    ∀ r ∈ routes, r ∈ assistantScope ++ slackActionScope := by
  unfold scopeRoutes at h
  split at h
  · cases h; intro r hr; exact List.mem_append_left _ hr
  · split at h
    · cases h; intro r hr; exact List.mem_append_right _ hr
    · cases h

def alertsLit : List Nat := [97, 108, 101, 114, 116, 115]
def oncallLit : List Nat := [111, 110, 99, 97, 108, 108]

theorem slack_scope_second : ∀ r ∈ slackActionScope,
    r.segs[1]? = some (.lit alertsLit) ∨ r.segs[1]? = some (.lit oncallLit) := by decide

theorem segsMatch_lit {ps : List SSeg} {cs : List (List Nat)} {k : Nat} {l : List Nat}
    (h : segsMatch ps cs = true) (hk : ps[k]? = some (.lit l)) : cs[k]? = some l := by
  unfold segsMatch at h
  simp only [Bool.and_eq_true, decide_eq_true_eq] at h
  obtain ⟨hl, ha⟩ := h
  have hk' : k < ps.length := by
    rcases Nat.lt_or_ge k ps.length with h | h
    · exact h
    · rw [List.getElem?_eq_none h] at hk; cases hk
  rw [List.all_eq_true] at ha
  have hm : (ps[k], cs[k]'(hl ▸ hk')) ∈ ps.zip cs := by
    rw [List.mem_iff_getElem]; exact ⟨k, by simp [hl]; omega, by simp⟩
  have := ha _ hm
  rw [List.getElem?_eq_getElem hk'] at hk
  simp only [Option.some.injEq] at hk
  rw [hk] at this
  simp only [segOk, decide_eq_true_eq] at this
  rw [List.getElem?_eq_getElem (hl ▸ hk'), this]

end openobserve_kernel.Verified
