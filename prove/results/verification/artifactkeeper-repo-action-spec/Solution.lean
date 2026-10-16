import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP

namespace artifactkeeper_kernel.Solution

attribute [local instance] Classical.propDecidable

-- Evaluate the policy's ASCII literals using kernel reduction.
@[simp] theorem lit_user : lit "user" = [117,115,101,114] := by unfold lit; decide +kernel
@[simp] theorem lit_service : lit "service_account" =
    [115,101,114,118,105,99,101,95,97,99,99,111,117,110,116] := by unfold lit; decide +kernel
@[simp] theorem lit_group : lit "group" = [103,114,111,117,112] := by unfold lit; decide +kernel
@[simp] theorem lit_repository : lit "repository" = [114,101,112,111,115,105,116,111,114,121] := by unfold lit; decide +kernel
@[simp] theorem lit_project : lit "project" = [112,114,111,106,101,99,116] := by unfold lit; decide +kernel
@[simp] theorem lit_admin : lit "admin" = [97,100,109,105,110] := by unfold lit; decide +kernel

h5i_derive_eq tables.Query tables.Query.Insts.CoreCmpPartialEqQuery.eq

@[simp] theorem nats_eq (a b : List U8) : nats a = nats b ↔ a = b := by
  exact (Function.Injective.list_map (fun x y h => UScalar.eq_of_val_eq h)).eq_iff

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    strs.bytes_eq a b ⦃ r => r = decide (nats a.val = nats b.val) ⦄ := by
  unfold strs.bytes_eq
  dsimp only
  split
  · rename_i h
    simp only [WP.spec_ok, nats_eq]
    have hn : a.val ≠ b.val := by intro he; simp [Slice.len, he] at h
    simp [hn]
  · rename_i h
    have hlen : a.val.length = b.val.length := by scalar_tac
    unfold strs.bytes_eq_loop
    apply WP.spec_mono (loop_search (a.val.zip b.val) (fun p => decide (p.1 ≠ p.2))
      id (fun _ _ => false) true _ ?_ 0#usize (by simp))
    · intro r hr
      have he := search_all _ _ _ hr
      simp only [decide_not, Bool.not_not] at he
      simpa [zip_all_eq _ _ hlen] using he
    · intro i hi
      unfold strs.bytes_eq_loop.body
      h5i_step [List.length_zip, hlen, List.getElem_zip]

@[step] theorem any_eq_spec (xs : Slice (alloc.vec.Vec U8)) (a : Slice U8) :
    strs.any_eq xs a ⦃ b => b = decide (Carries xs.val (nats a.val)) ⦄ := by
  classical
  unfold strs.any_eq strs.any_eq_loop
  h5i_search_any xs.val (fun v => decide (nats v.val = nats a.val))
  all_goals simp_all [Carries, vec_deref_val, searchFrom_const]
  all_goals scalar_tac

@[step] theorem fails_spec (db : tables.Db) (q : tables.Query) :
    tables.Db.fails db q ⦃ b => b = decide (q ∈ db.failing.val) ⦄ := by
  unfold tables.Db.fails tables.Db.fails_loop
  h5i_search_any db.failing.val (fun x => decide (x = q))
  all_goals simp_all [any_eq_iff]

@[step] theorem member_spec (db : tables.Db) (u g : U64) :
    permission.is_member db u g ⦃ b => b = decide ((u,g) ∈ db.members.val) ⦄ := by
  unfold permission.is_member permission.is_member_loop
  h5i_search_any db.members.val (fun x => decide (x = (u,g)))
  all_goals try simp_all [any_eq_iff, searchFrom_const]
  all_goals refine ⟨by scalar_tac, ?_⟩
  all_goals simp only [← i2_post, Prod.mk.injEq]
  all_goals scalar_tac

@[step] theorem project_of_spec (db : tables.Db) (r : U64) :
    permission.project_of db r ⦃ o => o =
      (db.repositories.val.find? (fun x => x.id = r)).bind (·.project_id) ⦄ := by
  unfold permission.project_of permission.project_of_loop
  apply WP.spec_mono (loop_search db.repositories.val (fun x => decide (x.id = r))
    id (fun _ x => x.project_id) none _ ?_ 0#usize (by simp))
  · intro o ho
    simp only [id_eq, searchFrom_findD, UScalar.ofNatCore_val_eq, List.drop_zero] at ho
    cases he : db.repositories.val.find? (fun x => decide (x.id = r)) <;> simpa [he] using ho
  · intro i hi
    unfold permission.project_of_loop.body
    h5i_step

@[step] theorem project_is_spec (db : tables.Db) (r p : U64) :
    permission.project_is db r p ⦃ b => b = decide (ProjectOf db r p) ⦄ := by
  unfold permission.project_is
  step*
  all_goals (rename_i h; simp [ProjectOf, ← o_post, h])

@[step] theorem cidr_spec (c : net.CidrRange) (ip : net.IpAddr) :
    net.CidrRange.contains c ip ⦃ b => b = inCidr c ip ⦄ := by
  unfold net.CidrRange.contains
  cases hn : c.network <;> cases ip <;> h5i_steps
  all_goals simp_all [inCidr]
  all_goals rw [Bool.eq_iff_iff]
  all_goals simp only [decide_eq_true_eq, beq_iff_eq]
  all_goals simp_all only [UScalar.eq_equiv_bv_eq]
  all_goals first
    | (simp only [true_iff]; rw [Nat.div_eq_of_lt (by scalar_tac), Nat.div_eq_of_lt (by scalar_tac)])
    | (simp only [show BitVec.ofNat 32 U32.rMax = BitVec.allOnes 32 from rfl,
        show BitVec.ofNat 128 U128.rMax = BitVec.allOnes 128 from rfl,
        BitVec.and_allOnes, ← BitVec.toNat_inj, UScalar.bv_toNat]; done)
    | (simp only [show BitVec.ofNat 32 U32.rMax = BitVec.allOnes 32 from rfl,
        show BitVec.ofNat 128 U128.rMax = BitVec.allOnes 128 from rfl]
       rw [bv_masked_eq_iff, ← BitVec.toNat_inj]
       simp only [BitVec.toNat_ushiftRight, Nat.shiftRight_eq_div_pow, UScalar.bv_toNat])

@[step] theorem any_cidr_spec (cs : Slice net.CidrRange) (ip : net.IpAddr) :
    net.any_contains cs ip ⦃ b => b = decide (∃ c ∈ cs.val, inCidr c ip = true) ⦄ := by
  unfold net.any_contains net.any_contains_loop
  h5i_search_any cs.val (fun c => inCidr c ip)
  all_goals try simp_all [searchFrom_const]

@[step] theorem ip_spec (p : tables.Permission) (ip : Option net.IpAddr) :
    permission.ip_condition p ip ⦃ b => b = decide (IpOk p ip) ⦄ := by
  unfold permission.ip_condition
  h5i_steps
  all_goals simp_all [IpOk, vec_deref_val]

@[step] theorem principal_spec (db : tables.Db) (p : tables.Permission) (u : U64) :
    permission.principal_matches db p u ⦃ b => b = decide (PrincipalMatches db p u) ⦄ := by
  unfold permission.principal_matches
  h5i_steps
  all_goals simp_all [PrincipalMatches, vec_deref_val, nats]

@[step] theorem repo_target_spec (db : tables.Db) (p : tables.Permission) (r : U64) :
    permission.repo_target_matches db p r ⦃ b => b = decide (OnRepo db p r) ⦄ := by
  unfold permission.repo_target_matches
  h5i_steps
  all_goals simp_all [OnRepo, vec_deref_val, nats]

@[step] theorem applicable_spec (db : tables.Db) (p : tables.Permission)
    (ip : Option net.IpAddr) (u r : U64) :
    permission.applicable db p ip u r ⦃ b => b = decide
      (PrincipalMatches db p u ∧ OnRepo db p r ∧ IpOk p ip) ⦄ := by
  unfold permission.applicable
  h5i_steps

@[step] theorem role_has_spec (db : tables.Db) (id : U64) (a : Slice U8) :
    permission.role_has db id a ⦃ b => b = decide
      (∃ r ∈ db.roles.val, r.id = id ∧ Carries r.permissions.val (nats a.val)) ⦄ := by
  unfold permission.role_has permission.role_has_loop
  h5i_search_any db.roles.val (fun r => decide (r.id = id ∧ Carries r.permissions.val (nats a.val)))
  all_goals try simp_all [searchFrom_const, vec_deref_val]
  all_goals scalar_tac

@[step] theorem assigned_role_spec (db : tables.Db) (u r : U64) (a : Slice U8) :
    permission.assigned_role_has db u r a ⦃ b => b = decide (RoleGrants db u r (nats a.val)) ⦄ := by
  unfold permission.assigned_role_has permission.assigned_role_has_loop
  h5i_search_any db.role_assignments.val (fun ra => decide
    (ra.user_id = u ∧ (ra.repository_id = some r ∨ ra.repository_id = none) ∧
      ∃ role ∈ db.roles.val, role.id = ra.role_id ∧ Carries role.permissions.val (nats a.val)))
  all_goals try simp_all [RoleGrants, searchFrom_const]
  all_goals h5i_step [RoleGrants, searchFrom_const]

@[step] theorem any_applicable_spec (db : tables.Db) (ip : Option net.IpAddr) (u r : U64) :
    permission.any_applicable db ip u r ⦃ b => b = decide (∃ p, Applicable db ip u r p) ⦄ := by
  unfold permission.any_applicable permission.any_applicable_loop
  h5i_search_any db.permissions.val (fun p => decide
    (PrincipalMatches db p u ∧ OnRepo db p r ∧ IpOk p ip))
  all_goals try simp_all [Applicable, searchFrom_const]

@[step] theorem any_grants_spec (db : tables.Db) (ip : Option net.IpAddr) (u r : U64) (a : Slice U8) :
    permission.any_applicable_grants db ip u r a ⦃ b => b = decide
      (∃ p, Applicable db ip u r p ∧
        (Carries p.actions.val (nats a.val) ∨ Carries p.actions.val (lit "admin"))) ⦄ := by
  unfold permission.any_applicable_grants permission.any_applicable_grants_loop
  h5i_search_any db.permissions.val (fun p => decide
    (PrincipalMatches db p u ∧ OnRepo db p r ∧ IpOk p ip ∧
      (Carries p.actions.val (nats a.val) ∨ Carries p.actions.val (lit "admin"))))
  all_goals try simp_all [Applicable, searchFrom_const, vec_deref_val, nats, and_assoc]
  all_goals scalar_tac

theorem check_repository_action_spec (db : tables.Db) (ip : Option net.IpAddr) (user repo : U64)
    (a : Slice U8) (hf : tables.Query.RepositoryAction ∉ db.failing.val) :
    ∃ b, permission.check_repository_action db ip user repo a false = ok (.Ok b) ∧
      (b = true ↔ RepoAction db ip user repo (nats a.val)) := by
  have hs : permission.check_repository_action db ip user repo a false ⦃
      o => o = .Ok (decide (RepoAction db ip user repo (nats a.val))) ⦄ := by
    unfold permission.check_repository_action
    h5i_steps
    all_goals simp_all [RepoAction, nats]
  exact ⟨_, eq_ok_of_spec hs, by simp⟩

end artifactkeeper_kernel.Solution
