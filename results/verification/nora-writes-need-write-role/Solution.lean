import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

namespace nora_kernel.Solution

open Aeneas.Std.WP
set_option maxHeartbeats 2000000
set_option maxRecDepth 4096

@[step] theorem starts_with_spec (s p : Slice U8) :
    middleware.starts_with s p ⦃ b => b = decide (p.val <+: s.val) ⦄ := by
  unfold middleware.starts_with
  dsimp only
  split
  · rename_i h
    have hn : ¬ p.val <+: s.val := fun hp => by
      have := hp.length_le
      scalar_tac
    simp [hn]
  · rename_i h
    have hlen : p.val.length ≤ s.val.length := by scalar_tac
    unfold middleware.starts_with_loop
    -- Every byte before the current index has already matched.
    apply loop_idx_spec _ (fun i => i) p.val.length
      (fun i => s.val.take i.val = p.val.take i.val)
      (fun b => b = decide (p.val <+: s.val)) ?_ 0#usize (by simp) (by simp)
    intro i hi hib
    unfold middleware.starts_with_loop.body
    dsimp only
    split
    · rename_i hic
      have hip : i.val < p.val.length := by scalar_tac
      have his : i.val < s.val.length := by omega
      step*
      · rename_i hne
        have hn : ¬ p.val <+: s.val := by
          intro hp
          have he := hp.getElem hip
          simp_all
          exact hne rfl
        simp [hn]
      · have heq : s.val[i.val] = p.val[i.val] := by scalar_tac
        refine ⟨?_, by omega, by omega⟩
        rw [i4_post, List.take_succ_eq_append_getElem his,
          List.take_succ_eq_append_getElem hip, hi, heq]
    · have hie : i.val = p.val.length := by scalar_tac
      have hp : p.val <+: s.val := prefix_iff_take.2 ⟨hlen, by simpa [hie] using hi⟩
      simp [hp]

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    oracle.bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold oracle.bytes_eq
  dsimp only
  split
  · have hn : a.val ≠ b.val := by intro he; scalar_tac
    simp [hn]
  · rename_i h
    have hlen : a.val.length = b.val.length := by scalar_tac
    have he : a.len = b.len := by scalar_tac
    -- With equal lengths, equality uses the same scan as the prefix matcher.
    have hb : (fun i => oracle.bytes_eq_loop.body a b i) =
        (fun i => middleware.starts_with_loop.body a b i) := by
      funext i
      simp only [oracle.bytes_eq_loop.body, middleware.starts_with_loop.body, he]
    unfold oracle.bytes_eq_loop
    rw [hb]
    have hs := starts_with_spec a b
    unfold middleware.starts_with at hs
    simp only [show ¬ a.len < b.len by scalar_tac, if_false,
      middleware.starts_with_loop] at hs
    apply spec_mono hs
    intro r hr
    rw [hr]
    congr 1
    apply propext
    constructor
    · intro hp; exact (hp.eq_of_length hlen.symm).symm
    · intro hp; simp [hp]

@[simp] theorem nats_eq_iff (a b : List U8) : nats a = nats b ↔ a = b := by
  unfold nats
  constructor
  · intro h
    induction a generalizing b with
    | nil => cases b <;> simp_all
    | cons x xs ih =>
      cases b with
      | nil => simp at h
      | cons y ys =>
        simp only [List.map_cons, List.cons.injEq] at h
        have hxy : x = y := (u8_eq_iff x y).2 h.1
        simp [hxy, ih _ h.2]
  · rintro rfl; rfl

@[simp] theorem nats_prefix_iff (p s : List U8) : nats p <+: nats s ↔ p <+: s := by
  constructor
  · intro h
    obtain ⟨hlen, hg⟩ := List.prefix_iff_getElem.1 h
    simp only [nats, List.length_map] at hlen
    refine List.prefix_iff_getElem.2 ⟨hlen, ?_⟩
    intro i hi
    have := hg i (by simpa [nats] using hi)
    simp only [nats, List.getElem_map] at this
    exact (u8_eq_iff _ _).2 this
  · intro h; exact h.map _

attribute [-step] starts_with_spec bytes_eq_spec

@[step] theorem starts_with_nats_spec (s p : Slice U8) :
    middleware.starts_with s p ⦃ b => b = decide (nats p.val <+: nats s.val) ⦄ := by
  simpa using starts_with_spec s p

@[step] theorem bytes_eq_nats_spec (a b : Slice U8) :
    oracle.bytes_eq a b ⦃ r => r = decide (nats a.val = nats b.val) ⦄ := by
  simpa using bytes_eq_spec a b

@[simp] theorem lit_values :
    lit "/" = [47] ∧
    lit "/health" = [47, 104, 101, 97, 108, 116, 104] ∧
    lit "/ready" = [47, 114, 101, 97, 100, 121] ∧
    lit "/api/tokens" = [47, 97, 112, 105, 47, 116, 111, 107, 101, 110, 115] ∧
    lit "/api/tokens/list" = [47, 97, 112, 105, 47, 116, 111, 107, 101, 110, 115, 47, 108, 105, 115, 116] ∧
    lit "/api/tokens/revoke" = [47, 97, 112, 105, 47, 116, 111, 107, 101, 110, 115, 47, 114, 101, 118, 111, 107, 101] ∧
    lit "/ui/tokens" = [47, 117, 105, 47, 116, 111, 107, 101, 110, 115] ∧
    lit "/api/ui/tokens" = [47, 97, 112, 105, 47, 117, 105, 47, 116, 111, 107, 101, 110, 115] ∧
    lit "/ui" = [47, 117, 105] ∧
    lit "/api/ui" = [47, 97, 112, 105, 47, 117, 105] ∧
    lit "/api-docs" = [47, 97, 112, 105, 45, 100, 111, 99, 115] ∧
    lit "/metrics" = [47, 109, 101, 116, 114, 105, 99, 115] ∧
    lit "/npm/-/npm/v1/security/advisories/bulk" =
      [47, 110, 112, 109, 47, 45, 47, 110, 112, 109, 47, 118, 49, 47, 115, 101, 99, 117, 114, 105, 116, 121,
       47, 97, 100, 118, 105, 115, 111, 114, 105, 101, 115, 47, 98, 117, 108, 107] ∧
    lit "/npm/-/npm/v1/security/audits/quick" =
      [47, 110, 112, 109, 47, 45, 47, 110, 112, 109, 47, 118, 49, 47, 115, 101, 99, 117, 114, 105, 116, 121,
       47, 97, 117, 100, 105, 116, 115, 47, 113, 117, 105, 99, 107] := by
  decide +kernel

theorem prefix_bool (p s : List Nat) : p.isPrefixOf s = decide (p <+: s) := by
  apply Bool.eq_iff_iff.2
  simp

@[step] theorem public_path_spec (p : Slice U8) :
    middleware.is_public_path p ⦃ b => b = isPublicPath (nats p.val) ⦄ := by
  unfold middleware.is_public_path
  step*
  all_goals simp_all [isPublicPath, nats]

@[step] theorem web_surface_spec (p : Slice U8) :
    middleware.is_web_surface p ⦃ b => b = isWebSurface (nats p.val) ⦄ := by
  unfold middleware.is_web_surface
  step*
  all_goals simp_all [isWebSurface, isTokenPage, prefix_bool, nats]

@[simp] theorem write_method_eq (m : middleware.HttpMethod) :
    middleware.is_write_method m = ok (isWriteMethod m) := by
  cases m <;> simp [middleware.is_write_method, isWriteMethod]

theorem can_write_true (role : Role) (h : Role.can_write role = ok true) :
    role = .Write ∨ role = .Admin := by
  cases role <;> simp_all [Role.can_write]

open Lean Elab Tactic Meta in
-- Destructure the tuples introduced while inverting successful calls.
elab "cases_pair" : tactic => withMainContext do
  for d in ← getLCtx do
    if d.isImplementationDetail then continue
    if (← whnf d.type).isAppOfArity ``Prod 2 then
      evalTactic (← `(tactic| cases $(mkIdent d.userName):ident))
      return
  throwError "no pair to destructure"

macro "invert_pairs " h:ident : tactic => `(tactic| (
  iterate 8 (
    all_goals simp_all -failIfUnchanged only [middleware.Outcome.Next.injEq,
      Prod.mk.injEq, and_false, false_and, and_true, true_and,
      Bool.false_eq_true, Bool.true_eq_false, ↓reduceIte, ite_self,
      bind_ok, bind_tc_ok, uncurry_apply_pair]
    all_goals h5i_invert $h
    all_goals try cases_pair)
  all_goals h5i_invert $h))

theorem token_identity_write (writes : alloc.vec.Vec middleware.Write)
    (ip : Option net.IpAddr) (m : middleware.HttpMethod) (adm : Bool)
    (user : alloc.vec.Vec U8) (role : Role)
    (ws : alloc.vec.Vec middleware.Write) (a : NamespaceAuthority)
    (u : alloc.vec.Vec U8) (r : Option Role) (hw : isWriteMethod m)
    (h : middleware.token_identity writes ip m adm user role = ok (ws, .Next a u r)) :
    r = some .Write ∨ r = some .Admin := by
  unfold middleware.token_identity at h
  simp only [write_method_eq, hw] at h
  invert_pairs h
  all_goals cases role <;> simp_all [Role.can_write]

theorem bearer_write (cfg : middleware.Config) (cr : oracle.Crypto)
    (fs : Slice lockout.FailureEntry) (jw : Option middleware.Jwt)
    (req : middleware.Request) (token : Slice U8) (ip : Option net.IpAddr) (adm : Bool)
    (ws : alloc.vec.Vec middleware.Write) (a : NamespaceAuthority)
    (u : alloc.vec.Vec U8) (r : Option Role) (hw : isWriteMethod req.method)
    (h : middleware.bearer cfg cr fs jw req token ip adm = ok (ws, .Next a u r)) :
    r = some .Write ∨ r = some .Admin := by
  unfold middleware.bearer at h
  simp only [write_method_eq, hw] at h
  invert_pairs h
  all_goals try exact token_identity_write _ _ _ _ _ _ _ _ _ _ hw h
  all_goals simp_all -failIfUnchanged
  all_goals
    have hg := can_write_true _ (by assumption)
    rcases hg with hg | hg <;> simp_all

theorem basic_write (cfg : middleware.Config) (cr : oracle.Crypto)
    (fs : Slice lockout.FailureEntry) (req : middleware.Request)
    (header : Slice U8) (ip : Option net.IpAddr) (adm : Bool)
    (ws : alloc.vec.Vec middleware.Write) (a : NamespaceAuthority)
    (u : alloc.vec.Vec U8) (r : Option Role) (hw : isWriteMethod req.method)
    (h : middleware.basic cfg cr fs req header ip adm = ok (ws, .Next a u r)) :
    r = some .Write ∨ r = some .Admin := by
  unfold middleware.basic at h
  invert_pairs h
  all_goals first
    | exact token_identity_write _ _ _ _ _ _ _ _ _ _ hw h
    | simp_all

@[simp] theorem bytes_eq_eq (a b : Slice U8) :
    oracle.bytes_eq a b = ok (decide (nats a.val = nats b.val)) :=
  eq_ok_of_spec (bytes_eq_nats_spec a b)

@[simp] theorem public_path_eq (p : Slice U8) :
    middleware.is_public_path p = ok (isPublicPath (nats p.val)) :=
  eq_ok_of_spec (public_path_spec p)

@[simp] theorem web_surface_eq (p : Slice U8) :
    middleware.is_web_surface p = ok (isWebSurface (nats p.val)) :=
  eq_ok_of_spec (web_surface_spec p)

theorem writes_need_write_role (cfg : middleware.Config) (fs : Slice lockout.FailureEntry)
    (cr : oracle.Crypto) (jw : Option middleware.Jwt) (req : middleware.Request)
    (ws : alloc.vec.Vec middleware.Write) (a : NamespaceAuthority) (u : alloc.vec.Vec U8) (r : Option Role)
    (he : cfg.enabled = true) (hw : isWriteMethod req.method)
    (ho : ¬ IsOpen cfg (nats req.path.val)) (hn : isNpmAudit (nats req.path.val) = false)
    (h : middleware.auth_middleware cfg fs cr jw req = ok (ws, .Next a u r)) :
    r = some .Write ∨ r = some .Admin := by
  have hp : isPublicPath (nats req.path.val) = false := by
    cases hb : isPublicPath (nats req.path.val)
    · rfl
    · exact False.elim (ho (Or.inl hb))
  have ha : nats req.path.val ≠ lit "/npm/-/npm/v1/security/advisories/bulk" ∧
      nats req.path.val ≠ lit "/npm/-/npm/v1/security/audits/quick" := by
    simpa [isNpmAudit] using hn
  have hweb : isWebSurface (nats req.path.val) = true →
      cfg.anonymous_read = false ∧ cfg.public_web_ui = false := by
    intro hb
    cases hr : cfg.anonymous_read <;> cases hu : cfg.public_web_ui <;>
      simp_all [IsOpen]
  have hmet : nats req.path.val = lit "/metrics" → cfg.public_metrics = false := by
    intro hb
    cases hm : cfg.public_metrics <;> simp_all [IsOpen]
  simp only [nats, lit_values] at hp ha hweb hmet
  have hgate_result : (if List.map (fun x : U8 => x.val) req.path.val =
      [47, 109, 101, 116, 114, 105, 99, 115] then ok cfg.public_metrics else ok false) =
      (ok false : Result Bool) := by
    split
    · simp [hmet (by assumption)]
    · rfl
  cases hm : req.method <;> simp only [hm, isWriteMethod, Bool.false_eq_true] at hw
  all_goals
    unfold middleware.auth_middleware at h
    simp only [he, if_true, public_path_eq, web_surface_eq,
      bytes_eq_eq, lift, bind_ok, if_false, Bool.false_eq_true,
      alloc.vec.Vec.deref, Array.to_slice, Array.make, Array.from_val, Slice.from_val,
      nats, List.map_cons, List.map_nil, UScalar.ofNatCore_val_eq,
      hp, ha.1, ha.2, decide_false, decide_eq_true_eq, hgate_result, hm,
      middleware.HttpMethod.Insts.CoreCmpPartialEqHttpMethod.eq,
      middleware.HttpMethod.read_discriminant] at h
    cases hb : isWebSurface (List.map (fun x : U8 => x.val) req.path.val)
    · simp only [hb, Bool.false_eq_true, if_false, bind_ok] at h
      simp -failIfUnchanged only [uncurry_apply_pair, Bool.false_eq_true,
        ↓reduceIte, ite_self, bind_ok] at h
      clear ho hn hp ha hweb hmet hgate_result
      invert_pairs h
      all_goals first
        | exact bearer_write _ _ _ _ _ _ _ _ _ _ _ _ (by simp [hm, isWriteMethod]) h
        | exact basic_write _ _ _ _ _ _ _ _ _ _ _ (by simp [hm, isWriteMethod]) h
    · obtain ⟨hr, hu⟩ := hweb hb
      simp only [hb, hr, hu, if_true, if_false, Bool.false_eq_true,
        bind_ok] at h
      simp -failIfUnchanged only [uncurry_apply_pair, Bool.false_eq_true,
        ↓reduceIte, ite_self, bind_ok] at h
      clear ho hn hp ha hweb hmet hgate_result
      invert_pairs h
      all_goals first
        | exact bearer_write _ _ _ _ _ _ _ _ _ _ _ _ (by simp [hm, isWriteMethod]) h
        | exact basic_write _ _ _ _ _ _ _ _ _ _ _ (by simp [hm, isWriteMethod]) h

end nora_kernel.Solution
