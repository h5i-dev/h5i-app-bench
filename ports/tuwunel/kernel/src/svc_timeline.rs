//! `service/rooms/timeline/{mod,pdus}.rs`, `metadata::exists`, and the
//! short-id and state-hash lookups of `short` and `state` they use.
use crate::*;

/// `short::get_shortroomid`.
pub fn get_shortroomid(s: &Snapshot, room: u64) -> Result<u64, Error> {
    let mut i = 0;
    while i < s.rooms.len() {
        if s.rooms[i].id == room {
            return Ok(s.rooms[i].short);
        }
        i += 1;
    }
    Err(Error::NotFound)
}

/// The room whose short id is `short`.
pub fn room_of_short(s: &Snapshot, short: u64) -> Option<u64> {
    let mut i = 0;
    while i < s.rooms.len() {
        if s.rooms[i].short == short {
            return Some(s.rooms[i].id);
        }
        i += 1;
    }
    None
}

/// `state::get_room_shortstatehash`: `roomid_shortstatehash`.
pub fn get_room_shortstatehash(s: &Snapshot, room: u64) -> Result<u64, Error> {
    let mut i = 0;
    while i < s.rooms.len() {
        if s.rooms[i].id == room {
            return match s.rooms[i].state {
                StateRef::Hash(h) => Ok(h),
                StateRef::None => Err(Error::NotFound),
            };
        }
        i += 1;
    }
    Err(Error::NotFound)
}

/// Whether `p` is a timeline row of `room`.
pub fn in_timeline(p: &Pdu, room: u64) -> bool {
    !p.outlier && p.room == room
}

/// `metadata::exists`: the room has a short id and a timeline row.
pub fn exists(s: &Snapshot, room: u64) -> bool {
    match get_shortroomid(s, room) {
        Err(_) => false,
        Ok(_) => has_timeline_row(s, room),
    }
}

fn has_timeline_row(s: &Snapshot, room: u64) -> bool {
    let mut i = 0;
    while i < s.pdus.len() {
        if in_timeline(&s.pdus[i], room) {
            return true;
        }
        i += 1;
    }
    false
}

/// `get_non_outlier`: `eventid_pduid` then `pduid_pdu`.
pub fn get_non_outlier(s: &Snapshot, event_id: u64) -> Result<usize, Error> {
    let mut i = 0;
    while i < s.pdus.len() {
        if !s.pdus[i].outlier && s.pdus[i].event_id == event_id {
            return Ok(i);
        }
        i += 1;
    }
    Err(Error::NotFound)
}

/// `get_outlier`: `eventid_outlierpdu`.
pub fn get_outlier(s: &Snapshot, event_id: u64) -> Result<usize, Error> {
    let mut i = 0;
    while i < s.pdus.len() {
        if s.pdus[i].outlier && s.pdus[i].event_id == event_id {
            return Ok(i);
        }
        i += 1;
    }
    Err(Error::NotFound)
}

/// `get_pdu` (`get`): the accepted row, else the outlier.
pub fn get_pdu(s: &Snapshot, event_id: u64) -> Result<usize, Error> {
    match get_non_outlier(s, event_id) {
        Ok(i) => Ok(i),
        Err(_) => get_outlier(s, event_id),
    }
}

/// `get_pdu_id`: the event's `(shortroomid, count)`; outliers have none.
pub fn get_pdu_id(s: &Snapshot, event_id: u64) -> Result<(u64, i64), Error> {
    match get_non_outlier(s, event_id) {
        Err(e) => Err(e),
        Ok(i) => match get_shortroomid(s, s.pdus[i].room) {
            Err(e) => Err(e),
            Ok(short) => Ok((short, s.pdus[i].count)),
        },
    }
}

/// `get_pdu_count`.
pub fn get_pdu_count(s: &Snapshot, event_id: u64) -> Result<i64, Error> {
    match get_pdu_id(s, event_id) {
        Err(e) => Err(e),
        Ok((_, c)) => Ok(c),
    }
}

/// `get_pdu_from_id`: the timeline row at `(shortroomid, count)`.
pub fn get_pdu_from_id(s: &Snapshot, short: u64, count: i64) -> Result<usize, Error> {
    match room_of_short(s, short) {
        None => Err(Error::NotFound),
        Some(room) => find_row(s, room, count),
    }
}

fn find_row(s: &Snapshot, room: u64, count: i64) -> Result<usize, Error> {
    let mut i = 0;
    while i < s.pdus.len() {
        if in_timeline(&s.pdus[i], room) && s.pdus[i].count == count {
            return Ok(i);
        }
        i += 1;
    }
    Err(Error::NotFound)
}

/// `pdus`: the room's timeline after `from` (exclusive) in count order.
/// `pdu_count_to_id` moves the bound one step forward, so with only normal
/// rows stored this is every row with a count above `from`.
pub fn pdus(s: &Snapshot, room: u64, from: i64) -> Result<Vec<usize>, Error> {
    match get_shortroomid(s, room) {
        Err(e) => Err(e),
        Ok(_) => {
            let mut out = Vec::new();
            let mut i = 0;
            while i < s.pdus.len() {
                if in_timeline(&s.pdus[i], room) && s.pdus[i].count > from {
                    out.push(i);
                }
                i += 1;
            }
            Ok(out)
        }
    }
}

/// `pdus_rev`: the room's timeline before `until` (exclusive), newest
/// first.
pub fn pdus_rev(s: &Snapshot, room: u64, until: i64) -> Result<Vec<usize>, Error> {
    match get_shortroomid(s, room) {
        Err(e) => Err(e),
        Ok(_) => {
            let mut out = Vec::new();
            let mut i = s.pdus.len();
            while i > 0 {
                i -= 1;
                if in_timeline(&s.pdus[i], room) && s.pdus[i].count < until {
                    out.push(i);
                }
            }
            Ok(out)
        }
    }
}

/// `state::get_shortstatehash` of a PDU: `shorteventid_shortstatehash`.
pub fn state_of(p: &Pdu) -> Result<u64, Error> {
    match p.state {
        StateRef::Hash(h) => Ok(h),
        StateRef::None => Err(Error::NotFound),
    }
}

/// `state::pdu_shortstatehash`: the state recorded for an event, accepted
/// or outlier.
pub fn pdu_shortstatehash(s: &Snapshot, event_id: u64) -> Result<u64, Error> {
    match get_pdu(s, event_id) {
        Err(e) => Err(e),
        Ok(i) => state_of(&s.pdus[i]),
    }
}

/// `next_timeline_count`: the first count of the room above `after`.
pub fn next_timeline_count(s: &Snapshot, room: u64, after: i64) -> Result<i64, Error> {
    let mut i = 0;
    while i < s.pdus.len() {
        if in_timeline(&s.pdus[i], room) && s.pdus[i].count > after {
            return Ok(s.pdus[i].count);
        }
        i += 1;
    }
    Err(Error::NotFound)
}

/// `get_shorteventid_from_pdu_id` then `state::get_shortstatehash`.
fn shortstatehash_at(s: &Snapshot, short: u64, count: i64) -> Result<u64, Error> {
    match get_pdu_from_id(s, short, count) {
        Err(e) => Err(e),
        Ok(i) => state_of(&s.pdus[i]),
    }
}

/// `next_shortstatehash`: the state at the room event directly after
/// `after`.
pub fn next_shortstatehash(s: &Snapshot, room: u64, after: i64) -> Result<u64, Error> {
    match get_shortroomid(s, room) {
        Err(_) => Err(Error::NotFound),
        Ok(short) => match next_timeline_count(s, room, after) {
            Err(e) => Err(e),
            Ok(c) => shortstatehash_at(s, short, c),
        },
    }
}

/// `shortstatehash_after`: the state before the first event after `count`,
/// or the current state when none follows.
pub fn shortstatehash_after(s: &Snapshot, room: u64, count: i64) -> Result<u64, Error> {
    match get_shortroomid(s, room) {
        Err(_) => Err(Error::NotFound),
        Ok(short) => match next_timeline_count(s, room, count) {
            Err(_) => get_room_shortstatehash(s, room),
            Ok(c) => shortstatehash_at(s, short, c),
        },
    }
}

/// `last_timeline_count(None, room, None)`: the newest count, or
/// `PduCount::max()` without one.
pub fn last_timeline_count(s: &Snapshot, room: u64) -> Result<i64, Error> {
    match pdus_rev(s, room, COUNT_MAX) {
        Err(e) => Err(e),
        Ok(v) => {
            if v.len() == 0 {
                Ok(COUNT_MAX)
            } else {
                let c = s.pdus[v[0]].count;
                if c > 0 { Ok(c) } else { Ok(COUNT_MAX) }
            }
        }
    }
}
