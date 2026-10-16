import Spec
import Schema
/-!
# The lookups, as list functions

Each lookup loop of the kernel computes its counterpart over the snapshot's
lists. Search loops use `H5iAppLib.loop_search`.
-/
open Aeneas Aeneas.Std Result linkding_kernel linkding_kernel.Spec linkding_kernel.Schema H5iAppLib

namespace linkding_kernel.Helpers

@[step] theorem user_clone_spec (x : User) : User.Insts.CoreCloneClone.clone x ⦃ y => y = x ⦄ := by
  simp [User.clone_eq]

@[step] theorem find_user_spec (us : alloc.vec.Vec User) (id : U64) :
    find_user us id ⦃ o => o = us.val.find? (·.id = id) ⦄ := by
  unfold find_user find_user_loop
  apply WP.spec_mono (loop_search us.val (fun x => decide (x.id = id)) (fun o : Option User => o)
    (fun _ x => some x) none _ ?_ 0#usize (by simp))
  · intro r hr; exact search_find _ _ _ hr
  · intro j hj; unfold find_user_loop.body; h5i_step

/-- Who a presented token names: its row's user, if that user exists. -/
def tokenOf (s : Snapshot) (t : alloc.vec.Vec U8) : core.result.Result U64 Error :=
  ((s.tokens.val.find? (·.key = t)).map (fun k =>
    if (s.users.val.find? (·.id = k.user)).isSome then core.result.Result.Ok k.user
    else core.result.Result.Err Error.BadToken)).getD (core.result.Result.Err Error.BadToken)

/-- The caller: 0 (a guest) for no token, else `tokenOf`. -/
def actorOf (s : Snapshot) (t : alloc.vec.Vec U8) : core.result.Result U64 Error :=
  if t.val = [] then core.result.Result.Ok 0#u64 else tokenOf s t

@[step] theorem actor_spec (s : Snapshot) (t : alloc.vec.Vec U8) :
    actor s t ⦃ r => r = actorOf s t ⦄ := by
  unfold actor actorOf
  by_cases h : t.val = []
  · have : alloc.vec.Vec.len t = 0#usize := by
      simp [alloc.vec.Vec.len, h]; rfl
    rw [this]; simp [h]
  · have : alloc.vec.Vec.len t ≠ 0#usize := by
      intro h0; apply h
      have := congrArg UScalar.val h0
      simpa [alloc.vec.Vec.len, alloc.vec.Vec.length] using this
    simp only [this, if_false, h]
    unfold actor_loop
    apply WP.spec_mono (loop_search s.tokens.val (fun k => decide (k.key = t)) (fun r => r)
      (fun _ k => if (s.users.val.find? (·.id = k.user)).isSome then core.result.Result.Ok k.user
        else core.result.Result.Err Error.BadToken) (core.result.Result.Err Error.BadToken) _ ?_ 0#usize (by simp))
    · intro r hr
      rw [hr, searchFrom_findD]; simp [tokenOf]
    · intro j hj; unfold actor_loop.body; h5i_step

end linkding_kernel.Helpers
