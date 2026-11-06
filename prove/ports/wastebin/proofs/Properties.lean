import Verified.Store
import Verified.Delete
import Verified.Get
import Verified.Burn
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

/-! ## Reading a paste (`Database::get`) -/

/-- Content comes out only for a paste that exists, has not expired, and is
plaintext or opened by the password given; it is the paste's own content
and metadata, flagged `Encrypted` exactly when the paste is encrypted. -/
theorem get_content_needs_password (rows : alloc.vec.Vec Row) (id now : I64) (pw : Option U64)
    (v : alloc.vec.Vec Row) (e : store.Entry)
    (h : store.get rows id now pw = ok (v, .Ok e)) :
    ∃ r, rowOf rows.val id = some r ∧ ¬ Expired r now.val ∧ Opens r pw ∧
      (entryData e).data = r.data ∧ (entryData e).metadata.uid = r.uid ∧
      (entryData e).metadata.title = r.title ∧ isEncrypted e = r.secret.isSome := by
  have := Verified.Get.get_eq rows id now pw v _ h
  obtain ⟨r, hr, he, ho, hd, -, hi⟩ := Verified.Get.getM_ok this.symm
  exact ⟨r, hr, he, ho, by rw [hd], by rw [hd]; rfl, by rw [hd]; rfl, hi⟩

/-- An expired paste is never read: the answer is `NotFound` and the row is
deleted. -/
theorem get_expired_never_read (rows : alloc.vec.Vec Row) (id now : I64) (pw : Option U64) (r : Row)
    (hr : rowOf rows.val id = some r) (he : Expired r now.val) :
    ∃ v, store.get rows id now pw = ok (v, .Err .NotFound) ∧ v.val = without rows.val id := by
  obtain ⟨⟨v, res⟩, hx⟩ := ok_of (Verified.Get.get_spec rows id now pw)
  have := Verified.Get.get_eq rows id now pw v res hx
  rw [Verified.Get.getM_expired hr he] at this
  simp only [Prod.mk.injEq] at this
  exact ⟨v, by rw [hx, this.2], this.1⟩

/-- A missing or wrong password reveals nothing and changes nothing: in
particular it does not burn a burn-after-reading paste. -/
theorem get_wrong_password_keeps_paste (rows : alloc.vec.Vec Row) (id now : I64) (pw : Option U64) (r : Row)
    (hr : rowOf rows.val id = some r) (he : ¬ Expired r now.val) (ho : ¬ Opens r pw) :
    ∃ v, store.get rows id now pw = ok (v, .Err (if pw = none then .NoPassword else .Crypto)) ∧
      v.val = rows.val := by
  obtain ⟨⟨v, res⟩, hx⟩ := ok_of (Verified.Get.get_spec rows id now pw)
  have := Verified.Get.get_eq rows id now pw v res hx
  rw [Verified.Get.getM_closed hr he ho] at this
  simp only [Prod.mk.injEq] at this
  exact ⟨v, by rw [hx, this.2], this.1⟩

/-- A successful read of a burn-after-reading paste deletes it. -/
theorem get_burn_consumes (rows : alloc.vec.Vec Row) (id now : I64) (pw : Option U64)
    (v : alloc.vec.Vec Row) (e : store.Entry) (r : Row)
    (h : store.get rows id now pw = ok (v, .Ok e)) (hr : rowOf rows.val id = some r) (hb : Burns r) :
    v.val = without rows.val id := by
  have := Verified.Get.get_eq rows id now pw v _ h
  obtain ⟨r', hr', -, -, -, hv, -⟩ := Verified.Get.getM_ok this.symm
  rw [hr] at hr'; cases hr'
  simpa [hb] using hv

/-- Reading a paste that does not burn changes nothing. -/
theorem get_keeps_unburned (rows : alloc.vec.Vec Row) (id now : I64) (pw : Option U64)
    (v : alloc.vec.Vec Row) (e : store.Entry) (r : Row)
    (h : store.get rows id now pw = ok (v, .Ok e)) (hr : rowOf rows.val id = some r) (hb : ¬ Burns r) :
    v.val = rows.val := by
  have := Verified.Get.get_eq rows id now pw v _ h
  obtain ⟨r', hr', -, -, -, hv, -⟩ := Verified.Get.getM_ok this.symm
  rw [hr] at hr'; cases hr'
  simpa [hb] using hv

/-- After a burn-after-reading paste was read, every later read, with any
password at any time, is `NotFound` and changes nothing. -/
theorem burn_second_read_not_found (rows : alloc.vec.Vec Row) (id now : I64) (pw : Option U64)
    (v : alloc.vec.Vec Row) (e : store.Entry) (r : Row)
    (h : store.get rows id now pw = ok (v, .Ok e)) (hr : rowOf rows.val id = some r) (hb : Burns r)
    (now' : I64) (pw' : Option U64) :
    ∃ v', store.get v id now' pw' = ok (v', .Err .NotFound) ∧ v'.val = v.val := by
  have hv := get_burn_consumes rows id now pw v e r h hr hb
  have hn : rowOf v.val id = none := by
    rw [hv]; exact Verified.Get.rowOf_none_of_present (Verified.Get.present_without _ _)
  obtain ⟨⟨v', res⟩, hx⟩ := ok_of (Verified.Get.get_spec v id now' pw')
  have := Verified.Get.get_eq v id now' pw' v' res hx
  rw [Verified.Get.getM_missing hn] at this
  simp only [Prod.mk.injEq] at this
  exact ⟨v', by rw [hx, this.2], this.1⟩

/-- Concurrent readers of a burn-after-reading paste: however many readers
fetched and decrypted it, and in whatever order their burning `DELETE`s run,
exactly one of them receives the content if the paste is still in the
table, and none otherwise. -/
theorem burn_readers_exactly_once (id : I64) (rs : List (store.Data × Bool)) (v : alloc.vec.Vec Row) :
    ∃ bs, burnReaders id rs v = ok bs ∧ bs.length = rs.length ∧
      bs.count true = if (∃ x ∈ v.val, x.id = id) ∧ rs ≠ [] then 1 else 0 := by
  obtain ⟨bs, hb⟩ := ok_of (Verified.Burn.burn_readers_spec id rs v)
  have := post_of_ok (Verified.Burn.burn_readers_spec id rs v) hb
  refine ⟨bs, hb, this.1, ?_⟩
  rw [this.2]
  simp [Verified.Get.present]

end wastebin_kernel.Properties
