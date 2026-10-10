import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

namespace nora_kernel.Solution

set_option maxHeartbeats 2000000
set_option maxRecDepth 4096

macro "lit_eval" : tactic => `(tactic| (
  unfold lit
  simp only [String.toUTF8_eq_toByteArray]
  rw [← String.utf8Encode_toList]
  conv_lhs => simp [List.utf8Encode, String.utf8EncodeChar]
  cbv))

@[simp] theorem lit_root : lit "/" = [47] := by lit_eval
@[simp] theorem lit_health : lit "/health" = [47, 104, 101, 97, 108, 116, 104] := by lit_eval
@[simp] theorem lit_ready : lit "/ready" = [47, 114, 101, 97, 100, 121] := by lit_eval
@[simp] theorem lit_tokens : lit "/api/tokens" = [47, 97, 112, 105, 47, 116, 111, 107, 101, 110, 115] := by lit_eval
@[simp] theorem lit_list : lit "/api/tokens/list" = [47, 97, 112, 105, 47, 116, 111, 107, 101, 110, 115, 47, 108, 105, 115, 116] := by lit_eval
@[simp] theorem lit_revoke : lit "/api/tokens/revoke" = [47, 97, 112, 105, 47, 116, 111, 107, 101, 110, 115, 47, 114, 101, 118, 111, 107, 101] := by lit_eval
@[simp] theorem lit_ui_tokens : lit "/ui/tokens" = [47, 117, 105, 47, 116, 111, 107, 101, 110, 115] := by lit_eval
@[simp] theorem lit_api_ui_tokens : lit "/api/ui/tokens" = [47, 97, 112, 105, 47, 117, 105, 47, 116, 111, 107, 101, 110, 115] := by lit_eval
@[simp] theorem lit_ui : lit "/ui" = [47, 117, 105] := by lit_eval
@[simp] theorem lit_api_ui : lit "/api/ui" = [47, 97, 112, 105, 47, 117, 105] := by lit_eval
@[simp] theorem lit_docs : lit "/api-docs" = [47, 97, 112, 105, 45, 100, 111, 99, 115] := by lit_eval
@[simp] theorem lit_metrics : lit "/metrics" = [47, 109, 101, 116, 114, 105, 99, 115] := by lit_eval

theorem anonymous_spec : middleware.anonymous ⦃ v => nats v.val = lit "anonymous" ⦄ := by
  unfold middleware.anonymous
  step*
  simp_all [alloc.vec.Vec.val, nats, lit, Array.to_slice, Array.make]
  rw [← String.utf8Encode_toList]
  simp [List.utf8Encode, String.utf8EncodeChar, List.toByteArray, ByteArray.toList]
  cbv

theorem starts_with_spec (s p : Slice U8) :
    middleware.starts_with s p ⦃ b => b = decide (p.val <+: s.val) ⦄ := by
  unfold middleware.starts_with
  dsimp only
  split
  · rename_i hlen
    simp only [WP.spec_ok]
    have hn : ¬ p.val <+: s.val := by
      intro hpre
      have := hpre.length_le
      scalar_tac
    simp [hn]
  · rename_i hlen
    have hlen' : p.val.length ≤ s.val.length := by scalar_tac
    unfold middleware.starts_with_loop
    apply loop_idx_spec _ (fun i => i) p.val.length
      (fun i => ∀ j, j < i.val → p.val[j]? = s.val[j]?) _ ?_ 0#usize (by simp) (by simp)
    intro i hpre hi
    unfold middleware.starts_with_loop.body
    step*
    · have hip : i.val < p.val.length := by scalar_tac
      have hn : ¬ p.val <+: s.val := by
        intro h
        have heq := h.getElem hip
        simp_all
        contradiction
      simp [hn]
    · refine ⟨?_, by omega, by scalar_tac⟩
      intro j hj
      by_cases hj' : j < i.val
      · exact hpre j hj'
      · have hjEq : j = i.val := by omega
        subst j
        have hip : i.val < p.val.length := by scalar_tac
        have his : i.val < s.val.length := by omega
        rw [List.getElem?_eq_getElem hip, List.getElem?_eq_getElem his]
        congr 1
        scalar_tac
    · have heq : i.val = p.val.length := by scalar_tac
      have hpref : p.val <+: s.val := by
        apply List.prefix_iff_getElem?.mpr
        intro j hj
        rw [← hpre j (by omega), List.getElem?_eq_getElem hj]
      simp [hpref]

@[simp] theorem nats_eq_iff (p s : List U8) : nats p = nats s ↔ p = s :=
  List.map_inj_right (fun _ _ h => UScalar.eq_of_val_eq h)

@[simp] theorem nats_prefix_iff (p s : List U8) : nats p <+: nats s ↔ p <+: s := by
  induction p generalizing s with
  | nil => simp [nats]
  | cons x xs ih =>
    cases s with
    | nil => simp [nats]
    | cons y ys =>
      simp_all [nats, List.cons_prefix_cons]
      intro _
      exact ⟨UScalar.eq_of_val_eq, fun h => congrArg UScalar.val h⟩

@[step] theorem starts_with_nats_spec (s p : Slice U8) :
    middleware.starts_with s p ⦃ b => b = (nats p.val).isPrefixOf (nats s.val) ⦄ := by
  apply WP.spec_mono (starts_with_spec s p)
  intro b hb
  rw [hb]
  apply Bool.eq_iff_iff.mpr
  simp

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    oracle.bytes_eq a b ⦃ r => r = decide (nats a.val = nats b.val) ⦄ := by
  unfold oracle.bytes_eq
  dsimp only
  split
  · rename_i hlen
    have hn : a.val ≠ b.val := by
      intro heq
      have := congrArg List.length heq
      simp_all
    simp [hn]
  · rename_i hlen
    have hl : a.val.length = b.val.length := by simpa using hlen
    have hloop : oracle.bytes_eq_loop a b 0#usize = middleware.starts_with_loop a b 0#usize := by
      unfold oracle.bytes_eq_loop middleware.starts_with_loop
      congr 1
      funext i
      unfold oracle.bytes_eq_loop.body middleware.starts_with_loop.body
      rw [show a.len = b.len by scalar_tac]
    rw [hloop]
    have hs := starts_with_spec a b
    simp only [middleware.starts_with] at hs
    have hlt : ¬ a.len < b.len := by scalar_tac
    simp only [hlt, reduceIte] at hs
    apply WP.spec_mono hs
    intro r hr
    rw [hr]
    apply decide_eq_decide.mpr
    simp only [nats_eq_iff]
    constructor
    · intro hp
      exact (hp.eq_of_length hl.symm).symm
    · intro heq
      rw [heq]

@[step] theorem public_path_spec (p : Slice U8) :
    middleware.is_public_path p ⦃ b => b = isPublicPath (nats p.val) ⦄ := by
  unfold middleware.is_public_path
  step*
  all_goals simp_all [isPublicPath, nats, Array.to_slice, Array.make]

@[step] theorem web_surface_spec (p : Slice U8) :
    middleware.is_web_surface p ⦃ b => b = isWebSurface (nats p.val) ⦄ := by
  unfold middleware.is_web_surface
  step*
  all_goals simp_all [isWebSurface, isTokenPage, nats, Array.to_slice, Array.make]

/-- The configuration adjustments and open-path decision at the start of the middleware. -/
def open_choice (cfg : middleware.Config) (path : alloc.vec.Vec U8) (b : Bool) :
    Result (Bool × Bool × Bool) := do
  if b then ok (cfg.anonymous_read, cfg.public_web_ui, true)
  else
    let web ← middleware.is_web_surface path.deref
    if web then
      if cfg.anonymous_read then ok (true, cfg.public_web_ui, true)
      else
        let (ui, op) ←
          if cfg.public_web_ui then ok (true, true)
          else do
            let s ← lift (Array.to_slice (Array.make 8#usize
              [47#u8, 109#u8, 101#u8, 116#u8, 114#u8, 105#u8, 99#u8, 115#u8]))
            let metrics ← oracle.bytes_eq path.deref s
            let op ← if metrics then ok cfg.public_metrics else ok false
            ok (false, op)
        ok (false, ui, op)
    else
      let s ← lift (Array.to_slice (Array.make 8#usize
        [47#u8, 109#u8, 101#u8, 116#u8, 114#u8, 105#u8, 99#u8, 115#u8]))
      let metrics ← oracle.bytes_eq path.deref s
      let op ← if metrics then ok cfg.public_metrics else ok false
      ok (cfg.anonymous_read, cfg.public_web_ui, op)

theorem open_choice_spec (cfg : middleware.Config) (path : alloc.vec.Vec U8) (b : Bool)
    (hpub : b = isPublicPath (nats path.val)) :
    open_choice cfg path b ⦃ t => t.2.2 = true → IsOpen cfg (nats path.val) ⦄ := by
  unfold open_choice
  h5i_steps
  all_goals simp_all [IsOpen, nats, Array.to_slice, Array.make,
    alloc.vec.Vec.deref, alloc.vec.Vec.val]

theorem locked_out_only_open (cfg : middleware.Config) (fs : Slice lockout.FailureEntry)
    (cr : oracle.Crypto) (jw : Option middleware.Jwt) (req : middleware.Request)
    (ws : alloc.vec.Vec middleware.Write) (a : NamespaceAuthority) (u : alloc.vec.Vec U8) (r : Option Role)
    (peer ip : net.IpAddr) (secs : U64)
    (he : cfg.enabled = true) (hp : req.peer = some peer)
    (hip : net.resolve_client_ip peer req.xff req.x_real_ip cfg.trusted_proxies = ok ip)
    (hb : lockout.AuthFailureTracker.check_blocked cfg.tracker fs ip req.mono = ok (some secs))
    (hu : nats u.val ≠ lit "anonymous")
    (h : middleware.auth_middleware cfg fs cr jw req = ok (ws, .Next a u r)) :
    IsOpen cfg (nats req.path.val) := by
  obtain ⟨anon, hanon⟩ := ok_of anonymous_spec
  have hne : anon ≠ u := by
    intro heq
    apply hu
    have ha := post_of_ok (x := anon) anonymous_spec hanon
    simpa [heq] using ha
  simp only [middleware.auth_middleware, he, reduceIte] at h
  have hbind := bind_tc_eq_ok.mp h
  clear h
  rcases hbind with ⟨b, hpub, h⟩
  have hbind := bind_tc_eq_ok.mp h
  clear h
  rcases hbind with ⟨⟨b1, b2, op⟩, hopen, h⟩
  change open_choice cfg req.path b = ok (b1, b2, op) at hopen
  by_cases ho : op = true
  · have hpub' := post_of_ok (public_path_spec req.path.deref) hpub
    have hp' : b = isPublicPath (nats req.path.val) := by
      simpa [alloc.vec.Vec.deref, alloc.vec.Vec.val] using hpub'
    exact post_of_ok (open_choice_spec cfg req.path b hp') hopen ho
  · clear hopen hpub
    simp (config := { zetaHave := true }) [ho, hp, hip, hb, hanon] at h
    simp (config := { maxSteps := 1000000, zetaHave := true })
      [bind_tc_eq_ok, ite_eq_iff, Prod.exists, hne] at h

end nora_kernel.Solution
