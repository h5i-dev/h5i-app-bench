//! Verbatim (host-adapted) copy of pico-bit's upstream armory filename logic.
//!
//! Source: `anapeksha/pico-bit` @ `b6349e2`, `src/runners/http.rs`:
//! `hex_digit`, `valid_armory_asset_filename`, `decode_armory_asset_filename`,
//! `armory_storage_path_unrestricted`. The only changes are host ergonomics:
//! the fixed `StringCopy<N>`/`[u8; N]` buffers become `Vec<u8>` with the same
//! `LISTED_FILE_NAME_MAX` (64) and `LISTED_FILE_PATH_MAX` (128) caps, and the
//! `?` operators are expanded. Behaviour is unchanged.

pub const LISTED_FILE_NAME_MAX: usize = 64;
pub const LISTED_FILE_PATH_MAX: usize = 128;

/// `hex_digit` in http.rs.
pub fn hex_digit(byte: u8) -> Option<u8> {
    match byte {
        b'0'..=b'9' => Some(byte - b'0'),
        b'a'..=b'f' => Some(byte - b'a' + 10),
        b'A'..=b'F' => Some(byte - b'A' + 10),
        _ => None,
    }
}

/// `valid_armory_asset_filename` in http.rs.
pub fn valid_armory_asset_filename(filename: &[u8]) -> bool {
    if filename.is_empty() || filename.len() > LISTED_FILE_NAME_MAX {
        return false;
    }

    if filename == b"." || filename == b".." {
        return false;
    }

    filename
        .iter()
        .all(|byte| *byte != b'/' && *byte != b'\\' && *byte != 0)
}

/// `decode_armory_asset_filename` in http.rs. Returns the decoded filename
/// bytes when accepted. Note the upstream also requires valid UTF-8 at the end.
pub fn decode_armory_asset_filename(path: &[u8]) -> Option<Vec<u8>> {
    let mut decoded: Vec<u8> = Vec::new();
    let mut index = 0usize;

    while index < path.len() {
        let byte = if path[index] == b'%' {
            if index + 2 >= path.len() {
                return None;
            }
            let high = hex_digit(path[index + 1])?;
            let low = hex_digit(path[index + 2])?;
            index += 3;
            (high << 4) | low
        } else {
            let byte = path[index];
            index += 1;
            byte
        };

        if decoded.len() >= LISTED_FILE_NAME_MAX {
            return None;
        }

        decoded.push(byte);
    }

    if !valid_armory_asset_filename(&decoded) {
        return None;
    }

    // Upstream additionally requires the decoded name to be valid UTF-8.
    core::str::from_utf8(&decoded).ok()?;
    Some(decoded)
}

/// `armory_storage_path_unrestricted` in http.rs: builds `/armory/<filename>`.
pub fn armory_storage_path_unrestricted(filename: &[u8]) -> Option<Vec<u8>> {
    if !valid_armory_asset_filename(filename) {
        return None;
    }
    let prefix = b"/armory/";
    let len = prefix.len() + filename.len();
    if len > LISTED_FILE_PATH_MAX {
        return None;
    }
    let mut path = Vec::with_capacity(len);
    path.extend_from_slice(prefix);
    path.extend_from_slice(filename);
    Some(path)
}
