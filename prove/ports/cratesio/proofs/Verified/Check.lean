import Verified.Derived
import Verified.Auth
import Verified.Scopes
/-!
# `AuthCheck::check` and `authenticate`
-/
open Aeneas Aeneas.Std Result cratesio_kernel cratesio_kernel.Spec
open H5iAppLib hiding Covers
open Aeneas.Std.WP
open cratesio_kernel.Verified.Bytes cratesio_kernel.Verified.Auth cratesio_kernel.Verified.Scopes

namespace cratesio_kernel.Verified.Check

@[step] theorem scope_eq_spec (a b : scopes.EndpointScope) : scopes.scope_eq a b ⦃ r => decide (a = b) = r ⦄ := by
  unfold scopes.scope_eq; cases a <;> cases b <;> simp

@[step] theorem contains_scope_spec (ss : Slice scopes.EndpointScope) (s : scopes.EndpointScope) :
    scopes.contains_scope ss s ⦃ b => decide (s ∈ ss.val) = b ⦄ := by
  unfold scopes.contains_scope scopes.contains_scope_loop
  apply WP.spec_mono (loop_search ss.val (fun e => decide (e = s)) (fun b : Bool => b)
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr
    rw [search_any _ _ _ hr, eq_comm, Bool.eq_iff_iff]
    simp [List.any_eq_true]
  · intro j hj; unfold scopes.contains_scope_loop.body; h5i_step

@[step] theorem any_scope_matches_spec (ss : alloc.vec.Vec (alloc.vec.Vec U8)) (n : Slice U8) :
    scopes.any_scope_matches ss n ⦃ b => decide (∃ p ∈ ss.val, Spec.Covers p.val n.val) = b ⦄ := by
  unfold scopes.any_scope_matches scopes.any_scope_matches_loop
  apply WP.spec_mono (loop_search ss.val (fun p => coversB p.val n.val) (fun b : Bool => b)
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr
    rw [search_any _ _ _ hr, eq_comm, Bool.eq_iff_iff]
    simp [List.any_eq_true, coversB_iff]
  · intro j hj; unfold scopes.any_scope_matches_loop.body; h5i_step

@[step] theorem find_token_spec (tokens : alloc.vec.Vec auth.ApiToken) (s : Slice U8) (now : I64) :
    auth.find_token tokens s now ⦃ o => tokens.val.findIdx? (fun t => decide (Live t s.val now.val)) = o.map (·.val) ∧
      ∀ i, o = some i → i.val < tokens.val.length ⦄ := by
  unfold auth.find_token auth.find_token_loop
  apply WP.spec_mono (loop_search tokens.val (fun t => decide (Live t s.val now.val))
    (fun o : Option Usize => (o.map (·.val) : Option Nat)) (fun k _ => some k) none _ ?_ 0#usize (by simp))
  · intro r hr
    have := search_findIdx _ _ _ hr
    refine ⟨this.symm, fun i hi => ?_⟩
    rw [hi] at this
    simp only [Option.map_some] at this
    exact (List.findIdx?_eq_some_iff_findIdx_eq.1 this.symm).1
  · intro j hj; unfold auth.find_token_loop.body; h5i_step

/-- The endpoint scope check passes exactly for a legacy token or a token
listing the endpoint's scope. -/
@[step] theorem endpoint_scope_matches_spec (ac : auth.AuthCheck) (ts : Option (alloc.vec.Vec scopes.EndpointScope)) :
    auth.endpoint_scope_matches ac ts ⦃ b =>
      (b = true ↔ (ts = none ∨ ∃ v s, ts = some v ∧ ac.endpoint_scope = some s ∧ s ∈ v.val)) ⦄ := by
  unfold auth.endpoint_scope_matches
  rcases ts with _ | v
  · simp
  · rcases h : ac.endpoint_scope with _ | s
    · simp [h]
    · simp only [h]; step*; rw [← b_post]; simp

/-- The crate scope check passes exactly for a legacy token, a token without
crate scopes, an endpoint without a crate that allows any scope, or a token
with a pattern covering the endpoint's crate. -/
@[step] theorem crate_scope_matches_spec (ac : auth.AuthCheck) (ts : Option (alloc.vec.Vec (alloc.vec.Vec U8))) :
    auth.crate_scope_matches ac ts ⦃ b =>
      (b = true ↔ (ts = none ∨ (∃ v, ts = some v ∧ v.val = []) ∨
        (∃ v, ts = some v ∧ ac.crate_name = none ∧ ac.allow_any_crate_scope = true) ∨
        (∃ v n, ts = some v ∧ ac.crate_name = some n ∧ ∃ p ∈ v.val, Spec.Covers p.val n.val))) ⦄ := by
  unfold auth.crate_scope_matches
  rcases ts with _ | v
  · simp
  · simp only
    split
    · rename_i h
      have : v.val = [] := by
        have : v.val.length = 0 := by scalar_tac
        exact List.eq_nil_of_length_eq_zero this
      simp [this]
    · rename_i h
      have hne : v.val ≠ [] := by intro e; simp [e] at h
      rcases hn : ac.crate_name with _ | n
      · simp [hne, hn]
      · simp only [hn]; step*; rw [← b_post]; simp [hne]

end cratesio_kernel.Verified.Check
