// Pinned migration_safety.rs byte scanner. String allocation/rendering is
// represented by UTF-8 byte vectors; scanner byte positions remain exact.
pub fn lower(c: u8) -> u8 { if c >= b'A' && c <= b'Z' { c + 32 } else { c } }
pub fn whitespace(c: u8) -> bool { c == 9 || c == 10 || c == 12 || c == 13 || c == 32 }
pub fn is_word_byte(c: u8) -> bool {
    (c >= b'A' && c <= b'Z') || (c >= b'a' && c <= b'z') || (c >= b'0' && c <= b'9') || c == b'_'
}
pub fn word_boundary(c: u8) -> bool {
    if is_word_byte(c) { false } else { true }
}
pub fn mask_sql(b: &[u8]) -> Vec<u8> {
    let n = b.len();
    let mut out = Vec::new();
    let mut i = 0;
    while i < n {
        let c = b[i];
        let nx = if i + 1 < n { b[i + 1] } else { 0 };
        if c == b'-' && nx == b'-' {
            while i < n && b[i] != b'\n' { out.push(b' '); i += 1; }
        } else if c == b'/' && nx == b'*' {
            out.push(b' '); out.push(b' '); i += 2;
            let mut depth = 1u32;
            while i < n && depth > 0 {
                if b[i] == b'/' && i + 1 < n && b[i + 1] == b'*' {
                    depth += 1; out.push(b' '); out.push(b' '); i += 2;
                } else if b[i] == b'*' && i + 1 < n && b[i + 1] == b'/' {
                    depth -= 1; out.push(b' '); out.push(b' '); i += 2;
                } else {
                    out.push(if b[i] == b'\n' { b'\n' } else { b' ' }); i += 1;
                }
            }
        } else if c == b'\'' {
            out.push(b' '); i += 1;
            while i < n {
                if b[i] == b'\'' && i + 1 < n && b[i + 1] == b'\'' {
                    out.push(b' '); out.push(b' '); i += 2;
                } else if b[i] == b'\'' { out.push(b' '); i += 1; break; }
                else { out.push(if b[i] == b'\n' { b'\n' } else { b' ' }); i += 1; }
            }
        } else { out.push(c); i += 1; }
    }
    out
}
/// Exact byte-offset search, including upstream behavior for an empty needle.
pub fn find_phrase(h: &[u8], needle: &[u8], from: usize) -> Option<(usize, usize)> {
    let mut at = from;
    while at < h.len() {
        let start = at;
        let mut p = at;
        let mut q = 0;
        let mut first = true;
        let mut matched = true;
        while q < needle.len() {
            while q < needle.len() && whitespace(needle[q]) { q += 1; }
            if q == needle.len() { break; }
            if !first {
                let ws_start = p;
                while p < h.len() && whitespace(h[p]) { p += 1; }
                if p == ws_start { matched = false; break; }
            }
            first = false;
            while q < needle.len() && !whitespace(needle[q]) {
                if p >= h.len() || lower(h[p]) != lower(needle[q]) { matched = false; break; }
                q += 1; p += 1;
            }
            if !matched { break; }
        }
        if matched {
            let before_ok = start == 0 || word_boundary(h[start - 1]);
            let after_ok = p >= h.len() || word_boundary(h[p]);
            if before_ok && after_ok { return Some((start, p)); }
        }
        at = start + 1;
    }
    None
}
/// Ordered keyword dispatch avoids a borrowed slice-array iterator in extraction.
pub fn skip_modifier(h: &[u8], p: usize) -> Option<usize> {
    if let Some((s,e)) = find_phrase(h,b"IF NOT EXISTS",p) { if s == p { return Some(e); } }
    if let Some((s,e)) = find_phrase(h,b"IF EXISTS",p) { if s == p { return Some(e); } }
    if let Some((s,e)) = find_phrase(h,b"ONLY",p) { if s == p { return Some(e); } }
    None
}
/// Last schema component, preserving upstream quote/qualifier/fallback rules.
pub fn identifier_after(h: &[u8], from: usize) -> Option<Vec<u8>> {
    let mut p = from;
    loop {
        while p < h.len() && whitespace(h[p]) { p += 1; }
        let next = skip_modifier(h, p);
        match next { Some(e) => p = e, None => break }

    }
    while p < h.len() && whitespace(h[p]) { p += 1; }
    if p < h.len() && h[p] == b'"' { p += 1; }
    let start = p;
    let mut first = Vec::new();
    while p < h.len() && is_word_byte(h[p]) { first.push(lower(h[p])); p += 1; }
    if p == start { return None; }
    if p < h.len() && h[p] == b'.' {
        match identifier_after(h,p+1) { Some(v) => Some(v), None => Some(first) }
    } else { Some(first) }
}
pub fn skip_ws(h: &[u8], from: usize) -> usize {
    let mut p = from;
    while p < h.len() && whitespace(h[p]) { p += 1; }
    p
}
pub fn alter_target(stmt: &[u8], pos: usize) -> Option<Vec<u8>> {
    let mut best = None;
    let mut from = 0;
    while let Some((s,e)) = find_phrase(stmt,b"ALTER TABLE",from) {
        from = e;
        if s <= pos { best = Some(e); } else { break; }
    }
    match best { Some(p) => identifier_after(stmt,p), None => None }
}
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Kind { BlockingIndex, ValidatingConstraint, ColumnRewrite, SetNotNull, VolatileDefault, UnboundedBackfill, TableRewrite }
#[derive(Clone,Debug,PartialEq,Eq)]
pub struct Finding { pub kind: Kind, pub table: Vec<u8>, pub at: usize }
pub fn contains_call(stmt: &[u8], from: usize, name: &[u8]) -> bool {
    let mut i = from;
    while i < stmt.len() {
        let mut j = 0;
        while j < name.len() && i+j < stmt.len() && lower(stmt[i+j]) == name[j] { j += 1; }
        if j == name.len() && i+j < stmt.len() && stmt[i+j] == b'(' { return true; }
        i += 1;
    }
    false
}
pub fn classify(stmt: &[u8]) -> Vec<Finding> {
    let mut out = Vec::new();
    for opener in [b"CREATE INDEX".as_slice(), b"CREATE UNIQUE INDEX".as_slice()] {
        let mut from = 0;
        while let Some((s,e)) = find_phrase(stmt,opener,from) {
            from = e;
            if find_phrase(stmt,b"CONCURRENTLY",e).map(|p|p.0) == Some(skip_ws(stmt,e)) { continue; }
            if let Some((_,on_end)) = find_phrase(stmt,b"ON",e) {
                if let Some(table) = identifier_after(stmt,on_end) { out.push(Finding{kind:Kind::BlockingIndex,table,at:s}); }
            }
        }
    }
    let mut from = 0;
    while let Some((s,e)) = find_phrase(stmt,b"ADD CONSTRAINT",from) {
        from = e;
        if find_phrase(stmt,b"NOT VALID",e).is_some() { continue; }
        if let Some(table) = alter_target(stmt,s) { out.push(Finding{kind:Kind::ValidatingConstraint,table,at:s}); }
    }
    let mut from = 0;
    while let Some((s,e)) = find_phrase(stmt,b"TYPE",from) {
        from = e;
        if find_phrase(stmt,b"ALTER TABLE",0).is_none() { continue; }
        if let Some(table) = alter_target(stmt,s) { out.push(Finding{kind:Kind::ColumnRewrite,table,at:s}); }
    }
    let mut from = 0;
    while let Some((s,e)) = find_phrase(stmt,b"SET NOT NULL",from) {
        from = e;
        if let Some(table) = alter_target(stmt,s) { out.push(Finding{kind:Kind::SetNotNull,table,at:s}); }
    }
    if let Some((add_s,add_e)) = find_phrase(stmt,b"ADD COLUMN",0) {
        if let Some((_,def_e)) = find_phrase(stmt,b"DEFAULT",add_e) {
            let volatile = contains_call(stmt,def_e,b"gen_random_uuid") || contains_call(stmt,def_e,b"uuid_generate_v4") || contains_call(stmt,def_e,b"random") || contains_call(stmt,def_e,b"clock_timestamp");
            if volatile {
                if let Some(table) = alter_target(stmt,add_s) { out.push(Finding{kind:Kind::VolatileDefault,table,at:add_s}); }
            }
        }
    }
    let bounded = find_phrase(stmt,b"LIMIT",0).is_some() || find_phrase(stmt,b"LOOP",0).is_some();
    if !bounded {
        for opener in [b"UPDATE".as_slice(),b"DELETE FROM".as_slice()] {
            let mut from = 0;
            while let Some((s,e)) = find_phrase(stmt,opener,from) {
                from = e;
                if let Some(table) = identifier_after(stmt,e) { out.push(Finding{kind:Kind::UnboundedBackfill,table,at:s}); }
            }
        }
    }
    for opener in [b"CLUSTER".as_slice(),b"VACUUM FULL".as_slice(),b"REINDEX TABLE".as_slice(),b"REINDEX INDEX".as_slice()] {
        let mut from = 0;
        while let Some((s,e)) = find_phrase(stmt,opener,from) {
            from = e;
            if find_phrase(stmt,b"CONCURRENTLY",e).is_some() { continue; }
            if let Some(table) = identifier_after(stmt,e) { out.push(Finding{kind:Kind::TableRewrite,table,at:s}); }
        }
    }
    out
}
