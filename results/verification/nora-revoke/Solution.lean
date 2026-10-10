import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

namespace nora_kernel.Solution

h5i_derive_clone Role Role.Insts.CoreCloneClone.clone
h5i_derive_clone tokens.TokenInfo tokens.TokenInfo.Insts.CoreCloneClone.clone
h5i_derive_clone tokens.CachedToken tokens.CachedToken.Insts.CoreCloneClone.clone
@[simp] lemma file_clone (f : tokens.TokenFile) :
    tokens.TokenFile.Insts.CoreCloneClone.clone f = ok f := by
  cases f with
  | mk p info => cases info <;> simp [tokens.TokenFile.Insts.CoreCloneClone.clone, u8vec_clone]

lemma bytes_eq_correct (a b : Slice U8) (v : Bool)
    (h : oracle.bytes_eq a b = ok v) : (v = true ↔ a.val = b.val) := by
  unfold oracle.bytes_eq at h
  dsimp only at h
  split at h
  · h5i_invert h
    simp only [Bool.false_eq_true, false_iff]
    intro he
    rename_i hn
    simp [Slice.len, he] at hn
  · rename_i hn
    have hl : a.val.length = b.val.length := by
      simp only [Slice.len] at hn
      scalar_tac
    unfold oracle.bytes_eq_loop at h
    apply loop_idx_ok _ (fun i => i) a.val.length
      (fun i => ∀ k, k < i.val → a.val[k]? = b.val[k]?)
      (fun v => v = true ↔ a.val = b.val) ?_ 0#usize v (by simp) (by simp) h
    intro i r hi hn hr
    unfold oracle.bytes_eq_loop.body at hr
    h5i_invert hr
    · simp only [Bool.false_eq_true, false_iff]
      intro he
      obtain ⟨ha, ea⟩ := slice_index_ok hi2
      obtain ⟨hb, eb⟩ := slice_index_ok hi3
      have he' := congrArg (fun l : List U8 => l[i.val]?) he
      have : i2 = i3 := by simpa [ha, hb, ea, eb] using he'
      simp [this] at hc_1
    · have hnxt : i4.val = i.val + 1 := by have := add_ok_val hi4; scalar_tac
      have he : i2 = i3 := by scalar_tac
      obtain ⟨ha, ea⟩ := slice_index_ok hi2
      obtain ⟨hb, eb⟩ := slice_index_ok hi3
      refine ⟨?_, by omega, by simp only [Slice.len] at hc; scalar_tac⟩
      intro k hk
      by_cases hki : k < i.val
      · exact hi k hki
      · have : k = i.val := by omega
        subst k
        simp [ha, hb, ea, eb, he]
    · simp only [true_iff]
      apply List.ext_getElem hl
      intro k hk hk'
      have hki : k < i.val := by simp only [Slice.len] at hc; scalar_tac
      have := hi k hki
      simpa [List.getElem?_eq_getElem, hk, hk'] using this

lemma starts_with_of_prefix (s p : Slice U8) (v : Bool)
    (hp : p.val <+: s.val) (h : tokens.starts_with s p = ok v) : v = true := by
  unfold tokens.starts_with at h
  dsimp only at h
  split at h
  · rename_i hc
    have := hp.length_le
    simp only [Slice.len] at hc
    scalar_tac
  · unfold tokens.starts_with_loop at h
    apply loop_idx_ok _ (fun i => i) p.val.length (fun _ => True)
      (fun b => b = true) ?_ 0#usize v trivial (by simp) h
    intro i r _ hi hr
    unfold tokens.starts_with_loop.body at hr
    h5i_invert hr
    · obtain ⟨ha, ea⟩ := slice_index_ok hi2
      obtain ⟨hb, eb⟩ := slice_index_ok hi3
      have he : i2 = i3 := by
        rw [← ea, ← eb]
        exact (List.IsPrefix.getElem hp hb).symm
      simp [he] at hc_1
    · have : i4.val = i.val + 1 := by have := add_ok_val hi4; scalar_tac
      exact ⟨trivial, by omega, by simp only [Slice.len] at hc; scalar_tac⟩
    · rfl

lemma push_val {α} (v w : alloc.vec.Vec α) (x : α)
    (h : alloc.vec.Vec.push v x = ok w) : w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  h5i_invert h
  simp

/-- Every retained file has a different prefix from the revoked one. -/
lemma remove_file_excludes (files : Slice tokens.TokenFile) (p : Slice U8)
    (out : alloc.vec.Vec tokens.TokenFile) (h : tokens.remove_file files p = ok out) :
    ∀ f ∈ out.val, f.prefix.val ≠ p.val := by
  unfold tokens.remove_file tokens.remove_file_loop at h
  apply loop_idx_ok _ (fun x => x.2) files.val.length
    (fun x => ∀ f ∈ x.1.val, f.prefix.val ≠ p.val)
    (fun o => ∀ f ∈ o.val, f.prefix.val ≠ p.val) ?_
    (alloc.vec.Vec.new tokens.TokenFile, 0#usize) out (by simp [alloc.vec.Vec.new]) (by simp) h
  rintro ⟨o, i⟩ r hi hn hr
  unfold tokens.remove_file_loop.body at hr
  simp only [file_clone, bind_ok] at hr
  h5i_invert hr
  · have hj : i2.val = i.val + 1 := by have := add_ok_val hi2; scalar_tac
    refine ⟨?_, by simp; omega, by simp only [Slice.len] at hc; dsimp; scalar_tac⟩
    split at hout1
    · h5i_invert hout1
      exact hi
    · rename_i hbfalse
      have he := bytes_eq_correct _ _ _ hb
      simp [alloc.vec.Vec.deref] at he
      have hne : f.prefix.val ≠ p.val := fun hfp => hbfalse (he.mpr hfp)
      rw [push_val o out1 f hout1]
      intro f' hf'
      simp only [List.mem_append, List.mem_singleton] at hf'
      rcases hf' with hm | rfl
      · exact hi f' hm
      · exact hne
  · exact hi

/-- Revocation removes all cached keys extending the revoked prefix. -/
lemma invalidate_cache_excludes (cache : Slice tokens.CachedToken) (p : Slice U8)
    (out : alloc.vec.Vec tokens.CachedToken) (h : tokens.invalidate_cache cache p = ok out) :
    ∀ c ∈ out.val, ¬ p.val <+: c.key.val := by
  unfold tokens.invalidate_cache tokens.invalidate_cache_loop at h
  apply loop_idx_ok _ (fun x => x.2) cache.val.length
    (fun x => ∀ c ∈ x.1.val, ¬ p.val <+: c.key.val)
    (fun o => ∀ c ∈ o.val, ¬ p.val <+: c.key.val) ?_
    (alloc.vec.Vec.new tokens.CachedToken, 0#usize) out (by simp [alloc.vec.Vec.new]) (by simp) h
  rintro ⟨o, i⟩ r hi hn hr
  unfold tokens.invalidate_cache_loop.body at hr
  simp only [tokens.CachedToken.Insts.CoreCloneClone.clone.ok_eq, bind_ok] at hr
  h5i_invert hr
  · have hj : i2.val = i.val + 1 := by have := add_ok_val hi2; scalar_tac
    refine ⟨?_, by simp; omega, by simp only [Slice.len] at hc; dsimp; scalar_tac⟩
    split at hout1
    · h5i_invert hout1
      exact hi
    · rename_i hbfalse
      have hne : ¬ p.val <+: c.key.val := by
        intro hp
        apply hbfalse
        apply starts_with_of_prefix (alloc.vec.Vec.deref c.key) p b _ hb
        simpa [alloc.vec.Vec.deref] using hp
      rw [push_val o out1 c hout1]
      intro c' hc'
      simp only [List.mem_append, List.mem_singleton] at hc'
      rcases hc' with hm | rfl
      · exact hi c' hm
      · exact hne
  · exact hi

lemma find_cached_witness (cache : Slice tokens.CachedToken) (key : Slice U8)
    (res : Option tokens.CachedToken) (h : tokens.find_cached cache key = ok res) :
    ∀ c, res = some c → c ∈ cache.val ∧ c.key.val = key.val := by
  unfold tokens.find_cached tokens.find_cached_loop at h
  apply loop_idx_ok _ (fun i => i) cache.val.length (fun _ => True)
    (fun res => ∀ c, res = some c → c ∈ cache.val ∧ c.key.val = key.val)
    ?_ 0#usize res trivial (by simp) h
  intro i r _ hn hr
  unfold tokens.find_cached_loop.body at hr
  simp only [tokens.CachedToken.Insts.CoreCloneClone.clone.ok_eq, bind_ok] at hr
  h5i_invert hr
  · intro c he
    cases Option.some.inj he
    exact ⟨slice_index_ok_mem hct, by simpa [alloc.vec.Vec.deref] using (bytes_eq_correct _ _ _ hb).mp hc_1⟩
  · have hj : i2.val = i.val + 1 := by have := add_ok_val hi2; scalar_tac
    exact ⟨trivial, by omega, by simp only [Slice.len] at hc; scalar_tac⟩
  · simp

lemma find_file_witness (files : Slice tokens.TokenFile) (p : Slice U8)
    (res : Option Usize) (h : tokens.find_file files p = ok res) :
    ∀ i, res = some i → ∃ f ∈ files.val, f.prefix.val = p.val := by
  unfold tokens.find_file tokens.find_file_loop at h
  apply loop_idx_ok _ (fun i => i) files.val.length (fun _ => True)
    (fun res => ∀ i, res = some i → ∃ f ∈ files.val, f.prefix.val = p.val)
    ?_ 0#usize res trivial (by simp) h
  intro i r _ hn hr
  unfold tokens.find_file_loop.body at hr
  h5i_invert hr
  · intro j he
    exact ⟨tf, slice_index_ok_mem htf, by simpa [alloc.vec.Vec.deref] using (bytes_eq_correct _ _ _ hb).mp hc_1⟩
  · have hj : i2.val = i.val + 1 := by have := add_ok_val hi2; scalar_tac
    exact ⟨trivial, by omega, by simp only [Slice.len] at hc; scalar_tac⟩
  · simp

lemma prefix16_val (key : Slice U8) (out : alloc.vec.Vec U8)
    (h : tokens.prefix16 key = ok out) : out.val = key.val.take 16 := by
  unfold tokens.prefix16 tokens.prefix16_loop at h
  apply loop_idx_ok _ (fun x => x.2) key.val.length
    (fun x => x.2.val ≤ 16 ∧ x.1.val = key.val.take x.2.val)
    (fun o => o.val = key.val.take 16) ?_
    (alloc.vec.Vec.new U8, 0#usize) out (by simp [alloc.vec.Vec.new]) (by simp) h
  rintro ⟨o, i⟩ r ⟨hi, ho⟩ hn hr
  dsimp only at hi ho hn
  unfold tokens.prefix16_loop.body at hr
  h5i_invert hr
  · have hj : i3.val = i.val + 1 := by have := add_ok_val hi3; scalar_tac
    obtain ⟨hk, he⟩ := slice_index_ok hi2
    refine ⟨⟨?_, ?_⟩, ?_, ?_⟩
    · dsimp; scalar_tac
    · dsimp at ho ⊢
      rw [push_val o out1 i2 hout1, ho, hj, List.take_succ_eq_append_getElem hk, he]
    · dsimp; omega
    · dsimp; omega
  · dsimp at ho hn ⊢
    have hieq : i.val = key.val.length := by simp only [Slice.len] at hc_1; scalar_tac
    rw [ho, hieq, List.take_length, List.take_of_length_le (by omega)]
  · dsimp at ho ⊢
    have hieq : i.val = 16 := by scalar_tac
    simpa [hieq] using ho

lemma valid_prefix_length (p : Slice U8) (h : tokens.is_valid_hash_prefix p = ok true) :
    p.val.length = 16 := by
  unfold tokens.is_valid_hash_prefix at h
  dsimp only at h
  split at h
  · h5i_invert h
  · rename_i hc
    simp only [Slice.len] at hc
    scalar_tac

theorem revoked_token_rejected (store store' : tokens.TokenStore) (cr : oracle.Crypto) (p t : Slice U8)
    (sha : alloc.vec.Vec U8) (now mono : U64) (ws : alloc.vec.Vec tokens.TokenWrite)
    (res : core.result.Result (alloc.vec.Vec U8 × Role) tokens.TokenError)
    (hr : tokens.revoke_token store p = ok (store', .Ok ()))
    (hs : oracle.Crypto.sha256_hex cr t = ok sha) (hp : p.val <+: sha.val)
    (h : tokens.verify_token store' cr t now mono = ok (ws, res)) :
    ∃ e, res = .Err e := by
  unfold tokens.revoke_token at hr
  h5i_invert hr
  all_goals try (exact False.elim hr.2)
  obtain ⟨rfl, _⟩ := hr
  have hplen := valid_prefix_length p (hc ▸ hb)
  have hfex := remove_file_excludes _ _ _ hfiles
  have hcex := invalidate_cache_excludes _ _ _ hcache
  have htake : sha.val.take 16 = p.val := by
    simpa [hplen] using (List.prefix_iff_eq_take.mp hp).symm
  -- Both lookup paths are empty for this hash after successful revocation.
  unfold tokens.verify_token at h
  obtain ⟨b, hb, h⟩ := bind_tc_eq_ok.mp h
  cases b
  · h5i_invert h
    exact ⟨tokens.TokenError.InvalidFormat, h.2.symm⟩
  · simp only [↓reduceIte] at h
    obtain ⟨key, hkey, h⟩ := bind_tc_eq_ok.mp h
    have hekey : key = sha := result_ok_inj (hkey.symm.trans hs)
    subst key
    obtain ⟨cached, hcached, h⟩ := bind_tc_eq_ok.mp h
    have hnone : cached = none := by
      cases cached with
      | none => rfl
      | some c =>
        obtain ⟨hm, he⟩ := find_cached_witness _ _ _ hcached c rfl
        simp [alloc.vec.Vec.deref] at hm he
        exact False.elim (hcex c hm (he ▸ hp))
    subst cached
    dsimp only at h
    obtain ⟨pref, hpref, h⟩ := bind_tc_eq_ok.mp h
    have hprefeq : pref.val = p.val := by
      have he := prefix16_val _ _ hpref
      simpa [alloc.vec.Vec.deref, htake] using he
    obtain ⟨found, hfound, h⟩ := bind_tc_eq_ok.mp h
    have hnone : found = none := by
      cases found with
      | none => rfl
      | some i =>
        obtain ⟨f, hm, he⟩ := find_file_witness _ _ _ hfound i rfl
        simp [alloc.vec.Vec.deref] at hm he
        exact False.elim (hfex f hm (he.trans hprefeq))
    subst found
    h5i_invert h
    exact ⟨tokens.TokenError.NotFound, h.2.symm⟩

end nora_kernel.Solution
