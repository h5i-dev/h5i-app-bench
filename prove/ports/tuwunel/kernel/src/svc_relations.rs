//! `service/rooms/pdu_metadata/relations.rs`.
use crate::*;

/// `PduCount::saturating_inc(dir)` of a signed count, as the unsigned bits
/// `to_be_bytes` writes: `Normal` counts move in `u64`, `Backfilled` in
/// `i64`.
pub fn inc_bits(c: i64, dir: Dir) -> u64 {
    if c > 0 {
        match dir {
            Dir::Forward => (c as u64) + 1,
            Dir::Backward => (c as u64) - 1,
        }
    } else {
        match dir {
            Dir::Forward => c.saturating_add(1) as u64,
            Dir::Backward => c.saturating_sub(1) as u64,
        }
    }
}

/// `get_relations`: the events relating to `target` in the room
/// `shortroomid`, scanning `tofrom_relation` from the key `[target, from]`
/// in direction `dir`; `from` itself is excluded. Rows whose event is not a
/// timeline row of that room are skipped.
pub fn get_relations(s: &Snapshot, shortroomid: u64, target: i64, from: Option<i64>, dir: Dir) -> Vec<(i64, usize)> {
    let target_bits = target as u64;
    let start = match from {
        Some(f) => inc_bits(f, dir),
        None => match dir {
            Dir::Backward => COUNT_MAX as u64,
            Dir::Forward => 0,
        },
    };
    let mut out = Vec::new();
    match dir {
        Dir::Forward => {
            let mut i = 0;
            while i < s.relations.len() {
                let r = &s.relations[i];
                if r.to == target_bits && r.from >= start {
                    push_relation(s, shortroomid, r.from, &mut out);
                }
                i += 1;
            }
        }
        Dir::Backward => {
            let mut i = s.relations.len();
            while i > 0 {
                i -= 1;
                let r = &s.relations[i];
                if r.to == target_bits && r.from <= start {
                    push_relation(s, shortroomid, r.from, &mut out);
                }
            }
        }
    }
    out
}

fn push_relation(s: &Snapshot, shortroomid: u64, from: u64, out: &mut Vec<(i64, usize)>) {
    let count = from as i64;
    match svc_timeline::get_pdu_from_id(s, shortroomid, count) {
        Ok(p) => out.push((count, p)),
        Err(_) => {}
    }
}

/// `RelationTypeEqual::relation_type_equal`: the event's
/// `m.relates_to.rel_type`.
pub fn relation_type_equal(rel_type: RelType, p: &Pdu) -> bool {
    match p.relates_to {
        Relates::To(r, _) => rel_type_eq(r, rel_type),
        Relates::None => false,
    }
}

fn any_rel_type(rel_types: &[RelType], p: &Pdu) -> bool {
    let mut i = 0;
    while i < rel_types.len() {
        if relation_type_equal(rel_types[i], p) {
            return true;
        }
        i += 1;
    }
    false
}

/// `has_incoming_relation`: some event relating to the target has a sender
/// in `senders` and a relation type in `rel_types` (an empty list allows
/// any).
pub fn has_incoming_relation(s: &Snapshot, shortroomid: u64, count: i64, senders: &[u64], rel_types: &[RelType]) -> bool {
    let rels = get_relations(s, shortroomid, count, None, Dir::Forward);
    let mut i = 0;
    while i < rels.len() {
        let p = &s.pdus[rels[i].1];
        let sender_matches = senders.len() == 0 || contains_u64(senders, p.sender);
        let rel_type_matches = rel_types.len() == 0 || any_rel_type(rel_types, p);
        if sender_matches && rel_type_matches {
            return true;
        }
        i += 1;
    }
    false
}
