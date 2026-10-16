import SpecUnicode
open rustfs_kernel.Spec
namespace rustfs_kernel.Verified.RustfsUnicodeStructure
set_option maxRecDepth 8192
set_option maxHeartbeats 2000000

theorem whitespace_distinct : UnicodeWhitespace.Nodup := by decide +kernel

theorem whitespace_count : UnicodeWhitespace.length = 25 := by decide +kernel

theorem singleton_keys_distinct :
    (LowerSingletonEntries.map Prod.fst).Nodup := by decide +kernel

theorem singleton_expansion_shape :
    ∀ r ∈ LowerSingletonEntries,
      r.2.2.2 = 1 ∨ (r.1 = 304 ∧ r.2.1 = 105 ∧ r.2.2.1 = 775 ∧ r.2.2.2 = 2) := by
  decide +kernel

theorem singleton_scalar_bounds :
    ∀ r ∈ LowerSingletonEntries,
      r.1 < 0x110000 ∧ r.2.1 < 0x110000 ∧ r.2.2.1 < 0x110000 ∧
      (r.2.1 < 0xD800 ∨ 0xDFFF < r.2.1) ∧
      (r.2.2.1 < 0xD800 ∨ 0xDFFF < r.2.2.1) := by decide +kernel

theorem range_shape (cp : Nat) (rs : List LowerRange) (a b n : Nat)
    (h : LookupLowerRanges cp rs = some (a,b,n)) : b = 0 ∧ n = 1 := by
  induction rs with
  | nil => simp [LookupLowerRanges] at h
  | cons r rs ih =>
    simp only [LookupLowerRanges] at h
    split at h
    · cases h; exact ⟨rfl,rfl⟩
    · exact ih h
theorem range_entries_well_formed :
    ∀ r ∈ LowerRangeEntries,
      r.1 ≤ r.2.1 ∧ r.2.1 < 0x110000 ∧ r.2.2.1 ≤ 2 ∧
      (r.2.2.2 < 0 → (-r.2.2.2).toNat ≤ r.1) ∧
      LowerRangeValue r.1 r < 0x110000 ∧ LowerRangeValue r.2.1 r < 0x110000 ∧
      (LowerRangeValue r.2.1 r < 0xD800 ∨ 0xDFFF < LowerRangeValue r.1 r) := by
  decide +kernel

end rustfs_kernel.Verified.RustfsUnicodeStructure
