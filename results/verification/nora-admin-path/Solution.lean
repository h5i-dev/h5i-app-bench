import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

namespace nora_kernel.Solution

theorem starts_with_spec (s p : Slice U8) :
    middleware.starts_with s p ⦃ b => b = decide (p.val <+: s.val) ⦄ := by
  unfold middleware.starts_with; simp only []
  split
  · simp only [WP.spec_ok]
    have : ¬ p.val <+: s.val := fun h => by have := h.length_le; scalar_tac
    simp [this]
  · unfold middleware.starts_with_loop
    apply loop.spec_decr_nat (measure := fun (j : Usize) => p.length - j.val)
      (inv := fun j => j.val ≤ p.length ∧ ∀ k < j.val, s.val[k]! = p.val[k]!)
    · rintro j ⟨hj, hk⟩
      unfold middleware.starts_with_loop.body; simp only []
      step*
      · have : ¬ p.val <+: s.val := fun h => by
          have := h.getElem (i := j.val) (by scalar_tac); simp_all; contradiction
        simp [this]
      · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
        intro k hk'
        rcases Nat.lt_succ_iff_lt_or_eq.1 (show k < j.val + 1 by scalar_tac) with h1 | h1
        · exact hk k h1
        · subst h1
          rw [List.getElem!_eq_getElem?_getD, List.getElem!_eq_getElem?_getD,
            List.getElem?_eq_getElem (by scalar_tac), List.getElem?_eq_getElem (by scalar_tac)]
          simp only [Option.getD_some]
          apply UScalar.eq_of_val_eq
          simp_all
      · have hl : (p.val).length ≤ (s.val).length := by scalar_tac
        have : p.val <+: s.val := by
          rw [prefix_iff_take]; refine ⟨hl, ?_⟩
          apply List.ext_getElem (by simp; omega)
          intro n h1 h2
          have := hk n (by scalar_tac)
          simp at this
          rw [List.getElem?_eq_getElem (by omega)] at this
          simpa [List.getElem?_eq_getElem h2] using this
        simp [this]
    · simp
theorem bytes_eq_spec (a b : Slice U8) :
    oracle.bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold oracle.bytes_eq; simp only []
  split
  · simp only [WP.spec_ok]
    have : a.val ≠ b.val := fun h => by simp_all
    simp [this]
  · unfold oracle.bytes_eq_loop
    apply loop.spec_decr_nat (measure := fun (j : Usize) => a.length - j.val)
      (inv := fun j => j.val ≤ a.length ∧ ∀ k < j.val, a.val[k]! = b.val[k]!)
    · rintro j ⟨hj, hk⟩
      unfold oracle.bytes_eq_loop.body; simp only []
      step*
      · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
        intro k hk'
        rcases Nat.lt_succ_iff_lt_or_eq.1 (show k < j.val + 1 by scalar_tac) with h1 | h1
        · exact hk k h1
        · subst h1
          rw [List.getElem!_eq_getElem?_getD, List.getElem!_eq_getElem?_getD,
            List.getElem?_eq_getElem (by scalar_tac), List.getElem?_eq_getElem (by scalar_tac)]
          simp only [Option.getD_some]
          apply UScalar.eq_of_val_eq
          simp_all
      · have hl : (a.val).length = (b.val).length := by scalar_tac
        have : a.val = b.val := by
          apply List.ext_getElem hl
          intro n h1 h2
          have := hk n (by scalar_tac)
          simp at this
          rw [List.getElem?_eq_getElem (by omega)] at this
          simpa [List.getElem?_eq_getElem h2] using this
        simp [this]
    · simp

@[simp] theorem can_admin_iff {role : Role} : Role.can_admin role = ok true ↔ role = .Admin := by
  cases role <;> simp [Role.can_admin]

theorem token_identity_admin {wr : alloc.vec.Vec middleware.Write} {ip : Option net.IpAddr}
    {m : middleware.HttpMethod} {user : alloc.vec.Vec U8} {role : Role}
    {ws a u r} (h : middleware.token_identity wr ip m true user role = ok (ws, .Next a u r)) :
    r = some .Admin := by
  unfold middleware.token_identity at h
  h5i_invert h
  all_goals simp_all


-- Peel `h` down to its successful paths, destructuring the pairs that
-- `h5i_invert` leaves as `let (x, y) := p`.
set_option hygiene false in
macro "invert_all" : tactic => `(tactic| (
  h5i_invert h
  iterate 10 (all_goals (try (first
    | (split at h <;> h5i_invert h)
    | (cases_type* Prod; simp at h <;> h5i_invert h))))))

theorem bearer_admin {cfg cr fs jw req tok ip ws a u r}
    (h : middleware.bearer cfg cr fs jw req tok ip true = ok (ws, .Next a u r)) :
    r = some .Admin := by
  unfold middleware.bearer at h
  invert_all
  all_goals first
    | exact token_identity_admin h
    | simp_all

theorem basic_admin {cfg cr fs req hdr ip ws a u r}
    (h : middleware.basic cfg cr fs req hdr ip true = ok (ws, .Next a u r)) :
    r = some .Admin := by
  unfold middleware.basic at h
  invert_all
  all_goals first
    | exact token_identity_admin h
    | simp_all

theorem sw_eq (s p : Slice U8) :
    middleware.starts_with s p = ok (decide (nats p.val <+: nats s.val)) := by
  rw [eq_ok_of_spec (starts_with_spec s p)]
  simp only [nats, List.prefix_map_iff_of_injective (f := fun (x : U8) => x.val)
    (fun _ _ h => UScalar.eq_of_val_eq h)]

theorem be_eq (a b : Slice U8) :
    oracle.bytes_eq a b = ok (decide (nats a.val = nats b.val)) := by
  rw [eq_ok_of_spec (bytes_eq_spec a b)]
  simp only [nats, (List.map_injective_iff.2 (fun _ _ h => UScalar.eq_of_val_eq h) :
    Function.Injective (List.map (fun (x : U8) => x.val))).eq_iff]

theorem lit_admin : lit "/api/v1/admin/" = [47, 97, 112, 105, 47, 118, 49, 47, 97, 100, 109, 105, 110, 47] := by
  decide +kernel

theorem admin_path_needs_admin (cfg : middleware.Config) (fs : Slice lockout.FailureEntry)
    (cr : oracle.Crypto) (jw : Option middleware.Jwt) (req : middleware.Request)
    (ws : alloc.vec.Vec middleware.Write) (a : NamespaceAuthority) (u : alloc.vec.Vec U8) (r : Option Role)
    (he : cfg.enabled = true) (hp : isAdminPath (nats req.path.val))
    (h : middleware.auth_middleware cfg fs cr jw req = ok (ws, .Next a u r)) :
    r = some .Admin := by
  unfold isAdminPath at hp
  rw [lit_admin, List.isPrefixOf_iff_prefix] at hp
  obtain ⟨t, ht⟩ := hp
  unfold middleware.auth_middleware at h
  simp only [he, ite_true, sw_eq, be_eq, middleware.is_public_path, middleware.is_web_surface,
    middleware.is_docker_path, middleware.is_admin_path] at h
  simp only [nats] at ht
  simp [nats, Array.make, lift, alloc.vec.Vec.deref, ← ht] at h
  invert_all
  all_goals first
    | exact bearer_admin h
    | exact basic_admin h
    | simp at h

end nora_kernel.Solution
