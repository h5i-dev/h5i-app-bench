import Verified.Store
import Verified.Delete
import Spec
/-!
# wastebin: the security properties

Each theorem is stated over the extracted kernel and `Spec`; the proofs are in
`Verified/`.
-/
open Aeneas Aeneas.Std Result wastebin_kernel wastebin_kernel.Spec
open H5iAppLib

namespace wastebin_kernel.Properties

/-! ## Deletion -/

/-- A deletion goes through only with a verified `uid` cookie listing the
owner of an existing paste with the requested id; it removes exactly the
rows `deletedBy` names. -/
theorem delete_needs_owner (rows : alloc.vec.Vec Row) (path : Slice U8)
    (uids : Option (alloc.vec.Vec I64)) (rows' : alloc.vec.Vec Row)
    (h : handlers.delete_paste rows path uids = ok (rows', .Ok ())) :
    ∃ us, uids = some us ∧ ∃ pid i, ids.decode path = ok (.Ok pid) ∧ ids.to_i64 pid = ok i ∧
      (∃ x ∈ rows.val, x.id = i ∧ Owns us.val x.uid) ∧ rows'.val = deletedBy rows.val i us.val := by
  obtain ⟨us, hu, pid, i, hd, hi, hr, hx⟩ := Verified.Delete.delete_ok rows path uids rows' h
  exact ⟨us, hu, pid, i, hd, hi, hx, hr⟩

/-- A deletion removes only pastes the cookie's holder owns, and keeps every
other row. -/
theorem delete_removes_only_owned (rows : alloc.vec.Vec Row) (path : Slice U8)
    (uids : Option (alloc.vec.Vec I64)) (rows' : alloc.vec.Vec Row)
    (h : handlers.delete_paste rows path uids = ok (rows', .Ok ())) :
    ∃ us, uids = some us ∧
      (∀ x ∈ rows.val, x ∉ rows'.val → Owns us.val x.uid) ∧
      (∀ x ∈ rows.val, ¬ Owns us.val x.uid → x ∈ rows'.val) := by
  obtain ⟨us, hu, pid, i, hd, hi, hr, -⟩ := Verified.Delete.delete_ok rows path uids rows' h
  refine ⟨us, hu, fun x hx hn => ?_, fun x hx hn => ?_⟩
  · rw [hr] at hn
    simp only [deletedBy, List.mem_filter, not_and, Bool.not_eq_true', Bool.and_eq_false_iff,
      decide_eq_false_iff_not] at hn
    by_contra hc
    exact hn hx (Or.inr hc)
  · rw [hr]
    simp only [deletedBy, List.mem_filter, Bool.not_eq_true', Bool.and_eq_false_iff,
      decide_eq_false_iff_not]
    exact ⟨hx, Or.inr hn⟩

/-- A refused deletion changes nothing. -/
theorem delete_refusal_unchanged (rows : alloc.vec.Vec Row) (path : Slice U8)
    (uids : Option (alloc.vec.Vec I64)) (rows' : alloc.vec.Vec Row) (s : handlers.Status)
    (h : handlers.delete_paste rows path uids = ok (rows', .Err s)) : rows' = rows :=
  Verified.Delete.delete_refused rows path uids rows' s h

/-- Without a verified `uid` cookie a deletion is `403` and changes nothing. -/
theorem delete_without_cookie_forbidden (rows : alloc.vec.Vec Row) (path : Slice U8) :
    handlers.delete_paste rows path none = ok (rows, .Err .Forbidden) :=
  Verified.Delete.delete_no_cookie rows path

end wastebin_kernel.Properties
