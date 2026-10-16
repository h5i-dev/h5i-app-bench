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

end Commands

end linkding_kernel.Frame
