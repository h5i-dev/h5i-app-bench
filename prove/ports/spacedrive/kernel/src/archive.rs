//! `core/src/ops/files/archive/directory.rs` `ArchiveEntry::landing`: where an
//! archive entry lands beneath the extraction destination. The kernel returns
//! the path's segments (what `PathBuf::from_iter` is built from).

/// `name.replace('\\', "/")`.
pub fn normalize(name: &[u8]) -> Vec<u8> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < name.len() {
        if name[i] == b'\\' {
            out.push(b'/');
        } else {
            out.push(name[i]);
        }
        i += 1;
    }
    out
}

/// `part.contains('\0')`.
fn has_nul(part: &[u8]) -> bool {
    let mut i = 0;
    while i < part.len() {
        if part[i] == 0 {
            return true;
        }
        i += 1;
    }
    false
}

fn is_dot(part: &[u8]) -> bool {
    part.len() == 1 && part[0] == b'.'
}

fn is_dotdot(part: &[u8]) -> bool {
    part.len() == 2 && part[0] == b'.' && part[1] == b'.'
}

/// The loop over `normalized.split('/')`: `None` at the first `..` or NUL
/// segment, else the non-empty segments other than `.`, in order.
pub fn components(normalized: &[u8]) -> Option<Vec<Vec<u8>>> {
    let mut out: Vec<Vec<u8>> = Vec::new();
    let mut cur: Vec<u8> = Vec::new();
    let mut i = 0;
    while i <= normalized.len() {
        if i == normalized.len() || normalized[i] == b'/' {
            if cur.len() == 0 || is_dot(&cur) {
                // "" | "." => continue
            } else if is_dotdot(&cur) {
                return None;
            } else if has_nul(&cur) {
                return None;
            } else {
                out.push(cur);
            }
            cur = Vec::new();
        } else {
            cur.push(normalized[i]);
        }
        i += 1;
    }
    Some(out)
}

/// `components.into_iter().skip(strip as usize).collect()`.
pub fn skip(parts: Vec<Vec<u8>>, strip: u32) -> Vec<Vec<u8>> {
    let mut out = Vec::new();
    let mut i = strip as usize;
    while i < parts.len() {
        out.push(parts[i].clone());
        i += 1;
    }
    out
}

/// `ArchiveEntry::landing(strip)`.
pub fn landing(name: &[u8], strip: u32) -> Option<Vec<Vec<u8>>> {
    let normalized = normalize(name);
    let parts = match components(&normalized) {
        None => return None,
        Some(p) => p,
    };
    let kept = skip(parts, strip);
    if kept.len() == 0 {
        return None;
    }
    Some(kept)
}
