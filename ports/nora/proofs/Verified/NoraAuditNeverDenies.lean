import Verified.Derived
import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit
namespace nora_kernel.Verified.NoraAuditNeverDenies

lemma ite_eq_ok_cases {α : Type} (c : Prop) [Decidable c] (a b : α) (x : α)
    (h : (if c then ok a else ok b : Result α) = ok x) : x = a ∨ x = b := by
  by_cases hc : c
  · simp [hc] at h
    left; exact h.symm
  · simp [hc] at h
    right; exact h.symm

lemma enforce_namespace_scope_audit_not_denied
    (scopes : alloc.vec.Vec (alloc.vec.Vec (alloc.vec.Vec Std.U8))) (ns : Slice Std.U8) :
    enforce_namespace_scope (.Scoped scopes .Audit) ns ≠ ok (.Err .NamespaceDenied) := by
  intro h
  unfold enforce_namespace_scope at h
  simp only [bind_tc_eq_ok] at h
  rcases h with ⟨all, -, h2⟩
  by_cases hall : all = true
  · simp [hall] at h2
  · simp [hall] at h2

lemma enforce_namespace_scope_unrestricted_not_denied (ns : Slice Std.U8) :
    enforce_namespace_scope .Unrestricted ns ≠ ok (.Err .NamespaceDenied) := by
  intro h
  unfold enforce_namespace_scope at h
  simp at h

lemma from_oidc_scopes_cases {ps : Slice (alloc.vec.Vec Std.U8)}
    {rs : Option (alloc.vec.Vec (alloc.vec.Vec Std.U8))} {mode : ScopeEnforcement}
    {auth : NamespaceAuthority}
    (h : from_oidc_scopes ps rs mode = ok auth) :
    auth = .Unrestricted ∨ ∃ sc, auth = .Scoped sc mode := by
  unfold from_oidc_scopes at h
  rw [bind_tc_eq_ok] at h
  rcases h with ⟨b, hb, h⟩
  rw [bind_tc_eq_ok] at h
  rcases h with ⟨scopes, hscopes, h⟩
  rw [bind_tc_eq_ok] at h
  rcases h with ⟨scopes1, hscopes1, h⟩
  dsimp only at h
  rcases ite_eq_ok_cases (scopes1.len = 0#usize) .Unrestricted (.Scoped scopes1 mode) auth h with h1 | h2
  · left; exact h1
  · right; exact ⟨scopes1, h2⟩

lemma enforce_from_oidc_scopes_audit
    (ns : Slice Std.U8)
    {ps : Slice (alloc.vec.Vec Std.U8)}
    {rs : Option (alloc.vec.Vec (alloc.vec.Vec Std.U8))}
    {auth : NamespaceAuthority}
    (hauth : from_oidc_scopes ps rs .Audit = ok auth) :
    enforce_namespace_scope auth ns ≠ ok (.Err .NamespaceDenied) := by
  rcases from_oidc_scopes_cases hauth with rfl | ⟨sc, rfl⟩
  · exact enforce_namespace_scope_unrestricted_not_denied ns
  · exact enforce_namespace_scope_audit_not_denied sc ns

lemma namespace_check_not_denied (authority : NamespaceAuthority)
    (ns_opt : Option (alloc.vec.Vec Std.U8))
    (hauth : ∀ ns, enforce_namespace_scope authority ns ≠ ok (.Err .NamespaceDenied)) :
    (match ns_opt with
    | none => ok (core.result.Result.Ok Reply.Allowed)
    | some ns => do
      let s1 := alloc.vec.Vec.deref ns
      let r1 ← enforce_namespace_scope authority s1
      let cf1 ← core.result.Result.Insts.CoreOpsTry.branch r1
      match cf1 with
      | .Continue _ => ok (core.result.Result.Ok Reply.Allowed)
      | .Break residual =>
        core.result.Result.Insts.CoreOpsTry_traitFromResidualResult.from_residual
          Reply (core.convert.FromSame Error) residual) ≠ ok (.Err .NamespaceDenied) := by
  intro h
  cases ns_opt with
  | none => simp at h
  | some ns =>
    dsimp only at h
    rw [bind_tc_eq_ok] at h
    rcases h with ⟨r1, hr1, h⟩
    rw [bind_tc_eq_ok] at h
    rcases h with ⟨cf1, hcf1, h⟩
    cases r1 with
    | Ok v =>
      simp [core.result.Result.Insts.CoreOpsTry.branch] at hcf1
      subst hcf1
      simp at h
    | Err e =>
      simp [core.result.Result.Insts.CoreOpsTry.branch] at hcf1
      subst hcf1
      simp [core.result.Result.Insts.CoreOpsTry_traitFromResidualResult.from_residual,
            core.convert.FromSame.from] at h
      subst h
      exact hauth (alloc.vec.Vec.deref ns) hr1

lemma authority_check_not_denied (val : OidcIdentity) (req : Request)
    (h_mode : val.namespace_scope_enforcement = .Audit) :
    (do
      let s := alloc.vec.Vec.deref val.namespace_scope
      let authority ←
        from_oidc_scopes s val.rule_namespace_scope
          val.namespace_scope_enforcement
      match req.namespace with
      | none => ok (core.result.Result.Ok Reply.Allowed)
      | some ns =>
        let s1 := alloc.vec.Vec.deref ns
        let r1 ← enforce_namespace_scope authority s1
        let cf1 ← core.result.Result.Insts.CoreOpsTry.branch r1
        match cf1 with
        | core.ops.control_flow.ControlFlow.Continue _ =>
          ok (core.result.Result.Ok Reply.Allowed)
        | core.ops.control_flow.ControlFlow.Break residual =>
          core.result.Result.Insts.CoreOpsTry_traitFromResidualResult.from_residual
            Reply (core.convert.FromSame Error) residual) ≠ ok (.Err .NamespaceDenied) := by
  intro h
  dsimp only at h
  rw [bind_tc_eq_ok] at h
  rcases h with ⟨authority, hauth, h⟩
  rw [h_mode] at hauth
  exact namespace_check_not_denied authority req.namespace (fun ns => enforce_from_oidc_scopes_audit ns hauth) h

lemma validate_claims_not_denied (p : OidcProvider) (c : Claims) :
    validate_claims p c ≠ ok (.Err .NamespaceDenied) := by
  intro h
  unfold validate_claims at h
  revert h
  cases c.iat
  · intro h
    rw [bind_tc_eq_ok] at h
    rcases h with ⟨sub, -, h⟩
    rw [bind_tc_eq_ok] at h
    rcases h with ⟨o, -, h⟩
    cases o with
    | none => simp at h
    | some x =>
      cases x with
      | mk role rule_scope =>
        change (do
          let v ← alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) p.namespace_scope
          ok (core.result.Result.Ok ({ subject := sub, role := role, namespace_scope := v, rule_namespace_scope := rule_scope, namespace_scope_enforcement := p.namespace_scope_enforcement } : OidcIdentity))) = ok (core.result.Result.Err Error.NamespaceDenied) at h
        rw [bind_tc_eq_ok] at h
        rcases h with ⟨v, -, h⟩
        simp at h
  · cases c.exp
    · intro h
      rw [bind_tc_eq_ok] at h
      rcases h with ⟨sub, -, h⟩
      rw [bind_tc_eq_ok] at h
      rcases h with ⟨o, -, h⟩
      cases o with
      | none => simp at h
      | some x =>
        cases x with
        | mk role rule_scope =>
          change (do
            let v ← alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) p.namespace_scope
            ok (core.result.Result.Ok ({ subject := sub, role := role, namespace_scope := v, rule_namespace_scope := rule_scope, namespace_scope_enforcement := p.namespace_scope_enforcement } : OidcIdentity))) = ok (core.result.Result.Err Error.NamespaceDenied) at h
          rw [bind_tc_eq_ok] at h
          rcases h with ⟨v, -, h⟩
          simp at h
    · intro h
      rw [bind_tc_eq_ok] at h
      rcases h with ⟨lt, -, h⟩
      split at h
      · simp at h
      · rw [bind_tc_eq_ok] at h
        rcases h with ⟨sub, -, h⟩
        rw [bind_tc_eq_ok] at h
        rcases h with ⟨o, -, h⟩
        cases o with
        | none => simp at h
        | some x =>
          cases x with
          | mk role rule_scope =>
            change (do
              let v ← alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) p.namespace_scope
              ok (core.result.Result.Ok ({ subject := sub, role := role, namespace_scope := v, rule_namespace_scope := rule_scope, namespace_scope_enforcement := p.namespace_scope_enforcement } : OidcIdentity))) = ok (core.result.Result.Err Error.NamespaceDenied) at h
            rw [bind_tc_eq_ok] at h
            rcases h with ⟨v, -, h⟩
            simp at h

lemma validate_claims_enforcement (p : OidcProvider) (c : Claims) (val : OidcIdentity)
    (h : validate_claims p c = ok (.Ok val)) :
    val.namespace_scope_enforcement = p.namespace_scope_enforcement := by
  unfold validate_claims at h
  revert h
  cases c.iat
  · intro h
    rw [bind_tc_eq_ok] at h
    rcases h with ⟨sub, -, h⟩
    rw [bind_tc_eq_ok] at h
    rcases h with ⟨o, -, h⟩
    cases o with
    | none => simp at h
    | some x =>
      cases x with
      | mk role rule_scope =>
        change (do
          let v ← alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) p.namespace_scope
          ok (core.result.Result.Ok ({ subject := sub, role := role, namespace_scope := v, rule_namespace_scope := rule_scope, namespace_scope_enforcement := p.namespace_scope_enforcement } : OidcIdentity))) = ok (.Ok val) at h
        rw [bind_tc_eq_ok] at h
        rcases h with ⟨v, -, h⟩
        simp only [ok.injEq, core.result.Result.Ok.injEq] at h
        subst h; rfl
  · cases c.exp
    · intro h
      rw [bind_tc_eq_ok] at h
      rcases h with ⟨sub, -, h⟩
      rw [bind_tc_eq_ok] at h
      rcases h with ⟨o, -, h⟩
      cases o with
      | none => simp at h
      | some x =>
        cases x with
        | mk role rule_scope =>
          change (do
            let v ← alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) p.namespace_scope
            ok (core.result.Result.Ok ({ subject := sub, role := role, namespace_scope := v, rule_namespace_scope := rule_scope, namespace_scope_enforcement := p.namespace_scope_enforcement } : OidcIdentity))) = ok (.Ok val) at h
          rw [bind_tc_eq_ok] at h
          rcases h with ⟨v, -, h⟩
          simp only [ok.injEq, core.result.Result.Ok.injEq] at h
          subst h; rfl
    · intro h
      rw [bind_tc_eq_ok] at h
      rcases h with ⟨lt, -, h⟩
      split at h
      · simp at h
      · rw [bind_tc_eq_ok] at h
        rcases h with ⟨sub, -, h⟩
        rw [bind_tc_eq_ok] at h
        rcases h with ⟨o, -, h⟩
        cases o with
        | none => simp at h
        | some x =>
          cases x with
          | mk role rule_scope =>
            change (do
              let v ← alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) p.namespace_scope
              ok (core.result.Result.Ok ({ subject := sub, role := role, namespace_scope := v, rule_namespace_scope := rule_scope, namespace_scope_enforcement := p.namespace_scope_enforcement } : OidcIdentity))) = ok (.Ok val) at h
            rw [bind_tc_eq_ok] at h
            rcases h with ⟨v, -, h⟩
            simp only [ok.injEq, core.result.Result.Ok.injEq] at h
            subst h; rfl

theorem audit_never_denies (p : OidcProvider) (c : Claims) (r : Request)
    (ha : p.namespace_scope_enforcement = .Audit) :
    transition p c r ≠ ok (.Err .NamespaceDenied) := by
  intro h
  unfold transition at h
  rw [bind_tc_eq_ok] at h
  rcases h with ⟨r_claims, hr_claims, h⟩
  rw [bind_tc_eq_ok] at h
  rcases h with ⟨cf, hcf, h⟩
  cases r_claims with
  | Err e =>
    simp [core.result.Result.Insts.CoreOpsTry.branch] at hcf
    subst hcf
    simp [core.result.Result.Insts.CoreOpsTry_traitFromResidualResult.from_residual,
          core.convert.FromSame.from] at h
    subst h
    exact validate_claims_not_denied p c hr_claims
  | Ok val =>
    simp [core.result.Result.Insts.CoreOpsTry.branch] at hcf
    subst hcf
    have h_mode : val.namespace_scope_enforcement = .Audit := by
      rw [validate_claims_enforcement p c val hr_claims, ha]
    rw [bind_tc_eq_ok] at h
    rcases h with ⟨writes, hwrites, h⟩
    cases writes with
    | false =>
      simp only [Bool.false_eq_true, ↓reduceIte] at h
      by_cases hadmin : r.is_admin
      · simp [hadmin] at h
        rw [bind_tc_eq_ok] at h
        rcases h with ⟨b, hb, h⟩
        by_cases hb_admin : b = true
        · simp [hb_admin] at h
          exact authority_check_not_denied val r h_mode h
        · simp [hb_admin] at h
      · simp [hadmin] at h
        exact authority_check_not_denied val r h_mode h
    | true =>
      simp only [↓reduceIte] at h
      rw [bind_tc_eq_ok] at h
      rcases h with ⟨b, hb, h⟩
      by_cases hb_write : b = true
      · simp [hb_write] at h
        by_cases hadmin : r.is_admin
        · simp [hadmin] at h
          rw [bind_tc_eq_ok] at h
          rcases h with ⟨b1, hb1, h⟩
          by_cases hb1_admin : b1 = true
          · simp [hb1_admin] at h
            exact authority_check_not_denied val r h_mode h
          · simp [hb1_admin] at h
        · simp [hadmin] at h
          exact authority_check_not_denied val r h_mode h
      · simp [hb_write] at h

end nora_kernel.Verified.NoraAuditNeverDenies
