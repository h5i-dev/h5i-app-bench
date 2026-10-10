//! Remaining pure principal and wildcard/path helpers.
use crate::bytes;
pub enum PrincipalFormat {
    Wildcard(Vec<u8>),
    Object(PrincipalObject),
}
pub struct PrincipalObject {
    pub aws: Option<PrincipalValues>,
    pub service: Option<PrincipalValues>,
}
pub enum PrincipalValues {
    Single(Vec<u8>),
    Multiple(Vec<Vec<u8>>),
}
/// Input Multiple values represent an upstream HashSet; remove repeated list entries.
pub fn principal_values_into_set(values: PrincipalValues) -> Vec<Vec<u8>> {
    match values {
        PrincipalValues::Single(s) => vec![s],
        PrincipalValues::Multiple(v) => unique_values(&v),
    }
}
fn unique_values(values: &[Vec<u8>]) -> Vec<Vec<u8>> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < values.len() {
        if !bytes::member(&out, &values[i]) {
            out.push(values[i].clone());
        }
        i += 1;
    }
    out
}
pub struct LazyBuf<'a> {
    pub source: &'a [u8],
    pub buffer: Option<Vec<u8>>,
    pub written: usize,
}
pub fn lazybuf_new(source: &[u8]) -> LazyBuf<'_> {
    LazyBuf {
        source,
        buffer: None,
        written: 0,
    }
}
/// Paired-byte prefix scan, preserving the upstream empty-text and wildcard cases.
pub fn is_match_as_pattern_prefix(pattern: &[u8], text: &[u8]) -> bool {
    let mut i = 0;
    while i < pattern.len() && i < text.len() {
        let x = pattern[i];
        let y = text[i];
        if x == b'*' {
            return true;
        }
        if x != b'?' && x != y {
            return false;
        }
        i += 1;
    }
    text.len() <= pattern.len()
}
