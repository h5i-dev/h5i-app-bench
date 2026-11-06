import Verified.RouteScope
/-! `core::auth::org_from_path` and the `AuthExtractor` org, and why a route the
delegated check admits names the same org for the permission check. -/
open Aeneas Aeneas.Std Result openobserve_kernel openobserve_kernel.Spec openobserve_kernel.Verified
open H5iAppLib hiding lit
open openobserve_kernel.delegation

namespace openobserve_kernel.Verified

theorem splitSlash_v2 (x : List Nat) : splitSlash ([118, 50, 47] ++ x) = [118, 50] :: splitSlash x := by
  simp [splitSlash, splitAcc]

theorem splitAcc_eq (cur l : List Nat) :
    splitAcc cur l = (cur ++ l.takeWhile (· ≠ 47)) ::
      (match l.dropWhile (· ≠ 47) with | [] => [] | _ :: r => splitAcc [] r) := by
  induction l generalizing cur with
  | nil => simp [splitAcc]
  | cons c cs ih =>
    by_cases h : c = 47
    · subst h; simp [splitAcc]
    · simp only [splitAcc, h, if_false, List.takeWhile_cons, List.dropWhile_cons, ne_eq, not_false_eq_true,
        decide_true, if_true]
      rw [ih]; simp

theorem v2_head {l : List Nat} {o : List Nat} {r : List (List Nat)}
    (h : splitSlash l = [118, 50] :: o :: r) : [118, 50, 47] <+: l := by
  unfold splitSlash at h
  rw [splitAcc_eq] at h
  simp only [List.nil_append, List.cons.injEq] at h
  obtain ⟨h1, h2⟩ := h
  have hl := List.takeWhile_append_dropWhile (p := fun x => decide (x ≠ 47)) (l := l)
  split at h2
  · cases h2
  · rename_i a rest hd
    have ha : a = 47 := by
      have := List.head?_dropWhile_not (fun x => decide (x ≠ 47)) l
      rw [hd] at this
      simpa using this
    subst ha
    rw [← hl, h1, hd]
    exact ⟨rest, rfl⟩

def v2ModuleOk (r : SRoute) : Bool :=
  match r.segs[1]? with
  | some (SSeg.lit l) => decide (l ∈ v2OrgModules)
  | _ => false

theorem tables_v2_module : ∀ r ∈ assistantScope ++ slackActionScope, r.v2 = true → v2ModuleOk r = true := by
  decide

theorem v2ModuleOk_iff {r : SRoute} (h : v2ModuleOk r = true) : ∃ l, r.segs[1]? = some (.lit l) ∧ l ∈ v2OrgModules := by
  unfold v2ModuleOk at h
  split at h
  · exact ⟨_, ‹_›, by simpa using h⟩
  · cases h

theorem orgFromPath_head {v : List Nat} {t : List (List Nat)} (hv : v ≠ [118, 50]) : orgFromPath (v :: t) = v := by
  rcases t with _ | ⟨a, _ | ⟨b, t⟩⟩ <;> simp [orgFromPath, hv]

theorem orgFromPath_v2 {a b : List Nat} {t : List (List Nat)} (hb : b ∈ v2OrgModules) :
    orgFromPath ([118, 50] :: a :: b :: t) = a := by
  simp [orgFromPath, hb]

theorem dropCond_head (v : List Nat) (t : List (List Nat)) :
    ∃ t', (if 1 < (v :: t).length ∧ (v :: t).getLast? = some [] then (v :: t).dropLast else v :: t) = v :: t' := by
  split
  · rcases t with _ | ⟨a, t⟩
    · simp at *
    · exact ⟨(a :: t).dropLast, by simp [List.dropLast_cons₂]⟩
  · exact ⟨t, rfl⟩

theorem dropCond_v2 (a b : List Nat) (t : List (List Nat)) (hb : b ≠ []) :
    ∃ t', (if 1 < ([118, 50] :: a :: b :: t).length ∧ ([118, 50] :: a :: b :: t).getLast? = some []
      then ([118, 50] :: a :: b :: t).dropLast else [118, 50] :: a :: b :: t) = [118, 50] :: a :: b :: t' := by
  split
  · rename_i hc
    rcases t with _ | ⟨c, t⟩
    · simp at hc; exact absurd hc hb
    · exact ⟨(c :: t).dropLast, by simp [List.dropLast_cons₂]⟩
  · exact ⟨t, rfl⟩

theorem checkRoute_org_consistent {path pfx : List Nat} {m : Method} {org scope : List Nat}
    (h : checkRoute path pfx m org scope = .Ok ()) : extractorOrg path = org := by
  obtain ⟨-, hpo, routes, hr, hin⟩ := checkRoute_ok h
  obtain ⟨-, r, hrm, -, hv2, hseg⟩ := inScope_true hin
  have hrt := scopeRoutes_sub hr r hrm
  unfold extractorOrg
  dsimp only
  generalize relativePath path = rel at hpo hv2 hseg ⊢
  by_cases hp : [118, 50, 47] <+: rel
  · obtain ⟨x, rfl⟩ := hp
    have hrv : r.v2 = true := by simpa using hv2
    obtain ⟨l, hl1, hlm⟩ := v2ModuleOk_iff (tables_v2_module r hrt hrv)
    rw [if_pos ⟨x, rfl⟩] at hseg
    simp only [List.cons_append, List.nil_append, List.drop_succ_cons, List.drop_zero] at hseg
    have hb := segsMatch_lit hseg hl1
    rw [splitSlash_v2]
    unfold pathOrg at hpo
    rw [splitSlash_v2] at hpo
    rcases hcx : splitSlash x with _ | ⟨a, _ | ⟨b, t⟩⟩
    · exact absurd hcx (splitSlash_ne_nil _)
    · rw [hcx] at hb; simp at hb
    · rw [hcx] at hb hpo
      simp only [List.getElem?_cons_succ, List.getElem?_cons_zero, Option.some.injEq] at hb
      subst hb
      have hne : b ≠ [] := by intro h; subst h; revert hlm; decide
      obtain ⟨t', ht'⟩ := dropCond_v2 a b t hne
      rw [ht', orgFromPath_v2 hlm]
      simp only [if_true] at hpo
      split at hpo
      · exact Option.some.inj hpo
      · cases hpo
  · rcases hc : splitSlash rel with _ | ⟨v, _ | ⟨o, t⟩⟩
    · exact absurd hc (splitSlash_ne_nil _)
    · unfold pathOrg at hpo; rw [hc] at hpo; simp at hpo
    · have hv : v ≠ [118, 50] := by
        intro hv; subst hv; exact hp (v2_head hc)
      obtain ⟨t', ht'⟩ := dropCond_head v (o :: t)
      rw [ht', orgFromPath_head hv]
      unfold pathOrg at hpo; rw [hc] at hpo
      simp only [hv, if_false] at hpo
      split at hpo
      · exact Option.some.inj hpo
      · cases hpo

@[step] theorem auth_lit_spec (s : Slice U8) : auth.lit s ⦃ v => nats v.val = nats s.val ⦄ := by
  unfold auth.lit; step*; subst s_post; rfl

set_option maxHeartbeats 4000000 in
@[step] theorem v2_org_modules_spec :
    auth.v2_org_modules ⦃ v => v.val.map (fun w => nats w.val) = v2OrgModules ⦄ := by
  unfold auth.v2_org_modules
  h5i_steps
  all_goals simp_all [v2OrgModules, auth.lit, Array.to_slice, Array.make, alloc.vec.Vec.new, nats]
  all_goals scalar_tac

theorem org_from_path_prefix_spec (cols : Slice (alloc.vec.Vec U8)) (n : Usize) (hn : n.val ≤ cols.length) :
    auth.org_from_path_prefix cols n ⦃ r => nats r.val = orgFromPath ((cols.val.map (fun c => nats c.val)).take n.val) ⦄ := by
  unfold auth.org_from_path_prefix
  have hv2 : ∀ h, ((Array.make 2#usize [118#u8, 50#u8] h).to_slice : Slice U8).val = [118#u8, 50#u8] := by
    intro h; simp [Array.to_slice, Array.make]
  have hlen : cols.length = cols.val.length := rfl
  rcases hc : cols.val with _ | ⟨a, _ | ⟨b, _ | ⟨c, t⟩⟩⟩
  · have : n.val = 0 := by have := hn; rw [hlen, hc] at this; simpa using this
    step*
    all_goals (simp_all [nats, orgFromPath]; try omega)
  · rw [hc] at hlen; simp at hlen
    step*
    all_goals first
      | (simp_all [nats, orgFromPath]; done)
      | (have h1 : n.val = 1 := by scalar_tac
         simp_all [nats, orgFromPath])
  · rw [hc] at hlen; simp at hlen
    step*
    all_goals first
      | (simp_all [nats, orgFromPath]; done)
      | (rcases (show n.val = 1 ∨ n.val = 2 by scalar_tac) with h | h <;> simp_all [nats, orgFromPath])
      | (have h : n.val = 0 := by scalar_tac
         simp_all [nats, orgFromPath])
  · rw [hc] at hlen; simp at hlen
    have ha : ∀ h, cols.val[0]'h = a := by intro h; simp [hc]
    have hb : ∀ h, cols.val[1]'h = b := by intro h; simp [hc]
    have hcc : ∀ h, cols.val[2]'h = c := by intro h; simp [hc]
    step*
    all_goals try (have h : n.val = 0 := by scalar_tac
                   subst_vars; rw [h]; simp [nats, orgFromPath])
    all_goals try (have hn3 : n.val < 3 := by scalar_tac
                   first
                   | (exfalso; scalar_tac)
                   | (rcases (show n.val = 1 ∨ n.val = 2 by scalar_tac) with h | h <;>
                       (subst_vars; rw [h]; simp [nats, orgFromPath, ha, hc])))
    all_goals (obtain ⟨k, hk⟩ : ∃ k, n.val = k + 3 := ⟨n.val - 3, by scalar_tac⟩
               rw [hk]
               (try (subst s1_post; simp only [hv2] at b_post))
               simp_all [nats, orgFromPath, alloc.vec.Vec.deref])

@[step] theorem extractor_org_id_spec (path : Slice U8) (hp : path.length < Usize.max) :
    auth.extractor_org_id path ⦃ r => nats r.val = extractorOrg (nats path.val) ⦄ := by
  unfold auth.extractor_org_id
  step*
  · have h := congrArg List.length routed_post
    simp only [nats, List.length_map] at h
    have := relativePath_len (nats path.val); simp only [nats, List.length_map] at this
    have : (routed.deref).length = routed.val.length := by simp [alloc.vec.Vec.deref, Slice.length]
    scalar_tac
  · have hd : nats routed.deref.val = relativePath (nats path.val) := by simpa [alloc.vec.Vec.deref] using routed_post
    rw [hd] at cols_post
    unfold extractorOrg
    dsimp only
    rw [← cols_post]
    have hlen : (cols.val.map (fun w => nats w.val)).length = cols.val.length := by simp
    split
    · rename_i h1
      step*
      rename_i j _ hj
      have hj' : j.val = cols.val.length - 1 := by scalar_tac
      have hlast : (cols.val.map (fun w => nats w.val)).getLast? = some (nats x.val) := by
        rw [List.getLast?_map, List.getLast?_eq_getElem?, x_post]
        simp only [List.getElem?_eq_getElem (show cols.val.length - 1 < cols.val.length by scalar_tac)]
        simp only [Option.map_some, hj']
      by_cases hx : x.len = 0#usize
      · simp only [hx, if_true]
        step*
        apply WP.spec_mono (org_from_path_prefix_spec _ _ (by simp [alloc.vec.Vec.deref] at *; scalar_tac))
        intro r hr; rw [hr]
        have hxe : nats x.val = [] := by
          have : x.val.length = 0 := by scalar_tac
          simp [nats, List.length_eq_zero_iff.1 this]
        have hc1 : 1 < (cols.val.map (fun w => nats w.val)).length := by rw [hlen]; scalar_tac
        have hc2 : (cols.val.map (fun w => nats w.val)).getLast? = some [] := by rw [hlast, hxe]
        rw [if_pos ⟨hc1, hc2⟩, List.dropLast_eq_take, hlen]
        simp [alloc.vec.Vec.deref, *]
      · simp only [hx, if_false]
        apply WP.spec_bind (Pₘ := fun n => n = cols.len) (by simp)
        intro n hn; subst hn
        apply WP.spec_mono (org_from_path_prefix_spec _ _ (by simp [alloc.vec.Vec.deref]))
        intro r hr; rw [hr]
        have hxe : nats x.val ≠ [] := by
          have : x.val.length ≠ 0 := by intro h; apply hx; scalar_tac
          simpa [nats] using this
        rw [if_neg (fun h => hxe (by rw [hlast] at h; simpa using h.2))]
        simp only [alloc.vec.Vec.deref]
        rw [List.take_of_length_le (by simp)]
        simp
    · apply WP.spec_bind (Pₘ := fun n => n = cols.len) (by simp)
      intro n hn; subst hn
      apply WP.spec_mono (org_from_path_prefix_spec _ _ (by simp [alloc.vec.Vec.deref]))
      intro r hr; rw [hr]
      have hc1 : ¬ 1 < (cols.val.map (fun w => nats w.val)).length := by rw [hlen]; scalar_tac
      rw [if_neg (fun h => hc1 h.1)]
      simp only [alloc.vec.Vec.deref]
      rw [List.take_of_length_le (by simp)]
      simp

end openobserve_kernel.Verified
