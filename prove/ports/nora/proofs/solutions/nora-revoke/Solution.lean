import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

h5i_derive_clone Role Role.Insts.CoreCloneClone.clone
h5i_derive_clone tokens.TokenInfo tokens.TokenInfo.Insts.CoreCloneClone.clone
h5i_derive_clone tokens.CachedToken tokens.CachedToken.Insts.CoreCloneClone.clone
namespace nora_kernel.Solution

set_option maxHeartbeats 0
set_option maxRecDepth 100000

theorem starts_with_spec (s p : Slice U8) :
    tokens.starts_with s p ⦃ b => b = decide (p.val <+: s.val) ⦄ := by
  unfold tokens.starts_with; simp only []
  split
  · simp only [WP.spec_ok]
    have : ¬ p.val <+: s.val := fun h => by have := h.length_le; scalar_tac
    simp [this]
  · unfold tokens.starts_with_loop
    apply loop.spec_decr_nat (measure := fun (j : Usize) => p.length - j.val)
      (inv := fun j => j.val ≤ p.length ∧ ∀ k < j.val, s.val[k]! = p.val[k]!)
    · rintro j ⟨hj, hk⟩
      unfold tokens.starts_with_loop.body; simp only []
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

attribute [local step] starts_with_spec bytes_eq_spec

@[step] theorem token_file_clone_spec (f : tokens.TokenFile) :
    tokens.TokenFile.Insts.CoreCloneClone.clone f ⦃ r => r = f ⦄ := by
  cases f with
  | mk pref info =>
    cases info <;> simp [tokens.TokenFile.Insts.CoreCloneClone.clone, u8vec_clone]

def NoPrefixFiles (files : alloc.vec.Vec tokens.TokenFile) (p : Slice U8) : Prop :=
  ∀ f ∈ files.val, f.prefix.val ≠ p.val

def NoPrefixCache (cache : alloc.vec.Vec tokens.CachedToken) (p : Slice U8) : Prop :=
  ∀ c ∈ cache.val, ¬ p.val <+: c.key.val

@[step] theorem remove_file_spec (files : Slice tokens.TokenFile) (p : Slice U8) :
    tokens.remove_file files p ⦃ out => NoPrefixFiles out p ⦄ := by
  unfold tokens.remove_file tokens.remove_file_loop
  apply loop_idx_spec _ (fun x => x.2) files.length
    (fun x => x.1.val.length ≤ x.2.val ∧ NoPrefixFiles x.1 p) _ ?_ _
    (by simp [NoPrefixFiles]) (by simp)
  rintro ⟨out, i⟩ ⟨hlen, hout⟩ hi
  unfold tokens.remove_file_loop.body
  h5i_step [NoPrefixFiles]
  refine ⟨?_, by scalar_tac⟩
  intro f hf
  rcases hf with hf | rfl
  · exact hout f hf
  · simpa [alloc.vec.Vec.deref] using b_post

@[step] theorem invalidate_cache_spec (cache : Slice tokens.CachedToken) (p : Slice U8) :
    tokens.invalidate_cache cache p ⦃ out => NoPrefixCache out p ⦄ := by
  unfold tokens.invalidate_cache tokens.invalidate_cache_loop
  apply loop_idx_spec _ (fun x => x.2) cache.length
    (fun x => x.1.val.length ≤ x.2.val ∧ NoPrefixCache x.1 p) _ ?_ _
    (by simp [NoPrefixCache]) (by simp)
  rintro ⟨out, i⟩ ⟨hlen, hout⟩ hi
  unfold tokens.invalidate_cache_loop.body
  h5i_step [NoPrefixCache]
  refine ⟨?_, by scalar_tac⟩
  intro c hc
  rcases hc with hc | rfl
  · exact hout c hc
  · simpa [alloc.vec.Vec.deref] using b_post

@[step] theorem find_file_none_spec (files : Slice tokens.TokenFile) (p : Slice U8)
    (hn : ∀ f ∈ files.val, f.prefix.val ≠ p.val) :
    tokens.find_file files p ⦃ o => o = none ⦄ := by
  unfold tokens.find_file tokens.find_file_loop
  apply loop_idx_spec _ id files.length (fun _ => True) _ ?_ _ trivial (by simp)
  intro i _ hi
  unfold tokens.find_file_loop.body
  step*
  all_goals dsimp only [id] at *
  · exfalso
    apply hn tf (by rw [tf_post]; exact List.getElem_mem _)
    simp_all [alloc.vec.Vec.deref]
  · exact ⟨by scalar_tac, by scalar_tac⟩

@[step] theorem find_cached_none_spec (cache : Slice tokens.CachedToken) (p key : Slice U8)
    (hn : ∀ c ∈ cache.val, ¬ p.val <+: c.key.val) (hp : p.val <+: key.val) :
    tokens.find_cached cache key ⦃ o => o = none ⦄ := by
  unfold tokens.find_cached tokens.find_cached_loop
  apply loop_idx_spec _ id cache.length (fun _ => True) _ ?_ _ trivial (by simp)
  intro i _ hi
  unfold tokens.find_cached_loop.body
  step*
  all_goals dsimp only [id] at *
  · exfalso
    apply hn ct (by rw [ct_post]; exact List.getElem_mem _)
    have heq : ct.key.val = key.val := by simp_all [alloc.vec.Vec.deref]
    simpa [heq] using hp
  · exact ⟨by scalar_tac, by scalar_tac⟩

@[step] theorem prefix16_spec (key : Slice U8) (hk : 16 ≤ key.val.length) :
    tokens.prefix16 key ⦃ v => v.val = key.val.take 16 ⦄ := by
  unfold tokens.prefix16 tokens.prefix16_loop
  apply loop_idx_spec _ (fun x => x.2) 16
    (fun x => x.1.val = key.val.take x.2.val) _ ?_ _ (by simp) (by simp)
  rintro ⟨out, i⟩ hout hi
  unfold tokens.prefix16_loop.body
  step*
  all_goals dsimp only [Prod.fst, Prod.snd] at *
  · refine ⟨?_, by scalar_tac, by scalar_tac⟩
    have hilt : i.val < key.val.length := by scalar_tac
    have hival : i3.val = i.val + 1 := by scalar_tac
    rw [out1_post, hout, hival, List.take_succ_eq_append_getElem hilt, i2_post]

theorem valid_prefix_length (p : Slice U8)
    (h : tokens.is_valid_hash_prefix p = ok true) : p.val.length = 16 := by
  unfold tokens.is_valid_hash_prefix at h
  dsimp only at h
  split at h
  · simp at h
  · scalar_tac

theorem revoke_removes (store store' : tokens.TokenStore) (p : Slice U8)
    (h : tokens.revoke_token store p = ok (store', .Ok ())) :
    p.val.length = 16 ∧ NoPrefixFiles store'.files p ∧ NoPrefixCache store'.cache p := by
  unfold tokens.revoke_token at h
  h5i_invert h
  all_goals try simp at h
  have hl := valid_prefix_length p (by simpa_all using hb)
  have hf := post_of_ok (remove_file_spec (alloc.vec.Vec.deref store.files) p) hfiles
  have hc := post_of_ok (invalidate_cache_spec (alloc.vec.Vec.deref store.cache) p) hcache
  simp at h
  rw [← h]
  exact ⟨hl, hf, hc⟩

end nora_kernel.Solution

