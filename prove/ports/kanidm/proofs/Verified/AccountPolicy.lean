import KanidmKernel
import H5iAppLib
open Aeneas Aeneas.Std Result kanidm_kernel
open Aeneas.Std.WP H5iAppLib
namespace kanidm_kernel.Verified.AccountPolicy

private theorem if_ok {α : Type} (p : Prop) [Decidable p] (a b : α) :
    (if p then ok a else ok b) = (ok (if p then a else b) : Result α) := by
  split <;> rfl

def maxOption (a b : Option U64) : Option U64 :=
  match a, b with
  | none, x | x, none => x
  | some x, some y => some (max x y)

theorem option_max_spec (a b : Option U64) :
    account_policy.option_max a b = ok (maxOption a b) := by
  cases a <;> cases b <;> simp [account_policy.option_max, maxOption, max_def]
  split <;> split <;> simp_all <;> scalar_tac

def conjunction (a b : Option Bool) : Option Bool :=
  match a, b with
  | none, x | x, none => x
  | some x, some y => some (x && y)

def combine (a b : account_policy.Policy) : account_policy.Policy :=
  { privilege_expiry := min a.privilege_expiry b.privilege_expiry,
    authsession_expiry := min a.authsession_expiry b.authsession_expiry,
    pw_min_length := max a.pw_min_length b.pw_min_length,
    credential_policy := max a.credential_policy b.credential_policy,
    limit_search_max_filter_test := maxOption a.limit_search_max_filter_test b.limit_search_max_filter_test,
    limit_search_max_results := maxOption a.limit_search_max_results b.limit_search_max_results,
    allow_primary_cred_fallback := conjunction a.allow_primary_cred_fallback b.allow_primary_cred_fallback }

theorem combine_spec (a b : account_policy.Policy) :
    account_policy.combine a b = ok (combine a b) := by
  have hpriv : (if b.privilege_expiry < a.privilege_expiry then b.privilege_expiry else a.privilege_expiry) = min a.privilege_expiry b.privilege_expiry := by
    simp [min_def]; split <;> split <;> simp_all <;> scalar_tac
  have hauth : (if b.authsession_expiry < a.authsession_expiry then b.authsession_expiry else a.authsession_expiry) = min a.authsession_expiry b.authsession_expiry := by
    simp [min_def]; split <;> split <;> simp_all <;> scalar_tac
  have hpw : (if b.pw_min_length > a.pw_min_length then b.pw_min_length else a.pw_min_length) = max a.pw_min_length b.pw_min_length := by
    simp [max_def]; split <;> split <;> simp_all <;> scalar_tac
  have hcred : (if b.credential_policy > a.credential_policy then b.credential_policy else a.credential_policy) = max a.credential_policy b.credential_policy := by
    simp [max_def]; split <;> split <;> simp_all <;> scalar_tac
  unfold account_policy.combine
  simp only [if_ok, bind_ok, option_max_spec]
  rw [hpriv, hauth, hpw, hcred]
  cases ha : a.allow_primary_cred_fallback <;> cases hb : b.allow_primary_cred_fallback <;>
    simp [combine, conjunction, ha, hb]
  split <;> simp_all

def finalize (a : account_policy.Policy) : account_policy.Resolved :=
  { policy := if a.credential_policy < 10#u16 then
      {a with pw_min_length := max a.pw_min_length 15#u32} else a,
    pw_max_length := 128#u32 }

theorem finalize_spec (a : account_policy.Policy) :
    account_policy.finalize a = ok (finalize a) := by
  unfold account_policy.finalize finalize
  split <;> simp_all
  split <;> simp_all [max_def] <;> scalar_tac

/-- Every combined policy tightens both expiries, and never reduces either minimum. -/
theorem combine_bounds (a b : account_policy.Policy) :
    (combine a b).privilege_expiry ≤ a.privilege_expiry ∧
    (combine a b).privilege_expiry ≤ b.privilege_expiry ∧
    (combine a b).authsession_expiry ≤ a.authsession_expiry ∧
    (combine a b).authsession_expiry ≤ b.authsession_expiry ∧
    a.pw_min_length ≤ (combine a b).pw_min_length ∧
    b.pw_min_length ≤ (combine a b).pw_min_length ∧
    a.credential_policy ≤ (combine a b).credential_policy ∧
    b.credential_policy ≤ (combine a b).credential_policy := by
  simp [combine, min_le_left, min_le_right, le_max_left, le_max_right]

/-- A single false fallback policy survives every subsequent combination. -/
theorem fallback_false (a b : account_policy.Policy)
    (h : a.allow_primary_cred_fallback = some false ∨ b.allow_primary_cred_fallback = some false) :
    (combine a b).allow_primary_cred_fallback = some false := by
  rcases h with h | h <;> simp [combine, conjunction, h] <;>
    cases a.allow_primary_cred_fallback <;> cases b.allow_primary_cred_fallback <;> simp_all [conjunction]
@[step] theorem combine_wp (a b : account_policy.Policy) :
    account_policy.combine a b ⦃ r => r = combine a b ⦄ := by
  rw [combine_spec]
  simp

@[step] theorem finalize_wp (a : account_policy.Policy) :
    account_policy.finalize a ⦃ r => r = finalize a ⦄ := by
  rw [finalize_spec]
  simp

/-- The entire accumulation loop equals an independent list fold, at any valid index. -/
@[step] theorem fold_loop_spec (policies : Slice account_policy.Policy)
    (acc : account_policy.Policy) (i : Usize) (hi : i.val ≤ policies.val.length) :
    account_policy.fold_from_loop policies acc i
      ⦃ r => r = (policies.val.drop i.val).foldl combine acc ⦄ := by
  unfold account_policy.fold_from_loop
  apply loop.spec_decr_nat (measure := fun x => policies.val.length - x.2.val)
    (inv := fun x => x.2.val ≤ policies.val.length ∧
      (policies.val.drop x.2.val).foldl combine x.1 =
      (policies.val.drop i.val).foldl combine acc)
  · rintro ⟨a,j⟩ ⟨hj,heq⟩
    by_cases hlt : j.val < policies.val.length
    · have hfold : (policies.val.drop j.val).foldl combine a =
          (policies.val.drop (j.val+1)).foldl combine (combine a policies.val[j.val]) := by
        rw [List.drop_eq_getElem_cons hlt, List.foldl_cons]
      h5i_unfold_body
      h5i_steps
      all_goals (try simp_all)
      all_goals (try scalar_tac)
    · have hdrop : policies.val.drop j.val = [] := List.drop_eq_nil_of_le (by omega)
      h5i_unfold_body
      h5i_steps
      all_goals (try simp_all)
      all_goals (try scalar_tac)
  · exact ⟨hi,rfl⟩

def initial : account_policy.Policy :=
  {privilege_expiry := 3600#u32, authsession_expiry := 4294967295#u32,
   pw_min_length := 10#u32, credential_policy := 0#u16,
   limit_search_max_filter_test := none, limit_search_max_results := none,
   allow_primary_cred_fallback := none}

/-- Complete scalar-policy result for arbitrary finite policy inputs. -/
theorem fold_from_spec (policies : Slice account_policy.Policy) :
    account_policy.fold_from policies
      ⦃ r => r = finalize (policies.val.foldl combine initial) ⦄ := by
  unfold account_policy.fold_from account_policy.initial
  h5i_steps
  all_goals (try simp_all [initial])
  all_goals rfl
end kanidm_kernel.Verified.AccountPolicy
