//! The kernel against the copied upstream code on random snapshots and
//! requests: same reply, or same error kind.
use tuwunel_kernel::*;

use crate::{
    generate::{Rng, request, snapshot},
    world::upstream,
};

const SNAPSHOTS: usize = 6_000;
const REQUESTS: usize = 40;

/// `joined_members` collects into a map keyed by user id: compared as a
/// sorted set. Every other list must match in order.
fn normalize(r: Result<Reply, Error>) -> Result<Reply, Error> {
    let sorted = |mut v: Vec<u64>| {
        v.sort();
        v
    };
    r.map(|x| match x {
        Reply::JoinedMembers { joined } => {
            let mut j = sorted(joined);
            j.dedup();
            Reply::JoinedMembers { joined: j }
        }
        x => x,
    })
}

/// Counts of replies per kind, to see that each endpoint is reached.
#[derive(Default, Debug)]
struct Seen {
    ok: [usize; 11],
    err: [usize; 11],
}

fn op_index(op: &Op) -> usize {
    match op {
        Op::Messages { .. } => 0,
        Op::Context { .. } => 1,
        Op::Relations { .. } => 2,
        Op::Threads { .. } => 3,
        Op::State { .. } => 4,
        Op::StateEvent { .. } => 5,
        Op::Members { .. } => 6,
        Op::JoinedMembers { .. } => 7,
        Op::InitialSync { .. } => 8,
        Op::RoomEvent { .. } => 9,
        Op::ServerCanSee { .. } => 10,
    }
}

fn nonempty(r: &Reply) -> bool {
    match r {
        Reply::Messages { chunk, .. } | Reply::Relations { chunk, .. } | Reply::Threads { chunk, .. } | Reply::Members { chunk } => {
            !chunk.is_empty()
        }
        Reply::Context { events_before, events_after, .. } => !events_before.is_empty() || !events_after.is_empty(),
        Reply::State { events } => !events.is_empty(),
        Reply::JoinedMembers { joined } => !joined.is_empty(),
        Reply::InitialSync { chunk, .. } => !chunk.is_empty(),
        Reply::RoomEvent { .. } | Reply::StateEvent { .. } => true,
        Reply::CanSee(b) => *b,
    }
}

/// Paths worth seeing taken, by name.
fn paths(s: &Snapshot, req: &Request, r: &Result<Reply, Error>) -> Vec<&'static str> {
    let mut v = Vec::new();
    let room_of = |e: u64| s.pdus.iter().find(|p| p.event_id == e).map(|p| p.room);
    match (&req.op, r) {
        (Op::Relations { .. }, Ok(Reply::Relations { recursion_depth: Some(d), chunk, .. })) if *d >= 2 && chunk.len() >= 3 => {
            v.push("relations: recursion interleaved")
        }
        (Op::Messages { dir: Dir::Backward, .. }, Ok(Reply::Messages { end: Some(e), chunk, .. })) if !chunk.is_empty() => {
            let last = s.pdus.iter().find(|p| p.event_id == chunk[chunk.len() - 1]).unwrap().count;
            if *e != last {
                v.push("messages: exhausted backward token")
            }
        }
        (Op::Messages { to: Token::At(_), .. }, Ok(Reply::Messages { chunk, .. })) if !chunk.is_empty() => v.push("messages: to bound"),
        (Op::Threads { participated: true, .. }, Ok(Reply::Threads { chunk, .. })) if !chunk.is_empty() => {
            v.push("threads: participated")
        }
        (Op::Threads { .. }, Ok(Reply::Threads { next_batch: Some(_), .. })) => v.push("threads: next batch"),
        (Op::InitialSync { .. }, Ok(Reply::InitialSync { membership: Some(Membership::Leave | Membership::Ban), .. })) => {
            v.push("initial sync: departed")
        }
        (Op::Context { .. }, Err(Error::SenderIgnored)) => v.push("context: ignored sender"),
        (Op::RoomEvent { room, .. }, Ok(Reply::RoomEvent { event })) if room_of(*event) != Some(*room) => {
            v.push("event: id not in the timeline")
        }
        (Op::Messages { filter, .. }, Ok(Reply::Messages { chunk, .. }))
            if !chunk.is_empty() && !filter.related_by_rel_types.is_empty() =>
        {
            v.push("messages: related_by filter")
        }
        (Op::Members { at: Token::At(_), .. }, Ok(Reply::Members { chunk })) if !chunk.is_empty() => v.push("members: at token"),
        _ => {}
    }
    v
}

#[test]
fn kernel_agrees_with_upstream() {
    let mut hits: std::collections::BTreeMap<&'static str, usize> = Default::default();
    let mut rng = Rng(0x9e37_79b9_7f4a_7c15);
    let mut seen = Seen::default();
    for _ in 0..SNAPSHOTS {
        let b = snapshot(&mut rng);
        let s = &b.snapshot;
        for _ in 0..REQUESTS {
            let req = request(&mut rng, s);
            let k = normalize(transition(s, &req));
            let u = normalize(upstream(s, &req));
            assert_eq!(k, u, "request {req:?}\nsnapshot {s:#?}");
            for p in paths(s, &req, &k) {
                *hits.entry(p).or_default() += 1;
            }
            let i = op_index(&req.op);
            match &k {
                Ok(Reply::CanSee(false)) => seen.err[i] += 1,
                Ok(r) if nonempty(r) => seen.ok[i] += 1,
                Ok(_) => {}
                Err(_) => seen.err[i] += 1,
            }
        }
    }
    eprintln!("{seen:?}\n{hits:#?}");
    assert_eq!(hits.len(), 10, "paths not taken: {hits:?}");
    assert!(hits.values().all(|n| *n >= 20), "paths rarely taken: {hits:?}");
    for i in 0..11 {
        assert!(seen.ok[i] > 200 && seen.err[i] > 50, "endpoint {i} poorly covered: {seen:?}");
    }
}
