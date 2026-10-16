//! Credential extraction and the CSRF contract, `api/middleware/auth.rs`.
//! A request's headers are `(lowercase name, raw value)` pairs in order, as
//! `http::HeaderMap` keeps them.
use crate::strs::*;
use crate::paths::{extract_conda_url_token, is_nuget_push_path};
use crate::Method;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Request {
    pub method: Method,
    /// `request.uri().path()`.
    pub path: Vec<u8>,
    /// `request.uri().query()`.
    pub query: Option<Vec<u8>>,
    pub headers: Vec<(Vec<u8>, Vec<u8>)>,
}

/// `HeaderValue::to_str` succeeds: visible ASCII or tab.
pub fn visible_ascii(v: &[u8]) -> bool {
    let mut i = 0;
    while i < v.len() {
        let b = v[i];
        if !((b >= 32 && b < 127) || b == 9) {
            return false;
        }
        i += 1;
    }
    true
}

/// `headers.get(name)`: the first value.
pub fn header_get(headers: &[(Vec<u8>, Vec<u8>)], name: &[u8]) -> Option<Vec<u8>> {
    let mut i = 0;
    while i < headers.len() {
        if bytes_eq(&headers[i].0, name) {
            return Some(headers[i].1.clone());
        }
        i += 1;
    }
    None
}

/// `headers.get(name).and_then(|v| v.to_str().ok())`.
pub fn header_str(headers: &[(Vec<u8>, Vec<u8>)], name: &[u8]) -> Option<Vec<u8>> {
    match header_get(headers, name) {
        Some(v) => {
            if visible_ascii(&v) { Some(v) } else { None }
        }
        None => None,
    }
}

pub fn contains_key(headers: &[(Vec<u8>, Vec<u8>)], name: &[u8]) -> bool {
    let mut i = 0;
    while i < headers.len() {
        if bytes_eq(&headers[i].0, name) {
            return true;
        }
        i += 1;
    }
    false
}

/// `ExtractedToken`, owning the credential text.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum ExtractedToken {
    Bearer(Vec<u8>),
    ApiKey(Vec<u8>),
    Basic(Vec<u8>),
    None,
    Invalid,
}

/// `extract_token_from_auth_header`.
pub fn extract_token_from_auth_header(auth_header: &[u8]) -> ExtractedToken {
    if let Some(token) = strip_prefix(auth_header, b"Bearer ") {
        ExtractedToken::Bearer(token)
    } else if let Some(token) = strip_prefix(auth_header, b"Token ") {
        ExtractedToken::Bearer(token)
    } else if let Some(token) = strip_prefix(auth_header, b"ApiKey ") {
        ExtractedToken::ApiKey(token)
    } else if let Some(creds) = strip_prefix(auth_header, b"Basic ") {
        ExtractedToken::Basic(creds)
    } else if let Some(creds) = strip_prefix(auth_header, b"basic ") {
        ExtractedToken::Basic(creds)
    } else if auth_header.len() > 0 && !contains_byte(auth_header, b' ') {
        ExtractedToken::Bearer(auth_header.to_vec())
    } else {
        ExtractedToken::Invalid
    }
}

/// The `find_map` of `session_cookie_token` over the `;` pieces.
fn find_session_cookie(pieces: &[Vec<u8>]) -> Option<Vec<u8>> {
    let mut i = 0;
    while i < pieces.len() {
        let t = trim(&pieces[i]);
        match strip_prefix(&t, b"ak_access_token=") {
            Some(tok) => return Some(tok),
            None => {}
        }
        i += 1;
    }
    None
}

/// `session_cookie_token`.
pub fn session_cookie_token(headers: &[(Vec<u8>, Vec<u8>)]) -> Option<Vec<u8>> {
    let cookie = match header_str(headers, b"cookie") {
        Some(c) => c,
        None => return None,
    };
    find_session_cookie(&split(&cookie, b';'))
}

/// `extract_token`.
pub fn extract_token(req: &Request) -> ExtractedToken {
    if let Some(auth_header) = header_str(&req.headers, b"authorization") {
        let result = extract_token_from_auth_header(&auth_header);
        if !matches!(result, ExtractedToken::None) {
            return result;
        }
    }
    if let Some(api_key) = header_str(&req.headers, b"x-api-key") {
        return ExtractedToken::ApiKey(api_key);
    }
    if let Some(token) = session_cookie_token(&req.headers) {
        return ExtractedToken::Bearer(token);
    }
    ExtractedToken::None
}

/// `has_header_credential`.
pub fn has_header_credential(headers: &[(Vec<u8>, Vec<u8>)]) -> bool {
    let auth = match header_str(headers, b"authorization") {
        Some(h) => !matches!(extract_token_from_auth_header(&h), ExtractedToken::None),
        None => false,
    };
    auth || contains_key(headers, b"x-api-key")
}

/// `credential_is_session_cookie`.
pub fn credential_is_session_cookie(headers: &[(Vec<u8>, Vec<u8>)]) -> bool {
    !has_header_credential(headers) && session_cookie_token(headers).is_some()
}

/// `request_carries_credentials`.
pub fn request_carries_credentials(headers: &[(Vec<u8>, Vec<u8>)]) -> bool {
    has_header_credential(headers) || session_cookie_token(headers).is_some()
}

/// `is_state_changing_method`.
pub fn is_state_changing_method(method: Method) -> bool {
    matches!(method, Method::Post | Method::Put | Method::Patch | Method::Delete)
}

/// `declares_same_origin`.
pub fn declares_same_origin(headers: &[(Vec<u8>, Vec<u8>)]) -> bool {
    match header_str(headers, b"sec-fetch-site") {
        Some(v) => {
            let v = trim(&v);
            eq_ignore_ascii_case(&v, b"same-origin") || eq_ignore_ascii_case(&v, b"none")
        }
        None => false,
    }
}

/// `is_browser_request`.
pub fn is_browser_request(headers: &[(Vec<u8>, Vec<u8>)]) -> bool {
    if contains_key(headers, b"sec-fetch-mode") || contains_key(headers, b"sec-fetch-site") {
        return true;
    }
    match header_str(headers, b"accept") {
        Some(v) => contains(&ascii_lowercase(&v), b"text/html"),
        None => false,
    }
}

/// `violates_csrf_contract`.
pub fn violates_csrf_contract(method: Method, headers: &[(Vec<u8>, Vec<u8>)]) -> bool {
    is_state_changing_method(method)
        && credential_is_session_cookie(headers)
        && is_browser_request(headers)
        && !contains_key(headers, b"x-requested-with")
        && !declares_same_origin(headers)
}

/// `extract_nuget_push_api_key`.
pub fn extract_nuget_push_api_key(req: &Request) -> Option<Vec<u8>> {
    if req.method != Method::Put || !is_nuget_push_path(&req.path) {
        return None;
    }
    match header_str(&req.headers, b"x-nuget-apikey") {
        Some(v) => {
            if v.len() > 0 { Some(v) } else { None }
        }
        None => None,
    }
}

/// `extract_visibility_token`.
pub fn extract_visibility_token(req: &Request) -> ExtractedToken {
    let extracted = extract_token(req);
    if !matches!(extracted, ExtractedToken::None) {
        return extracted;
    }
    if let Some(token) = extract_conda_url_token(&req.path) {
        return ExtractedToken::ApiKey(token);
    }
    if let Some(token) = extract_nuget_push_api_key(req) {
        return ExtractedToken::ApiKey(token);
    }
    ExtractedToken::None
}
