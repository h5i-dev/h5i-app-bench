import Commands
/-!
# Committing a write set

The theorems talk about `Spec.applyAll`, the list meaning of a write set.
Here we prove that the kernel's `apply`, which the reference engine runs,
computes exactly that: `loop_search` covers the upserts and `loop_fold` the
deletes and `apply` itself.
-/
open Aeneas Aeneas.Std Result conduit_kernel conduit_kernel.Spec conduit_kernel.Helpers I5hLib

namespace conduit_kernel.ApplyProofs

/-- Rows in a snapshot; each write adds at most one. -/
def total (s : Snapshot) : Nat :=
  s.users.length + s.follows.length + s.articles.length + s.tags.length + s.favorites.length + s.comments.length

theorem follow_clone (x : Follow) : Follow.Insts.CoreCloneClone.clone x = ok x := by
  simp [Follow.Insts.CoreCloneClone.clone, lift]

theorem favorite_clone (x : Favorite) : Favorite.Insts.CoreCloneClone.clone x = ok x := by
  simp [Favorite.Insts.CoreCloneClone.clone, lift]

@[step] theorem follow_clone_spec (x : Follow) : Follow.Insts.CoreCloneClone.clone x ⦃ y => y = x ⦄ := by
  simp [follow_clone]

@[step] theorem favorite_clone_spec (x : Favorite) : Favorite.Insts.CoreCloneClone.clone x ⦃ y => y = x ⦄ := by
  simp [favorite_clone]

theorem write_clone (w : Write) : Write.Insts.CoreCloneClone.clone w = ok w := by
  cases w <;> simp [Write.Insts.CoreCloneClone.clone, user_clone, follow_clone, article_clone, tag_clone,
    favorite_clone, comment_clone, Counter.Insts.CoreCloneClone.clone, lift]

@[step] theorem write_clone_spec (w : Write) : Write.Insts.CoreCloneClone.clone w ⦃ w' => w' = w ⦄ := by
  rw [write_clone]; simp

theorem snapshot_clone (s : Snapshot) : Snapshot.Insts.CoreCloneClone.clone s = ok s := by
  simp [Snapshot.Insts.CoreCloneClone.clone, Counter.Insts.CoreCloneClone.clone, lift,
    vec_clone_eq User.Insts.CoreCloneClone s.users user_clone,
    vec_clone_eq Follow.Insts.CoreCloneClone s.follows follow_clone,
    vec_clone_eq Article.Insts.CoreCloneClone s.articles article_clone,
    vec_clone_eq Tag.Insts.CoreCloneClone s.tags tag_clone,
    vec_clone_eq Favorite.Insts.CoreCloneClone s.favorites favorite_clone,
    vec_clone_eq Comment.Insts.CoreCloneClone s.comments comment_clone]

/-! ## Table loops -/

@[step]
theorem put_user_loop_spec (v : alloc.vec.Vec User) (x : User) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (·.id) x v.val = v.val.take i.val ++ upsert (·.id) x (v.val.drop i.val)) :
    put_user_loop v x i ⦃ v' => v'.val = upsert (·.id) x v.val ⦄ := by
  unfold put_user_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide ((·.id) q = (·.id) x))
    (fun y : alloc.vec.Vec User => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (·.id) x _ _ hi hpre
  · intro j hj; unfold put_user_loop.body; i5h_step

@[step]
theorem put_follow_loop_spec (v : alloc.vec.Vec Follow) (x : Follow) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (fun f => (f.follower, f.followed)) x v.val =
      v.val.take i.val ++ upsert (fun f => (f.follower, f.followed)) x (v.val.drop i.val)) :
    put_follow_loop v x i ⦃ v' => v'.val = upsert (fun f => (f.follower, f.followed)) x v.val ⦄ := by
  unfold put_follow_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide ((q.follower, q.followed) = (x.follower, x.followed)))
    (fun y : alloc.vec.Vec Follow => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (fun f => (f.follower, f.followed)) x _ _ hi hpre
  · intro j hj; unfold put_follow_loop.body; i5h_step

@[step]
theorem put_article_loop_spec (v : alloc.vec.Vec Article) (x : Article) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (·.id) x v.val = v.val.take i.val ++ upsert (·.id) x (v.val.drop i.val)) :
    put_article_loop v x i ⦃ v' => v'.val = upsert (·.id) x v.val ⦄ := by
  unfold put_article_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide ((·.id) q = (·.id) x))
    (fun y : alloc.vec.Vec Article => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (·.id) x _ _ hi hpre
  · intro j hj; unfold put_article_loop.body; i5h_step

@[step]
theorem put_tag_loop_spec (v : alloc.vec.Vec Tag) (x : Tag) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (fun t => (t.article, t.tag)) x v.val =
      v.val.take i.val ++ upsert (fun t => (t.article, t.tag)) x (v.val.drop i.val)) :
    put_tag_loop v x i ⦃ v' => v'.val = upsert (fun t => (t.article, t.tag)) x v.val ⦄ := by
  unfold put_tag_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide ((q.article, q.tag) = (x.article, x.tag)))
    (fun y : alloc.vec.Vec Tag => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (fun t => (t.article, t.tag)) x _ _ hi hpre
  · intro j hj; unfold put_tag_loop.body; i5h_step

@[step]
theorem put_favorite_loop_spec (v : alloc.vec.Vec Favorite) (x : Favorite) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (fun f => (f.article, f.user)) x v.val =
      v.val.take i.val ++ upsert (fun f => (f.article, f.user)) x (v.val.drop i.val)) :
    put_favorite_loop v x i ⦃ v' => v'.val = upsert (fun f => (f.article, f.user)) x v.val ⦄ := by
  unfold put_favorite_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide ((q.article, q.user) = (x.article, x.user)))
    (fun y : alloc.vec.Vec Favorite => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (fun f => (f.article, f.user)) x _ _ hi hpre
  · intro j hj; unfold put_favorite_loop.body; i5h_step

@[step]
theorem put_comment_loop_spec (v : alloc.vec.Vec Comment) (x : Comment) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (·.id) x v.val = v.val.take i.val ++ upsert (·.id) x (v.val.drop i.val)) :
    put_comment_loop v x i ⦃ v' => v'.val = upsert (·.id) x v.val ⦄ := by
  unfold put_comment_loop
  apply WP.spec_mono (loop_search v.val (fun q => decide ((·.id) q = (·.id) x))
    (fun y : alloc.vec.Vec Comment => y.val) (fun j _ => v.val.set j x) (v.val ++ [x]) _ ?_ i hi)
  · intro r hr; rw [hr]; exact upsert_loop_result (·.id) x _ _ hi hpre
  · intro j hj; unfold put_comment_loop.body; i5h_step

@[step]
theorem del_follow_loop_spec (v : alloc.vec.Vec Follow) (k : Follow) (out : alloc.vec.Vec Follow)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun g => ¬(g.follower = k.follower ∧ g.followed = k.followed))) :
    del_follow_loop v k out i ⦃ v' => v'.val = v.val.filter (fun g => ¬(g.follower = k.follower ∧ g.followed = k.followed)) ⦄ := by
  unfold del_follow_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Follow => w.val)
    (fun acc x => if decide ((fun g => ¬(g.follower = k.follower ∧ g.followed = k.followed)) x) then acc ++ [x] else acc)
    (fun w j => w.length ≤ j) (fun x => del_follow_loop.body v k x.1 x.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_follow_loop.body; i5h_step

@[step]
theorem del_article_loop_spec (v : alloc.vec.Vec Article) (k : U64) (out : alloc.vec.Vec Article)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun x => x.id ≠ k)) :
    del_article_loop v k out i ⦃ v' => v'.val = v.val.filter (fun x => x.id ≠ k) ⦄ := by
  unfold del_article_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Article => w.val)
    (fun acc x => if decide ((fun x => x.id ≠ k) x) then acc ++ [x] else acc)
    (fun w j => w.length ≤ j) (fun x => del_article_loop.body v k x.1 x.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_article_loop.body; i5h_step

@[step]
theorem del_tags_of_loop_spec (v : alloc.vec.Vec Tag) (k : U64) (out : alloc.vec.Vec Tag)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun x => x.article ≠ k)) :
    del_tags_of_loop v k out i ⦃ v' => v'.val = v.val.filter (fun x => x.article ≠ k) ⦄ := by
  unfold del_tags_of_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Tag => w.val)
    (fun acc x => if decide ((fun x => x.article ≠ k) x) then acc ++ [x] else acc)
    (fun w j => w.length ≤ j) (fun x => del_tags_of_loop.body v k x.1 x.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_tags_of_loop.body; i5h_step

@[step]
theorem del_favorite_loop_spec (v : alloc.vec.Vec Favorite) (k : Favorite) (out : alloc.vec.Vec Favorite)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun g => ¬(g.article = k.article ∧ g.user = k.user))) :
    del_favorite_loop v k out i ⦃ v' => v'.val = v.val.filter (fun g => ¬(g.article = k.article ∧ g.user = k.user)) ⦄ := by
  unfold del_favorite_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Favorite => w.val)
    (fun acc x => if decide ((fun g => ¬(g.article = k.article ∧ g.user = k.user)) x) then acc ++ [x] else acc)
    (fun w j => w.length ≤ j) (fun x => del_favorite_loop.body v k x.1 x.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_favorite_loop.body; i5h_step

@[step]
theorem del_favorites_of_loop_spec (v : alloc.vec.Vec Favorite) (k : U64) (out : alloc.vec.Vec Favorite)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun x => x.article ≠ k)) :
    del_favorites_of_loop v k out i ⦃ v' => v'.val = v.val.filter (fun x => x.article ≠ k) ⦄ := by
  unfold del_favorites_of_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Favorite => w.val)
    (fun acc x => if decide ((fun x => x.article ≠ k) x) then acc ++ [x] else acc)
    (fun w j => w.length ≤ j) (fun x => del_favorites_of_loop.body v k x.1 x.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_favorites_of_loop.body; i5h_step

@[step]
theorem del_comment_loop_spec (v : alloc.vec.Vec Comment) (k : U64) (out : alloc.vec.Vec Comment)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun x => x.id ≠ k)) :
    del_comment_loop v k out i ⦃ v' => v'.val = v.val.filter (fun x => x.id ≠ k) ⦄ := by
  unfold del_comment_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Comment => w.val)
    (fun acc x => if decide ((fun x => x.id ≠ k) x) then acc ++ [x] else acc)
    (fun w j => w.length ≤ j) (fun x => del_comment_loop.body v k x.1 x.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_comment_loop.body; i5h_step

@[step]
theorem del_comments_of_loop_spec (v : alloc.vec.Vec Comment) (k : U64) (out : alloc.vec.Vec Comment)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun x => x.article ≠ k)) :
    del_comments_of_loop v k out i ⦃ v' => v'.val = v.val.filter (fun x => x.article ≠ k) ⦄ := by
  unfold del_comments_of_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Comment => w.val)
    (fun acc x => if decide ((fun x => x.article ≠ k) x) then acc ++ [x] else acc)
    (fun w j => w.length ≤ j) (fun x => del_comments_of_loop.body v k x.1 x.2) ?_ out i hi
    (by rw [alloc.vec.Vec.length, hout]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)))
  · intro r hr; rw [hr, foldl_filter, hout, filter_split]
  · intro o j hj ho; have := v.len_ineq; unfold del_comments_of_loop.body; i5h_step

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
        | (have := upsert_length (fun f => (f.follower, f.followed)) ‹Follow› s.follows.val; omega)
        | (have := upsert_length (·.id) ‹Article› s.articles.val; omega)
        | (have := upsert_length (fun t => (t.article, t.tag)) ‹Tag› s.tags.val; omega)
        | (have := upsert_length (fun f => (f.article, f.user)) ‹Favorite› s.favorites.val; omega)
        | (have := upsert_length (·.id) ‹Comment› s.comments.val; omega)
        | grind [List.length_filter_le]
    | simp

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

end conduit_kernel.ApplyProofs
