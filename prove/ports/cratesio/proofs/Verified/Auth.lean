import Verified.Bytes
/-!
# Authentication (`src/auth.rs`) as list functions
-/
open Aeneas Aeneas.Std Result cratesio_kernel cratesio_kernel.Spec
open H5iAppLib
open Aeneas.Std.WP
open cratesio_kernel.Verified.Bytes

namespace cratesio_kernel.Verified.Auth

def lockedB (u : auth.User) (now : Int) : Bool :=
  u.lock_reason && match u.lock_until with | none => true | some t => decide (now < t.val)

instance (u : auth.User) (now : Int) : Decidable (Locked u now) :=
  decidable_of_iff (lockedB u now = true) (by
    unfold Locked lockedB; rcases u.lock_until with _ | t <;> simp)

def liveB (t : auth.ApiToken) (s : List U8) (now : Int) : Bool :=
  !t.revoked && (match t.expired_at with | none => true | some e => decide (now < e.val)) &&
    decide (t.secret.val = s)

instance (t : auth.ApiToken) (s : List U8) (now : Int) : Decidable (Live t s now) :=
  decidable_of_iff (liveB t s now = true) (by
    unfold Live liveB; rcases t.expired_at with _ | e <;> simp)

@[step] theorem contains_u64_spec (xs : Slice U64) (x : U64) :
    auth.contains_u64 xs x ⦃ b => decide (x ∈ xs.val) = b ⦄ := by
  unfold auth.contains_u64 auth.contains_u64_loop
  apply WP.spec_mono (loop_search xs.val (fun u => decide (u = x)) (fun b : Bool => b)
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr
    rw [search_any _ _ _ hr, eq_comm, Bool.eq_iff_iff]
    simp [List.any_eq_true]
  · intro j hj; unfold auth.contains_u64_loop.body; h5i_step

@[step] theorem origins_ok_spec (origins allowed : Slice U64) :
    auth.origins_ok origins allowed ⦃ b => decide (∀ o ∈ origins.val, o ∈ allowed.val) = b ⦄ := by
  unfold auth.origins_ok auth.origins_ok_loop
  apply WP.spec_mono (loop_search origins.val (fun o => !decide (o ∈ allowed.val)) (fun b : Bool => b)
    (fun _ _ => false) true _ ?_ 0#usize (by simp))
  · intro r hr
    rw [search_all _ _ _ hr, eq_comm, Bool.eq_iff_iff]
    simp [List.all_eq_true]
  · intro j hj; unfold auth.origins_ok_loop.body; h5i_step

@[step] theorem find_user_spec (users : Slice auth.User) (id : I32) :
    auth.find_user users id ⦃ o => users.val.find? (fun u => u.id = id) = o ⦄ := by
  unfold auth.find_user auth.find_user_loop
  apply WP.spec_mono (loop_search users.val (fun u => decide (u.id = id)) (fun o : Option auth.User => o)
    (fun _ u => some u) none _ ?_ 0#usize (by simp))
  · intro r hr; rw [search_find _ _ _ hr]
  · intro j hj; unfold auth.find_user_loop.body; h5i_step

@[step] theorem is_locked_spec (u : auth.User) (now : I64) :
    auth.is_locked u now ⦃ b => decide (Locked u now.val) = b ⦄ := by
  unfold auth.is_locked
  rcases h : u.lock_reason <;> rcases h' : u.lock_until with _ | t <;> simp [Locked, h, h']

@[step] theorem token_live_spec (t : auth.ApiToken) (s : Slice U8) (now : I64) :
    auth.token_live t s now ⦃ b => decide (Live t s.val now.val) = b ⦄ := by
  unfold auth.token_live
  rcases hr : t.revoked
  · rcases he : t.expired_at with _ | e
    · simp only [hr, he, Bool.false_eq_true, if_false, bind_tc_ok, if_true]
      step*; simp_all [Live]
    · simp only [hr, he, Bool.false_eq_true, if_false, bind_tc_ok]
      by_cases hlt : now.val < e.val
      · have : (e > now) = true := by simp; scalar_tac
        simp only [this, if_true]
        step*; simp_all [Live]
      · have : (e > now) = false := by simp; scalar_tac
        simp only [this, Bool.false_eq_true, if_false, WP.spec_ok]
        simp [Live, hr, he, hlt]
  · simp [Live, hr]

end cratesio_kernel.Verified.Auth
