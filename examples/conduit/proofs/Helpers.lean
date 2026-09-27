import Spec
/-!
# The helpers, as list functions

Each lookup and loop of the kernel computes its counterpart from `Spec.lean`.
Search loops use `I5hLib.loop_search` and the others `I5hLib.loop_fold`.
Views take a flag `up` that selects upstream's `favorited` (issue #16).
-/
open Aeneas Aeneas.Std Result conduit_kernel conduit_kernel.Spec I5hLib

namespace conduit_kernel.Helpers

/-! ## Both variants of the favorite flag -/

def favFlag (up : Bool) (s : St) (u a : U64) : Bool :=
  if up then favoritedUpstream s u else favorited s u a

def viewWith (up : Bool) (s : St) (viewer : U64) (a : Article) : View :=
  ⟨a, tagsOf s a.id, favFlag up s viewer a.id, favCount s a.id, authorOf s viewer a.author⟩

def listedWith (up : Bool) (s : St) (tag : Option Text) (author fav : Option U64) (a : Article) : Bool :=
  tag.all (fun t => s.tags.any (fun x => x.article = a.id ∧ x.tag = t)) &&
    author.all (a.author = ·) && fav.all (fun u => favFlag up s u a.id)

@[simp] theorem viewWith_false : viewWith false = view := rfl
@[simp] theorem listedWith_false : listedWith false = listed := rfl

/-! ## Lists -/

theorem foldl_filter_map {α β} (P : α → Bool) (f : α → β) (l : List α) (acc : List β) :
    l.foldl (fun acc x => if P x then acc ++ [f x] else acc) acc = acc ++ (l.filter P).map f := by
  induction l generalizing acc with
  | nil => simp
  | cons y ys ih => rw [List.foldl_cons, ih]; by_cases hp : P y <;> simp [hp, List.filter_cons]

theorem foldl_map_acc {α β} (f : α → β) (l : List α) (acc : List β) :
    l.foldl (fun acc x => acc ++ [f x]) acc = acc ++ l.map f := by
  induction l generalizing acc with
  | nil => simp
  | cons y ys ih => rw [List.foldl_cons, ih]; simp

theorem length_filter_map_le {α β} (P : α → Bool) (f : α → β) (l : List α) (k : Nat) :
    ((l.take k).filter P |>.map f).length ≤ k := by
  simp only [List.length_map]
  exact (List.length_filter_le _ _).trans (List.length_take_le _ _)

theorem distinct_length_le {α} [DecidableEq α] (l acc : List α) :
    (l.foldl (fun acc x => if acc.any (· = x) then acc else acc ++ [x]) acc).length ≤ acc.length + l.length := by
  induction l generalizing acc with
  | nil => simp
  | cons y ys ih =>
    rw [List.foldl_cons]
    refine (ih _).trans ?_
    split <;> simp <;> omega

/-! ## Scalars, clones, equality -/

@[simp] theorem u64_val_eq (x y : U64) : x.val = y.val ↔ x = y :=
  ⟨fun h => by scalar_tac, fun h => h ▸ rfl⟩

theorem u8vec_clone (v : Text) : alloc.vec.CloneVec.clone core.clone.CloneU8 v = ok v :=
  vec_clone_eq _ v (fun _ => rfl)

@[step] theorem u8vec_clone_spec (v : Text) :
    alloc.vec.CloneVec.clone core.clone.CloneU8 v ⦃ w => w = v ⦄ := by
  simp [u8vec_clone]

theorem user_clone (x : User) : User.Insts.CoreCloneClone.clone x = ok x := by
  simp [User.Insts.CoreCloneClone.clone, u8vec_clone, lift]

theorem article_clone (x : Article) : Article.Insts.CoreCloneClone.clone x = ok x := by
  simp [Article.Insts.CoreCloneClone.clone, u8vec_clone, lift]

theorem comment_clone (x : Comment) : Comment.Insts.CoreCloneClone.clone x = ok x := by
  simp [Comment.Insts.CoreCloneClone.clone, u8vec_clone, lift]

theorem tag_clone (x : Tag) : Tag.Insts.CoreCloneClone.clone x = ok x := by
  simp [Tag.Insts.CoreCloneClone.clone, u8vec_clone, lift]

@[step] theorem user_clone_spec (x : User) : User.Insts.CoreCloneClone.clone x ⦃ y => y = x ⦄ := by
  simp [user_clone]

@[step] theorem article_clone_spec (x : Article) : Article.Insts.CoreCloneClone.clone x ⦃ y => y = x ⦄ := by
  simp [article_clone]

@[step] theorem comment_clone_spec (x : Comment) : Comment.Insts.CoreCloneClone.clone x ⦃ y => y = x ⦄ := by
  simp [comment_clone]

@[step] theorem tag_clone_spec (x : Tag) : Tag.Insts.CoreCloneClone.clone x ⦃ y => y = x ⦄ := by
  simp [tag_clone]

theorem allM_u8 (l : List (U8 × U8)) :
    List.allM (fun (p : U8 × U8) => core.cmp.PartialEqU8.eq p.1 p.2) l =
      ok (l.all (fun p => decide (p.1 = p.2))) := by
  induction l with
  | nil => rfl
  | cons p ps ih =>
    by_cases h : p.1 = p.2 <;> simp [List.allM, liftFun2, h, ih] <;> rfl

theorem zip_all_eq (a b : List U8) (h : a.length = b.length) :
    (List.zip a b).all (fun p => decide (p.1 = p.2)) = decide (a = b) := by
  induction a generalizing b with
  | nil => cases b <;> simp_all
  | cons x xs ih =>
    cases b with
    | nil => simp at h
    | cons y ys =>
      simp only [List.length_cons, Nat.add_right_cancel_iff] at h
      simp [List.zip_cons_cons, ih ys h]

/-- `==` on byte strings. -/
@[step]
theorem vec_u8_eq_spec (v w : Text) :
    alloc.vec.partial_eq.PartialEqVec.eq core.cmp.PartialEqU8 v w ⦃ b => b = decide (v = w) ⦄ := by
  unfold alloc.vec.partial_eq.PartialEqVec.eq
  split
  · rename_i hlen
    rw [show (fun (x : U8 × U8) => match x with | (x0, x1) => core.cmp.PartialEqU8.eq x0 x1) =
        (fun p => core.cmp.PartialEqU8.eq p.1 p.2) from rfl, allM_u8]
    simp only [WP.spec_ok]
    rw [zip_all_eq _ _ hlen]; exact decide_eq_decide.2 (alloc.vec.Vec.eq_iff v w).symm
  · rename_i hlen
    simp only [WP.spec_ok]
    have : v ≠ w := fun h => hlen (by simp [h])
    simp [this]

@[simp] theorem usize_cast_u64 (n : Usize) : (UScalar.cast .U64 n).val = n.val := by
  rw [UScalar.cast_val_eq]; apply Nat.mod_eq_of_lt
  have h1 := usize_max_le; have h2 : n.val ≤ Usize.max := by scalar_tac
  rw [U64.max_def] at h1; simp [U64.numBits] at h1; simp; omega

@[step] theorem one_spec (w : Write) : one w ⦃ v => v.val = [w] ⦄ := by
  unfold one; step*

@[simp] theorem u64_bne (x y : U64) : (x != y) = !decide (x = y) := by
  by_cases h : x = y <;> simp [h]

/-! ## Lookups -/

theorem search_bool {α} (l : List α) (P : α → Bool) (r : Bool)
    (hr : r = searchFrom l P (fun _ _ => true) false (↑(0#usize : Usize))) : r = l.any P := by
  rw [hr, searchFrom_const, UScalar.ofNatCore_val_eq, List.drop_zero]; cases l.any P <;> rfl

theorem search_find {α} (l : List α) (P : α → Bool) (r : Option α)
    (hr : r = searchFrom l P (fun _ x => some x) none (↑(0#usize : Usize))) : r = l.find? P := by
  rw [hr, show (fun (_ : Nat) (x : α) => some x) = (fun _ x => some (_root_.id x)) from rfl,
    searchFrom_find, UScalar.ofNatCore_val_eq, List.drop_zero]; simp

@[step] theorem find_user_spec (us : alloc.vec.Vec User) (id : U64) :
    find_user us id ⦃ o => o = us.val.find? (·.id = id) ⦄ := by
  unfold find_user find_user_loop
  apply WP.spec_mono (loop_search us.val (fun x => decide (x.id = id)) (fun o : Option User => o)
    (fun _ x => some x) none _ ?_ 0#usize (by simp))
  · intro r hr; exact search_find _ _ _ hr
  · intro j hj; unfold find_user_loop.body; i5h_step

@[step] theorem find_user_by_name_spec (us : alloc.vec.Vec User) (n : Text) :
    find_user_by_name us n ⦃ o => o = us.val.find? (·.username = n) ⦄ := by
  unfold find_user_by_name find_user_by_name_loop
  apply WP.spec_mono (loop_search us.val (fun x => decide (x.username = n)) (fun o : Option User => o)
    (fun _ x => some x) none _ ?_ 0#usize (by simp))
  · intro r hr; exact search_find _ _ _ hr
  · intro j hj; unfold find_user_by_name_loop.body; i5h_step

@[step] theorem find_user_by_email_spec (us : alloc.vec.Vec User) (e : Text) :
    find_user_by_email us e ⦃ o => o = us.val.find? (·.email = e) ⦄ := by
  unfold find_user_by_email find_user_by_email_loop
  apply WP.spec_mono (loop_search us.val (fun x => decide (x.email = e)) (fun o : Option User => o)
    (fun _ x => some x) none _ ?_ 0#usize (by simp))
  · intro r hr; exact search_find _ _ _ hr
  · intro j hj; unfold find_user_by_email_loop.body; i5h_step

@[step] theorem find_article_spec (v : alloc.vec.Vec Article) (slug : Text) :
    find_article v slug ⦃ o => o = v.val.find? (·.slug = slug) ⦄ := by
  unfold find_article find_article_loop
  apply WP.spec_mono (loop_search v.val (fun x => decide (x.slug = slug)) (fun o : Option Article => o)
    (fun _ x => some x) none _ ?_ 0#usize (by simp))
  · intro r hr; exact search_find _ _ _ hr
  · intro j hj; unfold find_article_loop.body; i5h_step

@[step] theorem find_comment_spec (v : alloc.vec.Vec Comment) (id : U64) :
    find_comment v id ⦃ o => o = v.val.find? (·.id = id) ⦄ := by
  unfold find_comment find_comment_loop
  apply WP.spec_mono (loop_search v.val (fun x => decide (x.id = id)) (fun o : Option Comment => o)
    (fun _ x => some x) none _ ?_ 0#usize (by simp))
  · intro r hr; exact search_find _ _ _ hr
  · intro j hj; unfold find_comment_loop.body; i5h_step

@[step] theorem is_following_spec (fs : alloc.vec.Vec Follow) (u v : U64) :
    is_following fs u v ⦃ b => b = fs.val.any (fun f => f.follower = u ∧ f.followed = v) ⦄ := by
  unfold is_following is_following_loop
  apply WP.spec_mono (loop_search fs.val (fun f => decide (f.follower = u ∧ f.followed = v)) (fun b : Bool => b)
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr; exact search_bool _ _ _ hr
  · intro j hj; unfold is_following_loop.body; i5h_step

@[step] theorem is_favorited_spec (fs : alloc.vec.Vec Favorite) (a u : U64) :
    is_favorited fs a u ⦃ b => b = fs.val.any (fun f => f.article = a ∧ f.user = u) ⦄ := by
  unfold is_favorited is_favorited_loop
  apply WP.spec_mono (loop_search fs.val (fun f => decide (f.article = a ∧ f.user = u)) (fun b : Bool => b)
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr; exact search_bool _ _ _ hr
  · intro j hj; unfold is_favorited_loop.body; i5h_step

@[step] theorem has_favorite_spec (fs : alloc.vec.Vec Favorite) (u : U64) :
    has_favorite fs u ⦃ b => b = fs.val.any (fun f => f.user = u) ⦄ := by
  unfold has_favorite has_favorite_loop
  apply WP.spec_mono (loop_search fs.val (fun f => decide (f.user = u)) (fun b : Bool => b)
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr; exact search_bool _ _ _ hr
  · intro j hj; unfold has_favorite_loop.body; i5h_step

@[step] theorem has_favorite_except_spec (fs : alloc.vec.Vec Favorite) (u a : U64) :
    has_favorite_except fs u a ⦃ b => b = fs.val.any (fun f => f.user = u ∧ f.article ≠ a) ⦄ := by
  unfold has_favorite_except has_favorite_except_loop
  apply WP.spec_mono (loop_search fs.val (fun f => decide (f.user = u ∧ f.article ≠ a)) (fun b : Bool => b)
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr; exact search_bool _ _ _ hr
  · intro j hj; unfold has_favorite_except_loop.body; i5h_step

@[step] theorem has_tag_spec (ts : alloc.vec.Vec Tag) (a : U64) (t : Text) :
    has_tag ts a t ⦃ b => b = ts.val.any (fun x => x.article = a ∧ x.tag = t) ⦄ := by
  unfold has_tag has_tag_loop
  apply WP.spec_mono (loop_search ts.val (fun x => decide (x.article = a ∧ x.tag = t)) (fun b : Bool => b)
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr; exact search_bool _ _ _ hr
  · intro j hj; unfold has_tag_loop.body; i5h_step

@[step] theorem contains_text_spec (v : alloc.vec.Vec Text) (t : Text) :
    contains_text v t ⦃ b => b = v.val.any (· = t) ⦄ := by
  unfold contains_text contains_text_loop
  apply WP.spec_mono (loop_search v.val (fun x => decide (x = t)) (fun b : Bool => b)
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr; exact search_bool _ _ _ hr
  · intro j hj; unfold contains_text_loop.body; i5h_step

theorem find_user_by_name_eq (us : alloc.vec.Vec User) (n : Text) :
    find_user_by_name us n = ok (us.val.find? (·.username = n)) := eq_ok_of_spec (find_user_by_name_spec us n)
theorem find_user_by_email_eq (us : alloc.vec.Vec User) (e : Text) :
    find_user_by_email us e = ok (us.val.find? (·.email = e)) := eq_ok_of_spec (find_user_by_email_spec us e)
theorem find_article_eq (v : alloc.vec.Vec Article) (slug : Text) :
    find_article v slug = ok (v.val.find? (·.slug = slug)) := eq_ok_of_spec (find_article_spec v slug)
theorem find_user_eq (us : alloc.vec.Vec User) (id : U64) :
    find_user us id = ok (us.val.find? (·.id = id)) := eq_ok_of_spec (find_user_spec us id)
theorem find_comment_eq (v : alloc.vec.Vec Comment) (id : U64) :
    find_comment v id = ok (v.val.find? (·.id = id)) := eq_ok_of_spec (find_comment_spec v id)

/-! ## Folds -/

@[step] theorem fav_count_loop_spec (fs : alloc.vec.Vec Favorite) (a : U64) :
    fav_count_loop fs a 0#usize 0#usize ⦃ n => n.val = (fs.val.filter (·.article = a)).length ⦄ := by
  unfold fav_count_loop
  apply WP.spec_mono (loop_fold fs.val (fun n : Usize => n.val) (fun c x => c + if decide (x.article = a) then 1 else 0)
    (fun n j => n.val ≤ j) (fun x => fav_count_loop.body fs a x.1 x.2) ?_ 0#usize 0#usize (by simp) (by simp))
  · intro r hr; rw [hr, foldl_count]; simp
  · intro n j hj hn; have := fs.len_ineq; unfold fav_count_loop.body; i5h_step

@[step] theorem fav_count_spec (fs : alloc.vec.Vec Favorite) (a : U64) :
    fav_count fs a ⦃ n => n.val = (fs.val.filter (·.article = a)).length ⦄ := by
  unfold fav_count
  step*
  rw [usize_cast_u64]; exact ‹_›

@[step] theorem tags_of_spec (ts : alloc.vec.Vec Tag) (a : U64) :
    tags_of ts a ⦃ v => v.val = (ts.val.filter (·.article = a)).map (·.tag) ⦄ := by
  unfold tags_of tags_of_loop
  apply WP.spec_mono (loop_fold ts.val (fun w : alloc.vec.Vec Text => w.val)
    (fun acc x => if decide (x.article = a) then acc ++ [x.tag] else acc)
    (fun w j => w.length ≤ j) (fun x => tags_of_loop.body ts a x.1 x.2) ?_ _ 0#usize (by simp) (by simp))
  · intro r hr; rw [hr, foldl_filter_map]; simp
  · intro o j hj ho; have := ts.len_ineq; unfold tags_of_loop.body; i5h_step

@[step] theorem dedup_spec (v : alloc.vec.Vec Text) :
    dedup v ⦃ w => w.val = distinct v.val ⦄ := by
  unfold dedup dedup_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec Text => w.val)
    (fun acc x => if acc.any (· = x) then acc else acc ++ [x])
    (fun w j => w.length ≤ j) (fun x => dedup_loop.body v x.1 x.2) ?_ _ 0#usize (by simp) (by simp))
  · intro r hr; rw [hr]; simp only [distinct, List.drop_zero, UScalar.ofNatCore_val_eq]; rfl
  · intro o j hj ho; have := v.len_ineq; unfold dedup_loop.body; i5h_step
    exact ⟨by scalar_tac, fun hm => b_post _ hm rfl⟩

@[step] theorem all_tags_spec (ts : alloc.vec.Vec Tag) :
    all_tags ts ⦃ w => w.val = distinct (ts.val.map (·.tag)) ⦄ := by
  unfold all_tags all_tags_loop
  apply WP.spec_mono (loop_fold ts.val (fun w : alloc.vec.Vec Text => w.val)
    (fun acc x => if acc.any (· = x.tag) then acc else acc ++ [x.tag])
    (fun w j => w.length ≤ j) (fun x => all_tags_loop.body ts x.1 x.2) ?_ _ 0#usize (by simp) (by simp))
  · intro r hr; rw [hr]; simp only [distinct, List.foldl_map, List.drop_zero, UScalar.ofNatCore_val_eq]; rfl
  · intro o j hj ho; have := ts.len_ineq; unfold all_tags_loop.body; i5h_step
    exact ⟨by scalar_tac, fun hm => b_post _ hm rfl⟩

/-! ## Views -/

@[step] theorem profile_spec (s : Snapshot) (viewer : U64) (x : User) :
    profile s viewer x ⦃ p => p = profileOf (Snapshot.toSt s) viewer x ⦄ := by
  unfold profile; step*; simp_all [profileOf, follows, Snapshot.toSt]

@[step] theorem author_profile_spec (s : Snapshot) (viewer id : U64) :
    author_profile s viewer id ⦃ p => p = authorOf (Snapshot.toSt s) viewer id ⦄ := by
  unfold author_profile; step*
  · simp only [authorOf, userById, Snapshot.toSt]; rw [← o_post, ‹o = none›]; rfl
  · simp only [authorOf, userById, Snapshot.toSt]; rw [← o_post, ‹o = some _›]; exact ‹_ = profileOf _ _ _›

@[step] theorem favorited_flag_spec (fs : alloc.vec.Vec Favorite) (a u : U64) (up : Bool) :
    favorited_flag fs a u up ⦃ b => b = if up then fs.val.any (fun f => f.user = u)
      else fs.val.any (fun f => f.article = a ∧ f.user = u) ⦄ := by
  unfold favorited_flag; split <;> step* <;> simp_all

@[step] theorem article_view_spec (s : Snapshot) (u : U64) (a : Article) (up : Bool) :
    article_view s u a up ⦃ v => v.toView = viewWith up (Snapshot.toSt s) u a ⦄ := by
  unfold article_view; step*
  simp_all [ArticleView.toView, viewWith, favFlag, favorited, favoritedUpstream, favCount, tagsOf, Snapshot.toSt]

@[step] theorem views_spec (s : Snapshot) (u : U64) (v : alloc.vec.Vec Article) (up : Bool) :
    views s u v up ⦃ w => w.val.map ArticleView.toView = v.val.map (viewWith up (Snapshot.toSt s) u) ⦄ := by
  unfold views views_loop
  apply WP.spec_mono (loop_fold v.val (fun w : alloc.vec.Vec ArticleView => w.val.map ArticleView.toView)
    (fun acc x => acc ++ [viewWith up (Snapshot.toSt s) u x])
    (fun w j => w.length ≤ j) (fun x => views_loop.body s u v up x.1 x.2) ?_ _ 0#usize (by simp) (by simp))
  · intro r hr; rw [hr, foldl_map_acc]; simp
  · intro o j hj ho; have := v.len_ineq; unfold views_loop.body; i5h_step

@[step] theorem comment_views_spec (s : Snapshot) (u a : U64) :
    comment_views s u a ⦃ w => w.val = commentsOf (Snapshot.toSt s) u a ⦄ := by
  unfold comment_views comment_views_loop
  apply WP.spec_mono (loop_fold s.comments.val (fun w : alloc.vec.Vec CommentView => w.val)
    (fun acc x => if decide (x.article = a) then acc ++ [⟨x, authorOf (Snapshot.toSt s) u x.author⟩] else acc)
    (fun w j => w.length ≤ j) (fun x => comment_views_loop.body s u a x.1 x.2) ?_ _ 0#usize (by simp) (by simp))
  · intro r hr; rw [hr, foldl_filter_map (f := fun x => (⟨x, authorOf (Snapshot.toSt s) u x.author⟩ : CommentView))]
    simp [commentsOf, Snapshot.toSt]
  · intro o j hj ho; have := s.comments.len_ineq; unfold comment_views_loop.body; i5h_step

/-! ## Listing -/

@[step] theorem matches_spec (s : Snapshot) (a : Article) (tag : Option Text) (author fav : Option U64) (up : Bool) :
    «matches» s a tag author fav up ⦃ b => b = listedWith up (Snapshot.toSt s) tag author fav a ⦄ := by
  unfold «matches»
  cases tag <;> cases author <;> cases fav <;> step* <;>
    simp_all [listedWith, favFlag, favorited, favoritedUpstream, Snapshot.toSt]

@[step] theorem select_spec (s : Snapshot) (tag : Option Text) (author fav : Option U64) (up : Bool) :
    select s tag author fav up ⦃ w => w.val = s.articles.val.filter (listedWith up (Snapshot.toSt s) tag author fav) ⦄ := by
  unfold select select_loop
  apply WP.spec_mono (loop_fold s.articles.val (fun w : alloc.vec.Vec Article => w.val)
    (fun acc x => if listedWith up (Snapshot.toSt s) tag author fav x then acc ++ [x] else acc)
    (fun w j => w.length ≤ j) (fun x => select_loop.body s tag author fav up x.1 x.2) ?_ _ 0#usize (by simp) (by simp))
  · intro r hr; rw [hr, foldl_filter]; simp
  · intro o j hj ho; have := s.articles.len_ineq; unfold select_loop.body; i5h_step

@[step] theorem feed_select_spec (s : Snapshot) (u : U64) :
    feed_select s u ⦃ w => w.val = s.articles.val.filter (fun a => follows (Snapshot.toSt s) u a.author) ⦄ := by
  unfold feed_select feed_select_loop
  apply WP.spec_mono (loop_fold s.articles.val (fun w : alloc.vec.Vec Article => w.val)
    (fun acc x => if follows (Snapshot.toSt s) u x.author then acc ++ [x] else acc)
    (fun w j => w.length ≤ j) (fun x => feed_select_loop.body s u x.1 x.2) ?_ _ 0#usize (by simp) (by simp))
  · intro r hr; rw [hr, foldl_filter]; simp
  · intro o j hj ho; have := s.articles.len_ineq; unfold feed_select_loop.body; i5h_step <;>
      simp_all [follows, Snapshot.toSt] <;> scalar_tac

theorem getElem_page (v : List Article) (off lim j : Nat) (h : j < ((v.reverse.drop off).take lim).length) :
    ((v.reverse.drop off).take lim)[j] = v[v.length - off - 1 - j]'(by simp at h; omega) := by
  simp only [List.getElem_take, List.getElem_drop, List.getElem_reverse]
  congr 1; simp at h; omega

theorem foldl_snoc {α} (l acc : List α) : l.foldl (fun acc x => acc ++ [x]) acc = acc ++ l := by
  induction l generalizing acc with
  | nil => simp
  | cons y ys ih => rw [List.foldl_cons, ih]; simp

theorem page_loop_spec (v : alloc.vec.Vec Article) (lim : U64) (start : Usize) (off : Nat)
    (hs : off + start.val = v.length) :
    page_loop v lim (alloc.vec.Vec.new Article) start 0#usize ⦃ w => w.val = pageOf v.val off lim.val ⦄ := by
  have hlen : ((v.val.reverse.drop off).take lim.val).length = min start.val lim.val := by
    simp [alloc.vec.Vec.length] at hs ⊢; omega
  unfold page_loop
  apply WP.spec_mono (loop_fold ((v.val.reverse.drop off).take lim.val) (fun w : alloc.vec.Vec Article => w.val)
    (fun acc x => acc ++ [x]) (fun w j => w.length ≤ j)
    (fun x => page_loop.body v lim start x.1 x.2) ?_ _ 0#usize (by simp) (by simp))
  · intro r hr; rw [hr, foldl_snoc]; simp [pageOf]
  · intro o j hj ho
    have := v.len_ineq
    unfold page_loop.body
    step*
    · have hi : i.val = j.val := by simp [i_post]
      have hjl : j.val < ((v.val.reverse.drop off).take lim.val).length := by rw [hlen]; scalar_tac
      refine ⟨hjl, ?_, j1_post, ?_⟩
      · simp only [out1_post, a1_post, a_post]
        rw [getElem_page _ _ _ _ hjl]
        congr 2; simp [alloc.vec.Vec.length] at hs
        have hidx : i2.val = v.val.length - off - 1 - j.val := by omega
        simp only [hidx]
      · simp only [alloc.vec.Vec.length] at *; simp [out1_post, j1_post]; omega
    · have hi : i.val = j.val := by simp [i_post]
      simp only [FoldStep, and_true]; rw [hlen]; scalar_tac
    · simp only [FoldStep, and_true]; rw [hlen]; scalar_tac

theorem u64_cast_usize (x : U64) (h : x.val ≤ Usize.max) : (UScalar.cast .Usize x).val = x.val := by
  rw [UScalar.cast_val_eq]; apply Nat.mod_eq_of_lt
  have h2 : Usize.max < 2 ^ UScalarTy.Usize.numBits := by
    rw [Usize.max_def, Usize.numBits_def]; exact Nat.sub_lt (Nat.two_pow_pos _) Nat.one_pos
  omega

@[step] theorem page_spec (v : alloc.vec.Vec Article) (off lim : U64) :
    page v off lim ⦃ w => w.val = pageOf v.val off.val lim.val ⦄ := by
  unfold page
  have := v.len_ineq; have := usize_max_le
  step*
  · have : v.val.reverse.length ≤ off.val := by simp_all [alloc.vec.Vec.length] <;> scalar_tac
    simp [pageOf, List.drop_eq_nil_of_le this]
  · have : off.val ≤ Usize.max := by simp_all [alloc.vec.Vec.length] <;> scalar_tac
    rw [i1_post, u64_cast_usize _ this]; simp_all [alloc.vec.Vec.length] <;> omega
  · have : off.val ≤ Usize.max := by simp_all [alloc.vec.Vec.length] <;> scalar_tac
    apply page_loop_spec
    rw [start_post, i1_post, u64_cast_usize _ this]; simp_all [alloc.vec.Vec.length] <;> scalar_tac

@[step] theorem tag_writes_spec (ws : alloc.vec.Vec Write) (a : U64) (tags : alloc.vec.Vec Text)
    (h : ws.length + tags.length ≤ Usize.max) :
    tag_writes ws a tags ⦃ w => w.val = ws.val ++ tags.val.map (fun t => .PutTag ⟨a, t⟩) ⦄ := by
  unfold tag_writes tag_writes_loop
  apply WP.spec_mono (loop_fold tags.val (fun w : alloc.vec.Vec Write => w.val)
    (fun acc t => acc ++ [.PutTag ⟨a, t⟩]) (fun w j => w.length ≤ ws.length + j)
    (fun x => tag_writes_loop.body a tags x.1 x.2) ?_ _ 0#usize (by simp) (by simp))
  · intro r hr; rw [hr, foldl_map_acc]; simp
  · intro o j hj ho; unfold tag_writes_loop.body; i5h_step

/-! ## Small helpers -/

@[step] theorem resolve_spec (us : alloc.vec.Vec User) (n : Option Text) :
    resolve us n ⦃ o => o = match n with
      | none => some none
      | some n => (us.val.find? (·.username = n)).map (fun x => some x.id) ⦄ := by
  unfold resolve; cases n with
  | none => simp
  | some n => simp only [find_user_by_name_eq, bind_ok]; split <;> rename_i h <;> simp [h]

@[step] theorem name_taken_spec (us : alloc.vec.Vec User) (n : Option Text) (me : U64) :
    name_taken us n me ⦃ b => b = ((n.bind fun n => us.val.find? (·.username = n)).any (·.id ≠ me)) ⦄ := by
  unfold name_taken; cases n with
  | none => simp
  | some n => simp only [find_user_by_name_eq, bind_ok]; split <;> rename_i h <;> simp [h]

@[step] theorem email_taken_spec (us : alloc.vec.Vec User) (e : Option Text) (me : U64) :
    email_taken us e me ⦃ b => b = ((e.bind fun e => us.val.find? (·.email = e)).any (·.id ≠ me)) ⦄ := by
  unfold email_taken; cases e with
  | none => simp
  | some n => simp only [find_user_by_email_eq, bind_ok]; split <;> rename_i h <;> simp [h]

@[step] theorem slug_taken_spec (v : alloc.vec.Vec Article) (n : Option Text) (id : U64) :
    slug_taken v n id ⦃ b => b = ((n.bind fun n => v.val.find? (·.slug = n)).any (·.id ≠ id)) ⦄ := by
  unfold slug_taken; cases n with
  | none => simp
  | some n => simp only [find_article_eq, bind_ok]; split <;> rename_i h <;> simp [h]

@[step] theorem or_keep_spec (n : Option Text) (old : Text) : or_keep n old ⦃ t => t = n.getD old ⦄ := by
  unfold or_keep; cases n <;> step* <;> simp_all

@[step] theorem account_spec (x : User) : account x ⦃ r => r = ⟨x.id, x.email, x.username, x.bio, x.image⟩ ⦄ := by
  unfold account; step*

@[step] theorem dec_if_spec (b : Bool) (n : U64) : dec_if b n ⦃ m => m.val = if b then n.val - 1 else n.val ⦄ := by
  unfold dec_if; split <;> step* <;> simp_all <;> scalar_tac

@[step] theorem unfavorited_flag_spec (fs : alloc.vec.Vec Favorite) (a u : U64) (up : Bool) :
    unfavorited_flag fs a u up ⦃ b => b = (up && fs.val.any (fun f => f.user = u ∧ f.article ≠ a)) ⦄ := by
  unfold unfavorited_flag; split <;> step* <;> simp_all

end conduit_kernel.Helpers
