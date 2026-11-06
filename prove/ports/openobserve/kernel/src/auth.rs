//! `core/src/auth.rs`: `org_from_path`, `routed_path`, and the org the
//! `AuthExtractor` (`FromRequestParts`, lines 340-360) hands to the
//! permission check.
use crate::bytes::{bytes_eq, contains, split_slash};
use crate::delegation::relative_path;

fn lit(s: &[u8]) -> Vec<u8> {
    s.to_vec()
}

/// `V2_ORG_MODULES`.
pub fn v2_org_modules() -> Vec<Vec<u8>> {
    let mut out = Vec::new();
    out.push(lit(b"alerts"));
    out.push(lit(b"folders"));
    out.push(lit(b"reports"));
    out.push(lit(b"synthetics"));
    out.push(lit(b"incidents"));
    out.push(lit(b"downtimes"));
    out.push(lit(b"workflows"));
    out.push(lit(b"alert_calibration"));
    out.push(lit(b"fleets"));
    out
}

/// `org_from_path(&path_columns[..n])` for `n <= path_columns.len()`.
pub fn org_from_path_prefix(cols: &[Vec<u8>], n: usize) -> Vec<u8> {
    if n >= 3 && bytes_eq(&cols[0], b"v2") && contains(&v2_org_modules(), &cols[2]) {
        return cols[1].clone();
    }
    if n >= 1 {
        return cols[0].clone();
    }
    Vec::new()
}

/// `org_from_path(path_columns)`.
pub fn org_from_path(cols: &[Vec<u8>]) -> Vec<u8> {
    org_from_path_prefix(cols, cols.len())
}

/// The `org_id` the `AuthExtractor` computes for a request path: the routed
/// path split at `/`, one trailing empty segment dropped, then `org_from_path`.
pub fn extractor_org_id(path: &[u8]) -> Vec<u8> {
    let routed = relative_path(path);
    let cols = split_slash(&routed);
    let n = if cols.len() > 1 && cols[cols.len() - 1].len() == 0 { cols.len() - 1 } else { cols.len() };
    org_from_path_prefix(&cols, n)
}
