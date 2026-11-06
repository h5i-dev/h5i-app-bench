//! pico-bit's web surface decision logic, as an h5i-app kernel for a
//! microcontroller.
//!
//! Upstream: `anapeksha/pico-bit` @ `b6349e2` (picoserve 0.18, embassy-rp,
//! RP235x). pico-bit is a USB-HID / Wi-Fi "bad-USB" research tool whose Wi-Fi
//! portal exposes an unauthenticated HTTP API. The byte-level request handling
//! is hand-written in `src/runners/http.rs` and `src/net/http/api/armory`,
//! *not* delegated to picoserve for the hot paths (picoserve only handles
//! `StartupRequest::Other`). This kernel ports the two pieces of that
//! hand-written logic whose correctness is security-relevant:
//!
//! 1. **Armory filename handling** (`decode_armory_asset_filename`,
//!    `valid_armory_asset_filename`, `armory_storage_path_unrestricted` in
//!    `src/runners/http.rs`): a request path segment is percent-decoded and
//!    only then validated, and a LittleFS path `/armory/<name>` is built from
//!    it. The security property is that an accepted name can never make the
//!    device open or delete a file outside `/armory/` (path traversal).
//!
//! 2. **Request classification** (`classify_startup_request` in
//!    `src/runners/http.rs`): the first bytes of a connection decide which
//!    handler runs. We model it to show it is a total, deterministic function
//!    whose mutating classes each require a non-idempotent method + a specific
//!    path prefix.
//!
//! `#![no_std]`, no allocation, in the Rust subset Charon and Aeneas translate
//! to Lean. `proofs/` proves the properties about this code as extracted.

#![no_std]

// ----- byte constants -----
pub const SLASH: u8 = 47; // '/'
pub const BACKSLASH: u8 = 92; // '\\'
pub const NUL: u8 = 0;
pub const DOT: u8 = 46; // '.'
pub const PERCENT: u8 = 37; // '%'

/// Longest accepted decoded filename (upstream `LISTED_FILE_NAME_MAX`).
pub const NAME_MAX: usize = 64;

/// Longest raw (still percent-encoded) path segment we will scan. Each decoded
/// byte costs at least one raw byte, and a `%XX` escape costs three, so any raw
/// segment longer than `NAME_MAX * 3` must decode to more than `NAME_MAX` bytes
/// and would be rejected by the length check anyway. Capping the scan makes the
/// loop's index arithmetic provably non-overflowing without changing which
/// inputs are accepted.
pub const RAW_MAX: usize = NAME_MAX * 3;

// ===================================================================
// 1. Armory filename handling
// ===================================================================

/// Hex digit value, or -1 if `b` is not `[0-9a-fA-F]`.
/// Mirrors `hex_digit` in `src/runners/http.rs`.
pub fn hex_digit(b: u8) -> i32 {
    if b >= 48 && b <= 57 {
        (b - 48) as i32
    } else if b >= 97 && b <= 102 {
        (b - 97) as i32 + 10
    } else if b >= 65 && b <= 70 {
        (b - 65) as i32 + 10
    } else {
        -1
    }
}

/// Percent-decode `raw` into `out`, returning the decoded length, or `None` if
/// the input is malformed (`%` without two hex digits) or does not fit.
///
/// Mirrors the decode loop of `decode_armory_asset_filename`. Note the decode
/// happens *before* any validation: `%2e%2e` decodes to `..` and `%2f` to `/`,
/// which the subsequent [`valid_name_prefix`] gate then rejects.
pub fn percent_decode(raw: &[u8], out: &mut [u8]) -> Option<usize> {
    if raw.len() > RAW_MAX {
        return None;
    }
    let mut i: usize = 0;
    let mut n: usize = 0;
    while i < raw.len() {
        let byte: u8;
        if raw[i] == PERCENT {
            // Need two more bytes after '%'.
            if raw.len() - i < 3 {
                return None;
            }
            let hi = hex_digit(raw[i + 1]);
            if hi < 0 {
                return None;
            }
            let lo = hex_digit(raw[i + 2]);
            if lo < 0 {
                return None;
            }
            byte = ((hi << 4) | lo) as u8;
            i += 3;
        } else {
            byte = raw[i];
            i += 1;
        }
        if n >= out.len() {
            return None;
        }
        out[n] = byte;
        n += 1;
    }
    Some(n)
}

/// A byte that must never appear inside an accepted filename: a path separator
/// (`/` or `\`) or a NUL. Mirrors the per-byte test in
/// `valid_armory_asset_filename`.
pub fn is_separator(b: u8) -> bool {
    b == SLASH || b == BACKSLASH || b == NUL
}

/// Whether `buf[..len]` is exactly `.` or `..` (the relative-path entries that
/// must never name an armory file). Kept in its own function so the separator
/// loop below extracts as a single loop.
pub fn is_dot_name(buf: &[u8], len: usize) -> bool {
    if len == 1 && buf.len() >= 1 {
        return buf[0] == DOT;
    }
    if len == 2 && buf.len() >= 2 {
        return buf[0] == DOT && buf[1] == DOT;
    }
    false
}

/// The filename-acceptance gate over `buf[..len]`, written with an explicit
/// length so Aeneas does not reason about reslicing a `&mut` buffer. Mirrors
/// `valid_armory_asset_filename`: reject empty / over-long names, `.`, `..`,
/// and any name containing a separator or NUL.
pub fn valid_name_prefix(buf: &[u8], len: usize) -> bool {
    if len == 0 || len > NAME_MAX {
        return false;
    }
    if len > buf.len() {
        return false;
    }
    if is_dot_name(buf, len) {
        return false;
    }
    let mut i: usize = 0;
    while i < len {
        if is_separator(buf[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// [`valid_name_prefix`] over a whole slice: the policy predicate the proofs
/// phrase the traversal property over.
pub fn valid_name(name: &[u8]) -> bool {
    valid_name_prefix(name, name.len())
}

/// Percent-decode a raw request path segment into `out` and accept it only if
/// the decoded bytes pass [`valid_name_prefix`]. Returns the accepted decoded
/// length.
///
/// This composition is the whole point: the device validates the *decoded*
/// bytes, so an attacker cannot smuggle a separator or `..` segment through
/// percent-encoding.
pub fn decode_filename(raw: &[u8], out: &mut [u8]) -> Option<usize> {
    match percent_decode(raw, out) {
        Some(n) => {
            if valid_name_prefix(out, n) {
                Some(n)
            } else {
                None
            }
        }
        None => None,
    }
}

// ===================================================================
// 2. Request classification
// ===================================================================

/// One handler class, mirroring `StartupRequest` in `src/runners/http.rs`.
/// The security-relevant point is that classification is a total function of
/// the leading request bytes and that mutating classes require a specific
/// method + path prefix.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Class {
    Root,
    Bootstrap,
    Armory,
    ArmoryUpload,
    ArmoryDelete,
    ArmoryAsset,
    Payload,
    PayloadSave,
    PayloadRun,
    Runs,
    Metrics,
    KeyboardTarget,
    Options,
    Other,
}

/// Whether `bytes` begins with `prefix`.
pub fn starts_with(bytes: &[u8], prefix: &[u8]) -> bool {
    if bytes.len() < prefix.len() {
        return false;
    }
    let mut i: usize = 0;
    while i < prefix.len() {
        if bytes[i] != prefix[i] {
            return false;
        }
        i += 1;
    }
    true
}

/// Classify the leading bytes of a request. Mirrors the decision order of
/// `classify_startup_request`, restricted to the routes that mutate device
/// state or serve files (the security-relevant ones). Unlike upstream's
/// bidirectional `request_starts_with`, this uses ordinary prefix matching:
/// see DEVIATIONS.md for why the two agree on any complete request line.
pub fn classify(bytes: &[u8]) -> Class {
    if starts_with(bytes, b"POST /api/armory/upload ") {
        return Class::ArmoryUpload;
    }
    if starts_with(bytes, b"DELETE /api/armory/") {
        return Class::ArmoryDelete;
    }
    if starts_with(bytes, b"GET /api/armory/") || starts_with(bytes, b"HEAD /api/armory/") {
        return Class::ArmoryAsset;
    }
    if starts_with(bytes, b"GET /api/armory ") {
        return Class::Armory;
    }
    if starts_with(bytes, b"POST /api/payload/run ") {
        return Class::PayloadRun;
    }
    if starts_with(bytes, b"POST /api/payload ") {
        return Class::PayloadSave;
    }
    if starts_with(bytes, b"GET /api/payload ") {
        return Class::Payload;
    }
    if starts_with(bytes, b"GET /api/runs ") {
        return Class::Runs;
    }
    if starts_with(bytes, b"GET /api/metrics ") {
        return Class::Metrics;
    }
    if starts_with(bytes, b"GET /api/bootstrap ") {
        return Class::Bootstrap;
    }
    if starts_with(bytes, b"POST /api/keyboard/layout ") {
        return Class::KeyboardTarget;
    }
    if starts_with(bytes, b"OPTIONS ") {
        return Class::Options;
    }
    if starts_with(bytes, b"GET / ") || starts_with(bytes, b"HEAD / ") {
        return Class::Root;
    }
    Class::Other
}

/// Whether a class mutates device state (writes flash / runs a payload /
/// changes the keyboard target). Used to phrase the "mutation needs a
/// non-idempotent method" property.
pub fn is_mutating(c: Class) -> bool {
    match c {
        Class::ArmoryUpload => true,
        Class::ArmoryDelete => true,
        Class::PayloadSave => true,
        Class::PayloadRun => true,
        Class::KeyboardTarget => true,
        _ => false,
    }
}
