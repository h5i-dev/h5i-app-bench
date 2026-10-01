//! `api/client/relations.rs`: `/relations`.
use crate::*;
use crate::api_message::is_ignored_pdu;

/// One `fetch` stream of the recursion: its depth, the `get_relations`
/// rows (an index into the list arena) and the next position.
pub struct Fetch {
    pub depth: u64,
    pub list: usize,
    pub pos: usize,
}

/// `paginate_relations_with_filter`.
pub fn paginate_relations_with_filter(
    s: &Snapshot,
    user: u64,
    room: u64,
    target: u64,
    filter_event_type: Option<Kind>,
    filter_rel_type: Option<RelType>,
    from: Token,
    to: Token,
    limit: Option<u64>,
    recurse: bool,
    dir: Dir,
) -> Result<Reply, Error> {
    let from = match from {
        Token::Invalid => return Err(Error::Parse),
        Token::At(c) => Some(c),
        Token::Absent => None,
    };
    let to = match to {
        Token::At(c) => Some(c),
        _ => None,
    };
    let max_depth: u64 = if recurse { 3 } else { 0 };
    let limit = api_message::bounded(limit, 30, 100);
    let shortroomid = match svc_timeline::get_shortroomid(s, room) {
        Ok(x) => x,
        Err(e) => return Err(e),
    };
    // `try_join3(shortroomid, target, visible)`: `target` wraps only its
    // success in `Ok`, so a missing event fails the join.
    let (target_short, target_count) = match svc_timeline::get_pdu_id(s, target) {
        Ok(x) => x,
        Err(e) => return Err(e),
    };
    if !svc_accessor::user_can_see_state_events(s, user, room) {
        return Err(Error::Forbidden);
    }
    if shortroomid != target_short {
        return Err(Error::NotFound);
    }
    if target_count <= 0 {
        return Ok(empty());
    }
    match svc_timeline::get_pdu(s, target) {
        Ok(tp) => {
            if is_ignored_pdu(s, &s.pdus[tp], user) {
                return Err(Error::SenderIgnored);
            }
        }
        Err(_) => {}
    }
    let events = walk(s, user, shortroomid, target_count, from, dir, max_depth, to, filter_event_type, filter_rel_type, limit);
    let recursion_depth = if max_depth > 0 { max_depth_of(&events) } else { None };
    let next_batch = if events.len() == 0 { None } else { Some(events[events.len() - 1].1) };
    let prev_batch = if events.len() == 0 { from } else { Some(events[0].1) };
    let mut chunk = Vec::new();
    let mut i = 0;
    while i < events.len() {
        chunk.push(s.pdus[events[i].2].event_id);
        i += 1;
    }
    Ok(Reply::Relations { chunk, next_batch, prev_batch, recursion_depth })
}

fn empty() -> Reply {
    Reply::Relations { chunk: Vec::new(), next_batch: None, prev_batch: None, recursion_depth: None }
}

fn max_depth_of(events: &[(u64, i64, usize)]) -> Option<u64> {
    if events.len() == 0 {
        return None;
    }
    let mut m = 0;
    let mut i = 0;
    while i < events.len() {
        if events[i].0 > m {
            m = events[i].0;
        }
        i += 1;
    }
    Some(m)
}

/// `fetch`: `get_relations` keeping `Normal` counts.
pub fn fetch(s: &Snapshot, shortroomid: u64, count: i64, from: Option<i64>, dir: Dir) -> Vec<(i64, usize)> {
    let rels = svc_relations::get_relations(s, shortroomid, count, from, dir);
    let mut out = Vec::new();
    let mut i = 0;
    while i < rels.len() {
        if rels[i].0 > 0 {
            out.push(rels[i]);
        }
        i += 1;
    }
    out
}

/// The `unfold` over `select_all`: streams are polled in turn, a stream that
/// yields goes back to the end of the queue, followed by the stream of the
/// relations of the yielded event while `depth < max_depth`. Downstream:
/// `take_while(count != to)`, the event and relation type filters,
/// `user_can_see_event`, and `take(limit)`.
pub fn walk(
    s: &Snapshot,
    user: u64,
    shortroomid: u64,
    target_count: i64,
    from: Option<i64>,
    dir: Dir,
    max_depth: u64,
    to: Option<i64>,
    filter_event_type: Option<Kind>,
    filter_rel_type: Option<RelType>,
    limit: u64,
) -> Vec<(u64, i64, usize)> {
    let mut lists: Vec<Vec<(i64, usize)>> = Vec::new();
    lists.push(fetch(s, shortroomid, target_count, from, dir));
    let mut queue: Vec<Fetch> = Vec::new();
    queue.push(Fetch { depth: 0, list: 0, pos: 0 });
    let mut out: Vec<(u64, i64, usize)> = Vec::new();
    let mut done = false;
    let mut qi = 0;
    while !done && qi < queue.len() && (out.len() as u64) < limit {
        let depth = queue[qi].depth;
        let list = queue[qi].list;
        let pos = queue[qi].pos;
        qi += 1;
        if pos < lists[list].len() {
            let (count, p) = lists[list][pos];
            queue.push(Fetch { depth, list, pos: pos + 1 });
            if depth < max_depth {
                let child = fetch(s, shortroomid, count, from, dir);
                lists.push(child);
                queue.push(Fetch { depth: depth + 1, list: lists.len() - 1, pos: 0 });
            }
            let at_to = match to {
                Some(t) => count == t,
                None => false,
            };
            if at_to {
                done = true;
            } else if keep(s, user, &s.pdus[p], filter_event_type, filter_rel_type) {
                out.push((depth, count, p));
            }
        }
    }
    out
}

/// The event type, relation type and visibility filters.
fn keep(s: &Snapshot, user: u64, p: &Pdu, filter_event_type: Option<Kind>, filter_rel_type: Option<RelType>) -> bool {
    let type_ok = match filter_event_type {
        None => true,
        Some(k) => kind_eq(k, p.kind),
    };
    let rel_ok = match filter_rel_type {
        None => true,
        Some(r) => svc_relations::relation_type_equal(r, p),
    };
    type_ok && rel_ok && svc_accessor::user_can_see_event(s, user, p.room, p.event_id)
}
