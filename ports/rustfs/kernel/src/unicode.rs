//! Rust char::to_lowercase's Unicode table, generated from the pinned Rust toolchain.
//! Scalar decoding/encoding is written out because Aeneas has no char/String support.
/// Lowercase a scalar, returning up to two scalars and their count.
pub fn lowercase_scalar(cp: u32) -> (u32, u32, usize) {
    let mut i = 0;
    while i < 9 {
        if let Some(v) = range_chunk(cp, i) {
            return v;
        }
        i += 1;
    }
    singleton(cp)
}
fn within(cp: u32, start: u32, end: u32, parity: u32) -> bool {
    if cp < start || cp > end {
        return false;
    }
    parity == 0 || cp % 2 == parity - 1
}
fn range_chunk(cp: u32, index: usize) -> Option<(u32, u32, usize)> {
    match index {
        0 => range_0(cp),
        1 => range_1(cp),
        2 => range_2(cp),
        3 => range_3(cp),
        4 => range_4(cp),
        5 => range_5(cp),
        6 => range_6(cp),
        7 => range_7(cp),
        8 => range_8(cp),
        _ => None,
    }
}
fn range_0(cp: u32) -> Option<(u32, u32, usize)> {
    if within(cp, 65, 90, 0) {
        return Some((cp + 32, 0, 1));
    }
    if within(cp, 192, 214, 0) {
        return Some((cp + 32, 0, 1));
    }
    if within(cp, 216, 222, 0) {
        return Some((cp + 32, 0, 1));
    }
    if within(cp, 256, 302, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 306, 310, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 313, 327, 2) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 330, 374, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 377, 381, 2) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 386, 388, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 393, 394, 0) {
        return Some((cp + 205, 0, 1));
    }
    None
}
fn range_1(cp: u32) -> Option<(u32, u32, usize)> {
    if within(cp, 416, 420, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 433, 434, 0) {
        return Some((cp + 217, 0, 1));
    }
    if within(cp, 435, 437, 2) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 459, 475, 2) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 478, 494, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 498, 500, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 504, 542, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 546, 562, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 582, 590, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 880, 882, 1) {
        return Some((cp + 1, 0, 1));
    }
    None
}
fn range_2(cp: u32) -> Option<(u32, u32, usize)> {
    if within(cp, 904, 906, 0) {
        return Some((cp + 37, 0, 1));
    }
    if within(cp, 910, 911, 0) {
        return Some((cp + 63, 0, 1));
    }
    if within(cp, 913, 929, 0) {
        return Some((cp + 32, 0, 1));
    }
    if within(cp, 931, 939, 0) {
        return Some((cp + 32, 0, 1));
    }
    if within(cp, 984, 1006, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 1021, 1023, 0) {
        return Some((cp - 130, 0, 1));
    }
    if within(cp, 1024, 1039, 0) {
        return Some((cp + 80, 0, 1));
    }
    if within(cp, 1040, 1071, 0) {
        return Some((cp + 32, 0, 1));
    }
    if within(cp, 1120, 1152, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 1162, 1214, 1) {
        return Some((cp + 1, 0, 1));
    }
    None
}
fn range_3(cp: u32) -> Option<(u32, u32, usize)> {
    if within(cp, 1217, 1229, 2) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 1232, 1326, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 1329, 1366, 0) {
        return Some((cp + 48, 0, 1));
    }
    if within(cp, 4256, 4293, 0) {
        return Some((cp + 7264, 0, 1));
    }
    if within(cp, 5024, 5103, 0) {
        return Some((cp + 38864, 0, 1));
    }
    if within(cp, 5104, 5109, 0) {
        return Some((cp + 8, 0, 1));
    }
    if within(cp, 7312, 7354, 0) {
        return Some((cp - 3008, 0, 1));
    }
    if within(cp, 7357, 7359, 0) {
        return Some((cp - 3008, 0, 1));
    }
    if within(cp, 7680, 7828, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 7840, 7934, 1) {
        return Some((cp + 1, 0, 1));
    }
    None
}
fn range_4(cp: u32) -> Option<(u32, u32, usize)> {
    if within(cp, 7944, 7951, 0) {
        return Some((cp - 8, 0, 1));
    }
    if within(cp, 7960, 7965, 0) {
        return Some((cp - 8, 0, 1));
    }
    if within(cp, 7976, 7983, 0) {
        return Some((cp - 8, 0, 1));
    }
    if within(cp, 7992, 7999, 0) {
        return Some((cp - 8, 0, 1));
    }
    if within(cp, 8008, 8013, 0) {
        return Some((cp - 8, 0, 1));
    }
    if within(cp, 8025, 8031, 2) {
        return Some((cp - 8, 0, 1));
    }
    if within(cp, 8040, 8047, 0) {
        return Some((cp - 8, 0, 1));
    }
    if within(cp, 8072, 8079, 0) {
        return Some((cp - 8, 0, 1));
    }
    if within(cp, 8088, 8095, 0) {
        return Some((cp - 8, 0, 1));
    }
    if within(cp, 8104, 8111, 0) {
        return Some((cp - 8, 0, 1));
    }
    None
}
fn range_5(cp: u32) -> Option<(u32, u32, usize)> {
    if within(cp, 8120, 8121, 0) {
        return Some((cp - 8, 0, 1));
    }
    if within(cp, 8122, 8123, 0) {
        return Some((cp - 74, 0, 1));
    }
    if within(cp, 8136, 8139, 0) {
        return Some((cp - 86, 0, 1));
    }
    if within(cp, 8152, 8153, 0) {
        return Some((cp - 8, 0, 1));
    }
    if within(cp, 8154, 8155, 0) {
        return Some((cp - 100, 0, 1));
    }
    if within(cp, 8168, 8169, 0) {
        return Some((cp - 8, 0, 1));
    }
    if within(cp, 8170, 8171, 0) {
        return Some((cp - 112, 0, 1));
    }
    if within(cp, 8184, 8185, 0) {
        return Some((cp - 128, 0, 1));
    }
    if within(cp, 8186, 8187, 0) {
        return Some((cp - 126, 0, 1));
    }
    if within(cp, 8544, 8559, 0) {
        return Some((cp + 16, 0, 1));
    }
    None
}
fn range_6(cp: u32) -> Option<(u32, u32, usize)> {
    if within(cp, 9398, 9423, 0) {
        return Some((cp + 26, 0, 1));
    }
    if within(cp, 11264, 11311, 0) {
        return Some((cp + 48, 0, 1));
    }
    if within(cp, 11367, 11371, 2) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 11390, 11391, 0) {
        return Some((cp - 10815, 0, 1));
    }
    if within(cp, 11392, 11490, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 11499, 11501, 2) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 42560, 42604, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 42624, 42650, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 42786, 42798, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 42802, 42862, 1) {
        return Some((cp + 1, 0, 1));
    }
    None
}
fn range_7(cp: u32) -> Option<(u32, u32, usize)> {
    if within(cp, 42873, 42875, 2) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 42878, 42886, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 42896, 42898, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 42902, 42920, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 42932, 42946, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 42951, 42953, 2) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 42956, 42970, 1) {
        return Some((cp + 1, 0, 1));
    }
    if within(cp, 65313, 65338, 0) {
        return Some((cp + 32, 0, 1));
    }
    if within(cp, 66560, 66599, 0) {
        return Some((cp + 40, 0, 1));
    }
    if within(cp, 66736, 66771, 0) {
        return Some((cp + 40, 0, 1));
    }
    None
}
fn range_8(cp: u32) -> Option<(u32, u32, usize)> {
    if within(cp, 66928, 66938, 0) {
        return Some((cp + 39, 0, 1));
    }
    if within(cp, 66940, 66954, 0) {
        return Some((cp + 39, 0, 1));
    }
    if within(cp, 66956, 66962, 0) {
        return Some((cp + 39, 0, 1));
    }
    if within(cp, 66964, 66965, 0) {
        return Some((cp + 39, 0, 1));
    }
    if within(cp, 68736, 68786, 0) {
        return Some((cp + 64, 0, 1));
    }
    if within(cp, 68944, 68965, 0) {
        return Some((cp + 32, 0, 1));
    }
    if within(cp, 71840, 71871, 0) {
        return Some((cp + 32, 0, 1));
    }
    if within(cp, 93760, 93791, 0) {
        return Some((cp + 32, 0, 1));
    }
    if within(cp, 93856, 93880, 0) {
        return Some((cp + 27, 0, 1));
    }
    if within(cp, 125184, 125217, 0) {
        return Some((cp + 34, 0, 1));
    }
    None
}
fn singleton(cp: u32) -> (u32, u32, usize) {
    match cp {
        304 => (105, 775, 2),
        376 => (255, 0, 1),
        385 => (595, 0, 1),
        390 => (596, 0, 1),
        391 => (392, 0, 1),
        395 => (396, 0, 1),
        398 => (477, 0, 1),
        399 => (601, 0, 1),
        400 => (603, 0, 1),
        401 => (402, 0, 1),
        403 => (608, 0, 1),
        404 => (611, 0, 1),
        406 => (617, 0, 1),
        407 => (616, 0, 1),
        408 => (409, 0, 1),
        412 => (623, 0, 1),
        413 => (626, 0, 1),
        415 => (629, 0, 1),
        422 => (640, 0, 1),
        423 => (424, 0, 1),
        425 => (643, 0, 1),
        428 => (429, 0, 1),
        430 => (648, 0, 1),
        431 => (432, 0, 1),
        439 => (658, 0, 1),
        440 => (441, 0, 1),
        444 => (445, 0, 1),
        452 => (454, 0, 1),
        453 => (454, 0, 1),
        455 => (457, 0, 1),
        456 => (457, 0, 1),
        458 => (460, 0, 1),
        497 => (499, 0, 1),
        502 => (405, 0, 1),
        503 => (447, 0, 1),
        544 => (414, 0, 1),
        570 => (11365, 0, 1),
        571 => (572, 0, 1),
        573 => (410, 0, 1),
        574 => (11366, 0, 1),
        577 => (578, 0, 1),
        579 => (384, 0, 1),
        580 => (649, 0, 1),
        581 => (652, 0, 1),
        886 => (887, 0, 1),
        895 => (1011, 0, 1),
        902 => (940, 0, 1),
        908 => (972, 0, 1),
        975 => (983, 0, 1),
        1012 => (952, 0, 1),
        1015 => (1016, 0, 1),
        1017 => (1010, 0, 1),
        1018 => (1019, 0, 1),
        1216 => (1231, 0, 1),
        4295 => (11559, 0, 1),
        4301 => (11565, 0, 1),
        7305 => (7306, 0, 1),
        7838 => (223, 0, 1),
        8124 => (8115, 0, 1),
        8140 => (8131, 0, 1),
        8172 => (8165, 0, 1),
        8188 => (8179, 0, 1),
        8486 => (969, 0, 1),
        8490 => (107, 0, 1),
        8491 => (229, 0, 1),
        8498 => (8526, 0, 1),
        8579 => (8580, 0, 1),
        11360 => (11361, 0, 1),
        11362 => (619, 0, 1),
        11363 => (7549, 0, 1),
        11364 => (637, 0, 1),
        11373 => (593, 0, 1),
        11374 => (625, 0, 1),
        11375 => (592, 0, 1),
        11376 => (594, 0, 1),
        11378 => (11379, 0, 1),
        11381 => (11382, 0, 1),
        11506 => (11507, 0, 1),
        42877 => (7545, 0, 1),
        42891 => (42892, 0, 1),
        42893 => (613, 0, 1),
        42922 => (614, 0, 1),
        42923 => (604, 0, 1),
        42924 => (609, 0, 1),
        42925 => (620, 0, 1),
        42926 => (618, 0, 1),
        42928 => (670, 0, 1),
        42929 => (647, 0, 1),
        42930 => (669, 0, 1),
        42931 => (43859, 0, 1),
        42948 => (42900, 0, 1),
        42949 => (642, 0, 1),
        42950 => (7566, 0, 1),
        42955 => (612, 0, 1),
        42972 => (411, 0, 1),
        42997 => (42998, 0, 1),
        _ => (cp, 0, 1),
    }
}
/// Decode one scalar from a valid UTF-8 string, returning its next byte index.
pub fn scalar_at(s: &[u8], i: usize) -> (u32, usize) {
    let first = s[i] as u32;
    if first < 128 {
        return (first, i + 1);
    }
    if first < 224 {
        return (((first & 31) << 6) | (s[i + 1] as u32 & 63), i + 2);
    }
    if first < 240 {
        return (
            ((first & 15) << 12) | ((s[i + 1] as u32 & 63) << 6) | (s[i + 2] as u32 & 63),
            i + 3,
        );
    }
    (
        ((first & 7) << 18)
            | ((s[i + 1] as u32 & 63) << 12)
            | ((s[i + 2] as u32 & 63) << 6)
            | (s[i + 3] as u32 & 63),
        i + 4,
    )
}
/// Encode one Unicode scalar as UTF-8.
pub fn append_scalar(out: &mut Vec<u8>, cp: u32) {
    if cp < 128 {
        out.push(cp as u8);
    } else if cp < 2048 {
        out.push((192 | (cp >> 6)) as u8);
        out.push((128 | (cp & 63)) as u8);
    } else if cp < 65536 {
        out.push((224 | (cp >> 12)) as u8);
        out.push((128 | ((cp >> 6) & 63)) as u8);
        out.push((128 | (cp & 63)) as u8);
    } else {
        out.push((240 | (cp >> 18)) as u8);
        out.push((128 | ((cp >> 12) & 63)) as u8);
        out.push((128 | ((cp >> 6) & 63)) as u8);
        out.push((128 | (cp & 63)) as u8);
    }
}
/// Unicode lowercase as flat_map(char::to_lowercase), without contextual string casing.
pub fn lower(s: &[u8]) -> Vec<u8> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < s.len() {
        let (cp, next) = scalar_at(s, i);
        let (a, b, count) = lowercase_scalar(cp);
        append_scalar(&mut out, a);
        if count == 2 {
            append_scalar(&mut out, b);
        }
        i = next;
    }
    out
}
/// Rust char::is_whitespace (Unicode White_Space).
pub fn whitespace(cp: u32) -> bool {
    (cp >= 9 && cp <= 13)
        || cp == 32
        || cp == 133
        || cp == 160
        || cp == 5760
        || (cp >= 8192 && cp <= 8202)
        || cp == 8232
        || cp == 8233
        || cp == 8239
        || cp == 8287
        || cp == 12288
}
/// str::trim on valid UTF-8 bytes.
pub fn trim(s: &[u8]) -> Vec<u8> {
    let mut first = s.len();
    let mut last = 0;
    let mut i = 0;
    while i < s.len() {
        let (cp, next) = scalar_at(s, i);
        if !whitespace(cp) {
            if first == s.len() {
                first = i;
            }
            last = next;
        }
        i = next;
    }
    if first == s.len() {
        Vec::new()
    } else {
        crate::bytes::slice(s, first, last)
    }
}
