//! `api/client/threads.rs`: `/threads`.
use crate::*;

/// `get_threads_route`. The ignore-list view (MSC3856) changes how a root
/// is presented, not which roots are listed.
pub fn get_threads_route(s: &Snapshot, user: u64, room: u64, from: Token, limit: Option<u64>, participated: bool) -> Result<Reply, Error> {
    if !svc_timeline::exists(s, room) {
        return Err(Error::Forbidden);
    }
    if !svc_accessor::user_can_see_room(s, user, room) {
        return Err(Error::Forbidden);
    }
    let limit = match limit {
        Some(l) => {
            if l < 100 { l } else { 100 }
        }
        None => 10,
    };
    let from = match from {
        Token::Invalid => return Err(Error::Parse),
        Token::At(c) => c,
        Token::Absent => COUNT_MAX,
    };
    let all = match svc_threads::threads_until(s, user, room, from, participated) {
        Ok(v) => v,
        Err(e) => return Err(e),
    };
    let mut threads: Vec<(i64, usize)> = Vec::new();
    let mut i = 0;
    while i < all.len() && (threads.len() as u64) < limit + 1 {
        let (count, p) = all[i];
        if svc_accessor::user_can_see_event(s, user, room, s.pdus[p].event_id) {
            threads.push((count, p));
        }
        i += 1;
    }
    let more = (threads.len() as u64) > limit;
    let threads = truncate(&threads, limit);
    let next_batch = if more { api_message::last_count(&threads) } else { None };
    Ok(Reply::Threads { chunk: api_message::event_ids(s, &threads), next_batch })
}

/// `Vec::truncate`.
fn truncate(v: &[(i64, usize)], n: u64) -> Vec<(i64, usize)> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < v.len() && (i as u64) < n {
        out.push(v[i]);
        i += 1;
    }
    out
}
