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

end Commands

end linkding_kernel.Frame
