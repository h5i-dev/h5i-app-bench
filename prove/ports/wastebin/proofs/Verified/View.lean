import Verified.Get
import Verified.Delete
/-!
# The paste view (`html::paste::get`, `html::rendered::get`), raw/download, QR

`viewIdM`, `rawIdM` and `qrIdM` restate the id-level decisions over lists.
-/
open Aeneas Aeneas.Std Result wastebin_kernel wastebin_kernel.Spec
open H5iAppLib
open Aeneas.Std.WP
open wastebin_kernel.Verified.Store wastebin_kernel.Verified.Get

namespace wastebin_kernel.Verified.View

/-- The verified cookie lists the owner. -/
def CookieOwns (uids : Option (alloc.vec.Vec I64)) (owner : Option I64) : Prop :=
  ∃ us, uids = some us ∧ Owns us.val owner

def cookieOwnsB : Option (alloc.vec.Vec I64) → Option I64 → Bool
  | some us, some o => decide (o ∈ us.val)
  | _, _ => false

instance (uids : Option (alloc.vec.Vec I64)) (owner : Option I64) : Decidable (CookieOwns uids owner) :=
  decidable_of_iff (cookieOwnsB uids owner = true) (by
    unfold CookieOwns Owns cookieOwnsB
    rcases uids with _ | us <;> rcases owner with _ | o <;> simp)

@[step] theorem can_delete_spec (uids : Option (alloc.vec.Vec I64)) (owner : Option I64) :
    handlers.can_delete uids owner ⦃ b => decide (CookieOwns uids owner) = b ⦄ := by
  unfold handlers.can_delete
  rcases uids with _ | us <;> rcases owner with _ | o <;> step* <;> simp_all [CookieOwns, Owns]

theorem can_delete_eq (uids : Option (alloc.vec.Vec I64)) (owner : Option I64) :
    handlers.can_delete uids owner = ok (decide (CookieOwns uids owner)) := by
  obtain ⟨x, hx⟩ := ok_of (can_delete_spec uids owner)
  rw [hx, post_of_ok (can_delete_spec uids owner) hx]

def statusM : store.DbError → handlers.Status
  | .NotFound => .NotFound
  | .Delete => .Forbidden
  | .Crypto => .Forbidden
  | .NoPassword => .BadRequest

@[step] theorem db_status_spec (e : store.DbError) : handlers.db_status e ⦃ s => statusM e = s ⦄ := by
  unfold handlers.db_status; cases e <;> simp [statusM]

def availM : store.Entry → Bool
  | .Regular _ => true
  | .Burned _ => false
  | .Encrypted d => !d.metadata.must_be_deleted

def pageM (e : store.Entry) (req : handlers.ViewRequest) : handlers.PastePage :=
  { data := (entryData e).data, title := (entryData e).metadata.title,
    can_delete := decide (CookieOwns req.uids (entryData e).metadata.uid),
    is_available := availM e, no_store := isEncrypted e,
    cache_put := !req.cached && availM e && req.password.isNone }

@[step] theorem no_password_spec (p : Option U64) : handlers.no_password p ⦃ b => p.isNone = b ⦄ := by
  unfold handlers.no_password; cases p <;> simp

@[step] theorem page_of_spec (e : store.Entry) (req : handlers.ViewRequest) :
    handlers.page_of e req ⦃ p => pageM e req = p ⦄ := by
  unfold handlers.page_of
  cases e with
  | Regular d | Burned d | Encrypted d =>
    step* <;> (subst_vars; cases hm : d.metadata.must_be_deleted <;> cases hp : req.password <;>
      simp_all [pageM, availM, entryData, isEncrypted])

def viewIdM (rows : List Row) (id now : I64) (req : handlers.ViewRequest) : List Row × handlers.View :=
  match rowOf rows id with
  | none => (rows, .Error .NotFound)
  | some r =>
    if Burns r ∧ req.confirmed = false then (rows, .BurnConfirmation r.title)
    else match getM rows id now req.password with
      | (v, .Ok e) => (v, .Paste (pageM e req))
      | (v, .Err .NoPassword) => (v, .PasswordInput)
      | (v, .Err e) => (v, .Error (statusM e))

theorem eq_of_spec' {α} {m : Result α} {v : α} (h : m ⦃ x => v = x ⦄) : m = ok v := by
  obtain ⟨x, hx⟩ := ok_of h
  rw [hx, post_of_ok h hx]

theorem get_metadata_eq (rows : alloc.vec.Vec Row) (id : I64) :
    store.get_metadata rows id =
      ok (match rowOf rows.val id with | none => .Err .NotFound | some r => .Ok (metaM r)) :=
  eq_of_spec' (get_metadata_spec rows id)

theorem page_of_eq (e : store.Entry) (req : handlers.ViewRequest) :
    handlers.page_of e req = ok (pageM e req) := eq_of_spec' (page_of_spec e req)

theorem db_status_eq (e : store.DbError) : handlers.db_status e = ok (statusM e) :=
  eq_of_spec' (db_status_spec e)

theorem get_ok (rows : alloc.vec.Vec Row) (id now : I64) (pw : Option U64) :
    ∃ v res, store.get rows id now pw = ok (v, res) ∧ getM rows.val id now pw = (v.val, res) := by
  obtain ⟨⟨v, res⟩, h⟩ := ok_of (get_spec rows id now pw)
  exact ⟨v, res, h, post_of_ok (P := fun x => getM rows.val id now pw = (x.1.val, x.2)) (get_spec rows id now pw) h⟩

@[step] theorem view_id_spec (rows : alloc.vec.Vec Row) (id now : I64) (req : handlers.ViewRequest) :
    handlers.view_id rows id now req ⦃ x => viewIdM rows.val id now req = (x.1.val, x.2) ⦄ := by
  unfold handlers.view_id
  rw [get_metadata_eq]
  obtain ⟨v, res, hg, hm⟩ := get_ok rows id now req.password
  rcases hr : rowOf rows.val id with _ | row
  · simp [Delete.clone_rows, viewIdM, hr, db_status_eq, statusM]
  · have hv : viewIdM rows.val id now req = if Burns row ∧ req.confirmed = false then
        (rows.val, .BurnConfirmation row.title) else
        match (v.val, res) with
        | (v, .Ok e) => (v, .Paste (pageM e req))
        | (v, .Err .NoPassword) => (v, .PasswordInput)
        | (v, .Err e) => (v, .Error (statusM e)) := by
      simp only [viewIdM, hr, hm]; rfl
    rw [hv]
    by_cases hb : Burns row <;> cases hc : req.confirmed <;>
      simp only [metaM, hb, hc, decide_true, decide_false, Bool.not_true, Bool.not_false,
        Bool.and_true, Bool.and_false, Bool.true_and, Bool.false_and, if_true, if_false, and_true,
        and_false, Bool.false_eq_true, not_false_eq_true, not_true_eq_false, bind_tc_ok, hg,
        Delete.clone_rows, WP.spec_ok] <;>
      (rcases res with e | de <;> [simp [page_of_eq]; (cases de <;> simp [db_status_eq, statusM])])

/-! ## View outcomes on lists -/

theorem opens_none {r : Row} (h : Opens r none) : r.secret = none := by
  rcases h with h | ⟨k, -, hk⟩
  · exact h
  · cases hk

theorem viewIdM_paste {rows : List Row} {id now : I64} {req : handlers.ViewRequest} {v : List Row}
    {p : handlers.PastePage} (h : viewIdM rows id now req = (v, .Paste p)) :
    ∃ r, rowOf rows id = some r ∧ ¬ Expired r now.val ∧ Opens r req.password ∧
      p.data = r.data ∧ p.title = r.title ∧ (Burns r → req.confirmed = true) ∧
      p.no_store = r.secret.isSome ∧ (p.can_delete = true ↔ CookieOwns req.uids r.uid) ∧
      (p.cache_put = true → r.secret = none ∧ ¬ Burns r ∧ req.password = none ∧ req.cached = false) ∧
      v = (if Burns r then without rows id else rows) := by
  unfold viewIdM at h
  rcases hr : rowOf rows id with _ | r <;> simp only [hr] at h
  · simp at h
  · by_cases hb : Burns r ∧ req.confirmed = false
    · simp [hb] at h
    · simp only [hb, if_false] at h
      rcases hg : getM rows id now req.password with ⟨v', res⟩
      rw [hg] at h
      rcases res with e | de
      · simp only [Prod.mk.injEq, handlers.View.Paste.injEq] at h
        obtain ⟨rfl, rfl⟩ := h
        obtain ⟨r', hr', he, ho, hd, hv, hi, hreg, hbur⟩ := getM_ok hg
        rw [hr] at hr'; cases hr'
        refine ⟨r, rfl, he, ho, by simp [pageM, hd], by simp [pageM, hd, metaM], ?_, ?_, ?_, ?_, hv⟩
        · intro hb'; by_contra hc; exact hb ⟨hb', by simpa using hc⟩
        · simp [pageM, hi]
        · simp [pageM, hd, metaM]
        · intro hc
          simp only [pageM, Bool.and_eq_true, Bool.not_eq_true', Option.isNone_iff_eq_none] at hc
          obtain ⟨⟨hca, hav⟩, hpw⟩ := hc
          have hs : r.secret = none := opens_none (hpw ▸ ho)
          refine ⟨hs, ?_, hpw, hca⟩
          intro hbr
          cases e with
          | Regular d => exact hreg hbr d rfl
          | Burned d => simp [availM] at hav
          | Encrypted d => simp [isEncrypted, hs] at hi
      · cases de <;> simp at h

theorem viewIdM_burn_unconfirmed {rows : List Row} {id now : I64} {req : handlers.ViewRequest} {r : Row}
    (hr : rowOf rows id = some r) (hb : Burns r) (hc : req.confirmed = false) :
    viewIdM rows id now req = (rows, .BurnConfirmation r.title) := by
  simp [viewIdM, hr, hb, hc]

/-- The view changes the table only by deleting the requested paste, and
only when it is expired or a confirmed read burned it. -/
theorem viewIdM_table {rows : List Row} {id now : I64} {req : handlers.ViewRequest} {v : List Row}
    {x : handlers.View} (h : viewIdM rows id now req = (v, x)) :
    v = rows ∨ ∃ r, rowOf rows id = some r ∧ v = without rows id ∧
      (Expired r now.val ∨ (Burns r ∧ req.confirmed = true ∧ ∃ p, x = .Paste p)) := by
  unfold viewIdM at h
  rcases hr : rowOf rows id with _ | r <;> simp only [hr] at h
  · left; simp at h; exact h.1.symm
  · by_cases hb : Burns r ∧ req.confirmed = false
    · left; simp [hb] at h; exact h.1.symm
    · simp only [hb, if_false] at h
      rcases hg : getM rows id now req.password with ⟨v', res⟩
      rw [hg] at h
      unfold getM fetchM at hg
      simp only [hr] at hg
      by_cases he : Expired r now.val
      · simp only [he, if_true, Prod.mk.injEq] at hg
        obtain ⟨rfl, rfl⟩ := hg
        right; refine ⟨r, rfl, ?_, .inl he⟩
        simp at h; exact h.1.symm
      · simp only [he, if_false] at hg
        rcases hd : decryptM r.secret req.password with x | de <;> simp only [hd] at hg
        · simp only [Prod.mk.injEq] at hg
          obtain ⟨h1, h2⟩ := hg
          subst h1 h2
          have hp := present_of_rowOf hr
          by_cases hbr : Burns r
          · have hc : req.confirmed = true := by
              by_contra hc; exact hb ⟨hbr, by simpa using hc⟩
            right; refine ⟨r, rfl, ?_, .inr ⟨hbr, hc, ?_⟩⟩
            · cases hs : r.secret.isSome <;> simp [finishM, hbr, hp, hs] at h <;> exact h.1.symm
            · cases hs : r.secret.isSome <;> simp [finishM, hbr, hp, hs] at h <;> exact ⟨_, h.2.symm⟩
          · left
            cases hs : r.secret.isSome <;> simp [finishM, hbr, hp, hs] at h <;> exact h.1.symm
        · simp only [Prod.mk.injEq] at hg
          obtain ⟨rfl, rfl⟩ := hg
          left; cases de <;> simp at h <;> exact h.1.symm

/-! ## The whole view: handoff, key parsing -/

theorem view_cases (rows : alloc.vec.Vec Row) (path : Slice U8) (now : I64) (req : handlers.ViewRequest)
    (v : alloc.vec.Vec Row) (x : handlers.View) (h : handlers.view rows path now req = ok (v, x)) :
    (∃ c l, req.claim = some c ∧ handlers.handoff req.uids c = ok l ∧ v = rows ∧ x = .Handoff l) ∨
    (req.claim = none ∧ ∃ k i, ids.parse_key path = ok (.Ok k) ∧ ids.to_i64 k.id = ok i ∧
      viewIdM rows.val i now req = (v.val, x)) ∨
    (req.claim = none ∧ v = rows ∧ x = .Error .BadRequest) := by
  unfold handlers.view at h
  rcases hc : req.claim with _ | c <;> simp only [hc] at h
  · h5i_invert h
    · right; left
      exact ⟨rfl, _, _, ‹_›, ‹_›, post_of_ok (P := fun x => viewIdM rows.val _ now req = (x.1.val, x.2))
        (view_id_spec rows _ now req) h⟩
    · right; right; simp_all [Delete.clone_rows]
  · h5i_invert h
    left; simp_all [Delete.clone_rows]

/-! ## Raw and download -/

def rawIdM (rows : List Row) (id now : I64) (pw : Option U64) : List Row × handlers.Raw :=
  match getM rows id now pw with
  | (v, .Ok e) => (v, .Content (entryData e).data (entryData e).metadata.title (isEncrypted e))
  | (v, .Err .NoPassword) => (v, .PasswordInput)
  | (v, .Err e) => (v, .Error (statusM e))

theorem raw_id_spec (rows : alloc.vec.Vec Row) (id now : I64) (pw : Option U64) :
    handlers.raw_id rows id now pw ⦃ x => rawIdM rows.val id now pw = (x.1.val, x.2) ⦄ := by
  unfold handlers.raw_id
  obtain ⟨v, res, hg, hm⟩ := get_ok rows id now pw
  have hv : rawIdM rows.val id now pw = match (v.val, res) with
      | (v, .Ok e) => (v, .Content (entryData e).data (entryData e).metadata.title (isEncrypted e))
      | (v, .Err .NoPassword) => (v, .PasswordInput)
      | (v, .Err e) => (v, .Error (statusM e)) := by
    simp only [rawIdM, hm]; rfl
  rw [hv, hg]
  rcases res with e | de
  · cases e <;> simp [entryData, isEncrypted]
  · cases de <;> simp [db_status_eq, statusM]

theorem raw_cases (rows : alloc.vec.Vec Row) (path : Slice U8) (now : I64) (pw : Option U64)
    (v : alloc.vec.Vec Row) (x : handlers.Raw) (h : handlers.raw rows path now pw = ok (v, x)) :
    (∃ k i, ids.parse_key path = ok (.Ok k) ∧ ids.to_i64 k.id = ok i ∧
      rawIdM rows.val i now pw = (v.val, x)) ∨ (v = rows ∧ x = .Error .BadRequest) := by
  unfold handlers.raw at h
  h5i_invert h
  · left
    exact ⟨_, _, ‹_›, ‹_›, post_of_ok (P := fun x => rawIdM rows.val _ now pw = (x.1.val, x.2))
      (raw_id_spec rows _ now pw) h⟩
  · right; simp_all [Delete.clone_rows]

/-! ## QR -/

theorem qr_id_eq (rows : alloc.vec.Vec Row) (id : I64) (uids : Option (alloc.vec.Vec I64)) :
    handlers.qr_id rows id uids = ok (match rowOf rows.val id with
      | none => .Error .NotFound
      | some r => .Page r.title r.expires (decide (CookieOwns uids r.uid))) := by
  unfold handlers.qr_id
  rw [get_metadata_eq]
  rcases hr : rowOf rows.val id with _ | r
  · simp [db_status_eq, statusM]
  · simp [can_delete_eq, metaM]

end wastebin_kernel.Verified.View
