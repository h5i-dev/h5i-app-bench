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

@[step] theorem decrypt_spec (s p : Option U64) : store.decrypt s p ⦃ x => decryptM s p = x ⦄ := by
  unfold store.decrypt
  rcases s with _ | k <;> rcases p with _ | q <;> simp [decryptM]
  split <;> simp_all

@[step] theorem is_expired_spec (r : Row) (now : I64) :
    store.is_expired r now ⦃ b => b = decide (Expired r now.val) ⦄ := by
  unfold store.is_expired
  rcases h : r.expires with _ | e <;> simp [Expired, h]

@[step] theorem must_be_deleted_spec (r : Row) :
    store.must_be_deleted r ⦃ b => decide (Burns r) = b ⦄ := by
  unfold store.must_be_deleted
  rcases h : r.burn with _ | b
  · simp [Burns, h]
  · cases b <;> simp [Burns, h]

@[step] theorem metadata_of_spec (r : Row) : store.metadata_of r ⦃ m => metaM r = m ⦄ := by
  unfold store.metadata_of
  step*
  simp [metaM, *]

@[step] theorem fetch_spec (rows : alloc.vec.Vec Row) (id now : I64) (pw : Option U64) :
    store.fetch rows id now pw ⦃ f => fetchM rows.val id now pw = f ⦄ := by
  unfold store.fetch
  step*
  all_goals simp_all [fetchM]

@[step] theorem finish_spec (rows : alloc.vec.Vec Row) (id : I64) (d : store.Data) (enc burn : Bool) :
    store.finish rows id d enc burn ⦃ x => x.1.val = (if burn then without rows.val id else rows.val) ∧
      x.2 = finishM (present rows.val id) d enc burn ⦄ := by
  unfold store.finish
  split
  · step*
    all_goals simp_all [finishM, present]
  · split <;> step* <;> simp_all [finishM]

@[step] theorem get_metadata_spec (rows : alloc.vec.Vec Row) (id : I64) :
    store.get_metadata rows id ⦃ x =>
      (match rowOf rows.val id with | none => .Err .NotFound | some r => .Ok (metaM r)) = x ⦄ := by
  unfold store.get_metadata
  step*
  all_goals simp_all

@[step] theorem get_spec (rows : alloc.vec.Vec Row) (id now : I64) (pw : Option U64) :
    store.get rows id now pw ⦃ x => getM rows.val id now pw = (x.1.val, x.2) ⦄ := by
  unfold store.get
  step*
  all_goals simp_all [getM]

/-! ## The read path on lists -/

theorem rowOf_some {rows : List Row} {id : I64} {r : Row} (h : rowOf rows id = some r) :
    r ∈ rows ∧ r.id = id := by
  unfold rowOf at h
  exact ⟨List.mem_of_find?_eq_some h, by simpa using List.find?_some h⟩

theorem present_of_rowOf {rows : List Row} {id : I64} {r : Row} (h : rowOf rows id = some r) :
    present rows id = true := by
  obtain ⟨hm, hi⟩ := rowOf_some h
  simp only [present, List.any_eq_true, decide_eq_true_eq]
  exact ⟨r, hm, hi⟩

theorem present_without (rows : List Row) (id : I64) : present (without rows id) id = false := by
  simp [present, without]

theorem without_without (rows : List Row) (id : I64) : without (without rows id) id = without rows id := by
  simp [without, List.filter_filter]

theorem decryptM_ok (s pw : Option U64) :
    decryptM s pw = .Ok () ↔ (s = none ∨ ∃ k, s = some k ∧ pw = some k) := by
  rcases s with _ | k <;> rcases pw with _ | p <;> simp [decryptM]
  constructor
  · intro h; scalar_tac
  · intro h; simp [h]

theorem opens_iff (r : Row) (pw : Option U64) : Opens r pw ↔ decryptM r.secret pw = .Ok () := by
  rw [decryptM_ok]; rfl

theorem getM_ok {rows : List Row} {id now : I64} {pw : Option U64} {v : List Row} {e : store.Entry}
    (h : getM rows id now pw = (v, .Ok e)) :
    ∃ r, rowOf rows id = some r ∧ ¬ Expired r now.val ∧ Opens r pw ∧
      entryData e = ⟨r.data, metaM r⟩ ∧ v = (if Burns r then without rows id else rows) ∧
      (isEncrypted e = r.secret.isSome) := by
  unfold getM fetchM at h
  rcases hr : rowOf rows id with _ | r <;> simp only [hr] at h
  · simp at h
  · by_cases he : Expired r now.val <;> simp only [he, if_true, if_false] at h
    · simp at h
    · rcases hd : decryptM r.secret pw with x | x <;> simp only [hd] at h
      · refine ⟨r, rfl, he, (opens_iff r pw).2 (by cases x; exact hd), ?_⟩
        have hp := present_of_rowOf hr
        rw [Prod.mk.injEq] at h
        obtain ⟨h1, h2⟩ := h
        by_cases hb : Burns r
        · simp only [hb, decide_true, finishM, if_true, hp] at h1 h2
          rcases hs : r.secret with _ | k <;> simp only [hs, Option.isSome] at h2 <;>
            simp only [Bool.false_eq_true, if_false, if_true, core.result.Result.Ok.injEq] at h2 <;>
            subst h2 <;> simp [entryData, isEncrypted, hb, h1, hs]
        · simp only [hb, decide_false, finishM, Bool.false_eq_true, if_false] at h1 h2
          rcases hs : r.secret with _ | k <;> simp only [hs, Option.isSome] at h2 <;>
            simp only [Bool.false_eq_true, if_false, if_true, core.result.Result.Ok.injEq] at h2 <;>
            subst h2 <;> simp [entryData, isEncrypted, hb, h1, hs]
      · simp at h

theorem getM_expired {rows : List Row} {id now : I64} {pw : Option U64} {r : Row}
    (hr : rowOf rows id = some r) (he : Expired r now.val) :
    getM rows id now pw = (without rows id, .Err .NotFound) := by
  simp [getM, fetchM, hr, he]

theorem getM_closed {rows : List Row} {id now : I64} {pw : Option U64} {r : Row}
    (hr : rowOf rows id = some r) (he : ¬ Expired r now.val) (ho : ¬ Opens r pw) :
    getM rows id now pw = (rows, .Err (if pw = none then .NoPassword else .Crypto)) := by
  rw [opens_iff] at ho
  unfold getM fetchM
  simp only [hr, he, if_false]
  rcases hs : r.secret with _ | k <;> rcases hp : pw with _ | p <;> simp_all [decryptM]

theorem getM_missing {rows : List Row} {id now : I64} {pw : Option U64}
    (hr : rowOf rows id = none) : getM rows id now pw = (rows, .Err .NotFound) := by
  simp [getM, fetchM, hr]

theorem rowOf_none_of_present {rows : List Row} {id : I64} (h : present rows id = false) :
    rowOf rows id = none := by
  simp only [present, List.any_eq_false, decide_eq_true_eq] at h
  simp only [rowOf, List.find?_eq_none, decide_eq_true_eq]
  exact h

theorem get_eq (rows : alloc.vec.Vec Row) (id now : I64) (pw : Option U64)
    (v : alloc.vec.Vec Row) (res : core.result.Result store.Entry store.DbError)
    (h : store.get rows id now pw = ok (v, res)) : (v.val, res) = getM rows.val id now pw :=
  (post_of_ok (P := fun x => getM rows.val id now pw = (x.1.val, x.2)) (get_spec rows id now pw) h).symm

end wastebin_kernel.Verified.Get
