//! `service/rooms/state_cache/mod.rs`: the membership index reads.
use crate::*;

fn has_row(rows: &[UserRoom], user: u64, room: u64) -> bool {
    let mut i = 0;
    while i < rows.len() {
        if rows[i].user == user && rows[i].room == room {
            return true;
        }
        i += 1;
    }
    false
}

/// `user_membership`: join, leave, knock, then invite; a once-joined user
/// with none of these is reported as `Ban`.
pub fn user_membership(s: &Snapshot, user: u64, room: u64) -> Option<Membership> {
    let joined = is_joined(s, user, room);
    let left = is_left(s, user, room);
    let knocked = is_knocked(s, user, room);
    let invited = is_invited(s, user, room);
    let once = once_joined(s, user, room);
    if joined {
        Some(Membership::Join)
    } else if left {
        Some(Membership::Leave)
    } else if knocked {
        Some(Membership::Knock)
    } else if invited {
        Some(Membership::Invite)
    } else if once {
        Some(Membership::Ban)
    } else {
        None
    }
}

/// `once_joined`: `roomuseroncejoinedids`.
pub fn once_joined(s: &Snapshot, user: u64, room: u64) -> bool {
    has_row(&s.once_joined, user, room)
}

/// `is_joined`: `userroomid_joinedcount`.
pub fn is_joined(s: &Snapshot, user: u64, room: u64) -> bool {
    has_row(&s.joined, user, room)
}

/// `is_knocked`: `userroomid_knockedstate`.
pub fn is_knocked(s: &Snapshot, user: u64, room: u64) -> bool {
    has_row(&s.knocked, user, room)
}

/// `is_invited`: `userroomid_invitestate`.
pub fn is_invited(s: &Snapshot, user: u64, room: u64) -> bool {
    has_row(&s.invited, user, room)
}

/// `is_left`: `userroomid_leftstate`.
pub fn is_left(s: &Snapshot, user: u64, room: u64) -> bool {
    let mut i = 0;
    while i < s.left.len() {
        if s.left[i].user == user && s.left[i].room == room {
            return true;
        }
        i += 1;
    }
    false
}

/// `get_left_count`: `roomuserid_leftcount`; a missing row is an error.
pub fn get_left_count(s: &Snapshot, room: u64, user: u64) -> Result<u64, Error> {
    let mut i = 0;
    while i < s.left.len() {
        if s.left[i].user == user && s.left[i].room == room {
            return Ok(s.left[i].count);
        }
        i += 1;
    }
    Err(Error::NotFound)
}

/// `room_members`: the joined users of a room.
pub fn room_members(s: &Snapshot, room: u64) -> Vec<u64> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < s.joined.len() {
        if s.joined[i].room == room {
            out.push(s.joined[i].user);
        }
        i += 1;
    }
    out
}
