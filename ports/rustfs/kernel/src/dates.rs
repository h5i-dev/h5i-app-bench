//! The DateFunc comparison and its RFC3339 primitive, written out for Aeneas.
use crate::{
    conddata::{DateFunc, Op},
    condfuncs::{CondValues, get_value, key_lookup_name},
};
macro_rules! value_or_none {
    ($e:expr) => {
        match $e {
            Some(v) => v,
            None => return None,
        }
    };
}
fn digits(s: &[u8], from: usize, count: usize) -> Option<i64> {
    if from > s.len() || count > s.len() - from {
        return None;
    }
    let mut n = 0;
    let mut i = 0;
    while i < count {
        let b = s[from + i];
        if b < b'0' || b > b'9' {
            return None;
        }
        n = n * 10 + (b - b'0') as i64;
        i += 1;
    }
    Some(n)
}
fn month_days(year: i64, month: i64) -> i64 {
    if month == 2 {
        if year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) {
            29
        } else {
            28
        }
    } else if month == 4 || month == 6 || month == 9 || month == 11 {
        30
    } else {
        31
    }
}
/// Gregorian calendar days relative to 1970-01-01 (the civil-date algorithm).
fn civil_days(year: i64, month: i64, day: i64) -> i64 {
    let y = if month <= 2 { year - 1 } else { year };
    let era = if y >= 0 { y / 400 } else { (y - 399) / 400 };
    let yoe = y - era * 400;
    let m = if month > 2 { month - 3 } else { month + 9 };
    let doy = (153 * m + 2) / 5 + day - 1;
    era * 146097 + yoe * 365 + yoe / 4 - yoe / 100 + doy - 719468
}
fn calendar_fields(s: &[u8]) -> Option<(i64, i64, i64)> {
    let year = value_or_none!(digits(s, 0, 4));
    let month = value_or_none!(digits(s, 5, 2));
    let day = value_or_none!(digits(s, 8, 2));
    if month < 1 || month > 12 || day < 1 || day > month_days(year, month) { return None; }
    Some((year, month, day))
}
fn time_fields(s: &[u8]) -> Option<(i64, i64, i64)> {
    let hour = value_or_none!(digits(s, 11, 2));
    let minute = value_or_none!(digits(s, 14, 2));
    let second = value_or_none!(digits(s, 17, 2));
    if hour > 23 || minute > 59 || second > 60 { return None; }
    Some((hour, minute, second))
}
fn fraction(s: &[u8]) -> Option<(i64, usize)> {
    let mut i = 19; let mut nano = 0;
    if s[i] == b'.' {
        i += 1; let first = i; let mut multiplier = 100000000;
        while i < s.len() && s[i] >= b'0' && s[i] <= b'9' {
            nano += (s[i] - b'0') as i64 * multiplier;
            multiplier /= 10; i += 1;
        }
        if i == first { return None; }
    }
    Some((nano, i))
}
fn offset(s: &[u8], i: usize) -> Option<i64> {
    if i >= s.len() { return None; }
    if s[i] == b'Z' || s[i] == b'z' { return if i + 1 == s.len() { Some(0) } else { None }; }
    if i + 6 != s.len() || (s[i] != b'+' && s[i] != b'-') || s[i+3] != b':' { return None; }
    let oh = value_or_none!(digits(s, i+1, 2));
    let om = value_or_none!(digits(s, i+4, 2));
    if oh > 23 || om > 59 { return None; }
    let v = oh * 3600 + om * 60;
    Some(if s[i] == b'-' { -v } else { v })
}
fn leap_valid(utc: i64, local_day: i64, year: i64, month: i64, day: i64) -> bool {
    let rem = ((utc % 86400) + 86400) % 86400;
    let utc_day = (utc - rem) / 86400;
    let last = month_days(year, month);
    rem == 86399 && ((utc_day == local_day && day == last)
        || (utc_day == local_day - 1 && day == 1)
        || (utc_day == local_day + 1 && day == last - 1))
}
fn nanos(utc: i64, nano: i64) -> i128 { utc as i128 * 1000000000 + nano as i128 }
/// `OffsetDateTime::parse(_, Rfc3339)`, as UTC nanoseconds. Input remains UTF-8.
pub fn parse_rfc3339(s: &[u8]) -> Option<i128> {
    if s.len() < 20 || s[4] != b'-' || s[7] != b'-' || s[13] != b':' || s[16] != b':' { return None; }
    let (year, month, day) = value_or_none!(calendar_fields(s));
    let (hour, minute, second) = value_or_none!(time_fields(s));
    let (mut nano, i) = value_or_none!(fraction(s));
    let off = value_or_none!(offset(s, i));
    let local_day = civil_days(year, month, day);
    let sec = if second == 60 { 59 } else { second };
    let utc = local_day * 86400 + hour * 3600 + minute * 60 + sec - off;
    if second == 60 {
        if !leap_valid(utc, local_day, year, month, day) { return None; }
        nano = 999999999;
    }
    Some(nanos(utc, nano))
}
/// Date comparisons passed as closures upstream become an operation tag.
pub fn compare(op: Op, request: i128, expected: i128) -> bool {
    match op {
        Op::DateEquals => request == expected,
        Op::DateNotEquals => request != expected,
        Op::DateLessThan => request < expected,
        Op::DateLessThanEquals => request <= expected,
        Op::DateGreaterThan => request > expected,
        Op::DateGreaterThanEquals => request >= expected,
        _ => false,
    }
}
/// `DateFunc::evaluate`: only the first request value is parsed; all keys must match.
pub fn evaluate(inner: &DateFunc, op: Op, values: &CondValues) -> bool {
    let mut i = 0;
    while i < inner.entries.len() {
        let entry = &inner.entries[i];
        let vs = match get_value(values, &key_lookup_name(&entry.key)) {
            Some(v) => v,
            None => return false,
        };
        if vs.len() == 0 {
            return false;
        }
        let request = match parse_rfc3339(&vs[0]) {
            Some(t) => t,
            None => return false,
        };
        if !compare(op, request, entry.values.unix_nanos) {
            return false;
        }
        i += 1;
    }
    true
}

/// Parse a date value while retaining its source offset for serialization by the shell.
pub fn parse_value(s: &[u8]) -> Option<crate::conddata::DateFuncValue> {
    let unix_nanos = match parse_rfc3339(s) {
        Some(v) => v,
        None => return None,
    };
    let offset_seconds = if s[s.len() - 1] == b'Z' || s[s.len() - 1] == b'z' {
        0
    } else {
        let i = s.len() - 6;
        let hour = match digits(s, i + 1, 2) {
            Some(v) => v,
            None => return None,
        };
        let minute = match digits(s, i + 4, 2) {
            Some(v) => v,
            None => return None,
        };
        let offset = (hour * 3600 + minute * 60) as i32;
        if s[i] == b'-' { -offset } else { offset }
    };
    Some(crate::conddata::DateFuncValue {
        unix_nanos,
        offset_seconds,
    })
}
