import Verified.ArtifactkeeperScopesGrant
import H5iAppLib
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel artifactkeeper_kernel.Spec
namespace artifactkeeper_kernel.Verified.TokenScope
open ArtifactkeeperScopesGrant
set_option maxHeartbeats 4000000

def allowed (s : List Nat) : Bool :=
  decide (s = [114, 101, 97, 100, 58, 97, 114, 116, 105, 102, 97, 99, 116, 115]) ||
  decide (s = [119, 114, 105, 116, 101, 58, 97, 114, 116, 105, 102, 97, 99, 116, 115]) ||
  decide (s = [100, 101, 108, 101, 116, 101, 58, 97, 114, 116, 105, 102, 97, 99, 116, 115]) ||
  decide (s = [112, 114, 111, 109, 111, 116, 101, 58, 97, 114, 116, 105, 102, 97, 99, 116, 115]) ||
  decide (s = [114, 101, 97, 100, 58, 114, 101, 112, 111, 115, 105, 116, 111, 114, 105, 101, 115]) ||
  decide (s = [119, 114, 105, 116, 101, 58, 114, 101, 112, 111, 115, 105, 116, 111, 114, 105, 101, 115]) ||
  decide (s = [100, 101, 108, 101, 116, 101, 58, 114, 101, 112, 111, 115, 105, 116, 111, 114, 105, 101, 115]) ||
  decide (s = [114, 101, 97, 100, 58, 117, 115, 101, 114, 115]) ||
  decide (s = [119, 114, 105, 116, 101, 58, 117, 115, 101, 114, 115]) ||
  decide (s = [116, 114, 105, 103, 103, 101, 114, 58, 115, 121, 110, 99]) ||
  decide (s = [119, 114, 105, 116, 101, 58, 102, 105, 110, 100, 105, 110, 103, 115]) ||
  decide (s = [97, 100, 109, 105, 110]) ||
  decide (s = [42])

@[step] theorem is_allowed_scope_spec (s : Slice U8) :
    token_scope.is_allowed_scope s ⦃ r => r = allowed (nats s.val) ⦄ := by
  unfold token_scope.is_allowed_scope
  h5i_steps
  all_goals simp_all [allowed, nats, Array.to_slice, Array.make, List.map_eq_singleton_iff]

def adminOnly (s : List Nat) : Bool :=
  decide (s = [97, 100, 109, 105, 110]) ||
  decide (s = [42]) ||
  decide (s = [100, 101, 108, 101, 116, 101, 58, 97, 114, 116, 105, 102, 97, 99, 116, 115]) ||
  decide (s = [100, 101, 108, 101, 116, 101, 58, 114, 101, 112, 111, 115, 105, 116, 111, 114, 105, 101, 115]) ||
  decide (s = [112, 114, 111, 109, 111, 116, 101, 58, 97, 114, 116, 105, 102, 97, 99, 116, 115]) ||
  decide (s = [116, 114, 105, 103, 103, 101, 114, 58, 115, 121, 110, 99]) ||
  decide (s = [119, 114, 105, 116, 101, 58, 117, 115, 101, 114, 115]) ||
  decide (s = [119, 114, 105, 116, 101, 58, 102, 105, 110, 100, 105, 110, 103, 115])

@[step] theorem is_admin_only_scope_spec (s : Slice U8) :
    token_scope.is_admin_only_scope s ⦃ r => r = adminOnly (nats s.val) ⦄ := by
  unfold token_scope.is_admin_only_scope
  h5i_steps
  all_goals simp_all [adminOnly, nats, Array.to_slice, Array.make, List.map_eq_singleton_iff]
  all_goals
    change decide (nats s.val = [119, 114, 105, 116, 101, 58, 102, 105, 110, 100, 105, 110, 103, 115]) =
      (decide (nats s.val = [42]) || decide (nats s.val = [119, 114, 105, 116, 101, 58, 102, 105, 110, 100, 105, 110, 103, 115]))
    have hn : ¬ nats s.val = [42] := by
      intro h
      obtain ⟨x, hx, he⟩ := List.map_eq_singleton_iff.mp h
      exact b1_post x hx he
    simp only [decide_eq_false hn, Bool.false_or]

/-- Complete result: the first invalid scope, or successful exhaustion. -/
def validation (xs : List (alloc.vec.Vec U8)) : core.result.Result Unit (alloc.vec.Vec U8) :=
  ((xs.find? (fun s => !allowed (nats s.val))).map core.result.Result.Err).getD (.Ok ())

theorem validation_spec (scopes : Slice (alloc.vec.Vec U8)) :
    token_scope.validate_scopes_pure scopes = ok (validation scopes.val) := by
  apply eq_ok_of_spec
  unfold token_scope.validate_scopes_pure token_scope.validate_scopes_pure_loop
  apply WP.spec_mono (loop_search scopes.val (fun s => !allowed (nats s.val)) id
    (fun _ s => core.result.Result.Err s) (.Ok ()) _ ?_ 0#usize (by simp))
  · intro r hr
    simpa [validation, searchFrom_findD] using hr
  · intro i hi
    unfold token_scope.validate_scopes_pure_loop.body
    h5i_step [alloc.vec.Vec.deref]

/-- Admin callers bypass this check; otherwise the first privileged scope fails. -/
def adminValidation (xs : List (alloc.vec.Vec U8)) (admin : Bool) :
    core.result.Result Unit (alloc.vec.Vec U8) :=
  if admin then .Ok () else
    ((xs.find? (fun s => adminOnly (nats s.val))).map core.result.Result.Err).getD (.Ok ())

theorem admin_validation_spec (scopes : Slice (alloc.vec.Vec U8)) (admin : Bool) :
    token_scope.enforce_admin_only_scopes scopes admin = ok (adminValidation scopes.val admin) := by
  apply eq_ok_of_spec
  unfold token_scope.enforce_admin_only_scopes
  split
  · simp_all [adminValidation, WP.spec_ok]
  · unfold token_scope.enforce_admin_only_scopes_loop
    apply WP.spec_mono (loop_search scopes.val (fun s => adminOnly (nats s.val)) id
      (fun _ s => core.result.Result.Err s) (.Ok ()) _ ?_ 0#usize (by simp))
    · intro r hr
      simpa [adminValidation, searchFrom_findD, *] using hr
    · intro i hi
      unfold token_scope.enforce_admin_only_scopes_loop.body
      h5i_step [alloc.vec.Vec.deref]

/-- Unrestricted interactive credentials satisfy every requested action. -/
def held (e : AuthExtension) (s : List Nat) : Bool :=
  match e.scopes with
  | none => true
  | some scopes => scopeGrants (scopes.val.map (fun v => nats v.val)) s

@[step] theorem has_scope_spec (e : AuthExtension) (s : Slice U8) :
    token_scope.AuthExtension.has_scope e s ⦃ r => r = held e (nats s.val) ⦄ := by
  unfold token_scope.AuthExtension.has_scope
  cases hs : e.scopes <;> simp only [hs]
  · simp [WP.spec_ok, held, hs]
  · rw [scopes_grant_access_spec]
    simp [WP.spec_ok, held, hs, alloc.vec.Vec.deref]

def mint (e : AuthExtension) (requested : List (alloc.vec.Vec U8)) :
    core.result.Result Unit AppError :=
  if e.is_admin then .Ok () else
  if ∃ s ∈ requested, held e (nats s.val) = false then .Err .Authorization else .Ok ()

theorem mint_spec (e : AuthExtension) (requested : Slice (alloc.vec.Vec U8)) :
    token_scope.check_mint_ceiling e requested = ok (mint e requested.val) := by
  apply eq_ok_of_spec
  unfold token_scope.check_mint_ceiling token_scope.AuthExtension.enforce_mint_ceiling
  split
  · simp_all [mint, WP.spec_ok]
  · unfold token_scope.AuthExtension.enforce_mint_ceiling_loop
    apply WP.spec_mono (loop_search requested.val (fun s => !held e (nats s.val)) id
      (fun _ _ => core.result.Result.Err AppError.Authorization) (.Ok ()) _ ?_ 0#usize (by simp))
    · intro r hr
      have hh := search_bool _ _ _ _ _ hr
      simpa [mint, *] using hh
    · intro i hi
      unfold token_scope.AuthExtension.enforce_mint_ceiling_loop.body
      h5i_step [alloc.vec.Vec.deref]
      all_goals simp_all [held]
      all_goals scalar_tac

/-- Restricted credentials inherit nonempty repositories verbatim. -/
def repoMint (e : AuthExtension) (requested : Bool) :
    core.result.Result (Option (alloc.vec.Vec U64)) AppError :=
  match e.allowed_repo_ids with
  | .Admin => .Ok none
  | .Restricted ids =>
      if requested || ids.val.isEmpty then .Err .Authorization else .Ok (some ids)

theorem repo_mint_spec (e : AuthExtension) (requested : Bool) :
    token_scope.check_repo_ceiling e requested = ok (repoMint e requested) := by
  apply eq_ok_of_spec
  unfold token_scope.check_repo_ceiling token_scope.AuthExtension.mint_repo_ceiling
  h5i_steps
  all_goals simp_all [repoMint, List.isEmpty_iff]
  all_goals apply List.length_eq_zero_iff.mp; scalar_tac

end artifactkeeper_kernel.Verified.TokenScope
