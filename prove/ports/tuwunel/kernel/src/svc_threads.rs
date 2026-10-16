//! `service/rooms/threads/mod.rs`: `threads_until` and its helpers.
use crate::*;

/// `threads_until`: the room's thread activity rows below `count`, newest
/// first, each resolved to its root by `live_thread`.
pub fn threads_until(s: &Snapshot, user: u64, room: u64, count: i64, participated: bool) -> Result<Vec<(i64, usize)>, Error> {
    match svc_timeline::get_shortroomid(s, room) {
        Err(e) => Err(e),
        Ok(short) => {
            let mut out = Vec::new();
            let mut i = s.thread_activity.len();
            while i > 0 {
                i -= 1;
                let a = &s.thread_activity[i];
                if a.room_short == short && (a.count as i64) < count {
                    match live_thread(s, user, participated, short, a.count, a.root) {
                        Some(x) => out.push(x),
                        None => {}
                    }
                }
            }
            Ok(out)
        }
    }
}

/// `live_thread`: the root, if this row is the thread's latest activity
/// (and the user took part, when asked).
pub fn live_thread(s: &Snapshot, user: u64, participated: bool, short: u64, activity: u64, root: u64) -> Option<(i64, usize)> {
    let count = activity as i64;
    match latest_count(s, short, root) {
        None => None,
        Some(pointer) => {
            if count != pointer as i64 {
                return None;
            }
            if participated && !is_participant(s, short, root, user) {
                return None;
            }
            match svc_timeline::get_pdu_from_id(s, short, root as i64) {
                Err(_) => None,
                Ok(p) => Some((count, p)),
            }
        }
    }
}

/// `threadrootid_latestcount`.
fn latest_count(s: &Snapshot, short: u64, root: u64) -> Option<u64> {
    let mut i = 0;
    while i < s.thread_latest.len() {
        if s.thread_latest[i].room_short == short && s.thread_latest[i].root == root {
            return Some(s.thread_latest[i].latest);
        }
        i += 1;
    }
    None
}

/// `is_participant`: `threadid_userids` holds the user.
pub fn is_participant(s: &Snapshot, short: u64, root: u64, user: u64) -> bool {
    let mut i = 0;
    while i < s.thread_participants.len() {
        let t = &s.thread_participants[i];
        if t.room_short == short && t.root == root {
            return contains_u64(&t.users, user);
        }
        i += 1;
    }
    false
}
