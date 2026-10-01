//! `api/client/room/{initial_sync,event}.rs`.
use crate::*;

pub const LIMIT_MAX: u64 = 50;

/// `room_initial_sync_route`: a user who left sees the room as of their
/// departure.
pub fn room_initial_sync_route(s: &Snapshot, user: u64, room: u64, limit: Option<u64>) -> Result<Reply, Error> {
    match svc_cache::user_membership(s, user, room) {
        Some(Membership::Ban) => return Err(Error::Forbidden),
        _ => {}
    }
    if !svc_accessor::user_can_see_state_events(s, user, room) {
        return Err(Error::Forbidden);
    }
    let current_shortstatehash = match svc_timeline::get_room_shortstatehash(s, room) {
        Ok(h) => h,
        Err(e) => return Err(e),
    };
    let member = match svc_accessor::state_get(s, current_shortstatehash, Kind::Member, user) {
        Ok(p) => Some(p),
        Err(Error::NotFound) => None,
        Err(e) => return Err(e),
    };
    let membership = match member {
        None => None,
        Some(p) => match s.pdus[p].membership {
            MemberField::Is(m) => Some(m),
            MemberField::Absent => return Err(Error::Parse),
        },
    };
    let departed = match membership {
        Some(Membership::Leave) => true,
        Some(Membership::Ban) => true,
        _ => false,
    };
    let (timeline_end, shortstatehash) = match member {
        Some(p) => {
            if departed {
                match departure_snapshot(s, room, &s.pdus[p], current_shortstatehash) {
                    Ok(x) => x,
                    Err(e) => return Err(e),
                }
            } else {
                (s.current_count, current_shortstatehash)
            }
        }
        None => (s.current_count, current_shortstatehash),
    };
    let limit = match limit {
        Some(l) => {
            if l < LIMIT_MAX { l } else { LIMIT_MAX }
        }
        None => LIMIT_MAX,
    };
    let state = match svc_accessor::state_full_pdus_strict(s, shortstatehash) {
        Ok(v) => v,
        Err(e) => return Err(e),
    };
    let it = match svc_timeline::pdus_rev(s, room, timeline_end.saturating_add(1)) {
        Ok(v) => v,
        Err(e) => return Err(e),
    };
    let mut events: Vec<(i64, usize)> = Vec::new();
    let mut i = 0;
    while i < it.len() && (events.len() as u64) < limit {
        let p = it[i];
        if api_message::visibility_filter(s, p, user) {
            events.push((s.pdus[p].count, p));
        }
        i += 1;
    }
    let events = reversed(&events);
    let start = if events.len() == 0 { None } else { Some(events[0].0) };
    let end = match api_message::last_count(&events) {
        Some(c) => c,
        None => timeline_end,
    };
    let mut state_ids = Vec::new();
    let mut j = 0;
    while j < state.len() {
        state_ids.push(s.pdus[state[j]].event_id);
        j += 1;
    }
    Ok(Reply::InitialSync { membership, state: state_ids, chunk: api_message::event_ids(s, &events), start, end })
}

fn reversed(v: &[(i64, usize)]) -> Vec<(i64, usize)> {
    let mut out = Vec::new();
    let mut i = v.len();
    while i > 0 {
        i -= 1;
        out.push(v[i]);
    }
    out
}

/// `departure_snapshot`: the timeline ends at the departure event; the
/// state is the one after it.
pub fn departure_snapshot(s: &Snapshot, room: u64, pdu: &Pdu, current_shortstatehash: u64) -> Result<(i64, u64), Error> {
    let timeline_end = match svc_timeline::get_pdu_count(s, pdu.event_id) {
        Ok(c) => c,
        Err(e) => return Err(e),
    };
    let latest_count = match svc_timeline::last_timeline_count(s, room) {
        Ok(c) => c,
        Err(e) => return Err(e),
    };
    if latest_count == timeline_end {
        Ok((timeline_end, current_shortstatehash))
    } else {
        match svc_timeline::next_shortstatehash(s, room, timeline_end) {
            Ok(h) => Ok((timeline_end, h)),
            Err(e) => Err(e),
        }
    }
}

/// `get_room_event_route`: one event, if visible and not ignored. The
/// release build does not check that the event is in `room`.
pub fn get_room_event_route(s: &Snapshot, user: u64, room: u64, event_id: u64) -> Result<Reply, Error> {
    let event = svc_timeline::get_pdu(s, event_id);
    let visible = svc_accessor::user_can_see_event(s, user, room, event_id);
    let p = match event {
        Ok(p) => p,
        Err(_) => return Err(Error::NotFound),
    };
    if !visible {
        return Err(Error::NotFound);
    }
    if api_message::is_ignored_pdu(s, &s.pdus[p], user) {
        return Err(Error::SenderIgnored);
    }
    Ok(Reply::RoomEvent { event: s.pdus[p].event_id })
}
