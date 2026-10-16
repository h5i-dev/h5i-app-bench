//! Path and method classifiers of `api/middleware/auth.rs`,
//! `api/middleware/guest_access.rs` and `api/middleware/oci_errors.rs`.
//! Upstream walks `path.split('/')` with `next()`; here the pieces are a
//! vector and `segments.next()` is an index that only grows.
use crate::strs::*;
use crate::{Method, Visibility};

/// `percent_hex_val`.
pub fn percent_hex_val(b: u8) -> Option<u8> {
    if b >= b'0' && b <= b'9' {
        Some(b - b'0')
    } else if b >= b'a' && b <= b'f' {
        Some(b - b'a' + 10)
    } else if b >= b'A' && b <= b'F' {
        Some(b - b'A' + 10)
    } else {
        None
    }
}

/// The decoding loop of `percent_decode_path_segment`.
fn percent_decode_bytes(bytes: &[u8]) -> Option<Vec<u8>> {
    let mut decoded = Vec::new();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%' {
            if i + 1 >= bytes.len() {
                return None;
            }
            let hi = match percent_hex_val(bytes[i + 1]) {
                Some(h) => h,
                None => return None,
            };
            if i + 2 >= bytes.len() {
                return None;
            }
            let lo = match percent_hex_val(bytes[i + 2]) {
                Some(l) => l,
                None => return None,
            };
            decoded.push((hi << 4) | lo);
            i += 3;
        } else {
            decoded.push(bytes[i]);
            i += 1;
        }
    }
    Some(decoded)
}

/// `percent_decode_path_segment`; the borrowed fast path is a copy.
pub fn percent_decode_path_segment(segment: &[u8]) -> Option<Vec<u8>> {
    if !contains_byte(segment, b'%') {
        return Some(segment.to_vec());
    }
    match percent_decode_bytes(segment) {
        Some(decoded) => {
            if is_utf8(&decoded) { Some(decoded) } else { None }
        }
        None => None,
    }
}

/// `extract_repo_key`.
pub fn extract_repo_key(path: &[u8]) -> Vec<u8> {
    let trimmed = trim_start_byte(path, b'/');
    let segments = split(&trimmed, b'/');
    // `split` yields at least one piece, so `format` is `segments[0]`.
    let is_conda = seg_is(&segments, 0, b"conda");
    let is_ext = seg_is(&segments, 0, b"ext");
    let is_api = seg_is(&segments, 0, b"api");
    let mut next = 1;
    if is_conda && seg_is(&segments, next, b"t") {
        if next + 2 < segments.len() {
            next += 2;
        }
    }
    if is_ext {
        next += 1;
    }
    if is_api && (seg_is(&segments, next, b"cargo") || seg_is(&segments, next, b"helm")) {
        next += 1;
    }
    let raw = if next < segments.len() { segments[next].clone() } else { Vec::new() };
    match percent_decode_path_segment(&raw) {
        Some(decoded) => decoded,
        None => raw,
    }
}

/// `extract_conda_url_token`.
pub fn extract_conda_url_token(path: &[u8]) -> Option<Vec<u8>> {
    let trimmed = trim_start_byte(path, b'/');
    let segments = split(&trimmed, b'/');
    if !seg_is(&segments, 0, b"conda") {
        return None;
    }
    if segments.len() < 2 || !bytes_eq(&segments[1], b"t") {
        return None;
    }
    if !seg_nonempty(&segments, 2) {
        return None;
    }
    if segments.len() < 4 {
        return None;
    }
    Some(segments[2].clone())
}

/// `is_nuget_push_path`.
pub fn is_nuget_push_path(path: &[u8]) -> bool {
    let trimmed = trim_start_byte(path, b'/');
    let segments = split(&trimmed, b'/');
    if !seg_is(&segments, 0, b"nuget") {
        return false;
    }
    if !seg_nonempty(&segments, 1) {
        return false;
    }
    if !seg_is(&segments, 2, b"api") || !seg_is(&segments, 3, b"v2") {
        return false;
    }
    if !seg_is(&segments, 4, b"package") {
        return false;
    }
    if segments.len() <= 5 {
        true
    } else if segments[5].len() == 0 {
        segments.len() <= 6
    } else {
        false
    }
}

/// `is_pypi_xmlrpc_tail`, over the pieces after the leading `pypi`
/// (`segments[1..]`).
fn is_pypi_xmlrpc_tail(segments: &[Vec<u8>]) -> bool {
    seg_nonempty(segments, 1)
        && seg_is(segments, 2, b"pypi")
        && (segments.len() <= 3 || segments[3].len() == 0)
        && segments.len() <= 4
}

/// `is_non_mutating_format_post`.
pub fn is_non_mutating_format_post(path: &[u8]) -> bool {
    let trimmed = trim_start_byte(path, b'/');
    let segments = split(&trimmed, b'/');
    if seg_is(&segments, 0, b"lfs") {
        seg_nonempty(&segments, 1)
            && seg_is(&segments, 2, b"objects")
            && seg_is(&segments, 3, b"batch")
            && segments.len() <= 4
    } else if seg_is(&segments, 0, b"conan") {
        seg_nonempty(&segments, 1)
            && seg_is(&segments, 2, b"v2")
            && seg_is(&segments, 3, b"users")
            && seg_is(&segments, 4, b"authenticate")
            && segments.len() <= 5
    } else if seg_is(&segments, 0, b"vscode") {
        seg_nonempty(&segments, 1)
            && seg_is(&segments, 2, b"gallery")
            && seg_is(&segments, 3, b"extensionquery")
            && segments.len() <= 4
    } else if seg_is(&segments, 0, b"pypi") {
        is_pypi_xmlrpc_tail(&segments)
    } else {
        false
    }
}

/// `is_anonymous_readable_format_post`: strips one leading `/`, not all.
pub fn is_anonymous_readable_format_post(path: &[u8]) -> bool {
    let trimmed = match strip_prefix(path, b"/") {
        Some(t) => t,
        None => path.to_vec(),
    };
    let segments = split(&trimmed, b'/');
    if seg_is(&segments, 0, b"vscode") {
        seg_nonempty(&segments, 1)
            && seg_is(&segments, 2, b"gallery")
            && seg_is(&segments, 3, b"extensionquery")
            && segments.len() <= 4
    } else if seg_is(&segments, 0, b"pypi") {
        is_pypi_xmlrpc_tail(&segments)
    } else {
        false
    }
}

/// `should_allow_repo_access`.
pub fn should_allow_repo_access(visibility: Visibility, has_auth: bool) -> bool {
    visibility.allows_anonymous_read() || has_auth
}

/// `is_write_method`.
pub fn is_write_method(method: Method) -> bool {
    matches!(method, Method::Post | Method::Put | Method::Patch | Method::Delete)
}

/// `action_for_method`.
pub fn action_for_method(method: Method) -> Vec<u8> {
    match method {
        Method::Get | Method::Head | Method::Options => b"read".to_vec(),
        Method::Put | Method::Post | Method::Patch => b"write".to_vec(),
        Method::Delete => b"delete".to_vec(),
        Method::Other => b"read".to_vec(),
    }
}

/// `public_read_satisfies_acl`.
pub fn public_read_satisfies_acl(visibility: Visibility, action: &[u8]) -> bool {
    visibility.allows_anonymous_read() && bytes_eq(action, b"read")
}

/// `authenticated_read_satisfies_acl`.
pub fn authenticated_read_satisfies_acl(visibility: Visibility, action: &[u8]) -> bool {
    visibility.allows_authenticated_read() && bytes_eq(action, b"read")
}

/// `ticket_method_allowed`.
pub fn ticket_method_allowed(method: Method) -> bool {
    matches!(method, Method::Get | Method::Head)
}

/// `ticket_path_allowed`.
pub fn ticket_path_allowed(bound_path: &Option<Vec<u8>>, request_path: &[u8]) -> bool {
    match bound_path {
        None => true,
        Some(p) => bytes_eq(p, request_path),
    }
}

/// `path_exempt_from_password_change`.
pub fn path_exempt_from_password_change(path: &[u8]) -> bool {
    let path = match strip_suffix(path, b"/") {
        Some(p) => p,
        None => path.to_vec(),
    };
    ends_with(&path, b"/auth/me") || ends_with(&path, b"/password") || ends_with(&path, b"/auth/logout")
}

/// `guest_access.rs` `is_allowlisted`.
pub fn is_allowlisted(path: &[u8]) -> bool {
    bytes_eq(path, b"/health")
        || bytes_eq(path, b"/healthz")
        || bytes_eq(path, b"/ready")
        || bytes_eq(path, b"/readyz")
        || bytes_eq(path, b"/livez")
        || bytes_eq(path, b"/api/v1/system/config")
        || bytes_eq(path, b"/v2/token")
        || starts_with(path, b"/api/v1/auth/")
        || bytes_eq(path, b"/api/v1/auth")
        || starts_with(path, b"/api/v1/setup/")
        || bytes_eq(path, b"/api/v1/setup")
}

/// `oci_errors.rs` `is_oci_v2_path`.
pub fn is_oci_v2_path(path: &[u8]) -> bool {
    bytes_eq(path, b"/v2") || bytes_eq(path, b"/v2/") || starts_with(path, b"/v2/")
}

/// `(c as char).to_digit(16)` for a byte.
fn hex_digit(b: u8) -> Option<u32> {
    match percent_hex_val(b) {
        Some(v) => Some(v as u32),
        None => None,
    }
}

/// The index of the first `&`-separated pair of `q` whose key (the text
/// before the first `=`) is `ticket`, with the start and end of that pair.
fn find_ticket_pair(q: &[u8]) -> Option<(usize, usize)> {
    let mut start = 0;
    let mut i = 0;
    while i <= q.len() {
        if i == q.len() || q[i] == b'&' {
            let pair = sub(q, start, i);
            let key = match find_byte(&pair, b'=') {
                Some(e) => sub(&pair, 0, e),
                None => pair.clone(),
            };
            if bytes_eq(&key, b"ticket") {
                return Some((start, i));
            }
            start = i + 1;
        }
        i += 1;
    }
    None
}

/// The decoding loop of `extract_ticket_from_query`: `+` is a space, `%XX`
/// a byte pushed as a Latin-1 `char`, and so is every other byte.
fn decode_ticket(bytes: &[u8]) -> Vec<u8> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < bytes.len() {
        let b = bytes[i];
        if b == b'+' {
            out.push(b' ');
            i += 1;
        } else if b == b'%' && i + 2 < bytes.len() {
            match (hex_digit(bytes[i + 1]), hex_digit(bytes[i + 2])) {
                (Some(h), Some(l)) => {
                    push_latin1(&mut out, (h * 16 + l) as u8);
                    i += 3;
                }
                _ => {
                    push_latin1(&mut out, b);
                    i += 1;
                }
            }
        } else {
            push_latin1(&mut out, b);
            i += 1;
        }
    }
    out
}

/// `extract_ticket_from_query`.
pub fn extract_ticket_from_query(query: &Option<Vec<u8>>) -> Option<Vec<u8>> {
    let q = match query {
        Some(q) => q,
        None => return None,
    };
    let (start, end) = match find_ticket_pair(q) {
        Some(p) => p,
        None => return None,
    };
    let pair = sub(q, start, end);
    let raw = match find_byte(&pair, b'=') {
        Some(e) => sub(&pair, e + 1, pair.len()),
        None => Vec::new(),
    };
    if raw.len() == 0 {
        return None;
    }
    Some(decode_ticket(&raw))
}

/// `Option<Vec<u8>>::clone`, which Aeneas does not model.
pub fn clone_path(p: &Option<Vec<u8>>) -> Option<Vec<u8>> {
    match p {
        Some(v) => Some(v.clone()),
        None => None,
    }
}
