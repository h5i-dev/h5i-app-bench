import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

namespace nora_kernel.Solution

theorem lifetime_bounded (p : OidcProvider) (c : Claims) (r : Request) (x : Reply) (iat exp : U64)
    (h : transition p c r = ok (.Ok x)) (hi : c.iat = some iat) (he : c.exp = some exp) :
    exp.val - iat.val ≤ p.max_token_lifetime_secs.val := by
  by_contra hb
  have hg : p.max_token_lifetime_secs.val < (core.num.U64.saturating_sub exp iat).val := by
    h5i_arith
  have hc : validate_claims p c = ok (.Err .TokenLifetime) := by
    simp [validate_claims, hi, he, hg, lift]
  simp [transition, hc, core.result.Result.Insts.CoreOpsTry.branch,
    core.result.Result.Insts.CoreOpsTry_traitFromResidualResult.from_residual,
    core.convert.FromSame.from] at h

end nora_kernel.Solution
