import Spec
open Aeneas Aeneas.Std Result spacedrive_kernel spacedrive_kernel.Spec
open H5iAppLib

set_option maxHeartbeats 4000000

-- brought over from Scratch.lean (proved there)
axiom is_dot_false {part : Slice U8} (h : archive.is_dot part = ok false) : nats part.val ≠ dot
axiom is_dotdot_false {part : Slice U8} (h : archive.is_dotdot part = ok false) : nats part.val ≠ dotdot
axiom has_nul_false {part : Slice U8} (h : archive.has_nul part = ok false) : 0 ∉ nats part.val

theorem push_val {α} {v : alloc.vec.Vec α} {x : α} {w : alloc.vec.Vec α} (h : v.push x = ok w) :
    w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  dsimp only at h
  split at h
  · simp at h; subst h; simp
  · simp at h

theorem deref_val (cur : alloc.vec.Vec U8) : (alloc.vec.Vec.deref cur).val = cur.val := by
  simp [alloc.vec.Vec.deref]

/-- A pushed `cur` passed all four guards, so it is a safe segment. `s` is the
slice `cur.deref` the guards were applied to. -/
theorem flush_safe {cur : alloc.vec.Vec U8} {s : Slice U8}
    (hd : archive.is_dot s = ok false) (hdd : archive.is_dotdot s = ok false)
    (hn : archive.has_nul s = ok false) (hne : ¬ alloc.vec.Vec.len cur = 0#usize)
    (hs : s.val = cur.val) :
    SafeSeg (nats cur.val) := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro he; apply hne; apply UScalar.eq_of_val_eq
    have : cur.val.length = 0 := by
      have := congrArg List.length he; simpa [nats] using this
    simpa using this
  · have := is_dot_false hd; rwa [hs] at this
  · have := is_dotdot_false hdd; rwa [hs] at this
  · have := has_nul_false hn; rwa [hs] at this

set_option maxRecDepth 4096 in
theorem components_safe {normalized : Slice U8} {out : alloc.vec.Vec (alloc.vec.Vec U8)}
    (h : archive.components normalized = ok (some out)) :
    ∀ s ∈ out.val, SafeSeg (nats s.val) := by
  unfold archive.components archive.components_loop at h
  refine loop_ok (fun x => archive.components_loop.body normalized x.1 x.2.1 x.2.2)
    (fun x => (∀ s ∈ x.1.val, SafeSeg (nats s.val)) ∧ x.2.2.val ≤ normalized.val.length + 1)
    (fun o => ∀ out', o = some out' → ∀ s ∈ out'.val, SafeSeg (nats s.val))
    (fun x => normalized.val.length + 1 - x.2.2.val)
    ?_ _ (some out) ⟨by simp, by simp⟩ h out rfl
  rintro ⟨out, cur, i⟩ r ⟨hInv, hle⟩ hbody
  simp only at hInv hle
  unfold archive.components_loop.body at hbody
  h5i_invert hbody
  all_goals first
    | -- done (some out) : unchanged out
      (intro out' heq; rw [Option.some.injEq] at heq; subst heq; exact hInv)
    | -- done none
      (intro out' heq; exact absurd heq (by simp))
    | -- any cont: prove the invariant and the measure decrease
      (refine ⟨⟨?_, by dsimp only; h5i_ok_facts; scalar_tac⟩, by dsimp only; h5i_ok_facts; scalar_tac⟩
       dsimp only
       first
         | exact hInv
         | (intro s hs
            have hp : _ = _ ++ [_] := push_val (by assumption)
            rw [hp] at hs
            rcases List.mem_append.1 hs with h1 | h1
            · exact hInv s h1
            · rw [List.mem_singleton.1 h1]
              simp only [Bool.not_eq_true] at *
              subst_vars
              exact flush_safe ‹archive.is_dot _ = ok false› ‹archive.is_dotdot _ = ok false›
                ‹archive.has_nul _ = ok false› (by assumption) (by first | rfl | simp [deref_val])))
