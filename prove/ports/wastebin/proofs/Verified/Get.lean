import Verified.Derived
import Verified.Store
/-!
# `Database::get` as a list function

`fetchM` and `getM` restate `store.fetch` and `store.get` over lists, and
the `@[step]` specs prove the extracted functions equal them. The
properties are then lemmas about the list functions.
-/
open Aeneas Aeneas.Std Result wastebin_kernel wastebin_kernel.Spec
open H5iAppLib
open Aeneas.Std.WP
open wastebin_kernel.Verified.Store

namespace wastebin_kernel.Verified.Get

/-- `decrypt` over values. -/
def decryptM : Option U64 → Option U64 → core.result.Result Unit store.DbError
  | none, _ => .Ok ()
  | some _, none => .Err .NoPassword
  | some k, some p => if p = k then .Ok () else .Err .Crypto

def metaM (r : Row) : store.Metadata :=
  { uid := r.uid, title := r.title, expires := r.expires, must_be_deleted := decide (Burns r) }

def fetchM (rows : List Row) (id : I64) (now : I64) (pw : Option U64) : store.Fetch :=
  match rowOf rows id with
  | none => .Missing
  | some r =>
    if Expired r now.val then .Expired
    else match decryptM r.secret pw with
      | .Err e => .Refused e
      | .Ok () => .Ready ⟨r.data, metaM r⟩ r.secret.isSome (decide (Burns r))

/-- `finish`'s result, given whether the row is still there. -/
def finishM (present : Bool) (d : store.Data) (enc burn : Bool) : core.result.Result store.Entry store.DbError :=
  if burn then
    if present then (if enc then .Ok (.Encrypted d) else .Ok (.Burned d)) else .Err .NotFound
  else if enc then .Ok (.Encrypted d) else .Ok (.Regular d)

def present (rows : List Row) (id : I64) : Bool := rows.any (fun r => decide (r.id = id))

def getM (rows : List Row) (id : I64) (now : I64) (pw : Option U64) :
    List Row × core.result.Result store.Entry store.DbError :=
  match fetchM rows id now pw with
  | .Missing => (rows, .Err .NotFound)
  | .Expired => (without rows id, .Err .NotFound)
  | .Refused e => (rows, .Err e)
  | .Ready d enc b => (if b then without rows id else rows, finishM (present rows id) d enc b)

@[step] theorem decrypt_spec (s p : Option U64) : store.decrypt s p ⦃ x => x = decryptM s p ⦄ := by
  unfold store.decrypt
  rcases s with _ | k <;> rcases p with _ | q <;> simp [decryptM]
  split <;> simp_all

@[step] theorem is_expired_spec (r : Row) (now : I64) :
    store.is_expired r now ⦃ b => b = decide (Expired r now.val) ⦄ := by
  unfold store.is_expired
  rcases h : r.expires with _ | e <;> simp [Expired, h]

theorem burns_iff (r : Row) : decide (Burns r) = match r.burn with | none => false | some b => b := by
  unfold Burns; rcases r.burn with _ | (_ | _) <;> simp

@[step] theorem must_be_deleted_spec (r : Row) :
    store.must_be_deleted r ⦃ b => b = decide (Burns r) ⦄ := by
  unfold store.must_be_deleted
  rw [burns_iff]
  rcases r.burn with _ | b <;> simp

@[step] theorem metadata_of_spec (r : Row) : store.metadata_of r ⦃ m => m = metaM r ⦄ := by
  unfold store.metadata_of
  step*
  simp [metaM, *]

@[step] theorem fetch_spec (rows : alloc.vec.Vec Row) (id now : I64) (pw : Option U64) :
    store.fetch rows id now pw ⦃ f => f = fetchM rows.val id now pw ⦄ := by
  unfold store.fetch
  step*
  done

end wastebin_kernel.Verified.Get
