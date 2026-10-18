//! Allocation-free authorization/state-transition subset, shared with PTX.
//! ABI: command, actor, article exists/author, comment exists/author, profile exists, already.
pub const WORDS: usize = 8;
pub fn evaluate(r: &[u64]) -> u32 {
    if r.len() != WORDS || r[0] > 7 {
        return u32::MAX;
    }
    if r[1] == 0 {
        return 1;
    } // Unauthenticated precedes resource errors.
    match r[0] {
        0 | 1 => 0, // CurrentUser / Feed
        2 => {
            if r[2] == 0 {
                2
            } else if r[3] != r[1] {
                3
            } else {
                0
            }
        }
        3 => {
            if r[2] == 0 {
                2
            } else if r[4] == 0 {
                4
            } else if r[5] != r[1] {
                5
            } else {
                0
            }
        }
        4 | 5 => {
            if r[6] == 0 {
                return 6;
            }
            let on = r[0] == 4;
            let changed = if on { r[7] == 0 } else { r[7] != 0 };
            10 + (on as u32) * 2 + changed as u32
        }
        6 | 7 => {
            if r[2] == 0 {
                return 2;
            }
            match (r[0] == 6, r[7] != 0) {
                (true, false) => 20,  // true, Up
                (true, true) => 21,   // true, Same
                (false, true) => 22,  // false, Down
                (false, false) => 23, // false, Same
            }
        }
        _ => u32::MAX,
    }
}
