import Verified.NoraMiddlewareSupport
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit
namespace nora_kernel.Verified.NoraMiddlewareTotal
set_option maxRecDepth 4096
set_option maxHeartbeats 12000000 in
theorem middleware_total (cfg : middleware.Config) (fs : Slice lockout.FailureEntry)
    (cr : oracle.Crypto) (jw : Option middleware.Jwt) (req : middleware.Request)
    (hf : ∀ e ∈ fs.val, e.failures.val < U32.max)
    (hpat : ∀ p b, cfg.oidc = some (p, b) → ∀ rule ∈ p.role_rules.val, rule.pattern.length < Usize.max) :
    ∃ y, middleware.auth_middleware cfg fs cr jw req = ok y := by
  apply ok_of (P := fun _ => True)
  unfold middleware.auth_middleware
  by_cases hEnabled : cfg.enabled = true
  · rw [if_pos hEnabled]
    step as ⟨publicPath⟩
    -- Join classification branches before proving the rest of the middleware.
    apply Aeneas.Std.WP.spec_bind (Pₘ := fun _ => True)
    · h5i_steps
    rintro ⟨anonymousRead, publicWebUi, openPath⟩ _
    h5i_steps
    all_goals try simp_all [alloc.vec.Vec.deref]
      <;> try (apply usize_lt_max; omega) <;> try scalar_tac
  · rw [if_neg hEnabled]
    h5i_steps

end nora_kernel.Verified.NoraMiddlewareTotal
