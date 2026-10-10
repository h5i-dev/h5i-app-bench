import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit

namespace artifactkeeper_kernel.Verified.ArtifactkeeperRuleOverridesRole

/-! ## Byte strings -/

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    strs.bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold strs.bytes_eq strs.bytes_eq_loop
  by_cases hl : a.val.length = b.val.length
  · have : ¬ (Slice.len a != Slice.len b) = true := by simp; scalar_tac
    simp only [this]
    apply WP.spec_mono (loop_search (a.val.zip b.val) (fun p => p.1 != p.2) id (fun _ _ => false) true _ ?_ 0#usize (by simp))
    · intro r hr
      simp only [id] at hr
      have := search_all _ _ _ hr
      rw [this, show (fun x : U8 × U8 => !(x.1 != x.2)) = (fun p => decide (p.1 = p.2)) from by funext p; by_cases h : p.1 = p.2 <;> simp [h],
        zip_all_eq _ _ hl]
    · intro j hj
      unfold strs.bytes_eq_loop.body
      step*
      · simp only [SearchStep, id, List.length_zip, List.getElem_zip]
        left
        refine ⟨by scalar_tac, by simp_all, trivial⟩
      · simp only [SearchStep, List.length_zip, List.getElem_zip]
        refine ⟨by scalar_tac, by simp_all, by scalar_tac⟩
      · simp only [SearchStep, id, List.length_zip]
        right; refine ⟨by scalar_tac, trivial⟩
  · have : (Slice.len a != Slice.len b) = true := by simp; scalar_tac
    simp only [this, if_true, WP.spec_ok]
    simp; intro h; exact hl (h ▸ rfl)

@[step] theorem any_eq_spec (l : Slice (alloc.vec.Vec U8)) (s : Slice U8) :
    strs.any_eq l s ⦃ r => r = l.val.any (fun x => decide (x.val = s.val)) ⦄ := by
  unfold strs.any_eq strs.any_eq_loop
  h5i_search_any l.val (fun x : alloc.vec.Vec U8 => decide (x.val = s.val))
  all_goals (refine ⟨by scalar_tac, ?_⟩; simpa [vec_deref_val] using b_post)

@[step] theorem project_of_spec (db : tables.Db) (repo : U64) :
    permission.project_of db repo ⦃ o => o = (db.repositories.val.find? (fun r => r.id = repo)).bind (·.project_id) ⦄ := by
  unfold permission.project_of permission.project_of_loop
  apply WP.spec_mono (loop_search db.repositories.val (fun r => decide (r.id = repo)) id (fun _ r => r.project_id) none _ ?_ 0#usize (by simp))
  · intro r hr
    simp only [id] at hr
    rw [hr, searchFrom_findD (f := fun r : tables.Repository => r.project_id) (d := none)]
    cases h : List.find? (fun r => decide (r.id = repo)) db.repositories.val <;> simp [h]
  · intro j hj
    unfold permission.project_of_loop.body
    step*
    · left; exact ⟨by scalar_tac, by simp_all, by simp_all⟩
    · exact ⟨by scalar_tac, by simp_all, by scalar_tac⟩
    · right; exact ⟨by scalar_tac, rfl⟩

@[step] theorem is_member_spec (db : tables.Db) (u g : U64) :
    permission.is_member db u g ⦃ r => r = db.members.val.any (fun m => decide (m = (u, g))) ⦄ := by
  unfold permission.is_member permission.is_member_loop
  h5i_search_any db.members.val (fun m : U64 × U64 => decide (m = (u, g)))
  all_goals (refine ⟨by scalar_tac, ?_⟩; intro heq; rw [heq] at i2_post; simp only [Prod.mk.injEq] at i2_post; obtain ⟨h1, h2⟩ := i2_post; subst_vars; simp_all)

theorem masked_dec {ty : UScalarTy} (n a m : UScalar ty) (k : Nat) (hm : m.bv = BitVec.allOnes _ <<< k) (e : Nat)
    (he : k = e) : decide (n &&& m = a &&& m) = (n.val / 2 ^ e == a.val / 2 ^ e) := by
  subst he
  by_cases h : n.val / 2 ^ k = a.val / 2 ^ k <;> simp [masked_eq_iff n a m k hm, h]

@[step] theorem contains_spec (c : net.CidrRange) (ip : net.IpAddr) :
    net.CidrRange.contains c ip ⦃ r => r = inCidr c ip ⦄ := by
  obtain ⟨nw, pl⟩ := c
  unfold net.CidrRange.contains inCidr
  cases nw <;> cases ip <;> simp only
  all_goals h5i_steps
  all_goals rw [UScalar.eq_of_val_eq i_post, UScalar.eq_of_val_eq i1_post]
  · subst_vars; exact masked_dec _ _ _ 32 (by decide) _ (by simp)
  · exact masked_dec _ _ _ 0 (by rw [BitVec.shiftLeft_zero]; exact u32_max_bv) _ (by scalar_tac)
  · refine masked_dec _ _ _ x.val (by rw [mask_post1, u32_max_bv]) _ ?_
    subst_vars; simp at *; scalar_tac
  · subst_vars; exact masked_dec _ _ _ 128 (by decide) _ (by simp)
  · exact masked_dec _ _ _ 0 (by rw [BitVec.shiftLeft_zero]; exact u128_max_bv) _ (by scalar_tac)
  · refine masked_dec _ _ _ x.val (by rw [mask_post1, u128_max_bv]) _ ?_
    subst_vars; simp at *; scalar_tac

@[step] theorem any_contains_spec (rs : Slice net.CidrRange) (ip : net.IpAddr) :
    net.any_contains rs ip ⦃ r => r = rs.val.any (fun c => inCidr c ip) ⦄ := by
  unfold net.any_contains net.any_contains_loop
  h5i_search_any rs.val (fun c => inCidr c ip)

@[step] theorem ip_condition_spec (p : tables.Permission) (ip : Option net.IpAddr) :
    permission.ip_condition p ip ⦃ r => r = true ↔ IpOk p ip ⦄ := by
  unfold permission.ip_condition IpOk
  rcases h : p.allowed_cidrs with _ | cs <;> rcases ip with _ | a <;> simp only
  all_goals step*
  all_goals simp_all [vec_deref_val]

theorem nats_eq_iff (l l' : List U8) : nats l = nats l' ↔ l = l' := by
  unfold nats
  constructor
  · intro h
    exact List.map_injective_iff.2 (fun x y hxy => by scalar_tac) h
  · intro h; rw [h]

theorem lit_user : lit "user" = nats [117#u8, 115#u8, 101#u8, 114#u8] := by decide +kernel
theorem lit_group : lit "group" = nats [103#u8, 114#u8, 111#u8, 117#u8, 112#u8] := by decide +kernel
theorem lit_sa : lit "service_account" = nats [115#u8, 101#u8, 114#u8, 118#u8, 105#u8, 99#u8, 101#u8, 95#u8, 97#u8,
          99#u8, 99#u8, 111#u8, 117#u8, 110#u8, 116#u8] := by decide +kernel
theorem lit_repository : lit "repository" = nats [114#u8, 101#u8, 112#u8, 111#u8, 115#u8, 105#u8, 116#u8, 111#u8,
          114#u8, 121#u8] := by decide +kernel
theorem lit_project : lit "project" = nats [112#u8, 114#u8, 111#u8, 106#u8, 101#u8, 99#u8, 116#u8] := by decide +kernel
theorem lit_admin : lit "admin" = nats [97#u8, 100#u8, 109#u8, 105#u8, 110#u8] := by decide +kernel

@[step] theorem project_is_spec (db : tables.Db) (repo tid : U64) :
    permission.project_is db repo tid ⦃ r => r = true ↔ ProjectOf db repo tid ⦄ := by
  unfold permission.project_is ProjectOf
  step*
  rw [← o_post, ‹o = some _›]; simp

@[step] theorem principal_matches_spec (db : tables.Db) (p : tables.Permission) (u : U64) :
    permission.principal_matches db p u ⦃ r => r = true ↔ PrincipalMatches db p u ⦄ := by
  unfold permission.principal_matches PrincipalMatches
  step*
  all_goals simp_all [lit_user, lit_group, lit_sa, nats_eq_iff, vec_deref_val]

@[step] theorem repo_target_matches_spec (db : tables.Db) (p : tables.Permission) (repo : U64) :
    permission.repo_target_matches db p repo ⦃ r => r = true ↔ OnRepo db p repo ⦄ := by
  unfold permission.repo_target_matches OnRepo
  step*
  all_goals simp_all [lit_repository, lit_project, nats_eq_iff, vec_deref_val]

@[step] theorem applicable_spec (db : tables.Db) (p : tables.Permission) (ip : Option net.IpAddr) (u repo : U64) :
    permission.applicable db p ip u repo ⦃ r => r = true ↔ (PrincipalMatches db p u ∧ OnRepo db p repo ∧ IpOk p ip) ⦄ := by
  unfold permission.applicable
  step*

theorem carries_iff (xs : List (alloc.vec.Vec U8)) (s : List U8) :
    Carries xs (nats s) ↔ xs.any (fun x => decide (x.val = s)) = true := by
  simp [Carries, nats_eq_iff]

section
open Classical

@[step] theorem any_applicable_spec (db : tables.Db) (ip : Option net.IpAddr) (u repo : U64) :
    permission.any_applicable db ip u repo ⦃ r => r = true ↔
      ∃ p ∈ db.permissions.val, PrincipalMatches db p u ∧ OnRepo db p repo ∧ IpOk p ip ⦄ := by
  unfold permission.any_applicable permission.any_applicable_loop
  apply WP.spec_mono (loop_search db.permissions.val
    (fun p => decide (PrincipalMatches db p u ∧ OnRepo db p repo ∧ IpOk p ip)) id (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr
    simp only [id] at hr
    rw [hr, searchFrom_const]
    simp
  · intro j hj
    unfold permission.any_applicable_loop.body
    step*
    · left; exact ⟨by scalar_tac, by simp_all, rfl⟩
    · exact ⟨by scalar_tac, by simp_all, by scalar_tac⟩
    · right; exact ⟨by scalar_tac, rfl⟩

@[step] theorem any_applicable_grants_spec (db : tables.Db) (ip : Option net.IpAddr) (u repo : U64) (a : Slice U8) :
    permission.any_applicable_grants db ip u repo a ⦃ r => r = true →
      ∃ p ∈ db.permissions.val, (PrincipalMatches db p u ∧ OnRepo db p repo ∧ IpOk p ip) ∧
        (Carries p.actions.val (nats a.val) ∨ Carries p.actions.val (lit "admin")) ⦄ := by
  unfold permission.any_applicable_grants permission.any_applicable_grants_loop
  apply WP.spec_mono (loop_search db.permissions.val
    (fun p => decide ((PrincipalMatches db p u ∧ OnRepo db p repo ∧ IpOk p ip) ∧
        (Carries p.actions.val (nats a.val) ∨ Carries p.actions.val (lit "admin")))) id (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr
    simp only [id] at hr
    rw [hr, searchFrom_const]
    simp
  · intro j hj
    unfold permission.any_applicable_grants_loop.body
    step*
    all_goals simp only [SearchStep, id]
    all_goals first
      | (left; refine ⟨by scalar_tac, ?_, trivial⟩; simp_all [carries_iff, lit_admin, vec_deref_val])
      | (refine ⟨by scalar_tac, ?_, by scalar_tac⟩; simp_all [carries_iff, lit_admin, vec_deref_val])
      | (right; exact ⟨by scalar_tac, trivial⟩)

@[step] theorem role_has_spec (db : tables.Db) (rid : U64) (perm : Slice U8) :
    permission.role_has db rid perm ⦃ r => r = true ↔
      ∃ ro ∈ db.roles.val, ro.id = rid ∧ Carries ro.permissions.val (nats perm.val) ⦄ := by
  unfold permission.role_has permission.role_has_loop
  apply WP.spec_mono (loop_search db.roles.val
    (fun ro => decide (ro.id = rid ∧ Carries ro.permissions.val (nats perm.val))) id (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr
    simp only [id] at hr
    rw [hr, searchFrom_const]
    simp
  · intro j hj
    unfold permission.role_has_loop.body
    step*
    all_goals simp only [SearchStep, id]
    all_goals first
      | (left; refine ⟨by scalar_tac, ?_, trivial⟩; simp_all [carries_iff, vec_deref_val])
      | (refine ⟨by scalar_tac, ?_, by scalar_tac⟩; simp_all [carries_iff, vec_deref_val])
      | (right; exact ⟨by scalar_tac, trivial⟩)

@[step] theorem assigned_role_has_spec (db : tables.Db) (u repo : U64) (perm : Slice U8) :
    permission.assigned_role_has db u repo perm ⦃ r => r = true ↔
      ∃ ra ∈ db.role_assignments.val, ra.user_id = u ∧
        (ra.repository_id = some repo ∨ ra.repository_id = none) ∧
        ∃ ro ∈ db.roles.val, ro.id = ra.role_id ∧ Carries ro.permissions.val (nats perm.val) ⦄ := by
  unfold permission.assigned_role_has permission.assigned_role_has_loop
  apply WP.spec_mono (loop_search db.role_assignments.val
    (fun ra => decide (ra.user_id = u ∧ (ra.repository_id = some repo ∨ ra.repository_id = none) ∧
        ∃ ro ∈ db.roles.val, ro.id = ra.role_id ∧ Carries ro.permissions.val (nats perm.val))) id (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr
    simp only [id] at hr
    rw [hr, searchFrom_const]
    simp
  · intro j hj
    unfold permission.assigned_role_has_loop.body
    h5i_steps
    all_goals simp only [SearchStep, id]
    all_goals first
      | (left; refine ⟨by scalar_tac, ?_, trivial⟩; simp_all [carries_iff])
      | (refine ⟨by scalar_tac, ?_, by scalar_tac⟩; simp_all [carries_iff]; try assumption)
      | (right; exact ⟨by scalar_tac, trivial⟩)

end

theorem rule_overrides_role (db : tables.Db) (ip : Option net.IpAddr) (user repo : U64) (a : Slice U8)
    (hp : ∃ p, Applicable db ip user repo p)
    (hn : ∀ p, Applicable db ip user repo p →
      ¬ Carries p.actions.val (nats a.val) ∧ ¬ Carries p.actions.val (lit "admin"))
    (hr : ¬ RoleGrants db user repo (lit "admin")) :
    permission.check_repository_action db ip user repo a false ≠ ok (.Ok true) := by
  intro h
  unfold permission.check_repository_action at h
  h5i_invert h
  all_goals have hsv : nats s.val = lit "admin" := (by
    simp only [lift, ok.injEq] at hs; subst hs; rw [array_to_slice_val, lit_admin]; rfl)
  · exact hr (hsv ▸ (post_of_ok (assigned_role_has_spec db user repo s) howner).1 hc_1)
  · have hb1t : b1 = true := (post_of_ok (any_applicable_spec db ip user repo) hb1).2
      (by obtain ⟨p, hm, h1, h2, h3⟩ := hp; exact ⟨p, hm, h1, h2, h3⟩)
    rw [if_pos hb1t] at hdecided
    obtain ⟨p, hm, hA, hC⟩ := post_of_ok (any_applicable_grants_spec db ip user repo a) hdecided rfl
    have := hn p ⟨hm, hA⟩
    rcases hC with hC | hC
    · exact this.1 hC
    · exact this.2 hC

end artifactkeeper_kernel.Verified.ArtifactkeeperRuleOverridesRole
