//! `policy/utils/path.rs` `clean`, Go's `path.Clean`. `LazyBuf` copies the
//! input only once it diverges; writing into a copy from the start gives the
//! same bytes.

pub fn clean(path: &[u8]) -> Vec<u8> {
    if path.len() == 0 {
        return b".".to_vec();
    }
    let p = path;
    let n = path.len();
    let rooted = p[0] == b'/';
    let mut buf = path.to_vec();
    let mut w: usize = 0;
    let mut r: usize = 0;
    let mut dotdot: usize = 0;
    if rooted {
        buf[w] = b'/';
        w += 1;
        r = 1;
        dotdot = 1;
    }
    while r < n {
        if p[r] == b'/' || (p[r] == b'.' && (r + 1 == n || p[r + 1] == b'/')) {
            r += 1;
        } else if p[r] == b'.' && p[r + 1] == b'.' && (r + 2 == n || p[r + 2] == b'/') {
            r += 2;
            if w > dotdot {
                w -= 1;
                w = back_to_slash(&buf, w, dotdot);
            } else if !rooted {
                if w > 0 {
                    buf[w] = b'/';
                    w += 1;
                }
                buf[w] = b'.';
                w += 1;
                buf[w] = b'.';
                w += 1;
                dotdot = w;
            }
        } else {
            if (rooted && w != 1) || (!rooted && w != 0) {
                buf[w] = b'/';
                w += 1;
            }
            let (b2, w2, r2) = copy_element(buf, w, p, r);
            buf = b2;
            w = w2;
            r = r2;
        }
    }
    if w == 0 {
        return b".".to_vec();
    }
    let mut out = Vec::new();
    let mut i = 0;
    while i < w {
        out.push(buf[i]);
        i += 1;
    }
    out
}

/// `while out.w > dotdot && out.index(out.w) != b'/' { out.w -= 1; }`
fn back_to_slash(buf: &[u8], w: usize, dotdot: usize) -> usize {
    let mut w = w;
    while w > dotdot && buf[w] != b'/' {
        w -= 1;
    }
    w
}

/// `while r < n && p[r] != b'/' { out.append(p[r]); r += 1; }`
fn copy_element(mut buf: Vec<u8>, w: usize, p: &[u8], r: usize) -> (Vec<u8>, usize, usize) {
    let mut w = w;
    let mut r = r;
    while r < p.len() && p[r] != b'/' {
        buf[w] = p[r];
        w += 1;
        r += 1;
    }
    (buf, w, r)
}
