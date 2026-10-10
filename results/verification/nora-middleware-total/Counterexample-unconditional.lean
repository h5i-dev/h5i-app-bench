import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

/-!
The requested totality theorem is false in the extracted model. An OIDC
role pattern of `Usize.max` stars is a valid slice, but splitting it creates
`Usize.max + 1` parts. The final push fails with `maximumSizeExceeded`.
The request below reaches that pattern with an empty failure table.

Check independently with `cd proofs && lake env lean Counterexample.lean`.
-/

namespace nora_kernel.Counterexample

def stars : Slice U8 := Slice.from (List.replicate Usize.max 42#u8) (by simp)

theorem stars_length : stars.val.length = Usize.max := by simp [stars]

theorem stars_get (i : Usize) (h : i.val < stars.val.length) :
    stars.val[i.val] = 42#u8 := by simp [stars]

theorem split_stars_loop :
    split_loop stars 42#u8 (alloc.vec.Vec.new _) (alloc.vec.Vec.new _) 0#usize
      ⦃ r => r.1.val.length = Usize.max ∧ r.2.val = [] ⦄ := by
  unfold split_loop
  apply loop_idx_spec _ (fun x => x.2.2) stars.val.length
    (fun x => x.1.val.length = x.2.2.val ∧ x.2.1.val = []) _ ?_ _ ?_ ?_
  · rintro ⟨out, cur, i⟩ ⟨hout, hcur⟩ hi
    unfold split_loop.body
    step*
    all_goals try simp_all [stars_get, stars_length]
    all_goals step*
    all_goals try simp_all [stars_length, alloc.vec.Vec.new]
  · simp [alloc.vec.Vec.new]
  · simp

theorem push_full_fail {α} (v : alloc.vec.Vec α) (x : α)
    (h : v.val.length = Usize.max) :
    alloc.vec.Vec.push v x = fail Error.maximumSizeExceeded := by
  have hmax : U32.max ≤ Usize.max := by
    simpa [U32.max_def, U32.numBits] using usize_max_ge
  unfold alloc.vec.Vec.push
  simp [h, hmax]

theorem split_stars_fail : split stars 42#u8 = fail Error.maximumSizeExceeded := by
  obtain ⟨⟨out, cur⟩, heq, hout, hcur⟩ :=
    (Aeneas.Std.WP.spec_equiv_exists _ _).mp split_stars_loop
  unfold split
  rw [heq]
  simpa using push_full_fail out cur hout

theorem glob_stars_fail (value : Slice U8) :
    glob_match stars value = fail Error.maximumSizeExceeded := by
  have hs : Slice.len stars ≠ 1#usize := by
    intro h
    have hv := congrArg UScalar.val h
    have hmax := usize_max_ge
    simp only [Slice.len_val, stars_length, UScalar.ofNatCore_val_eq] at hv
    omega
  simp [glob_match, is_star, hs, split_stars_fail]

def badProvider : OidcProvider := {
  max_token_lifetime_secs := 0#u64
  role_rules := vecOf [{pattern := ⟨stars⟩, role := vecOf [], namespace_scope := none}]
  namespace_scope := vecOf []
  namespace_scope_enforcement := .Enforce
}

theorem bad_match_role (subject : Slice U8) :
    match_role badProvider subject = fail Error.maximumSizeExceeded := by
  unfold match_role match_role_loop
  rw [loop]
  simp [match_role_loop.body, badProvider, vecOf, alloc.vec.Vec.index,
    alloc.vec.Vec.from, alloc.vec.Vec.deref, alloc.vec.Vec.val, Slice.index_usize,
    glob_stars_fail]

def emptyClaims : Claims := ⟨none, none, none⟩

theorem bad_validate :
    validate_claims badProvider emptyClaims = fail Error.maximumSizeExceeded := by
  simp [validate_claims, emptyClaims, bad_match_role]

theorem starts_self (s : Slice U8) : middleware.starts_with s s = ok true := by
  apply eq_ok_of_spec
  unfold middleware.starts_with
  simp only [lt_self_iff_false, ↓reduceIte]
  unfold middleware.starts_with_loop
  refine loop_idx_spec _ (fun i => i) s.val.length (fun _ => True) _ ?_ _ trivial (by simp)
  intro i _ hi
  unfold middleware.starts_with_loop.body
  step*

theorem strip_self (s : Slice U8) :
    middleware.strip_prefix s s = ok (some (alloc.vec.Vec.new U8)) := by
  unfold middleware.strip_prefix
  rw [starts_self]
  simp only [bind_ok, ↓reduceIte]
  unfold middleware.strip_prefix_loop
  rw [loop]
  simp [middleware.strip_prefix_loop.body]

def badConfig : middleware.Config := {
  enabled := true
  anonymous_read := false
  public_web_ui := false
  public_metrics := false
  docker_anon_pull := false
  htpasswd := none
  tokens := none
  oidc := some (badProvider, true)
  trusted_proxies := ⟨vecOf []⟩
  tracker := ⟨0#u32, 0#u64⟩
}

def emptyCrypto : oracle.Crypto := ⟨vecOf [], vecOf [], vecOf [], vecOf [], vecOf []⟩
def badJwt : middleware.Jwt := ⟨vecOf [], some emptyClaims⟩
def bearerHeader : alloc.vec.Vec U8 :=
  vecOf [66#u8, 101#u8, 97#u8, 114#u8, 101#u8, 114#u8, 32#u8]
def badRequest : middleware.Request := {
  path := vecOf []
  method := .Get
  has_auth_header := true
  auth_header := some bearerHeader
  peer := none
  xff := none
  x_real_ip := none
  now := 0#u64
  mono := 0#u64
}

theorem bad_bearer (fs : Slice lockout.FailureEntry) (req : middleware.Request)
    (admin : Bool) :
    middleware.bearer badConfig emptyCrypto fs (some badJwt) req
      (Slice.new U8) none admin = fail Error.maximumSizeExceeded := by
  simp [middleware.bearer, badConfig, middleware.oidc_claims, badJwt,
    oracle.bytes_eq, vecOf, alloc.vec.Vec.deref, alloc.vec.Vec.from,
    alloc.vec.Vec.val, oracle.bytes_eq_loop]
  rw [loop]
  simp [oracle.bytes_eq_loop.body, bad_validate]

theorem bad_middleware :
    middleware.auth_middleware badConfig (Slice.new lockout.FailureEntry)
      emptyCrypto (some badJwt) badRequest = fail Error.maximumSizeExceeded := by
  unfold middleware.auth_middleware
  simp only [badConfig, badRequest]
  simp [middleware.is_public_path, middleware.is_web_surface,
    middleware.is_docker_path, middleware.is_admin_path, oracle.bytes_eq,
    middleware.starts_with, middleware.ends_with, vecOf, alloc.vec.Vec.deref,
    alloc.vec.Vec.from, alloc.vec.Vec.val, Array.to_slice, Array.make,
    middleware.HttpMethod.Insts.CoreCmpPartialEqHttpMethod.eq, lift,
    middleware.HttpMethod.read_discriminant]
  simp only [bearerHeader, vecOf, alloc.vec.Vec.from, strip_self, bind_ok]
  exact bad_bearer _ badRequest false

theorem counterexample :
    (∀ e ∈ (Slice.new lockout.FailureEntry).val, e.failures.val < U32.max) ∧
    ¬ ∃ y, middleware.auth_middleware badConfig (Slice.new lockout.FailureEntry)
      emptyCrypto (some badJwt) badRequest = ok y := by
  constructor
  · simp
  · rintro ⟨y, hy⟩
    rw [bad_middleware] at hy
    simp at hy

theorem middleware_total_is_false :
    ¬ (∀ (cfg : middleware.Config) (fs : Slice lockout.FailureEntry)
        (cr : oracle.Crypto) (jw : Option middleware.Jwt) (req : middleware.Request),
      (∀ e ∈ fs.val, e.failures.val < U32.max) →
      ∃ y, middleware.auth_middleware cfg fs cr jw req = ok y) := by
  intro h
  exact counterexample.2
    (h badConfig (Slice.new lockout.FailureEntry) emptyCrypto (some badJwt)
      badRequest counterexample.1)

#print axioms middleware_total_is_false

end nora_kernel.Counterexample
