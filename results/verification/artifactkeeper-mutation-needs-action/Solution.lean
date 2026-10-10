import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit

namespace artifactkeeper_kernel.Solution

set_option maxHeartbeats 2000000
set_option maxRecDepth 10000

h5i_derive_eq Method Method.Insts.CoreCmpPartialEqMethod.eq
h5i_derive_eq tables.Query tables.Query.Insts.CoreCmpPartialEqQuery.eq

attribute [local simp] vec_deref_val
attribute [local simp] u64_val_eq

theorem bytes_eq_raw_spec (a b : Slice U8) :
    strs.bytes_eq a b ⦃ v => v = decide (a.val = b.val) ⦄ := by
  unfold strs.bytes_eq
  dsimp only
  split
  · simp only [WP.spec_ok]
    rename_i h
    have hn : a.val ≠ b.val := by
      intro he
      simp [Slice.len, he] at h
    simp [hn]
  · rename_i h
    have hlen : a.val.length = b.val.length := by
      simpa [Slice.len] using h
    unfold strs.bytes_eq_loop
    apply loop_idx_spec _ (fun i => i) a.val.length
      (fun i => ∀ j, j < i.val → a.val[j]? = b.val[j]?) _ ?_ 0#usize (by simp) (by simp)
    intro i hi hib
    unfold strs.bytes_eq_loop.body
    step*
    · rename_i j _ hj
      refine ⟨?_, by scalar_tac, by scalar_tac⟩
      intro k hk
      by_cases hk' : k < i.val
      · exact hi k hk'
      · have hkval : k = i.val := by scalar_tac
        subst k
        have hlt : i.val < a.val.length := by scalar_tac
        simp only [List.getElem?_eq_getElem hlt,
          List.getElem?_eq_getElem (show i.val < b.val.length by omega), Option.some.injEq]
        simp_all
        scalar_tac
    · have he : a.val = b.val := by
        apply List.ext_getElem?
        intro j
        by_cases hj : j < i.val
        · exact hi j hj
        · simp [List.getElem?_eq_none, show a.val.length ≤ j by scalar_tac,
            show b.val.length ≤ j by scalar_tac]
      simp [he]

@[simp] theorem nats_inj (a b : List U8) : nats a = nats b ↔ a = b := by
  exact ⟨fun h => (List.map_injective_iff (f := fun x : U8 => x.val)).mpr
    (fun _ _ h => UScalar.eq_of_val_eq h) h, congrArg nats⟩

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    strs.bytes_eq a b ⦃ v => v = decide (nats a.val = nats b.val) ⦄ := by
  simpa only [nats_inj] using bytes_eq_raw_spec a b

@[simp] theorem lit_user : lit "user" = [117,115,101,114] := by unfold lit; decide +kernel
@[simp] theorem lit_service : lit "service_account" = [115,101,114,118,105,99,101,95,97,99,99,111,117,110,116] := by unfold lit; decide +kernel
@[simp] theorem lit_group : lit "group" = [103,114,111,117,112] := by unfold lit; decide +kernel
@[simp] theorem lit_repository : lit "repository" = [114,101,112,111,115,105,116,111,114,121] := by unfold lit; decide +kernel
@[simp] theorem lit_project : lit "project" = [112,114,111,106,101,99,116] := by unfold lit; decide +kernel
@[simp] theorem lit_admin : lit "admin" = [97,100,109,105,110] := by unfold lit; decide +kernel
@[simp] theorem lit_write : lit "write" = [119,114,105,116,101] := by unfold lit; decide +kernel
@[simp] theorem lit_delete : lit "delete" = [100,101,108,101,116,101] := by unfold lit; decide +kernel

@[step] theorem any_eq_spec (xs : Slice (alloc.vec.Vec U8)) (s : Slice U8) :
    strs.any_eq xs s ⦃ b => (b = true ↔ Carries xs.val (nats s.val)) ⦄ := by
  unfold strs.any_eq strs.any_eq_loop
  h5i_search_any xs.val (fun x => decide (nats x.val = nats s.val))
  rename_i hr
  rw [← hr]
  simp only [List.any_eq_true, decide_eq_true_eq, Carries]
  constructor
  · rintro ⟨x, hx, he⟩; exact ⟨x, hx, congrArg nats he⟩
  · rintro ⟨x, hx, he⟩
    refine ⟨x, hx, ?_⟩
    exact List.map_injective_iff.mpr (fun _ _ h => UScalar.eq_of_val_eq h) he

@[step] theorem member_spec (db : tables.Db) (u g : U64) :
    permission.is_member db u g ⦃ b => (b = true ↔ (u,g) ∈ db.members.val) ⦄ := by
  unfold permission.is_member permission.is_member_loop
  h5i_search_any db.members.val (fun x => decide (x = (u,g)))
  all_goals try (refine ⟨by scalar_tac, ?_⟩; simp_all [← i2_post])
  rename_i hr
  rw [← hr]
  simp

@[step] theorem project_spec (db : tables.Db) (repo : U64) :
    permission.project_of db repo ⦃ pid =>
      pid = (db.repositories.val.find? (fun r => r.id = repo)).bind (·.project_id) ⦄ := by
  unfold permission.project_of permission.project_of_loop
  apply WP.spec_mono (loop_search db.repositories.val (fun r => r.id = repo)
    id (fun _ r => r.project_id) none _ ?_ 0#usize (by simp))
  · intro pid hp
    rw [id_eq, searchFrom_findD] at hp
    simp only [UScalar.ofNatCore_val_eq, List.drop_zero] at hp
    rw [hp]
    cases db.repositories.val.find? (fun r => r.id = repo) <;> rfl
  · intro i hi
    unfold permission.project_of_loop.body
    h5i_step

@[step] theorem project_is_spec (db : tables.Db) (repo target : U64) :
    permission.project_is db repo target ⦃ b => (b = true ↔ ProjectOf db repo target) ⦄ := by
  unfold permission.project_is
  step* <;> simp_all [ProjectOf, ← o_post]

@[step] theorem principal_spec (db : tables.Db) (p : tables.Permission) (u : U64) :
    permission.principal_matches db p u ⦃ b => (b = true ↔ PrincipalMatches db p u) ⦄ := by
  unfold permission.principal_matches
  step* <;> simp_all [PrincipalMatches, nats, Array.to_slice, Array.make]

@[step] theorem target_spec (db : tables.Db) (p : tables.Permission) (repo : U64) :
    permission.repo_target_matches db p repo ⦃ b => (b = true ↔ OnRepo db p repo) ⦄ := by
  unfold permission.repo_target_matches
  step* <;> simp_all [OnRepo, nats, Array.to_slice, Array.make]

theorem masked_outputs {ty : UScalarTy} (x y m i j : UScalar ty) (k : Nat)
    (hm : m.bv = BitVec.allOnes _ <<< k)
    (hi : i.bv = x.bv &&& m.bv) (hj : j.bv = y.bv &&& m.bv) :
    i = j ↔ x.val / 2^k = y.val / 2^k := by
  rw [UScalar.eq_equiv_bv_eq, hi, hj, hm, bv_masked_eq_iff, ← BitVec.toNat_inj]
  simp [BitVec.toNat_ushiftRight, Nat.shiftRight_eq_div_pow]

@[step] theorem cidr_spec (c : net.CidrRange) (ip : net.IpAddr) :
    net.CidrRange.contains c ip ⦃ b => b = inCidr c ip ⦄ := by
  unfold net.CidrRange.contains
  cases hn : c.network <;> cases ip <;> simp only [hn]
  all_goals h5i_steps
  all_goals try simp_all [inCidr]
  all_goals apply Bool.eq_iff_iff.mpr
  all_goals simp only [decide_eq_true_eq, beq_iff_eq]
  · have he : i = i1 := by scalar_tac
    simp only [he, true_iff]
    rw [Nat.div_eq_of_lt (by scalar_tac), Nat.div_eq_of_lt (by scalar_tac)]
  · have val_iff (a b : U32) : a.val = b.val ↔ a = b :=
      ⟨UScalar.eq_of_val_eq, fun h => congrArg UScalar.val h⟩
    rw [val_iff]
    simp only [UScalar.eq_equiv_bv_eq, i_post1, i1_post1,
      show BitVec.ofNat 32 U32.rMax = BitVec.allOnes 32 from rfl, BitVec.and_allOnes]
  · exact masked_outputs _ _ _ _ _ _
      (by simpa only [UScalarTy.numBits, show BitVec.ofNat 32 U32.rMax = BitVec.allOnes _ from rfl] using mask_post1)
      (by simpa only [mask_post1] using i_post1)
      (by simpa only [mask_post1] using i1_post1)
  · have he : i = i1 := by scalar_tac
    simp only [he, true_iff]
    rw [Nat.div_eq_of_lt (by scalar_tac), Nat.div_eq_of_lt (by scalar_tac)]
  · have val_iff (a b : U128) : a.val = b.val ↔ a = b :=
      ⟨UScalar.eq_of_val_eq, fun h => congrArg UScalar.val h⟩
    rw [val_iff]
    simp only [UScalar.eq_equiv_bv_eq, i_post1, i1_post1,
      show BitVec.ofNat 128 U128.rMax = BitVec.allOnes 128 from rfl, BitVec.and_allOnes]
  · exact masked_outputs _ _ _ _ _ _
      (by simpa only [UScalarTy.numBits, show BitVec.ofNat 128 U128.rMax = BitVec.allOnes _ from rfl] using mask_post1)
      (by simpa only [mask_post1] using i_post1)
      (by simpa only [mask_post1] using i1_post1)

@[step] theorem any_cidr_spec (cs : Slice net.CidrRange) (ip : net.IpAddr) :
    net.any_contains cs ip ⦃ b => (b = true ↔ ∃ c ∈ cs.val, inCidr c ip = true) ⦄ := by
  unfold net.any_contains net.any_contains_loop
  h5i_search_any cs.val (fun c => inCidr c ip)
  rename_i hr
  rw [← hr]
  simp

@[step] theorem ip_spec (p : tables.Permission) (ip : Option net.IpAddr) :
    permission.ip_condition p ip ⦃ b => (b = true ↔ IpOk p ip) ⦄ := by
  unfold permission.ip_condition
  cases hc : p.allowed_cidrs <;> cases ip <;> simp only [hc]
  all_goals step* <;> simp_all [IpOk]

@[step] theorem applicable_spec (db : tables.Db) (p : tables.Permission)
    (ip : Option net.IpAddr) (u repo : U64) :
    permission.applicable db p ip u repo ⦃ b =>
      (b = true ↔ PrincipalMatches db p u ∧ OnRepo db p repo ∧ IpOk p ip) ⦄ := by
  unfold permission.applicable
  step* <;> simp_all

@[step] theorem role_spec (db : tables.Db) (role : U64) (perm : Slice U8) :
    permission.role_has db role perm ⦃ b =>
      (b = true ↔ ∃ r ∈ db.roles.val, r.id = role ∧ Carries r.permissions.val (nats perm.val)) ⦄ := by
  classical
  unfold permission.role_has permission.role_has_loop
  h5i_search_any db.roles.val (fun r => decide (r.id = role ∧ Carries r.permissions.val (nats perm.val)))
  rename_i hr
  rw [← hr]
  simp

@[step] theorem assigned_spec (db : tables.Db) (u repo : U64) (perm : Slice U8) :
    permission.assigned_role_has db u repo perm ⦃ b =>
      (b = true ↔ RoleGrants db u repo (nats perm.val)) ⦄ := by
  classical
  unfold permission.assigned_role_has permission.assigned_role_has_loop
  h5i_search_any db.role_assignments.val (fun ra => decide (ra.user_id = u ∧
    (ra.repository_id = some repo ∨ ra.repository_id = none) ∧
    ∃ r ∈ db.roles.val, r.id = ra.role_id ∧ Carries r.permissions.val (nats perm.val)))
  all_goals try h5i_step
  all_goals try simp_all [SearchStep, RoleGrants]
  rename_i hr
  rw [← hr]
  simp [RoleGrants]

@[step] theorem any_applicable_spec (db : tables.Db) (ip : Option net.IpAddr) (u repo : U64) :
    permission.any_applicable db ip u repo ⦃ b => (b = true ↔ ∃ p, Applicable db ip u repo p) ⦄ := by
  classical
  unfold permission.any_applicable permission.any_applicable_loop
  h5i_search_any db.permissions.val (fun p => decide
    (PrincipalMatches db p u ∧ OnRepo db p repo ∧ IpOk p ip))
  rename_i hr
  rw [← hr]
  simp [Applicable]

@[step] theorem grants_spec (db : tables.Db) (ip : Option net.IpAddr) (u repo : U64) (a : Slice U8) :
    permission.any_applicable_grants db ip u repo a ⦃ b =>
      (b = true ↔ ∃ p, Applicable db ip u repo p ∧
        (Carries p.actions.val (nats a.val) ∨ Carries p.actions.val (lit "admin"))) ⦄ := by
  classical
  unfold permission.any_applicable_grants permission.any_applicable_grants_loop
  h5i_search_any db.permissions.val (fun p => decide
    ((PrincipalMatches db p u ∧ OnRepo db p repo ∧ IpOk p ip) ∧
      (Carries p.actions.val (nats a.val) ∨ Carries p.actions.val (lit "admin"))))
  all_goals try simp_all [SearchStep, nats]
  all_goals try scalar_tac
  rename_i hr
  rw [← hr]
  simp [Applicable, and_assoc]

@[step] theorem fails_spec (db : tables.Db) (q : tables.Query) :
    tables.Db.fails db q ⦃ b => b = db.failing.val.any (fun x => decide (x = q)) ⦄ := by
  unfold tables.Db.fails tables.Db.fails_loop
  h5i_search_any db.failing.val (fun x => decide (x = q))

@[step] theorem check_action_spec (db : tables.Db) (ip : Option net.IpAddr) (u repo : U64) (a : Slice U8) :
    permission.check_repository_action db ip u repo a false ⦃ r =>
      match r with
      | .Ok b => b = true → RepoAction db ip u repo (nats a.val)
      | .Err _ => True ⦄ := by
  unfold permission.check_repository_action
  h5i_steps
  all_goals simp_all [RepoAction, nats]
  all_goals aesop

theorem check_action_sound (db : tables.Db) (ip : Option net.IpAddr) (u repo : U64) (a : Slice U8)
    (h : permission.check_repository_action db ip u repo a false = ok (.Ok true)) :
    RepoAction db ip u repo (nats a.val) := by
  exact post_of_ok (check_action_spec db ip u repo a) h rfl

@[step] theorem lookup_loop_spec (db : tables.Db) (key : Slice U8) :
    middleware.lookup_repo_loop db key 0#usize ⦃ o => o =
      (db.repositories.val.find? (fun r => decide (r.key.val = key.val))).map
        (fun r => (r.id, r.visibility.getD .Private)) ⦄ := by
  unfold middleware.lookup_repo_loop
  apply WP.spec_mono (loop_search db.repositories.val (fun r => decide (r.key.val = key.val))
    id (fun _ r => some (r.id, r.visibility.getD .Private)) none _ ?_ 0#usize (by simp))
  · intro o ho
    simpa only [id_eq, searchFrom_find, UScalar.ofNatCore_val_eq, List.drop_zero] using ho
  · intro i hi
    unfold middleware.lookup_repo_loop.body
    h5i_step
    all_goals try simp_all [SearchStep, Option.getD]

@[step] theorem lookup_spec (db : tables.Db) (key : Slice U8) :
    middleware.lookup_repo db key ⦃ o => o = none ∨ o =
      (db.repositories.val.find? (fun r => decide (r.key.val = key.val))).map
        (fun r => (r.id, r.visibility.getD .Private)) ⦄ := by
  unfold middleware.lookup_repo
  step* <;> simp_all

@[step] theorem to_vec_spec (s : Slice U8) :
    alloc.slice.Slice.to_vec core.clone.CloneU8 s ⦃ a => a.val = s.val ⦄ := by
  apply WP.spec_mono (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 s (by simp))
  intro a ha
  exact (congrArg Slice.val ha).symm

theorem action_spec (m : Method) (hm : isMutation m) :
    paths.action_for_method m ⦃ a => nats a.val = writeAction m ⦄ := by
  rcases hm with rfl | rfl | rfl
  all_goals unfold paths.action_for_method
  all_goals step*
  all_goals simp_all [writeAction, nats]

theorem permission_arm_sound (db : tables.Db) (ip : Option net.IpAddr) (e : AuthExtension)
    (repo : U64) (v : Visibility) (req : http.Request) (hm : isMutation req.method)
    (h : middleware.permission_arm db ip e repo v req true false = ok none) :
    RepoAction db ip e.user_id repo (writeAction req.method) := by
  unfold middleware.permission_arm at h
  h5i_invert h
  have hact := post_of_ok (action_spec req.method hm) haction
  have hgrant := check_action_sound db ip e.user_id repo action.deref (by simpa [hc] using hr)
  simpa only [vec_deref_val, hact] using hgrant

theorem ticket_shape (db : tables.Db) (req : http.Request)
    (x : alloc.vec.Vec resolve.Write × Option AuthExtension × Bool)
    (h : (do
      let (auth, writes) ← resolve.try_ticket db (alloc.vec.Vec.new resolve.Write) req
      let (auth', ticket) ← match auth with
        | none => ok (none, false)
        | some _ => ok (auth, true)
      ok (writes, auth', ticket)) = ok x) :
    x.2.1 = none ∨ x.2.2 = true := by
  replace h := bind_eq_ok.mp h
  rcases h with ⟨⟨auth, writes⟩, _, h⟩
  cases auth with
  | none =>
    change (do let p ← ok (none, false); ok (writes, p.1, p.2)) = ok x at h
    simp only [bind_ok] at h
    have hx := Result.ok.inj h
    subst x
    simp
  | some ext =>
    change (do let p ← ok (some ext, true); ok (writes, p.1, p.2)) = ok x at h
    simp only [bind_ok] at h
    have hx := Result.ok.inj h
    subst x
    simp

theorem mutation_needs_action (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (e : AuthExtension) (t : Bool)
    (r : tables.Repository)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, .Next (some e) t))
    (ha : e.is_admin = false) (hm : isMutation req.method) (hn : ¬ NonMutatingPost req)
    (hr : RepoOf db req r) :
    RepoAction db ip e.user_id r.id (writeAction req.method) := by
  obtain ⟨key, hk, hfind⟩ := hr
  have hpost : Method.Insts.CoreCmpPartialEqMethod.eq req.method .Post = ok false := by
    have hne : req.method ≠ .Post := by rcases hm with hm | hm | hm <;> simp [hm]
    simpa [hne] using eq_ok_of_spec (Method.Insts.CoreCmpPartialEqMethod.eq.spec req.method .Post)
  have hwrite : paths.is_write_method req.method = ok true := by
    rcases hm with h | h | h <;> rw [h] <;> simp [paths.is_write_method]
  unfold middleware.repo_visibility_middleware at h
  dsimp only at h
  rw [hk] at h
  simp (config := { maxSteps := 1000000 }) only [bind_tc_ok, bind_ok, hpost, hwrite, middleware.respond,
    Bool.false_eq_true, Bool.not_false, decide_false, decide_true, reduceIte] at h
  by_cases hlen : key.len = 0#usize
  · rw [if_pos hlen] at h
    simp at h
  · rw [if_neg hlen] at h
    replace h := bind_eq_ok.mp h
    rcases h with ⟨found, hlookup, h⟩
    cases found with
    | none =>
      dsimp only at h
      h5i_invert h
      simp at h
    | some found =>
      obtain ⟨rid, vis⟩ := found
      have hl := post_of_ok (lookup_spec db key.deref) hlookup
      simp only [vec_deref_val, hfind, Option.map_some, reduceCtorEq,
        false_or, Option.some.injEq, Prod.mk.injEq] at hl
      obtain ⟨rfl, rfl⟩ := hl
      dsimp only at h
      replace h := bind_eq_ok.mp h
      rcases h with ⟨n, hnval, h⟩
      have hnmp : n = false := by
        cases n
        · rfl
        · exact False.elim (hn hnval)
      subst n
      replace h := bind_eq_ok.mp h
      rcases h with ⟨extracted, hextracted, h⟩
      replace h := bind_eq_ok.mp h
      rcases h with ⟨outcome, houtcome, h⟩
      cases outcome
      all_goals simp (config := { maxSteps := 1000000 }) only [bind_ok, reduceIte,
        Bool.false_eq_true, Bool.true_eq_false, core.option.Option.is_none,
        core.option.Option.is_some, Option.isNone, Option.isSome, decide_true,
        decide_false, Bool.not_true, Bool.not_false] at h
      all_goals h5i_invert h
      all_goals h5i_invert h
      all_goals try simp at h
      case Resolved ext =>
        h5i_invert h
        all_goals try simp at h
        all_goals try (rcases h with ⟨hw, he, ht⟩; subst_vars)
        all_goals try simp_all [ha]
        all_goals exact permission_arm_sound db ip ext r.id (r.visibility.getD .Private) req hm ho1
      case NoCredential =>
        have hs := ticket_shape db req x hx
        rcases x with ⟨writes, auth, ticket⟩
        rcases hs with hs | hs
        · simp only at hs
          subst auth
          simp [bind_ok] at h
        · simp only at hs
          subst ticket
          cases auth <;> simp [bind_ok] at h
      case InvalidCredential =>
        have hs := ticket_shape db req x hx
        rcases x with ⟨writes, auth, ticket⟩
        rcases hs with hs | hs
        · simp only at hs
          subst auth
          simp [bind_ok] at h
        · simp only at hs
          subst ticket
          cases auth <;> simp [bind_ok] at h

end artifactkeeper_kernel.Solution
