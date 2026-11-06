//! Host-side differential harness for the pico-bit armory filename kernel.

pub mod reference;

/// Kernel wrapper: decode + validate, returning the decoded bytes when accepted.
pub fn kernel_decode(raw: &[u8]) -> Option<Vec<u8>> {
    let mut out = [0u8; 64];
    match pico_bit_kernel::decode_filename(raw, &mut out) {
        Some(n) => Some(out[..n].to_vec()),
        None => None,
    }
}

/// Kernel wrapper: the filename-acceptance gate on already-decoded bytes.
pub fn kernel_valid_name(name: &[u8]) -> bool {
    pico_bit_kernel::valid_name(name)
}

/// Build `/armory/<name>` the way the device would, then report whether the
/// resulting path escapes `/armory/` (contains a `..` segment or an extra
/// separator). Used to witness the confinement property at runtime.
pub fn escapes_armory(name: &[u8]) -> bool {
    let mut path = b"/armory/".to_vec();
    path.extend_from_slice(name);
    // Split on '/', drop empty segments, and look for a parent-dir segment.
    path.split(|&b| b == b'/')
        .filter(|seg| !seg.is_empty())
        .any(|seg| seg == b"..")
        // or a name segment beyond the single armory child:
        || path.split(|&b| b == b'/').filter(|s| !s.is_empty()).count() != 2
        || name.contains(&b'\\')
}
