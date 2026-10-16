import TuwunelKernel
import H5iAppLib
/-!
# Who may see what in a tuwunel room: the spec

From the Matrix client-server specification ("History visibility", the
`/messages`, `/context`, `/state`, `/members` endpoints) and from tuwunel's
own documentation of its rule at 7801b8e (`service/rooms/state_accessor/
user_can.rs`). Everything here reads the kernel's tables as plain lists and
uses none of the kernel's functions.

User ids are numbers; the server of user `u` is `u / 1000`. State key `0` is
the empty state key, any other the user with that number.
-/
open Aeneas Aeneas.Std tuwunel_kernel

namespace tuwunel_kernel

deriving instance DecidableEq for Kind
deriving instance DecidableEq for Membership
deriving instance DecidableEq for HistoryVisibility
deriving instance DecidableEq for MemberField
deriving instance DecidableEq for HvField

end tuwunel_kernel

namespace tuwunel_kernel.Spec

/-! ## The database -/

/-- The room timeline: every stored PDU that is not an outlier. -/
def timeline (s : Snapshot) : List Pdu := s.pdus.val.filter (fun p => !p.outlier)

/-- The event with id `e`: its timeline row, else the outlier. -/
def eventOf (s : Snapshot) (e : Nat) : Option Pdu :=
  match (timeline s).find? (fun p => p.event_id.val = e) with
  | some p => some p
  | none => (s.pdus.val.filter (fun p => p.outlier)).find? (fun p => p.event_id.val = e)

/-- The timeline count of event `e`. -/
def countOf (s : Snapshot) (e : Nat) : Option Int :=
  ((timeline s).find? (fun p => p.event_id.val = e)).map (fun p => p.count.val)

/-- `e` is a timeline event of `room`. -/
def InRoom (s : Snapshot) (room e : Nat) : Prop :=
  ∃ p ∈ timeline s, p.event_id.val = e ∧ p.room.val = room

/-- Event ids, room ids and room short ids are keys. -/
def Keys (s : Snapshot) : Prop :=
  (s.pdus.val.map (fun p => p.event_id.val)).Nodup ∧
  (s.rooms.val.map (fun r => r.id.val)).Nodup ∧
  (s.rooms.val.map (fun r => r.short.val)).Nodup

/-- The timeline is stored in count order. -/
def Sorted (s : Snapshot) : Prop :=
  (timeline s).Pairwise (fun a b => a.count.val < b.count.val)

/-- The entries of state snapshot `h`. -/
def stateEntries (s : Snapshot) (h : Nat) : Option (List StateEntry) :=
  (s.states.val.find? (fun x => x.hash.val = h)).map (fun x => x.entries.val)

/-- The event under `(kind, state_key)` in state snapshot `h`. -/
def stateLookup (s : Snapshot) (h : Nat) (k : Kind) (key : Nat) : Option Pdu :=
  match stateEntries s h with
  | none => none
  | some es =>
    match es.find? (fun en => en.kind = k ∧ en.state_key.val = key) with
    | none => none
    | some en => eventOf s en.event_id.val

/-- The room's current state snapshot. -/
def roomState (s : Snapshot) (room : Nat) : Option Nat :=
  match s.rooms.val.find? (fun r => r.id.val = room) with
  | some ⟨_, _, .Hash h⟩ => some h.val
  | _ => none

/-- A user's membership in state snapshot `h`; none recorded, or content
that does not parse, counts as `leave`. -/
def membershipAt (s : Snapshot) (h u : Nat) : Membership :=
  match stateLookup s h .Member u with
  | some p => match p.membership with
    | .Is m => m
    | .Absent => .Leave
  | none => .Leave

/-- The history visibility in state snapshot `h`; none recorded, or content
that does not parse, counts as `shared`. -/
def visibilityAt (s : Snapshot) (h : Nat) : HistoryVisibility :=
  match stateLookup s h .HistoryVisibility 0 with
  | some p => match p.history_visibility with
    | .Is v => v
    | .Absent => .Shared
  | none => .Shared

/-- The room is world-readable now. -/
def WorldReadableNow (s : Snapshot) (room : Nat) : Prop :=
  ∃ h, roomState s room = some h ∧ ∃ p, stateLookup s h .HistoryVisibility 0 = some p ∧
    p.history_visibility = .Is .WorldReadable

/-! ## Membership as the state cache records it -/

def Joined (s : Snapshot) (u room : Nat) : Prop := ∃ x ∈ s.joined.val, x.user.val = u ∧ x.room.val = room
def Invited (s : Snapshot) (u room : Nat) : Prop := ∃ x ∈ s.invited.val, x.user.val = u ∧ x.room.val = room
def OnceJoined (s : Snapshot) (u room : Nat) : Prop := ∃ x ∈ s.once_joined.val, x.user.val = u ∧ x.room.val = room

/-- The count of the user's latest leave, if the room is not forgotten. -/
def leftCount (s : Snapshot) (u room : Nat) : Option Nat :=
  (s.left.val.find? (fun x => x.user.val = u ∧ x.room.val = room)).map (fun x => x.count.val)

/-- A stored `u64` count read as the signed count it encodes. -/
def toSigned (l : Nat) : Int := if l < 2 ^ 63 then l else (l : Int) - 2 ^ 64

/-! ## Who may see an event -/

/-- tuwunel's rule (`user_can_see_event`) for user `u` asking in `room`:
an event with no recorded state is visible; otherwise the history visibility
in the state before the event decides:
- `world_readable`: anyone;
- `invited`: users invited or joined at the event;
- `joined`: users joined at the event;
- `shared`, or a value tuwunel does not know: users joined in `room` now,
  users joined at the event, and users who once joined `room` and whose
  latest leave is no earlier than the event. -/
def Visible (s : Snapshot) (u room e : Nat) : Prop :=
  match eventOf s e with
  | none => True
  | some p =>
    match p.state with
    | .None => True
    | .Hash h =>
      match visibilityAt s h.val with
      | .WorldReadable => True
      | .Invited => membershipAt s h.val u = .Join ∨ membershipAt s h.val u = .Invite
      | .Joined => membershipAt s h.val u = .Join
      | _ =>
        Joined s u room ∨ membershipAt s h.val u = .Join ∨
          (OnceJoined s u room ∧ ∃ l c, leftCount s u room = some l ∧ countOf s e = some c ∧ c ≤ toSigned l)

/-- The Matrix spec's rule: world-readable events are visible; so are
events at which the user was joined; under `shared`, events the user joined
the room after (or is joined now); under `invited`, events at which the user
was invited. -/
def MatrixVisible (s : Snapshot) (u room e : Nat) : Prop :=
  ∃ p h, eventOf s e = some p ∧ p.state = .Hash h ∧
    (visibilityAt s h.val = .WorldReadable ∨ membershipAt s h.val u = .Join ∨
      (visibilityAt s h.val = .Shared ∧
        (Joined s u room ∨ ∃ q ∈ timeline s, q.room.val = room ∧ q.kind = .Member ∧ q.state_key.val = u ∧
          q.membership = .Is .Join ∧ p.count.val < q.count.val)) ∨
      (visibilityAt s h.val = .Invited ∧ membershipAt s h.val u = .Invite))

/-- Event types a user's ignore list hides (`IGNORED_MESSAGE_TYPES`). -/
def messageLike : Kind → Bool
  | .Message | .Reaction | .Encrypted | .Sticker => true
  | _ => false

/-- A server the configuration forbids: never the own server; one on the
deny list, or off a non-empty allow list. -/
def Forbidden (c : Config) (server : Nat) : Prop :=
  server ≠ c.server_name.val ∧
    ((∃ x ∈ c.forbidden_remote_server_names.val, x.val = server) ∨
      (c.allowed_remote_server_names.val ≠ [] ∧ ∀ x ∈ c.allowed_remote_server_names.val, x.val ≠ server))

/-- `u` does not get `p`: dummy events, and message-like events from an
ignored user or a forbidden server. -/
def Ignored (s : Snapshot) (u : Nat) (p : Pdu) : Prop :=
  p.kind = .Dummy ∨
    (messageLike p.kind ∧
      (Forbidden s.config (p.sender.val / 1000) ∨ ∃ i ∈ s.ignored.val, i.user.val = u ∧ i.ignored.val = p.sender.val))

/-! ## How the state is kept -/

/-- The latest state event of `room` under `(kind, state_key)` before count `c`. -/
def latestBefore (s : Snapshot) (room : Nat) (k : Kind) (key : Nat) (c : Int) : Option Pdu :=
  ((timeline s).filter (fun p => p.room.val = room ∧ p.kind = k ∧ p.has_state_key ∧ p.state_key.val = key ∧
    p.count.val < c)).getLast?

/-- The state recorded before each timeline event holds, for each type and
state key, the latest earlier state event of the room. -/
def StateConsistent (s : Snapshot) : Prop :=
  ∀ q ∈ timeline s, ∀ h, q.state = .Hash h → ∀ k key, stateLookup s h.val k key = latestBefore s q.room.val k key q.count.val

/-- `p` is `u`'s last membership event in `room`. -/
def LastMembership (s : Snapshot) (u room : Nat) (p : Pdu) : Prop :=
  p ∈ timeline s ∧ p.room.val = room ∧ p.kind = .Member ∧ p.has_state_key ∧ p.state_key.val = u ∧
    ∀ q ∈ timeline s, q.room.val = room → q.kind = .Member → q.has_state_key → q.state_key.val = u →
      q.count.val ≤ p.count.val

end tuwunel_kernel.Spec
