import Spec
open Aeneas Aeneas.Std Result tuwunel_kernel tuwunel_kernel.Spec
open H5iAppLib hiding lit

namespace tuwunel_kernel.Properties

/-- `/messages` returns only events of the room that the user may see and
has not ignored. -/
theorem messages_visible (s : Snapshot) (u room : U64) (frm upto : Token) (dir : Dir) (lim : U64) (f : Filter)
    (st : I64) (en : Option I64) (chunk : alloc.vec.Vec U64)
    (h : transition s ⟨u, .Messages room frm upto dir lim f⟩ = ok (.Ok (.Messages st en chunk)))
    (hk : Keys s) :
    ∀ e ∈ chunk.val, InRoom s room.val e.val ∧ Visible s u.val room.val e.val ∧
      ∀ p ∈ timeline s, p.event_id = e → ¬ Ignored s u.val p := by
  sorry

/-- `/messages` pages in order: forward above the `from` token and below
`to`, backward below `from` and above `to`, at most `limit` (capped at
1000) events. -/
theorem messages_ordered (s : Snapshot) (u room : U64) (frm upto : Token) (dir : Dir) (lim : U64) (f : Filter)
    (st : I64) (en : Option I64) (chunk : alloc.vec.Vec U64)
    (h : transition s ⟨u, .Messages room frm upto dir lim f⟩ = ok (.Ok (.Messages st en chunk)))
    (hk : Keys s) (hs : Sorted s) :
    ∃ cs : List Int, chunk.val.map (fun e => countOf s e.val) = cs.map some ∧
      (dir = .Forward → cs.Pairwise (· < ·) ∧ ∀ c ∈ cs, st.val < c ∧ ∀ t, upto = .At t → c < t.val) ∧
      (dir = .Backward → cs.Pairwise (· > ·) ∧ ∀ c ∈ cs, c < st.val ∧ ∀ t, upto = .At t → t.val < c) ∧
      chunk.val.length ≤ min lim.val 1000 := by
  sorry

/-- A user whose last membership event in the room is a leave or a ban,
and who is not joined in the state cache, gets from `/messages` no event
after that departure unless it is world-readable (or has no recorded
state). -/
theorem messages_nothing_after_leaving (s : Snapshot) (u room : U64) (frm upto : Token) (dir : Dir) (lim : U64)
    (f : Filter) (st : I64) (en : Option I64) (chunk : alloc.vec.Vec U64)
    (h : transition s ⟨u, .Messages room frm upto dir lim f⟩ = ok (.Ok (.Messages st en chunk)))
    (hk : Keys s) (hs : Sorted s) (hc : StateConsistent s)
    (p : Pdu) (hp : LastMembership s u.val room.val p)
    (hleave : p.membership = .Is .Leave ∨ p.membership = .Is .Ban)
    (hj : ¬ Joined s u.val room.val) (hl : ∀ l, leftCount s u.val room.val = some l → (l : Int) ≤ p.count.val) :
    ∀ e ∈ chunk.val, ∀ q ∈ timeline s, q.event_id = e → p.count.val < q.count.val →
      q.state = .None ∨ ∃ hq, q.state = .Hash hq ∧ visibilityAt s hq.val = .WorldReadable := by
  sorry

/-- `/context` returns a base event, events before and events after, all in
the room and visible to the user. -/
theorem context_visible (s : Snapshot) (u room ev lim : U64) (f : Filter)
    (base : U64) (st en : I64) (before after state : alloc.vec.Vec U64)
    (h : transition s ⟨u, .Context room ev lim f⟩ = ok (.Ok (.Context base st en before after state)))
    (hk : Keys s) :
    base = ev ∧ ∀ e ∈ base :: (before.val ++ after.val), InRoom s room.val e.val ∧ Visible s u.val room.val e.val := by
  sorry

/-- Where the history visibility at an event is `joined` or `invited`, the
events `/context` returns satisfy the Matrix spec's rule. -/
theorem context_matches_spec (s : Snapshot) (u room ev lim : U64) (f : Filter)
    (base : U64) (st en : I64) (before after state : alloc.vec.Vec U64)
    (h : transition s ⟨u, .Context room ev lim f⟩ = ok (.Ok (.Context base st en before after state)))
    (hk : Keys s) :
    ∀ e ∈ base :: (before.val ++ after.val), ∀ p hp, eventOf s e.val = some p → p.state = .Hash hp →
      (visibilityAt s hp.val = .Joined ∨ visibilityAt s hp.val = .Invited) → MatrixVisible s u.val room.val e.val := by
  sorry

/-- `/context` and `/messages` agree: the events after the base event are
the first page of `/messages` forward from the base event's count, and the
events before it the first page backward, with the same filter and the
limit split as `/context` splits it. -/
theorem context_agrees_with_messages (s : Snapshot) (u room ev lim : U64) (f : Filter)
    (base : U64) (st en : I64) (before after state : alloc.vec.Vec U64) (c : I64) (k1 k2 : U64)
    (h : transition s ⟨u, .Context room ev lim f⟩ = ok (.Ok (.Context base st en before after state)))
    (hk : Keys s) (hc : countOf s ev.val = some c.val)
    (hk1 : k1.val = (min lim.val 100 + 1) / 2) (hk2 : k2.val = min lim.val 100 / 2)
    (st1 st2 : I64) (en1 en2 : Option I64) (c1 c2 : alloc.vec.Vec U64)
    (h1 : transition s ⟨u, .Messages room (.At c) .Absent .Forward k1 f⟩ = ok (.Ok (.Messages st1 en1 c1)))
    (h2 : transition s ⟨u, .Messages room (.At c) .Absent .Backward k2 f⟩ = ok (.Ok (.Messages st2 en2 c2))) :
    after = c1 ∧ before = c2 := by
  sorry

/-- The base event `/context` serves, `/event` serves too. -/
theorem context_base_served_by_event (s : Snapshot) (u room ev lim : U64) (f : Filter)
    (base : U64) (st en : I64) (before after state : alloc.vec.Vec U64)
    (h : transition s ⟨u, .Context room ev lim f⟩ = ok (.Ok (.Context base st en before after state)))
    (hk : Keys s) :
    transition s ⟨u, .RoomEvent room ev⟩ = ok (.Ok (.RoomEvent ev)) := by
  sorry

/-- `/relations` needs the room's state to be readable (joined, invited,
once joined, or world-readable) and returns events of the room the user
may see. -/
theorem relations_visible (s : Snapshot) (u room ev : U64) (rt : Option RelType) (et : Option Kind)
    (frm upto : Token) (lim : Option U64) (recurse : Bool) (dir : Dir)
    (chunk : alloc.vec.Vec U64) (nb pb : Option I64) (depth : Option U64)
    (h : transition s ⟨u, .Relations room ev rt et frm upto lim recurse dir⟩ =
      ok (.Ok (.Relations chunk nb pb depth)))
    (hk : Keys s) :
    (Joined s u.val room.val ∨ Invited s u.val room.val ∨ OnceJoined s u.val room.val ∨ WorldReadableNow s room.val) ∧
      ∀ e ∈ chunk.val, InRoom s room.val e.val ∧ Visible s u.val room.val e.val := by
  sorry

/-- `/threads` returns thread roots of the room the user may see. -/
theorem threads_visible (s : Snapshot) (u room : U64) (frm : Token) (lim : Option U64) (part : Bool)
    (chunk : alloc.vec.Vec U64) (nb : Option I64)
    (h : transition s ⟨u, .Threads room frm lim part⟩ = ok (.Ok (.Threads chunk nb)))
    (hk : Keys s) :
    ∀ e ∈ chunk.val, InRoom s room.val e.val ∧ Visible s u.val room.val e.val := by
  sorry

/-- `/event` returns the event asked for, and only if the rule lets the user
see it when asking in that room. -/
theorem room_event_visible (s : Snapshot) (u room ev x : U64)
    (h : transition s ⟨u, .RoomEvent room ev⟩ = ok (.Ok (.RoomEvent x))) :
    x = ev ∧ Visible s u.val room.val ev.val := by
  sorry

/-- An event that is world-readable at the time it was sent is served by
`/event` to anyone who has not ignored its sender. -/
theorem world_readable_event_served (s : Snapshot) (u room ev : U64) (p : Pdu) (hp : U64)
    (he : eventOf s ev.val = some p) (hs : p.state = .Hash hp)
    (hw : visibilityAt s hp.val = .WorldReadable) (hi : ¬ Ignored s u.val p) :
    transition s ⟨u, .RoomEvent room ev⟩ = ok (.Ok (.RoomEvent ev)) := by
  sorry

/-- The room state, one state event and the member list need the user to be
joined, invited, once joined, or the room to be world-readable. -/
theorem state_reads_need_membership (s : Snapshot) (u room : U64) (op : Op) (r : Reply)
    (hop : op = .State room ∨ (∃ k key, op = .StateEvent room k key) ∨ ∃ at_ m n, op = .Members room at_ m n)
    (h : transition s ⟨u, op⟩ = ok (.Ok r)) :
    Joined s u.val room.val ∨ Invited s u.val room.val ∨ OnceJoined s u.val room.val ∨ WorldReadableNow s room.val := by
  sorry

/-- `/joined_members` needs the user to be joined or the room to be
world-readable. -/
theorem joined_members_need_join (s : Snapshot) (u room : U64) (r : Reply)
    (h : transition s ⟨u, .JoinedMembers room⟩ = ok (.Ok r)) :
    Joined s u.val room.val ∨ WorldReadableNow s room.val := by
  sorry

/-- `initialSync` returns events of the room the user may see. -/
theorem initial_sync_visible (s : Snapshot) (u room : U64) (lim : Option U64)
    (m : Option Membership) (state chunk : alloc.vec.Vec U64) (st : Option I64) (en : I64)
    (h : transition s ⟨u, .InitialSync room lim⟩ = ok (.Ok (.InitialSync m state chunk st en)))
    (hk : Keys s) :
    ∀ e ∈ chunk.val, InRoom s room.val e.val ∧ Visible s u.val room.val e.val := by
  sorry

/-- A user whose membership in the room's current state is a leave or a
ban sees the room as of their departure in `initialSync`: no event after it. -/
theorem initial_sync_stops_at_departure (s : Snapshot) (u room : U64) (lim : Option U64)
    (m : Option Membership) (state chunk : alloc.vec.Vec U64) (st : Option I64) (en : I64)
    (h : transition s ⟨u, .InitialSync room lim⟩ = ok (.Ok (.InitialSync m state chunk st en)))
    (hk : Keys s) (h0 : Nat) (hr : roomState s room.val = some h0) (p : Pdu)
    (hm : stateLookup s h0 .Member u.val = some p) (ht : p ∈ timeline s)
    (hleave : p.membership = .Is .Leave ∨ p.membership = .Is .Ban) :
    ∀ e ∈ chunk.val, ∃ q ∈ timeline s, q.event_id = e ∧ q.count.val ≤ p.count.val := by
  sorry

/-- Over federation, an event whose history visibility is `joined` is shown
to a server only if one of its users, joined to the room now, was joined at
the event. -/
theorem server_sees_joined_only (s : Snapshot) (origin room ev : U64) (p : Pdu) (hp : U64)
    (h : transition s ⟨0#u64, .ServerCanSee origin room ev⟩ = ok (.Ok (.CanSee true)))
    (he : eventOf s ev.val = some p) (hs : p.state = .Hash hp) (hj : visibilityAt s hp.val = .Joined) :
    ∃ m, Joined s m room.val ∧ m / 1000 = origin.val ∧ membershipAt s hp.val m = .Join := by
  sorry

/-- Every request gets a reply: the kernel neither panics nor loops. -/
theorem transition_total (s : Snapshot) (req : Request) :
    ∃ r, transition s req = ok r := by
  sorry

end tuwunel_kernel.Properties
