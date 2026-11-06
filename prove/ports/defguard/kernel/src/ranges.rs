//! `crates/defguard_core/src/enterprise/utils.rs` `merge_ranges`, used for
//! the port and address sets of firewall rules. One function for every
//! element type: values are `u128` below a `max` (65535 for ports, 2^32 - 1
//! for IPv4, 2^128 - 1 for IPv6), and `Next::next` wraps at `max` as
//! `wrapping_add(1)` does on the original type.

/// `RangeInclusive<T>`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Range {
    pub start: u128,
    pub end: u128,
}

/// `Next::next`.
pub fn next(x: u128, max: u128) -> u128 {
    if x >= max { 0 } else { x + 1 }
}

/// Insert `r` after every range whose start is not greater (stable).
pub fn insert_by_start(v: &Vec<Range>, r: Range) -> Vec<Range> {
    let mut res = Vec::new();
    let mut i = 0;
    while i < v.len() && v[i].start <= r.start {
        res.push(v[i]);
        i += 1;
    }
    res.push(r);
    while i < v.len() {
        res.push(v[i]);
        i += 1;
    }
    res
}

/// Sort by start (stable insertion sort; upstream's `sort_unstable_by` may
/// order equal starts differently, which matters only next to `max`).
pub fn sort_by_start(v: &Vec<Range>) -> Vec<Range> {
    let mut res = Vec::new();
    let mut i = 0;
    while i < v.len() {
        res = insert_by_start(&res, v[i]);
        i += 1;
    }
    res
}

/// The sweep of `merge_ranges` over `rs` (sorted, non-empty).
fn sweep(rs: &Vec<Range>, max: u128) -> Vec<Range> {
    let mut merged = Vec::new();
    let mut cur_start = rs[0].start;
    let mut cur_end = rs[0].end;
    let mut next_up = next(cur_end, max);
    let mut i = 1;
    while i < rs.len() {
        let s = rs[i].start;
        let e = rs[i].end;
        if next_up >= s {
            if e >= cur_end {
                next_up = next(e, max);
                cur_end = e;
            }
        } else {
            merged.push(Range { start: cur_start, end: cur_end });
            cur_start = s;
            next_up = next(e, max);
            cur_end = e;
        }
        i += 1;
    }
    merged.push(Range { start: cur_start, end: cur_end });
    merged
}

/// `merge_ranges`.
pub fn merge_ranges(input: &Vec<Range>, max: u128) -> Vec<Range> {
    if input.len() == 0 {
        return Vec::new();
    }
    let sorted = sort_by_start(input);
    sweep(&sorted, max)
}
