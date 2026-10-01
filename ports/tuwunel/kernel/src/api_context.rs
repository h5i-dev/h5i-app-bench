//! `api/client/context.rs`: `/context`.
use crate::*;
use crate::api_message::{bounded, event_ids, is_ignored_pdu, passes};

pub const LIMIT_MAX: u64 = 100;
pub const LIMIT_DEFAULT: u64 = 10;

/// `get_context_route`.
pub fn get_context_route(s: &Snapshot, user: u64, room: u64, event: u64, limit: u64, filter: &Filter) -> Result<Reply, Error> {
    event_context(s, user, room, event, Some(limit), filter, false)
}

/// `event_context`.
pub fn event_context(
    s: &Snapshot,
    user: u64,
    room: u64,
    event_id: u64,
    limit: Option<u64>,
    filter: &Filter,
    bypass_visibility: bool,
) -> Result<Reply, Error> {
    if !svc_timeline::exists(s, room) {
        return Err(Error::Forbidden);
    }
    let limit = bounded(limit, LIMIT_DEFAULT, LIMIT_MAX);
    let (base_count, base_pdu) = match resolve_base_event(s, room, event_id, user, bypass_visibility) {
        Ok(x) => x,
        Err(e) => return Err(e),
    };
    let shortroomid = match svc_timeline::get_shortroomid(s, room) {
        Ok(x) => x,
        Err(e) => return Err(e),
    };
    let before_it = match svc_timeline::pdus_rev(s, room, base_count) {
        Ok(v) => v,
        Err(_) => Vec::new(),
    };
    let after_it = match svc_timeline::pdus(s, room, base_count) {
        Ok(v) => v,
        Err(_) => Vec::new(),
    };
    let events_before = collect_timeline_half(s, user, filter, shortroomid, bypass_visibility, &before_it, limit / 2);
    let events_after = collect_timeline_half(s, user, filter, shortroomid, bypass_visibility, &after_it, limit / 2 + limit % 2);
    let state_at = if events_after.len() == 0 {
        event_id
    } else {
        s.pdus[events_after[events_after.len() - 1].1].event_id
    };
    let state_ids = match load_state_ids(s, room, state_at) {
        Ok(v) => v,
        Err(e) => return Err(e),
    };
    let state = build_state_response(s, &state_ids);
    let start = if events_before.len() == 0 { base_count } else { events_before[events_before.len() - 1].0 };
    let end = if events_after.len() == 0 {
        base_count.saturating_add(1)
    } else {
        events_after[events_after.len() - 1].0
    };
    Ok(Reply::Context {
        event: s.pdus[base_pdu].event_id,
        start,
        end,
        events_before: event_ids(s, &events_before),
        events_after: event_ids(s, &events_after),
        state,
    })
}

/// `resolve_base_event`: the event must be a timeline row of the room, be
/// visible and not be ignored. Remote fetching is off.
pub fn resolve_base_event(s: &Snapshot, room: u64, event_id: u64, user: u64, bypass_visibility: bool) -> Result<(i64, usize), Error> {
    let base_id = match svc_timeline::get_pdu_id(s, event_id) {
        Ok(x) => x,
        Err(_) => return Err(Error::NotFound),
    };
    let base_pdu = match svc_timeline::get_pdu(s, event_id) {
        Ok(x) => x,
        Err(_) => return Err(Error::NotFound),
    };
    let visible = svc_accessor::user_can_see_event(s, user, room, event_id);
    if s.pdus[base_pdu].room != room || s.pdus[base_pdu].event_id != event_id {
        return Err(Error::NotFound);
    }
    if !bypass_visibility && !visible {
        return Err(Error::NotFound);
    }
    if !bypass_visibility && is_ignored_pdu(s, &s.pdus[base_pdu], user) {
        return Err(Error::SenderIgnored);
    }
    Ok((base_id.1, base_pdu))
}

/// `collect_timeline_half`: the filters of `/messages`, then `take`.
pub fn collect_timeline_half(
    s: &Snapshot,
    user: u64,
    filter: &Filter,
    shortroomid: u64,
    bypass_visibility: bool,
    it: &[usize],
    take: u64,
) -> Vec<(i64, usize)> {
    let mut out: Vec<(i64, usize)> = Vec::new();
    let mut i = 0;
    while i < it.len() && (out.len() as u64) < take {
        let p = it[i];
        let c = s.pdus[p].count;
        if passes(s, user, filter, shortroomid, c, p, bypass_visibility) {
            out.push((c, p));
        }
        i += 1;
    }
    out
}

/// `load_state_ids`: the state at `state_at`, else the room's current
/// state.
pub fn load_state_ids(s: &Snapshot, room: u64, state_at: u64) -> Result<Vec<u64>, Error> {
    let hash = match svc_timeline::pdu_shortstatehash(s, state_at) {
        Ok(h) => h,
        Err(_) => match svc_timeline::get_room_shortstatehash(s, room) {
            Ok(h) => h,
            Err(_) => return Err(Error::Database),
        },
    };
    Ok(svc_accessor::state_full_ids(s, hash))
}

/// `build_state_response` without lazy loading: the state events that
/// resolve.
pub fn build_state_response(s: &Snapshot, state_ids: &[u64]) -> Vec<u64> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < state_ids.len() {
        match svc_timeline::get_pdu(s, state_ids[i]) {
            Ok(p) => out.push(s.pdus[p].event_id),
            Err(_) => {}
        }
        i += 1;
    }
    out
}
