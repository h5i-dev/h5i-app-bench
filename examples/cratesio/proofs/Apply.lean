import Theorems
/-!
# Committing a write set

The theorems talk about `Spec.applyAll`, the list meaning of a write set.
Here we prove that the kernel's own `apply`, which the reference engine runs,
computes exactly that. Each loop is covered by a lemma from `I5hLib`:
`loop_search` for the upserts and `loop_fold` for the deletes and for `apply`
itself.
-/
open Aeneas Aeneas.Std Result cratesio_kernel cratesio_kernel.Spec I5hLib

namespace cratesio_kernel.ApplyProofs

/-- Rows in a snapshot; each write adds at most one. -/
def total (s : Snapshot) : Nat :=
  s.users.length + s.sessions.length + s.tokens.length + s.crates.length + s.versions.length +
    s.owners.length + s.invites.length + s.deps.length

theorem snapshot_clone (s : Snapshot) : Snapshot.Insts.CoreCloneClone.clone s = ok s := by
  simp [Snapshot.Insts.CoreCloneClone.clone, Counter.Insts.CoreCloneClone.clone,
    vec_clone_eq User.Insts.CoreCloneClone s.users (fun _ => rfl),
    vec_clone_eq Session.Insts.CoreCloneClone s.sessions (fun _ => rfl),
    vec_clone_eq Token.Insts.CoreCloneClone s.tokens (fun _ => rfl),
    vec_clone_eq Krate.Insts.CoreCloneClone s.crates (fun _ => rfl),
    vec_clone_eq Version.Insts.CoreCloneClone s.versions (fun _ => rfl),
    vec_clone_eq Owner.Insts.CoreCloneClone s.owners (fun _ => rfl),
    vec_clone_eq Invite.Insts.CoreCloneClone s.invites (fun _ => rfl),
    vec_clone_eq Dep.Insts.CoreCloneClone s.deps (fun _ => rfl)]

/-! ## Upserts -/

@[step]
theorem put_user_loop_spec (v : alloc.vec.Vec User) (x : User) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (·.id) x v.val = v.val.take i.val ++ upsert (·.id) x (v.val.drop i.val)) :
    put_user_loop v x i ⦃ v' => v'.val = upsert (·.id) x v.val ⦄ := by
  unfold put_user_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide (q.id = x.id))
    (fun y : alloc.vec.Vec User => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (·.id) x _ _ hi hpre
  · intro j hj; unfold put_user_loop.body; i5h_step

@[step]
theorem put_session_loop_spec (v : alloc.vec.Vec Session) (x : Session) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (·.id) x v.val = v.val.take i.val ++ upsert (·.id) x (v.val.drop i.val)) :
    put_session_loop v x i ⦃ v' => v'.val = upsert (·.id) x v.val ⦄ := by
  unfold put_session_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide (q.id = x.id))
    (fun y : alloc.vec.Vec Session => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (·.id) x _ _ hi hpre
  · intro j hj; unfold put_session_loop.body; i5h_step

@[step]
theorem put_token_loop_spec (v : alloc.vec.Vec Token) (x : Token) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (·.id) x v.val = v.val.take i.val ++ upsert (·.id) x (v.val.drop i.val)) :
    put_token_loop v x i ⦃ v' => v'.val = upsert (·.id) x v.val ⦄ := by
  unfold put_token_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide (q.id = x.id))
    (fun y : alloc.vec.Vec Token => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (·.id) x _ _ hi hpre
  · intro j hj; unfold put_token_loop.body; i5h_step

@[step]
theorem put_crate_loop_spec (v : alloc.vec.Vec Krate) (x : Krate) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (·.id) x v.val = v.val.take i.val ++ upsert (·.id) x (v.val.drop i.val)) :
    put_crate_loop v x i ⦃ v' => v'.val = upsert (·.id) x v.val ⦄ := by
  unfold put_crate_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide (q.id = x.id))
    (fun y : alloc.vec.Vec Krate => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (·.id) x _ _ hi hpre
  · intro j hj; unfold put_crate_loop.body; i5h_step

@[step]
theorem put_version_loop_spec (v : alloc.vec.Vec Version) (x : Version) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (fun v => (v.krate, v.num)) x v.val = v.val.take i.val ++ upsert (fun v => (v.krate, v.num)) x (v.val.drop i.val)) :
    put_version_loop v x i ⦃ v' => v'.val = upsert (fun v => (v.krate, v.num)) x v.val ⦄ := by
  unfold put_version_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide ((q.krate, q.num) = (x.krate, x.num)))
    (fun y : alloc.vec.Vec Version => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (fun v => (v.krate, v.num)) x _ _ hi hpre
  · intro j hj; unfold put_version_loop.body; i5h_step

@[step]
theorem put_owner_loop_spec (v : alloc.vec.Vec Owner) (x : Owner) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (fun o => (o.krate, o.owner, o.team)) x v.val = v.val.take i.val ++ upsert (fun o => (o.krate, o.owner, o.team)) x (v.val.drop i.val)) :
    put_owner_loop v x i ⦃ v' => v'.val = upsert (fun o => (o.krate, o.owner, o.team)) x v.val ⦄ := by
  unfold put_owner_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide ((q.krate, q.owner, q.team) = (x.krate, x.owner, x.team)))
    (fun y : alloc.vec.Vec Owner => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (fun o => (o.krate, o.owner, o.team)) x _ _ hi hpre
  · intro j hj; unfold put_owner_loop.body; i5h_step

@[step]
theorem put_invite_loop_spec (v : alloc.vec.Vec Invite) (x : Invite) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (fun i => (i.krate, i.user)) x v.val = v.val.take i.val ++ upsert (fun i => (i.krate, i.user)) x (v.val.drop i.val)) :
    put_invite_loop v x i ⦃ v' => v'.val = upsert (fun i => (i.krate, i.user)) x v.val ⦄ := by
  unfold put_invite_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide ((q.krate, q.user) = (x.krate, x.user)))
    (fun y : alloc.vec.Vec Invite => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (fun i => (i.krate, i.user)) x _ _ hi hpre
  · intro j hj; unfold put_invite_loop.body; i5h_step

@[step]
theorem put_dep_loop_spec (v : alloc.vec.Vec Dep) (x : Dep) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (fun d => (d.krate, d.num, d.on)) x v.val = v.val.take i.val ++ upsert (fun d => (d.krate, d.num, d.on)) x (v.val.drop i.val)) :
    put_dep_loop v x i ⦃ v' => v'.val = upsert (fun d => (d.krate, d.num, d.on)) x v.val ⦄ := by
  unfold put_dep_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide ((q.krate, q.num, q.on) = (x.krate, x.num, x.on)))
    (fun y : alloc.vec.Vec Dep => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (fun d => (d.krate, d.num, d.on)) x _ _ hi hpre
  · intro j hj; unfold put_dep_loop.body; i5h_step

/-! ## Deletes -/

@[step]
theorem del_owner_loop_spec (v : alloc.vec.Vec Owner) (x : Owner) (out : alloc.vec.Vec Owner)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun o => decide ((o.krate, o.owner, o.team) ≠ (x.krate, x.owner, x.team)))) :
    del_owner_loop v x out i ⦃ v' => v'.val = v.val.filter (fun o => decide ((o.krate, o.owner, o.team) ≠ (x.krate, x.owner, x.team))) ⦄ := by
  unfold del_owner_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Owner => w.val)
    (fun acc y => if (fun o => decide ((o.krate, o.owner, o.team) ≠ (x.krate, x.owner, x.team))) y then acc ++ [y] else acc)
    (fun w j => w.length ≤ j) (fun y => del_owner_loop.body v x y.1 y.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_owner_loop.body; i5h_step

@[step]
theorem del_invite_loop_spec (v : alloc.vec.Vec Invite) (k u : U64) (out : alloc.vec.Vec Invite)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun i => decide ((i.krate, i.user) ≠ (k, u)))) :
    del_invite_loop v k u out i ⦃ v' => v'.val = v.val.filter (fun i => decide ((i.krate, i.user) ≠ (k, u))) ⦄ := by
  unfold del_invite_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Invite => w.val)
    (fun acc y => if (fun i => decide ((i.krate, i.user) ≠ (k, u))) y then acc ++ [y] else acc)
    (fun w j => w.length ≤ j) (fun y => del_invite_loop.body v k u y.1 y.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_invite_loop.body; i5h_step

@[step]
theorem del_crate_loop_spec (v : alloc.vec.Vec Krate) (k : U64) (out : alloc.vec.Vec Krate)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun c => decide (c.id ≠ k))) :
    del_crate_loop v k out i ⦃ v' => v'.val = v.val.filter (fun c => decide (c.id ≠ k)) ⦄ := by
  unfold del_crate_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Krate => w.val)
    (fun acc y => if (fun c => decide (c.id ≠ k)) y then acc ++ [y] else acc)
    (fun w j => w.length ≤ j) (fun y => del_crate_loop.body v k y.1 y.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_crate_loop.body; i5h_step

@[step]
theorem del_versions_of_loop_spec (v : alloc.vec.Vec Version) (k : U64) (out : alloc.vec.Vec Version)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun c => decide (c.krate ≠ k))) :
    del_versions_of_loop v k out i ⦃ v' => v'.val = v.val.filter (fun c => decide (c.krate ≠ k)) ⦄ := by
  unfold del_versions_of_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Version => w.val)
    (fun acc y => if (fun c => decide (c.krate ≠ k)) y then acc ++ [y] else acc)
    (fun w j => w.length ≤ j) (fun y => del_versions_of_loop.body v k y.1 y.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_versions_of_loop.body; i5h_step

@[step]
theorem del_owners_of_loop_spec (v : alloc.vec.Vec Owner) (k : U64) (out : alloc.vec.Vec Owner)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun c => decide (c.krate ≠ k))) :
    del_owners_of_loop v k out i ⦃ v' => v'.val = v.val.filter (fun c => decide (c.krate ≠ k)) ⦄ := by
  unfold del_owners_of_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Owner => w.val)
    (fun acc y => if (fun c => decide (c.krate ≠ k)) y then acc ++ [y] else acc)
    (fun w j => w.length ≤ j) (fun y => del_owners_of_loop.body v k y.1 y.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_owners_of_loop.body; i5h_step

@[step]
theorem del_invites_of_loop_spec (v : alloc.vec.Vec Invite) (k : U64) (out : alloc.vec.Vec Invite)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun c => decide (c.krate ≠ k))) :
    del_invites_of_loop v k out i ⦃ v' => v'.val = v.val.filter (fun c => decide (c.krate ≠ k)) ⦄ := by
  unfold del_invites_of_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Invite => w.val)
    (fun acc y => if (fun c => decide (c.krate ≠ k)) y then acc ++ [y] else acc)
    (fun w j => w.length ≤ j) (fun y => del_invites_of_loop.body v k y.1 y.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_invites_of_loop.body; i5h_step

@[step]
theorem del_deps_of_loop_spec (v : alloc.vec.Vec Dep) (k : U64) (out : alloc.vec.Vec Dep)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun c => decide (c.krate ≠ k))) :
    del_deps_of_loop v k out i ⦃ v' => v'.val = v.val.filter (fun c => decide (c.krate ≠ k)) ⦄ := by
  unfold del_deps_of_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Dep => w.val)
    (fun acc y => if (fun c => decide (c.krate ≠ k)) y then acc ++ [y] else acc)
    (fun w j => w.length ≤ j) (fun y => del_deps_of_loop.body v k y.1 y.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_deps_of_loop.body; i5h_step

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
        | (have := upsert_length (·.id) ‹User› s.users.val; omega)
        | (have := upsert_length (·.id) ‹Session› s.sessions.val; omega)
        | (have := upsert_length (·.id) ‹Token› s.tokens.val; omega)
        | (have := upsert_length (·.id) ‹Krate› s.crates.val; omega)
        | (have := upsert_length (fun v => (v.krate, v.num)) ‹Version› s.versions.val; omega)
        | (have := upsert_length (fun o => (o.krate, o.owner, o.team)) ‹Owner› s.owners.val; omega)
        | (have := upsert_length (fun i => (i.krate, i.user)) ‹Invite› s.invites.val; omega)
        | (have := upsert_length (fun d => (d.krate, d.num, d.on)) ‹Dep› s.deps.val; omega)
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

end cratesio_kernel.ApplyProofs
