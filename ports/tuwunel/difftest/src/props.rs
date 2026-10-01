//! Falsification tests for the statements in proofs/Properties.lean. Each
//! checks its property on random snapshots and requests and counts how often
//! the premises hold (with a non-empty reply where that matters), so a
//! statement that is false, or true only because its premises never hold,
//! fails here. The helpers transcribe proofs/Spec.lean.
use tuwunel_kernel::*;

use crate::generate::{Rng, SERVERS, STRANGER, USERS, filter, request, snapshot};

const SNAPSHOTS: usize = 4_000;
/// Each property's premises must hold in at least this many cases.
const MIN_HITS: usize = 300;

// ---- Spec.lean ----

fn timeline(s: &Snapshot) -> impl Iterator<Item = &Pdu> {
    s.pdus.iter().filter(|p| !p.outlier)
}

fn event_of(s: &Snapshot, e: u64) -> Option<&Pdu> {
    timeline(s).find(|p| p.event_id == e).or_else(|| s.pdus.iter().filter(|p| p.outlier).find(|p| p.event_id == e))
}

fn count_of(s: &Snapshot, e: u64) -> Option<i64> {
    timeline(s).find(|p| p.event_id == e).map(|p| p.count)
}

fn in_room(s: &Snapshot, room: u64, e: u64) -> bool {
    timeline(s).any(|p| p.event_id == e && p.room == room)
}

fn nodup(mut v: Vec<u64>) -> bool {
    let n = v.len();
    v.sort();
    v.dedup();
    v.len() == n
}

fn keys(s: &Snapshot) -> bool {
    nodup(s.pdus.iter().map(|p| p.event_id).collect())
        && nodup(s.rooms.iter().map(|r| r.id).collect())
        && nodup(s.rooms.iter().map(|r| r.short).collect())
}

fn sorted(s: &Snapshot) -> bool {
    let c: Vec<i64> = timeline(s).map(|p| p.count).collect();
    c.windows(2).all(|w| w[0] < w[1])
}

fn state_entries(s: &Snapshot, h: u64) -> Option<&Vec<StateEntry>> {
    s.states.iter().find(|x| x.hash == h).map(|x| &x.entries)
}

fn state_lookup(s: &Snapshot, h: u64, k: Kind, key: u64) -> Option<&Pdu> {
    let en = state_entries(s, h)?.iter().find(|en| en.kind == k && en.state_key == key)?;
    event_of(s, en.event_id)
}

fn room_state(s: &Snapshot, room: u64) -> Option<u64> {
    match s.rooms.iter().find(|r| r.id == room)?.state {
        StateRef::Hash(h) => Some(h),
        StateRef::None => None,
    }
}

fn membership_at(s: &Snapshot, h: u64, u: u64) -> Membership {
    match state_lookup(s, h, Kind::Member, u).map(|p| p.membership) {
        Some(MemberField::Is(m)) => m,
        _ => Membership::Leave,
    }
}

fn visibility_at(s: &Snapshot, h: u64) -> HistoryVisibility {
    match state_lookup(s, h, Kind::HistoryVisibility, 0).map(|p| p.history_visibility) {
        Some(HvField::Is(v)) => v,
        _ => HistoryVisibility::Shared,
    }
}

fn world_readable_now(s: &Snapshot, room: u64) -> bool {
    room_state(s, room).is_some_and(|h| {
        state_lookup(s, h, Kind::HistoryVisibility, 0)
            .is_some_and(|p| p.history_visibility == HvField::Is(HistoryVisibility::WorldReadable))
    })
}

fn joined(s: &Snapshot, u: u64, room: u64) -> bool {
    s.joined.iter().any(|x| x.user == u && x.room == room)
}
fn invited(s: &Snapshot, u: u64, room: u64) -> bool {
    s.invited.iter().any(|x| x.user == u && x.room == room)
}
fn once_joined(s: &Snapshot, u: u64, room: u64) -> bool {
    s.once_joined.iter().any(|x| x.user == u && x.room == room)
}
fn left_count(s: &Snapshot, u: u64, room: u64) -> Option<u64> {
    s.left.iter().find(|x| x.user == u && x.room == room).map(|x| x.count)
}
fn to_signed(l: u64) -> i128 {
    if (l as u128) < (1u128 << 63) { l as i128 } else { l as i128 - (1i128 << 64) }
}

fn visible(s: &Snapshot, u: u64, room: u64, e: u64) -> bool {
    let Some(p) = event_of(s, e) else { return true };
    let StateRef::Hash(h) = p.state else { return true };
    match visibility_at(s, h) {
        HistoryVisibility::WorldReadable => true,
        HistoryVisibility::Invited => matches!(membership_at(s, h, u), Membership::Join | Membership::Invite),
        HistoryVisibility::Joined => membership_at(s, h, u) == Membership::Join,
        _ => {
            joined(s, u, room)
                || membership_at(s, h, u) == Membership::Join
                || (once_joined(s, u, room)
                    && match (left_count(s, u, room), count_of(s, e)) {
                        (Some(l), Some(c)) => (c as i128) <= to_signed(l),
                        _ => false,
                    })
        }
    }
}

fn matrix_visible(s: &Snapshot, u: u64, room: u64, e: u64) -> bool {
    let Some(p) = event_of(s, e) else { return false };
    let StateRef::Hash(h) = p.state else { return false };
    let v = visibility_at(s, h);
    v == HistoryVisibility::WorldReadable
        || membership_at(s, h, u) == Membership::Join
        || (v == HistoryVisibility::Shared
            && (joined(s, u, room)
                || timeline(s).any(|q| {
                    q.room == room
                        && q.kind == Kind::Member
                        && q.state_key == u
                        && q.membership == MemberField::Is(Membership::Join)
                        && p.count < q.count
                })))
        || (v == HistoryVisibility::Invited && membership_at(s, h, u) == Membership::Invite)
}

fn message_like(k: Kind) -> bool {
    matches!(k, Kind::Message | Kind::Reaction | Kind::Encrypted | Kind::Sticker)
}

fn forbidden(c: &Config, server: u64) -> bool {
    server != c.server_name
        && (c.forbidden_remote_server_names.contains(&server)
            || (!c.allowed_remote_server_names.is_empty() && !c.allowed_remote_server_names.contains(&server)))
}

fn ignored(s: &Snapshot, u: u64, p: &Pdu) -> bool {
    p.kind == Kind::Dummy
        || (message_like(p.kind)
            && (forbidden(&s.config, p.sender / 1000) || s.ignored.iter().any(|i| i.user == u && i.ignored == p.sender)))
}

fn latest_before(s: &Snapshot, room: u64, k: Kind, key: u64, c: i64) -> Option<&Pdu> {
    timeline(s)
        .filter(|p| p.room == room && p.kind == k && p.has_state_key && p.state_key == key && p.count < c)
        .last()
}

/// `StateConsistent`, over the types and keys that occur.
fn state_consistent(s: &Snapshot) -> bool {
    let mut tk: Vec<(Kind, u64)> = timeline(s).filter(|p| p.has_state_key).map(|p| (p.kind, p.state_key)).collect();
    for st in &s.states {
        tk.extend(st.entries.iter().map(|e| (e.kind, e.state_key)));
    }
    timeline(s).all(|q| match q.state {
        StateRef::None => true,
        StateRef::Hash(h) => tk.iter().all(|&(k, key)| {
            state_lookup(s, h, k, key).map(|p| p.event_id) == latest_before(s, q.room, k, key, q.count).map(|p| p.event_id)
        }),
    })
}

fn last_membership(s: &Snapshot, u: u64, room: u64) -> Option<&Pdu> {
    let ms: Vec<&Pdu> =
        timeline(s).filter(|q| q.room == room && q.kind == Kind::Member && q.has_state_key && q.state_key == u).collect();
    let p = *ms.iter().max_by_key(|q| q.count)?;
    ms.iter().all(|q| q.count <= p.count).then_some(p)
}

// ---- drivers ----

fn run(mut check: impl FnMut(&mut Rng, &Snapshot) -> usize) -> usize {
    let mut rng = Rng(0x2545_f491_4f6c_dd1d);
    let mut hits = 0;
    for _ in 0..SNAPSHOTS {
        let b = snapshot(&mut rng);
        hits += check(&mut rng, &b.snapshot);
    }
    hits
}

fn requests(rng: &mut Rng, s: &Snapshot, n: usize, keep: impl Fn(&Op) -> bool) -> Vec<Request> {
    let mut v = Vec::new();
    let mut tries = 0;
    while v.len() < n && tries < 40 * n {
        let r = request(rng, s);
        if keep(&r.op) {
            v.push(r);
        }
        tries += 1;
    }
    v
}

fn assert_hits(name: &str, hits: usize) {
    eprintln!("{name}: {hits} hits");
    assert!(hits >= MIN_HITS, "{name}: premises held only {hits} times");
}

// ---- Properties.lean ----

#[test]
fn messages_visible() {
    let hits = run(|rng, s| {
        let mut hits = 0;
        for req in requests(rng, s, 10, |op| matches!(op, Op::Messages { .. })) {
            let Op::Messages { room, .. } = req.op else { unreachable!() };
            if let Ok(Reply::Messages { chunk, .. }) = transition(s, &req) {
                if !keys(s) || chunk.is_empty() {
                    continue;
                }
                for e in &chunk {
                    assert!(in_room(s, room, *e) && visible(s, req.user, room, *e), "{req:?} {e}");
                    assert!(timeline(s).filter(|p| p.event_id == *e).all(|p| !ignored(s, req.user, p)), "{req:?} {e}");
                }
                hits += 1;
            }
        }
        hits
    });
    assert_hits("messages_visible", hits);
}

#[test]
fn messages_ordered() {
    let hits = run(|rng, s| {
        let mut hits = 0;
        for req in requests(rng, s, 10, |op| matches!(op, Op::Messages { .. })) {
            let Op::Messages { to, dir, limit, .. } = req.op else { unreachable!() };
            if let Ok(Reply::Messages { start, chunk, .. }) = transition(s, &req) {
                if !keys(s) || !sorted(s) || chunk.len() < 2 {
                    continue;
                }
                let cs: Vec<i64> = chunk.iter().map(|e| count_of(s, *e).expect("timeline event")).collect();
                match dir {
                    Dir::Forward => {
                        assert!(cs.windows(2).all(|w| w[0] < w[1]));
                        assert!(cs.iter().all(|c| start < *c && !matches!(to, Token::At(t) if *c >= t)));
                    }
                    Dir::Backward => {
                        assert!(cs.windows(2).all(|w| w[0] > w[1]));
                        assert!(cs.iter().all(|c| *c < start && !matches!(to, Token::At(t) if t >= *c)));
                    }
                }
                assert!(chunk.len() as u64 <= limit.min(1000));
                hits += 1;
            }
        }
        hits
    });
    assert_hits("messages_ordered", hits);
}

#[test]
fn messages_nothing_after_leaving() {
    let hits = run(|rng, s| {
        if !keys(s) || !sorted(s) || !state_consistent(s) {
            return 0;
        }
        let mut hits = 0;
        for room in s.rooms.iter().map(|r| r.id) {
            for u in USERS {
                let Some(p) = last_membership(s, u, room) else { continue };
                let left = matches!(p.membership, MemberField::Is(Membership::Leave | Membership::Ban));
                if !left || joined(s, u, room) || left_count(s, u, room).is_some_and(|l| l as i128 > p.count as i128) {
                    continue;
                }
                for dir in [Dir::Forward, Dir::Backward] {
                    let req = Request {
                        user: u,
                        op: Op::Messages { room, from: Token::Absent, to: Token::Absent, dir, limit: 50, filter: filter(rng) },
                    };
                    if let Ok(Reply::Messages { chunk, .. }) = transition(s, &req) {
                        for e in &chunk {
                            let q = timeline(s).find(|q| q.event_id == *e).unwrap();
                            if q.count > p.count {
                                assert!(
                                    match q.state {
                                        StateRef::None => true,
                                        StateRef::Hash(h) => visibility_at(s, h) == HistoryVisibility::WorldReadable,
                                    },
                                    "{req:?} {e}"
                                );
                            }
                        }
                        // the premises bite: the room has events after the
                        // departure that are not world-readable
                        let hidden = timeline(s).any(|q| {
                            q.room == room
                                && q.count > p.count
                                && matches!(q.state, StateRef::Hash(h) if visibility_at(s, h) != HistoryVisibility::WorldReadable)
                        });
                        hits += hidden as usize;
                    }
                }
            }
        }
        hits
    });
    assert_hits("messages_nothing_after_leaving", hits);
}

fn context_reply(s: &Snapshot, req: &Request) -> Option<(u64, Vec<u64>, Vec<u64>)> {
    match transition(s, req) {
        Ok(Reply::Context { event, events_before, events_after, .. }) => Some((event, events_before, events_after)),
        _ => None,
    }
}

#[test]
fn context_visible() {
    let hits = run(|rng, s| {
        let mut hits = 0;
        for req in requests(rng, s, 10, |op| matches!(op, Op::Context { .. })) {
            let Op::Context { room, event, .. } = req.op else { unreachable!() };
            if let Some((base, before, after)) = context_reply(s, &req) {
                if !keys(s) {
                    continue;
                }
                assert_eq!(base, event);
                for e in std::iter::once(&base).chain(&before).chain(&after) {
                    assert!(in_room(s, room, *e) && visible(s, req.user, room, *e), "{req:?} {e}");
                }
                hits += 1;
            }
        }
        hits
    });
    assert_hits("context_visible", hits);
}

#[test]
fn context_matches_spec() {
    let hits = run(|rng, s| {
        let mut hits = 0;
        for req in requests(rng, s, 10, |op| matches!(op, Op::Context { .. })) {
            let Op::Context { room, .. } = req.op else { unreachable!() };
            if let Some((base, before, after)) = context_reply(s, &req) {
                if !keys(s) {
                    continue;
                }
                for e in std::iter::once(&base).chain(&before).chain(&after) {
                    let p = event_of(s, *e).unwrap();
                    if let StateRef::Hash(h) = p.state {
                        if matches!(visibility_at(s, h), HistoryVisibility::Joined | HistoryVisibility::Invited) {
                            assert!(matrix_visible(s, req.user, room, *e), "{req:?} {e}");
                            hits += 1;
                        }
                    }
                }
            }
        }
        hits
    });
    assert_hits("context_matches_spec", hits);
}

#[test]
fn context_agrees_with_messages() {
    let hits = run(|rng, s| {
        let mut hits = 0;
        for req in requests(rng, s, 10, |op| matches!(op, Op::Context { .. })) {
            let Op::Context { room, event, limit, filter } = req.op.clone() else { unreachable!() };
            let Some((_, before, after)) = context_reply(s, &req) else { continue };
            if !keys(s) {
                continue;
            }
            let c = count_of(s, event).unwrap();
            let l = limit.min(100);
            let page = |dir, k| {
                let r = Request {
                    user: req.user,
                    op: Op::Messages { room, from: Token::At(c), to: Token::Absent, dir, limit: k, filter: filter.clone() },
                };
                match transition(s, &r) {
                    Ok(Reply::Messages { chunk, .. }) => Some(chunk),
                    _ => None,
                }
            };
            if let (Some(c1), Some(c2)) = (page(Dir::Forward, (l + 1) / 2), page(Dir::Backward, l / 2)) {
                assert_eq!((after.clone(), before.clone()), (c1, c2), "{req:?}");
                hits += !(after.is_empty() && before.is_empty()) as usize;
            }
        }
        hits
    });
    assert_hits("context_agrees_with_messages", hits);
}

#[test]
fn context_base_served_by_event() {
    let hits = run(|rng, s| {
        let mut hits = 0;
        for req in requests(rng, s, 10, |op| matches!(op, Op::Context { .. })) {
            let Op::Context { room, event, .. } = req.op else { unreachable!() };
            if context_reply(s, &req).is_some() && keys(s) {
                let r = Request { user: req.user, op: Op::RoomEvent { room, event } };
                assert_eq!(transition(s, &r), Ok(Reply::RoomEvent { event }), "{req:?}");
                hits += 1;
            }
        }
        hits
    });
    assert_hits("context_base_served_by_event", hits);
}

fn state_readable(s: &Snapshot, u: u64, room: u64) -> bool {
    joined(s, u, room) || invited(s, u, room) || once_joined(s, u, room) || world_readable_now(s, room)
}

#[test]
fn relations_visible() {
    let hits = run(|rng, s| {
        let mut hits = 0;
        for req in requests(rng, s, 10, |op| matches!(op, Op::Relations { .. })) {
            let Op::Relations { room, .. } = req.op else { unreachable!() };
            if let Ok(Reply::Relations { chunk, .. }) = transition(s, &req) {
                if !keys(s) {
                    continue;
                }
                assert!(state_readable(s, req.user, room), "{req:?}");
                for e in &chunk {
                    assert!(in_room(s, room, *e) && visible(s, req.user, room, *e), "{req:?} {e}");
                }
                hits += !chunk.is_empty() as usize;
            }
        }
        hits
    });
    assert_hits("relations_visible", hits);
}

#[test]
fn threads_visible() {
    let hits = run(|rng, s| {
        let mut hits = 0;
        for req in requests(rng, s, 10, |op| matches!(op, Op::Threads { .. })) {
            let Op::Threads { room, .. } = req.op else { unreachable!() };
            if let Ok(Reply::Threads { chunk, .. }) = transition(s, &req) {
                if !keys(s) || chunk.is_empty() {
                    continue;
                }
                for e in &chunk {
                    assert!(in_room(s, room, *e) && visible(s, req.user, room, *e), "{req:?} {e}");
                }
                hits += 1;
            }
        }
        hits
    });
    assert_hits("threads_visible", hits);
}

#[test]
fn room_event_visible() {
    let hits = run(|rng, s| {
        let mut hits = 0;
        for req in requests(rng, s, 10, |op| matches!(op, Op::RoomEvent { .. })) {
            let Op::RoomEvent { room, event } = req.op else { unreachable!() };
            if let Ok(Reply::RoomEvent { event: x }) = transition(s, &req) {
                assert!(x == event && visible(s, req.user, room, event), "{req:?}");
                hits += 1;
            }
        }
        hits
    });
    assert_hits("room_event_visible", hits);
}

#[test]
fn world_readable_event_served() {
    let hits = run(|rng, s| {
        let mut hits = 0;
        for p in &s.pdus {
            let StateRef::Hash(h) = p.state else { continue };
            if visibility_at(s, h) != HistoryVisibility::WorldReadable || event_of(s, p.event_id).map(|x| x.event_id) != Some(p.event_id) {
                continue;
            }
            let p = event_of(s, p.event_id).unwrap();
            let StateRef::Hash(h) = p.state else { continue };
            if visibility_at(s, h) != HistoryVisibility::WorldReadable {
                continue;
            }
            let u = if rng.pct(30) { STRANGER } else { rng.pick(&USERS) };
            if ignored(s, u, p) {
                continue;
            }
            let room = rng.pick(&[1, 2, 3, 99]);
            let r = Request { user: u, op: Op::RoomEvent { room, event: p.event_id } };
            assert_eq!(transition(s, &r), Ok(Reply::RoomEvent { event: p.event_id }), "{r:?}");
            hits += 1;
        }
        hits
    });
    assert_hits("world_readable_event_served", hits);
}

#[test]
fn state_reads_need_membership() {
    let hits = run(|rng, s| {
        let mut hits = 0;
        let reads = |op: &Op| matches!(op, Op::State { .. } | Op::StateEvent { .. } | Op::Members { .. });
        for req in requests(rng, s, 12, reads) {
            let room = match req.op {
                Op::State { room } | Op::StateEvent { room, .. } | Op::Members { room, .. } => room,
                _ => unreachable!(),
            };
            if transition(s, &req).is_ok() {
                assert!(state_readable(s, req.user, room), "{req:?}");
                hits += !joined(s, req.user, room) as usize;
            }
        }
        hits
    });
    assert_hits("state_reads_need_membership", hits);
}

#[test]
fn joined_members_need_join() {
    let hits = run(|rng, s| {
        let mut hits = 0;
        for req in requests(rng, s, 6, |op| matches!(op, Op::JoinedMembers { .. })) {
            let Op::JoinedMembers { room } = req.op else { unreachable!() };
            if transition(s, &req).is_ok() {
                assert!(joined(s, req.user, room) || world_readable_now(s, room), "{req:?}");
                hits += 1;
            }
        }
        hits
    });
    assert_hits("joined_members_need_join", hits);
}

#[test]
fn initial_sync_visible() {
    let hits = run(|rng, s| {
        let mut hits = 0;
        for req in requests(rng, s, 8, |op| matches!(op, Op::InitialSync { .. })) {
            let Op::InitialSync { room, .. } = req.op else { unreachable!() };
            if let Ok(Reply::InitialSync { chunk, .. }) = transition(s, &req) {
                if !keys(s) || chunk.is_empty() {
                    continue;
                }
                for e in &chunk {
                    assert!(in_room(s, room, *e) && visible(s, req.user, room, *e), "{req:?} {e}");
                }
                hits += 1;
            }
        }
        hits
    });
    assert_hits("initial_sync_visible", hits);
}

#[test]
fn initial_sync_stops_at_departure() {
    let hits = run(|rng, s| {
        if !keys(s) {
            return 0;
        }
        let mut hits = 0;
        for room in s.rooms.iter().map(|r| r.id) {
            let Some(h0) = room_state(s, room) else { continue };
            for u in USERS {
                let Some(p) = state_lookup(s, h0, Kind::Member, u) else { continue };
                if p.outlier || !matches!(p.membership, MemberField::Is(Membership::Leave | Membership::Ban)) {
                    continue;
                }
                let req = Request { user: u, op: Op::InitialSync { room, limit: if rng.pct(50) { None } else { Some(20) } } };
                if let Ok(Reply::InitialSync { chunk, .. }) = transition(s, &req) {
                    for e in &chunk {
                        assert!(timeline(s).any(|q| q.event_id == *e && q.count <= p.count), "{req:?} {e}");
                    }
                    hits += 1;
                }
            }
        }
        hits
    });
    assert_hits("initial_sync_stops_at_departure", hits);
}

#[test]
fn server_sees_joined_only() {
    let hits = run(|rng, s| {
        let mut hits = 0;
        for p in &s.pdus {
            let Some(q) = event_of(s, p.event_id) else { continue };
            let StateRef::Hash(h) = q.state else { continue };
            if visibility_at(s, h) != HistoryVisibility::Joined {
                continue;
            }
            let origin = rng.pick(&SERVERS);
            let room = if rng.pct(80) { p.room } else { rng.pick(&[1, 2, 3]) };
            let r = Request { user: 0, op: Op::ServerCanSee { origin, room, event: p.event_id } };
            if transition(s, &r) == Ok(Reply::CanSee(true)) {
                assert!(
                    s.joined.iter().any(|m| m.room == room && m.user / 1000 == origin && membership_at(s, h, m.user) == Membership::Join),
                    "{r:?}"
                );
                hits += 1;
            }
        }
        hits
    });
    assert_hits("server_sees_joined_only", hits);
}

#[test]
fn transition_total() {
    // `transition` returning at all is the property; the differential test
    // runs it on 240,000 requests, this on more varied ones.
    let hits = run(|rng, s| {
        for _ in 0..20 {
            let _ = transition(s, &request(rng, s));
        }
        1
    });
    assert_hits("transition_total", hits);
}

// ---- upstream behaviors that depart from the Matrix spec ----




