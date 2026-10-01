//! Falsification tests for the statements in proofs/Properties.lean. Each
//! checks the property on random inputs and counts how often its premises
//! hold, so a statement that is false, or true only because its premises
//! never hold, fails here.
use crate::tests::Rng;
use nora_kernel::*;

const ROLES: &[&str] = &["read", "write", "admin", "owner"];
const METHODS: &[Method] = &[Method::Get, Method::Head, Method::Put, Method::Post, Method::Delete, Method::Patch];
const N: usize = 3_000_000;
/// Each property's premises must hold in at least this many cases.
const MIN_HITS: usize = 500;

fn b(s: &str) -> Vec<u8> {
    s.as_bytes().to_vec()
}
fn bs(v: &[String]) -> Vec<Vec<u8>> {
    v.iter().map(|s| b(s)).collect()
}

fn case(r: &mut Rng) -> (OidcProvider, Claims, Request) {
    let rules = (0..r.below(4)).map(|_| OidcRoleRule {
        pattern: b(&r.text(4)),
        role: b(ROLES[r.below(4) as usize]),
        namespace_scope: if r.chance(50) { Some(bs(&r.scope())) } else { None },
    }).collect();
    let p = OidcProvider {
        max_token_lifetime_secs: r.below(10),
        role_rules: rules,
        namespace_scope: bs(&r.scope()),
        namespace_scope_enforcement: if r.chance(20) { ScopeEnforcement::Audit } else { ScopeEnforcement::Enforce },
    };
    let c = Claims {
        sub: if r.chance(90) { Some(b(&r.text(4))) } else { None },
        iat: if r.chance(70) { Some(r.below(20)) } else { None },
        exp: if r.chance(70) { Some(r.below(20)) } else { None },
    };
    let req = Request {
        method: METHODS[r.below(6) as usize],
        is_admin: r.chance(20),
        namespace: if r.chance(80) { Some(b(&r.text(5))) } else { None },
    };
    (p, c, req)
}

fn subject(c: &Claims) -> Vec<u8> {
    c.sub.clone().unwrap_or_default()
}
fn first_match(p: &OidcProvider, sub: &[u8]) -> Option<usize> {
    p.role_rules.iter().position(|x| glob_match(&x.pattern, sub))
}
fn is_write(m: Method) -> bool {
    matches!(m, Method::Put | Method::Post | Method::Delete | Method::Patch)
}
fn unrestricted(scope: &[Vec<u8>]) -> bool {
    scope.iter().any(|p| p == b"*")
}
fn in_scope(scope: &[Vec<u8>], ns: &[u8]) -> bool {
    scope.iter().any(|p| namespace_match(p, ns))
}

/// Runs `check` on N cases; `check` returns whether the premises held.
fn property(seed: u64, check: impl Fn(&OidcProvider, &Claims, &Request, &Result<Reply, Error>) -> bool) {
    let mut r = Rng(seed);
    let mut hits = 0;
    for _ in 0..N {
        let (p, c, req) = case(&mut r);
        let out = transition(&p, &c, &req);
        if check(&p, &c, &req, &out) {
            hits += 1;
        }
    }
    assert!(hits >= MIN_HITS, "premises held only {hits} times");
}

#[test]
fn read_only_cannot_write() {
    property(1, |p, c, req, out| {
        if out.is_err() || !is_write(req.method) {
            return false;
        }
        let i = first_match(p, &subject(c)).expect("a rule matched");
        assert!(p.role_rules[i].role == b"write" || p.role_rules[i].role == b"admin");
        true
    });
}

#[test]
fn provider_ceiling() {
    property(2, |p, _, req, out| {
        let Some(ns) = &req.namespace else { return false };
        if out.is_err() || p.namespace_scope_enforcement != ScopeEnforcement::Enforce || unrestricted(&p.namespace_scope) {
            return false;
        }
        assert!(in_scope(&p.namespace_scope, ns));
        true
    });
}

#[test]
fn rule_narrows() {
    property(3, |p, c, req, out| {
        let Some(ns) = &req.namespace else { return false };
        if out.is_err() || p.namespace_scope_enforcement != ScopeEnforcement::Enforce {
            return false;
        }
        let Some(i) = first_match(p, &subject(c)) else { return false };
        let Some(sc) = &p.role_rules[i].namespace_scope else { return false };
        if unrestricted(sc) {
            return false;
        }
        assert!(in_scope(sc, ns));
        true
    });
}

#[test]
fn audit_never_denies() {
    property(4, |p, _, req, out| {
        if p.namespace_scope_enforcement != ScopeEnforcement::Audit || req.namespace.is_none() {
            return false;
        }
        assert_ne!(*out, Err(Error::NamespaceDenied));
        true
    });
}

#[test]
fn lifetime_bounded() {
    property(5, |p, c, _, out| {
        let (Some(iat), Some(exp)) = (c.iat, c.exp) else { return false };
        if out.is_err() {
            return false;
        }
        assert!(exp.saturating_sub(iat) <= p.max_token_lifetime_secs);
        true
    });
}

/// `globSpec` in Spec.lean, transcribed.
fn parts_match(parts: &[Vec<u8>], i: usize, v: &[u8]) -> bool {
    let Some((part, rest)) = parts.split_first() else { return true };
    if part.is_empty() {
        parts_match(rest, i + 1, v)
    } else if i == 0 {
        v.starts_with(part) && parts_match(rest, i + 1, &v[part.len()..])
    } else if rest.is_empty() {
        v.ends_with(part)
    } else {
        match (0..=v.len()).find(|&k| v[k..].starts_with(part)) {
            Some(k) => parts_match(rest, i + 1, &v[k + part.len()..]),
            None => false,
        }
    }
}
fn glob_spec(pattern: &[u8], v: &[u8]) -> bool {
    if pattern == b"*" {
        return true;
    }
    let parts: Vec<Vec<u8>> = pattern.split(|&c| c == b'*').map(|x| x.to_vec()).collect();
    if parts.len() == 1 { pattern == v } else { parts_match(&parts, 0, v) }
}

/// `segGlobSpec` in Spec.lean, transcribed.
fn seg_glob_spec(p: &[u8], v: &[u8]) -> bool {
    match p.split_first() {
        None => v.is_empty(),
        Some((b'*', rest)) => seg_glob_spec(rest, v) || (!v.is_empty() && seg_glob_spec(p, &v[1..])),
        Some((c, rest)) => !v.is_empty() && v[0] == *c && seg_glob_spec(rest, &v[1..]),
    }
}

#[test]
fn matchers_agree_with_models() {
    let mut r = Rng(6);
    let (mut g, mut s) = (0, 0);
    for _ in 0..N {
        let (p, v) = (b(&r.text(6)), b(&r.text(6)));
        let got = glob_match(&p, &v);
        assert_eq!(got, glob_spec(&p, &v), "{p:?} {v:?}");
        g += got as usize;
        let got = segment_glob(&p, &v);
        assert_eq!(got, seg_glob_spec(&p, &v), "{p:?} {v:?}");
        s += got as usize;
    }
    // Both outcomes occur.
    assert!(g >= MIN_HITS && N - g >= MIN_HITS && s >= MIN_HITS && N - s >= MIN_HITS, "{g} {s}");
}
