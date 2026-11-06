import Verified.Store
import Verified.Delete
import Verified.Get
import Verified.Burn
import Verified.View
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
  obtain ⟨r, hr, he, ho, hd, -, hi, -⟩ := Verified.Get.getM_ok this.symm
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

/-! ## The paste view (`html::paste::get`, `html::rendered::get`) -/

section View
open Verified.View

theorem view_paste_facts {rows : alloc.vec.Vec Row} {path : Slice U8} {now : I64} {req : handlers.ViewRequest}
    {v : alloc.vec.Vec Row} {p : handlers.PastePage} (h : handlers.view rows path now req = ok (v, .Paste p)) :
    req.claim = none ∧ ∃ k i, ids.parse_key path = ok (.Ok k) ∧ ids.to_i64 k.id = ok i ∧
      ∃ r, rowOf rows.val i = some r ∧ ¬ Expired r now.val ∧ Opens r req.password ∧
        p.data = r.data ∧ p.title = r.title ∧ (Burns r → req.confirmed = true) ∧
        p.no_store = r.secret.isSome ∧ (p.can_delete = true ↔ ∃ us, req.uids = some us ∧ Owns us.val r.uid) ∧
        (p.cache_put = true → r.secret = none ∧ ¬ Burns r ∧ req.password = none ∧ req.cached = false) ∧
        v.val = (if Burns r then without rows.val i else rows.val) := by
  rcases view_cases rows path now req v _ h with ⟨c, l, -, -, -, hx⟩ | ⟨hc, k, i, hk, hi, hv⟩ | ⟨-, -, hx⟩
  · cases hx
  · exact ⟨hc, k, i, hk, hi, viewIdM_paste hv⟩
  · cases hx

/-- The paste page shows content only for a paste that exists, has not
expired, is plaintext or opened by the form's password, and, if it burns,
only after the reader confirmed the burn. The content is the paste's own. -/
theorem view_content_gated (rows : alloc.vec.Vec Row) (path : Slice U8) (now : I64) (req : handlers.ViewRequest)
    (v : alloc.vec.Vec Row) (p : handlers.PastePage) (h : handlers.view rows path now req = ok (v, .Paste p)) :
    ∃ k i, ids.parse_key path = ok (.Ok k) ∧ ids.to_i64 k.id = ok i ∧
      ∃ r, rowOf rows.val i = some r ∧ ¬ Expired r now.val ∧ Opens r req.password ∧
        (Burns r → req.confirmed = true) ∧ p.data = r.data ∧ p.title = r.title := by
  obtain ⟨-, k, i, hk, hi, r, hr, he, ho, hd, ht, hb, -⟩ := view_paste_facts h
  exact ⟨k, i, hk, hi, r, hr, he, ho, hb, hd, ht⟩

/-- A page showing an encrypted paste is `Cache-Control: no-store`, and only
those are. -/
theorem view_encrypted_no_store (rows : alloc.vec.Vec Row) (path : Slice U8) (now : I64) (req : handlers.ViewRequest)
    (v : alloc.vec.Vec Row) (p : handlers.PastePage) (h : handlers.view rows path now req = ok (v, .Paste p)) :
    ∃ i r, rowOf rows.val i = some r ∧ p.no_store = r.secret.isSome := by
  obtain ⟨-, k, i, -, -, r, hr, -, -, -, -, -, hn, -⟩ := view_paste_facts h
  exact ⟨i, r, hr, hn⟩

/-- The server-side HTML cache only ever receives a plaintext paste that does
not burn, read without a password, on a cache miss. -/
theorem view_cache_only_public (rows : alloc.vec.Vec Row) (path : Slice U8) (now : I64) (req : handlers.ViewRequest)
    (v : alloc.vec.Vec Row) (p : handlers.PastePage) (h : handlers.view rows path now req = ok (v, .Paste p))
    (hc : p.cache_put = true) :
    ∃ i r, rowOf rows.val i = some r ∧ r.secret = none ∧ ¬ Burns r ∧ req.password = none ∧ req.cached = false := by
  obtain ⟨-, k, i, -, -, r, hr, -, -, -, -, -, -, -, hp, -⟩ := view_paste_facts h
  exact ⟨i, r, hr, hp hc⟩

/-- The delete button is offered exactly when the verified `uid` cookie lists
the paste's owner. -/
theorem view_can_delete_iff_owner (rows : alloc.vec.Vec Row) (path : Slice U8) (now : I64) (req : handlers.ViewRequest)
    (v : alloc.vec.Vec Row) (p : handlers.PastePage) (h : handlers.view rows path now req = ok (v, .Paste p)) :
    ∃ i r, rowOf rows.val i = some r ∧ (p.can_delete = true ↔ ∃ us, req.uids = some us ∧ Owns us.val r.uid) := by
  obtain ⟨-, k, i, -, -, r, hr, -, -, -, -, -, -, hd, -⟩ := view_paste_facts h
  exact ⟨i, r, hr, hd⟩

/-- An unconfirmed request for a burn-after-reading paste gets the
interstitial and burns nothing. -/
theorem view_burn_needs_confirmation (rows : alloc.vec.Vec Row) (path : Slice U8) (now : I64)
    (req : handlers.ViewRequest) (k : ids.Key) (i : I64) (r : Row)
    (hcl : req.claim = none) (hk : ids.parse_key path = ok (.Ok k)) (hi : ids.to_i64 k.id = ok i)
    (hr : rowOf rows.val i = some r) (hb : Burns r) (hc : req.confirmed = false) :
    ∃ v, handlers.view rows path now req = ok (v, .BurnConfirmation r.title) ∧ v.val = rows.val := by
  obtain ⟨⟨v, x⟩, hx⟩ := ok_of (view_id_spec rows i now req)
  have hm := post_of_ok (P := fun x => viewIdM rows.val i now req = (x.1.val, x.2)) (view_id_spec rows i now req) hx
  rw [viewIdM_burn_unconfirmed hr hb hc] at hm
  simp only [Prod.mk.injEq] at hm
  obtain ⟨hm1, rfl⟩ := hm
  refine ⟨v, ?_, hm1.symm⟩
  simp [handlers.view, hcl, hk, hi, hx]

/-- The view changes the table only by deleting the requested paste, and
only when it had expired or a confirmed read burned it. -/
theorem view_changes_only_burned_or_expired (rows : alloc.vec.Vec Row) (path : Slice U8) (now : I64)
    (req : handlers.ViewRequest) (v : alloc.vec.Vec Row) (x : handlers.View)
    (h : handlers.view rows path now req = ok (v, x)) :
    v.val = rows.val ∨ ∃ i r, rowOf rows.val i = some r ∧ v.val = without rows.val i ∧
      (Expired r now.val ∨ (Burns r ∧ req.confirmed = true ∧ ∃ p, x = .Paste p)) := by
  rcases view_cases rows path now req v x h with ⟨c, l, -, -, hv, -⟩ | ⟨-, k, i, -, -, hv⟩ | ⟨-, hv, -⟩
  · left; rw [hv]
  · rcases viewIdM_table hv with h1 | ⟨r, hr, hw, hx⟩
    · left; exact h1
    · right; exact ⟨i, r, hr, hw, hx⟩
  · left; rw [hv]

/-- A verified `?owner=` handoff answers with the new cookie and reads or
writes no paste. -/
theorem view_handoff_touches_no_paste (rows : alloc.vec.Vec Row) (path : Slice U8) (now : I64)
    (req : handlers.ViewRequest) (c : I64) (hc : req.claim = some c) (v : alloc.vec.Vec Row) (x : handlers.View)
    (h : handlers.view rows path now req = ok (v, x)) :
    v = rows ∧ ∃ l, handlers.handoff req.uids c = ok l ∧ x = .Handoff l := by
  rcases view_cases rows path now req v x h with ⟨c', l, hc', hl, hv, hx⟩ | ⟨hn, -⟩ | ⟨hn, -⟩
  · rw [hc] at hc'; cases hc'; exact ⟨hv, l, hl, hx⟩
  · rw [hc] at hn; cases hn
  · rw [hc] at hn; cases hn

/-! ## Raw and download (`raw::get`, `download::get`) -/

/-- Raw content and downloads come out only for a paste that exists, has not
expired, and is plaintext or opened by the password; encrypted ones are
`no-store`. -/
theorem raw_content_gated (rows : alloc.vec.Vec Row) (path : Slice U8) (now : I64) (pw : Option U64)
    (v : alloc.vec.Vec Row) (d : U64) (t : Option U64) (ns : Bool)
    (h : handlers.raw rows path now pw = ok (v, .Content d t ns)) :
    ∃ k i, ids.parse_key path = ok (.Ok k) ∧ ids.to_i64 k.id = ok i ∧
      ∃ r, rowOf rows.val i = some r ∧ ¬ Expired r now.val ∧ Opens r pw ∧ d = r.data ∧ t = r.title ∧
        ns = r.secret.isSome ∧ v.val = (if Burns r then without rows.val i else rows.val) := by
  rcases raw_cases rows path now pw v _ h with ⟨k, i, hk, hi, hv⟩ | ⟨-, hx⟩
  · refine ⟨k, i, hk, hi, ?_⟩
    unfold rawIdM at hv
    rcases hg : Verified.Get.getM rows.val i now pw with ⟨v', res⟩
    rw [hg] at hv
    rcases res with e | de
    · simp only [Prod.mk.injEq, handlers.Raw.Content.injEq] at hv
      obtain ⟨rfl, hd, ht, hn⟩ := hv
      obtain ⟨r, hr, he, ho, hed, hw, hi', -⟩ := Verified.Get.getM_ok hg
      refine ⟨r, hr, he, ho, by rw [← hd, hed], by rw [← ht, hed]; rfl, by rw [← hn, hi'], hw⟩
    · cases de <;> simp at hv
  · cases hx

end View

/-! ## Finding: metadata of expired pastes stays visible -/

/-- FINDING (upstream behavior, recorded): the QR page reads only
`get_metadata`, which does not check expiry. For any paste still in the
table, expired or not, `/qr/{id}` shows its title (and owner status) until
`wastebin-ctl purge` or a full read deletes the row. -/
theorem qr_shows_title_of_expired_paste (rows : alloc.vec.Vec Row) (i now : I64) (r : Row)
    (uids : Option (alloc.vec.Vec I64)) (hr : rowOf rows.val i = some r) (_he : Expired r now.val) :
    ∃ b, handlers.qr_id rows i uids = ok (.Page r.title r.expires b) := by
  rw [Verified.View.qr_id_eq, hr]
  exact ⟨_, rfl⟩

/-- FINDING (upstream behavior, recorded): the burn interstitial is decided on
`get_metadata` before `Database::get` checks expiry, so an expired
burn-after-reading paste still shows its title to anyone with the URL. -/
theorem burn_interstitial_shows_title_of_expired_paste (rows : alloc.vec.Vec Row) (path : Slice U8) (now : I64)
    (req : handlers.ViewRequest) (k : ids.Key) (i : I64) (r : Row)
    (hcl : req.claim = none) (hk : ids.parse_key path = ok (.Ok k)) (hi : ids.to_i64 k.id = ok i)
    (hr : rowOf rows.val i = some r) (hb : Burns r) (hc : req.confirmed = false) (_he : Expired r now.val) :
    ∃ v, handlers.view rows path now req = ok (v, .BurnConfirmation r.title) ∧ v.val = rows.val :=
  view_burn_needs_confirmation rows path now req k i r hcl hk hi hr hb hc

end wastebin_kernel.Properties
