//! `crates/wastebin_server/src/handlers/download.rs`:
//! `make_content_disposition`, the `Content-Disposition` header of a
//! download, whose filename is the paste's user-chosen title.

use crate::ext::is_ascii_alphanumeric;

/// `"attachment; filename*=UTF-8''"`.
pub const PREFIX: [u8; 29] = [
    b'a', b't', b't', b'a', b'c', b'h', b'm', b'e', b'n', b't', b';', b' ', b'f', b'i', b'l', b'e',
    b'n', b'a', b'm', b'e', b'*', b'=', b'U', b'T', b'F', b'-', b'8', b'\'', b'\'',
];

/// `"0123456789ABCDEF"`: `{b:02X}`.
pub const HEX: [u8; 16] = [
    b'0', b'1', b'2', b'3', b'4', b'5', b'6', b'7', b'8', b'9', b'A', b'B', b'C', b'D', b'E', b'F',
];

/// Bytes written as themselves: ASCII alphanumerics and `.-_~+`.
pub fn unreserved(b: u8) -> bool {
    is_ascii_alphanumeric(b)
        || b == b'.'
        || b == b'-'
        || b == b'_'
        || b == b'~'
        || b == b'+'
}

/// `make_content_disposition` before `HeaderValue::try_from`: the prefix,
/// then each byte of the filename as itself or `%XX`.
pub fn content_disposition(filename: &[u8]) -> Vec<u8> {
    let mut v = Vec::new();
    let mut i = 0;
    while i < 29 {
        v.push(PREFIX[i]);
        i += 1;
    }
    let mut j = 0;
    while j < filename.len() {
        let b = filename[j];
        if unreserved(b) {
            v.push(b);
        } else {
            v.push(b'%');
            v.push(HEX[(b >> 4) as usize]);
            v.push(HEX[(b & 0xf) as usize]);
        }
        j += 1;
    }
    v
}
