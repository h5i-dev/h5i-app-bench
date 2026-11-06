import Verified.Derived
import Verified.Store
/-!
# Deletion: `delete_paste` (`delete::api::delete`, `delete::form::delete`)
-/
open Aeneas Aeneas.Std Result wastebin_kernel wastebin_kernel.Spec
open H5iAppLib
open Aeneas.Std.WP
open wastebin_kernel.Verified.Store

namespace wastebin_kernel.Verified.Delete

@[simp] theorem deref_val {α : Type} (v : alloc.vec.Vec α) : v.deref.val = v.val := by
  simp [alloc.vec.Vec.deref, alloc.vec.Vec.val]

theorem clone_rows (rows : alloc.vec.Vec Row) :
    alloc.vec.CloneVec.clone store.Row.Insts.CoreCloneClone rows = ok rows := by
  apply eq_ok_of_spec; step*

/-- A deletion that succeeds came with a verified cookie, decoded the path to
an id, and removed exactly the holder's paste(s) with that id, which exist. -/
theorem delete_ok (rows : alloc.vec.Vec Row) (path : Slice U8) (uids : Option (alloc.vec.Vec I64))
    (rows' : alloc.vec.Vec Row)
    (h : handlers.delete_paste rows path uids = ok (rows', .Ok ())) :
    ∃ us, uids = some us ∧ ∃ pid i, ids.decode path = ok (.Ok pid) ∧ ids.to_i64 pid = ok i ∧
      rows'.val = deletedBy rows.val i us.val ∧ HasOwned rows.val i us.val := by
  unfold handlers.delete_paste at h
  h5i_invert h
  all_goals try simp_all [clone_rows]
  have := post_of_ok (delete_for_spec rows i us.deref) hr1
  simpa using this

/-- A refused deletion leaves the table as it was. -/
theorem delete_refused (rows : alloc.vec.Vec Row) (path : Slice U8) (uids : Option (alloc.vec.Vec I64))
    (rows' : alloc.vec.Vec Row) (s : handlers.Status)
    (h : handlers.delete_paste rows path uids = ok (rows', .Err s)) : rows' = rows := by
  unfold handlers.delete_paste at h
  h5i_invert h
  all_goals simp_all [clone_rows]

/-- Without a verified `uid` cookie the answer is `403` and nothing changes. -/
theorem delete_no_cookie (rows : alloc.vec.Vec Row) (path : Slice U8) :
    handlers.delete_paste rows path none = ok (rows, .Err .Forbidden) := by
  simp [handlers.delete_paste, clone_rows]

end wastebin_kernel.Verified.Delete
