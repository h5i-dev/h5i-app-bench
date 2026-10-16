//! `api/client/state.rs`: the state reads.
use crate::*;

/// `get_state_events_route`: the room's current state.
pub fn get_state_events_route(s: &Snapshot, user: u64, room: u64) -> Result<Reply, Error> {
    if !svc_accessor::user_can_see_state_events(s, user, room) {
        return Err(Error::Forbidden);
    }
    match svc_accessor::room_state_full_pdus(s, room) {
        Err(e) => Err(e),
        Ok(v) => {
            let mut events = Vec::new();
            let mut i = 0;
            while i < v.len() {
                events.push(s.pdus[v[i]].event_id);
                i += 1;
            }
            Ok(Reply::State { events })
        }
    }
}

/// `get_state_events_for_key_route`: one current state event.
pub fn get_state_events_for_key_route(s: &Snapshot, user: u64, room: u64, kind: Kind, state_key: u64) -> Result<Reply, Error> {
    if !svc_accessor::user_can_see_state_events(s, user, room) {
        return Err(Error::NotFound);
    }
    match svc_accessor::room_state_get(s, room, kind, state_key) {
        Err(_) => Err(Error::NotFound),
        Ok(p) => Ok(Reply::StateEvent { event: s.pdus[p].event_id }),
    }
}
