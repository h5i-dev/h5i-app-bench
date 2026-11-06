//! `crates/wastebin_server/src/cache.rs`: `valid_extension`.

/// `MAX_EXTENSION_LEN`.
pub const MAX_EXTENSION_LEN: usize = 32;

/// `u8::is_ascii_alphanumeric`.
pub fn is_ascii_alphanumeric(b: u8) -> bool {
    (b >= b'0' && b <= b'9') || (b >= b'A' && b <= b'Z') || (b >= b'a' && b <= b'z')
}

/// One byte of an accepted extension.
pub fn extension_byte(b: u8) -> bool {
    is_ascii_alphanumeric(b) || b == b'.' || b == b'_' || b == b'-'
}

/// `valid_extension`: ASCII alphanumerics, `.`, `_` and `-`, at most
/// `MAX_EXTENSION_LEN` bytes.
pub fn valid_extension(extension: &[u8]) -> bool {
    if extension.len() > MAX_EXTENSION_LEN {
        return false;
    }
    let mut i = 0;
    while i < extension.len() {
        if !extension_byte(extension[i]) {
            return false;
        }
        i += 1;
    }
    true
}
