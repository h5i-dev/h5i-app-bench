import Theorems
/-!
# The extracted `apply` computes `applyAll`

So `Runs`, built on `applyAll`, describes the states the Rust `apply` commits,
as long as no table outgrows a `Vec`.
-/
open Aeneas Aeneas.Std Result I5hLib keys_kernel

namespace Keys

theorem key_clone (k : Key) : Key.Insts.CoreCloneClone.clone k = ok k := by
  cases k; simp [Key.Insts.CoreCloneClone.clone, u8vec_clone, perm_vec_clone]

@[step] theorem session_clone_spec (x : Session) : Session.Insts.CoreCloneClone.clone x ⦃ y => y = x ⦄ := by
  cases x; simp [Session.Insts.CoreCloneClone.clone, lift, u8vec_clone, perm_vec_clone]

theorem session_clone (x : Session) : Session.Insts.CoreCloneClone.clone x = ok x :=
  eq_ok_of_spec (session_clone_spec x)

@[step] theorem snapshot_clone_spec (s : Snapshot) : Snapshot.Insts.CoreCloneClone.clone s ⦃ t => t = s ⦄ := by
  cases s
  have hr : ∀ v, alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) v = ok v :=
    fun v => vec_clone_eq _ v (fun x => u8vec_clone x)
  have hk : ∀ v, alloc.vec.CloneVec.clone Key.Insts.CoreCloneClone v = ok v :=
    fun v => vec_clone_eq Key.Insts.CoreCloneClone v key_clone
  have hs : ∀ v, alloc.vec.CloneVec.clone Session.Insts.CoreCloneClone v = ok v :=
    fun v => vec_clone_eq Session.Insts.CoreCloneClone v session_clone
  simp [Snapshot.Insts.CoreCloneClone.clone, lift, hk, hs, hr]

@[step] theorem without_spec (keys : Slice Key) (sec : alloc.vec.Vec U8) :
    without keys sec ⦃ o => o.val = keys.val.filter (fun k => k.secret ≠ sec) ⦄ := by
  unfold without without_loop
  step*; subst_vars
  apply WP.spec_mono (iter_filter_map keys (fun k => k.secret ≠ sec) id _ ?_)
  · intro o h; simp_all
  · intro i acc hi hinv
    unfold without_loop.body
    i5h_iter

/-- Room for every write in every table. -/
def Fits (s : Snapshot) (n : Nat) : Prop :=
  s.keys.val.length + n ≤ Usize.max ∧ s.revoked.val.length + n ≤ Usize.max ∧
    s.sessions.val.length + n ≤ Usize.max

theorem apply_spec (s : Snapshot) (ws : Slice Write) (h : Fits s ws.val.length) :
    apply s ws ⦃ t => toSt t = ws.val.foldl applyW (toSt s) ⦄ := by
  unfold apply apply_loop
  step*; subst_vars
  apply WP.spec_mono (iter_fold ws toSt applyW (fun t i => Fits t (ws.val.length - i)) _ ?_ 0 _
    (by simp) (by simpa using h))
  · intro t ht; simpa using ht
  · intro i acc hi hinv
    unfold apply_loop.body Fits at *
    i5h_iter [toSt, applyW, vec_deref_val]
    refine ⟨le_trans (Nat.add_le_add_right (List.length_filter_le _ _) _) (by omega), by omega, by omega⟩

end Keys
