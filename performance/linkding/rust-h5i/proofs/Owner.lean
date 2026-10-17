import Helpers
import ReadOnly
/-!
# Writes touch only the caller's rows

`writes_own`: every write of an accepted command creates, changes or deletes
only rows that belong to the user the token names (`OwnWrite`). Links join
one of the caller's bookmarks, written in the same write set, to one of the
caller's tags, existing or written in the same write set.

`get_bookmark_owned`, `get_tag_owned`, `get_bundle_owned`: a lookup by id
replies only with a row of the caller's.

Stated over the extracted `transition`, for every state and command; the
read-only commands write nothing (`ReadOnly.lean`).
-/
open Aeneas Aeneas.Std Result linkding_kernel linkding_kernel.Spec linkding_kernel.Helpers H5iAppLib

namespace linkding_kernel.Owner

/-- What `tag_writes` adds to a write set `out`: the owner's new tags, and
links from bookmark `id` to the owner's tags. -/
def TagWrite (s : Snapshot) (owner id : U64) (out : List Write) (w : Write) : Prop :=
  (∃ t, w = .PutTag t ∧ t.owner = owner) ∨
  (∃ l, w = .PutLink l ∧ l.bookmark = id ∧
    ∃ t, t.id = l.tag ∧ t.owner = owner ∧ (t ∈ s.tags.val ∨ .PutTag t ∈ out))

theorem tagWrite_mono {s owner id out out' w} (hs : ∀ x ∈ out, x ∈ out') (h : TagWrite s owner id out w) :
    TagWrite s owner id out' w := by
  rcases h with h | ⟨l, rfl, hb, t, ht, ho, hm⟩
  · exact .inl h
  · exact .inr ⟨l, rfl, hb, t, ht, ho, hm.imp (fun x => x) (hs _)⟩

/-- The loop's state: what it has written keeps the starting writes, adds
only `TagWrite`s, and every tag it made is written. -/
def TwInv (s : Snapshot) (owner id : U64) (ws : List Write) (out : List Write) (made : List Tag) : Prop :=
  (∀ w ∈ ws, w ∈ out) ∧ (∀ w ∈ out, w ∈ ws ∨ TagWrite s owner id out w) ∧
    (∀ t ∈ made, t.owner = owner ∧ .PutTag t ∈ out)

theorem tag_writes_loop_ok (s : Snapshot) (owner id : U64) (names : alloc.vec.Vec (alloc.vec.Vec U8)) (now : U64)
    (ws : List Write) :
    ∀ out shown made next i r,
      TwInv s owner id ws out.val made.val →
      tag_writes_loop s owner id names now out shown made next i = ok r →
      TwInv s owner id ws r.1.val [] := by
  intro out shown made next i r hinv h
  unfold tag_writes_loop at h
  refine loop_ok _ (fun x : (alloc.vec.Vec Write) × (alloc.vec.Vec (alloc.vec.Vec U8)) × (alloc.vec.Vec Tag) × U64 × Usize =>
      TwInv s owner id ws x.1.val x.2.2.1.val)
    (fun y => TwInv s owner id ws y.1.val []) (fun x => names.length - x.2.2.2.2.val) ?_ _ _ hinv h
  rintro ⟨out, shown, made, next, i⟩ c hI hb
  unfold tag_writes_loop.body at hb
  h5i_invert hb
  · simp only [] at hI ⊢
    have ho' := eq_ok_of_spec (find_tag_named_spec s.tags owner lower)
    rw [ho'] at ho; simp only [ok.injEq] at ho; subst ho
    -- The tag: found (the caller's, existing or made in this loop) or new.
    have key : (∀ w ∈ out.val, w ∈ out1.val) ∧ TwInv s owner id ws out1.val made1.val ∧
        t.owner = owner ∧ (t ∈ s.tags.val ∨ .PutTag t ∈ out1.val) := by
      rcases hfo : s.tags.val.find? (fun t => t.owner = owner ∧ t.name_lower = lower) with _ | t0 <;>
        rw [hfo] at hfound <;> simp only at hfound
      · have hm := eq_ok_of_spec (find_tag_named_spec made owner lower)
        rw [hm] at hfound; simp only [ok.injEq] at hfound; subst hfound
        rcases hfm : made.val.find? (fun t => t.owner = owner ∧ t.name_lower = lower) with _ | t1 <;>
          simp only [hfm, core.option.Option.is_none, Option.isNone_none, Option.isNone_some, ite_true, ite_false, Bool.false_eq_true, if_true, if_false] at hnext1 ht hout1 hmade1
        · -- New tag.
          h5i_invert ht
          h5i_invert hout1
          h5i_invert hmade1
          have e1 := tag_clone_ok ht1
          have e1' := tag_clone_ok ht1_1
          subst e1 e1'
          have e2 := push_ok hout1
          have e3 := push_ok hmade1
          rw [e2, e3]
          refine ⟨fun w hw => List.mem_append_left _ hw, ⟨fun w hw => List.mem_append_left _ (hI.1 w hw), ?_, ?_⟩,
            rfl, .inr (by simp)⟩
          · intro w hw
            rcases List.mem_append.1 hw with hw | hw
            · exact (hI.2.1 w hw).imp (fun x => x) (tagWrite_mono (fun x hx => List.mem_append_left _ hx))
            · simp at hw; subst hw; exact .inr (.inl ⟨_, rfl, rfl⟩)
          · intro t' ht'
            rcases List.mem_append.1 ht' with ht' | ht'
            · exact ⟨(hI.2.2 t' ht').1, List.mem_append_left _ (hI.2.2 t' ht').2⟩
            · simp at ht'; subst ht'; exact ⟨rfl, by simp⟩
        · -- A tag this loop made.
          simp only [ok.injEq] at ht hout1 hmade1
          subst ht hout1 hmade1
          have := List.find?_some hfm; simp at this
          have hmem := List.mem_of_find?_eq_some hfm
          exact ⟨fun w hw => hw, hI, this.1, .inr (hI.2.2 t1 hmem).2⟩
      · -- One of the caller's tags.
        simp only [ok.injEq] at hfound; subst hfound
        simp only [core.option.Option.is_none, Option.isNone_some, ite_false, if_false, Bool.false_eq_true, ok.injEq] at ht hout1 hmade1
        subst ht hout1 hmade1
        have := List.find?_some hfo; simp at this
        exact ⟨fun w hw => hw, hI, this.1, .inl (List.mem_of_find?_eq_some hfo)⟩
    obtain ⟨hmono, hI1, hto, htm⟩ := key
    have hlen : i2.val = i.val + 1 := by h5i_arith
    have hlt : i.val < names.length := by scalar_tac
    refine ⟨?_, by simp only [hlen]; omega⟩
    split at hout2
    · simp only [ok.injEq] at hout2; subst hout2; exact hI1
    · have e := push_ok hout2
      rw [e]
      refine ⟨fun w hw => List.mem_append_left _ (hI1.1 w hw), ?_,
        fun t' ht' => ⟨(hI1.2.2 t' ht').1, List.mem_append_left _ (hI1.2.2 t' ht').2⟩⟩
      intro w hw
      rcases List.mem_append.1 hw with hw | hw
      · exact (hI1.2.1 w hw).imp (fun x => x) (tagWrite_mono (fun x hx => List.mem_append_left _ hx))
      · simp at hw; subst hw
        exact .inr (.inr ⟨_, rfl, rfl, t, rfl, hto, htm.imp (fun x => x) (fun x => List.mem_append_left _ x)⟩)
  · simp only []
    exact ⟨hI.1, hI.2.1, by simp⟩

theorem tag_writes_ok (s : Snapshot) (owner id : U64) (names : alloc.vec.Vec (alloc.vec.Vec U8)) (now : U64)
    (ws : alloc.vec.Vec Write) (last : U64) out shown next
    (h : tag_writes s owner id names now ws last = ok (.Ok (out, shown, next))) :
    TwInv s owner id ws.val out.val [] := by
  unfold tag_writes at h
  h5i_invert h
  have := tag_writes_loop_ok s owner id names now ws.val ws _ _ _ _ _ ⟨fun w hw => hw, fun w hw => .inl hw, by simp⟩ hx
  obtain ⟨o1, s1, n1⟩ := x
  -- A match on a tuple: restate `h` at its reduced type.
  have h' : (ok (.Ok (o1, s1, n1)) : Result (core.result.Result _ Error)) = ok (.Ok (out, shown, next)) := h
  simp only [ok.injEq, core.result.Result.Ok.injEq, Prod.mk.injEq] at h'
  obtain ⟨rfl, rfl, rfl⟩ := h'
  exact this

/-! ## The caller's rows -/

theorem own_bookmark_ok (s : Snapshot) (me : User) (id : U64) (b : Bookmark)
    (h : own_bookmark s me id = ok (.Ok b)) : b ∈ s.bookmarks.val ∧ b.owner = me.id ∧ b.id = id := by
  unfold own_bookmark at h
  h5i_invert h
  rw [eq_ok_of_spec (find_bookmark_spec _ _)] at ho
  simp only [ok.injEq] at ho
  have := List.find?_some ho
  simp at this
  exact ⟨List.mem_of_find?_eq_some ho, hc, this⟩

theorem own_tag_ok (s : Snapshot) (me : User) (id : U64) (t : Tag)
    (h : own_tag s me id = ok (.Ok t)) : t ∈ s.tags.val ∧ t.owner = me.id ∧ t.id = id := by
  unfold own_tag at h
  h5i_invert h
  rw [eq_ok_of_spec (find_tag_spec _ _)] at ho
  simp only [ok.injEq] at ho
  have := List.find?_some ho
  simp at this
  exact ⟨List.mem_of_find?_eq_some ho, hc, this⟩

theorem own_bundle_ok (s : Snapshot) (me : User) (id : U64) (b : Bundle)
    (h : own_bundle s me id = ok (.Ok b)) : b ∈ s.bundles.val ∧ b.owner = me.id ∧ b.id = id := by
  unfold own_bundle at h
  h5i_invert h
  rw [eq_ok_of_spec (find_bundle_spec _ _)] at ho
  simp only [ok.injEq] at ho
  have := List.find?_some ho
  simp at this
  exact ⟨List.mem_of_find?_eq_some ho, hc, this⟩

/-! ## Lookups that return the caller's rows -/

theorem index_mem {α : Type} (v : alloc.vec.Vec α) (i : Usize) (b : α)
    (h : alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice α) v i = ok b) : b ∈ v.val := by
  rw [alloc.vec.Vec.index_slice_index] at h
  unfold alloc.vec.Vec.index_usize at h
  split at h
  · simp at h
  · rename_i x hx
    simp only [ok.injEq] at h; subst h
    exact List.mem_of_getElem? hx

theorem same_url_owner (b : Bookmark) (owner : U64) (u n : alloc.vec.Vec U8)
    (h : same_url b owner u n = ok true) : b.owner = owner := by
  unfold same_url at h
  split at h
  · assumption
  · simp at h

theorem find_same_url_ok (s : Snapshot) (owner : U64) (u n : alloc.vec.Vec U8) (id : U64) (b : Bookmark)
    (h : find_same_url s owner u n id = ok (some b)) : b ∈ s.bookmarks.val ∧ b.owner = owner := by
  unfold find_same_url find_same_url_loop at h
  refine loop_ok _ (fun _ => True) (fun o => ∀ b, o = some b → b ∈ s.bookmarks.val ∧ b.owner = owner)
    (fun i : Usize => s.bookmarks.length - i.val) ?_ _ _ trivial h b rfl
  intro i c _ hb
  unfold find_same_url_loop.body at hb
  h5i_invert hb
  · intro b' hb'
    simp only [Option.some.injEq] at hb'
    subst hb'
    have e := bookmark_clone_ok hb2; subst e
    exact ⟨index_mem _ _ _ hb_1, same_url_owner _ _ _ _ (hc_2 ▸ hb1)⟩
  all_goals first
    | (simp; done)
    | (refine ⟨trivial, ?_⟩; have : i.val < s.bookmarks.length := by scalar_tac
       have : i2.val = i.val + 1 := by h5i_arith
       omega)

theorem existing_ok (s : Snapshot) (owner : U64) (u n : alloc.vec.Vec U8) (b : Bookmark)
    (h : existing s owner u n = ok (some b)) : b ∈ s.bookmarks.val ∧ b.owner = owner := by
  unfold existing at h
  h5i_invert h
  -- The loop hands back the snapshot's bookmarks unchanged.
  have hl : x.2.2.2.1 = s.bookmarks := by
    unfold existing_loop at hx
    refine loop_ok _ (fun _ => True) (fun y => y.2.2.2.1 = s.bookmarks)
      (fun st : Bool × U64 × Usize => s.bookmarks.length - st.2.2.val) ?_ _ _ trivial hx
    rintro ⟨found, best, i⟩ c _ hb
    unfold existing_loop.body at hb
    h5i_invert hb
    all_goals first
      | (simp; done)
      | (refine ⟨trivial, ?_⟩; have : i.val < s.bookmarks.length := by scalar_tac
         have : i2.val = i.val + 1 := by h5i_arith
         simp only; omega)
  obtain ⟨c, v, v1, v2, v3, v4, v5, found, best⟩ := x
  simp only at hl; subst hl
  have h' : (if found = true then find_same_url (Snapshot.mk c v v1 s.bookmarks v3 v4 v5) owner u n best
    else ok none) = ok (some b) := h
  split at h'
  · exact find_same_url_ok _ _ _ _ _ _ h'
  · simp at h'

/-! ## Bundles -/

theorem renumbered_ok (ws : alloc.vec.Vec Write) (x : Bundle) (pos : U64) (out : alloc.vec.Vec Write)
    (h : renumbered ws x pos = ok out) :
    ∃ y, out.val = ws.val ++ [.PutBundle y] ∧ y.owner = x.owner ∧ y.id = x.id := by
  unfold renumbered at h
  h5i_invert h
  have e := bundle_clone_ok hy; subst e
  exact ⟨_, push_ok h, rfl, rfl⟩

/-- What the renumbering loop of `delete_bundle` adds: bundles of `mine`, moved. -/
def Renum (mine : List Bundle) (ws : List Write) (w : Write) : Prop :=
  w ∈ ws ∨ ∃ y x, w = .PutBundle y ∧ x ∈ mine ∧ y.owner = x.owner ∧ y.id = x.id

theorem delete_bundle_loop_ok (id : U64) (mine : alloc.vec.Vec Bundle) (ws0 : List Write) :
    ∀ ws pos i r, (∀ w ∈ ws.val, Renum mine.val ws0 w) →
      delete_bundle_loop id mine ws pos i = ok r → ∀ w ∈ r.val, Renum mine.val ws0 w := by
  intro ws pos i r hinv h
  unfold delete_bundle_loop at h
  refine loop_ok _ (fun st : (alloc.vec.Vec Write) × U64 × Usize => ∀ w ∈ st.1.val, Renum mine.val ws0 w)
    (fun r => ∀ w ∈ r.val, Renum mine.val ws0 w) (fun st => mine.length - st.2.2.val) ?_ _ _ hinv h
  rintro ⟨ws, pos, i⟩ c hI hb
  unfold delete_bundle_loop.body at hb
  h5i_invert hb
  · have hlt : i.val < mine.length := by scalar_tac
    have : i3.val = i.val + 1 := by h5i_arith
    refine ⟨?_, by simp only; omega⟩
    split at hws1
    · obtain ⟨y, hy, ho, hid⟩ := renumbered_ok _ _ _ _ hws1
      intro w hw
      rw [hy] at hw
      rcases List.mem_append.1 hw with hw | hw
      · exact hI w hw
      · simp at hw; subst hw; exact .inr ⟨y, b, rfl, index_mem _ _ _ hb_1, ho, hid⟩
    · simp only [ok.injEq] at hws1; subst hws1; exact hI
  · exact hI

theorem insert_bundle_ok (v : alloc.vec.Vec Bundle) (x : Bundle) (w : alloc.vec.Vec Bundle)
    (h : insert_bundle v x = ok w) : ∀ y ∈ w.val, y ∈ v.val ∨ y = x := by
  unfold insert_bundle at h
  h5i_invert h
  have hl : ∀ y ∈ x_1.1.val, y ∈ v.val ∨ y = x := by
    unfold insert_bundle_loop at hx_1
    refine loop_ok _ (fun st : (alloc.vec.Vec Bundle) × Bool × Usize => ∀ y ∈ st.1.val, y ∈ v.val ∨ y = x)
      (fun r => ∀ y ∈ r.1.val, y ∈ v.val ∨ y = x) (fun st => v.length - st.2.2.val) ?_ _ _ (by simp) hx_1
    rintro ⟨out, placed, i⟩ c hI hb
    unfold insert_bundle_loop.body at hb
    h5i_invert hb
    · have hlt : i.val < v.length := by scalar_tac
      have : i2.val = i.val + 1 := by h5i_arith
      refine ⟨?_, by simp only; omega⟩
      have e1 := bundle_clone_ok hb1; subst e1
      rw [push_ok hout2]
      intro y hy
      rcases List.mem_append.1 hy with hy | hy
      · split at hout1
        · h5i_invert hout1
          have e2 := bundle_clone_ok ‹Bundle.Insts.CoreCloneClone.clone x = ok _›; subst e2
          rw [push_ok hout1] at hy
          rcases List.mem_append.1 hy with hy | hy
          · exact hI y hy
          · simp at hy; exact .inr hy
        · simp only [ok.injEq] at hout1; subst hout1; exact hI y hy
      · simp at hy; subst hy; exact .inl (index_mem _ _ _ hb_1)
    · exact hI
  obtain ⟨out, placed⟩ := x_1
  have h' : (if placed = true then ok out else do
      let b ← Bundle.Insts.CoreCloneClone.clone x
      alloc.vec.Vec.push out b) = ok w := h
  split at h'
  · simp only [ok.injEq] at h'; subst h'; exact hl
  · h5i_invert h'
    have e := bundle_clone_ok hb; subst e
    rw [push_ok h']
    intro y hy
    rcases List.mem_append.1 hy with hy | hy
    · exact hl y hy
    · simp at hy; exact .inr hy

theorem bundles_of_ok (s : Snapshot) (owner : U64) (r : alloc.vec.Vec Bundle) (h : bundles_of s owner = ok r) :
    ∀ b ∈ r.val, b ∈ s.bundles.val ∧ b.owner = owner := by
  unfold bundles_of bundles_of_loop at h
  refine loop_ok _ (fun st : (alloc.vec.Vec Bundle) × Usize => ∀ b ∈ st.1.val, b ∈ s.bundles.val ∧ b.owner = owner)
    (fun r => ∀ b ∈ r.val, b ∈ s.bundles.val ∧ b.owner = owner) (fun st => s.bundles.length - st.2.val) ?_ _ _
    (by simp) h
  rintro ⟨out, i⟩ c hI hb
  unfold bundles_of_loop.body at hb
  h5i_invert hb
  · have hlt : i.val < s.bundles.length := by scalar_tac
    have : i2.val = i.val + 1 := by h5i_arith
    refine ⟨?_, by simp only; omega⟩
    have hbm := index_mem _ _ _ hb_1
    split at hout1
    · intro y hy
      rcases insert_bundle_ok _ _ _ hout1 y hy with hy | rfl
      · exact hI y hy
      · exact ⟨hbm, by assumption⟩
    · simp only [ok.injEq] at hout1; subst hout1; exact hI
  · exact hI

/-! ## The theorem -/

/-- A write of user `u` in write set `ws` on state `s`: it creates or
changes rows owned by `u`, or deletes rows of `s` owned by `u`. A link joins
a bookmark `u` writes in `ws` to a tag of `u`, existing or written in `ws`. -/
def OwnWrite (s : Snapshot) (u : U64) (ws : List Write) : Write → Prop
  | .PutBookmark b => b.owner = u
  | .DelBookmark o _ _ => o = u
  | .PutTag t => t.owner = u
  | .DelTag id => ∃ t ∈ s.tags.val, t.id = id ∧ t.owner = u
  | .PutLink l => (∃ b, .PutBookmark b ∈ ws ∧ b.id = l.bookmark ∧ b.owner = u) ∧
      ∃ t, t.id = l.tag ∧ t.owner = u ∧ (t ∈ s.tags.val ∨ .PutTag t ∈ ws)
  | .DelLinksOf id => ∃ b ∈ s.bookmarks.val, b.id = id ∧ b.owner = u
  | .DelLinksTo id => ∃ t ∈ s.tags.val, t.id = id ∧ t.owner = u
  | .PutBundle b => b.owner = u
  | .DelBundle id => ∃ b ∈ s.bundles.val, b.id = id ∧ b.owner = u
  | .SetCounter _ => True

/-- What a command writes, as `writes_own` states it for each command. -/
def AllOwn (s : Snapshot) (u : U64) (ws : List Write) : Prop := ∀ w ∈ ws, OwnWrite s u ws w

theorem ownWrite_mono {s u ws ws' w} (hs : ∀ x ∈ ws, x ∈ ws') (h : OwnWrite s u ws w) : OwnWrite s u ws' w := by
  cases w with
  | PutLink l =>
    obtain ⟨⟨b, hb, h1, h2⟩, t, h3, h4, h5⟩ := h
    exact ⟨⟨b, hs _ hb, h1, h2⟩, t, h3, h4, h5.imp id (hs _)⟩
  | _ => exact h

/-- The caller of a command that signed in as `me`. -/
theorem me_eq {s : Snapshot} {t : alloc.vec.Vec U8} {me : User} {u : U64} (h : signed_in s t = ok (.Ok me))
    (ha : actorOf s t = .Ok u) : me.id = u := by
  have := (signed_in_ok _ _ _ h).1
  rw [ha] at this
  simp only [core.result.Result.Ok.injEq] at this
  exact this.symm

theorem delete_bookmark_own (s : Snapshot) (tk : alloc.vec.Vec U8) (id : U64) out rp u
    (h : delete_bookmark s tk id = ok (.Ok (out, rp))) (ha : actorOf s tk = .Ok u) : AllOwn s u out.val := by
  unfold delete_bookmark at h
  h5i_invert h
  obtain ⟨rfl, rfl⟩ := h
  have := me_eq hr ha; subst this
  obtain ⟨hm, ho, -⟩ := own_bookmark_ok _ _ _ _ hr1
  rw [push_ok hws1, push_ok hws]
  simp [AllOwn, OwnWrite]
  exact ⟨⟨_, hm, rfl, ho⟩, ho⟩


theorem one_ok {w : Write} {v : alloc.vec.Vec Write} (h : one w = ok v) : v.val = [w] := by
  unfold one at h; simpa using push_ok h

theorem archive_own (s : Snapshot) (tk : alloc.vec.Vec U8) (id : U64) (arch : Bool) (now : U64) out rp u
    (h : archive s tk id arch now = ok (.Ok (out, rp))) (ha : actorOf s tk = .Ok u) : AllOwn s u out.val := by
  unfold archive at h
  h5i_invert h
  obtain ⟨rfl, rfl⟩ := h
  have := me_eq hr ha; subst this
  obtain ⟨-, ho, -⟩ := own_bookmark_ok _ _ _ _ hr1
  rw [one_ok hv7]
  simp [AllOwn, OwnWrite, ho]

theorem delete_tag_own (s : Snapshot) (tk : alloc.vec.Vec U8) (id : U64) out rp u
    (h : delete_tag s tk id = ok (.Ok (out, rp))) (ha : actorOf s tk = .Ok u) : AllOwn s u out.val := by
  unfold delete_tag at h
  h5i_invert h
  obtain ⟨rfl, rfl⟩ := h
  have := me_eq hr ha; subst this
  obtain ⟨hm, ho, -⟩ := own_tag_ok _ _ _ _ hr1
  rw [push_ok hws1, push_ok hws]
  simp [AllOwn, OwnWrite]
  exact ⟨_, hm, rfl, ho⟩

theorem create_tag_own (s : Snapshot) (tk : alloc.vec.Vec U8) (nm : alloc.vec.Vec U8) (now : U64) out rp u
    (h : create_tag s tk nm now = ok (.Ok (out, rp))) (ha : actorOf s tk = .Ok u) : AllOwn s u out.val := by
  unfold create_tag at h
  h5i_invert h
  all_goals obtain ⟨rfl, rfl⟩ := h
  all_goals have := me_eq hr ha; subst this
  · have e := tag_clone_ok ht; subst e
    rw [push_ok hws1, push_ok hws]
    simp [AllOwn, OwnWrite, set_counter] at hw ⊢
    subst hw; simp
  · simp [AllOwn]

theorem update_bundle_own (s : Snapshot) (tk : alloc.vec.Vec U8) (id : U64) (f : BundleFields) (now : U64) out rp u
    (h : update_bundle s tk id f now = ok (.Ok (out, rp))) (ha : actorOf s tk = .Ok u) : AllOwn s u out.val := by
  unfold update_bundle at h
  h5i_invert h
  all_goals obtain ⟨rfl, rfl⟩ := h
  all_goals have := me_eq hr ha; subst this
  obtain ⟨-, ho, -⟩ := own_bundle_ok _ _ _ _ hr1
  have e := bundle_clone_ok hb; subst e
  rw [one_ok hv9]; simp [AllOwn, OwnWrite, ho]

theorem create_bundle_own (s : Snapshot) (tk : alloc.vec.Vec U8) (f : BundleFields) (now : U64) out rp u
    (h : create_bundle s tk f now = ok (.Ok (out, rp))) (ha : actorOf s tk = .Ok u) : AllOwn s u out.val := by
  unfold create_bundle at h
  h5i_invert h
  all_goals obtain ⟨rfl, rfl⟩ := h
  all_goals have := me_eq hr ha; subst this
  all_goals first
    | (have e := bundle_clone_ok hb; subst e
       rw [push_ok hws1, push_ok hws]
       simp [AllOwn, OwnWrite])

theorem delete_bundle_own (s : Snapshot) (tk : alloc.vec.Vec U8) (id : U64) out rp u
    (h : delete_bundle s tk id = ok (.Ok (out, rp))) (ha : actorOf s tk = .Ok u) : AllOwn s u out.val := by
  unfold delete_bundle at h
  h5i_invert h
  all_goals obtain ⟨rfl, rfl⟩ := h
  have := me_eq hr ha; subst this
  obtain ⟨hm, ho, -⟩ := own_bundle_ok _ _ _ _ hr1
  have hmine := bundles_of_ok _ _ _ hmine1
  have hl := delete_bundle_loop_ok _ _ [.DelBundle v1.id] _ _ _ _ (by rw [one_ok hws]; intro w hw; exact .inl hw) hws1
  intro w hw
  rcases hl w hw with hw0 | ⟨y, x, rfl, hx, hyo, -⟩
  · simp at hw0; subst hw0; exact ⟨_, hm, rfl, ho⟩
  · show y.owner = _
    rw [hyo]; exact (hmine x hx).2


/-- A write set made by `tag_writes` from `ws0` for bookmark `id`, with the
counter set after: the caller's if `ws0` is and writes bookmark `id`. -/
theorem tw_own (s : Snapshot) (u id : U64) (ws0 out : List Write) (c : Write) (hc : ∃ k, c = .SetCounter k)
    (htw : TwInv s u id ws0 out []) (hb : ∃ b, .PutBookmark b ∈ ws0 ∧ b.id = id ∧ b.owner = u)
    (h0 : ∀ w ∈ ws0, OwnWrite s u (out ++ [c]) w) : AllOwn s u (out ++ [c]) := by
  obtain ⟨k, rfl⟩ := hc
  obtain ⟨b, hbm, hbi, hbo⟩ := hb
  intro w hw
  rcases List.mem_append.1 hw with hw | hw
  · rcases htw.2.1 w hw with hw0 | ⟨t, rfl, ho⟩ | ⟨l, rfl, hl, t, ht, ho, hm⟩
    · exact h0 w hw0
    · exact ho
    · exact ⟨⟨b, List.mem_append_left _ (htw.1 _ hbm), hbi.trans hl.symm, hbo⟩, t, ht, ho,
        hm.imp (fun x => x) (List.mem_append_left _)⟩
  · simp at hw; subst hw; trivial

theorem set_counter_is (s : Snapshot) (a b : U64) (w : Write) (h : set_counter s a b = ok w) :
    ∃ k, w = .SetCounter k := by
  simp [set_counter] at h; exact ⟨_, h.symm⟩

theorem create_bookmark_own (s : Snapshot) (tk : alloc.vec.Vec U8) (f : BookmarkFields) (now : U64) out rp u
    (h : create_bookmark s tk f now = ok (.Ok (out, rp))) (ha : actorOf s tk = .Ok u) : AllOwn s u out.val := by
  unfold create_bookmark at h
  h5i_invert h
  · obtain ⟨o1, s1, n1⟩ := v4
    change (do let w ← set_counter s i1 n1; let ws2 ← o1.push w; ok (core.result.Result.Ok (ws2, _))) = _ at h
    h5i_invert h
    obtain ⟨rfl, rfl⟩ := h
    have := me_eq hr ha; subst this
    have e := bookmark_clone_ok hb3
    have htw := tag_writes_ok _ _ _ _ _ _ _ _ _ _ hr1
    rw [one_ok hws] at htw
    rw [push_ok hws2]
    refine tw_own _ _ _ _ _ _ (set_counter_is _ _ _ _ hw) htw ⟨b3, by simp, by rw [e], by rw [e]⟩ ?_
    intro w hw; simp at hw; subst hw; rw [e]; rfl
  · obtain ⟨o1, s1, n1⟩ := v4_1
    change (do let w ← set_counter s s.counter.last_bookmark n1; let ws3 ← o1.push w; ok (core.result.Result.Ok (ws3, _))) = _ at h
    h5i_invert h
    obtain ⟨rfl, rfl⟩ := h
    have := me_eq hr ha; subst this
    have e := bookmark_clone_ok hb3
    obtain ⟨hxm, hxo⟩ := existing_ok _ _ _ _ _ ho
    have htw := tag_writes_ok _ _ _ _ _ _ _ _ _ _ hr1
    rw [push_ok hws1, push_ok hws] at htw
    rw [push_ok hws3]
    refine tw_own _ _ _ _ _ _ (set_counter_is _ _ _ _ hw) htw ⟨b3, by simp, by rw [e], by rw [e]; exact hxo⟩ ?_
    intro w hw; simp at hw
    rcases hw with rfl | rfl
    · show b3.owner = _; rw [e]; exact hxo
    · exact ⟨x, hxm, rfl, hxo⟩


theorem moved_ok (v1 : Bookmark) (i : U64) (ws : alloc.vec.Vec Write)
    (h : (if (i != v1.added) = true then (alloc.vec.Vec.new Write).push (.DelBookmark v1.owner v1.added v1.id)
      else ok (alloc.vec.Vec.new Write)) = ok ws) : ∀ w ∈ ws.val, w = .DelBookmark v1.owner v1.added v1.id := by
  split at h
  · rw [push_ok h]; simp
  · simp only [ok.injEq] at h; subst h; simp

theorem update_fin (s : Snapshot) (u : U64) (v1 b : Bookmark) (ws : List Write)
    (hws : ∀ w ∈ ws, w = .DelBookmark v1.owner v1.added v1.id) (hm : v1 ∈ s.bookmarks.val) (ho : v1.owner = u)
    (hbo : b.owner = v1.owner) (hbi : b.id = v1.id) :
    AllOwn s u (ws ++ [.PutBookmark b]) ∧
      ∀ o1 c, (∃ k, c = .SetCounter k) → TwInv s u v1.id (ws ++ [.PutBookmark b] ++ [.DelLinksOf v1.id]) o1 [] →
        AllOwn s u (o1 ++ [c]) := by
  refine ⟨?_, ?_⟩
  · intro w hw
    rcases List.mem_append.1 hw with hw | hw
    · rw [hws w hw]; exact ho
    · simp at hw; subst hw; exact hbo.trans ho
  · intro o1 c hc htw
    refine tw_own _ _ _ _ _ _ hc htw ⟨b, by simp, hbi, hbo.trans ho⟩ ?_
    intro w hw
    simp only [List.mem_append, List.mem_singleton] at hw
    rcases hw with (hw | rfl) | rfl
    · rw [hws w hw]; exact ho
    · exact hbo.trans ho
    · exact ⟨v1, hm, rfl, ho⟩

theorem update_bookmark_own (s : Snapshot) (tk : alloc.vec.Vec U8) (id : U64) (f : BookmarkFields) (now : U64) out rp u
    (h : update_bookmark s tk id f now = ok (.Ok (out, rp))) (ha : actorOf s tk = .Ok u) : AllOwn s u out.val := by
  unfold update_bookmark at h
  h5i_invert h
  all_goals have := me_eq hr ha; subst this
  all_goals obtain ⟨hm, ho, -⟩ := own_bookmark_ok _ _ _ _ hr1
  all_goals have hmv := moved_ok _ _ _ hws
  · obtain ⟨rfl, rfl⟩ := h
    have e := bookmark_clone_ok hb3
    rw [push_ok hws1]
    exact (update_fin s _ v1 b3 _ hmv hm ho (by rw [e]) (by rw [e])).1
  · obtain ⟨o1, s1, n1⟩ := v4_1
    change (do let w ← set_counter s s.counter.last_bookmark n1; let ws4 ← o1.push w; ok (core.result.Result.Ok (ws4, _))) = _ at h
    h5i_invert h
    obtain ⟨rfl, rfl⟩ := h
    have e := bookmark_clone_ok hb3
    have htw := tag_writes_ok _ _ _ _ _ _ _ _ _ _ hr2
    rw [push_ok hws2, push_ok hws1] at htw
    rw [push_ok hws4]
    exact (update_fin s _ v1 b3 _ hmv hm ho (by rw [e]) (by rw [e])).2 _ _ (set_counter_is _ _ _ _ hw) htw
  · obtain ⟨rfl, rfl⟩ := h
    have e := bookmark_clone_ok hb4
    rw [push_ok hws1]
    exact (update_fin s _ v1 b4 _ hmv hm ho (by rw [e]) (by rw [e])).1
  · obtain ⟨o1, s1, n1⟩ := v4_1
    change (do let w ← set_counter s s.counter.last_bookmark n1; let ws4 ← o1.push w; ok (core.result.Result.Ok (ws4, _))) = _ at h
    h5i_invert h
    obtain ⟨rfl, rfl⟩ := h
    have e := bookmark_clone_ok hb4
    have htw := tag_writes_ok _ _ _ _ _ _ _ _ _ _ hr2
    rw [push_ok hws2, push_ok hws1] at htw
    rw [push_ok hws4]
    exact (update_fin s _ v1 b4 _ hmv hm ho (by rw [e]) (by rw [e])).2 _ _ (set_counter_is _ _ _ _ hw) htw


/-- Every write of an accepted command is the caller's (`OwnWrite`): it
creates or changes rows the caller owns, deletes rows of the state the
caller owns, links the caller's bookmark written in the same write set to
the caller's tag, or sets the id counters. -/
theorem writes_own (o : U64) (s : Snapshot) (c : Command) (t : alloc.vec.Vec U8) (ws : alloc.vec.Vec Write)
    (r : Reply) (u : U64) (h : transition ⟨o, t⟩ s c = ok (.Ok (ws, r))) (ha : Helpers.actorOf s t = .Ok u) :
    ∀ w ∈ ws.val, OwnWrite s u ws.val w := by
  have nil : ws.val = [] → ∀ w ∈ ws.val, OwnWrite s u ws.val w := fun e w hw => by simp [e] at hw
  cases c <;> simp only [transition] at h
  · exact nil (ReadOnly.profile_ws _ _ _ _ h)
  · exact nil (ReadOnly.list_ws _ _ _ _ _ _ _ h)
  · exact nil (ReadOnly.check_ws _ _ _ _ _ _ h)
  · exact nil (ReadOnly.get_bookmark_ws _ _ _ _ _ h)
  · exact create_bookmark_own _ _ _ _ _ _ _ h ha
  · exact update_bookmark_own _ _ _ _ _ _ _ _ h ha
  · exact delete_bookmark_own _ _ _ _ _ _ h ha
  · exact archive_own _ _ _ _ _ _ _ _ h ha
  · exact nil (ReadOnly.list_tags_ws _ _ _ _ _ _ h)
  · exact create_tag_own _ _ _ _ _ _ _ h ha
  · exact nil (ReadOnly.get_tag_ws _ _ _ _ _ h)
  · exact delete_tag_own _ _ _ _ _ _ h ha
  · exact nil (ReadOnly.list_bundles_ws _ _ _ _ _ _ h)
  · exact create_bundle_own _ _ _ _ _ _ _ h ha
  · exact nil (ReadOnly.get_bundle_ws _ _ _ _ _ h)
  · exact update_bundle_own _ _ _ _ _ _ _ _ h ha
  · exact delete_bundle_own _ _ _ _ _ _ h ha

/-! ## Replies of the caller's rows -/

theorem view_bookmark (s : Snapshot) (b : Bookmark) (v : BookmarkView) (h : view s b = ok v) : v.bookmark = b := by
  unfold view at h
  h5i_invert h
  exact bookmark_clone_ok hb1

/-- `GetBookmark` replies with one of the caller's bookmarks. -/
theorem get_bookmark_owned (o : U64) (s : Snapshot) (t : alloc.vec.Vec U8) (id : U64) ws v u
    (h : transition ⟨o, t⟩ s (.GetBookmark id) = ok (.Ok (ws, .Bookmark v))) (ha : Helpers.actorOf s t = .Ok u) :
    v.bookmark ∈ s.bookmarks.val ∧ v.bookmark.owner = u ∧ v.bookmark.id = id := by
  simp only [transition] at h
  unfold get_bookmark at h
  h5i_invert h
  have := me_eq hr ha; subst this
  simp only [Reply.Bookmark.injEq] at h
  obtain ⟨-, rfl⟩ := h
  rw [view_bookmark _ _ _ hbv]
  exact own_bookmark_ok _ _ _ _ hr1

/-- `GetTag` replies with one of the caller's tags. -/
theorem get_tag_owned (o : U64) (s : Snapshot) (t : alloc.vec.Vec U8) (id : U64) ws x u
    (h : transition ⟨o, t⟩ s (.GetTag id) = ok (.Ok (ws, .Tag x))) (ha : Helpers.actorOf s t = .Ok u) :
    x ∈ s.tags.val ∧ x.owner = u ∧ x.id = id := by
  simp only [transition] at h
  unfold get_tag at h
  h5i_invert h
  have := me_eq hr ha; subst this
  simp only [Reply.Tag.injEq] at h
  obtain ⟨-, rfl⟩ := h
  exact own_tag_ok _ _ _ _ hr1

/-- `GetBundle` replies with one of the caller's bundles. -/
theorem get_bundle_owned (o : U64) (s : Snapshot) (t : alloc.vec.Vec U8) (id : U64) ws x u
    (h : transition ⟨o, t⟩ s (.GetBundle id) = ok (.Ok (ws, .Bundle x))) (ha : Helpers.actorOf s t = .Ok u) :
    x ∈ s.bundles.val ∧ x.owner = u ∧ x.id = id := by
  simp only [transition] at h
  unfold get_bundle at h
  h5i_invert h
  have := me_eq hr ha; subst this
  simp only [Reply.Bundle.injEq] at h
  obtain ⟨-, rfl⟩ := h
  exact own_bundle_ok _ _ _ _ hr1

end linkding_kernel.Owner
