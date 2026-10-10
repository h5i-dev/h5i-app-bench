import Spec
import H5iAppLib
/-!
The requested totality statement is false: a namespace scope may contain
`Usize.max` slash bytes. Splitting that scope requires one more segment than
a vector can hold. This file proves the failure through the full transition,
while the provider still satisfies the role-pattern hypothesis.
-/
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP

namespace Counterexample

def slashes : Slice U8 :=
  Slice.from (List.replicate Usize.max 47#u8) (by simp)

theorem split_slashes_loop :
    split_loop slashes 47#u8 (alloc.vec.Vec.new _) (alloc.vec.Vec.new _) 0#usize
      ⦃ r => r.1.val.length = Usize.max ⦄ := by
  unfold split_loop
  apply loop_idx_spec _ (fun x => x.2.2) Usize.max
    (fun x => x.1.val.length = x.2.2.val) _ ?_ _ (by simp) (by simp)
  rintro ⟨out, cur, i⟩ hi hbound
  simp only at hi hbound
  unfold split_loop.body
  have hs : slashes.val = List.replicate Usize.max 47#u8 := by simp [slashes]
  have hslen : slashes.length = Usize.max := by simp [slashes]
  h5i_steps
  all_goals simp_all
  all_goals scalar_tac

theorem u32_le_usize : U32.max ≤ Usize.max := by
  have := usize_max_ge
  simpa [U32.max_def, U32.numBits] using this

theorem split_slashes_fail : split slashes 47#u8 = fail .maximumSizeExceeded := by
  obtain ⟨r, hr, hlen⟩ := (WP.spec_equiv_exists _ _).mp split_slashes_loop
  rcases r with ⟨out, cur⟩
  simp only at hlen
  unfold split
  rw [hr]
  unfold alloc.vec.Vec.push
  have h32 := u32_le_usize
  simp [hlen, show ¬ Usize.max < U32.max by omega]

theorem bytes_eq_self (s : Slice U8) : bytes_eq s s = ok true := by
  apply eq_ok_of_spec
  unfold bytes_eq
  simp only [bne_self_eq_false, Bool.false_eq_true, ↓reduceIte]
  unfold bytes_eq_loop
  h5i_total (fun i => i) s.length

def rule : OidcRoleRule :=
  { pattern := vecOf [42#u8]
    role := vecOf [97#u8, 100#u8, 109#u8, 105#u8, 110#u8]
    namespace_scope := none }

def provider : OidcProvider :=
  { max_token_lifetime_secs := 0#u64
    role_rules := vecOf [rule]
    namespace_scope := vecOf [{ slice := slashes }]
    namespace_scope_enforcement := .Enforce }

def claims : Claims := { sub := none, iat := none, exp := none }
def request : Request :=
  { method := .Get, is_admin := false, «namespace» := some (alloc.vec.Vec.new U8) }

theorem pattern_bound :
    ∀ r ∈ provider.role_rules.val, r.pattern.length < Usize.max := by
  intro r hr
  simp only [provider, vecOf_val, List.mem_singleton] at hr
  subst r
  simp only [rule, alloc.vec.Vec.length, vecOf_val, List.length_cons, List.length_nil]
  exact usize_lt_max (by decide)

theorem role_match : match_role provider (Slice.new U8) = ok (some (.Admin, none)) := by
  unfold match_role match_role_loop
  rw [loop]
  simp [match_role_loop.body,
    provider, rule, vecOf, glob_match, is_star,
    alloc.vec.Vec.from, alloc.vec.Vec.deref, alloc.vec.Vec.val, lift, Slice.len,
    alloc.vec.Vec.index, Slice.index_usize,
    Array.to_slice, Array.make, bytes_eq_self, UScalar.eq_equiv]

@[simp] theorem scope_clone (v : alloc.vec.Vec (alloc.vec.Vec U8)) :
    alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) v = ok v := by
  apply vec_clone_eq
  intro x
  exact u8vec_clone x

def identity : OidcIdentity :=
  { subject := alloc.vec.Vec.new U8, role := .Admin,
    namespace_scope := provider.namespace_scope, rule_namespace_scope := none,
    namespace_scope_enforcement := .Enforce }

theorem valid_claims : validate_claims provider claims = ok (.Ok identity) := by
  have hnew : (alloc.vec.Vec.new U8).deref = Slice.new U8 := by
    apply Slice.ext
    simp [alloc.vec.Vec.deref, alloc.vec.Vec.new, alloc.vec.Vec.val, alloc.vec.Vec.from]
  simp only [validate_claims, claims, bind_ok, hnew, role_match, scope_clone]
  rfl

theorem is_star_slashes : is_star slashes = ok false := by
  have hmax : Usize.max ≠ 1 := by have := usize_max_ge; omega
  simp [is_star, slashes, hmax]

theorem has_star_slashes :
    has_star provider.namespace_scope.deref = ok false := by
  unfold has_star has_star_loop
  rw [loop]
  simp [has_star_loop.body, provider, vecOf, alloc.vec.Vec.from,
    alloc.vec.Vec.val, alloc.vec.Vec.deref, Slice.index_usize, is_star_slashes]
  have hadd : (0#usize : Usize) + 1#usize = ok 1#usize := by
    apply eq_ok_of_spec
    step*
  rw [hadd]
  simp only [bind_ok]
  rw [loop]
  simp only [UScalar.ofNatCore_val_eq, Nat.one_ne_zero, ↓reduceIte, bind_ok]

@[simp] theorem to_vec_eq (v : alloc.vec.Vec (alloc.vec.Vec U8)) :
    alloc.slice.Slice.to_vec (core.clone.CloneallocvecVec core.clone.CloneU8) v.deref = ok v := by
  apply eq_ok_of_spec
  apply WP.spec_mono (alloc.slice.Slice.to_vec_spec _ v.deref (fun x _ => u8vec_clone x))
  intro w hw
  apply alloc.vec.Vec.ext
  simpa [alloc.vec.Vec.val, alloc.vec.Vec.deref] using congrArg Slice.val hw.symm

@[simp] theorem push_new {α : Type} (v : α) :
    alloc.vec.Vec.push (alloc.vec.Vec.new α) v = ok (vecOf [v]) := by
  apply eq_ok_of_spec
  apply WP.spec_mono (alloc.vec.Vec.push_spec _ v (usize_lt_max (by simp [alloc.vec.Vec.new])))
  intro w hw
  apply alloc.vec.Vec.ext
  simpa [vec_new_val] using hw

def scopes := vecOf [provider.namespace_scope]

theorem authority :
    from_oidc_scopes provider.namespace_scope.deref none .Enforce =
      ok (.Scoped scopes .Enforce) := by
  simp [from_oidc_scopes, has_star_slashes, scopes, UScalar.eq_equiv]

theorem namespace_fail (s : Slice U8) :
    namespace_match slashes s = fail .maximumSizeExceeded := by
  simp [namespace_match, is_star_slashes, split_slashes_fail]

theorem scope_fail (s : Slice U8) :
    scope_matches provider.namespace_scope.deref s =
      fail .maximumSizeExceeded := by
  unfold scope_matches scope_matches_loop
  rw [loop]
  simp [scope_matches_loop.body, provider, vecOf, alloc.vec.Vec.from,
    alloc.vec.Vec.val, alloc.vec.Vec.deref, Slice.index_usize, namespace_fail]

theorem enforce_fail (s : Slice U8) :
    enforce_namespace_scope (.Scoped scopes .Enforce) s =
      fail .maximumSizeExceeded := by
  simp only [enforce_namespace_scope]
  unfold enforce_namespace_scope_loop
  rw [loop]
  simp [enforce_namespace_scope_loop.body, scopes,
    alloc.vec.Vec.index, Slice.index_usize, scope_fail,
    vecOf, alloc.vec.Vec.from, alloc.vec.Vec.val]

theorem transition_fail :
    transition provider claims request = fail .maximumSizeExceeded := by
  simp [transition, valid_claims, request, identity,
    core.result.Result.Insts.CoreOpsTry.branch, authority, enforce_fail]

theorem total_statement_false :
    ¬ (∀ (p : OidcProvider) (c : Claims) (r : Request),
      (∀ rule ∈ p.role_rules.val, rule.pattern.length < Usize.max) →
      ∃ y, transition p c r = ok y) := by
  intro h
  obtain ⟨y, hy⟩ := h provider claims request pattern_bound
  rw [transition_fail] at hy
  exact fail_ne_ok hy

end Counterexample
