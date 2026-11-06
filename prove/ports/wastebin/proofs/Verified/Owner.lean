import Verified.View
/-!
# Owner identity: the `?owner=` handoff and the owner of a new paste
-/
open Aeneas Aeneas.Std Result wastebin_kernel wastebin_kernel.Spec
open H5iAppLib
open Aeneas.Std.WP
open wastebin_kernel.Verified.Store

namespace wastebin_kernel.Verified.Owner

/-- The uids of an optional cookie. -/
def cookieList : Option (alloc.vec.Vec I64) → List I64
  | none => []
  | some us => us.val

theorem copy_step (us a : alloc.vec.Vec I64) (i : Usize) (hi : i.val ≤ us.val.length)
    (hinv : a.val.length ≤ i.val) (hmax : us.val.length < Usize.max) (hlt : i < us.len) :
    (do
      let x ← alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice I64) us i
      let a' ← alloc.vec.Vec.push a x
      let j ← i + 1#usize
      ok (ControlFlow.cont (a', j))) ⦃ FoldStep us.val (fun (a : alloc.vec.Vec I64) => a.val)
        (fun acc x => acc ++ [x]) (fun a i => a.val.length ≤ i) a i ⦄ := by
  step*
  simp_all [FoldStep]
  all_goals scalar_tac

theorem handoff_loop_spec (us : alloc.vec.Vec I64) (hmax : us.val.length < Usize.max) :
    handlers.handoff_loop us (alloc.vec.Vec.new I64) 0#usize ⦃ out => out.val = us.val ⦄ := by
  unfold handlers.handoff_loop
  apply WP.spec_mono (loop_fold us.val (fun (a : alloc.vec.Vec I64) => a.val) (fun acc x => acc ++ [x])
    (fun a i => a.val.length ≤ i) _ ?_ (alloc.vec.Vec.new I64) 0#usize (by simp) (by simp [vec_new_val]))
  · intro r hr
    rw [show ((0#usize : Usize) : Nat) = 0 from rfl, List.drop_zero] at hr
    rw [hr, foldl_snoc]
    simp [vec_new_val]
  · intro a i hi hinv
    unfold handlers.handoff_loop.body
    dsimp only
    split
    · exact copy_step us a i hi hinv hmax ‹_›
    · simp only [WP.spec_ok, FoldStep, and_true]; scalar_tac

theorem form_owner_loop_spec (us : alloc.vec.Vec I64) (hmax : us.val.length < Usize.max) :
    handlers.form_owner_loop us (alloc.vec.Vec.new I64) 0#usize ⦃ out => out.val = us.val ⦄ := by
  unfold handlers.form_owner_loop
  apply WP.spec_mono (loop_fold us.val (fun (a : alloc.vec.Vec I64) => a.val) (fun acc x => acc ++ [x])
    (fun a i => a.val.length ≤ i) _ ?_ (alloc.vec.Vec.new I64) 0#usize (by simp) (by simp [vec_new_val]))
  · intro r hr
    rw [show ((0#usize : Usize) : Nat) = 0 from rfl, List.drop_zero] at hr
    rw [hr, foldl_snoc]
    simp [vec_new_val]
  · intro a i hi hinv
    unfold handlers.form_owner_loop.body
    dsimp only
    split
    · exact copy_step us a i hi hinv hmax ‹_›
    · simp only [WP.spec_ok, FoldStep, and_true]; scalar_tac

/-- The handoff's cookie: the old list, then the claimed uid unless it was
already there. -/
theorem handoff_spec (uids : Option (alloc.vec.Vec I64)) (c : I64)
    (hmax : (cookieList uids).length < Usize.max) :
    handlers.handoff uids c ⦃ l => l.val = cookieList uids ++ (if c ∈ cookieList uids then [] else [c]) ⦄ := by
  unfold handlers.handoff
  rcases uids with _ | us
  · step*
    all_goals simp_all [cookieList, vec_new_val]
  · simp only [cookieList] at hmax
    have hl := handoff_loop_spec us hmax
    step with hl
    step*
    all_goals simp_all [cookieList]

/-- The owner of a paste inserted through the form, and the cookie set
afterwards: the cookie's first uid and the cookie unchanged, or, without a
(non-empty) cookie, the fresh uid and a cookie holding only it. -/
theorem form_owner_spec (uids : Option (alloc.vec.Vec I64)) (fresh : I64)
    (hmax : (cookieList uids).length < Usize.max) :
    handlers.form_owner uids fresh ⦃ x => match cookieList uids with
      | [] => x.1 = fresh ∧ x.2.val = [fresh]
      | u :: rest => x.1 = u ∧ x.2.val = u :: rest ⦄ := by
  unfold handlers.form_owner
  rcases uids with _ | us
  · step*
    all_goals simp_all [cookieList, vec_new_val]
  · simp only [cookieList] at hmax ⊢
    have hl := form_owner_loop_spec us hmax
    step with hl
    rcases hu : us.val with _ | ⟨u, rest⟩
    · step*
    · step*

end wastebin_kernel.Verified.Owner
