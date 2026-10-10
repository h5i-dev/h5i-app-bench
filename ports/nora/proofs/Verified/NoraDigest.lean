import Verified.Derived
import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit

namespace nora_kernel.Verified.NoraDigest

def A256 : List Nat := [115, 104, 97, 50, 53, 54]
def A512 : List Nat := [115, 104, 97, 53, 49, 50]

theorem lit256 : lit "sha256:" = A256 ++ [58] := by decide +kernel
theorem lit512 : lit "sha512:" = A512 ++ [58] := by decide +kernel

theorem eq_prefix (P L : List Nat) (h : ∀ k < P.length, L[k]? = P[k]?) :
    L = P ++ L.drop P.length := by
  induction P generalizing L with
  | nil => simp
  | cons p P ih =>
    cases L with
    | nil => have := h 0 (by simp); simp at this
    | cons x L =>
      have h0 := h 0 (by simp); simp at h0
      have := ih L (fun k hk => by simpa using h (k + 1) (by simp; omega))
      simp [h0]; exact this

theorem hex_ne {x : Nat} (h : isLowerHex x = true) : x ≠ 46 ∧ x ≠ 47 ∧ x ≠ 58 := by
  simp [isLowerHex] at h; omega

theorem shape_cases {L : List Nat} (h : DigestShape L) :
    ((∀ k < 6, L[k]? = A256[k]?) ∧ L.length = 71 ∨ (∀ k < 6, L[k]? = A512[k]?) ∧ L.length = 135) ∧
    (L.drop 7).all isLowerHex ∧ L.findIdx? (· = 58) = some 6 ∧ 46 ∉ L ∧ 47 ∉ L := by
  rcases h with ⟨H, rfl, hl, ha⟩ | ⟨H, rfl, hl, ha⟩ <;>
  · simp only [lit256, lit512, A256, A512] at *
    refine ⟨?_, by simpa using ha, ?_, ?_, ?_⟩
    · first
        | (left; refine ⟨fun k hk => ?_, by simp [hl]⟩; rcases k with _|_|_|_|_|_|k <;> (try simp at hk ⊢); omega)
        | (right; refine ⟨fun k hk => ?_, by simp [hl]⟩; rcases k with _|_|_|_|_|_|k <;> (try simp at hk ⊢); omega)
    · simp [List.findIdx?_cons]
    · intro hm; simp at hm; exact (hex_ne (List.all_eq_true.1 ha _ hm)).1 rfl
    · intro hm; simp at hm; exact (hex_ne (List.all_eq_true.1 ha _ hm)).2.1 rfl

theorem idx6 {L : List Nat} (hc : L.findIdx? (· = 58) = some 6) : L[6]? = some 58 := by
  obtain ⟨h, hp, -⟩ := List.findIdx?_eq_some_iff_getElem.1 hc
  simp at hp; simp [List.getElem?_eq_getElem h, hp]

theorem shape_of {L : List Nat} (hc : L.findIdx? (· = 58) = some 6)
    (ha : (L.drop 7).all isLowerHex) :
    ((∀ k < 6, L[k]? = A256[k]?) ∧ L.length = 71 ∨ (∀ k < 6, L[k]? = A512[k]?) ∧ L.length = 135) →
    DigestShape L := by
  have h6 := idx6 hc
  rintro (⟨hp, hl⟩ | ⟨hp, hl⟩)
  · refine Or.inl ⟨L.drop 7, ?_, by simp [hl], ha⟩
    rw [lit256]
    refine eq_prefix _ L (fun k hk => ?_)
    by_cases k6 : k < 6
    · rw [hp k k6]; simp [A256] at *; rcases k with _|_|_|_|_|_|k <;> simp at k6 ⊢; omega
    · have : k = 6 := by simp [A256] at hk; omega
      subst this; simp [h6, A256]
  · refine Or.inr ⟨L.drop 7, ?_, by simp [hl], ha⟩
    rw [lit512]
    refine eq_prefix _ L (fun k hk => ?_)
    by_cases k6 : k < 6
    · rw [hp k k6]; simp [A512] at *; rcases k with _|_|_|_|_|_|k <;> simp at k6 ⊢; omega
    · have : k = 6 := by simp [A512] at hk; omega
      subst this; simp [h6, A512]

theorem not_both {L : List Nat} (h1 : ∀ k < 6, L[k]? = A256[k]?) (h2 : ∀ k < 6, L[k]? = A512[k]?) :
    False := by
  have := (h1 3 (by omega)).symm.trans (h2 3 (by omega)); simp [A256, A512] at this

theorem key (L : List Nat) (i : Nat) (hi : L.findIdx? (· = 58) = some i) :
    DigestShape L ↔ i = 6 ∧ (((∀ k < 6, L[k]? = A256[k]?) ∧ L.length - i - 1 = 64) ∨
      ((∀ k < 6, L[k]? = A512[k]?) ∧ L.length - i - 1 = 128)) ∧ (L.drop (i + 1)).all isLowerHex := by
  constructor
  · intro hs
    obtain ⟨hc, ha, h6, -, -⟩ := shape_cases hs
    rw [hi] at h6; cases h6
    refine ⟨rfl, ?_, ha⟩
    rcases hc with ⟨hp, hl⟩ | ⟨hp, hl⟩
    · exact Or.inl ⟨hp, by omega⟩
    · exact Or.inr ⟨hp, by omega⟩
  · rintro ⟨rfl, hc, ha⟩
    refine shape_of hi ha ?_
    rcases hc with ⟨hp, hl⟩ | ⟨hp, hl⟩
    · have : 6 < L.length := (List.findIdx?_eq_some_iff_getElem.1 hi).1
      exact Or.inl ⟨hp, by omega⟩
    · have : 6 < L.length := (List.findIdx?_eq_some_iff_getElem.1 hi).1
      exact Or.inr ⟨hp, by omega⟩

@[step] theorem is_lower_hex_spec (c : U8) :
    validation.is_lower_hex c ⦃ b => b = isLowerHex c.val ⦄ := by
  unfold validation.is_lower_hex isLowerHex
  split <;> (try split) <;> (try split) <;> simp_all

@[step] theorem contains_byte_spec (s : Slice U8) (c : U8) :
    validation.contains_byte s c ⦃ b => b = true → c ∈ s.val ⦄ := by
  unfold validation.contains_byte validation.contains_byte_loop
  apply H5iAppLib.loop_idx_spec _ (fun i => i) s.length (fun _ => True) _ ?_ _ trivial (by simp)
  intro i _ hi
  unfold validation.contains_byte_loop.body
  step*
  intro _; subst_vars; apply List.getElem_mem

@[step] theorem contains_pair_spec (s : Slice U8) (a b : U8) :
    validation.contains_pair s a b ⦃ r => r = true → a ∈ s.val ⦄ := by
  unfold validation.contains_pair validation.contains_pair_loop
  apply H5iAppLib.loop_idx_spec _ (fun i => i) (s.length - 1) (fun _ => True) _ ?_ _ trivial (by simp)
  intro i _ hi
  unfold validation.contains_pair_loop.body
  step*
  all_goals first | scalar_tac | (intro _; subst_vars; apply List.getElem_mem)

@[step] theorem find_colon_spec (d : Slice U8) :
    validation.find_colon d ⦃ o => o.map (·.val) = (nats d.val).findIdx? (· = 58) ⦄ := by
  unfold validation.find_colon validation.find_colon_loop
  apply WP.spec_mono (loop_search (nats d.val) (fun x => decide (x = 58)) (Option.map (·.val))
    (fun i _ => some i) none _ ?_ 0#usize (by simp))
  · intro r hr; rw [search_findIdx _ _ _ hr]
  · intro j hj; unfold validation.find_colon_loop.body
    h5i_step [nats]
    refine ⟨by scalar_tac, ?_⟩; rw [← i2_post]; rfl

def isOkR : core.result.Result Unit validation.ValidationError → Bool
  | .Ok _ => true
  | .Err _ => false

@[step] theorem digest_hash_chars_spec (d : Slice U8) (k : Usize) (hk : k.val ≤ d.length) :
    validation.digest_hash_chars d k ⦃ r => r = .Ok () ↔ ((nats d.val).drop k.val).all isLowerHex ⦄ := by
  unfold validation.digest_hash_chars validation.digest_hash_chars_loop
  apply WP.spec_mono (loop_search (nats d.val) (fun x => !isLowerHex x) isOkR
    (fun _ _ => false) true _ ?_ k (by simpa [nats] using hk))
  · intro r hr; rw [searchFrom_const] at hr
    cases r <;> simp_all [isOkR]
  · intro j hj; unfold validation.digest_hash_chars_loop.body
    h5i_step [nats, isOkR]

@[step] theorem prefix_is_spec (d : Slice U8) (len : Usize) (lit : Slice U8) (h : len.val ≤ d.length) :
    validation.prefix_is d len lit ⦃ b => b = true ↔
      len.val = lit.length ∧ ∀ k < len.val, (nats d.val)[k]? = (nats lit.val)[k]? ⦄ := by
  unfold validation.prefix_is
  simp only
  split
  · simp_all
  · unfold validation.prefix_is_loop
    apply WP.spec_mono (loop_search (List.range len.val)
      (fun k => decide ((nats d.val)[k]? ≠ (nats lit.val)[k]?)) id
      (fun _ _ => false) true _ ?_ 0#usize (by simp))
    · intro r hr; simp only [id] at hr; rw [search_all _ _ _ hr]
      have hlen : len.val = lit.length := by simp at *; scalar_tac
      simp [List.all_eq_true, hlen]
    · intro j hj; unfold validation.prefix_is_loop.body
      have hlen : len.val = lit.length := by simp at *; scalar_tac
      h5i_step [nats]
      all_goals
        have hd : j.val < d.val.length := by scalar_tac
        have hl : j.val < lit.val.length := by scalar_tac
        refine ⟨by scalar_tac, ?_⟩
        rw [List.getElem?_eq_getElem hd, List.getElem?_eq_getElem hl]; simp_all

theorem validate_digest_spec (d : Slice U8) :
    validation.validate_digest d ⦃ r => r = .Ok () ↔ DigestShape (nats d.val) ⦄ := by
  have hL : (nats d.val).length = d.len.val := by simp [nats]
  unfold validation.validate_digest
  step*
  · simp only [reduceCtorEq, false_iff]; intro hs
    have := (List.findIdx?_eq_some_iff_getElem.1 (shape_cases hs).2.2.1).1; scalar_tac
  · simp only [reduceCtorEq, false_iff]; intro hs
    have := List.mem_map_of_mem (f := fun x : U8 => x.val) (b_post ‹_›)
    exact (shape_cases hs).2.2.2.1 (by simpa [nats] using this)
  · simp only [reduceCtorEq, false_iff]; intro hs
    have := List.mem_map_of_mem (f := fun x : U8 => x.val) (b1_post ‹_›)
    exact (shape_cases hs).2.2.2.2 (by simpa [nats] using this)
  · simp only [reduceCtorEq, false_iff]; intro hs
    subst_vars; have := (shape_cases hs).2.2.1; simp_all
  all_goals
    subst_vars
    have hi : (nats d.val).findIdx? (· = 58) = some i1.val := by simpa using o_post.symm
    have hlt := (List.findIdx?_eq_some_iff_getElem.1 hi).1
  · scalar_tac
  · scalar_tac
  all_goals rw [key _ _ hi]
  all_goals
    generalize nats d.val = L at *
    simp [nats] at b2_post
    try simp [nats] at b3_post
    have hh : hash_len.val = L.length - i1.val - 1 := by scalar_tac
    try simp only [bne_iff_ne, ne_eq, Decidable.not_not] at *
  · simp only [reduceCtorEq, false_iff]
    rintro ⟨h6, (⟨_, hl⟩ | ⟨hp2, _⟩), _⟩
    · scalar_tac
    · exact not_both (fun k hk => b2_post.2 k (by omega)) hp2
  · rw [r_post]; constructor
    · intro ha; exact ⟨b2_post.1, Or.inl ⟨fun k hk => b2_post.2 k (by omega), by scalar_tac⟩, by rwa [← i4_post]⟩
    · rintro ⟨_, _, ha⟩; rwa [i4_post]
  · simp only [reduceCtorEq, false_iff]
    rintro ⟨h6, (⟨hp1, _⟩ | ⟨_, hl⟩), _⟩
    · exact ‹¬b2 = true› (b2_post.2 ⟨h6, fun k hk => hp1 k (by omega)⟩)
    · scalar_tac
  · rw [r_post]; constructor
    · intro ha; exact ⟨b3_post.1, Or.inr ⟨fun k hk => b3_post.2 k (by omega), by scalar_tac⟩, by rwa [← i4_post]⟩
    · rintro ⟨_, _, ha⟩; rwa [i4_post]
  · simp only [reduceCtorEq, false_iff]
    rintro ⟨h6, (⟨hp1, _⟩ | ⟨hp2, _⟩), _⟩
    · exact ‹¬b2 = true› (b2_post.2 ⟨h6, fun k hk => hp1 k (by omega)⟩)
    · exact ‹¬b3 = true› (b3_post.2 ⟨h6, fun k hk => hp2 k (by omega)⟩)

theorem digest_iff (d : Slice U8) :
    validation.validate_digest d = ok (.Ok ()) ↔ DigestShape (nats d.val) := by
  obtain ⟨r, hr, hp⟩ := (WP.spec_equiv_exists _ _).1 (validate_digest_spec d)
  rw [hr, ← hp]; simp

end nora_kernel.Verified.NoraDigest
