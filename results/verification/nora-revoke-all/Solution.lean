import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

namespace nora_kernel.Solution

h5i_derive_all

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


attribute [local step] bytes_eq_spec

def NoUserFiles (fs : alloc.vec.Vec tokens.TokenFile) (user : Slice U8) : Prop :=
  ∀ f ∈ fs.val, ∀ info, f.info = some info → info.user.val ≠ user.val

def NoUserCache (cs : alloc.vec.Vec tokens.CachedToken) (user : Slice U8) : Prop :=
  ∀ c ∈ cs.val, c.user.val ≠ user.val

@[step] theorem token_file_clone_spec (f : tokens.TokenFile) :
    tokens.TokenFile.Insts.CoreCloneClone.clone f ⦃ r => r = f ⦄ := by
  cases f with
  | mk pref info =>
    cases info <;> simp [tokens.TokenFile.Insts.CoreCloneClone.clone, u8vec_clone]

@[step] theorem evict_user_spec (cache : Slice tokens.CachedToken) (user : Slice U8) :
    tokens.evict_user cache user ⦃ out => NoUserCache out user ⦄ := by
  unfold tokens.evict_user tokens.evict_user_loop
  apply loop_idx_spec _ (fun x => x.2) cache.length
    (fun x => x.1.val.length ≤ x.2.val ∧ NoUserCache x.1 user) _ ?_ _
    (by simp [NoUserCache]) (by simp)
  rintro ⟨out, i⟩ ⟨hlen, hout⟩ hi
  unfold tokens.evict_user_loop.body
  h5i_step [NoUserCache]
  refine ⟨?_, by scalar_tac⟩
  intro c hc
  rcases hc with hc | rfl
  · exact hout c hc
  · simpa [alloc.vec.Vec.deref] using b_post

@[step] theorem remove_user_files_spec (files : Slice tokens.TokenFile) (user : Slice U8) :
    tokens.remove_user_files files user ⦃ result => NoUserFiles result.1 user ⦄ := by
  unfold tokens.remove_user_files tokens.remove_user_files_loop
  apply loop_idx_spec _ (fun x => x.2.2) files.length
    (fun x => x.1.val.length + x.2.1.val ≤ x.2.2.val ∧ NoUserFiles x.1 user) _ ?_ _
    (by simp [NoUserFiles]) (by simp)
  rintro ⟨kept, count, i⟩ ⟨hlen, hkept⟩ hi
  unfold tokens.remove_user_files_loop.body
  h5i_step [NoUserFiles]
  all_goals refine ⟨by omega, ?_, by scalar_tac⟩
  all_goals
    intro f hf info hinfo
    rcases hf with hf | rfl
    · exact hkept f hf info hinfo
    · simp_all [alloc.vec.Vec.deref]

theorem revoke_all_effective (store store' : tokens.TokenStore) (cr : oracle.Crypto) (user t : Slice U8)
    (n : Usize) (now mono : U64) (ws : alloc.vec.Vec tokens.TokenWrite) (u : alloc.vec.Vec U8) (r : Role)
    (hr : tokens.revoke_all_for_user store user = ok (store', n)) (hn : 0 < n.val)
    (h : tokens.verify_token store' cr t now mono = ok (ws, .Ok (u, r))) :
    u.val ≠ user.val := by
  have clean : NoUserFiles store'.files user ∧ NoUserCache store'.cache user := by
    have hp : tokens.revoke_all_for_user store user ⦃ result =>
        0 < result.2.val → NoUserFiles result.1.files user ∧ NoUserCache result.1.cache user ⦄ := by
      unfold tokens.revoke_all_for_user
      step*
    exact post_of_ok hp hr hn
  obtain ⟨_, hc | hf⟩ := token_accepted_only_unexpired _ _ _ _ _ _ _ _ h
  · obtain ⟨c, hmem, hu, _, _⟩ := hc
    simpa [← hu] using clean.2 c hmem
  · obtain ⟨f, hmem, info, hi, hu, _, _⟩ := hf
    simpa [← hu] using clean.1 f hmem info hi

end nora_kernel.Solution
