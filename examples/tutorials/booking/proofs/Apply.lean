import Theorems
/-!
# Committing a write set

The kernel's `apply`, which the reference engine runs, computes
`Spec.applyAll`. As in tutorial 2, `loop_search` covers the upserts and
`loop_fold` covers the delete and the loop over the writes.
-/
open Aeneas Aeneas.Std Result booking_kernel booking_kernel.Spec booking_kernel.Commands I5hLib

namespace booking_kernel.ApplyProofs

/-- Rows in a snapshot; each write adds at most one. -/
def total (s : Snapshot) : Nat := s.admins.length + s.rooms.length + s.bookings.length

theorem snapshot_clone (s : Snapshot) : Snapshot.Insts.CoreCloneClone.clone s = ok s := by
  simp [Snapshot.Insts.CoreCloneClone.clone, Counter.Insts.CoreCloneClone.clone,
    vec_clone_eq Admin.Insts.CoreCloneClone s.admins (fun _ => rfl),
    vec_clone_eq Room.Insts.CoreCloneClone s.rooms (fun _ => rfl),
    vec_clone_eq Booking.Insts.CoreCloneClone s.bookings (fun _ => rfl)]

/-! ## The table loops -/

@[step]
theorem put_admin_loop_spec (v : alloc.vec.Vec Admin) (x : Admin) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (·.user) x v.val = v.val.take i.val ++ upsert (·.user) x (v.val.drop i.val)) :
    put_admin_loop v x i ⦃ v' => v'.val = upsert (·.user) x v.val ⦄ := by
  unfold put_admin_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide (q.user = x.user))
    (fun y : alloc.vec.Vec Admin => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (·.user) x _ _ hi hpre
  · intro j hj; unfold put_admin_loop.body; i5h_step

@[step]
theorem put_room_loop_spec (v : alloc.vec.Vec Room) (x : Room) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (·.id) x v.val = v.val.take i.val ++ upsert (·.id) x (v.val.drop i.val)) :
    put_room_loop v x i ⦃ v' => v'.val = upsert (·.id) x v.val ⦄ := by
  unfold put_room_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide (q.id = x.id))
    (fun y : alloc.vec.Vec Room => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (·.id) x _ _ hi hpre
  · intro j hj; unfold put_room_loop.body; i5h_step

@[step]
theorem put_booking_loop_spec (v : alloc.vec.Vec Booking) (x : Booking) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (·.id) x v.val = v.val.take i.val ++ upsert (·.id) x (v.val.drop i.val)) :
    put_booking_loop v x i ⦃ v' => v'.val = upsert (·.id) x v.val ⦄ := by
  unfold put_booking_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide (q.id = x.id))
    (fun y : alloc.vec.Vec Booking => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (·.id) x _ _ hi hpre
  · intro j hj; unfold put_booking_loop.body; i5h_step

@[step]
theorem del_booking_loop_spec (v : alloc.vec.Vec Booking) (k : U64) (out : alloc.vec.Vec Booking)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun x => x.id ≠ k)) :
    del_booking_loop v k out i ⦃ v' => v'.val = v.val.filter (fun x => x.id ≠ k) ⦄ := by
  unfold del_booking_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Booking => w.val)
    (fun acc x => if decide (x.id ≠ k) then acc ++ [x] else acc)
    (fun w j => w.length ≤ j) (fun x => del_booking_loop.body v k x.1 x.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_booking_loop.body; i5h_step

/-! ## One write, then the whole set -/

@[step]
theorem apply_write_spec (s : Snapshot) (w : Write) (h : total s < Usize.max) :
    apply_write s w ⦃ s' => Snapshot.toSt s' = applyWrite (Snapshot.toSt s) w ∧ total s' ≤ total s + 1 ⦄ := by
  unfold total at h
  unfold apply_write
  cases w <;> step*
  all_goals first
    | refine ⟨by simp [Snapshot.toSt, applyWrite, *], ?_⟩
      simp only [total, alloc.vec.Vec.length, *]
      first
        | omega
        | (have := upsert_length (·.user) ‹Admin› s.admins.val; omega)
        | (have := upsert_length (·.id) ‹Room› s.rooms.val; omega)
        | (have := upsert_length (·.id) ‹Booking› s.bookings.val; omega)
        | grind [List.length_filter_le]
    | simp

@[step]
theorem apply_loop_spec (ws : alloc.vec.Vec Write) (s₀ s : Snapshot) (i : Usize)
    (hi : i.val ≤ ws.length)
    (hs : Snapshot.toSt s = applyAll (Snapshot.toSt s₀) (ws.val.take i.val))
    (hroom : total s + (ws.length - i.val) < Usize.max) :
    apply_loop ws s i ⦃ s' => Snapshot.toSt s' = applyAll (Snapshot.toSt s₀) ws.val ⦄ := by
  unfold apply_loop
  apply WP.spec_mono (loop_fold ws.val Snapshot.toSt applyWrite
    (fun t k => total t + (ws.length - k) < Usize.max) (fun x => apply_loop.body ws x.1 x.2) ?_ s i hi hroom)
  · intro r hr
    rw [hr, hs, applyAll, applyAll, ← List.foldl_append, List.take_append_drop]
  · intro t j hj ht; unfold apply_loop.body; i5h_step

/-- The kernel's `apply` computes `Spec.applyAll`, as long as no vector can
overflow (each write adds at most one row). -/
theorem apply_spec (s : Snapshot) (ws : alloc.vec.Vec Write) (h : total s + ws.length < Usize.max) :
    apply s ws ⦃ s' => Snapshot.toSt s' = applyAll (Snapshot.toSt s) ws.val ⦄ := by
  unfold apply
  rw [snapshot_clone]
  simp only [bind_ok]
  exact apply_loop_spec ws s s 0#usize (by simp) (by simp [applyAll]) (by scalar_tac)

end booking_kernel.ApplyProofs
