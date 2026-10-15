import Verified.RustfsManagementCopies
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsDateValues
/-- Retaining a source timezone never changes the parsed UTC instant. -/
theorem parsed_instant (s : Slice U8) (out : conddata.DateFuncValue)
    (h : dates.parse_value s = ok (some out)) :
    dates.parse_rfc3339 s = ok (some out.unix_nanos) := by
  unfold dates.parse_value at h
  h5i_invert h
  all_goals cases Option.some.inj h; exact ho
/-- A failed timestamp parse cannot produce a dated condition value. -/
theorem rejects_invalid (s : Slice U8) (h : dates.parse_rfc3339 s = ok none) :
    dates.parse_value s = ok none := by
  simp only [dates.parse_value,h,bind_ok]

/-- A UTC designator has zero source offset. -/
theorem utc_offset (s : Slice U8) (out : conddata.DateFuncValue)
    (hz : s.val[s.val.length - 1]? = some 90#u8 ∨ s.val[s.val.length - 1]? = some 122#u8)
    (h : dates.parse_value s = ok (some out)) : out.offset_seconds = 0#i32 := by
  unfold dates.parse_value at h
  h5i_invert h
  all_goals try (cases Option.some.inj h; rfl)
  all_goals
    have ⟨hlt,he⟩ := slice_index_ok hi2
    have hsub := sub_ok_val hi1
    have heq : i1.val = s.val.length - 1 := by scalar_tac
    have hh : s.val[s.val.length - 1]? = some i2 := by
      rw [←heq,List.getElem?_eq_getElem hlt,he]
    rcases hz with hz | hz
    · rw [hh] at hz
      exact False.elim (hc (Option.some.inj hz))
    · have ⟨hlt4,he4⟩ := slice_index_ok hi5
      have hsub4 := sub_ok_val hi4
      have heq4 : i4.val = s.val.length - 1 := by scalar_tac
      have hh4 : s.val[s.val.length - 1]? = some i5 := by
        rw [←heq4,List.getElem?_eq_getElem hlt4,he4]
      rw [hh4] at hz
      exact False.elim (hc_1 (Option.some.inj hz))
end rustfs_kernel.Verified.RustfsDateValues
