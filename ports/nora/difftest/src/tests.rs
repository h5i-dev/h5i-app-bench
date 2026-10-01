use nora_upstream::auth::oidc as up;
use nora_upstream::auth::{enforce_namespace_scope, NamespaceAuthority};
use nora_upstream::validation::namespace_match;
use nora_kernel as k;

/// xorshift64*, so the test needs no dependencies.
pub(crate) struct Rng(pub(crate) u64);
impl Rng {
    pub(crate) fn next(&mut self) -> u64 {
        self.0 ^= self.0 >> 12;
        self.0 ^= self.0 << 25;
        self.0 ^= self.0 >> 27;
        self.0.wrapping_mul(0x2545F4914F6CDD1D)
    }
    pub(crate) fn below(&mut self, n: u64) -> u64 {
        self.next() % n
    }
    pub(crate) fn chance(&mut self, pct: u64) -> bool {
        self.below(100) < pct
    }
    /// Short strings over an alphabet that hits the matchers' edge cases.
    pub(crate) fn text(&mut self, max: u64) -> String {
        const A: &[&str] = &["a", "b", "*", "**", "/", ":", "-", "é", ""];
        (0..self.below(max + 1)).map(|_| A[self.below(A.len() as u64) as usize]).collect()
    }
    pub(crate) fn scope(&mut self) -> Vec<String> {
        (0..self.below(3)).map(|_| if self.chance(15) { "*".into() } else { self.text(5) }).collect()
    }
}

fn b(s: &str) -> Vec<u8> {
    s.as_bytes().to_vec()
}
fn bs(v: &[String]) -> Vec<Vec<u8>> {
    v.iter().map(|s| b(s)).collect()
}

fn mode(m: up::ScopeEnforcement) -> k::ScopeEnforcement {
    match m {
        up::ScopeEnforcement::Enforce => k::ScopeEnforcement::Enforce,
        up::ScopeEnforcement::Audit => k::ScopeEnforcement::Audit,
    }
}

/// Upstream's request path, from `validate_token`'s claims half through the
/// middleware's OIDC branch (`auth/mod.rs`, transcribed: it takes an axum
/// request) to the handler's `enforce_namespace_scope`.
fn upstream_transition(p: &up::OidcProvider, c: up::Claims, method: k::Method, is_admin: bool,
                       namespace: Option<&str>) -> Result<(), k::Error> {
    let v = up::OidcValidator { provider: p.clone(), active: true, jwt: Default::default() };
    let identity = match v.validate_claims(p, c) {
        Ok(i) => i,
        Err(e) if e.starts_with("Token lifetime") => return Err(k::Error::TokenLifetime),
        Err(_) => return Err(k::Error::NoRoleRule),
    };
    let writes = matches!(method, k::Method::Put | k::Method::Post | k::Method::Delete | k::Method::Patch);
    if writes && !identity.role.can_write() {
        return Err(k::Error::ReadOnly);
    }
    if is_admin && !identity.role.can_admin() {
        return Err(k::Error::AdminRequired);
    }
    let authority = NamespaceAuthority::from_oidc_scopes(
        &identity.provider,
        std::iter::once(identity.namespace_scope.as_slice()).chain(identity.rule_namespace_scope.as_deref()),
        identity.namespace_scope_enforcement,
    );
    if let Some(ns) = namespace {
        enforce_namespace_scope(&authority, ns).map_err(|_| k::Error::NamespaceDenied)?;
    }
    Ok(())
}

#[test]
fn namespace_match_agrees() {
    let mut r = Rng(0x9E3779B97F4A7C15);
    for _ in 0..2_000_000 {
        let (p, v) = (r.text(6), r.text(6));
        assert_eq!(k::namespace_match(&b(&p), &b(&v)), namespace_match(&p, &v), "{p:?} {v:?}");
    }
}

#[test]
fn transition_agrees() {
    let mut r = Rng(0xD1B54A32D192ED03);
    const ROLES: &[&str] = &["read", "write", "admin", "owner"];
    const METHODS: &[k::Method] = &[k::Method::Get, k::Method::Head, k::Method::Put,
        k::Method::Post, k::Method::Delete, k::Method::Patch];
    let mut outcomes = std::collections::BTreeMap::new();
    for _ in 0..500_000 {
        let rules: Vec<up::OidcRoleRule> = (0..r.below(4)).map(|_| up::OidcRoleRule {
            pattern: r.text(4),
            role: ROLES[r.below(4) as usize].into(),
            namespace_scope: if r.chance(50) { Some(r.scope()) } else { None },
        }).collect();
        let p = up::OidcProvider {
            name: "p".into(), issuer: "i".into(), max_token_lifetime_secs: r.below(10),
            role_rules: rules, namespace_scope: r.scope(),
            namespace_scope_enforcement: if r.chance(20) { up::ScopeEnforcement::Audit } else { up::ScopeEnforcement::Enforce },
        };
        let sub = if r.chance(90) { Some(r.text(4)) } else { None };
        let iat = if r.chance(70) { Some(r.below(20)) } else { None };
        let exp = if r.chance(70) { Some(r.below(20)) } else { None };
        let method = METHODS[r.below(6) as usize];
        let is_admin = r.chance(20);
        let ns = if r.chance(80) { Some(r.text(5)) } else { None };

        let kp = k::OidcProvider {
            max_token_lifetime_secs: p.max_token_lifetime_secs,
            role_rules: p.role_rules.iter().map(|x| k::OidcRoleRule {
                pattern: b(&x.pattern), role: b(&x.role),
                namespace_scope: x.namespace_scope.as_deref().map(bs),
            }).collect(),
            namespace_scope: bs(&p.namespace_scope),
            namespace_scope_enforcement: mode(p.namespace_scope_enforcement),
        };
        let kc = k::Claims { sub: sub.as_deref().map(b), iat, exp };
        let req = k::Request { method, is_admin, namespace: ns.as_deref().map(b) };
        let got = k::transition(&kp, &kc, &req).map(|_| ());
        let want = upstream_transition(&p, up::Claims { sub, iat, exp }, method, is_admin, ns.as_deref());
        assert_eq!(got, want, "{p:?} {kc:?} {req:?}");
        *outcomes.entry(format!("{want:?}")).or_insert(0) += 1;
    }
    // Every outcome must be exercised, or the test says little.
    println!("{outcomes:?}");
    assert_eq!(outcomes.len(), 6, "{outcomes:?}");
}
