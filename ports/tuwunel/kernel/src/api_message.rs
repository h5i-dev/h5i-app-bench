//! `api/client/message.rs`: `/messages` and the event filters it shares
//! with `/context`, `/relations` and `initialSync`.
use crate::*;

pub const LIMIT_MAX: u64 = 1000;
pub const LIMIT_DEFAULT: u64 = 10;

/// `get_message_events_route`.
pub fn get_message_events_route(
    s: &Snapshot,
    user: u64,
    room: u64,
    from: Token,
    to: Token,
    dir: Dir,
    limit: u64,
    filter: &Filter,
) -> Result<Reply, Error> {
    get_messages(s, user, room, from, to, dir, Some(limit), filter, false)
}

/// `usize_from_ruma_bounded(limit, default, max)`.
pub fn bounded(limit: Option<u64>, default: u64, max: u64) -> u64 {
    match limit {
        None => default,
        Some(l) => {
            if l < max { l } else { max }
        }
    }
}

/// `reached_to`: the `to` bound, inclusive, in the direction of travel.
pub fn reached_to(to: Option<i64>, dir: Dir, count: i64) -> bool {
    match to {
        None => false,
        Some(t) => match dir {
            Dir::Forward => count >= t,
            Dir::Backward => count <= t,
        },
    }
}

/// `get_messages`.
pub fn get_messages(
    s: &Snapshot,
    user: u64,
    room: u64,
    from: Token,
    to: Token,
    dir: Dir,
    limit: Option<u64>,
    filter: &Filter,
    bypass_visibility: bool,
) -> Result<Reply, Error> {
    if !svc_timeline::exists(s, room) {
        return Err(Error::Forbidden);
    }
    if !bypass_visibility && !svc_accessor::user_can_see_room(s, user, room) {
        return Err(Error::Forbidden);
    }
    let from = match from {
        Token::Invalid => return Err(Error::InvalidParam),
        Token::At(c) => c,
        Token::Absent => match dir {
            Dir::Forward => COUNT_MIN,
            Dir::Backward => COUNT_MAX,
        },
    };
    let to = match to {
        Token::Invalid => return Err(Error::InvalidParam),
        Token::At(c) => Some(c),
        Token::Absent => None,
    };
    let limit = bounded(limit, LIMIT_DEFAULT, LIMIT_MAX);
    let it = match dir {
        Dir::Forward => svc_timeline::pdus(s, room, from),
        Dir::Backward => svc_timeline::pdus_rev(s, room, from),
    };
    let it = match it {
        Ok(v) => v,
        Err(_) => Vec::new(),
    };
    let shortroomid = match svc_timeline::get_shortroomid(s, room) {
        Ok(x) => x,
        Err(e) => return Err(e),
    };
    let (events, scanned) = scan(s, user, &it, to, dir, limit, filter, shortroomid, bypass_visibility);
    let stopped_at_to = match scanned {
        Some(c) => reached_to(to, dir, c),
        None => false,
    };
    let exhausted = matches!(dir, Dir::Backward) && (events.len() as u64) < limit && !stopped_at_to;
    let next_token = if exhausted { scanned } else { last_count(&events) };
    Ok(Reply::Messages { start: from, end: next_token, chunk: event_ids(s, &events) })
}

/// The stream of `get_messages`: `inspect` records the count scanned,
/// `take_while` stops at `to`, the filters run, and `take(limit)` stops
/// once `limit` events passed.
fn scan(
    s: &Snapshot,
    user: u64,
    it: &[usize],
    to: Option<i64>,
    dir: Dir,
    limit: u64,
    filter: &Filter,
    shortroomid: u64,
    bypass_visibility: bool,
) -> (Vec<(i64, usize)>, Option<i64>) {
    let mut events: Vec<(i64, usize)> = Vec::new();
    let mut scanned = None;
    let mut done = false;
    let mut i = 0;
    while !done && i < it.len() && (events.len() as u64) < limit {
        let p = it[i];
        let c = s.pdus[p].count;
        scanned = Some(c);
        if reached_to(to, dir, c) {
            done = true;
        } else {
            if passes(s, user, filter, shortroomid, c, p, bypass_visibility) {
                events.push((c, p));
            }
            i += 1;
        }
    }
    (events, scanned)
}

/// `event_filter`, `related_by_filter` and `event_filters`, in the order
/// of the stream.
pub fn passes(s: &Snapshot, user: u64, filter: &Filter, shortroomid: u64, count: i64, p: usize, bypass_visibility: bool) -> bool {
    event_filter(s, p, filter)
        && related_by_filter(s, shortroomid, filter, count)
        && event_filters(s, user, p, bypass_visibility)
}

pub fn last_count(events: &[(i64, usize)]) -> Option<i64> {
    if events.len() == 0 { None } else { Some(events[events.len() - 1].0) }
}

pub fn event_ids(s: &Snapshot, events: &[(i64, usize)]) -> Vec<u64> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < events.len() {
        out.push(s.pdus[events[i].1].event_id);
        i += 1;
    }
    out
}

/// `event_filters`: not ignored, then visible.
pub fn event_filters(s: &Snapshot, user: u64, p: usize, bypass_visibility: bool) -> bool {
    if bypass_visibility {
        return true;
    }
    ignored_filter(s, p, user) && visibility_filter(s, p, user)
}

/// `related_by_filter` (MSC3440): with `related_by_*` set, some event must
/// relate to this one accordingly.
pub fn related_by_filter(s: &Snapshot, shortroomid: u64, filter: &Filter, count: i64) -> bool {
    if filter.related_by_senders.len() == 0 && filter.related_by_rel_types.len() == 0 {
        return true;
    }
    svc_relations::has_incoming_relation(s, shortroomid, count, &filter.related_by_senders, &filter.related_by_rel_types)
}

/// `ignored_filter`.
pub fn ignored_filter(s: &Snapshot, p: usize, user: u64) -> bool {
    !is_ignored_pdu(s, &s.pdus[p], user)
}

/// `IGNORED_MESSAGE_TYPES` among the modeled types.
pub fn is_ignored_message_type(k: Kind) -> bool {
    matches!(k, Kind::Message | Kind::Reaction | Kind::Encrypted | Kind::Sticker)
}

/// `users.user_is_ignored(sender, user)`.
pub fn user_is_ignored(s: &Snapshot, sender: u64, user: u64) -> bool {
    let mut i = 0;
    while i < s.ignored.len() {
        if s.ignored[i].user == user && s.ignored[i].ignored == sender {
            return true;
        }
        i += 1;
    }
    false
}

/// `is_ignored_pdu`: dummy events always; message-like events from a
/// forbidden server or an ignored sender.
pub fn is_ignored_pdu(s: &Snapshot, p: &Pdu, user: u64) -> bool {
    if matches!(p.kind, Kind::Dummy) {
        return true;
    }
    if !is_ignored_message_type(p.kind) {
        return false;
    }
    let ignored_server = filters::is_forbidden_remote_server_name(&s.config, server_name(p.sender));
    ignored_server || user_is_ignored(s, p.sender, user)
}

/// `visibility_filter`: `user_can_see_event` in the event's own room.
pub fn visibility_filter(s: &Snapshot, p: usize, user: u64) -> bool {
    svc_accessor::user_can_see_event(s, user, s.pdus[p].room, s.pdus[p].event_id)
}

/// `event_filter`.
pub fn event_filter(s: &Snapshot, p: usize, filter: &Filter) -> bool {
    filters::matches(filter, &s.pdus[p])
}
