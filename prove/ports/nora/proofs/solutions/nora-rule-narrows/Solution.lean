import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

namespace nora_kernel.Solution
set_option maxHeartbeats 0
set_option maxRecDepth 100000

lemma is_star_sound (s : Slice U8) (h : is_star s = ok true) :
    nats s.val = lit "*" := by
  unfold is_star at h
  h5i_invert h
  subst_vars
  have hl : s.val.length = 1 := by scalar_tac
  obtain ⟨x, hx⟩ := List.length_eq_one_iff.1 hl
  have hi := slice_index_ok hi1
  simp only [hx, List.length_singleton, UScalar.ofNatCore_val_eq,
    List.getElem_cons_zero] at hi
  obtain ⟨_, hxx⟩ := hi
  rw [hx, hxx]
  have h42 : nats [42#u8] = lit "*" := by decide +kernel
  have heq : i1 = 42#u8 := by simpa using h
  rw [heq]
  exact h42

lemma has_star_sound (s : Slice (alloc.vec.Vec U8))
    (h : has_star s = ok true) : Unrestricted s.val := by
  unfold has_star has_star_loop at h
  apply loop_true_witness _ (fun _ => True) (fun i : Usize => s.val.length - i.val)
    (Unrestricted s.val) ?_ _ trivial h
  intro i r _ hr
  unfold has_star_loop.body at hr
  h5i_invert hr
  all_goals subst_vars
  · intro _
    refine ⟨v, slice_index_ok_mem hv, ?_⟩
    simpa only [alloc.vec.Vec.deref, Slice.from_val] using is_star_sound _ hb
  · h5i_ok_facts
    simp_all [Slice.len]
    omega
  · simp

lemma scope_matches_sound (scope : Slice (alloc.vec.Vec U8)) (ns : Slice U8)
    (h : scope_matches scope ns = ok true) : InScope scope.val ns.val := by
  unfold scope_matches scope_matches_loop at h
  apply loop_true_witness _ (fun _ => True) (fun i : Usize => scope.val.length - i.val)
    (InScope scope.val ns.val) ?_ _ trivial h
  intro i r _ hr
  unfold scope_matches_loop.body at hr
  h5i_invert hr
  all_goals subst_vars
  · intro _
    refine ⟨v, slice_index_ok_mem hv, v.slice.property, ns.property, ?_⟩
    simpa only [Slice.val_from, alloc.vec.Vec.deref] using hb
  · h5i_ok_facts
    simp_all [Slice.len]
    omega
  · simp

lemma enforce_scoped_sound (scopes : alloc.vec.Vec (alloc.vec.Vec (alloc.vec.Vec U8)))
    (ns : Slice U8) (h : enforce_namespace_scope (.Scoped scopes .Enforce) ns = ok (.Ok ())) :
    ∀ s ∈ scopes.val, InScope s.val ns.val := by
  unfold enforce_namespace_scope at h
  h5i_invert h
  subst_vars
  unfold enforce_namespace_scope_loop at hall
  have hAll : ∀ j (hj : j < scopes.val.length), InScope scopes.val[j].val ns.val := by
    apply loop_ok _
      (fun z : Bool × Usize => z.1 = true →
        ∀ j (hj : j < scopes.val.length), j < z.2.val → InScope scopes.val[j].val ns.val)
      (fun b => b = true → ∀ j (hj : j < scopes.val.length), InScope scopes.val[j].val ns.val)
      (fun z => scopes.val.length - z.2.val) ?_ (true, 0#usize) true ?_ hall rfl
    · rintro ⟨all, i⟩ r hInv hr
      unfold enforce_namespace_scope_loop.body at hr
      h5i_invert hr
      all_goals simp only [Prod.fst, Prod.snd, UScalar.ofNatCore_val_eq] at *
      · have hinc := add_ok_val hi2
        simp only [UScalar.ofNatCore_val_eq] at hinc
        have hlt : i.val < scopes.val.length := by scalar_tac
        refine ⟨?_, by omega⟩
        intro ha j hj hji
        have hbtrue : b = true := by
          cases b <;> simp_all
        have hatrue : all = true := by simpa [hbtrue, ha] using hall1
        by_cases hji' : j < i.val
        · exact hInv hatrue j hj hji'
        · have hjiEq : j = i.val := by omega
          subst j
          obtain ⟨_, hget⟩ := vec_index_ok (by simpa using hv)
          rw [hget]
          simpa only [alloc.vec.Vec.deref, Slice.from_val] using
            scope_matches_sound v.deref ns (by simpa [hbtrue] using hb)
      · intro ha j hj
        apply hInv ha j hj
        have hge : scopes.val.length ≤ i.val := by scalar_tac
        omega
    · simp
  intro s hs
  obtain ⟨j, hj, rfl⟩ := List.mem_iff_getElem.1 hs
  exact hAll j hj

@[step] lemma scope_clone_spec (s : alloc.vec.Vec (alloc.vec.Vec U8)) :
    alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) s
      ⦃ v => v = s ⦄ := by
  rw [vec_clone_eq _ _ (fun x => u8vec_clone x)]
  simp

@[step] lemma scope_to_vec_spec (s : Slice (alloc.vec.Vec U8)) :
    alloc.slice.Slice.to_vec (core.clone.CloneallocvecVec core.clone.CloneU8) s
      ⦃ v => v.val = s.val ⦄ := by
  apply WP.spec_mono (alloc.slice.Slice.to_vec_spec _ s (fun x _ => u8vec_clone x))
  intro v hv
  exact congrArg Slice.val hv.symm

lemma scope_push_keeps {sc sc' : alloc.vec.Vec (alloc.vec.Vec (alloc.vec.Vec U8))}
    {v : alloc.vec.Vec (alloc.vec.Vec U8)} (h : alloc.vec.Vec.push sc v = ok sc') :
    sc'.val = sc.val ++ [v] := by
  unfold alloc.vec.Vec.push at h
  dsimp only at h
  split at h
  · simp only [ok.injEq] at h
    rw [← h]
    simp
  · simp at h

lemma from_scopes_contains_provider (ps : Slice (alloc.vec.Vec U8))
    (rs : Option (alloc.vec.Vec (alloc.vec.Vec U8))) (mode : ScopeEnforcement)
    (auth : NamespaceAuthority) (hu : ¬ Unrestricted ps.val)
    (h : from_oidc_scopes ps rs mode = ok auth) :
    ∃ sc, auth = .Scoped sc mode ∧ ∃ s ∈ sc.val, s.val = ps.val := by
  unfold from_oidc_scopes at h
  obtain ⟨b, hb, h⟩ := bind_tc_eq_ok.1 h
  cases b with
  | true => exact False.elim (hu (has_star_sound ps hb))
  | false =>
    simp only [Bool.false_eq_true, ↓reduceIte] at h
    obtain ⟨sc, hsc, h⟩ := bind_tc_eq_ok.1 h
    obtain ⟨s, hs, hsc⟩ := bind_tc_eq_ok.1 hsc
    have hsval := post_of_ok (scope_to_vec_spec ps) hs
    have hscval := scope_push_keeps hsc
    simp only [vec_new_val, List.nil_append] at hscval
    obtain ⟨sc', hsc', h⟩ := bind_tc_eq_ok.1 h
    have hm : s ∈ sc'.val := by
      cases rs with
      | none =>
        simp only [ok.injEq] at hsc'
        subst sc'
        simp [hscval]
      | some r =>
        obtain ⟨b', hb', hsc'⟩ := bind_tc_eq_ok.1 hsc'
        cases b' with
        | true =>
          simp only [↓reduceIte, ok.injEq] at hsc'
          subst sc'
          simp [hscval]
        | false =>
          simp only [Bool.false_eq_true, ↓reduceIte] at hsc'
          obtain ⟨v, hv, hpush⟩ := bind_tc_eq_ok.1 hsc'
          rw [scope_push_keeps hpush, hscval]
          simp
    have hn : ¬ sc'.len = 0#usize := by
      intro hz
      have hzval : sc'.val.length = 0 := by scalar_tac
      have : sc'.val = [] := List.length_eq_zero_iff.1 hzval
      simp [this] at hm
    simp only [if_neg hn, ok.injEq] at h
    exact ⟨sc', h.symm, s, hm, hsval⟩

lemma validate_claims_scope (p : OidcProvider) (c : Claims) (val : OidcIdentity)
    (h : validate_claims p c = ok (.Ok val)) :
    val.namespace_scope = p.namespace_scope ∧
      val.namespace_scope_enforcement = p.namespace_scope_enforcement := by
  unfold validate_claims at h
  cases hi : c.iat <;> cases he : c.exp
  all_goals simp only [hi, he] at h
  all_goals h5i_invert h
  all_goals try cases_type* Prod
  all_goals try dsimp only at h
  all_goals rw [eq_ok_of_spec (scope_clone_spec p.namespace_scope)] at h
  all_goals simp at h
  all_goals rw [← h]
  all_goals exact ⟨rfl, rfl⟩

lemma namespace_check_success (authority : NamespaceAuthority) (ns : alloc.vec.Vec U8) (x : Reply)
    (h : (do
      let r1 ← enforce_namespace_scope authority ns.deref
      let cf1 ← core.result.Result.Insts.CoreOpsTry.branch r1
      match cf1 with
      | .Continue _ => ok (core.result.Result.Ok Reply.Allowed)
      | .Break residual =>
        core.result.Result.Insts.CoreOpsTry_traitFromResidualResult.from_residual
          Reply (core.convert.FromSame Error) residual) = ok (.Ok x)) :
    enforce_namespace_scope authority ns.deref = ok (.Ok ()) := by
  h5i_invert h
  cases_type* Unit
  assumption

lemma authority_check_provider (val : OidcIdentity) (req : Request) (ns : alloc.vec.Vec U8) (x : Reply)
    (hm : val.namespace_scope_enforcement = .Enforce)
    (hn : req.namespace = some ns) (hu : ¬ Unrestricted val.namespace_scope.val)
    (h : (do
      let s := alloc.vec.Vec.deref val.namespace_scope
      let authority ← from_oidc_scopes s val.rule_namespace_scope val.namespace_scope_enforcement
      match req.namespace with
      | none => ok (core.result.Result.Ok Reply.Allowed)
      | some ns =>
        let s1 := alloc.vec.Vec.deref ns
        let r1 ← enforce_namespace_scope authority s1
        let cf1 ← core.result.Result.Insts.CoreOpsTry.branch r1
        match cf1 with
        | .Continue _ => ok (core.result.Result.Ok Reply.Allowed)
        | .Break residual =>
          core.result.Result.Insts.CoreOpsTry_traitFromResidualResult.from_residual
            Reply (core.convert.FromSame Error) residual) = ok (.Ok x)) :
    InScope val.namespace_scope.val ns.val := by
  dsimp only at h
  obtain ⟨auth, hauth, h⟩ := bind_tc_eq_ok.1 h
  rw [hn] at h
  have henforce := namespace_check_success auth ns x h
  rw [hm] at hauth
  obtain ⟨sc, rfl, s, hs, hsval⟩ := from_scopes_contains_provider
    val.namespace_scope.deref val.rule_namespace_scope .Enforce auth
    (by simpa only [alloc.vec.Vec.deref, Slice.from_val] using hu) hauth
  have hinscope := enforce_scoped_sound sc ns.deref henforce s hs
  simpa only [alloc.vec.Vec.deref, Slice.from_val, hsval] using hinscope

theorem provider_ceiling (p : OidcProvider) (c : Claims) (r : Request) (x : Reply) (ns : alloc.vec.Vec U8)
    (h : transition p c r = ok (.Ok x)) (he : p.namespace_scope_enforcement = .Enforce)
    (hn : r.namespace = some ns) (hu : ¬ Unrestricted p.namespace_scope.val) :
    InScope p.namespace_scope.val ns.val := by
  unfold transition at h
  obtain ⟨rc, hrc, h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨cf, hcf, h⟩ := bind_tc_eq_ok.1 h
  cases rc with
  | Err e =>
    simp [core.result.Result.Insts.CoreOpsTry.branch] at hcf
    subst cf
    simp at h
  | Ok val =>
    simp [core.result.Result.Insts.CoreOpsTry.branch] at hcf
    subst cf
    obtain ⟨hscope, hmode⟩ := validate_claims_scope p c val hrc
    have h_mode : val.namespace_scope_enforcement = .Enforce := hmode.trans he
    have hu' : ¬ Unrestricted val.namespace_scope.val := by simpa [hscope] using hu
    have hfinish := authority_check_provider val r ns x h_mode hn hu'
    obtain ⟨writes, hwrites, h⟩ := bind_tc_eq_ok.1 h
    cases writes with
    | false =>
      simp only [Bool.false_eq_true, ↓reduceIte] at h
      by_cases hadmin : r.is_admin
      · simp only [if_pos hadmin] at h
        obtain ⟨b, hb, h⟩ := bind_tc_eq_ok.1 h
        cases b <;> simp only [Bool.false_eq_true, ↓reduceIte] at h
        · simp at h
        · simpa only [hscope] using hfinish h
      · simp only [if_neg hadmin] at h
        simpa only [hscope] using hfinish h
    | true =>
      simp only [↓reduceIte] at h
      obtain ⟨b, hb, h⟩ := bind_tc_eq_ok.1 h
      cases b <;> simp only [Bool.false_eq_true, ↓reduceIte] at h
      · simp at h
      · by_cases hadmin : r.is_admin
        · simp only [if_pos hadmin] at h
          obtain ⟨b1, hb1, h⟩ := bind_tc_eq_ok.1 h
          cases b1 <;> simp only [Bool.false_eq_true, ↓reduceIte] at h
          · simp at h
          · simpa only [hscope] using hfinish h
        · simp only [if_neg hadmin] at h
          simpa only [hscope] using hfinish h

lemma match_role_scope (p : OidcProvider) (s : Slice U8) (o)
    (h : match_role p s = ok o) :
    ∀ role sc, o = some (role, sc) →
      ∃ k, ∃ hk : k < p.role_rules.val.length,
        (∀ j (hj : j < k), glob_match (p.role_rules.val[j]).pattern.deref s = ok false) ∧
        glob_match (p.role_rules.val[k]).pattern.deref s = ok true ∧
        sc = (p.role_rules.val[k]).namespace_scope := by
  unfold match_role match_role_loop at h
  refine loop_idx_ok _ id p.role_rules.val.length
    (fun i => ∀ j (hj : j < i.val) (hj' : j < p.role_rules.val.length),
      glob_match (p.role_rules.val[j]).pattern.deref s = ok false)
    (fun o => ∀ role sc, o = some (role, sc) →
      ∃ k, ∃ hk : k < p.role_rules.val.length,
        (∀ j (hj : j < k), glob_match (p.role_rules.val[j]).pattern.deref s = ok false) ∧
        glob_match (p.role_rules.val[k]).pattern.deref s = ok true ∧
        sc = (p.role_rules.val[k]).namespace_scope) ?_ _ _ (by simp) (by simp) h
  intro i r hk hle hr
  unfold match_role_loop.body at hr
  have hclone (v : alloc.vec.Vec (alloc.vec.Vec U8)) :
      alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) v = ok v :=
    eq_ok_of_spec (scope_clone_spec v)
  simp only [hclone] at hr
  h5i_invert hr
  all_goals try simp only [alloc.vec.Vec.index_slice_index] at hrule
  all_goals try obtain ⟨hi, rfl⟩ := vec_index_ok hrule
  all_goals first | (simp; done) | skip
  case isTrue.isFalse =>
    simp only [Bool.not_eq_true] at hc_1
    subst hc_1
    have hv := add_ok_val hi2
    refine ⟨fun j hj hj' => ?_, by simp; scalar_tac, by simp; scalar_tac⟩
    by_cases hji : j < i.val
    · exact hk j hji hj'
    · have : j = i.val := by scalar_tac
      subst this
      exact hb
  all_goals
    intro role sc heq
    refine ⟨i.val, hi, fun j hj => hk j hj _, by subst_vars; exact hb, ?_⟩
    all_goals simp_all

lemma validate_claims_role_scope (p : OidcProvider) (c : Claims) (val : OidcIdentity)
    (h : validate_claims p c = ok (.Ok val)) :
    ∃ sv : alloc.vec.Vec U8, sv.val = Spec.subject c ∧
      match_role p sv.deref = ok (some (val.role, val.rule_namespace_scope)) := by
  unfold validate_claims at h
  cases hi : c.iat <;> cases he : c.exp
  all_goals simp only [hi, he] at h
  all_goals h5i_invert h
  all_goals try cases_type* Prod
  all_goals rw [eq_ok_of_spec (scope_clone_spec p.namespace_scope)] at h
  all_goals simp at h
  all_goals refine ⟨subject, ?_, ?_⟩
  all_goals first
    | (rw [← h]; exact ho)
    | (cases hs : c.sub <;> simp only [hs, u8vec_clone, Result.ok.injEq] at hsubject <;>
       subst hsubject <;> simp [Spec.subject, hs])

lemma matched_scope_eq (p : OidcProvider) (c : Claims) (val : OidcIdentity)
    (i : Nat) (hi : i < p.role_rules.val.length)
    (hm : FirstMatch p (Spec.subject c) i)
    (h : validate_claims p c = ok (.Ok val)) :
    val.rule_namespace_scope = (p.role_rules.val[i]).namespace_scope := by
  obtain ⟨sv, hsv, hrole⟩ := validate_claims_role_scope p c val h
  obtain ⟨k, hk, hpre, htrue, hscope⟩ := match_role_scope p sv.deref _ hrole _ _ rfl
  obtain ⟨_, hmPre, hmTrue⟩ := hm
  have hglob (rule : OidcRoleRule) (b : Bool)
      (hg : Glob rule.pattern.val (Spec.subject c) b) :
      glob_match rule.pattern.deref sv.deref = ok b := by
    obtain ⟨hp, hs, hg⟩ := hg
    simpa only [alloc.vec.Vec.deref, hsv] using hg
  have hki : k = i := by
    by_contra hne
    rcases lt_or_gt_of_ne hne with hlt | hgt
    · have hf := hglob _ false (hmPre k hlt)
      have := hf.symm.trans htrue
      simp at this
    · have ht := hglob _ true hmTrue
      have := (hpre i hgt).symm.trans ht
      simp at this
  subst k
  exact hscope

lemma from_scopes_contains_rule (ps : Slice (alloc.vec.Vec U8))
    (rs : alloc.vec.Vec (alloc.vec.Vec U8)) (mode : ScopeEnforcement)
    (auth : NamespaceAuthority) (hu : ¬ Unrestricted rs.val)
    (h : from_oidc_scopes ps (some rs) mode = ok auth) :
    ∃ sc, auth = .Scoped sc mode ∧ rs ∈ sc.val := by
  unfold from_oidc_scopes at h
  obtain ⟨b, hb, h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨sc, hsc, h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨sc', hsc', h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨br, hbr, hsc'⟩ := bind_tc_eq_ok.1 hsc'
  cases br with
  | true =>
    have hu' : Unrestricted rs.val := by
      simpa only [alloc.vec.Vec.deref, Slice.from_val] using (has_star_sound rs.deref hbr)
    exact False.elim (hu hu')
  | false =>
    simp only [Bool.false_eq_true, ↓reduceIte] at hsc'
    rw [eq_ok_of_spec (scope_clone_spec rs)] at hsc'
    simp at hsc'
    have hm : rs ∈ sc'.val := by
      rw [scope_push_keeps hsc']
      simp
    have hn : ¬ sc'.len = 0#usize := by
      intro hz
      have hzval : sc'.val.length = 0 := by scalar_tac
      have : sc'.val = [] := List.length_eq_zero_iff.1 hzval
      simp [this] at hm
    simp only [if_neg hn, ok.injEq] at h
    exact ⟨sc', h.symm, hm⟩

lemma authority_check_rule (val : OidcIdentity) (req : Request) (ns : alloc.vec.Vec U8) (x : Reply)
    (rs : alloc.vec.Vec (alloc.vec.Vec U8)) (hrule : val.rule_namespace_scope = some rs)
    (hm : val.namespace_scope_enforcement = .Enforce)
    (hn : req.namespace = some ns) (hu : ¬ Unrestricted rs.val)
    (h : (do
      let s := alloc.vec.Vec.deref val.namespace_scope
      let authority ← from_oidc_scopes s val.rule_namespace_scope val.namespace_scope_enforcement
      match req.namespace with
      | none => ok (core.result.Result.Ok Reply.Allowed)
      | some ns =>
        let s1 := alloc.vec.Vec.deref ns
        let r1 ← enforce_namespace_scope authority s1
        let cf1 ← core.result.Result.Insts.CoreOpsTry.branch r1
        match cf1 with
        | .Continue _ => ok (core.result.Result.Ok Reply.Allowed)
        | .Break residual =>
          core.result.Result.Insts.CoreOpsTry_traitFromResidualResult.from_residual
            Reply (core.convert.FromSame Error) residual) = ok (.Ok x)) :
    InScope rs.val ns.val := by
  dsimp only at h
  obtain ⟨auth, hauth, h⟩ := bind_tc_eq_ok.1 h
  rw [hn] at h
  have henforce := namespace_check_success auth ns x h
  rw [hm] at hauth
  rw [hrule] at hauth
  obtain ⟨sc, rfl, hs⟩ := from_scopes_contains_rule
    val.namespace_scope.deref rs .Enforce auth hu hauth
  simpa only [alloc.vec.Vec.deref, Slice.from_val] using
    enforce_scoped_sound sc ns.deref henforce rs hs

theorem rule_narrows (p : OidcProvider) (c : Claims) (r : Request) (x : Reply) (ns : alloc.vec.Vec U8)
    (i : Nat) (hi : i < p.role_rules.val.length) (sc : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : transition p c r = ok (.Ok x)) (he : p.namespace_scope_enforcement = .Enforce)
    (hn : r.namespace = some ns) (hm : FirstMatch p (subject c) i)
    (hs : (p.role_rules.val[i]).namespace_scope = some sc) (hu : ¬ Unrestricted sc.val) :
    InScope sc.val ns.val := by
  unfold transition at h
  obtain ⟨rc, hrc, h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨cf, hcf, h⟩ := bind_tc_eq_ok.1 h
  cases rc with
  | Err e =>
    simp [core.result.Result.Insts.CoreOpsTry.branch] at hcf
    subst cf
    simp at h
  | Ok val =>
    simp [core.result.Result.Insts.CoreOpsTry.branch] at hcf
    subst cf
    obtain ⟨hscope, hmode⟩ := validate_claims_scope p c val hrc
    have h_mode : val.namespace_scope_enforcement = .Enforce := hmode.trans he
    have hrule : val.rule_namespace_scope = some sc := (matched_scope_eq p c val i hi hm hrc).trans hs
    have hfinish := authority_check_rule val r ns x sc hrule h_mode hn hu
    obtain ⟨writes, hwrites, h⟩ := bind_tc_eq_ok.1 h
    cases writes with
    | false =>
      simp only [Bool.false_eq_true, ↓reduceIte] at h
      by_cases hadmin : r.is_admin
      · simp only [if_pos hadmin] at h
        obtain ⟨b, hb, h⟩ := bind_tc_eq_ok.1 h
        cases b <;> simp only [Bool.false_eq_true, ↓reduceIte] at h
        · simp at h
        · exact hfinish h
      · simp only [if_neg hadmin] at h
        exact hfinish h
    | true =>
      simp only [↓reduceIte] at h
      obtain ⟨b, hb, h⟩ := bind_tc_eq_ok.1 h
      cases b <;> simp only [Bool.false_eq_true, ↓reduceIte] at h
      · simp at h
      · by_cases hadmin : r.is_admin
        · simp only [if_pos hadmin] at h
          obtain ⟨b1, hb1, h⟩ := bind_tc_eq_ok.1 h
          cases b1 <;> simp only [Bool.false_eq_true, ↓reduceIte] at h
          · simp at h
          · exact hfinish h
        · simp only [if_neg hadmin] at h
          exact hfinish h


end nora_kernel.Solution

