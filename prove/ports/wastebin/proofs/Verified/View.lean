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

@[step] theorem view_id_spec (rows : alloc.vec.Vec Row) (id now : I64) (req : handlers.ViewRequest) :
    handlers.view_id rows id now req ⦃ x => viewIdM rows.val id now req = (x.1.val, x.2) ⦄ := by
  unfold handlers.view_id
  rcases hr : rowOf rows.val id with _ | row
  all_goals step*
  all_goals simp_all [viewIdM, metaM]

end wastebin_kernel.Verified.View
