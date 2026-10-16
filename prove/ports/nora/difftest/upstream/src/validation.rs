// Copied from getnora-io/nora @ f864a9a by extract_upstream.py. Do not edit.
// Copyright (c) 2026 The NORA Authors
// SPDX-License-Identifier: MIT

//! Input validation for artifact registry paths and identifiers
//!
//! Provides security validation to prevent path traversal attacks and
//! ensure inputs conform to protocol specifications.

use axum::{
    body::Body,
    http::{Request, StatusCode},
    middleware::Next,
    response::{IntoResponse, Response},
};
use std::fmt;

/// Validation errors
#[derive(Debug, Clone, PartialEq)]
pub enum ValidationError {
    /// Path contains traversal sequences (../, etc.)
    PathTraversal,
    /// Docker image name is invalid
    InvalidDockerName(String),
    /// Content digest is invalid
    InvalidDigest(String),
    /// Tag/reference is invalid
    InvalidReference(String),
    /// Input is empty
    EmptyInput,
    /// Input exceeds maximum length
    TooLong { max: usize, actual: usize },
    /// Contains forbidden characters
    ForbiddenCharacter(char),
}

impl fmt::Display for ValidationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::PathTraversal => write!(f, "Path traversal detected"),
            Self::InvalidDockerName(reason) => write!(f, "Invalid Docker name: {}", reason),
            Self::InvalidDigest(reason) => write!(f, "Invalid digest: {}", reason),
            Self::InvalidReference(reason) => write!(f, "Invalid reference: {}", reason),
            Self::EmptyInput => write!(f, "Input cannot be empty"),
            Self::TooLong { max, actual } => {
                write!(f, "Input exceeds maximum length ({} > {})", actual, max)
            }
            Self::ForbiddenCharacter(c) => write!(f, "Forbidden character: {:?}", c),
        }
    }
}

impl std::error::Error for ValidationError {}

/// Case-insensitive suffix check for file extensions.
///
/// Avoids allocating a lowercased copy of the whole string.
pub fn ends_with_ci(s: &str, suffix: &str) -> bool {
    s.len() >= suffix.len()
        && s.as_bytes()[s.len() - suffix.len()..].eq_ignore_ascii_case(suffix.as_bytes())
}

/// Maximum allowed storage key length
const MAX_KEY_LENGTH: usize = 1024;

/// Maximum Docker name length
const MAX_DOCKER_NAME_LENGTH: usize = 256;

/// Maximum tag/reference length
const MAX_REFERENCE_LENGTH: usize = 128;

/// Validate and sanitize a storage key to prevent path traversal attacks.
///
/// Rejects keys containing:
/// - `..` path traversal sequences
/// - Leading `/` or `\` (absolute paths)
/// - Null bytes
/// - Empty segments
pub fn validate_storage_key(key: &str) -> Result<(), ValidationError> {
    if key.is_empty() {
        return Err(ValidationError::EmptyInput);
    }

    if key.len() > MAX_KEY_LENGTH {
        return Err(ValidationError::TooLong {
            max: MAX_KEY_LENGTH,
            actual: key.len(),
        });
    }

    // Reject non-ASCII characters — all registry paths are ASCII-only
    if let Some(ch) = key.chars().find(|c| !c.is_ascii()) {
        return Err(ValidationError::ForbiddenCharacter(ch));
    }

    // Check for null bytes
    if key.contains('\0') {
        return Err(ValidationError::ForbiddenCharacter('\0'));
    }

    // Check for absolute paths
    if key.starts_with('/') || key.starts_with('\\') {
        return Err(ValidationError::PathTraversal);
    }

    // Check for path traversal patterns
    if key.contains("..") {
        return Err(ValidationError::PathTraversal);
    }

    // Check for backslash (Windows path separator)
    if key.contains('\\') {
        return Err(ValidationError::PathTraversal);
    }

    // Check each segment
    for segment in key.split('/') {
        if segment.is_empty() && !key.is_empty() {
            // Allow trailing slash but not double slashes
            continue;
        }
        if segment == "." || segment == ".." {
            return Err(ValidationError::PathTraversal);
        }
    }

    Ok(())
}

/// Validate Docker image name per OCI distribution spec.
///
/// Valid names:
/// - Lowercase letters, digits, underscores, dots, hyphens
/// - May contain path separators (/)
/// - Each component must start with alphanumeric
/// - Max 256 characters
///
/// Examples:
/// - `nginx` ✓
/// - `library/nginx` ✓
/// - `my-org/my-image` ✓
/// - `NGINX` ✗ (uppercase)
/// - `../escape` ✗ (path traversal)
pub fn validate_docker_name(name: &str) -> Result<(), ValidationError> {
    if name.is_empty() {
        return Err(ValidationError::EmptyInput);
    }

    if name.len() > MAX_DOCKER_NAME_LENGTH {
        return Err(ValidationError::TooLong {
            max: MAX_DOCKER_NAME_LENGTH,
            actual: name.len(),
        });
    }

    // Check for path traversal
    if name.contains("..") {
        return Err(ValidationError::PathTraversal);
    }

    // Must contain only valid characters
    for c in name.chars() {
        if !matches!(c, 'a'..='z' | '0'..='9' | '_' | '.' | '-' | '/') {
            if c.is_ascii_uppercase() {
                return Err(ValidationError::InvalidDockerName(
                    "must be lowercase".to_string(),
                ));
            }
            return Err(ValidationError::ForbiddenCharacter(c));
        }
    }

    // Cannot start with separator
    if name.starts_with('/') || name.starts_with('.') || name.starts_with('-') {
        return Err(ValidationError::InvalidDockerName(
            "cannot start with separator or special character".to_string(),
        ));
    }

    // Cannot end with separator
    if name.ends_with('/') {
        return Err(ValidationError::InvalidDockerName(
            "cannot end with /".to_string(),
        ));
    }

    // No consecutive separators (except ..)
    if name.contains("//") || name.contains("--") || name.contains("__") {
        return Err(ValidationError::InvalidDockerName(
            "consecutive separators not allowed".to_string(),
        ));
    }

    // Each path segment must start with alphanumeric
    for segment in name.split('/') {
        if segment.is_empty() {
            return Err(ValidationError::InvalidDockerName(
                "empty path segment".to_string(),
            ));
        }
        // Safety: segment.is_empty() checked above, but use match for defense-in-depth
        let Some(first) = segment.chars().next() else {
            return Err(ValidationError::InvalidDockerName(
                "empty path segment".to_string(),
            ));
        };
        if !first.is_ascii_alphanumeric() {
            return Err(ValidationError::InvalidDockerName(
                "segment must start with alphanumeric".to_string(),
            ));
        }
    }

    Ok(())
}

/// Validate content digest format.
///
/// Supported formats:
/// - `sha256:<64 hex chars>`
/// - `sha512:<128 hex chars>`
///
/// Examples:
/// - `sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4` ✓
/// - `sha256:ABC` ✗ (uppercase)
/// - `md5:abc` ✗ (unsupported algorithm)
pub fn validate_digest(digest: &str) -> Result<(), ValidationError> {
    if digest.is_empty() {
        return Err(ValidationError::EmptyInput);
    }

    // Check for path traversal (shouldn't be in digest but defensive check)
    if digest.contains("..") || digest.contains('/') {
        return Err(ValidationError::PathTraversal);
    }

    let parts: Vec<&str> = digest.splitn(2, ':').collect();
    if parts.len() != 2 {
        return Err(ValidationError::InvalidDigest(
            "missing algorithm prefix (expected algo:hash)".to_string(),
        ));
    }

    let (algo, hash) = (parts[0], parts[1]);

    match algo {
        "sha256" => {
            if hash.len() != 64 {
                return Err(ValidationError::InvalidDigest(format!(
                    "sha256 hash must be 64 characters, got {}",
                    hash.len()
                )));
            }
        }
        "sha512" => {
            if hash.len() != 128 {
                return Err(ValidationError::InvalidDigest(format!(
                    "sha512 hash must be 128 characters, got {}",
                    hash.len()
                )));
            }
        }
        _ => {
            return Err(ValidationError::InvalidDigest(format!(
                "unsupported algorithm: {} (use sha256 or sha512)",
                algo
            )));
        }
    }

    // Hash must be lowercase hex
    for c in hash.chars() {
        if !matches!(c, '0'..='9' | 'a'..='f') {
            if c.is_ascii_uppercase() {
                return Err(ValidationError::InvalidDigest(
                    "hash must be lowercase hex".to_string(),
                ));
            }
            return Err(ValidationError::InvalidDigest(format!(
                "invalid character in hash: {:?}",
                c
            )));
        }
    }

    Ok(())
}

/// Validate Docker tag or reference (tag or digest).
///
/// Tags:
/// - Alphanumeric, dots, underscores, hyphens
/// - Max 128 characters
/// - Must start with alphanumeric
///
/// References may also be digests (sha256:...).
pub fn validate_docker_reference(reference: &str) -> Result<(), ValidationError> {
    if reference.is_empty() {
        return Err(ValidationError::EmptyInput);
    }

    if reference.len() > MAX_REFERENCE_LENGTH {
        return Err(ValidationError::TooLong {
            max: MAX_REFERENCE_LENGTH,
            actual: reference.len(),
        });
    }

    // Check for path traversal
    if reference.contains("..") || reference.contains('/') {
        return Err(ValidationError::PathTraversal);
    }

    // If it looks like a digest, validate as digest
    if reference.starts_with("sha256:") || reference.starts_with("sha512:") {
        return validate_digest(reference);
    }

    // Validate as tag
    // Safety: empty check at function start, but use let-else for defense-in-depth
    let Some(first) = reference.chars().next() else {
        return Err(ValidationError::EmptyInput);
    };
    if !first.is_ascii_alphanumeric() {
        return Err(ValidationError::InvalidReference(
            "tag must start with alphanumeric".to_string(),
        ));
    }

    for c in reference.chars() {
        if !matches!(c, 'a'..='z' | 'A'..='Z' | '0'..='9' | '.' | '_' | '-') {
            return Err(ValidationError::ForbiddenCharacter(c));
        }
    }

    Ok(())
}

/// Middleware that rejects requests with null bytes in the URI path.
///
/// Null bytes in URLs are used in path-traversal attacks. Axum URL-decodes
/// `%00` before passing the path to handlers, which can cause panics or
/// unexpected 500 errors. This middleware intercepts null bytes early and
/// returns a clean 400 Bad Request.
pub async fn reject_null_bytes_middleware(request: Request<Body>, next: Next) -> Response {
    let path = request.uri().path();

    // Check for literal null byte (already URL-decoded by hyper) or
    // percent-encoded null byte in the raw URI.
    if path.contains('\0') || path.contains("%00") || path.contains("%2500") {
        return (
            StatusCode::BAD_REQUEST,
            "Bad Request: null byte in URL path",
        )
            .into_response();
    }

    next.run(request).await
}

/// Match an artifact namespace `value` (a slash-separated coordinate such as
/// `myorg/repo`) against a scope `pattern` using segment-aware glob semantics.
///
/// This is used to enforce OIDC `namespace_scope` and is intentionally **not**
/// the same matcher as the `sub`-claim glob in the OIDC provider: that one is
/// substring/contains-based and is unsafe for `/`-separated paths (e.g. `org*`
/// would match `org-evil`). This matcher is anchored at both ends and treats
/// `/` as a hard segment boundary.
///
/// Semantics (`*` never matches across `/` — a segment boundary is hard):
/// - the whole pattern `"*"` matches anything — the universal, backward-compatible
///   no-op used by the default `namespace_scope = ["*"]`.
/// - a `**` segment matches zero or more segments (`github/**` matches `github`,
///   `github/a`, and `github/a/b`). `**` is only a wildcard as a whole segment.
/// - within a segment, `*` matches any run of non-`/` characters: a bare `*`
///   segment matches exactly one segment (`github/*` matches `github/repo` but
///   not `github/a/b`), and `team-*-dev` matches `team-alpha-dev` but never
///   `team-alpha/dev`.
/// - segments without `*` must match literally.
///
/// Note `github*/x` matches `github-evil/x` — an intra-segment trailing `*`
/// behaves like any glob. Scopes that must not capture sibling namespaces
/// should end the literal part at a `/` boundary (`github/**`, not `github*`).
///
/// # Examples
/// ```ignore
/// assert!(namespace_match("*", "anything/at/all"));
/// assert!(namespace_match("github/*", "github/repo"));
/// assert!(!namespace_match("github/*", "github-evil/x"));
/// assert!(!namespace_match("github/*", "github/a/b"));
/// assert!(namespace_match("github/**", "github/a/b"));
/// assert!(namespace_match("team-*-dev", "team-alpha-dev"));
/// assert!(!namespace_match("team-*-dev", "team-alpha/dev"));
/// ```
pub fn namespace_match(pattern: &str, value: &str) -> bool {
    // Universal no-op: the default scope, and any explicit `*`, matches everything.
    if pattern == "*" {
        return true;
    }
    let pat: Vec<&str> = pattern.split('/').collect();
    let val: Vec<&str> = value.split('/').collect();
    segments_match(&pat, &val)
}

/// Recursive segment matcher backing [`namespace_match`]. Patterns are operator
/// config of a handful of segments, so the worst-case branching on `**` is not a
/// practical concern.
fn segments_match(pat: &[&str], val: &[&str]) -> bool {
    match pat.split_first() {
        // Pattern exhausted: match iff the value is also exhausted (anchored end).
        None => val.is_empty(),
        // `**` consumes zero or more value segments.
        Some((&"**", rest)) => {
            // Zero consumed:
            if segments_match(rest, val) {
                return true;
            }
            // One or more consumed (suffixes val[1..], val[2..], …, []):
            (0..val.len()).any(|i| segments_match(rest, &val[i + 1..]))
        }
        // Any other segment consumes exactly one value segment; `*` inside it
        // matches within that segment only (never across `/`).
        Some((&seg, rest)) => {
            !val.is_empty() && segment_glob(seg, val[0]) && segments_match(rest, &val[1..])
        }
    }
}

/// Char-level glob for one path segment: `*` matches any run of characters
/// (the segment split has already removed every `/`). Iterative single-star
/// backtracking — O(len(pattern) · len(value)) worst case, no recursion, so
/// adversarial fuzz inputs can't blow the stack or go exponential.
fn segment_glob(pattern: &str, value: &str) -> bool {
    if !pattern.contains('*') {
        return pattern == value;
    }
    // Byte-wise is UTF-8-safe here: `*` is ASCII and never a continuation byte,
    // and non-wildcard bytes must be equal anyway.
    let (p, v) = (pattern.as_bytes(), value.as_bytes());
    let (mut pi, mut vi) = (0, 0);
    let mut backtrack: Option<(usize, usize)> = None;
    while vi < v.len() {
        if pi < p.len() && p[pi] == b'*' {
            backtrack = Some((pi, vi));
            pi += 1;
        } else if pi < p.len() && p[pi] == v[vi] {
            pi += 1;
            vi += 1;
        } else if let Some((star_pi, star_vi)) = backtrack {
            // Let the last `*` absorb one more byte and retry after it.
            backtrack = Some((star_pi, star_vi + 1));
            pi = star_pi + 1;
            vi = star_vi + 1;
        } else {
            return false;
        }
    }
    p[pi..].iter().all(|&b| b == b'*')
}

