import Spec
import H5iAppLib
/-!
The requested totality statement omits a bound on the request namespace.
The provider below has one role rule ("*" -> "admin") and scope [""].
The request writes to a namespace consisting of Usize.max slash bytes.
Both hypotheses in Solution.transition_total hold, but namespace_match
splits the namespace into Usize.max + 1 empty segments. That cannot fit
in the extracted Vec model. `task_counterexample` proves that transition
has no successful Result for this input, without evaluating the huge list.

Check independently with `lake env lean Counterexample.lean`.
-/
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP

namespace nora_kernel.Counterexample

theorem push_ok_length {α} {v w : alloc.vec.Vec α} {x : α}
    (h : alloc.vec.Vec.push v x = ok w) : w.val.length = v.val.length + 1 := by
  unfold alloc.vec.Vec.push at h
  dsimp only at h
  split at h
  · have he := result_ok_inj h
    subst w
    simp
  · simp at h

theorem split_loop_length (s : Slice U8) (sep : U8)
    (hall : ∀ x ∈ s.val, x = sep)
    (out : alloc.vec.Vec (alloc.vec.Vec U8)) (cur : alloc.vec.Vec U8) (i : Usize)
    (hi : i.val ≤ s.val.length) (hout : out.val.length = i.val)
    (o : alloc.vec.Vec (alloc.vec.Vec U8)) (cu : alloc.vec.Vec U8)
    (h : split_loop s sep out cur i = ok (o, cu)) : o.val.length = s.val.length := by
  unfold split_loop at h
  apply loop_idx_ok _ (fun x => x.2.2) s.val.length
    (fun x => x.1.val.length = x.2.2.val)
    (fun x => x.1.val.length = s.val.length) _ _ _ hout hi h
  rintro ⟨out, cur, i⟩ r hout hi hr
  simp only at hout hi
  unfold split_loop.body at hr
  h5i_invert hr
  · have he := hall _ (slice_index_ok_mem hi2)
    simp only [he, if_true] at hx
    h5i_invert hx
    change (do
      let j ← i + 1#usize
      ok (ControlFlow.cont (out2, alloc.vec.Vec.new U8, j))) = ok r at hr
    h5i_invert hr
    have hp := push_ok_length hout2
    h5i_arith
  · scalar_tac

theorem split_no_ok (s : Slice U8) (sep : U8)
    (hall : ∀ x ∈ s.val, x = sep) (hlen : s.val.length = Usize.max) :
    ¬ ∃ w, split s sep = ok w := by
  rintro ⟨w, h⟩
  unfold split at h
  h5i_invert h
  rcases x with ⟨out, cur⟩
  have hlenout := split_loop_length s sep hall _ _ 0#usize (by simp) (by simp) out cur hx
  change alloc.vec.Vec.push out cur = ok w at h
  have hp := push_ok_length h
  have hb := w.property
  omega

def largeNamespace : alloc.vec.Vec U8 :=
  alloc.vec.Vec.from (List.replicate Usize.max 47#u8) (by simp)

theorem largeNamespace_split_no_ok :
    ¬ ∃ w, split (alloc.vec.Vec.deref largeNamespace) 47#u8 = ok w := by
  apply split_no_ok
  · intro x hx
    exact (by simpa [largeNamespace, alloc.vec.Vec.deref] using hx :
      Usize.max ≠ 0 ∧ x = 47#u8).2
  · simp [largeNamespace, alloc.vec.Vec.deref]

theorem largeNamespace_match_no_ok :
    ¬ ∃ b, namespace_match (alloc.vec.Vec.deref (alloc.vec.Vec.new U8))
      (alloc.vec.Vec.deref largeNamespace) = ok b := by
  rintro ⟨b, h⟩
  simp [namespace_match, is_star, alloc.vec.Vec.deref] at h
  h5i_invert h
  exact largeNamespace_split_no_ok ⟨val, hval⟩

@[step] theorem bytes_eq_same (a b : Slice U8) (he : a.val = b.val) :
    bytes_eq a b ⦃ z => z = true ⦄ := by
  have hb : b = a := Slice.ext _ _ he.symm
  subst b
  unfold bytes_eq
  simp only [bne_self_eq_false, Bool.false_eq_true, if_false]
  unfold bytes_eq_loop
  h5i_total (fun i => i) a.val.length

@[simp] theorem nested_clone (v : alloc.vec.Vec (alloc.vec.Vec U8)) :
    alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) v = ok v :=
  vec_clone_eq _ v u8vec_clone

def provider : OidcProvider := {
  max_token_lifetime_secs := 0#u64
  role_rules := vecOf [{
    pattern := vecOf [42#u8]
    role := vecOf [97#u8, 100#u8, 109#u8, 105#u8, 110#u8]
    namespace_scope := none
  }]
  namespace_scope := vecOf [alloc.vec.Vec.new U8]
  namespace_scope_enforcement := .Enforce
}

def claims : Claims := { sub := none, iat := none, exp := none }

def request : Request := { method := .Put, is_admin := false, «namespace» := some largeNamespace }

def identity : OidcIdentity := {
  subject := alloc.vec.Vec.new U8
  role := .Admin
  namespace_scope := provider.namespace_scope
  rule_namespace_scope := none
  namespace_scope_enforcement := .Enforce
}

theorem claims_valid : validate_claims provider claims = ok (.Ok identity) := by
  apply eq_ok_of_spec
  unfold validate_claims claims
  simp only [bind_ok]
  unfold match_role match_role_loop
  rw [loop]
  unfold match_role_loop.body
  simp [provider, vecOf, alloc.vec.Vec.index_slice_index, alloc.vec.Vec.index_usize,
    glob_match, is_star, alloc.vec.Vec.deref, Slice.len, Slice.index_usize]
  have hone (h : 1 < 2 ^ UScalarTy.Usize.numBits) : Usize.ofNatCore 1 h = 1#usize := by scalar_tac
  simp only [hone, if_true, bind_ok]
  step
  step
  all_goals simp_all [identity, provider, vecOf]

def authority : NamespaceAuthority :=
  .Scoped (vecOf [provider.namespace_scope]) .Enforce

theorem scope_no_star : has_star provider.namespace_scope.deref = ok false := by
  apply eq_ok_of_spec
  unfold has_star has_star_loop
  rw [loop]
  unfold has_star_loop.body
  simp [provider, vecOf, alloc.vec.Vec.deref, Slice.len, Slice.index_usize, is_star]
  step
  have hx : x = 1#usize := by scalar_tac
  subst x
  rw [loop]
  simp

theorem authority_eq :
    from_oidc_scopes provider.namespace_scope.deref none .Enforce = ok authority := by
  apply eq_ok_of_spec
  unfold from_oidc_scopes
  simp only [scope_no_star, bind_ok, Bool.false_eq_true, if_false]
  step as ⟨v, hv⟩
  · intro x _
    exact u8vec_clone x
  · step as ⟨w, hw⟩
    have hvv : v = provider.namespace_scope := by
      apply alloc.vec.Vec.ext
      have he := congrArg Slice.val hv
      simpa [alloc.vec.Vec.deref, alloc.vec.Vec.val] using he.symm
    subst v
    have hww : w = vecOf [provider.namespace_scope] := by
      apply alloc.vec.Vec.ext
      simpa using hw
    rw [hww]
    simp [authority, vecOf]

theorem scope_matches_no_ok :
    ¬ ∃ b, scope_matches provider.namespace_scope.deref largeNamespace.deref = ok b := by
  rintro ⟨b, h⟩
  unfold scope_matches scope_matches_loop at h
  rw [loop] at h
  unfold scope_matches_loop.body at h
  simp [provider, vecOf, alloc.vec.Vec.deref, Slice.len, Slice.index_usize] at h
  h5i_invert h
  all_goals exact largeNamespace_match_no_ok ⟨x, hx⟩

theorem enforce_no_ok :
    ¬ ∃ y, enforce_namespace_scope authority largeNamespace.deref = ok y := by
  rintro ⟨y, h⟩
  simp only [enforce_namespace_scope, authority, enforce_namespace_scope_loop] at h
  rw [loop] at h
  unfold enforce_namespace_scope_loop.body at h
  simp [vecOf, alloc.vec.Vec.index_slice_index, alloc.vec.Vec.index_usize] at h
  h5i_invert h
  all_goals exact scope_matches_no_ok ⟨x, hx⟩

theorem transition_no_ok : ¬ ∃ y, transition provider claims request = ok y := by
  rintro ⟨y, h⟩
  unfold transition at h
  simp [claims_valid, request, identity, Role.can_write,
    core.result.Result.Insts.CoreOpsTry.branch, authority_eq] at h
  h5i_invert h
  all_goals exact enforce_no_ok ⟨r1, hr1⟩

theorem provider_pattern_bound :
    ∀ rule ∈ provider.role_rules.val, rule.pattern.length < Usize.max := by
  simp [provider, vecOf]
  exact usize_lt_max (by decide)

theorem provider_scope_bound :
    (∀ s ∈ provider.namespace_scope.val, s.length < Usize.max) ∧
      ∀ rule ∈ provider.role_rules.val, ∀ sc, rule.namespace_scope = some sc →
        ∀ s ∈ sc.val, s.length < Usize.max := by
  simp [provider, vecOf]
  exact usize_lt_max (by decide)

/-- The hypotheses of the requested theorem hold, but its conclusion does not. -/
theorem task_counterexample :
    ∃ (p : OidcProvider) (c : Claims) (r : Request),
      (∀ rule ∈ p.role_rules.val, rule.pattern.length < Usize.max) ∧
      ((∀ s ∈ p.namespace_scope.val, s.length < Usize.max) ∧
        ∀ rule ∈ p.role_rules.val, ∀ sc, rule.namespace_scope = some sc →
          ∀ s ∈ sc.val, s.length < Usize.max) ∧
      ¬ ∃ y, transition p c r = ok y := by
  exact ⟨provider, claims, request, provider_pattern_bound, provider_scope_bound, transition_no_ok⟩

#print axioms task_counterexample

/-- Explicit negation of the unchanged statement in Solution.lean. -/
theorem transition_total_statement_false :
    ¬ (∀ (p : OidcProvider) (c : Claims) (r : Request),
      (∀ rule ∈ p.role_rules.val, rule.pattern.length < Usize.max) →
      ((∀ s ∈ p.namespace_scope.val, s.length < Usize.max) ∧
        ∀ rule ∈ p.role_rules.val, ∀ sc, rule.namespace_scope = some sc →
          ∀ s ∈ sc.val, s.length < Usize.max) →
      ∃ y, transition p c r = ok y) := by
  intro htotal
  exact transition_no_ok
    (htotal provider claims request provider_pattern_bound provider_scope_bound)

#print axioms transition_total_statement_false

end nora_kernel.Counterexample
