//! `validation.rs`: storage keys, Docker names, digests and references.

/// `ValidationError`, with each message's reason as a variant.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ValidationError {
    PathTraversal,
    EmptyInput,
    TooLong,
    /// An ASCII byte that is not allowed.
    ForbiddenCharacter(u8),
    /// A character outside ASCII.
    ForbiddenNonAscii,
    DockerNameUppercase,
    DockerNameStart,
    DockerNameEnd,
    DockerNameConsecutive,
    DockerNameEmptySegment,
    DockerNameSegmentStart,
    DigestNoAlgorithm,
    DigestLength,
    DigestAlgorithm,
    DigestUppercase,
    DigestCharacter,
    ReferenceStart,
}

const MAX_KEY_LENGTH: usize = 1024;
const MAX_DOCKER_NAME_LENGTH: usize = 256;
const MAX_REFERENCE_LENGTH: usize = 128;

/// `s.contains(c)` for one byte.
pub fn contains_byte(s: &[u8], c: u8) -> bool {
    let mut i = 0;
    while i < s.len() {
        if s[i] == c {
            return true;
        }
        i += 1;
    }
    false
}

/// `s.contains(pair)` for two bytes.
pub fn contains_pair(s: &[u8], a: u8, b: u8) -> bool {
    let mut i = 0;
    while i + 1 < s.len() {
        if s[i] == a && s[i + 1] == b {
            return true;
        }
        i += 1;
    }
    false
}

fn to_ascii_lower(c: u8) -> u8 {
    if c >= b'A' && c <= b'Z' { c + 32 } else { c }
}

/// `ends_with_ci`.
pub fn ends_with_ci(s: &[u8], suffix: &[u8]) -> bool {
    if s.len() < suffix.len() {
        return false;
    }
    let off = s.len() - suffix.len();
    let mut i = 0;
    while i < suffix.len() {
        if to_ascii_lower(s[off + i]) != to_ascii_lower(suffix[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// The index of the first byte of `key` outside ASCII.
fn first_non_ascii(key: &[u8]) -> bool {
    let mut i = 0;
    while i < key.len() {
        if key[i] >= 128 {
            return true;
        }
        i += 1;
    }
    false
}

/// The segment loop of `validate_storage_key`: a `.` or `..` segment.
fn has_dot_segment(key: &[u8]) -> bool {
    let mut start = 0;
    let mut i = 0;
    while i <= key.len() {
        if i == key.len() || key[i] == b'/' {
            let n = i - start;
            if (n == 1 && key[start] == b'.') || (n == 2 && key[start] == b'.' && key[start + 1] == b'.') {
                return true;
            }
            start = i + 1;
        }
        i += 1;
    }
    false
}

/// `validate_storage_key`.
pub fn validate_storage_key(key: &[u8]) -> Result<(), ValidationError> {
    if key.len() == 0 {
        return Err(ValidationError::EmptyInput);
    }
    if key.len() > MAX_KEY_LENGTH {
        return Err(ValidationError::TooLong);
    }
    if first_non_ascii(key) {
        return Err(ValidationError::ForbiddenNonAscii);
    }
    if contains_byte(key, 0) {
        return Err(ValidationError::ForbiddenCharacter(0));
    }
    if key[0] == b'/' || key[0] == b'\\' {
        return Err(ValidationError::PathTraversal);
    }
    if contains_pair(key, b'.', b'.') {
        return Err(ValidationError::PathTraversal);
    }
    if contains_byte(key, b'\\') {
        return Err(ValidationError::PathTraversal);
    }
    if has_dot_segment(key) {
        return Err(ValidationError::PathTraversal);
    }
    Ok(())
}

fn is_docker_char(c: u8) -> bool {
    (c >= b'a' && c <= b'z') || (c >= b'0' && c <= b'9') || c == b'_' || c == b'.' || c == b'-' || c == b'/'
}

fn is_ascii_alphanumeric(c: u8) -> bool {
    (c >= b'a' && c <= b'z') || (c >= b'A' && c <= b'Z') || (c >= b'0' && c <= b'9')
}

/// The character loop of `validate_docker_name`.
fn docker_name_chars(name: &[u8]) -> Result<(), ValidationError> {
    let mut i = 0;
    while i < name.len() {
        let c = name[i];
        if !is_docker_char(c) {
            if c >= b'A' && c <= b'Z' {
                return Err(ValidationError::DockerNameUppercase);
            }
            if c >= 128 {
                return Err(ValidationError::ForbiddenNonAscii);
            }
            return Err(ValidationError::ForbiddenCharacter(c));
        }
        i += 1;
    }
    Ok(())
}

/// The segment loop of `validate_docker_name`.
fn docker_name_segments(name: &[u8]) -> Result<(), ValidationError> {
    let mut start = 0;
    let mut i = 0;
    while i <= name.len() {
        if i == name.len() || name[i] == b'/' {
            if i == start {
                return Err(ValidationError::DockerNameEmptySegment);
            }
            if !is_ascii_alphanumeric(name[start]) {
                return Err(ValidationError::DockerNameSegmentStart);
            }
            start = i + 1;
        }
        i += 1;
    }
    Ok(())
}

/// `validate_docker_name`.
pub fn validate_docker_name(name: &[u8]) -> Result<(), ValidationError> {
    if name.len() == 0 {
        return Err(ValidationError::EmptyInput);
    }
    if name.len() > MAX_DOCKER_NAME_LENGTH {
        return Err(ValidationError::TooLong);
    }
    if contains_pair(name, b'.', b'.') {
        return Err(ValidationError::PathTraversal);
    }
    docker_name_chars(name)?;
    if name[0] == b'/' || name[0] == b'.' || name[0] == b'-' {
        return Err(ValidationError::DockerNameStart);
    }
    if name[name.len() - 1] == b'/' {
        return Err(ValidationError::DockerNameEnd);
    }
    if contains_pair(name, b'/', b'/') || contains_pair(name, b'-', b'-') || contains_pair(name, b'_', b'_') {
        return Err(ValidationError::DockerNameConsecutive);
    }
    docker_name_segments(name)
}

fn is_lower_hex(c: u8) -> bool {
    (c >= b'0' && c <= b'9') || (c >= b'a' && c <= b'f')
}

/// The hash loop of `validate_digest`, from `from`.
fn digest_hash_chars(d: &[u8], from: usize) -> Result<(), ValidationError> {
    let mut i = from;
    while i < d.len() {
        let c = d[i];
        if !is_lower_hex(c) {
            if c >= b'A' && c <= b'Z' {
                return Err(ValidationError::DigestUppercase);
            }
            return Err(ValidationError::DigestCharacter);
        }
        i += 1;
    }
    Ok(())
}

/// `digest.find(':')`.
fn find_colon(d: &[u8]) -> Option<usize> {
    let mut i = 0;
    while i < d.len() {
        if d[i] == b':' {
            return Some(i);
        }
        i += 1;
    }
    None
}

fn prefix_is(d: &[u8], len: usize, lit: &[u8]) -> bool {
    if len != lit.len() {
        return false;
    }
    let mut i = 0;
    while i < len {
        if d[i] != lit[i] {
            return false;
        }
        i += 1;
    }
    true
}

/// `validate_digest`: `algo:hash` split at the first `:`.
pub fn validate_digest(digest: &[u8]) -> Result<(), ValidationError> {
    if digest.len() == 0 {
        return Err(ValidationError::EmptyInput);
    }
    if contains_pair(digest, b'.', b'.') || contains_byte(digest, b'/') {
        return Err(ValidationError::PathTraversal);
    }
    let colon = match find_colon(digest) {
        Some(i) => i,
        None => return Err(ValidationError::DigestNoAlgorithm),
    };
    let hash_len = digest.len() - colon - 1;
    if prefix_is(digest, colon, b"sha256") {
        if hash_len != 64 {
            return Err(ValidationError::DigestLength);
        }
    } else if prefix_is(digest, colon, b"sha512") {
        if hash_len != 128 {
            return Err(ValidationError::DigestLength);
        }
    } else {
        return Err(ValidationError::DigestAlgorithm);
    }
    digest_hash_chars(digest, colon + 1)
}

fn starts_with(s: &[u8], p: &[u8]) -> bool {
    if s.len() < p.len() {
        return false;
    }
    prefix_is(s, p.len(), p)
}

fn is_tag_char(c: u8) -> bool {
    is_ascii_alphanumeric(c) || c == b'.' || c == b'_' || c == b'-'
}

/// The character loop of `validate_docker_reference`.
fn reference_chars(r: &[u8]) -> Result<(), ValidationError> {
    let mut i = 0;
    while i < r.len() {
        let c = r[i];
        if !is_tag_char(c) {
            if c >= 128 {
                return Err(ValidationError::ForbiddenNonAscii);
            }
            return Err(ValidationError::ForbiddenCharacter(c));
        }
        i += 1;
    }
    Ok(())
}

/// `validate_docker_reference`.
pub fn validate_docker_reference(reference: &[u8]) -> Result<(), ValidationError> {
    if reference.len() == 0 {
        return Err(ValidationError::EmptyInput);
    }
    if reference.len() > MAX_REFERENCE_LENGTH {
        return Err(ValidationError::TooLong);
    }
    if contains_pair(reference, b'.', b'.') || contains_byte(reference, b'/') {
        return Err(ValidationError::PathTraversal);
    }
    if starts_with(reference, b"sha256:") || starts_with(reference, b"sha512:") {
        return validate_digest(reference);
    }
    if !is_ascii_alphanumeric(reference[0]) {
        return Err(ValidationError::ReferenceStart);
    }
    reference_chars(reference)
}
