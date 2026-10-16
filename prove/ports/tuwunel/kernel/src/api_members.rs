//! `api/client/membership/members.rs`.
use crate::*;

fn membership_filter(m: Membership, membership: Option<Membership>, not_membership: Option<Membership>) -> bool {
    let a = match membership {
        None => true,
        Some(x) => membership_eq(x, m),
    };
    let b = match not_membership {
        None => true,
        Some(x) => !membership_eq(x, m),
    };
    a && b
}

/// `get_member_events_route`: the member events of the current state, or
/// of the state after the `at` token.
pub fn get_member_events_route(
    s: &Snapshot,
    user: u64,
    room: u64,
    at: Token,
    membership: Option<Membership>,
    not_membership: Option<Membership>,
) -> Result<Reply, Error> {
    if !svc_accessor::user_can_see_state_events(s, user, room) {
        return Err(Error::Forbidden);
    }
    let at = match at {
        Token::Invalid => return Err(Error::InvalidParam),
        Token::At(c) => Some(c),
        Token::Absent => None,
    };
    let shortstatehash = match at {
        None => match svc_timeline::get_room_shortstatehash(s, room) {
            Ok(h) => h,
            Err(_) => return Err(Error::Database),
        },
        Some(c) => match svc_timeline::shortstatehash_after(s, room, c) {
            Ok(h) => h,
            Err(e) => return Err(e),
        },
    };
    let v = svc_accessor::state_full(s, shortstatehash);
    let mut chunk = Vec::new();
    let mut i = 0;
    while i < v.len() {
        let p = &s.pdus[v[i]];
        if matches!(p.kind, Kind::Member) {
            match p.membership {
                MemberField::Is(m) => {
                    if membership_filter(m, membership, not_membership) {
                        chunk.push(p.event_id);
                    }
                }
                MemberField::Absent => {}
            }
        }
        i += 1;
    }
    Ok(Reply::Members { chunk })
}

/// `joined_members_route`: the senders of the current `join` member events.
pub fn joined_members_route(s: &Snapshot, user: u64, room: u64) -> Result<Reply, Error> {
    let is_joined = svc_cache::is_joined(s, user, room);
    let is_world_readable = match svc_accessor::room_history_visibility(s, room) {
        Some(HistoryVisibility::WorldReadable) => true,
        _ => false,
    };
    if !(is_joined || is_world_readable) {
        return Err(Error::Forbidden);
    }
    let v = match svc_accessor::room_state_full(s, room) {
        Ok(v) => v,
        Err(_) => Vec::new(),
    };
    let mut joined = Vec::new();
    let mut i = 0;
    while i < v.len() {
        let p = &s.pdus[v[i]];
        if matches!(p.kind, Kind::Member) && matches!(p.membership, MemberField::Is(Membership::Join)) {
            joined.push(p.sender);
        }
        i += 1;
    }
    Ok(Reply::JoinedMembers { joined })
}
