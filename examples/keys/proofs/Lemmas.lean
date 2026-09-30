import Spec
/-!
# What the extracted functions compute

Every loop is a `for` over a slice; each lemma is a list form from
`I5hLib.Iter` and one `i5h_iter`.
-/
open Aeneas Aeneas.Std Result I5hLib keys_kernel

namespace Keys

@[step] theorem permits_spec (p : Perm) (a : Action) : permits p a ⦃ b => b = permitsM p a ⦄ := by
  unfold permits
  cases p <;> cases a <;> step* <;> simp_all [permitsM]

/-- `grants` looks at the whole permission list. -/
@[step] theorem grants_spec (ps : Slice Perm) (a : Action) : grants ps a ⦃ b => b = grantsM ps.val a ⦄ := by
  unfold grants grants_loop
  step*; subst_vars
  apply WP.spec_mono (iter_any ps (permitsM · a) true false _ ?_)
  · intro b h; rw [h, grantsM]; cases ps.val.any _ <;> rfl
  · intro i hi
    unfold grants_loop.body
    i5h_iter

@[step] theorem find_key_spec (keys : Slice Key) (sec : alloc.vec.Vec U8) :
    find_key keys sec ⦃ o => findKey keys.val sec = o ⦄ := by
  unfold find_key find_key_loop
  step*; subst_vars
  apply WP.spec_mono (iter_find keys (fun k => k.secret = sec) _ ?_)
  · intro o h; exact h.symm
  · intro i hi
    unfold find_key_loop.body
    i5h_iter

@[step] theorem is_revoked_spec (revoked : Slice (alloc.vec.Vec U8)) (sec : alloc.vec.Vec U8) :
    is_revoked revoked sec ⦃ b => b = revoked.val.any (fun r => r = sec) ⦄ := by
  unfold is_revoked is_revoked_loop
  step*; subst_vars
  apply WP.spec_mono (iter_any revoked (fun r => r = sec) true false _ ?_)
  · intro b h; rw [h]; cases revoked.val.any _ <;> rfl
  · intro i hi
    unfold is_revoked_loop.body
    i5h_iter

@[step] theorem find_session_spec (sessions : Slice Session) (id : U64) :
    find_session sessions id ⦃ o => sessions.val.find? (fun x => x.id = id) = o ⦄ := by
  unfold find_session find_session_loop
  step*; subst_vars
  apply WP.spec_mono (iter_find sessions (fun x => x.id = id) _ ?_)
  · intro o h; exact h.symm
  · intro i hi
    unfold find_session_loop.body
    i5h_iter

theorem perm_vec_clone (v : alloc.vec.Vec Perm) : alloc.vec.CloneVec.clone Perm.Insts.CoreCloneClone v = ok v :=
  vec_clone_eq _ v (fun _ => rfl)

@[step] theorem perm_vec_clone_spec (v : alloc.vec.Vec Perm) :
    alloc.vec.CloneVec.clone Perm.Insts.CoreCloneClone v ⦃ x => x = v ⦄ := by
  simp [perm_vec_clone]

@[step] theorem key_clone_spec (k : Key) : Key.Insts.CoreCloneClone.clone k ⦃ x => x = k ⦄ := by
  cases k
  simp [Key.Insts.CoreCloneClone.clone, u8vec_clone, perm_vec_clone]

@[step] theorem taken_spec (s : Snapshot) (sec : alloc.vec.Vec U8) :
    taken s sec ⦃ b => b = takenM s sec ⦄ := by
  unfold taken
  step*
  all_goals simp_all [takenM, vec_deref_val]

@[step] theorem live_spec (keys : Slice Key) (sec : alloc.vec.Vec U8) :
    live keys sec ⦃ o => o = findKey keys.val sec ⦄ := by
  unfold live
  step*

@[step] theorem resolve_spec (s : Snapshot) (c : Cred) : resolve s c false ⦃ o => o = resolveM s c ⦄ := by
  unfold resolve
  cases c <;> step* <;> simp_all [resolveM, vec_deref_val, -List.find?_eq_none]

@[step] theorem resolve_pre_spec (s : Snapshot) (c : Cred) : resolve s c true ⦃ o => o = resolvePreM s c ⦄ := by
  unfold resolve
  cases c <;> step* <;> simp_all [resolvePreM, vec_deref_val, -List.find?_eq_none]

end Keys
