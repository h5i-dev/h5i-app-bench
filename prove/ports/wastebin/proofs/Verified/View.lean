import Verified.Get
import Verified.Delete
/-!
# The paste view (`html::paste::get`, `html::rendered::get`)
-/
open Aeneas Aeneas.Std Result wastebin_kernel wastebin_kernel.Spec
open H5iAppLib
open Aeneas.Std.WP
open wastebin_kernel.Verified.Store wastebin_kernel.Verified.Get

namespace wastebin_kernel.Verified.View

/-- The verified cookie lists the owner. -/
def CookieOwns (uids : Option (alloc.vec.Vec I64)) (owner : Option I64) : Prop :=
  ∃ us, uids = some us ∧ Owns us.val owner

@[step] theorem can_delete_spec (uids : Option (alloc.vec.Vec I64)) (owner : Option I64) :
    handlers.can_delete uids owner ⦃ b => b = decide (CookieOwns uids owner) ⦄ := by
  unfold handlers.can_delete
  rcases uids with _ | us <;> rcases owner with _ | o <;> step* <;> simp_all [CookieOwns, Owns]

theorem get_facts {rows : alloc.vec.Vec Row} {id now : I64} {pw : Option U64}
    {v : alloc.vec.Vec Row} {e : store.Entry} (h : store.get rows id now pw = ok (v, .Ok e)) :
    ∃ r, rowOf rows.val id = some r ∧ ¬ Expired r now.val ∧ Opens r pw ∧
      entryData e = ⟨r.data, metaM r⟩ ∧ v.val = (if Burns r then without rows.val id else rows.val) ∧
      (isEncrypted e = r.secret.isSome) :=
  getM_ok (get_eq rows id now pw v _ h).symm

theorem paste_ok (rows : alloc.vec.Vec Row) (path : Slice U8) (now : I64) (req : handlers.ViewRequest)
    (v : alloc.vec.Vec Row) (p : handlers.PastePage)
    (h : handlers.view rows path now req = ok (v, .Paste p)) :
    req.claim = none ∧ ∃ k i, ids.parse_key path = ok (.Ok k) ∧ ids.to_i64 k.id = ok i ∧
      ∃ r, rowOf rows.val i = some r ∧ ¬ Expired r now.val ∧ Opens r req.password ∧
        p.data = r.data ∧ p.title = r.title ∧ (Burns r → req.confirmed = true) ∧
        p.no_store = r.secret.isSome ∧ (p.can_delete = true ↔ CookieOwns req.uids r.uid) ∧
        (p.cache_put = true → r.secret = none ∧ ¬ Burns r ∧ req.password = none ∧ req.cached = false) ∧
        v.val = (if Burns r then without rows.val i else rows.val) := by
  unfold handlers.view at h
  h5i_invert h
  all_goals sorry

end wastebin_kernel.Verified.View
