//! nora's OIDC write authorization (getnora-io/nora @ f864a9a) in the Aeneas
//! subset. Each function follows the upstream function of the same name; the
//! deviations are listed in ../DEVIATIONS.md. The JWT signature and claims
//! parsing are the trusted input: `transition` starts from verified claims.

pub mod oracle;
pub mod lockout;
pub mod middleware;
pub mod net;
pub mod tokens;
pub mod validation;

/// `tokens.rs` `Role`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Role {
    Read,
    Write,
    Admin,
}

impl Role {
    pub fn can_write(&self) -> bool {
        matches!(self, Role::Write | Role::Admin)
    }

    pub fn can_admin(&self) -> bool {
        matches!(self, Role::Admin)
    }
}

/// `config/auth.rs` `ScopeEnforcement`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ScopeEnforcement {
    Enforce,
    Audit,
}

/// `config/auth.rs` `OidcRoleRule`; `role` is the configured string.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct OidcRoleRule {
    pub pattern: Vec<u8>,
    pub role: Vec<u8>,
    pub namespace_scope: Option<Vec<Vec<u8>>>,
}

/// The fields of `config/auth.rs` `OidcProvider` that authorization reads.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct OidcProvider {
    pub max_token_lifetime_secs: u64,
    pub role_rules: Vec<OidcRoleRule>,
    pub namespace_scope: Vec<Vec<u8>>,
    pub namespace_scope_enforcement: ScopeEnforcement,
}

/// Verified JWT claims (`sub`, `iat`, `exp`).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Claims {
    pub sub: Option<Vec<u8>>,
    pub iat: Option<u64>,
    pub exp: Option<u64>,
}

/// `auth/oidc.rs` `OidcIdentity`, without the provider name and issuer.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct OidcIdentity {
    pub subject: Vec<u8>,
    pub role: Role,
    pub namespace_scope: Vec<Vec<u8>>,
    pub rule_namespace_scope: Option<Vec<Vec<u8>>>,
    pub namespace_scope_enforcement: ScopeEnforcement,
}

/// `auth/namespace.rs` `NamespaceAuthority`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum NamespaceAuthority {
    Unrestricted,
    Scoped { scopes: Vec<Vec<Vec<u8>>>, mode: ScopeEnforcement },
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Method {
    Get,
    Head,
    Put,
    Post,
    Delete,
    Patch,
}

/// One OIDC-authenticated request that reaches a write handler.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Request {
    pub method: Method,
    pub is_admin: bool,
    /// The canonical artifact coordinate the handler derives, if it writes one.
    pub namespace: Option<Vec<u8>>,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Reply {
    /// The request reaches the handler, and a namespaced write is in scope.
    Allowed,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    /// `validate_token` rejected the token: lifetime over the ceiling.
    TokenLifetime,
    /// `validate_token` rejected the token: no role rule matched.
    NoRoleRule,
    /// 403 "Read-only OIDC identity".
    ReadOnly,
    /// 403 "Admin role required".
    AdminRequired,
    /// `NamespaceDenied`, mapped to 403 by the handler.
    NamespaceDenied,
}

fn is_star(p: &[u8]) -> bool {
    p.len() == 1 && p[0] == b'*'
}

fn bytes_eq(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut i = 0;
    while i < a.len() {
        if a[i] != b[i] {
            return false;
        }
        i += 1;
    }
    true
}

/// `s.split(sep).collect()`, owning the pieces.
fn split(s: &[u8], sep: u8) -> Vec<Vec<u8>> {
    let mut out = Vec::new();
    let mut cur = Vec::new();
    let mut i = 0;
    while i < s.len() {
        if s[i] == sep {
            out.push(cur);
            cur = Vec::new();
        } else {
            cur.push(s[i]);
        }
        i += 1;
    }
    out.push(cur);
    out
}

/// `s[from..].starts_with(p)`.
fn starts_with_at(s: &[u8], from: usize, p: &[u8]) -> bool {
    if s.len() - from < p.len() {
        return false;
    }
    let mut i = 0;
    while i < p.len() {
        if s[from + i] != p[i] {
            return false;
        }
        i += 1;
    }
    true
}

/// `s[from..].find(p)`, as an index into `s`.
fn find_from(s: &[u8], from: usize, p: &[u8]) -> Option<usize> {
    let mut i = from;
    while i <= s.len() && s.len() - i >= p.len() {
        if starts_with_at(s, i, p) {
            return Some(i);
        }
        i += 1;
    }
    None
}

/// The loop of `auth/oidc.rs` `glob_match` over `parts`, from part `i` with
/// `remaining = value[rem..]`. Aeneas rejects `continue` next to an early
/// return, so an empty part takes the `else` of a plain `if`.
fn glob_parts(parts: &[Vec<u8>], value: &[u8]) -> bool {
    let mut rem = 0;
    let mut i = 0;
    while i < parts.len() {
        let part = &parts[i];
        if part.len() != 0 {
            if i == 0 {
                if !starts_with_at(value, rem, part) {
                    return false;
                }
                rem += part.len();
            } else if i == parts.len() - 1 {
                // `remaining.ends_with(part)`
                if value.len() - rem < part.len() {
                    return false;
                }
                return starts_with_at(value, value.len() - part.len(), part);
            } else {
                match find_from(value, rem, part) {
                    Some(pos) => rem = pos + part.len(),
                    None => return false,
                }
            }
        }
        i += 1;
    }
    true
}

/// `auth/oidc.rs` `glob_match`.
pub fn glob_match(pattern: &[u8], value: &[u8]) -> bool {
    if is_star(pattern) {
        return true;
    }
    let parts = split(pattern, b'*');
    if parts.len() == 1 {
        return bytes_eq(pattern, value);
    }
    glob_parts(&parts, value)
}

/// `OidcValidator::match_role`: first matching rule wins.
pub fn match_role(provider: &OidcProvider, subject: &[u8]) -> Option<(Role, Option<Vec<Vec<u8>>>)> {
    let mut i = 0;
    while i < provider.role_rules.len() {
        let rule = &provider.role_rules[i];
        if glob_match(&rule.pattern, subject) {
            let role = if bytes_eq(&rule.role, b"admin") {
                Role::Admin
            } else if bytes_eq(&rule.role, b"write") {
                Role::Write
            } else if bytes_eq(&rule.role, b"read") {
                Role::Read
            } else {
                return None;
            };
            // `rule.namespace_scope.clone()`; Aeneas has no `Option::clone`.
            let scope = match &rule.namespace_scope {
                Some(s) => Some(s.clone()),
                None => None,
            };
            return Some((role, scope));
        }
        i += 1;
    }
    None
}

/// The claims half of `OidcValidator::validate_token`, after the signature,
/// issuer and audience checks.
pub fn validate_claims(provider: &OidcProvider, claims: &Claims) -> Result<OidcIdentity, Error> {
    if let (Some(iat), Some(exp)) = (claims.iat, claims.exp) {
        let lifetime = exp.saturating_sub(iat);
        if lifetime > provider.max_token_lifetime_secs {
            return Err(Error::TokenLifetime);
        }
    }
    let subject = match &claims.sub {
        Some(s) => s.clone(),
        None => Vec::new(),
    };
    let (role, rule_scope) = match match_role(provider, &subject) {
        Some(x) => x,
        None => return Err(Error::NoRoleRule),
    };
    Ok(OidcIdentity {
        subject,
        role,
        namespace_scope: provider.namespace_scope.clone(),
        rule_namespace_scope: rule_scope,
        namespace_scope_enforcement: provider.namespace_scope_enforcement,
    })
}

fn has_star(scope: &[Vec<u8>]) -> bool {
    let mut i = 0;
    while i < scope.len() {
        if is_star(&scope[i]) {
            return true;
        }
        i += 1;
    }
    false
}

/// `NamespaceAuthority::from_oidc_scopes` for the provider scope and the
/// optional rule scope.
pub fn from_oidc_scopes(
    provider_scope: &[Vec<u8>],
    rule_scope: &Option<Vec<Vec<u8>>>,
    mode: ScopeEnforcement,
) -> NamespaceAuthority {
    let mut scopes = Vec::new();
    if !has_star(provider_scope) {
        scopes.push(provider_scope.to_vec());
    }
    if let Some(r) = rule_scope {
        if !has_star(r) {
            scopes.push(r.clone());
        }
    }
    if scopes.len() == 0 {
        return NamespaceAuthority::Unrestricted;
    }
    NamespaceAuthority::Scoped { scopes, mode }
}

fn contains_star(p: &[u8]) -> bool {
    let mut i = 0;
    while i < p.len() {
        if p[i] == b'*' {
            return true;
        }
        i += 1;
    }
    false
}

/// `p[pi..].iter().all(|&b| b == b'*')`.
fn all_stars_from(p: &[u8], pi: usize) -> bool {
    let mut i = pi;
    while i < p.len() {
        if p[i] != b'*' {
            return false;
        }
        i += 1;
    }
    true
}

/// The backtracking loop of `segment_glob`: the final `pi`, or `None` where
/// upstream returns `false`.
fn glob_scan(p: &[u8], v: &[u8]) -> Option<usize> {
    let mut pi = 0;
    let mut vi = 0;
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
            return None;
        }
    }
    Some(pi)
}

/// `validation.rs` `segment_glob`: `*` matches any run of bytes.
pub fn segment_glob(pattern: &[u8], value: &[u8]) -> bool {
    if !contains_star(pattern) {
        return bytes_eq(pattern, value);
    }
    match glob_scan(pattern, value) {
        Some(pi) => all_stars_from(pattern, pi),
        None => false,
    }
}

/// `(i..val.len()).any(|i| segments_match(rest, &val[i + 1..]))` with `rest`
/// at `pat[pi..]`, as recursion: Aeneas cannot compile a loop inside a
/// recursive function.
fn segments_match_any(pat: &[Vec<u8>], pi: usize, val: &[Vec<u8>], i: usize) -> bool {
    if i < val.len() {
        if segments_match(pat, pi, val, i + 1) {
            return true;
        }
        return segments_match_any(pat, pi, val, i + 1);
    }
    false
}

/// `validation.rs` `segments_match` on `pat[pi..]` and `val[vi..]`.
pub fn segments_match(pat: &[Vec<u8>], pi: usize, val: &[Vec<u8>], vi: usize) -> bool {
    if pi >= pat.len() {
        return vi >= val.len();
    }
    let seg = &pat[pi];
    if seg.len() == 2 && seg[0] == b'*' && seg[1] == b'*' {
        // Zero consumed, then one or more.
        if segments_match(pat, pi + 1, val, vi) {
            return true;
        }
        return segments_match_any(pat, pi + 1, val, vi);
    }
    vi < val.len() && segment_glob(seg, &val[vi]) && segments_match(pat, pi + 1, val, vi + 1)
}

/// `validation.rs` `namespace_match`.
pub fn namespace_match(pattern: &[u8], value: &[u8]) -> bool {
    if is_star(pattern) {
        return true;
    }
    let pat = split(pattern, b'/');
    let val = split(value, b'/');
    segments_match(&pat, 0, &val, 0)
}

fn scope_matches(scope: &[Vec<u8>], namespace: &[u8]) -> bool {
    let mut i = 0;
    while i < scope.len() {
        if namespace_match(&scope[i], namespace) {
            return true;
        }
        i += 1;
    }
    false
}

/// `auth/namespace.rs` `enforce_namespace_scope`, without metrics and logs.
pub fn enforce_namespace_scope(authority: &NamespaceAuthority, namespace: &[u8]) -> Result<(), Error> {
    let (scopes, mode) = match authority {
        NamespaceAuthority::Unrestricted => return Ok(()),
        NamespaceAuthority::Scoped { scopes, mode } => (scopes, *mode),
    };
    let mut all = true;
    let mut i = 0;
    while i < scopes.len() {
        if !scope_matches(&scopes[i], namespace) {
            all = false;
        }
        i += 1;
    }
    if all {
        return Ok(());
    }
    match mode {
        ScopeEnforcement::Enforce => Err(Error::NamespaceDenied),
        ScopeEnforcement::Audit => Ok(()),
    }
}

/// The OIDC branch of `auth/mod.rs` `auth_middleware`, then the handler's
/// `enforce_namespace_scope` call on the coordinate it writes.
pub fn transition(provider: &OidcProvider, claims: &Claims, req: &Request) -> Result<Reply, Error> {
    let identity = validate_claims(provider, claims)?;
    let writes = match req.method {
        Method::Put | Method::Post | Method::Delete | Method::Patch => true,
        Method::Get | Method::Head => false,
    };
    if writes && !identity.role.can_write() {
        return Err(Error::ReadOnly);
    }
    if req.is_admin && !identity.role.can_admin() {
        return Err(Error::AdminRequired);
    }
    let authority = from_oidc_scopes(
        &identity.namespace_scope,
        &identity.rule_namespace_scope,
        identity.namespace_scope_enforcement,
    );
    if let Some(ns) = &req.namespace {
        enforce_namespace_scope(&authority, ns)?;
    }
    Ok(Reply::Allowed)
}
