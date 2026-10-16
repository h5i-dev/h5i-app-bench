import Verified.Derived
import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

namespace nora_kernel.Verified.NoraTokenUnexpired


/-- `starts_with` returning `true` means `p` is a prefix of `s`. -/
theorem starts_with_true (s p : Slice U8) (h : tokens.starts_with s p = ok true) :
    p.val <+: s.val := by
  unfold tokens.starts_with at h
  dsimp only at h
  split at h
  · simp at h
  rename_i hlen
  refine loop_true_witness _ (fun i : Usize => i.val ≤ p.val.length ∧
      ∀ j (hj : j < i.val), s.val[j]? = p.val[j]?) (fun i => p.val.length - i.val) _ ?_ 0#usize
    (by simp) h
  rintro i r ⟨hi, hpre⟩ hr
  unfold tokens.starts_with_loop.body at hr
  h5i_invert hr
  · simp
  · dsimp only
    have hs := slice_index_ok hi2
    have hp := slice_index_ok hi3
    have e : i2 = i3 := by
      simp at hc_1
      exact UScalar.eq_of_val_eq hc_1
    have := add_ok_val hi4
    refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
    intro j hj
    by_cases hji : j < i.val
    · exact hpre j hji
    · have : j = i.val := by scalar_tac
      subst this
      obtain ⟨_, hs⟩ := hs
      obtain ⟨_, hp⟩ := hp
      simp [*]
  · dsimp only
    intro _
    have hpl : p.val.length ≤ s.val.length := by scalar_tac
    have hip : i.val = p.val.length := by scalar_tac
    refine List.prefix_iff_eq_take.2 (List.ext_getElem? fun j => ?_)
    rw [List.getElem?_take]
    split
    · exact (hpre j (by omega)).symm
    · simp; omega

/-- The token is a prefix-checked `nra_` token. -/
theorem token_prefix (t : Slice U8) (b : Bool) (hb : tokens.starts_with t tokens.TOKEN_PREFIX = ok b)
    (hc : b = true) : lit "nra_" <+: nats t.val := by
  subst hc
  have := (starts_with_true _ _ hb).map (fun x : U8 => x.val)
  have e : tokens.TOKEN_PREFIX.val.map (fun x : U8 => x.val) = lit "nra_" := by
    simp [tokens.TOKEN_PREFIX, lit]
    decide +kernel
  rw [e] at this
  exact this

/-- `find_cached` returns an entry of the cache. -/
theorem find_cached_mem (c : Slice tokens.CachedToken) (k : Slice U8) (x : tokens.CachedToken)
    (h : tokens.find_cached c k = ok (some x)) : x ∈ c.val := by
  unfold tokens.find_cached at h
  refine loop_ok _ (fun _ => True) (fun o => ∀ y, o = some y → y ∈ c.val)
    (fun i : Usize => c.val.length - i.val) ?_ 0#usize _ trivial h x rfl
  intro i r _ hr
  unfold tokens.find_cached_loop.body at hr
  h5i_invert hr
  · simp at hct1
    subst hct1
    simpa using slice_index_ok_mem hct
  · have := add_ok_val hi2
    dsimp only
    refine ⟨trivial, by scalar_tac⟩
  · simp

theorem token_accepted_only_unexpired (store : tokens.TokenStore) (cr : oracle.Crypto)
    (t : Slice U8) (now mono : U64) (ws : alloc.vec.Vec tokens.TokenWrite) (u : alloc.vec.Vec U8) (r : Role)
    (h : tokens.verify_token store cr t now mono = ok (ws, .Ok (u, r))) :
    lit "nra_" <+: nats t.val ∧
      ((∃ c ∈ store.cache.val, c.user = u ∧ c.role = r ∧ now.val ≤ c.expires_at.val) ∨
       (∃ f ∈ store.files.val, ∃ i, f.info = some i ∧ i.user = u ∧ i.role = r ∧
         now.val ≤ i.expires_at.val)) := by
  unfold tokens.verify_token at h
  h5i_invert h
  all_goals try exact h.2.elim
  all_goals refine ⟨token_prefix t b hb hc, ?_⟩
  all_goals first
    | exact Or.inl ⟨cached, vec_deref_val store.cache ▸ find_cached_mem _ _ _ ho, h.2.1, h.2.2, by scalar_tac⟩
    | skip
  all_goals
    simp only [tokens.TokenInfo.Insts.CoreCloneClone.clone.ok_eq, Result.ok.injEq] at hinfo
    subst hinfo
    obtain ⟨writes, hvalid⟩ := x_1
    cases hvalid <;> simp at h <;> h5i_invert h <;>
    exact Or.inr ⟨tf, vec_index_slice_ok_mem htf, _, ‹tf.info = some _›, h.2.1, h.2.2, by scalar_tac⟩

end nora_kernel.Verified.NoraTokenUnexpired
