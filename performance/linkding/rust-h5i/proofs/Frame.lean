import Plan
/-!
# Frame theorem: the read plans load enough

`frame`: for every command, `transition` on `Snapshot.load (readsA a c) s`
(what the server loads, `Schema.decode_load`) accepts with the same writes
and reply as on the whole site `s`. It uses what the database's primary keys
guarantee (`Keys`): token keys, user ids and bundle ids are unique, and no
user has id 0 (the guest).

Each command's plan keeps, of every table it reads, all rows a lookup of the
kernel can return (`H5iAppLib.Query.find?_slice`, `any_slice`), and every
row a loop over a table acts on (`Plan.foldlM_filter`); a paged listing loads
only the newest `offset + limit` bookmarks its read selects, which hold the
page (`H5iAppLib.Query.page_of_newest`), and the tag list the first
`offset + limit` of the caller's tags.
-/
open Classical Aeneas Aeneas.Std Result linkding_kernel linkding_kernel.Schema linkding_kernel.Helpers linkding_kernel.Plan
  H5iAppLib H5iAppLib.Query

namespace linkding_kernel.Frame

/-- What the primary keys guarantee: token keys, user ids and bundle ids are
unique. User ids start at 1; 0 is the guest. -/
structure Keys (s : Snapshot) : Prop where
  tokens : (s.tokens.val.map (·.key)).Nodup
  users : (s.users.val.map (·.id)).Nodup
  user_pos : ∀ u ∈ s.users.val, u.id ≠ 0#u64
  bundles : (s.bundles.val.map (·.id)).Nodup

/-! ## Predicates on encoded rows -/

@[simp] theorem holds_eq (tabs : H5iAppLib.Sql.Tables Val) (c : Nat) (v : Val) (r : List Val) :
    (Pred.eq c v).holds tabs r = decide (r[c]? = some v) := rfl

@[simp] theorem holds_all (tabs : H5iAppLib.Sql.Tables Val) (r : List Val) :
    (Pred.all : Pred Val).holds tabs r = true := rfl

@[simp] theorem holds_or (tabs : H5iAppLib.Sql.Tables Val) (p q : Pred Val) (r : List Val) :
    (Pred.or p q).holds tabs r = (p.holds tabs r || q.holds tabs r) := rfl

@[simp] theorem holds_and (tabs : H5iAppLib.Sql.Tables Val) (p q : Pred Val) (r : List Val) :
    (Pred.and p q).holds tabs r = (p.holds tabs r && q.holds tabs r) := rfl

/-- Unfolds the predicates of a plan on encoded rows. -/
macro "holds_simp" : tactic => `(tactic| simp [mineA, eqU, eqB, eqT, urlA, byIdA, scopeA, sharedA, taggedA,
  holds_in_0, holds_in_1, holds_in_2, holds_in_3, holds_in_4, holds_in_5, User.row, Token.row, Bookmark.row,
  Tag.row, Link.row, Bundle.row, int_u64])

/-- `mineA c t` on a row whose column `c` is user `x`: a token `t` names `x`. -/
theorem mine_holds (s : Snapshot) (t : Text) (x : U64) (r : List Val) (c : Nat) (h : r[c]? = some (int x.val)) :
    (mineA c t).holds (Snapshot.enc s) r = decide (∃ k ∈ s.tokens.val, k.key = t ∧ k.user = x) := by
  simp only [mineA, holds_in_1, h]
  simp [eqB, Token.row, int_u64]
  apply Bool.eq_iff_iff.2
  simp

/-! ## The caller -/

theorem actorOf_ok {s : Snapshot} {t : Text} {u : U64} (h : actorOf s t = .Ok u) (hu : u ≠ 0#u64) :
    ∃ k ∈ s.tokens.val, k.key = t ∧ k.user = u := by
  unfold actorOf at h
  split at h
  · simp at h; exact absurd h.symm hu
  · unfold tokenOf at h
    cases hk : s.tokens.val.find? (·.key = t) with
    | none => simp [hk] at h
    | some k =>
      simp only [hk, Option.map_some, Option.getD_some] at h
      split at h
      · simp only [core.result.Result.Ok.injEq] at h
        obtain ⟨hm, hp⟩ := find?_mem hk
        exact ⟨k, hm, by simpa using hp, h⟩
      · simp at h

section Caller
variable {s s' : Snapshot} {t : Text} {Kt : Token → Bool} {Ku : User → Bool}
  (htok : s'.tokens.val = s.tokens.val.filter Kt) (hkt : ∀ k ∈ s.tokens.val, k.key = t → Kt k)
  (husr : s'.users.val = s.users.val.filter Ku)
  (hku : ∀ x ∈ s.users.val, (∃ k ∈ s.tokens.val, k.key = t ∧ k.user = x.id) → Ku x)
include htok hkt husr hku

theorem actorOf_slice : actorOf s' t = actorOf s t := by
  unfold actorOf tokenOf
  split
  · rfl
  · rw [htok, find?_slice _ _ _ (fun k hk hp => hkt k hk (by simpa using hp))]
    cases hk : s.tokens.val.find? (·.key = t) with
    | none => rfl
    | some k =>
      obtain ⟨hm, hp⟩ := find?_mem hk
      simp only [Option.map_some, Option.getD_some]
      rw [husr, find?_slice _ _ _ (fun x hx hp' => hku x hx ⟨k, hm, by simpa using hp, (by simpa using hp' : x.id = k.user).symm⟩)]

theorem actor_slice : actor s' t = actor s t := by
  rw [eq_ok_of_spec (actor_spec s' t), eq_ok_of_spec (actor_spec s t), actorOf_slice htok hkt husr hku]

theorem signed_in_slice : signed_in s' t = signed_in s t := by
  unfold signed_in
  rw [actor_slice htok hkt husr hku, eq_ok_of_spec (actor_spec s t)]
  simp only [bind_tc_ok, bind_ok]
  cases ha : actorOf s t with
  | Err e => rfl
  | Ok u =>
    by_cases h0 : u = 0#u64
    · simp [h0]
    · simp only [h0, if_false]
      obtain ⟨k, hk, h1, h2⟩ := actorOf_ok ha h0
      rw [eq_ok_of_spec (find_user_spec _ _), eq_ok_of_spec (find_user_spec _ _), husr,
        find?_slice _ _ _ (fun x hx hp => hku x hx ⟨k, hk, h1, by rw [h2]; exact (by simpa using hp : x.id = u).symm⟩)]

end Caller

/-- `signed_in`, as a value. -/
def signedOf (s : Snapshot) (t : Text) : core.result.Result User Error :=
  match actorOf s t with
  | .Err e => .Err e
  | .Ok u => if u = 0#u64 then .Err .Unauthenticated else
    match s.users.val.find? (·.id = u) with
    | none => .Err .BadToken
    | some me => .Ok me

theorem signed_in_eq (s : Snapshot) (t : Text) : signed_in s t = ok (signedOf s t) := by
  unfold signed_in signedOf
  rw [eq_ok_of_spec (actor_spec s t)]
  simp only [bind_ok]
  cases actorOf s t with
  | Err e => rfl
  | Ok u =>
    simp only []
    split
    · rfl
    · rw [eq_ok_of_spec (find_user_spec _ _)]
      simp only [bind_ok]
      cases s.users.val.find? (fun x => decide (x.id = u)) <;> rfl

theorem signedOf_ok {s : Snapshot} {t : Text} {me : User} (h : signedOf s t = .Ok me) :
    actorOf s t = .Ok me.id ∧ me ∈ s.users.val ∧ me.id ≠ 0#u64 := by
  have := signed_in_ok s t me (by rw [signed_in_eq, h])
  refine ⟨this.1, this.2, ?_⟩
  unfold signedOf at h
  rw [this.1] at h
  intro h0; simp [h0] at h

/-- With unique token keys, `mineA` names the caller and nobody else. -/
theorem mine_iff {s : Snapshot} (hk : Keys s) {t : Text} {u : U64} (ha : actorOf s t = .Ok u) (hu : u ≠ 0#u64)
    (x : U64) : (∃ k ∈ s.tokens.val, k.key = t ∧ k.user = x) ↔ x = u := by
  obtain ⟨k0, hk0, h1, h2⟩ := actorOf_ok ha hu
  constructor
  · rintro ⟨k, hk', h3, h4⟩
    have : k = k0 := List.inj_on_of_nodup_map hk.tokens hk' hk0 (h3.trans h1.symm)
    subst this; rw [← h4, h2]
  · rintro rfl; exact ⟨k0, hk0, h1, h2⟩

theorem mine_holds_iff {s : Snapshot} (hk : Keys s) {t : Text} {u : U64} (ha : actorOf s t = .Ok u) (hu : u ≠ 0#u64)
    (x : U64) (r : List Val) (c : Nat) (h : r[c]? = some (int x.val)) :
    (mineA c t).holds (Snapshot.enc s) r = decide (x = u) := by
  rw [mine_holds s t x r c h]; exact decide_eq_decide.2 (mine_iff hk ha hu x)

theorem caller_gen (s : Snapshot) (t : Text) (P : Pred Val) (plan : List (Read Val))
    (htok : (Snapshot.load plan s).tokens.val = s.tokens.val.filter (fun k => (eqB 0 t).holds (Snapshot.enc s) (Token.row k)))
    (husr : (Snapshot.load plan s).users.val = s.users.val.filter (fun x => P.holds (Snapshot.enc s) (User.row x)))
    (hP : ∀ x, (mineA 0 t).holds (Snapshot.enc s) (User.row x) → P.holds (Snapshot.enc s) (User.row x)) :
    actor (Snapshot.load plan s) t = actor s t ∧ signed_in (Snapshot.load plan s) t = signed_in s t := by
  have hkt : ∀ k ∈ s.tokens.val, k.key = t → (eqB 0 t).holds (Snapshot.enc s) (Token.row k) := by
    intro k _ hk; simp [eqB, Token.row, hk]
  have hku : ∀ x ∈ s.users.val, (∃ k ∈ s.tokens.val, k.key = t ∧ k.user = x.id) →
      P.holds (Snapshot.enc s) (User.row x) := by
    intro x _ hx
    apply hP
    rw [mine_holds s t x.id _ 0 (by simp [User.row])]; simpa using hx
  exact ⟨actor_slice htok hkt husr hku, signed_in_slice htok hkt husr hku⟩

/-- A plan that starts with the caller's reads loads the caller. -/
theorem caller_slice (s : Snapshot) (t : Text) (rest : List (Read Val)) :
    actor (Snapshot.load (callerA t ++ rest) s) t = actor s t ∧
      signed_in (Snapshot.load (callerA t ++ rest) s) t = signed_in s t :=
  caller_gen s t (mineA 0 t) _ (by simp [pickRows, callerA]) (by simp [pickRows, callerA]) (fun _ h => h)

theorem caller_and_slice (s : Snapshot) (t : Text) (e : Pred Val) (rest : List (Read Val)) :
    actor (Snapshot.load (callerAndA t e ++ rest) s) t = actor s t ∧
      signed_in (Snapshot.load (callerAndA t e ++ rest) s) t = signed_in s t :=
  caller_gen s t (.or (mineA 0 t) e) _ (by simp [pickRows, callerAndA]) (by simp [pickRows, callerAndA])
    (fun _ h => by simp [h])

/-! ## Lookups on a slice -/

section Lookups
variable {s s' : Snapshot}

theorem own_bookmark_slice {K : Bookmark → Bool} (h : s'.bookmarks.val = s.bookmarks.val.filter K) (id : U64)
    (hk : ∀ x ∈ s.bookmarks.val, x.id = id → K x) (me : User) : own_bookmark s' me id = own_bookmark s me id := by
  unfold own_bookmark
  rw [eq_ok_of_spec (find_bookmark_spec _ _), eq_ok_of_spec (find_bookmark_spec _ _), h,
    find?_slice _ _ _ (fun x hx hp => hk x hx (by simpa using hp))]

theorem own_bookmark_eq (s : Snapshot) (me : User) (id : U64) :
    own_bookmark s me id = ok (match s.bookmarks.val.find? (·.id = id) with
      | none => .Err .NotFound
      | some b => if b.owner = me.id then .Ok b else .Err .NotFound) := by
  unfold own_bookmark
  rw [eq_ok_of_spec (find_bookmark_spec _ _)]
  simp only [bind_ok]
  cases s.bookmarks.val.find? (fun x => decide (x.id = id)) with
  | none => rfl
  | some b => simp only []; split <;> rfl

theorem own_tag_slice {K : Tag → Bool} (h : s'.tags.val = s.tags.val.filter K) (id : U64)
    (hk : ∀ x ∈ s.tags.val, x.id = id → K x) (me : User) : own_tag s' me id = own_tag s me id := by
  unfold own_tag
  rw [eq_ok_of_spec (find_tag_spec _ _), eq_ok_of_spec (find_tag_spec _ _), h,
    find?_slice _ _ _ (fun x hx hp => hk x hx (by simpa using hp))]

/-- `tag_names`' step over the links. -/
def tnStep (s : Snapshot) (id : U64) (out : alloc.vec.Vec Text) (l : Link) : Result (alloc.vec.Vec Text) :=
  if l.bookmark = id then (do
    let o ← find_tag s.tags l.tag
    match o with
    | none => ok out
    | some t => do let v ← alloc.vec.CloneVec.clone core.clone.CloneU8 t.name; out.push v)
  else ok out

theorem tag_names_eq (s : Snapshot) (id : U64) :
    tag_names s id = (do let a ← (s.links.val.foldlM (tnStep s id) (alloc.vec.Vec.new Text)); ok a) := by
  unfold tag_names tag_names_loop
  have := loop_foldlM s.links.val s.links.len_ineq (tnStep s id) (fun x => x) (fun a i => (a, i))
    (fun x => tag_names_loop.body s id x.1 x.2) ?_ (alloc.vec.Vec.new Text) 0#usize (by simp)
  · simpa using this
  · intro a i hi
    unfold tag_names_loop.body tnStep
    body_shape s.links

theorem tag_names_slice {KL : Link → Bool} {KT : Tag → Bool} (hl : s'.links.val = s.links.val.filter KL)
    (ht : s'.tags.val = s.tags.val.filter KT) (id : U64)
    (hkl : ∀ l ∈ s.links.val, l.bookmark = id → KL l)
    (hkt : ∀ l ∈ s.links.val, l.bookmark = id → ∀ x ∈ s.tags.val, x.id = l.tag → KT x) :
    tag_names s' id = tag_names s id := by
  rw [tag_names_eq, tag_names_eq, hl, foldlM_slice _ _ (tnStep s id) (tnStep s' id)]
  · intro l hm hk a
    have : ¬ l.bookmark = id := fun h => by simp [hkl l hm h] at hk
    simp [tnStep, this]
  · intro l hm _ a
    unfold tnStep
    split
    · rename_i hb
      rw [eq_ok_of_spec (find_tag_spec _ _), eq_ok_of_spec (find_tag_spec _ _), ht,
        find?_slice _ _ _ (fun x hx hp => hkt l hm hb x hx (by simpa using hp))]
    · rfl

theorem view_slice {KL : Link → Bool} {KT : Tag → Bool} (hl : s'.links.val = s.links.val.filter KL)
    (ht : s'.tags.val = s.tags.val.filter KT) (b : Bookmark)
    (hkl : ∀ l ∈ s.links.val, l.bookmark = b.id → KL l)
    (hkt : ∀ l ∈ s.links.val, l.bookmark = b.id → ∀ x ∈ s.tags.val, x.id = l.tag → KT x) :
    view s' b = view s b := by
  unfold view
  rw [tag_names_slice hl ht b.id hkl hkt]

/-- In a list with unique ids, the first row of id `i` among those `P`
keeps is the first of id `i`, if `P` keeps it. -/
theorem find_filter_unique {α : Type} (l : List α) (key : α → U64) (P : α → Bool) (i : U64)
    (hnd : (l.map key).Nodup) :
    (l.filter P).find? (fun x => decide (key x = i)) =
      match l.find? (fun x => decide (key x = i)) with
      | none => none
      | some b => if P b then some b else none := by
  induction l with
  | nil => rfl
  | cons x xs ih =>
    simp only [List.map_cons, List.nodup_cons] at hnd
    by_cases hq : key x = i
    · have hnone : (xs.filter P).find? (fun x => decide (key x = i)) = none := by
        rw [List.find?_eq_none]; intro y hy
        have := (List.mem_filter.1 hy).1
        simp only [decide_eq_true_eq]; intro hy'
        exact hnd.1 (by rw [List.mem_map]; exact ⟨y, this, hy'.trans hq.symm⟩)
      by_cases hp : P x = true
      · simp [List.filter_cons, hp, hq]
      · simp only [Bool.not_eq_true] at hp
        simp [List.filter_cons, hp, hq, hnone]
    · rw [List.filter_cons]
      split <;> simp [hq, ih hnd.2]

theorem own_bundle_slice {K : Bundle → Bool} (h : s'.bundles.val = s.bundles.val.filter K) (me : User)
    (hK : ∀ x ∈ s.bundles.val, K x = decide (x.owner = me.id)) (hnd : (s.bundles.val.map (·.id)).Nodup)
    (id : U64) : own_bundle s' me id = own_bundle s me id := by
  unfold own_bundle
  rw [eq_ok_of_spec (find_bundle_spec _ _), eq_ok_of_spec (find_bundle_spec _ _), h,
    List.filter_congr (fun x hx => hK x hx), find_filter_unique _ Bundle.id _ id hnd]
  simp only [bind_ok]
  cases hf : s.bundles.val.find? (fun x => decide (x.id = id)) with
  | none => rfl
  | some b => by_cases ho : b.owner = me.id <;> simp [ho]

theorem bundles_of_eq (s : Snapshot) (owner : U64) :
    bundles_of s owner = (do let a ← (s.bundles.val.foldlM
      (fun out b => if b.owner = owner then insert_bundle out b else ok out) (alloc.vec.Vec.new Bundle)); ok a) := by
  unfold bundles_of bundles_of_loop
  have := loop_foldlM s.bundles.val s.bundles.len_ineq
    (fun out b => if b.owner = owner then insert_bundle out b else ok out) (fun x => x) (fun a i => (a, i))
    (fun x => bundles_of_loop.body s owner x.1 x.2) ?_ (alloc.vec.Vec.new Bundle) 0#usize (by simp)
  · simpa using this
  · intro a i hi
    unfold bundles_of_loop.body
    body_shape s.bundles

theorem bundles_of_slice {K : Bundle → Bool} (h : s'.bundles.val = s.bundles.val.filter K) (owner : U64)
    (hK : ∀ x ∈ s.bundles.val, x.owner = owner → K x) : bundles_of s' owner = bundles_of s owner := by
  rw [bundles_of_eq, bundles_of_eq, h, foldlM_slice]
  · intro x hm hk a
    have : ¬ x.owner = owner := fun e => by simp [hK x hm e] at hk
    simp [this]
  · intro _ _ _ _; rfl

/-- `same_url`. -/
def sameP (b : Bookmark) (owner : U64) (url norm : Text) : Bool :=
  decide (b.owner = owner) && (decide (b.url_norm = norm) || (decide (b.url_norm.val = []) && decide (b.url = url)))

theorem same_url_eq (b : Bookmark) (owner : U64) (url norm : Text) :
    same_url b owner url norm = ok (sameP b owner url norm) := by
  unfold same_url sameP
  by_cases ho : b.owner = owner
  · simp only [ho, if_true, decide_true, Bool.true_and]
    rw [eq_ok_of_spec (vec_u8_eq_spec _ _)]
    simp only [bind_tc_ok, bind_ok]
    by_cases hn : b.url_norm = norm
    · simp [hn]
    · have hl : (alloc.vec.Vec.len b.url_norm = 0#usize) ↔ b.url_norm.val = [] := by
        simp only [alloc.vec.Vec.len, alloc.vec.Vec.length]
        rw [usize_ofNatCore_eq_zero]; simp
      by_cases he : b.url_norm.val = []
      · simp only [hn, decide_false, if_false, Bool.false_or, he, decide_true, Bool.true_and]
        rw [if_pos (hl.2 he), eq_ok_of_spec (vec_u8_eq_spec _ _)]; rfl
      · simp only [hn, decide_false, if_false, Bool.false_or, he, Bool.false_and]
        rw [if_neg (mt hl.1 he)]; rfl
  · simp [ho]

@[step] theorem same_url_spec (b : Bookmark) (owner : U64) (url norm : Text) :
    same_url b owner url norm ⦃ r => r = sameP b owner url norm ⦄ := by
  rw [same_url_eq]; simp

theorem find_same_url_eq (s : Snapshot) (owner : U64) (url norm : Text) (id : U64) :
    find_same_url s owner url norm id = ok (s.bookmarks.val.find? (fun b => decide (b.id = id) && sameP b owner url norm)) := by
  apply eq_ok_of_spec
  unfold find_same_url find_same_url_loop
  apply WP.spec_mono (loop_search s.bookmarks.val (fun b => decide (b.id = id) && sameP b owner url norm)
    (fun o : Option Bookmark => o) (fun _ x => some x) none _ ?_ 0#usize (by simp))
  · intro r hr; exact search_find _ _ _ hr
  · intro j hj; unfold find_same_url_loop.body; h5i_step

/-- `existing`'s step over the bookmarks. -/
def exStep (owner : U64) (url norm : Text) (acc : Bool × U64) (b : Bookmark) : Result (Bool × U64) := do
  let hit ← same_url b owner url norm
  let better ← improves hit acc.1 b.id acc.2
  let best1 ← if better then ok b.id else ok acc.2
  let found1 ← if hit then ok true else ok acc.1
  ok (found1, best1)

theorem existing_eq (s : Snapshot) (owner : U64) (url norm : Text) :
    existing s owner url norm = (do
      let a ← (s.bookmarks.val.foldlM (exStep owner url norm) (false, 0#u64))
      if a.1 then find_same_url s owner url norm a.2 else ok none) := by
  unfold existing existing_loop
  have := loop_foldlM s.bookmarks.val s.bookmarks.len_ineq (exStep owner url norm)
    (fun a => (s.counter, s.users, s.tokens, s.bookmarks, s.tags, s.links, s.bundles, a.1, a.2))
    (fun a i => (a.1, a.2, i)) (fun x => existing_loop.body s owner url norm x.1 x.2.1 x.2.2) ?_
    (false, 0#u64) 0#usize (by simp)
  · simp only at this
    rw [this]
    simp only [Std.bind_assoc, bind_ok]
    rfl
  · intro a i hi
    unfold existing_loop.body exStep
    body_shape s.bookmarks

theorem existing_slice {K : Bookmark → Bool} (h : s'.bookmarks.val = s.bookmarks.val.filter K) (owner : U64)
    (url norm : Text) (hk : ∀ x ∈ s.bookmarks.val, sameP x owner url norm = true → K x) :
    existing s' owner url norm = existing s owner url norm := by
  rw [existing_eq, existing_eq, h, foldlM_slice _ _ (exStep owner url norm) (exStep owner url norm)]
  · congr 1; funext a
    split
    · simp only [find_same_url_eq, h]
      rw [find?_slice _ _ _ (fun x hx hp => hk x hx (by simp only [Bool.and_eq_true] at hp; exact hp.2))]
    · rfl
  · intro x hm hkx a
    have : sameP x owner url norm = false := by
      cases hs : sameP x owner url norm
      · rfl
      · simp [hk x hm hs] at hkx
    simp [exStep, same_url_eq, this, improves]
  · intro _ _ _ _; rfl

theorem existing_total (s : Snapshot) (owner : U64) (url norm : Text) : ∃ o, existing s owner url norm = ok o := by
  rw [existing_eq]
  obtain ⟨a, ha⟩ := foldlM_total (exStep owner url norm) (fun a x => by
    simp only [exStep, same_url_eq, improves, bind_ok]
    split_ifs <;> simp <;> split_ifs <;> simp) s.bookmarks.val (false, 0#u64)
  rw [ha]; simp only [bind_tc_ok, bind_ok]
  split
  · exact ⟨_, find_same_url_eq _ _ _ _ _⟩
  · exact ⟨_, rfl⟩

theorem existing_some {s : Snapshot} {owner : U64} {url norm : Text} {b : Bookmark}
    (h : existing s owner url norm = ok (some b)) : b ∈ s.bookmarks.val ∧ sameP b owner url norm = true := by
  rw [existing_eq] at h
  obtain ⟨a, -, h2⟩ := bind_tc_eq_ok.1 h
  split at h2
  · rw [find_same_url_eq] at h2
    simp only [ok.injEq] at h2
    obtain ⟨hm, hp⟩ := find?_mem h2
    simp only [Bool.and_eq_true] at hp
    exact ⟨hm, hp.2⟩
  · simp at h2

theorem url_taken_eq (s : Snapshot) (owner : U64) (url : Text) (id : U64) :
    url_taken s owner url id = ok (s.bookmarks.val.any (fun b => decide (b.owner = owner) && decide (b.url = url) &&
      decide (b.id ≠ id))) := by
  apply eq_ok_of_spec
  unfold url_taken url_taken_loop
  h5i_search_any s.bookmarks.val (fun b => decide (b.owner = owner) && decide (b.url = url) && decide (b.id ≠ id))

theorem find_tag_named_slice {K : Tag → Bool} (h : s'.tags.val = s.tags.val.filter K) (owner : U64) (lower : Text)
    (hk : ∀ x ∈ s.tags.val, x.owner = owner → x.name_lower = lower → K x) :
    find_tag_named s'.tags owner lower = find_tag_named s.tags owner lower := by
  rw [eq_ok_of_spec (find_tag_named_spec _ _ _), eq_ok_of_spec (find_tag_named_spec _ _ _), h,
    find?_slice _ _ _ (fun x hx hp => by simp at hp; exact hk x hx hp.1 hp.2)]

/-- `tag_writes` reads the caller's tags of the names it is given. -/
theorem tag_writes_slice {K : Tag → Bool} (h : s'.tags.val = s.tags.val.filter K) (owner id : U64)
    (names : alloc.vec.Vec Text) (now : U64) (ws : alloc.vec.Vec Write) (last : U64)
    (hk : ∀ x ∈ s.tags.val, x.owner = owner → ∀ n ∈ names.val, x.name_lower = lowerT n → K x) :
    tag_writes s' owner id names now ws last = tag_writes s owner id names now ws last := by
  have hb : ∀ st : (alloc.vec.Vec Write) × (alloc.vec.Vec Text) × (alloc.vec.Vec Tag) × U64 × Usize, tag_writes_loop.body s' owner id names now st.1 st.2.1 st.2.2.1 st.2.2.2.1 st.2.2.2.2 =
      tag_writes_loop.body s owner id names now st.1 st.2.1 st.2.2.1 st.2.2.2.1 st.2.2.2.2 := by
    rintro ⟨out, shown, made, next, i⟩
    unfold tag_writes_loop.body
    by_cases hlt : i.val < names.val.length
    · simp only [(lt_len_iff _ _).2 hlt, vec_index_eq _ _ hlt, if_true, lower_text_total, bind_ok, bind_tc_ok]
      rw [find_tag_named_slice h owner _ (fun x hx ho hl => hk x hx ho _ (List.getElem_mem hlt) hl)]
    · simp only [mt (lt_len_iff _ _).1 hlt, if_false]
  unfold tag_writes tag_writes_loop
  have : (fun (x : (alloc.vec.Vec Write) × (alloc.vec.Vec Text) × (alloc.vec.Vec Tag) × U64 × Usize) =>
      match x with | (out1, shown1, made1, next1, i1) => tag_writes_loop.body s' owner id names now out1 shown1 made1 next1 i1) =
      (fun x => match x with | (out1, shown1, made1, next1, i1) => tag_writes_loop.body s owner id names now out1 shown1 made1 next1 i1) := by
    funext x; obtain ⟨a, b, c, d, e⟩ := x; exact hb (a, b, c, d, e)
  simp only [this]

/-- `namedA` on a tag row: the token's user's tag with one of the names. -/
theorem namedA_holds (t : Text) (names : List Text) (x : Tag) :
    (namedA t names).holds (Snapshot.enc s) (Tag.row x) =
      ((mineA 1 t).holds (Snapshot.enc s) (Tag.row x) && names.any (fun n => decide (x.name_lower = lowerT n))) := by
  unfold namedA
  rw [holds_and]
  congr 1
  have : ∀ (l : List Text) (base : Pred Val), (l.foldl (fun p n => .or p (eqB 3 (lowerT n))) base).holds
      (Snapshot.enc s) (Tag.row x) = (base.holds (Snapshot.enc s) (Tag.row x) || l.any (fun n => decide (x.name_lower = lowerT n))) := by
    intro l
    induction l with
    | nil => intro base; simp
    | cons n ns ih =>
      intro base
      rw [List.foldl_cons, ih]
      simp [eqB, Tag.row, Bool.or_assoc]
  rw [this]
  simp only [holds_and, holds_eq, eqU, Tag.row]
  have h01 : int 0 ≠ int 1 := fun e => by
    have := int_inj (by norm_num) (by norm_num) e; omega
  simp only [Bool.or_eq_right_iff_imp, Bool.and_eq_true, decide_eq_true_eq]
  rintro ⟨h1, h2⟩
  simp at h1 h2
  exact absurd (h1.symm.trans h2) h01

theorem url_taken_slice {K : Bookmark → Bool} (h : s'.bookmarks.val = s.bookmarks.val.filter K) (owner : U64)
    (url : Text) (id : U64) (hk : ∀ x ∈ s.bookmarks.val, x.owner = owner → x.url = url → K x) :
    url_taken s' owner url id = url_taken s owner url id := by
  rw [url_taken_eq, url_taken_eq, h, any_slice _ _ _ (fun x hx hp => by
    simp only [Bool.and_eq_true, decide_eq_true_eq] at hp; exact hk x hx hp.1.1 hp.1.2)]

/-! ### Paging -/

theorem page_snoc {α : Type} (l : List α) (x : α) (off lim : Nat) :
    ((l ++ [x]).drop off).take lim =
      if off ≤ l.length ∧ l.length - off < lim then (l.drop off).take lim ++ [x] else (l.drop off).take lim := by
  by_cases ho : off ≤ l.length
  · rw [List.drop_append_of_le_length ho]
    have hl : (l.drop off).length = l.length - off := List.length_drop
    by_cases hlt : l.length - off < lim
    · simp only [ho, hlt, and_self, if_true]
      rw [List.take_of_length_le (by simp; omega), List.take_of_length_le (by omega)]
    · simp only [hlt, and_false, if_false]
      rw [List.take_append_of_le_length (by omega)]
  · have : l.drop off = [] := List.drop_eq_nil_of_le (by omega)
    have : (l ++ [x]).drop off = [] := List.drop_eq_nil_of_le (by simp; omega)
    simp [*]

theorem on_page_eq (k off lim : U64) : on_page k off lim = ok (decide (off.val ≤ k.val ∧ k.val - off.val < lim.val)) := by
  unfold on_page
  split
  · rename_i h
    have : off.val ≤ k.val := by scalar_tac
    obtain ⟨d, hd, hdv⟩ := (WP.spec_equiv_exists _ _).1 (U64.sub_spec (x := k) (y := off) (by scalar_tac))
    rw [hd]; simp only [bind_tc_ok, bind_ok]
    congr 1
    simp only [this, true_and, decide_eq_decide]
    constructor <;> intro h' <;> scalar_tac
  · rename_i h
    have : ¬ off.val ≤ k.val := by scalar_tac
    simp [this]

/-- A paging loop (`page_tags`, `page_bookmarks`) keeps the elements at
positions `offset` to `offset + limit`. -/
theorem page_loop_spec {α : Type} (v : alloc.vec.Vec α) (off lim : U64) (clone : α → Result α)
    (hclone : ∀ x, clone x = ok x) (body : (alloc.vec.Vec α) × Usize → Result (ControlFlow ((alloc.vec.Vec α) × Usize) (alloc.vec.Vec α)))
    (hbody : ∀ out i, body (out, i) = if i < alloc.vec.Vec.len v then (do
      let i2 ← lift (UScalar.cast .U64 i)
      let b ← on_page i2 off lim
      let out1 ← if b then (do let x ← alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice α) v i; let x' ← clone x; out.push x') else ok out
      let i3 ← i + 1#usize
      ok (ControlFlow.cont (out1, i3))) else ok (ControlFlow.done out)) :
    loop body (alloc.vec.Vec.new α, 0#usize) ⦃ w => w.val = (v.val.drop off.val).take lim.val ⦄ := by
  apply loop.spec_decr_nat (measure := fun x => v.val.length - x.2.val)
    (inv := fun x => x.2.val ≤ v.val.length ∧ x.1.val = ((v.val.take x.2.val).drop off.val).take lim.val)
  · rintro ⟨out, i⟩ ⟨hi, hout⟩
    simp only at hi hout
    rw [hbody]
    by_cases hlt : i.val < v.val.length
    · rw [if_pos ((lt_len_iff _ _).2 hlt)]
      have hc : (UScalar.cast .U64 i).val = i.val := usize_cast_u64 i
      obtain ⟨i3, hi3, hv3⟩ := succ_ok i v.val.length hlt v.len_ineq
      simp only [lift, bind_tc_ok, bind_ok, on_page_eq, hc, vec_index_eq _ _ hlt, hclone]
      have hlen : out.val.length < Usize.max := by
        have := congrArg List.length hout
        have h1 : (((v.val.take i.val).drop off.val).take lim.val).length ≤ i.val := by
          simp only [List.length_take, List.length_drop]; omega
        have := v.len_ineq; omega
      have htk : v.val.take (i.val + 1) = v.val.take i.val ++ [v.val[i.val]] := by
        rw [List.take_add_one, List.getElem?_eq_getElem hlt]; rfl
      have htl : (v.val.take i.val).length = i.val := by simp; omega
      split
      · rename_i hb
        obtain ⟨o1, h1, h2⟩ := (WP.spec_equiv_exists _ _).1 (alloc.vec.Vec.push_spec out v.val[i.val] hlen)
        rw [h1]; simp only [bind_tc_ok, bind_ok, hi3, WP.spec_ok]
        refine ⟨⟨by simp only [hv3]; omega, ?_⟩, by simp only [hv3]; omega⟩
        simp only [hv3, htk, page_snoc, htl]
        simp only [decide_eq_true_eq] at hb
        rw [if_pos hb, h2, hout]
      · rename_i hb
        simp only [bind_tc_ok, bind_ok, hi3, WP.spec_ok]
        refine ⟨⟨by simp only [hv3]; omega, ?_⟩, by simp only [hv3]; omega⟩
        simp only [hv3, htk, page_snoc, htl]
        simp only [decide_eq_true_eq] at hb
        rw [if_neg hb, hout]
    · rw [if_neg (mt (lt_len_iff _ _).1 hlt)]
      simp only [WP.spec_ok]
      have : i.val = v.val.length := by omega
      rw [hout, this, List.take_length]
  · simp [vec_new_val]

theorem page_tags_spec (v : alloc.vec.Vec Tag) (off lim : U64) :
    page_tags v off lim ⦃ w => w.val = (v.val.drop off.val).take lim.val ⦄ := by
  unfold page_tags page_tags_loop
  exact page_loop_spec v off lim _ (fun x => Schema.Tag.clone_eq x) _ (fun out i => rfl)

theorem page_bookmarks_spec (v : alloc.vec.Vec Bookmark) (off lim : U64) :
    page_bookmarks v off lim ⦃ w => w.val = (v.val.drop off.val).take lim.val ⦄ := by
  unfold page_bookmarks page_bookmarks_loop
  exact page_loop_spec v off lim _ (fun x => Schema.Bookmark.clone_eq x) _ (fun out i => rfl)

/-- A loop that keeps the elements satisfying `P`. -/
theorem filter_loop_spec {α : Type} (v : alloc.vec.Vec α) (P : α → Prop) [DecidablePred P] (clone : α → Result α)
    (hclone : ∀ x, clone x = ok x) (body : (alloc.vec.Vec α) × Usize → Result (ControlFlow ((alloc.vec.Vec α) × Usize) (alloc.vec.Vec α)))
    (hbody : ∀ out i, body (out, i) = if i < alloc.vec.Vec.len v then (do
      let x ← alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice α) v i
      let out1 ← if P x then (do let x' ← clone x; out.push x') else ok out
      let i2 ← i + 1#usize
      ok (ControlFlow.cont (out1, i2))) else ok (ControlFlow.done out)) :
    loop body (alloc.vec.Vec.new α, 0#usize) ⦃ w => w.val = v.val.filter (fun x => decide (P x)) ⦄ := by
  apply loop.spec_decr_nat (measure := fun x => v.val.length - x.2.val)
    (inv := fun x => x.2.val ≤ v.val.length ∧ x.1.val = (v.val.take x.2.val).filter (fun x => decide (P x)))
  · rintro ⟨out, i⟩ ⟨hi, hout⟩
    simp only at hi hout
    rw [hbody]
    by_cases hlt : i.val < v.val.length
    · rw [if_pos ((lt_len_iff _ _).2 hlt)]
      obtain ⟨i3, hi3, hv3⟩ := succ_ok i v.val.length hlt v.len_ineq
      simp only [bind_tc_ok, bind_ok, vec_index_eq _ _ hlt, hclone]
      have hlen : out.val.length < Usize.max := by
        have h1 := congrArg List.length hout
        have h2 : ((v.val.take i.val).filter (fun x => decide (P x))).length ≤ i.val :=
          (List.length_filter_le _ _).trans (by simp)
        have := v.len_ineq; omega
      have htk : v.val.take (i.val + 1) = v.val.take i.val ++ [v.val[i.val]] := by
        rw [List.take_add_one, List.getElem?_eq_getElem hlt]; rfl
      split
      · rename_i hp
        obtain ⟨o1, h1, h2⟩ := (WP.spec_equiv_exists _ _).1 (alloc.vec.Vec.push_spec out v.val[i.val] hlen)
        rw [h1]; simp only [bind_tc_ok, bind_ok, hi3, WP.spec_ok]
        refine ⟨⟨by simp only [hv3]; omega, ?_⟩, by simp only [hv3]; omega⟩
        simp only [hv3, htk, List.filter_append, h2, hout]
        simp [hp]
      · rename_i hp
        simp only [bind_tc_ok, bind_ok, hi3, WP.spec_ok]
        refine ⟨⟨by simp only [hv3]; omega, ?_⟩, by simp only [hv3]; omega⟩
        simp only [hv3, htk, List.filter_append, hout]
        simp [hp]
    · rw [if_neg (mt (lt_len_iff _ _).1 hlt)]
      simp only [WP.spec_ok]
      have : i.val = v.val.length := by omega
      rw [hout, this, List.take_length]
  · simp [vec_new_val]

/-! ### The listing's context -/

theorem find_user_by_name_eq (us : alloc.vec.Vec User) (n : Text) :
    find_user_by_name us n = ok (us.val.find? (fun u => decide (u.username = n))) := by
  apply eq_ok_of_spec
  unfold find_user_by_name find_user_by_name_loop
  apply WP.spec_mono (loop_search us.val (fun u => decide (u.username = n)) (fun o : Option User => o)
    (fun _ x => some x) none _ ?_ 0#usize (by simp))
  · intro r hr; exact search_find _ _ _ hr
  · intro j hj; unfold find_user_by_name_loop.body; h5i_step

theorem lower_all_ok (v w : alloc.vec.Vec Text) (h : lower_all v = ok w) : w.val = v.val.map lowerT := by
  have hl : lower_all v = (do let a ← (v.val.foldlM (fun (out : alloc.vec.Vec Text) x =>
      do let y ← lower_text x; out.push y) (alloc.vec.Vec.new Text)); ok a) := by
    unfold lower_all lower_all_loop
    have := loop_foldlM v.val v.len_ineq (fun (out : alloc.vec.Vec Text) x => do let y ← lower_text x; out.push y)
      (fun x => x) (fun a i => (a, i)) (fun x => lower_all_loop.body v x.1 x.2) ?_ (alloc.vec.Vec.new Text) 0#usize (by simp)
    · simpa using this
    · intro a i hi
      unfold lower_all_loop.body
      body_shape v
  rw [hl] at h
  obtain ⟨a, ha, e⟩ := bind_tc_eq_ok.1 h
  simp only [ok.injEq] at e; subst e
  have := foldlM_abs (fun (out : alloc.vec.Vec Text) x => do let y ← lower_text x; out.push y) (fun o => o.val)
    (fun l x => l ++ [lowerT x]) (fun a x r hr => by
      simp only [lower_text_total, bind_tc_ok, bind_ok] at hr; rw [push_ok hr]) _ _ _ ha
  rw [this]
  simp only [vec_new_val]
  have : ∀ (l : List Text) (acc : List Text), l.foldl (fun l x => l ++ [lowerT x]) acc = acc ++ l.map lowerT := by
    intro l; induction l with
    | nil => intro acc; simp
    | cons y ys ih => intro acc; simp [ih]
  rw [this]; simp

theorem list_ctx_slice (flt : Filter) (v : U64) (hu : find_user s'.users v = find_user s.users v)
    (ho : owner_filter_of s' flt = owner_filter_of s flt) (hb : bundle_of s' flt v = bundle_of s flt v) :
    list_ctx s' flt v = list_ctx s flt v := by
  unfold list_ctx; simp only [hu, ho, hb]

theorem paged_simple {flt : Filter} (h : paged flt = ok true) : ∃ p, simple_query flt.q = ok (some p) := by
  unfold paged at h
  h5i_invert h
  cases o with
  | none => simp at h
  | some p => exact ⟨p, ho⟩

/-- What `list_ctx` resolves. -/
theorem list_ctx_ok {s : Snapshot} {flt : Filter} {v : U64} {ctx : ListCtx} (h : list_ctx s flt v = ok ctx) :
    ctx.viewer = v ∧ owner_filter_of s flt = ok ctx.owner_filter ∧ bundle_of s flt v = ok ctx.bundle ∧
      paged flt = ok ctx.paged ∧ (ctx.paged = true → ∃ tags u, simple_query flt.q = ok (some (tags, u)) ∧
        ctx.simple_tags.val = tags.val.map lowerT ∧ ctx.simple_unread = u) := by
  unfold list_ctx at h
  h5i_invert h
  obtain ⟨lax, legacy⟩ := x
  simp only [uncurry_apply_pair] at h
  h5i_invert h
  · subst hc
    obtain ⟨p, hp⟩ := paged_simple hpg
    rw [hp] at ho; simp at ho
  · subst hc
    obtain ⟨tg, u⟩ := p
    simp only [uncurry_apply_pair] at h
    h5i_invert h
    exact ⟨rfl, howner_filter, hbundle, hpg, fun _ => ⟨tg, u, ho, lower_all_ok _ _ hsimple_tags, rfl⟩⟩
  · simp only [Bool.not_eq_true] at hc; subst hc
    exact ⟨rfl, howner_filter, hbundle, hpg, by simp⟩

/-! ### The listing's selection -/

/-- `select`'s step over the bookmarks. -/
def selStep (s : Snapshot) (flt : Filter) (ctx : ListCtx) (sel : alloc.vec.Vec Bookmark) (b : Bookmark) :
    Result (alloc.vec.Vec Bookmark) := do
  let k ← keep s flt ctx b
  if k then (do let b2 ← Bookmark.Insts.CoreCloneClone.clone b; sel.push b2) else ok sel

theorem select_eq (s : Snapshot) (flt : Filter) (ctx : ListCtx) :
    select s flt ctx = (do let a ← (s.bookmarks.val.foldlM (selStep s flt ctx) (alloc.vec.Vec.new Bookmark)); ok a) := by
  unfold select select_loop
  have := loop_foldlM s.bookmarks.val s.bookmarks.len_ineq (selStep s flt ctx) (fun x => x) (fun a i => (a, i))
    (fun x => select_loop.body s flt ctx x.1 x.2) ?_ (alloc.vec.Vec.new Bookmark) 0#usize (by simp)
  · simpa using this
  · intro a i hi
    unfold select_loop.body selStep
    body_shape s.bookmarks

/-- What `select` keeps: bookmarks of the state that `keep` accepts. -/
theorem select_ok {s : Snapshot} {flt : Filter} {ctx : ListCtx} {sel : alloc.vec.Vec Bookmark}
    (h : select s flt ctx = ok sel) : ∀ b ∈ sel.val, b ∈ s.bookmarks.val ∧ keep s flt ctx b = ok true := by
  rw [select_eq] at h
  obtain ⟨a, ha, e⟩ := bind_tc_eq_ok.1 h
  simp only [ok.injEq] at e; subst e
  have key : ∀ (l : List Bookmark) (acc r : alloc.vec.Vec Bookmark), l.foldlM (selStep s flt ctx) acc = ok r →
      ∀ b ∈ r.val, b ∈ acc.val ∨ (b ∈ l ∧ keep s flt ctx b = ok true) := by
    intro l
    induction l with
    | nil => intro acc r h b hb; simp only [List.foldlM_nil, pure_tc_eq, ok.injEq] at h; subst h; exact .inl hb
    | cons x xs ih =>
      intro acc r h b hb
      simp only [List.foldlM_cons] at h
      obtain ⟨a1, h1, h2⟩ := bind_tc_eq_ok.1 h
      rcases ih a1 r h2 b hb with hb' | ⟨hm, hk⟩
      · unfold selStep at h1
        obtain ⟨k, hk, h3⟩ := bind_tc_eq_ok.1 h1
        split at h3
        · obtain ⟨b2, hb2, h4⟩ := bind_tc_eq_ok.1 h3
          have e := bookmark_clone_ok hb2; subst e
          rw [push_ok h4] at hb'
          rcases List.mem_append.1 hb' with hb' | hb'
          · exact .inl hb'
          · simp at hb'; subst hb'; rename_i hkt; exact .inr ⟨by simp, by rw [hk, hkt]⟩
        · simp only [ok.injEq] at h3; subst h3; exact .inl hb'
      · exact .inr ⟨List.mem_cons_of_mem _ hm, hk⟩
  intro b hb
  rcases key _ _ _ ha b hb with hb' | hb'
  · simp [vec_new_val] at hb'
  · exact hb'

/-- `tag_lowers`' step over the links. -/
def tlStep (s : Snapshot) (id : U64) (out : alloc.vec.Vec Text) (l : Link) : Result (alloc.vec.Vec Text) :=
  if l.bookmark = id then (do
    let o ← find_tag s.tags l.tag
    match o with
    | none => ok out
    | some t => do let v ← alloc.vec.CloneVec.clone core.clone.CloneU8 t.name_lower; out.push v)
  else ok out

theorem tag_lowers_eq (s : Snapshot) (id : U64) :
    tag_lowers s id = (do let a ← (s.links.val.foldlM (tlStep s id) (alloc.vec.Vec.new Text)); ok a) := by
  unfold tag_lowers tag_lowers_loop
  have := loop_foldlM s.links.val s.links.len_ineq (tlStep s id) (fun x => x) (fun a i => (a, i))
    (fun x => tag_lowers_loop.body s id x.1 x.2) ?_ (alloc.vec.Vec.new Text) 0#usize (by simp)
  · simpa using this
  · intro a i hi
    unfold tag_lowers_loop.body tlStep
    body_shape s.links

theorem tag_lowers_slice {KL : Link → Bool} {KT : Tag → Bool} (hl : s'.links.val = s.links.val.filter KL)
    (ht : s'.tags.val = s.tags.val.filter KT) (id : U64)
    (hkl : ∀ l ∈ s.links.val, l.bookmark = id → KL l)
    (hkt : ∀ l ∈ s.links.val, l.bookmark = id → ∀ x ∈ s.tags.val, x.id = l.tag → KT x) :
    tag_lowers s' id = tag_lowers s id := by
  rw [tag_lowers_eq, tag_lowers_eq, hl, foldlM_slice _ _ (tlStep s id) (tlStep s' id)]
  · intro l hm hk a
    have : ¬ l.bookmark = id := fun h => by simp [hkl l hm h] at hk
    simp [tlStep, this]
  · intro l hm _ a
    unfold tlStep
    split
    · rename_i hb
      rw [eq_ok_of_spec (find_tag_spec _ _), eq_ok_of_spec (find_tag_spec _ _), ht,
        find?_slice _ _ _ (fun x hx hp => hkt l hm hb x hx (by simpa using hp))]
    · rfl

theorem selected_slice (flt : Filter) (parsed : search.Parsed) (lax legacy : Bool) (bundle : Option Bundle)
    (tw : Bool) (b : Bookmark) (h : tag_lowers s' b.id = tag_lowers s b.id) :
    selected s' flt parsed lax legacy bundle tw b = selected s flt parsed lax legacy bundle tw b := by
  unfold selected facts
  simp only [h]

theorem shared_visible_slice (viewer : U64) (b : Bookmark) (o : Option U64)
    (h : find_user s'.users b.owner = find_user s.users b.owner) :
    shared_visible s' viewer b o = shared_visible s viewer b o := by
  unfold shared_visible
  simp only [h]

theorem views_eq (s : Snapshot) (page : alloc.vec.Vec Bookmark) :
    views s page = (do let a ← (page.val.foldlM (fun (items : alloc.vec.Vec BookmarkView) b =>
      do let bv ← view s b; items.push bv) (alloc.vec.Vec.new BookmarkView)); ok a) := by
  unfold views views_loop
  have := loop_foldlM page.val page.len_ineq (fun (items : alloc.vec.Vec BookmarkView) b =>
      do let bv ← view s b; items.push bv) (fun x => x) (fun a i => (a, i))
    (fun x => views_loop.body s page x.1 x.2) ?_ (alloc.vec.Vec.new BookmarkView) 0#usize (by simp)
  · simpa using this
  · intro a i hi
    unfold views_loop.body
    body_shape page

theorem views_slice (page : alloc.vec.Vec Bookmark) (h : ∀ b ∈ page.val, view s' b = view s b) :
    views s' page = views s page := by
  rw [views_eq, views_eq, foldlM_congr _ (fun (items : alloc.vec.Vec BookmarkView) b => do let bv ← view s b; items.push bv)
    (fun (items : alloc.vec.Vec BookmarkView) b => do let bv ← view s' b; items.push bv) (fun b hb a => by simp only [h b hb])]

/-! ### Sorting keeps the elements -/

theorem bookmarks_clone_ok {v w : alloc.vec.Vec Bookmark} (h : alloc.vec.CloneVec.clone Bookmark.Insts.CoreCloneClone v = ok w) :
    w = v := by
  rw [vec_clone_eq _ v (fun x => Schema.Bookmark.clone_eq x)] at h; simp only [ok.injEq] at h; exact h.symm

theorem merge_ok (a b : alloc.vec.Vec Bookmark) (sort : U8) (out : alloc.vec.Vec Bookmark) (h : merge a b sort = ok out) :
    ∀ x ∈ out.val, x ∈ a.val ∨ x ∈ b.val := by
  unfold merge merge_loop at h
  refine loop_ok _ (fun st : (alloc.vec.Vec Bookmark) × Usize × Usize => ∀ x ∈ st.1.val, x ∈ a.val ∨ x ∈ b.val)
    (fun r => ∀ x ∈ r.val, x ∈ a.val ∨ x ∈ b.val) (fun st => (a.length - st.2.1.val) + (b.length - st.2.2.val)) ?_ _ _
    (by simp [vec_new_val]) h
  rintro ⟨out, i, j⟩ c hI hb
  unfold merge_loop.body at hb
  h5i_invert hb
  all_goals simp only at hI ⊢
  all_goals first
    | exact hI
    | (refine ⟨fun x hx => ?_, ?_⟩
       · rw [push_ok hout1] at hx
         rcases List.mem_append.1 hx with hx | hx
         · exact hI x hx
         · simp at hx; subst hx
           have := bookmark_clone_ok ‹Bookmark.Insts.CoreCloneClone.clone _ = ok _›; subst this
           h5i_ok_facts
           first | exact .inl (by assumption) | exact .inr (by assumption)
       · h5i_ok_facts
         have : a.val.length = (alloc.vec.Vec.len a).val := by simp [alloc.vec.Vec.len]
         have : b.val.length = (alloc.vec.Vec.len b).val := by simp [alloc.vec.Vec.len]
         scalar_tac)

/-- Runs whose elements are elements of `v`. -/
def Within (v : List Bookmark) (runs : List (alloc.vec.Vec Bookmark)) : Prop := ∀ r ∈ runs, ∀ x ∈ r.val, x ∈ v

theorem runs_ok (v : alloc.vec.Vec Bookmark) (runs : alloc.vec.Vec (alloc.vec.Vec Bookmark))
    (h : sort_bookmarks_loop0 v (alloc.vec.Vec.new _) 0#usize = ok runs) : Within v.val runs.val := by
  unfold sort_bookmarks_loop0 at h
  refine loop_ok _ (fun st : (alloc.vec.Vec (alloc.vec.Vec Bookmark)) × Usize => Within v.val st.1.val)
    (fun r => Within v.val r.val) (fun st => v.length - st.2.val) ?_ _ _ (by simp [Within, vec_new_val]) h
  rintro ⟨runs, i⟩ c hI hb
  unfold sort_bookmarks_loop0.body at hb
  h5i_invert hb
  all_goals simp only at hI ⊢
  · refine ⟨fun r0 hm x hx => ?_, ?_⟩
    · rw [push_ok hruns1] at hm
      rcases List.mem_append.1 hm with hm | hm
      · exact hI r0 hm x hx
      · simp at hm; subst hm
        rw [push_ok hr] at hx; simp at hx; subst hx
        rw [bookmark_clone_ok hb1]; exact Owner.index_mem _ _ _ hb_1
    · h5i_ok_facts
      have : v.val.length = (alloc.vec.Vec.len v).val := by simp [alloc.vec.Vec.len]
      scalar_tac
  · exact hI

theorem pairs_ok (src : List Bookmark) (sort : U8) (runs next : alloc.vec.Vec (alloc.vec.Vec Bookmark))
    (hr : Within src runs.val) (h : sort_bookmarks_loop1_loop0 sort runs (alloc.vec.Vec.new _) 0#usize = ok next) :
    Within src next.val ∧ 2 * next.val.length ≤ runs.val.length + 1 := by
  unfold sort_bookmarks_loop1_loop0 at h
  refine loop_ok _ (fun st : (alloc.vec.Vec (alloc.vec.Vec Bookmark)) × Usize => Within src st.1.val ∧
      st.2.val ≤ runs.val.length + 1 ∧ 2 * st.1.val.length = st.2.val)
    (fun r => Within src r.val ∧ 2 * r.val.length ≤ runs.val.length + 1)
    (fun st => runs.length + 2 - st.2.val) ?_ _ _ (by simp [Within, vec_new_val]) h
  rintro ⟨next, k⟩ c ⟨hI, hk, hl⟩ hb
  simp only at hI hk hl
  unfold sort_bookmarks_loop1_loop0.body at hb
  have hlen : runs.val.length = (alloc.vec.Vec.len runs).val := by simp [alloc.vec.Vec.len]
  h5i_invert hb
  · have hle : k.val + 2 ≤ runs.val.length + 1 := by h5i_ok_facts; scalar_tac
    have hk2 : k1.val = k.val + 2 := by h5i_ok_facts; scalar_tac
    have key : Within src next1.val ∧ next1.val.length = next.val.length + 1 := by
      split at hnext1
      · h5i_invert hnext1
        rw [push_ok hnext1]
        refine ⟨fun r0 hm x hx => ?_, by simp⟩
        rcases List.mem_append.1 hm with hm | hm
        · exact hI r0 hm x hx
        · simp at hm; subst hm
          rcases merge_ok _ _ _ _ hv2 x hx with hx | hx
          · exact hr _ (Owner.index_mem _ _ _ hv) x hx
          · exact hr _ (Owner.index_mem _ _ _ hv1) x hx
      · h5i_invert hnext1
        rw [push_ok hnext1]
        refine ⟨fun r0 hm x hx => ?_, by simp⟩
        rcases List.mem_append.1 hm with hm | hm
        · exact hI r0 hm x hx
        · simp at hm; subst hm
          rw [bookmarks_clone_ok hv1] at hx
          exact hr _ (Owner.index_mem _ _ _ hv) x hx
    refine ⟨⟨key.1, ?_, ?_⟩, ?_⟩
    · show k1.val ≤ _; omega
    · show 2 * next1.val.length = k1.val; rw [key.2, hk2]; omega
    · show runs.length + 2 - k1.val < runs.length + 2 - k.val
      simp only [alloc.vec.Vec.length]; omega
  · simp only
    exact ⟨hI, by scalar_tac⟩

theorem sort_ok (v : alloc.vec.Vec Bookmark) (sort : U8) (w : alloc.vec.Vec Bookmark)
    (h : sort_bookmarks v sort = ok w) : ∀ x ∈ w.val, x ∈ v.val := by
  unfold sort_bookmarks at h
  h5i_invert h
  · simp [vec_new_val]
  · have h0 := runs_ok v runs hruns
    have h1 : Within v.val runs1.val := by
      unfold sort_bookmarks_loop1 at hruns1
      refine loop_ok _ (fun r : alloc.vec.Vec (alloc.vec.Vec Bookmark) => Within v.val r.val)
        (fun r => Within v.val r.val) (fun r => r.length) ?_ _ _ h0 hruns1
      intro r c hI hb
      unfold sort_bookmarks_loop1.body at hb
      have hlen : r.val.length = (alloc.vec.Vec.len r).val := by simp [alloc.vec.Vec.len]
      h5i_invert hb
      · obtain ⟨hw, hl⟩ := pairs_ok v.val sort r next hI hnext
        refine ⟨hw, ?_⟩
        simp only [alloc.vec.Vec.length]
        have : 1 < r.val.length := by scalar_tac
        omega
      · exact hI
    rw [bookmarks_clone_ok h]
    exact h1 _ (Owner.index_mem _ _ _ hv1)

theorem reversed_spec (v : alloc.vec.Vec Bookmark) : reversed v ⦃ w => w.val = v.val.reverse ⦄ := by
  unfold reversed reversed_loop
  apply loop.spec_decr_nat (measure := fun x => x.2.val)
    (inv := fun x => x.2.val ≤ v.val.length ∧ x.1.val = (v.val.drop x.2.val).reverse)
  · rintro ⟨out, i⟩ ⟨hi, hout⟩
    simp only at hi hout
    unfold reversed_loop.body
    by_cases h0 : i.val = 0
    · have : ¬ i > 0#usize := by scalar_tac
      simp only [this, if_false, WP.spec_ok]
      rw [hout, h0]; simp
    · have : i > 0#usize := by scalar_tac
      simp only [this, if_true]
      obtain ⟨i1, hi1, hv1⟩ := (WP.spec_equiv_exists _ _).1 (Usize.sub_spec (x := i) (y := 1#usize) (by scalar_tac))
      have hv1' : i1.val = i.val - 1 := by scalar_tac
      have hlt : i1.val < v.val.length := by omega
      rw [hi1]; simp only [bind_tc_ok, bind_ok, vec_index_eq _ _ hlt, Schema.Bookmark.clone_eq]
      have hlen : out.val.length < Usize.max := by
        have := congrArg List.length hout; simp at this
        have := v.len_ineq; omega
      obtain ⟨o1, h1, h2⟩ := (WP.spec_equiv_exists _ _).1 (alloc.vec.Vec.push_spec out v.val[i1.val] hlen)
      rw [h1]; simp only [bind_tc_ok, bind_ok, WP.spec_ok]
      refine ⟨⟨by omega, ?_⟩, by omega⟩
      rw [h2, hout, List.drop_eq_getElem_cons hlt]
      have : i1.val + 1 = i.val := by omega
      simp [this]
  · simp [alloc.vec.Vec.len, vec_new_val]

/-- The caller's user row is loaded; a guest (0) has none. -/
theorem find_user_viewer_slice {K : User → Bool} (hk : Keys s) (h : s'.users.val = s.users.val.filter K) {t : Text}
    (hK : ∀ x ∈ s.users.val, (mineA 0 t).holds (Snapshot.enc s) (User.row x) → K x) {v : U64}
    (ha : actorOf s t = .Ok v) : find_user s'.users v = find_user s.users v := by
  rw [eq_ok_of_spec (find_user_spec _ _), eq_ok_of_spec (find_user_spec _ _), h]
  by_cases h0 : v = 0#u64
  · subst h0
    have hn : s.users.val.find? (fun x => decide (x.id = 0#u64)) = none := by
      rw [List.find?_eq_none]; intro x hx; simpa using hk.user_pos x hx
    rw [hn]; congr 1; rw [List.find?_eq_none]
    intro x hx; have := (List.mem_filter.1 hx).1; simpa using hk.user_pos x this
  · obtain ⟨k, hkm, h1, h2⟩ := actorOf_ok ha h0
    rw [find?_slice _ _ _ (fun x hx hp => hK x hx (by
      rw [mine_holds s t x.id _ 0 (by simp [User.row])]; simp only [decide_eq_true_eq]
      exact ⟨k, hkm, h1, h2.trans (by simpa using hp : x.id = v).symm⟩))]

/-- The caller's bundle `?bundle=` names, loaded by its id and owner. -/
theorem bundle_of_slice (hk : Keys s) (flt : Filter) {t : Text} {v : U64} (ha : actorOf s t = .Ok v)
    (h : ∀ id, flt.bundle = some id → s'.bundles.val = s.bundles.val.filter (fun x =>
      (Pred.and (eqU 0 id) (mineA 1 t)).holds (Snapshot.enc s) (Bundle.row x))) :
    bundle_of s' flt v = bundle_of s flt v := by
  unfold bundle_of
  cases hb : flt.bundle with
  | none => rfl
  | some id =>
    simp only []
    split
    · rfl
    · rename_i h0
      rw [eq_ok_of_spec (find_bundle_spec _ _), eq_ok_of_spec (find_bundle_spec _ _), h id hb,
        List.filter_congr (fun x hx => show _ = decide (x.id = id ∧ x.owner = v) by
          rw [holds_and, mine_holds_iff hk ha h0 x.owner _ 1 (by simp [Bundle.row])]
          simp [eqU, Bundle.row])]
      rw [find_filter_unique _ Bundle.id _ id hk.bundles]
      simp only [bind_ok]
      cases hf : s.bundles.val.find? (fun x => decide (x.id = id)) with
      | none => rfl
      | some b =>
        have hi : b.id = id := by simpa using (find?_mem hf).2
        by_cases ho : b.owner = v <;> simp [ho, hi]

theorem select_slice {KB : Bookmark → Bool} (h : s'.bookmarks.val = s.bookmarks.val.filter KB) (flt : Filter)
    (ctx : ListCtx) (hskip : ∀ b ∈ s.bookmarks.val, KB b = false → keep s flt ctx b = ok false)
    (hsame : ∀ b ∈ s.bookmarks.val, KB b = true → keep s' flt ctx b = keep s flt ctx b) :
    select s' flt ctx = select s flt ctx := by
  rw [select_eq, select_eq, h, foldlM_slice _ _ (selStep s flt ctx) (selStep s' flt ctx)]
  · intro b hm hk a
    simp [selStep, hskip b hm hk]
  · intro b hm hk a
    simp only [selStep, hsame b hm hk]

end Lookups

/-! ## Commands -/

section Commands
variable (s : Snapshot) (t : Text)

theorem profile_frame (rest : List (Read Val)) : profile (Snapshot.load (callerA t ++ rest) s) t = profile s t := by
  unfold profile; rw [(caller_slice s t rest).2]

theorem by_id_frame (id : U64) :
    delete_bookmark (Snapshot.load (callerA t ++ [⟨2, byIdA id, {}⟩]) s) t id = delete_bookmark s t id ∧
      ∀ ar now, archive (Snapshot.load (callerA t ++ [⟨2, byIdA id, {}⟩]) s) t id ar now = archive s t id ar now := by
  have hs := (caller_slice s t [⟨2, byIdA id, {}⟩]).2
  set s' := Snapshot.load (callerA t ++ [⟨2, byIdA id, {}⟩]) s with hs'
  have hb : s'.bookmarks.val = s.bookmarks.val.filter (fun x => (byIdA id).holds (Snapshot.enc s) (Bookmark.row x)) := by
    simp [s', pickRows, callerA]
  have ho := own_bookmark_slice hb id (fun x _ hx => by holds_simp; exact hx)
  refine ⟨?_, fun ar now => ?_⟩
  · unfold delete_bookmark; simp only [hs, ho]
  · unfold archive; simp only [hs, ho]

theorem get_bookmark_frame (id : U64) :
    get_bookmark (Snapshot.load (callerA t ++ [⟨2, byIdA id, {}⟩] ++ tagReadsA (byIdA id) {}) s) t id =
      get_bookmark s t id := by
  have hs := (caller_slice s t ([⟨2, byIdA id, {}⟩] ++ tagReadsA (byIdA id) {})).2
  simp only [List.append_assoc] at hs ⊢
  generalize hp : callerA t ++ ([⟨2, byIdA id, {}⟩] ++ tagReadsA (byIdA id) {}) = plan at hs ⊢
  have hb : (Snapshot.load plan s).bookmarks.val =
      s.bookmarks.val.filter (fun x => (byIdA id).holds (Snapshot.enc s) (Bookmark.row x)) := by
    subst hp; simp [pickRows, callerA, tagReadsA]
  have hl : (Snapshot.load plan s).links.val =
      s.links.val.filter (fun x => (Pred.isIn 0 2 (byIdA id) 2 {}).holds (Snapshot.enc s) (Link.row x)) := by
    subst hp; simp [pickRows, callerA, tagReadsA]
  have ht : (Snapshot.load plan s).tags.val =
      s.tags.val.filter (fun x => (Pred.isIn 0 4 (Pred.isIn 0 2 (byIdA id) 2 {}) 1 {}).holds (Snapshot.enc s) (Tag.row x)) := by
    subst hp; simp [pickRows, callerA, tagReadsA]
  have ho := own_bookmark_slice hb id (fun x _ hx => by holds_simp; exact hx)
  unfold get_bookmark
  simp only [hs, ho]
  congr 1; funext r
  rcases r with v | e
  · simp only [own_bookmark_eq, bind_ok]
    cases hf : s.bookmarks.val.find? (fun x => decide (x.id = id)) with
    | none => rfl
    | some b =>
      obtain ⟨hm, hi⟩ := find?_mem hf
      simp only [decide_eq_true_eq] at hi
      by_cases hob : b.owner = v.id
      · simp only [hob, if_true]
        rw [view_slice hl ht b (fun l _ hl' => by holds_simp; exact ⟨b, hm, hi, hl'.symm⟩)
          (fun l hlm hl' x _ hx => by holds_simp; exact ⟨l, hlm, ⟨b, hm, hi, hl'.symm⟩, hx.symm⟩)]
      · simp only [hob, if_false]
  · rfl

theorem tag_id_frame (id : U64) :
    get_tag (Snapshot.load (callerA t ++ [⟨3, eqU 0 id, {}⟩]) s) t id = get_tag s t id ∧
      delete_tag (Snapshot.load (callerA t ++ [⟨3, eqU 0 id, {}⟩]) s) t id = delete_tag s t id := by
  have hs := (caller_slice s t [⟨3, eqU 0 id, {}⟩]).2
  have ht : (Snapshot.load (callerA t ++ [⟨3, eqU 0 id, {}⟩]) s).tags.val =
      s.tags.val.filter (fun x => (eqU 0 id).holds (Snapshot.enc s) (Tag.row x)) := by
    simp [pickRows, callerA]
  have ho := own_tag_slice ht id (fun x _ hx => by holds_simp; exact hx)
  exact ⟨by unfold get_tag; simp only [hs, ho], by unfold delete_tag; simp only [hs, ho]⟩

/-- The caller's bundles, loaded by `mineA 1 t`. -/
theorem bundles_load (hk : Keys s) (rest : List (Read Val)) (me : User) (hme : signedOf s t = .Ok me) :
    (∀ id, own_bundle (Snapshot.load (callerA t ++ ⟨5, mineA 1 t, {}⟩ :: rest) s) me id = own_bundle s me id) ∧
      bundles_of (Snapshot.load (callerA t ++ ⟨5, mineA 1 t, {}⟩ :: rest) s) me.id = bundles_of s me.id := by
  obtain ⟨ha, -, h0⟩ := signedOf_ok hme
  have hb : (Snapshot.load (callerA t ++ ⟨5, mineA 1 t, {}⟩ :: rest) s).bundles.val =
      s.bundles.val.filter (fun x => (mineA 1 t).holds (Snapshot.enc s) (Bundle.row x)) := by
    simp [pickRows, callerA]
  have hK : ∀ x ∈ s.bundles.val, (mineA 1 t).holds (Snapshot.enc s) (Bundle.row x) = decide (x.owner = me.id) :=
    fun x _ => mine_holds_iff hk ha h0 x.owner _ 1 (by simp [Bundle.row])
  exact ⟨own_bundle_slice hb me hK hk.bundles, bundles_of_slice hb me.id (fun x hx e => by rw [hK x hx]; simp [e])⟩

theorem bundle_frame (hk : Keys s) (rest : List (Read Val)) :
    let s' := Snapshot.load (callerA t ++ ⟨5, mineA 1 t, {}⟩ :: rest) s
    (∀ l o, list_bundles s' t l o = list_bundles s t l o) ∧ (∀ id, get_bundle s' t id = get_bundle s t id) ∧
      (∀ id f now, update_bundle s' t id f now = update_bundle s t id f now) ∧
      (∀ id, delete_bundle s' t id = delete_bundle s t id) := by
  intro s'
  have hs : signed_in s' t = signed_in s t := (caller_slice s t (⟨5, mineA 1 t, {}⟩ :: rest)).2
  refine ⟨fun l o => ?_, fun id => ?_, fun id f now => ?_, fun id => ?_⟩
  all_goals
    first | unfold list_bundles | unfold get_bundle | unfold update_bundle | unfold delete_bundle
    rw [hs, signed_in_eq]
    simp only [bind_ok]
    cases hme : signedOf s t with
    | Err e => rfl
    | Ok me =>
      obtain ⟨h1, h2⟩ := bundles_load s t hk rest me hme
      simp only [s', h1, h2]

theorem create_bundle_frame (hk : Keys s) (f : BundleFields) (now : U64) :
    create_bundle (Snapshot.load (callerA t ++ [⟨5, mineA 1 t, {}⟩, ⟨6, .all, {}⟩]) s) t f now =
      create_bundle s t f now := by
  have hs := (caller_slice s t [⟨5, mineA 1 t, {}⟩, ⟨6, .all, {}⟩]).2
  have hc : (Snapshot.load (callerA t ++ [⟨5, mineA 1 t, {}⟩, ⟨6, .all, {}⟩]) s).counter = s.counter := by
    simp [Snapshot.load, pickRows, callerA]
  unfold create_bundle
  rw [hs, signed_in_eq]
  simp only [bind_ok]
  cases hme : signedOf s t with
  | Err e => rfl
  | Ok me =>
    obtain ⟨-, h2⟩ := bundles_load s t hk [⟨6, .all, {}⟩] me hme
    simp only [h2, hc]

theorem vec_nil_eq (v : Text) : v.val = [] ↔ v = alloc.vec.Vec.new U8 := by
  constructor
  · intro h; apply alloc.vec.Vec.ext; simp [h, vec_new_val]
  · rintro rfl; rfl

/-- The caller's bookmarks of a URL are loaded by `urlA`. -/
theorem url_keep {me : User} (ha : actorOf s t = .Ok me.id) (h0 : me.id ≠ 0#u64) (url norm : Text) (x : Bookmark)
    (hx : sameP x me.id url norm = true) : (urlA t url norm).holds (Snapshot.enc s) (Bookmark.row x) = true := by
  obtain ⟨k, hk, h1, h2⟩ := actorOf_ok ha h0
  simp only [sameP, Bool.and_eq_true, Bool.or_eq_true, decide_eq_true_eq] at hx
  obtain ⟨ho, hu⟩ := hx
  simp only [urlA, holds_and, holds_or, Bool.and_eq_true, Bool.or_eq_true]
  refine ⟨?_, ?_⟩
  · rw [mine_holds s t x.owner _ 0 (by simp [Bookmark.row])]; simp only [decide_eq_true_eq]
    exact ⟨k, hk, h1, h2.trans ho.symm⟩
  · rcases hu with hu | ⟨hu1, hu2⟩
    · left; simp [eqB, Bookmark.row, hu]
    · right; simp [eqB, Bookmark.row, (vec_nil_eq _).1 hu1, hu2]

theorem check_frame (url norm : Text) :
    check (Snapshot.load (callerA t ++ [⟨2, urlA t url norm, {}⟩] ++ tagReadsA (urlA t url norm) {}) s) t url norm =
      check s t url norm := by
  have hs := (caller_slice s t ([⟨2, urlA t url norm, {}⟩] ++ tagReadsA (urlA t url norm) {})).2
  simp only [List.append_assoc] at hs ⊢
  generalize hp : callerA t ++ ([⟨2, urlA t url norm, {}⟩] ++ tagReadsA (urlA t url norm) {}) = plan at hs ⊢
  have hb : (Snapshot.load plan s).bookmarks.val =
      s.bookmarks.val.filter (fun x => (urlA t url norm).holds (Snapshot.enc s) (Bookmark.row x)) := by
    subst hp; simp [pickRows, callerA, tagReadsA]
  have hl : (Snapshot.load plan s).links.val =
      s.links.val.filter (fun x => (Pred.isIn 0 2 (urlA t url norm) 2 {}).holds (Snapshot.enc s) (Link.row x)) := by
    subst hp; simp [pickRows, callerA, tagReadsA]
  have ht : (Snapshot.load plan s).tags.val = s.tags.val.filter (fun x =>
      (Pred.isIn 0 4 (Pred.isIn 0 2 (urlA t url norm) 2 {}) 1 {}).holds (Snapshot.enc s) (Tag.row x)) := by
    subst hp; simp [pickRows, callerA, tagReadsA]
  unfold check
  rw [hs, signed_in_eq]
  simp only [bind_ok]
  cases hme : signedOf s t with
  | Err e => rfl
  | Ok me =>
    obtain ⟨ha, -, h0⟩ := signedOf_ok hme
    have hk := url_keep s t ha h0 url norm
    dsimp only
    rw [existing_slice hb me.id url norm (fun x _ hx => hk x hx)]
    obtain ⟨o, ho⟩ := existing_total s me.id url norm
    rw [ho]; simp only [bind_tc_ok, bind_ok]
    cases o with
    | none => rfl
    | some b =>
      obtain ⟨hm, hsb⟩ := existing_some ho
      have hkb := hk b hsb
      dsimp only
      rw [view_slice hl ht b (fun l _ hl' => by simp only [holds_in_2]; simp [Link.row]; exact ⟨b, hm, hkb, by simp [Bookmark.row, hl']⟩)
        (fun l hlm hl' x _ hx => by
          simp only [holds_in_4]; simp only [Tag.row, Link.row]; simp
          exact ⟨l, hlm, by simp only [holds_in_2]; simp; exact ⟨b, hm, hkb, by simp [Bookmark.row, hl']⟩, hx.symm⟩)]

/-- The caller's tags of the names, loaded by `namedA`. -/
theorem named_keep {me : User} (ha : actorOf s t = .Ok me.id) (h0 : me.id ≠ 0#u64) (names : List Text) (x : Tag)
    (ho : x.owner = me.id) (n : Text) (hn : n ∈ names) (hl : x.name_lower = lowerT n) :
    (namedA t names).holds (Snapshot.enc s) (Tag.row x) = true := by
  obtain ⟨k, hk, h1, h2⟩ := actorOf_ok ha h0
  rw [namedA_holds, mine_holds s t x.owner _ 1 (by simp [Tag.row])]
  simp only [Bool.and_eq_true, decide_eq_true_eq, List.any_eq_true]
  exact ⟨⟨k, hk, h1, h2.trans ho.symm⟩, n, hn, hl⟩

theorem create_bookmark_frame (f : BookmarkFields) (now : U64) :
    create_bookmark (Snapshot.load (callerA t ++ [⟨2, urlA t (orE f.url) (orE f.url_norm), {}⟩,
      ⟨3, namedA t (namesOf f.tags), {}⟩, ⟨6, .all, {}⟩]) s) t f now = create_bookmark s t f now := by
  have hs := (caller_slice s t [⟨2, urlA t (orE f.url) (orE f.url_norm), {}⟩,
      ⟨3, namedA t (namesOf f.tags), {}⟩, ⟨6, .all, {}⟩]).2
  generalize hp : callerA t ++ [⟨2, urlA t (orE f.url) (orE f.url_norm), {}⟩,
      ⟨3, namedA t (namesOf f.tags), {}⟩, ⟨6, .all, {}⟩] = plan at hs ⊢
  have hb : (Snapshot.load plan s).bookmarks.val = s.bookmarks.val.filter
      (fun x => (urlA t (orE f.url) (orE f.url_norm)).holds (Snapshot.enc s) (Bookmark.row x)) := by
    subst hp; simp [pickRows, callerA]
  have ht : (Snapshot.load plan s).tags.val = s.tags.val.filter
      (fun x => (namedA t (namesOf f.tags)).holds (Snapshot.enc s) (Tag.row x)) := by
    subst hp; simp [pickRows, callerA]
  have hc : (Snapshot.load plan s).counter = s.counter := by subst hp; simp [Snapshot.load, pickRows, callerA]
  unfold create_bookmark
  rw [hs, signed_in_eq]
  simp only [bind_ok]
  cases hme : signedOf s t with
  | Err e => rfl
  | Ok me =>
    obtain ⟨ha, -, h0⟩ := signedOf_ok hme
    dsimp only
    simp only [or_empty_eq, bind_tc_ok, bind_ok]
    rw [existing_slice hb me.id _ _ (fun x _ hx => url_keep s t ha h0 _ _ x hx)]
    have htw := fun id ws last => tag_writes_slice ht me.id id (f.tags.getD (alloc.vec.Vec.new Text)) now ws last
      (fun x _ ho n hn hl => named_keep s t ha h0 _ x ho n (by simpa [namesOf] using hn) hl)
    cases hft : f.tags with
    | none =>
      simp only [hft, Option.getD_none] at htw
      simp only [bind_tc_ok, bind_ok, hc, htw, set_counter]
    | some ns =>
      simp only [hft, Option.getD_some] at htw
      simp only [names_clone, bind_tc_ok, bind_ok, hc, htw, set_counter]

theorem update_bookmark_frame (id : U64) (f : BookmarkFields) (now : U64) :
    update_bookmark (Snapshot.load (callerA t ++
      [⟨2, (match f.url with | none => byIdA id | some u => .or (byIdA id) (.and (mineA 0 t) (eqB 3 u))), {}⟩,
       ⟨4, eqU 0 id, {}⟩, ⟨3, .or (.isIn 0 4 (eqU 0 id) 1 {}) (namedA t (namesOf f.tags)), {}⟩, ⟨6, .all, {}⟩]) s)
      t id f now = update_bookmark s t id f now := by
  generalize hd : (match f.url with | none => byIdA id | some u => .or (byIdA id) (.and (mineA 0 t) (eqB 3 u))) = dup
  have hs := (caller_slice s t [⟨2, dup, {}⟩, ⟨4, eqU 0 id, {}⟩,
    ⟨3, .or (.isIn 0 4 (eqU 0 id) 1 {}) (namedA t (namesOf f.tags)), {}⟩, ⟨6, .all, {}⟩]).2
  generalize hp : callerA t ++ [⟨2, dup, {}⟩, ⟨4, eqU 0 id, {}⟩,
    ⟨3, .or (.isIn 0 4 (eqU 0 id) 1 {}) (namedA t (namesOf f.tags)), {}⟩, ⟨6, .all, {}⟩] = plan at hs ⊢
  have hb : (Snapshot.load plan s).bookmarks.val = s.bookmarks.val.filter
      (fun x => dup.holds (Snapshot.enc s) (Bookmark.row x)) := by
    subst hp; simp [pickRows, callerA]
  have hl : (Snapshot.load plan s).links.val = s.links.val.filter
      (fun x => (eqU 0 id).holds (Snapshot.enc s) (Link.row x)) := by
    subst hp; simp [pickRows, callerA]
  have ht : (Snapshot.load plan s).tags.val = s.tags.val.filter
      (fun x => (Pred.or (.isIn 0 4 (eqU 0 id) 1 {}) (namedA t (namesOf f.tags))).holds (Snapshot.enc s) (Tag.row x)) := by
    subst hp; simp [pickRows, callerA]
  have hc : (Snapshot.load plan s).counter = s.counter := by subst hp; simp [Snapshot.load, pickRows, callerA]
  have hid : ∀ x, x.id = id → dup.holds (Snapshot.enc s) (Bookmark.row x) := by
    intro x hx; subst hd; cases f.url <;> simp [byIdA, eqU, Bookmark.row, hx]
  have ho := own_bookmark_slice hb id (fun x _ hx => hid x hx)
  have htn : tag_names (Snapshot.load plan s) id = tag_names s id :=
    tag_names_slice hl ht id (fun l _ hl' => by simp [eqU, Link.row, hl'])
      (fun l hlm hl' x _ hx => by
        simp only [holds_or, Bool.or_eq_true]; left
        simp only [holds_in_4]; simp [Tag.row, Link.row, eqU]; exact ⟨l, hlm, hl', hx.symm⟩)
  unfold update_bookmark
  rw [hs, signed_in_eq]
  simp only [bind_ok]
  cases hme : signedOf s t with
  | Err e => rfl
  | Ok me =>
    obtain ⟨ha, -, h0⟩ := signedOf_ok hme
    dsimp only
    rw [ho, own_bookmark_eq]
    simp only [bind_tc_ok, bind_ok]
    cases hf : s.bookmarks.val.find? (fun x => decide (x.id = id)) with
    | none => rfl
    | some b =>
      obtain ⟨hm, hi⟩ := find?_mem hf
      simp only [decide_eq_true_eq] at hi
      by_cases hob : b.owner = me.id
      · simp only [hob, if_true]
        have htw := fun i ws last => tag_writes_slice ht me.id i (f.tags.getD (alloc.vec.Vec.new Text)) now ws last
          (fun x _ ho n hn hl => by
            simp only [holds_or, Bool.or_eq_true]; right
            exact named_keep s t ha h0 _ x ho n (by simpa [namesOf] using hn) hl)
        have hut : ∀ u, f.url = some u → url_taken (Snapshot.load plan s) me.id u id = url_taken s me.id u id := by
          intro u hu
          refine url_taken_slice hb me.id u id (fun x _ hxo hxu => ?_)
          subst hd; rw [hu]
          obtain ⟨k, hk, h1, h2⟩ := actorOf_ok ha h0
          simp only [holds_or, holds_and, Bool.or_eq_true, Bool.and_eq_true]; right
          refine ⟨?_, by simp [eqB, Bookmark.row, hxu]⟩
          rw [mine_holds s t x.owner _ 0 (by simp [Bookmark.row])]; simp only [decide_eq_true_eq]
          exact ⟨k, hk, h1, h2.trans hxo.symm⟩
        rw [← hi] at htn
        cases hu : f.url with
        | none =>
          cases hft : f.tags with
          | none => simp only [hft, Option.getD_none] at htw; simp only [htn, htw, hc, set_counter]
          | some ns => simp only [hft, Option.getD_some] at htw; simp only [htn, htw, hc, set_counter]
        | some u =>
          simp only [hut u hu]
          cases hft : f.tags with
          | none => simp only [hft, Option.getD_none] at htw; simp only [htn, htw, hc, set_counter]
          | some ns => simp only [hft, Option.getD_some] at htw; simp only [htn, htw, hc, set_counter]
      · simp only [hob, if_false]

theorem create_tag_frame (n : Text) (now : U64) :
    create_tag (Snapshot.load (callerA t ++ [⟨3, namedA t [n], {}⟩, ⟨6, .all, {}⟩]) s) t n now = create_tag s t n now := by
  have hs := (caller_slice s t [⟨3, namedA t [n], {}⟩, ⟨6, .all, {}⟩]).2
  have ht : (Snapshot.load (callerA t ++ [⟨3, namedA t [n], {}⟩, ⟨6, .all, {}⟩]) s).tags.val = s.tags.val.filter
      (fun x => (namedA t [n]).holds (Snapshot.enc s) (Tag.row x)) := by simp [pickRows, callerA]
  have hc : (Snapshot.load (callerA t ++ [⟨3, namedA t [n], {}⟩, ⟨6, .all, {}⟩]) s).counter = s.counter := by
    simp [Snapshot.load, pickRows, callerA]
  unfold create_tag
  rw [hs, signed_in_eq]
  simp only [bind_ok]
  cases hme : signedOf s t with
  | Err e => rfl
  | Ok me =>
    obtain ⟨ha, -, h0⟩ := signedOf_ok hme
    dsimp only
    simp only [lower_text_total, bind_tc_ok, bind_ok]
    rw [find_tag_named_slice ht me.id _ (fun x _ ho hl => named_keep s t ha h0 [n] x ho n (by simp) hl)]
    simp only [hc, set_counter]

theorem list_tags_loop_spec (s : Snapshot) (me : User) :
    list_tags_loop s me (alloc.vec.Vec.new Tag) 0#usize ⦃ w => w.val = s.tags.val.filter (fun x => decide (x.owner = me.id)) ⦄ := by
  unfold list_tags_loop
  exact filter_loop_spec s.tags (fun x => x.owner = me.id) _ (fun x => Schema.Tag.clone_eq x) _ (fun out i => rfl)

theorem list_tags_frame (hk : Keys s) (lim off : U64) :
    list_tags (Snapshot.load (callerA t ++ [⟨3, mineA 1 t,
      ⟨false, 0, if lim.val > U64.rMax - off.val then none else some (off.val + lim.val)⟩⟩]) s) t lim off =
      list_tags s t lim off := by
  generalize hL : (if lim.val > U64.rMax - off.val then none else some (off.val + lim.val)) = L
  have hs := (caller_slice s t [⟨3, mineA 1 t, ⟨false, 0, L⟩⟩]).2
  have ht : (Snapshot.load (callerA t ++ [⟨3, mineA 1 t, ⟨false, 0, L⟩⟩]) s).tags.val =
      cut 0 L (s.tags.val.filter (fun x => (mineA 1 t).holds (Snapshot.enc s) (Tag.row x))) := by
    simp [pickRows, callerA, Window.apply]
  unfold list_tags
  rw [hs, signed_in_eq]
  simp only [bind_ok]
  cases hme : signedOf s t with
  | Err e => rfl
  | Ok me =>
    obtain ⟨ha, -, h0⟩ := signedOf_ok hme
    dsimp only
    obtain ⟨m1, hm1, hv1⟩ := (WP.spec_equiv_exists _ _).1 (list_tags_loop_spec (Snapshot.load (callerA t ++ [⟨3, mineA 1 t, ⟨false, 0, L⟩⟩]) s) me)
    obtain ⟨m2, hm2, hv2⟩ := (WP.spec_equiv_exists _ _).1 (list_tags_loop_spec s me)
    rw [hm1, hm2]; simp only [bind_tc_ok, bind_ok]
    obtain ⟨p1, hp1, hpv1⟩ := (WP.spec_equiv_exists _ _).1 (page_tags_spec m1 off lim)
    obtain ⟨p2, hp2, hpv2⟩ := (WP.spec_equiv_exists _ _).1 (page_tags_spec m2 off lim)
    rw [hp1, hp2]; simp only [bind_tc_ok, bind_ok]
    have hK : s.tags.val.filter (fun x => (mineA 1 t).holds (Snapshot.enc s) (Tag.row x)) =
        s.tags.val.filter (fun x => decide (x.owner = me.id)) :=
      List.filter_congr (fun x _ => mine_holds_iff hk ha h0 x.owner _ 1 (by simp [Tag.row]))
    rw [ht, hK] at hv1
    have : p1 = p2 := by
      apply alloc.vec.Vec.ext
      rw [hpv1, hpv2, hv1, hv2]
      subst hL
      split
      · simp [cut]
      · rename_i hno
        simp only [cut, List.drop_zero]
        rw [List.filter_eq_self.2 (fun x hx => (List.mem_filter.1 (List.mem_of_mem_take hx)).2),
          List.drop_take, List.take_take]
        congr 1; omega
    rw [this]

theorem list_scope_frame (hk : Keys s) (flt : Filter) (lim off : U64) (hsc : flt.scope ≠ SCOPE_SHARED)
    (hpg : pagedOf flt = false) :
    list_reply (Snapshot.load (callerA t ++ [⟨2, scopeA t flt.scope, {}⟩] ++ tagReadsA (scopeA t flt.scope) {} ++
      bundleReadA t flt.bundle) s) t flt lim off = list_reply s t flt lim off := by
  have hcall := caller_slice s t ([⟨2, scopeA t flt.scope, {}⟩] ++ tagReadsA (scopeA t flt.scope) {} ++
      bundleReadA t flt.bundle)
  simp only [List.append_assoc] at hcall ⊢
  generalize hp : callerA t ++ ([⟨2, scopeA t flt.scope, {}⟩] ++ (tagReadsA (scopeA t flt.scope) {} ++
      bundleReadA t flt.bundle)) = plan at hcall ⊢
  have hb : (Snapshot.load plan s).bookmarks.val =
      s.bookmarks.val.filter (fun x => (scopeA t flt.scope).holds (Snapshot.enc s) (Bookmark.row x)) := by
    subst hp; simp [pickRows, callerA, tagReadsA]
  have hl : (Snapshot.load plan s).links.val = s.links.val.filter
      (fun x => (Pred.isIn 0 2 (scopeA t flt.scope) 2 {}).holds (Snapshot.enc s) (Link.row x)) := by
    subst hp; simp [pickRows, callerA, tagReadsA]
  have ht : (Snapshot.load plan s).tags.val = s.tags.val.filter (fun x =>
      (Pred.isIn 0 4 (Pred.isIn 0 2 (scopeA t flt.scope) 2 {}) 1 {}).holds (Snapshot.enc s) (Tag.row x)) := by
    subst hp; simp [pickRows, callerA, tagReadsA]
  have hu : (Snapshot.load plan s).users.val = s.users.val.filter
      (fun x => (mineA 0 t).holds (Snapshot.enc s) (User.row x)) := by
    subst hp; simp [pickRows, callerA]
  have hbu : ∀ id, flt.bundle = some id → (Snapshot.load plan s).bundles.val = s.bundles.val.filter
      (fun x => (Pred.and (eqU 0 id) (mineA 1 t)).holds (Snapshot.enc s) (Bundle.row x)) := by
    intro id hid; subst hp; simp [pickRows, callerA, tagReadsA, bundleReadA, hid]
  have hsc' : (flt.scope != SCOPE_SHARED) = true := by simpa using hsc
  unfold list_reply
  rw [hcall.1, eq_ok_of_spec (actor_spec s t)]
  simp only [bind_ok]
  cases ha : actorOf s t with
  | Err e => rfl
  | Ok v =>
    dsimp only
    split
    · simp only [hsc', if_true]
    · rename_i h0
      obtain ⟨k0, hk0, hk1, hk2⟩ := actorOf_ok ha h0
      -- the bookmarks of the scope
      have hKB : ∀ b : Bookmark, (scopeA t flt.scope).holds (Snapshot.enc s) (Bookmark.row b) =
          decide (b.owner = v ∧ b.archived = decide (flt.scope = SCOPE_ARCHIVED)) := by
        intro b
        rw [scopeA, holds_and, mine_holds_iff hk ha h0 b.owner (Bookmark.row b) 0 (by simp [Bookmark.row])]
        simp [eqT, Bookmark.row]
      have hof : owner_filter_of (Snapshot.load plan s) flt = owner_filter_of s flt := by
        unfold owner_filter_of; simp [hsc']
      rw [list_ctx_slice flt v (find_user_viewer_slice hk hu (fun x _ h => h) ha) hof
        (bundle_of_slice hk flt ha hbu)]
      apply bind_congr_ok; intro ctx hctx
      obtain ⟨hcv, -, -, hpgc, -⟩ := list_ctx_ok hctx
      have hcp : ctx.paged = false := by have := pagedOf_eq hpgc; rw [hpg] at this; exact this.symm
      have hkl : ∀ b, b.owner = v → b.archived = decide (flt.scope = SCOPE_ARCHIVED) → b ∈ s.bookmarks.val →
          ∀ l ∈ s.links.val, l.bookmark = b.id →
            (Pred.isIn 0 2 (scopeA t flt.scope) 2 {}).holds (Snapshot.enc s) (Link.row l) := by
        intro b h1 h2 hbm l _ hl'
        simp only [holds_in_2, Link.row]; simp only [List.getElem?_cons_zero, Window.apply_default]
        simp only [List.any_eq_true, List.mem_filter, decide_eq_true_eq]
        exact ⟨b, ⟨hbm, by rw [hKB]; simp [h1, h2]⟩, by simp [Bookmark.row, hl']⟩
      have hkt : ∀ b, b.owner = v → b.archived = decide (flt.scope = SCOPE_ARCHIVED) → b ∈ s.bookmarks.val →
          ∀ l ∈ s.links.val, l.bookmark = b.id → ∀ x ∈ s.tags.val, x.id = l.tag →
            (Pred.isIn 0 4 (Pred.isIn 0 2 (scopeA t flt.scope) 2 {}) 1 {}).holds (Snapshot.enc s) (Tag.row x) := by
        intro b h1 h2 hbm l hlm hl' x _ hx
        simp only [holds_in_4, Tag.row]; simp only [List.getElem?_cons_zero, Window.apply_default]
        simp only [List.any_eq_true, List.mem_filter, decide_eq_true_eq]
        exact ⟨l, ⟨hlm, hkl b h1 h2 hbm l hlm hl'⟩, by simp [Link.row, hx]⟩
      have hsel : select (Snapshot.load plan s) flt ctx = select s flt ctx := by
        refine select_slice hb flt ctx (fun b _ hkb => ?_) (fun b hbm hkb => ?_)
        · rw [hKB] at hkb
          unfold keep in_scope
          simp only [hsc, if_false, hcv]
          by_cases ho : b.owner = v
          · have : ¬ b.archived = decide (flt.scope = SCOPE_ARCHIVED) := fun e => by simp [ho, e] at hkb
            simp [ho, this]
          · simp [ho]
        · rw [hKB] at hkb
          simp only [decide_eq_true_eq] at hkb
          unfold keep
          have his : in_scope (Snapshot.load plan s) flt ctx b = in_scope s flt ctx b := by
            unfold in_scope; simp only [hsc, if_false]
          rw [his, hcp]
          simp only [Bool.false_eq_true, if_false]
          rw [selected_slice _ _ _ _ _ _ b (tag_lowers_slice hl ht b.id
            (hkl b hkb.1 hkb.2 hbm) (hkt b hkb.1 hkb.2 hbm))]
      rw [hsel]
      apply bind_congr_ok; intro sel hsel'
      have hmem := select_ok hsel'
      apply bind_congr_ok; intro sorted hsorted
      have hsm : ∀ b ∈ sorted.val, b ∈ sel.val := by
        repeat' split at hsorted
        all_goals first
          | exact sort_ok _ _ _ hsorted
          | (intro b hb'; rw [post_of_ok (reversed_spec sel) hsorted, List.mem_reverse] at hb'; exact hb')
      apply bind_congr_ok; intro page hpage
      have hpm : ∀ b ∈ page.val, b ∈ sel.val := by
        intro b hb'
        rw [post_of_ok (page_bookmarks_spec sorted off lim) hpage] at hb'
        exact hsm b (List.mem_of_mem_drop (List.mem_of_mem_take hb'))
      rw [views_slice page (fun b hb' => by
        obtain ⟨hbm, hkeep⟩ := hmem b (hpm b hb')
        unfold keep in_scope at hkeep
        simp only [hsc, if_false, hcv] at hkeep
        by_cases ho : b.owner = v
        · by_cases har : b.archived = decide (flt.scope = SCOPE_ARCHIVED)
          · exact view_slice hl ht b (hkl b ho har hbm) (hkt b ho har hbm)
          · simp [ho, har] at hkeep
        · simp [ho] at hkeep)]

end Commands

end linkding_kernel.Frame
