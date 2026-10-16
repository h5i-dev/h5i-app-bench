import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP

namespace artifactkeeper_kernel.Solution

@[simp] theorem lit_repository : lit "repository" = [114,101,112,111,115,105,116,111,114,121] := by simp only [lit, String.toUTF8]; decide +kernel
@[simp] theorem lit_project : lit "project" = [112,114,111,106,101,99,116] := by simp only [lit, String.toUTF8]; decide +kernel
@[simp] theorem lit_anonymous : lit "anonymous" = [97,110,111,110,121,109,111,117,115] := by simp only [lit, String.toUTF8]; decide +kernel
@[simp] theorem lit_read : lit "read" = [114,101,97,100] := by simp only [lit, String.toUTF8]; decide +kernel
@[simp] theorem lit_admin : lit "admin" = [97,100,109,105,110] := by simp only [lit, String.toUTF8]; decide +kernel

@[simp] theorem u32_div_width (x : U32) : x.val / 4294967296 = 0 :=
  Nat.div_eq_of_lt (by scalar_tac)
@[simp] theorem u128_div_width (x : U128) : x.val / 340282366920938463463374607431768211456 = 0 :=
  Nat.div_eq_of_lt (by scalar_tac)

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    strs.bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold strs.bytes_eq
  dsimp only
  split
  · step*
  · rename_i he
    have hlen : a.val.length = b.val.length := by scalar_tac
    unfold strs.bytes_eq_loop
    apply loop_idx_spec _ id a.val.length
      (fun i => ∀ j, j < i.val → a.val[j]? = b.val[j]?)
      (fun r => r = decide (a.val = b.val)) ?_ 0#usize (by simp) (by simp)
    intro i hpre hi
    unfold strs.bytes_eq_loop.body
    step*
    all_goals try simp_all
    · constructor
      · intro j hj
        by_cases hj' : j < i.val
        · exact hpre j hj'
        · have : j = i.val := by omega
          subst j
          have helem : a.val[i.val]'(by scalar_tac) = b.val[i.val]'(by scalar_tac) := by scalar_tac
          rw [List.getElem?_eq_getElem (by scalar_tac), List.getElem?_eq_getElem (by scalar_tac)]
          exact congrArg some helem
      · scalar_tac
    · apply List.ext_getElem?
      intro j
      by_cases hj : j < i.val
      · exact hpre j hj
      · simp [show a.val.length ≤ j by omega,
          show b.val.length ≤ j by omega]

@[step] theorem any_eq_spec (xs : Slice (alloc.vec.Vec U8)) (s : Slice U8) :
    strs.any_eq xs s ⦃ b => b = xs.val.any (fun v => decide (v.val = s.val)) ⦄ := by
  unfold strs.any_eq strs.any_eq_loop
  h5i_search_any xs.val (fun v => decide (v.val = s.val))
  all_goals simp_all [vec_deref_val]
  all_goals scalar_tac

@[step] theorem project_of_spec (db : tables.Db) (repo : U64) :
    permission.project_of db repo ⦃ p =>
      p = (db.repositories.val.find? (fun r => decide (r.id = repo))).bind (·.project_id) ⦄ := by
  unfold permission.project_of permission.project_of_loop
  apply WP.spec_mono (loop_search db.repositories.val (fun r => decide (r.id = repo))
    id (fun _ r => r.project_id) none _ ?_ 0#usize (by simp))
  · intro p hp
    rw [id_eq, searchFrom_findD] at hp
    simp only [UScalar.ofNatCore_val_eq, List.drop_zero] at hp
    rw [hp]
    cases db.repositories.val.find? (fun r => decide (r.id = repo)) <;> rfl
  · intro i hi
    unfold permission.project_of_loop.body
    h5i_step

@[step] theorem lookup_repo_loop_spec (db : tables.Db) (key : Slice U8) :
    middleware.lookup_repo_loop db key 0#usize ⦃ p =>
      p = (db.repositories.val.find? (fun r => decide (r.key.val = key.val))).map
        (fun r => (r.id, r.visibility.getD .Private)) ⦄ := by
  unfold middleware.lookup_repo_loop
  apply WP.spec_mono (loop_search db.repositories.val (fun r => decide (r.key.val = key.val))
    id (fun _ r => some (r.id, r.visibility.getD .Private)) none _ ?_ 0#usize (by simp))
  · intro p hp
    simpa only [id_eq, searchFrom_find, UScalar.ofNatCore_val_eq, List.drop_zero] using hp
  · intro i hi
    unfold middleware.lookup_repo_loop.body
    h5i_step [vec_deref_val]

@[step] theorem project_is_spec (db : tables.Db) (repo target : U64) :
    permission.project_is db repo target ⦃ b => b = true → ProjectOf db repo target ⦄ := by
  unfold permission.project_is
  step*
  simp_all [ProjectOf]
  intro h
  subst target
  exact o_post.symm

@[step] theorem repo_target_spec (db : tables.Db) (p : tables.Permission) (repo : U64) :
    permission.repo_target_matches db p repo ⦃ b => b = true → OnRepo db p repo ⦄ := by
  unfold permission.repo_target_matches
  step*
  all_goals simp_all [OnRepo, nats, vec_deref_val, Array.to_slice, Array.make]

@[step] theorem cidr_contains_spec (c : net.CidrRange) (ip : net.IpAddr) :
    net.CidrRange.contains c ip ⦃ b => b = inCidr c ip ⦄ := by
  unfold net.CidrRange.contains
  cases hn : c.network <;> cases ip
  all_goals rename_i nw addr
  all_goals h5i_steps
  all_goals simp_all [inCidr]
  · have h : i = i1 := by scalar_tac
    simp [h]
  · apply Bool.eq_iff_iff.mpr
    simp only [decide_eq_true_eq, beq_iff_eq]
    simp only [UScalar.eq_equiv_bv_eq, i_post1, i1_post1]
    simp only [show BitVec.ofNat 32 U32.rMax = BitVec.allOnes 32 from rfl,
      BitVec.and_allOnes]
    exact BitVec.toNat_inj.symm
  · apply Bool.eq_iff_iff.mpr
    simp only [decide_eq_true_eq, beq_iff_eq]
    simp only [UScalar.eq_equiv_bv_eq, i_post1, i1_post1]
    exact (bv_masked_eq_iff nw.bv addr.bv (32 - c.prefix_len.val)).trans
      (by rw [← BitVec.toNat_inj]; simp only [BitVec.toNat_ushiftRight, UScalar.bv_toNat, Nat.shiftRight_eq_div_pow])
  · have h : i = i1 := by scalar_tac
    simp [h]
  · apply Bool.eq_iff_iff.mpr
    simp only [decide_eq_true_eq, beq_iff_eq]
    simp only [UScalar.eq_equiv_bv_eq, i_post1, i1_post1]
    simp only [show BitVec.ofNat 128 U128.rMax = BitVec.allOnes 128 from rfl,
      BitVec.and_allOnes]
    exact BitVec.toNat_inj.symm
  · apply Bool.eq_iff_iff.mpr
    simp only [decide_eq_true_eq, beq_iff_eq]
    simp only [UScalar.eq_equiv_bv_eq, i_post1, i1_post1]
    exact (bv_masked_eq_iff nw.bv addr.bv (128 - c.prefix_len.val)).trans
      (by rw [← BitVec.toNat_inj]; simp only [BitVec.toNat_ushiftRight, UScalar.bv_toNat, Nat.shiftRight_eq_div_pow])

@[step] theorem any_contains_spec (ranges : Slice net.CidrRange) (ip : net.IpAddr) :
    net.any_contains ranges ip ⦃ b => b = ranges.val.any (fun c => inCidr c ip) ⦄ := by
  unfold net.any_contains net.any_contains_loop
  h5i_search_any ranges.val (fun c => inCidr c ip)

@[step] theorem ip_condition_spec (p : tables.Permission) (ip : Option net.IpAddr) :
    permission.ip_condition p ip ⦃ b => b = true → IpOk p ip ⦄ := by
  unfold permission.ip_condition
  step*
  all_goals simp_all [IpOk, List.any_eq_true, vec_deref_val]

@[step] theorem anonymous_loop_spec (db : tables.Db) (ip : Option net.IpAddr) (repo : U64)
    (action : Slice U8) (ha : nats action.val = lit "read") :
    permission.check_anonymous_repository_action_loop db ip repo action 0#usize
      ⦃ b => b = true → AnonymousRead db ip repo ⦄ := by
  unfold permission.check_anonymous_repository_action_loop
  apply loop_idx_spec _ id db.permissions.val.length (fun _ => True)
    (fun b => b = true → AnonymousRead db ip repo) ?_ 0#usize trivial (by simp)
  intro i _ hi
  unfold permission.check_anonymous_repository_action_loop.body
  step*
  all_goals try (simp_all [vec_deref_val]; scalar_tac)
  all_goals simp_all [vec_deref_val]
  · obtain ⟨x, hx, he⟩ := b2_post
    have hc : Carries db.permissions.val[i.val].actions.val (nats action.val) :=
      ⟨x, hx, congrArg nats he⟩
    rw [ha] at hc
    refine ⟨db.permissions.val[i.val]'(by scalar_tac), List.getElem_mem _, ?_, b1_post,
      Or.inl (by rw [lit_read]; convert hc using 1; rfl), b3_post⟩
    simp_all [nats, Array.to_slice, Array.make]
  · obtain ⟨x, hx, he⟩ := b3_post
    have hc : Carries db.permissions.val[i.val].actions.val
        (nats [97#u8, 100#u8, 109#u8, 105#u8, 110#u8]) := ⟨x, hx, congrArg nats he⟩
    refine ⟨db.permissions.val[i.val]'(by scalar_tac), List.getElem_mem _, ?_, b1_post,
      Or.inr ?_, b4_post⟩
    · simp_all [nats, Array.to_slice, Array.make]
    · simp only [nats, List.map_cons, List.map_nil] at hc
      simp only [lit_admin, UScalar.ofNatCore_val_eq] at *
      convert hc using 1
      rfl

theorem anonymous_action_sound (db : tables.Db) (ip : Option net.IpAddr) (repo : U64)
    (action : Slice U8) (ha : nats action.val = lit "read")
    (h : permission.check_anonymous_repository_action db ip repo action = ok (.Ok true)) :
    AnonymousRead db ip repo := by
  unfold permission.check_anonymous_repository_action at h
  h5i_invert h
  exact post_of_ok (anonymous_loop_spec db ip repo action ha) hb1 rfl

theorem lookup_repo_sound (db : tables.Db) (key : Slice U8) (r : tables.Repository)
    (hr : db.repositories.val.find? (fun x => decide (x.key.val = key.val)) = some r)
    (repo : U64) (v : Visibility)
    (h : middleware.lookup_repo db key = ok (some (repo, v))) :
    repo = r.id ∧ v = r.visibility.getD .Private := by
  unfold middleware.lookup_repo at h
  h5i_invert h
  have hp := post_of_ok (lookup_repo_loop_spec db key) h
  simpa [hr] using hp

theorem nonpublic_denies_shortcut (visibility : Option Visibility)
    (h : visibility ≠ some .Public) :
    paths.should_allow_repo_access (visibility.getD .Private) false = ok false := by
  cases visibility with
  | none => simp [paths.should_allow_repo_access, Visibility.allows_anonymous_read]
  | some v => cases v <;> simp_all [paths.should_allow_repo_access, Visibility.allows_anonymous_read]

theorem anonymous_unwrap_sound (db : tables.Db) (ip : Option net.IpAddr) (repo : U64)
    (action : Slice U8) (ha : nats action.val = lit "read")
    (h : (do let res ← permission.check_anonymous_repository_action db ip repo action
             middleware.unwrap_false res) = ok true) : AnonymousRead db ip repo := by
  obtain ⟨res, hres, hunwrap⟩ := bind_tc_eq_ok.mp h
  cases res with
  | Err e => simp [middleware.unwrap_false] at hunwrap
  | Ok b =>
    have hb : b = true := by simpa [middleware.unwrap_false] using hunwrap
    subst b
    exact anonymous_action_sound db ip repo action ha hres

set_option maxRecDepth 4096 in
set_option maxHeartbeats 4000000 in
theorem anonymous_needs_rule (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (t : Bool) (r : tables.Repository)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, .Next none t))
    (hr : RepoOf db req r) (hv : r.visibility ≠ some .Public) :
    AnonymousRead db ip r.id := by
  obtain ⟨key, hkey, hrepo⟩ := hr
  unfold middleware.repo_visibility_middleware middleware.respond at h
  dsimp only at h
  rw [hkey] at h
  simp only [bind_ok] at h
  by_cases hk : key.len = 0#usize
  · simp only [hk, if_true, ok.injEq, Prod.mk.injEq, reduceCtorEq, and_false] at h
  · rw [if_neg hk] at h
    obtain ⟨found, hfound, hrest⟩ := bind_tc_eq_ok.mp h
    clear h
    cases found with
    | none =>
      h5i_invert hrest
      simp only [and_false] at hrest
    | some rv =>
      obtain ⟨repo, visibility⟩ := rv
      have hh := lookup_repo_sound db key.deref r (by simpa [vec_deref_val] using hrepo)
        repo visibility hfound
      obtain ⟨rfl, rfl⟩ := hh
      dsimp only [uncurry] at hrest
      h5i_invert hrest
      by_cases hover : b2 = true
      · simp only [hover, if_true, ok.injEq, Prod.mk.injEq, reduceCtorEq, and_false] at hrest
      · rw [if_neg hover] at hrest
        obtain ⟨invalid, hinvalid, htail⟩ := bind_tc_eq_ok.mp hrest
        clear hrest
        obtain ⟨auth, hauth, htail1⟩ := bind_tc_eq_ok.mp htail
        clear htail
        obtain ⟨ticket_result, hticket, htail⟩ := bind_tc_eq_ok.mp htail1
        clear htail1
        rcases ticket_result with ⟨writes, auth1, ticket⟩
        dsimp only [uncurry] at htail
        cases hauth1 : auth1
        all_goals simp only [hauth1, core.option.Option.is_none, core.option.Option.is_some,
          Option.isNone, Option.isSome, reduceIte] at htail
        all_goals h5i_invert htail
        all_goals simp -failIfUnchanged only [middleware.Outcome.Next.injEq, reduceCtorEq,
          and_false, false_and] at htail
        · have hdeny := nonpublic_denies_shortcut r.visibility hv
          simp only [hdeny, ok.injEq, hc_2, Bool.false_eq_true] at hb7
        · rw [hc_3] at hanonymous_read_granted
          simp only [lift, bind_ok] at hanonymous_read_granted
          apply anonymous_unwrap_sound db ip r.id _ ?_ hanonymous_read_granted
          simp [nats, Array.to_slice, Array.make]

end artifactkeeper_kernel.Solution
