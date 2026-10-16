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

@[step] theorem bookmark_clone_spec (x : Bookmark) : Bookmark.Insts.CoreCloneClone.clone x ⦃ y => y = x ⦄ := by
  simp [Bookmark.clone_eq]

@[step] theorem tag_clone_spec (x : Tag) : Tag.Insts.CoreCloneClone.clone x ⦃ y => y = x ⦄ := by
  simp [Tag.clone_eq]

@[step] theorem bundle_clone_spec (x : Bundle) : Bundle.Insts.CoreCloneClone.clone x ⦃ y => y = x ⦄ := by
  simp [Bundle.clone_eq]

@[step] theorem find_bookmark_spec (v : alloc.vec.Vec Bookmark) (id : U64) :
    find_bookmark v id ⦃ o => o = v.val.find? (·.id = id) ⦄ := by
  unfold find_bookmark find_bookmark_loop
  apply WP.spec_mono (loop_search v.val (fun x => decide (x.id = id)) (fun o : Option Bookmark => o)
    (fun _ x => some x) none _ ?_ 0#usize (by simp))
  · intro r hr; exact search_find _ _ _ hr
  · intro j hj; unfold find_bookmark_loop.body; h5i_step

@[step] theorem find_tag_spec (v : alloc.vec.Vec Tag) (id : U64) :
    find_tag v id ⦃ o => o = v.val.find? (·.id = id) ⦄ := by
  unfold find_tag find_tag_loop
  apply WP.spec_mono (loop_search v.val (fun x => decide (x.id = id)) (fun o : Option Tag => o)
    (fun _ x => some x) none _ ?_ 0#usize (by simp))
  · intro r hr; exact search_find _ _ _ hr
  · intro j hj; unfold find_tag_loop.body; h5i_step

@[step] theorem find_bundle_spec (v : alloc.vec.Vec Bundle) (id : U64) :
    find_bundle v id ⦃ o => o = v.val.find? (·.id = id) ⦄ := by
  unfold find_bundle find_bundle_loop
  apply WP.spec_mono (loop_search v.val (fun x => decide (x.id = id)) (fun o : Option Bundle => o)
    (fun _ x => some x) none _ ?_ 0#usize (by simp))
  · intro r hr; exact search_find _ _ _ hr
  · intro j hj; unfold find_bundle_loop.body; h5i_step

@[step] theorem find_tag_named_spec (v : alloc.vec.Vec Tag) (owner : U64) (lower : alloc.vec.Vec U8) :
    find_tag_named v owner lower ⦃ o => o = v.val.find? (fun t => t.owner = owner ∧ t.name_lower = lower) ⦄ := by
  unfold find_tag_named find_tag_named_loop
  apply WP.spec_mono (loop_search v.val (fun t => decide (t.owner = owner ∧ t.name_lower = lower))
    (fun o : Option Tag => o) (fun _ x => some x) none _ ?_ 0#usize (by simp))
  · intro r hr; exact search_find _ _ _ hr
  · intro j hj; unfold find_tag_named_loop.body; h5i_step

/-- `signed_in`: the token's user, if the token names one. -/
theorem signed_in_ok (s : Snapshot) (t : alloc.vec.Vec U8) (me : User)
    (h : signed_in s t = ok (.Ok me)) : actorOf s t = .Ok me.id ∧ me ∈ s.users.val := by
  unfold signed_in at h
  have ha := eq_ok_of_spec (actor_spec s t)
  rw [ha] at h
  rcases hact : actorOf s t with v | e <;> simp only [hact, bind_ok] at h
  · by_cases hv0 : v = 0#u64
    · simp [hv0] at h
    · have hf := eq_ok_of_spec (find_user_spec s.users v)
      simp only [hv0, if_false, hf, bind_ok] at h
      split at h
      · simp at h
      · rename_i me' hme
        simp only [ok.injEq, core.result.Result.Ok.injEq] at h
        subst h
        have := List.find?_some hme
        simp at this
        exact ⟨by rw [this], List.mem_of_find?_eq_some hme⟩
  · simp at h

theorem push_ok {α} {v w : alloc.vec.Vec α} {x : α} (h : v.push x = ok w) : w.val = v.val ++ [x] := by
  have hlen : v.val.length < Usize.max := by
    by_contra hn
    unfold alloc.vec.Vec.push at h
    simp only at h
    split at h
    · rename_i hc
      simp only [Bool.or_eq_true, decide_eq_true_eq] at hc
      rcases hc with hc | hc
      · have : U32.max ≤ Usize.max := by scalar_tac
        omega
      · omega
    · simp at h
  have := alloc.vec.Vec.push_spec v x hlen
  rw [h] at this
  simpa using this

theorem tag_clone_ok {x y : Tag} (h : Tag.Insts.CoreCloneClone.clone x = ok y) : y = x := by
  rw [Schema.Tag.clone_eq] at h; simp at h; exact h.symm

theorem bundle_clone_ok {x y : Bundle} (h : Bundle.Insts.CoreCloneClone.clone x = ok y) : y = x := by
  rw [Schema.Bundle.clone_eq] at h; simp at h; exact h.symm

theorem bookmark_clone_ok {x y : Bookmark} (h : Bookmark.Insts.CoreCloneClone.clone x = ok y) : y = x := by
  rw [Schema.Bookmark.clone_eq] at h; simp at h; exact h.symm

end linkding_kernel.Helpers
