//! `service/rooms/state_accessor/{state,room_state,user_can,server_can,mod}.rs`.
use crate::*;
use crate::svc_timeline::{get_pdu, get_pdu_count, get_room_shortstatehash, pdu_shortstatehash};

// ---- state.rs ----

/// `load_full_state`: the snapshot; a missing one is a `Database` error.
pub fn load_full_state(s: &Snapshot, hash: u64) -> Result<usize, Error> {
    let mut i = 0;
    while i < s.states.len() {
        if s.states[i].hash == hash {
            return Ok(i);
        }
        i += 1;
    }
    Err(Error::Database)
}

/// `state_get_id` (with `state_get_shortid`): the event under
/// `(kind, state_key)` in a snapshot.
pub fn state_get_id(s: &Snapshot, hash: u64, kind: Kind, state_key: u64) -> Result<u64, Error> {
    match load_full_state(s, hash) {
        Err(e) => Err(e),
        Ok(si) => find_entry(&s.states[si].entries, kind, state_key),
    }
}

fn find_entry(entries: &[StateEntry], kind: Kind, state_key: u64) -> Result<u64, Error> {
    let mut i = 0;
    while i < entries.len() {
        if kind_eq(entries[i].kind, kind) && entries[i].state_key == state_key {
            return Ok(entries[i].event_id);
        }
        i += 1;
    }
    Err(Error::NotFound)
}

/// `state_get`: the PDU under `(kind, state_key)` in a snapshot.
pub fn state_get(s: &Snapshot, hash: u64, kind: Kind, state_key: u64) -> Result<usize, Error> {
    match state_get_id(s, hash, kind, state_key) {
        Err(e) => Err(e),
        Ok(id) => get_pdu(s, id),
    }
}

/// `state_get_content::<RoomHistoryVisibilityEventContent>(hash, ..., "")`
/// mapped to `HistoryVisibility::Shared` on any error.
pub fn history_visibility_at(s: &Snapshot, hash: u64) -> HistoryVisibility {
    match state_get(s, hash, Kind::HistoryVisibility, 0) {
        Err(_) => HistoryVisibility::Shared,
        Ok(i) => match s.pdus[i].history_visibility {
            HvField::Is(v) => v,
            HvField::Absent => HistoryVisibility::Shared,
        },
    }
}

/// `user_was_joined`.
pub fn user_was_joined(s: &Snapshot, hash: u64, user: u64) -> bool {
    matches!(user_membership(s, hash, user), Membership::Join)
}

/// `user_was_invited`: invited or joined.
pub fn user_was_invited(s: &Snapshot, hash: u64, user: u64) -> bool {
    let m = user_membership(s, hash, user);
    matches!(m, Membership::Join) || matches!(m, Membership::Invite)
}

/// `user_membership`: missing state or content falls back to `Leave`.
pub fn user_membership(s: &Snapshot, hash: u64, user: u64) -> Membership {
    match state_get(s, hash, Kind::Member, user) {
        Err(_) => Membership::Leave,
        Ok(i) => match s.pdus[i].membership {
            MemberField::Is(m) => m,
            MemberField::Absent => Membership::Leave,
        },
    }
}

/// `state_full_ids`: the snapshot's event ids; nothing if it is missing.
pub fn state_full_ids(s: &Snapshot, hash: u64) -> Vec<u64> {
    let mut out = Vec::new();
    match load_full_state(s, hash) {
        Err(_) => {}
        Ok(si) => {
            let entries = &s.states[si].entries;
            let mut i = 0;
            while i < entries.len() {
                out.push(entries[i].event_id);
                i += 1;
            }
        }
    }
    out
}

/// `state_full_pdus`: the snapshot's PDUs, skipping unknown events.
pub fn state_full_pdus(s: &Snapshot, hash: u64) -> Vec<usize> {
    let ids = state_full_ids(s, hash);
    let mut out = Vec::new();
    let mut i = 0;
    while i < ids.len() {
        match get_pdu(s, ids[i]) {
            Ok(p) => out.push(p),
            Err(_) => {}
        }
        i += 1;
    }
    out
}

/// `state_full`: `state_full_pdus` restricted to events with a state key.
pub fn state_full(s: &Snapshot, hash: u64) -> Vec<usize> {
    let all = state_full_pdus(s, hash);
    let mut out = Vec::new();
    let mut i = 0;
    while i < all.len() {
        let p = all[i];
        if s.pdus[p].has_state_key {
            out.push(p);
        }
        i += 1;
    }
    out
}

/// `state_full_pdus_strict`: errors on a missing snapshot or event.
pub fn state_full_pdus_strict(s: &Snapshot, hash: u64) -> Result<Vec<usize>, Error> {
    match load_full_state(s, hash) {
        Err(e) => Err(e),
        Ok(si) => resolve_all(s, &s.states[si].entries),
    }
}

fn resolve_all(s: &Snapshot, entries: &[StateEntry]) -> Result<Vec<usize>, Error> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < entries.len() {
        match get_pdu(s, entries[i].event_id) {
            Ok(p) => out.push(p),
            Err(e) => return Err(e),
        }
        i += 1;
    }
    Ok(out)
}

// ---- room_state.rs ----

/// `room_state_get`.
pub fn room_state_get(s: &Snapshot, room: u64, kind: Kind, state_key: u64) -> Result<usize, Error> {
    match get_room_shortstatehash(s, room) {
        Err(e) => Err(e),
        Ok(h) => state_get(s, h, kind, state_key),
    }
}

/// `room_state_full_pdus` (and `room_state_full`, which also keeps only
/// events with a state key): a missing room state is a `Database` error.
pub fn room_state_full_pdus(s: &Snapshot, room: u64) -> Result<Vec<usize>, Error> {
    match get_room_shortstatehash(s, room) {
        Err(_) => Err(Error::Database),
        Ok(h) => Ok(state_full_pdus(s, h)),
    }
}

/// `room_state_full`.
pub fn room_state_full(s: &Snapshot, room: u64) -> Result<Vec<usize>, Error> {
    match get_room_shortstatehash(s, room) {
        Err(_) => Err(Error::Database),
        Ok(h) => Ok(state_full(s, h)),
    }
}

/// `room_state_get_content::<RoomHistoryVisibilityEventContent>`: `None`
/// on any error.
pub fn room_history_visibility(s: &Snapshot, room: u64) -> Option<HistoryVisibility> {
    match room_state_get(s, room, Kind::HistoryVisibility, 0) {
        Err(_) => None,
        Ok(i) => match s.pdus[i].history_visibility {
            HvField::Is(v) => Some(v),
            HvField::Absent => None,
        },
    }
}

// ---- mod.rs ----

/// `is_world_readable`.
pub fn is_world_readable(s: &Snapshot, room: u64) -> bool {
    match room_history_visibility(s, room) {
        Some(HistoryVisibility::WorldReadable) => true,
        _ => false,
    }
}

// ---- user_can.rs ----

/// `user_can_see_event`: an event without recorded state is visible; the
/// history visibility at the event decides otherwise, `shared` by default.
pub fn user_can_see_event(s: &Snapshot, user: u64, room: u64, event_id: u64) -> bool {
    match pdu_shortstatehash(s, event_id) {
        Err(_) => true,
        Ok(hash) => match history_visibility_at(s, hash) {
            HistoryVisibility::WorldReadable => true,
            HistoryVisibility::Invited => user_was_invited(s, hash, user),
            HistoryVisibility::Joined => user_was_joined(s, hash, user),
            _ => user_shared_history(s, hash, room, event_id, user),
        },
    }
}

/// `user_shared_history`: a current member, or one joined at the event,
/// sees it; a former member sees events up to their latest leave.
pub fn user_shared_history(s: &Snapshot, hash: u64, room: u64, event_id: u64, user: u64) -> bool {
    if svc_cache::is_joined(s, user, room) || user_was_joined(s, hash, user) {
        return true;
    }
    if !svc_cache::once_joined(s, user, room) {
        return false;
    }
    match svc_cache::get_left_count(s, room, user) {
        Err(_) => false,
        Ok(left_count) => match get_pdu_count(s, event_id) {
            Err(_) => false,
            Ok(event_count) => event_count <= left_count as i64,
        },
    }
}

/// `user_can_see_state_events`.
pub fn user_can_see_state_events(s: &Snapshot, user: u64, room: u64) -> bool {
    if svc_cache::is_joined(s, user, room) {
        return true;
    }
    let hv = match room_history_visibility(s, room) {
        Some(v) => v,
        None => HistoryVisibility::Shared,
    };
    match hv {
        HistoryVisibility::WorldReadable => true,
        HistoryVisibility::Invited => svc_cache::is_invited(s, user, room),
        HistoryVisibility::Shared => svc_cache::once_joined(s, user, room),
        _ => false,
    }
}

/// `user_can_see_room`: joined, invited, a retained leave, or world
/// readable.
pub fn user_can_see_room(s: &Snapshot, user: u64, room: u64) -> bool {
    svc_cache::is_joined(s, user, room)
        || svc_cache::is_invited(s, user, room)
        || svc_cache::is_left(s, user, room)
        || is_world_readable(s, room)
}

// ---- server_can.rs ----

/// `server_can_see_event`: for `invited` and `joined`, some current member
/// from `origin` must have had that membership at the event.
pub fn server_can_see_event(s: &Snapshot, origin: u64, room: u64, event_id: u64) -> bool {
    match pdu_shortstatehash(s, event_id) {
        Err(_) => true,
        Ok(hash) => {
            let hv = history_visibility_at(s, hash);
            let members = svc_cache::room_members(s, room);
            match hv {
                HistoryVisibility::Invited => any_member_was(s, hash, origin, &members, false),
                HistoryVisibility::Joined => any_member_was(s, hash, origin, &members, true),
                _ => true,
            }
        }
    }
}

fn any_member_was(s: &Snapshot, hash: u64, origin: u64, members: &[u64], joined: bool) -> bool {
    let mut i = 0;
    while i < members.len() {
        let m = members[i];
        if server_name(m) == origin {
            let ok = if joined { user_was_joined(s, hash, m) } else { user_was_invited(s, hash, m) };
            if ok {
                return true;
            }
        }
        i += 1;
    }
    false
}
