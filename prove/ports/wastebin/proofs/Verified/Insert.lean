import Verified.Delete
import Verified.Get
/-!
# Insert (`Handler::insert`) and purge (`Handler::purge`)
-/
open Aeneas Aeneas.Std Result wastebin_kernel wastebin_kernel.Spec
open H5iAppLib
open Aeneas.Std.WP
open wastebin_kernel.Verified.Store wastebin_kernel.Verified.Delete wastebin_kernel.Verified.Get

namespace wastebin_kernel.Verified.Insert

@[step] theorem id_taken_spec (rows : alloc.vec.Vec Row) (id : I64) :
    handlers.id_taken rows id ⦃ b => b = rows.val.any (fun r => decide (r.id = id)) ⦄ := by
  unfold handlers.id_taken handlers.id_taken_loop
  apply WP.spec_mono (loop_search rows.val (fun r => decide (r.id = id)) (fun b : Bool => b)
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr; exact search_any _ _ _ hr
  · intro j hj; unfold handlers.id_taken_loop.body; h5i_step

theorem push_val {α : Type} {v : alloc.vec.Vec α} {x : α} {w : alloc.vec.Vec α}
    (h : alloc.vec.Vec.push v x = ok w) : w.val = v.val ++ [x] := by
  by_cases hb : v.val.length < Usize.max
  · exact post_of_ok (P := fun w => w.val = v.val ++ [x]) (alloc.vec.Vec.push_spec v x hb) h
  · exfalso
    unfold alloc.vec.Vec.push at h
    dsimp only at h
    split at h
    · rename_i hc
      simp only [Bool.or_eq_true, decide_eq_true_eq] at hc
      have : U32.max ≤ Usize.max := by scalar_tac
      omega
    · simp at h

/-- The row `insert` writes. -/
def newRow (id : I64) (p : handlers.NewPaste) : Row :=
  { id, uid := some p.uid, burn := p.burn, secret := p.password, expires := p.expires, data := p.data,
    title := p.title }

theorem insert_ok (rows : alloc.vec.Vec Row) (ids : Slice I64) (p : handlers.NewPaste) (id : I64)
    (v : alloc.vec.Vec Row) (h : handlers.insert rows ids p = ok (some (id, v))) :
    id ∈ ids.val.take 11 ∧ (∀ r ∈ rows.val, r.id ≠ id) ∧ v.val = rows.val ++ [newRow id p] := by
  unfold handlers.insert handlers.insert_loop at h
  refine loop_ok (fun k => handlers.insert_loop.body rows ids p k) (fun k => k.val ≤ 10)
    (fun o => ∀ id v, o = some (id, v) →
      id ∈ ids.val.take 11 ∧ (∀ r ∈ rows.val, r.id ≠ id) ∧ v.val = rows.val ++ [newRow id p])
    (fun k => ids.val.length - k.val) ?_ 0#usize _ (by simp) h id v rfl
  intro k res hk hb
  unfold handlers.insert_loop.body at hb
  h5i_invert hb
  · intro i' v' e; cases e
  · h5i_ok_facts
    exact ⟨by scalar_tac, by scalar_tac⟩
  · intro i' v' e
    simp only [Option.some.injEq, Prod.mk.injEq] at e
    obtain ⟨rfl, rfl⟩ := e
    have hb := post_of_ok (id_taken_spec _ _) ‹_›
    have hid := slice_index_ok ‹ids.index_usize k = ok _›
    refine ⟨?_, fun r hr he => ?_, ?_⟩
    · obtain ⟨hk', hx⟩ := hid
      rw [← hx]
      exact List.mem_iff_getElem.2 ⟨k.val, by simp; scalar_tac, by simp⟩
    · have : rows.val.any (fun r => decide (r.id = _)) = true := List.any_eq_true.2 ⟨r, hr, by simpa using he⟩
      simp_all
    · have hout := ‹alloc.vec.CloneVec.clone store.Row.Insts.CoreCloneClone rows = ok _›
      rw [clone_rows rows] at hout
      have := Result.ok.inj hout; subst this
      rw [push_val ‹_›]; rfl
  · intro i' v' e; cases e

/-- `purge` keeps exactly the rows that have not expired, in order. -/
theorem purge_spec (rows : alloc.vec.Vec Row) (now : I64) :
    store.purge rows now ⦃ v => v.val = rows.val.filter (fun r => !decide (Expired r now.val)) ⦄ := by
  unfold store.purge store.purge_loop
  apply WP.spec_mono (loop_fold rows.val (fun (a : alloc.vec.Vec Row) => a.val)
    (fun acc r => if !decide (Expired r now.val) then acc ++ [r] else acc)
    (fun a i => a.val.length ≤ i) _ ?_ (alloc.vec.Vec.new Row) 0#usize (by simp) (by simp [vec_new_val]))
  · intro r hr
    rw [show ((0#usize : Usize) : Nat) = 0 from rfl, List.drop_zero] at hr
    rw [hr, foldl_filter]
    simp [vec_new_val]
  · intro a i hi hinv
    unfold store.purge_loop.body
    dsimp only
    split
    · h5i_steps
      all_goals (simp only [FoldStep]; refine ⟨by scalar_tac, ?_, by scalar_tac, ?_⟩)
      all_goals simp_all
      all_goals scalar_tac
    · simp only [WP.spec_ok, FoldStep, and_true]; scalar_tac

end wastebin_kernel.Verified.Insert
