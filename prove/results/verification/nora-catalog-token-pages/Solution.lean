import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

namespace nora_kernel.Solution

-- Evaluate the UTF-8 literals through their character lists.
private theorem literal_bytes (s : String) :
    lit s = s.toList.utf8Encode.toList.map (·.toNat) := by
  simp only [lit, String.toUTF8_eq_toByteArray, String.utf8Encode_toList]

macro "normalize_paths" : tactic => `(tactic|
  simp [literal_bytes, List.utf8Encode, String.utf8EncodeChar,
    ByteArray.toList, ByteArray.toList.loop, List.data_toByteArray, ByteArray.get!])

@[simp] private theorem root_bytes : lit "/" = [47] := by normalize_paths
@[simp] private theorem health_bytes : lit "/health" = [47,104,101,97,108,116,104] := by normalize_paths
@[simp] private theorem ready_bytes : lit "/ready" = [47,114,101,97,100,121] := by normalize_paths
@[simp] private theorem api_tokens_bytes : lit "/api/tokens" = [47,97,112,105,47,116,111,107,101,110,115] := by normalize_paths
@[simp] private theorem list_tokens_bytes : lit "/api/tokens/list" = [47,97,112,105,47,116,111,107,101,110,115,47,108,105,115,116] := by normalize_paths
@[simp] private theorem revoke_tokens_bytes : lit "/api/tokens/revoke" = [47,97,112,105,47,116,111,107,101,110,115,47,114,101,118,111,107,101] := by normalize_paths
@[simp] private theorem ui_tokens_bytes : lit "/ui/tokens" = [47,117,105,47,116,111,107,101,110,115] := by normalize_paths
@[simp] private theorem api_ui_tokens_bytes : lit "/api/ui/tokens" = [47,97,112,105,47,117,105,47,116,111,107,101,110,115] := by normalize_paths
@[simp] private theorem ui_bytes : lit "/ui" = [47,117,105] := by normalize_paths
@[simp] private theorem api_ui_bytes : lit "/api/ui" = [47,97,112,105,47,117,105] := by normalize_paths
@[simp] private theorem docs_bytes : lit "/api-docs" = [47,97,112,105,45,100,111,99,115] := by normalize_paths
@[simp] private theorem docker_bytes : lit "/v2" = [47,118,50] := by normalize_paths
@[simp] private theorem docker_prefix_bytes : lit "/v2/" = [47,118,50,47] := by normalize_paths
@[simp] private theorem catalog_bytes : lit "/v2/_catalog" = [47,118,50,47,95,99,97,116,97,108,111,103] := by normalize_paths
@[simp] private theorem metrics_bytes : lit "/metrics" = [47,109,101,116,114,105,99,115] := by normalize_paths

@[simp] private theorem prefix_bool (p s : List Nat) : p.isPrefixOf s = decide (p <+: s) := by
  apply Bool.eq_iff_iff.mpr
  simp only [List.isPrefixOf_iff_prefix, decide_eq_true_eq]

-- Every byte before the loop index has already matched.
private theorem starts_loop_spec (s p : Slice U8) (hlen : p.val.length ≤ s.val.length) :
    middleware.starts_with_loop s p 0#usize ⦃ b => b = decide (p.val <+: s.val) ⦄ := by
  unfold middleware.starts_with_loop
  apply loop_idx_spec _ id p.val.length
    (fun i => ∀ j, j < i.val → ∀ (hp : j < p.val.length) (hs : j < s.val.length),
      p.val[j] = s.val[j]) _ ?_ _ (by simp) (by simp)
  intro i hi hn
  unfold middleware.starts_with_loop.body
  step* <;> simp only [id_eq] at *
  · have hlt : i.val < p.val.length := by scalar_tac
    have hne : s.val[i.val] ≠ p.val[i.val] := by simpa [i2_post, i3_post] using ‹(i2 != i3) = true›
    symm
    apply decide_eq_false
    intro hp
    exact hne (hp.getElem hlt).symm
  · refine ⟨?_, by scalar_tac, by scalar_tac⟩
    intro j hj hp hs
    by_cases hji : j < i.val
    · exact hi j hji hp hs
    · have heq : j = i.val := by scalar_tac
      subst j
      have heq : i2 = i3 := (u8_eq_iff _ _).mpr (by simpa using ‹¬(i2 != i3) = true›)
      simpa [i2_post, i3_post] using heq.symm
  · symm
    apply decide_eq_true
    apply List.prefix_iff_getElem.mpr
    refine ⟨hlen, ?_⟩
    intro j hj
    exact hi j (by scalar_tac) hj (by omega)

@[step] private theorem starts_spec (s p : Slice U8) :
    middleware.starts_with s p ⦃ b => b = decide (nats p.val <+: nats s.val) ⦄ := by
  have hm : (nats p.val <+: nats s.val) ↔ p.val <+: s.val :=
    List.prefix_map_iff_of_injective (fun _ _ h => (u8_eq_iff _ _).mpr h)
  unfold middleware.starts_with
  dsimp only
  split
  · rename_i hlt
    have hn : ¬p.val <+: s.val := fun hp => by have := hp.length_le; scalar_tac
    simp [hn, hm]
  · rename_i hlt
    simpa [hm] using starts_loop_spec s p (by scalar_tac)

@[step] private theorem bytes_spec (a b : Slice U8) :
    oracle.bytes_eq a b ⦃ r => r = decide (nats a.val = nats b.val) ⦄ := by
  have hm : (nats a.val = nats b.val) ↔ a.val = b.val := by
    apply List.map_inj_right
    intro x y h
    exact (u8_eq_iff _ _).mpr h
  unfold oracle.bytes_eq
  dsimp only
  split
  · rename_i hn
    have hne : a.val ≠ b.val := fun h => by simp [Slice.len, h] at hn
    simp [hm, hne]
  · rename_i hn
    have hlen : a.val.length = b.val.length := by scalar_tac
    have hb : oracle.bytes_eq_loop.body a b = middleware.starts_with_loop.body a b := by
      funext i
      simp only [oracle.bytes_eq_loop.body, middleware.starts_with_loop.body, Slice.len, hlen]
    have hs := starts_loop_spec a b (by omega)
    have hp : (b.val <+: a.val) ↔ a.val = b.val :=
      ⟨fun h => (h.eq_of_length hlen.symm).symm, fun h => h ▸ List.prefix_refl _⟩
    simpa only [oracle.bytes_eq_loop, hb, middleware.starts_with_loop, hp, hm] using hs

@[step] private theorem public_spec (p : Slice U8) :
    middleware.is_public_path p ⦃ b => b = isPublicPath (nats p.val) ⦄ := by
  unfold middleware.is_public_path
  step* <;> simp_all [isPublicPath, nats, Array.make]

@[step] private theorem web_spec (p : Slice U8) :
    middleware.is_web_surface p ⦃ b => b = isWebSurface (nats p.val) ⦄ := by
  unfold middleware.is_web_surface
  step* <;> simp_all [isWebSurface, isTokenPage, nats, Array.make]

@[step] private theorem docker_spec (p : Slice U8) :
    middleware.is_docker_path p ⦃ b =>
      b = (decide (nats p.val = lit "/v2") || (lit "/v2/").isPrefixOf (nats p.val)) ⦄ := by
  unfold middleware.is_docker_path
  step* <;> simp_all [nats, Array.make]

private theorem protected_closed (p : List Nat)
    (hp : p = lit "/v2/_catalog" ∨ isTokenPage p) :
    isPublicPath p = false ∧ isWebSurface p = false ∧ p ≠ lit "/metrics" := by
  rcases hp with hc | ht
  · subst p
    simp [isPublicPath, isWebSurface, isTokenPage, List.cons_prefix_iff]
  · have hpub : isPublicPath p = false := by
      simp only [isPublicPath, Bool.or_eq_false_iff]
      repeat' constructor
      all_goals apply decide_eq_false
      all_goals intro heq
      all_goals subst p
      all_goals simp [isTokenPage, List.cons_prefix_iff] at ht
    refine ⟨hpub, by simp [isWebSurface, ht], ?_⟩
    intro heq
    subst p
    simp [isTokenPage, List.cons_prefix_iff] at ht

private theorem bytes_eq (a b : Slice U8) :
    oracle.bytes_eq a b = ok (decide (nats a.val = nats b.val)) :=
  eq_ok_of_spec (bytes_spec a b)

private theorem starts_eq (a b : Slice U8) :
    middleware.starts_with a b = ok (decide (nats b.val <+: nats a.val)) :=
  eq_ok_of_spec (starts_spec a b)

theorem catalog_and_token_pages_need_credentials (cfg : middleware.Config)
    (fs : Slice lockout.FailureEntry) (cr : oracle.Crypto) (jw : Option middleware.Jwt)
    (req : middleware.Request) (ws : alloc.vec.Vec middleware.Write) (o : middleware.Outcome)
    (he : cfg.enabled = true)
    (hp : nats req.path.val = lit "/v2/_catalog" ∨ isTokenPage (nats req.path.val))
    (h : middleware.auth_middleware cfg fs cr jw req = ok (ws, o)) (hpass : Passes o) :
    req.auth_header ≠ none := by
  obtain ⟨a, u, r, rfl⟩ := hpass
  intro hnone
  -- Protected paths cannot take the public, web, or metrics bypasses.
  obtain ⟨hpub, hweb, hmetrics⟩ := protected_closed (nats req.path.val) hp
  have hpub' := eq_ok_of_spec (public_spec (alloc.vec.Vec.deref req.path))
  have hweb' := eq_ok_of_spec (web_spec (alloc.vec.Vec.deref req.path))
  have hdocker' := eq_ok_of_spec (docker_spec (alloc.vec.Vec.deref req.path))
  conv at hpub' => rhs; simp [alloc.vec.Vec.deref, hpub]
  conv at hweb' => rhs; simp [alloc.vec.Vec.deref, hweb]
  simp only [alloc.vec.Vec.deref] at hpub' hweb' hdocker'
  simp only [middleware.auth_middleware, he, hnone, hpub', hweb', bytes_eq, starts_eq,
    lift, bind_ok, ↓reduceIte, Array.make, array_to_slice_val,
    alloc.vec.Vec.deref] at h
  simp [nats] at hmetrics
  simp [nats, hmetrics] at h
  -- The catalog is a Docker path; token pages have their own anonymous-access gate.
  rcases hp with hc | ht
  · simp [nats] at hc
    simp [hdocker', nats, hc, List.cons_prefix_iff] at h
    h5i_invert h
    all_goals cases x
    all_goals obtain ⟨_, _, hrest⟩ := bind_tc_eq_ok.mp h
    all_goals clear h
    all_goals h5i_invert hrest
    all_goals try cases x
    all_goals simp_all
    all_goals split at hrest
    all_goals h5i_invert hrest
    all_goals simp_all
  · simp only [isTokenPage, Bool.or_eq_true, prefix_bool, decide_eq_true_eq] at ht
    rcases ht with ht | ht
    all_goals rcases ht with ⟨tail, ht⟩
    all_goals simp [nats] at ht
    all_goals simp [hdocker', nats, ← ht, List.cons_prefix_iff] at h
    all_goals h5i_invert h
    all_goals cases x
    all_goals obtain ⟨_, _, hrest⟩ := bind_tc_eq_ok.mp h
    all_goals clear h
    all_goals h5i_invert hrest
    all_goals try cases x
    all_goals simp_all
    all_goals split at hrest
    all_goals h5i_invert hrest
    all_goals simp_all

end nora_kernel.Solution
