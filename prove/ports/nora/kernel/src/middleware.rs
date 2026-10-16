//! `auth/mod.rs` `auth_middleware`, in upstream's order. What the handler
//! receives is `Outcome::Next`; every early response is another variant.
use crate::oracle::{bytes_eq, Crypto};
use crate::lockout::{after_failure, AuthFailureTracker, FailureEntry};
use crate::net::{resolve_client_ip, IpAddr, TrustedProxies};
use crate::tokens::{verify_token, TokenError, TokenStore, TokenWrite};
use crate::{from_oidc_scopes, validate_claims, Claims, NamespaceAuthority, OidcProvider, Role};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum HttpMethod {
    Get,
    Head,
    Post,
    Put,
    Delete,
    Patch,
    Options,
}

/// `AuthConfig` and the stores the middleware reads.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Config {
    pub enabled: bool,
    pub anonymous_read: bool,
    pub public_web_ui: bool,
    pub public_metrics: bool,
    pub docker_anon_pull: bool,
    /// `HtpasswdAuth`: username and bcrypt hash.
    pub htpasswd: Option<Vec<(Vec<u8>, Vec<u8>)>>,
    pub tokens: Option<TokenStore>,
    /// The OIDC validator, if configured, and `is_active()`.
    pub oidc: Option<(OidcProvider, bool)>,
    pub trusted_proxies: TrustedProxies,
    pub tracker: AuthFailureTracker,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Request {
    pub path: Vec<u8>,
    pub method: HttpMethod,
    /// Whether an `Authorization` header is present.
    pub has_auth_header: bool,
    /// Its value, when it is visible ASCII (`to_str().ok()`).
    pub auth_header: Option<Vec<u8>>,
    /// `ConnectInfo` peer address, and the parsed forwarding headers.
    pub peer: Option<IpAddr>,
    pub xff: Option<IpAddr>,
    pub x_real_ip: Option<IpAddr>,
    /// Seconds since the epoch, and monotonic nanoseconds.
    pub now: u64,
    pub mono: u64,
}

/// The token string of a Bearer header: the JWT validator's verdict on it
/// (signature, issuer, audience; `None` when rejected) is trusted input.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Jwt {
    pub token: Vec<u8>,
    pub claims: Option<Claims>,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Deny {
    /// 401 with a JSON body and a Basic challenge.
    AuthenticationRequired,
    InvalidOrExpiredToken,
    BasicOrBearerRequired,
    BasicNotConfigured,
    InvalidCredentialsEncoding,
    InvalidCredentialsFormat,
    InvalidUsernameOrPassword,
    /// 401 "Authentication required" for a gated web surface without credentials.
    WebChallenge,
    /// 403.
    ReadOnlyToken,
    ReadOnlyOidc,
    AdminRequired,
    NamespaceDenied,
    /// 429 with the remaining lockout.
    TooManyRequests(u64),
    /// 503.
    TokenStoreUnavailable,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Outcome {
    /// The request reaches the handler with these extensions. `role` is
    /// absent where upstream inserts no `AuthenticatedRole`.
    Next { authority: NamespaceAuthority, user: Vec<u8>, role: Option<Role> },
    Deny(Deny),
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Write {
    Token(TokenWrite),
    /// `record_success`: the entry is removed.
    ClearFailures(IpAddr),
    /// `record_failure`: the entry after the failure.
    PutFailures(FailureEntry),
}

fn starts_with(s: &[u8], p: &[u8]) -> bool {
    if s.len() < p.len() {
        return false;
    }
    let mut i = 0;
    while i < p.len() {
        if s[i] != p[i] {
            return false;
        }
        i += 1;
    }
    true
}

fn ends_with(s: &[u8], p: &[u8]) -> bool {
    if s.len() < p.len() {
        return false;
    }
    let off = s.len() - p.len();
    let mut i = 0;
    while i < p.len() {
        if s[off + i] != p[i] {
            return false;
        }
        i += 1;
    }
    true
}

/// `s.strip_prefix(p)`.
fn strip_prefix(s: &[u8], p: &[u8]) -> Option<Vec<u8>> {
    if !starts_with(s, p) {
        return None;
    }
    let mut out = Vec::new();
    let mut i = p.len();
    while i < s.len() {
        out.push(s[i]);
        i += 1;
    }
    Some(out)
}

/// `s.split_once(':')`.
fn split_once_colon(s: &[u8]) -> Option<(Vec<u8>, Vec<u8>)> {
    let mut i = 0;
    while i < s.len() {
        if s[i] == b':' {
            let mut a = Vec::new();
            let mut j = 0;
            while j < i {
                a.push(s[j]);
                j += 1;
            }
            let mut b = Vec::new();
            let mut k = i + 1;
            while k < s.len() {
                b.push(s[k]);
                k += 1;
            }
            return Some((a, b));
        }
        i += 1;
    }
    None
}

pub fn is_public_path(path: &[u8]) -> bool {
    bytes_eq(path, b"/") || bytes_eq(path, b"/health") || bytes_eq(path, b"/ready")
        || bytes_eq(path, b"/api/tokens") || bytes_eq(path, b"/api/tokens/list")
        || bytes_eq(path, b"/api/tokens/revoke")
}

pub fn is_web_surface(path: &[u8]) -> bool {
    if starts_with(path, b"/ui/tokens") || starts_with(path, b"/api/ui/tokens") {
        return false;
    }
    starts_with(path, b"/ui") || starts_with(path, b"/api/ui") || starts_with(path, b"/api-docs")
}

pub fn is_docker_path(path: &[u8]) -> bool {
    bytes_eq(path, b"/v2") || starts_with(path, b"/v2/")
}

pub fn is_admin_path(path: &[u8]) -> bool {
    starts_with(path, b"/api/v1/admin/")
}

fn is_write_method(m: HttpMethod) -> bool {
    match m {
        HttpMethod::Put | HttpMethod::Post | HttpMethod::Delete | HttpMethod::Patch => true,
        _ => false,
    }
}

/// `HtpasswdAuth::authenticate`.
fn authenticate(users: &[(Vec<u8>, Vec<u8>)], crypto: &Crypto, username: &[u8], password: &[u8]) -> bool {
    let mut i = 0;
    while i < users.len() {
        if bytes_eq(&users[i].0, username) {
            return crypto.bcrypt_verify(password, &users[i].1);
        }
        i += 1;
    }
    false
}

/// `try_basic_auth`.
fn try_basic_auth(encoded: &[u8], auth: &Option<Vec<(Vec<u8>, Vec<u8>)>>, crypto: &Crypto) -> Option<Vec<u8>> {
    let decoded = match crypto.base64_decode(encoded) {
        Some(d) => d,
        None => return None,
    };
    if !crypto.is_utf8(&decoded) {
        return None;
    }
    let (username, password) = match split_once_colon(&decoded) {
        Some(p) => p,
        None => return None,
    };
    let users = match auth {
        Some(u) => u,
        None => return None,
    };
    if authenticate(users, crypto, &username, &password) { Some(username) } else { None }
}

fn anonymous() -> Vec<u8> {
    b"anonymous".to_vec()
}

fn token_writes(ws: Vec<TokenWrite>) -> Vec<Write> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < ws.len() {
        out.push(Write::Token(ws[i].clone()));
        i += 1;
    }
    out
}

fn record_success(writes: &mut Vec<Write>, client_ip: Option<IpAddr>) {
    if let Some(ip) = client_ip {
        writes.push(Write::ClearFailures(ip));
    }
}

/// The public-path branch: opportunistic authentication, then anonymous browse.
fn open_path(cfg: &Config, crypto: &Crypto, req: &Request) -> (Vec<Write>, Outcome) {
    if let Some(auth_val) = &req.auth_header {
        if let Some(encoded) = strip_prefix(auth_val, b"Basic ") {
            if let Some(username) = try_basic_auth(&encoded, &cfg.htpasswd, crypto) {
                return (Vec::new(), Outcome::Next {
                    authority: NamespaceAuthority::Unrestricted, user: username, role: Some(Role::Write),
                });
            }
        } else if let Some(token) = strip_prefix(auth_val, b"Bearer ") {
            if let Some(store) = &cfg.tokens {
                let (ws, r) = verify_token(store, crypto, &token, req.now, req.mono);
                if let Ok((user, role)) = r {
                    return (token_writes(ws), Outcome::Next {
                        authority: NamespaceAuthority::Unrestricted, user, role: Some(role),
                    });
                }
            }
        }
    }
    (Vec::new(), Outcome::Next { authority: NamespaceAuthority::Unrestricted, user: anonymous(), role: None })
}

/// A verified API token's identity: the write and admin gates, then pass.
fn token_identity(mut writes: Vec<Write>, client_ip: Option<IpAddr>, method: HttpMethod, is_admin: bool,
                  user: Vec<u8>, role: Role) -> (Vec<Write>, Outcome) {
    record_success(&mut writes, client_ip);
    if is_write_method(method) && !role.can_write() {
        return (writes, Outcome::Deny(Deny::ReadOnlyToken));
    }
    if is_admin && !role.can_admin() {
        return (writes, Outcome::Deny(Deny::AdminRequired));
    }
    (writes, Outcome::Next { authority: NamespaceAuthority::Unrestricted, user, role: Some(role) })
}

/// The claims the JWT validator accepted for this token.
fn oidc_claims<'a>(jwt: &'a Option<Jwt>, token: &[u8]) -> Option<&'a Claims> {
    match jwt {
        Some(j) => {
            if bytes_eq(&j.token, token) {
                match &j.claims {
                    Some(c) => Some(c),
                    None => None,
                }
            } else {
                None
            }
        }
        None => None,
    }
}

/// The Bearer branch: an API token, then OIDC.
fn bearer(cfg: &Config, crypto: &Crypto, failures: &[FailureEntry], jwt: &Option<Jwt>, req: &Request, token: &[u8],
          client_ip: Option<IpAddr>, is_admin: bool) -> (Vec<Write>, Outcome) {
    let mut writes = Vec::new();
    if let Some(store) = &cfg.tokens {
        let (ws, r) = verify_token(store, crypto, token, req.now, req.mono);
        writes = token_writes(ws);
        match r {
            Ok((user, role)) => return token_identity(writes, client_ip, req.method, is_admin, user, role),
            Err(TokenError::Storage) => return (writes, Outcome::Deny(Deny::TokenStoreUnavailable)),
            Err(_) => {}
        }
    }
    if let Some((provider, active)) = &cfg.oidc {
        if *active {
            // `validate_token`: the JWT checks are trusted, the claims are ours.
            let claims = oidc_claims(jwt, token);
            if let Some(c) = claims {
                if let Ok(identity) = validate_claims(provider, c) {
                    record_success(&mut writes, client_ip);
                    if is_write_method(req.method) && !identity.role.can_write() {
                        return (writes, Outcome::Deny(Deny::ReadOnlyOidc));
                    }
                    if is_admin && !identity.role.can_admin() {
                        return (writes, Outcome::Deny(Deny::AdminRequired));
                    }
                    let authority = from_oidc_scopes(
                        &identity.namespace_scope,
                        &identity.rule_namespace_scope,
                        identity.namespace_scope_enforcement,
                    );
                    return (writes, Outcome::Next { authority, user: identity.subject, role: Some(identity.role) });
                }
            }
        }
    }
    if let Some(ip) = client_ip {
        writes.push(Write::PutFailures(after_failure(failures, ip, req.mono)));
    }
    (writes, Outcome::Deny(Deny::InvalidOrExpiredToken))
}

/// The Basic branch: htpasswd, then an API token as the password.
fn basic(cfg: &Config, crypto: &Crypto, failures: &[FailureEntry], req: &Request, auth_header: &[u8],
         client_ip: Option<IpAddr>, is_admin: bool) -> (Vec<Write>, Outcome) {
    let mut writes = Vec::new();
    if !starts_with(auth_header, b"Basic ") {
        return (writes, Outcome::Deny(Deny::BasicOrBearerRequired));
    }
    let users = match &cfg.htpasswd {
        Some(u) => u,
        None => return (writes, Outcome::Deny(Deny::BasicNotConfigured)),
    };
    let encoded = match strip_prefix(auth_header, b"Basic ") {
        Some(e) => e,
        None => return (writes, Outcome::Deny(Deny::BasicOrBearerRequired)),
    };
    let decoded = match crypto.base64_decode(&encoded) {
        Some(d) => d,
        None => return (writes, Outcome::Deny(Deny::InvalidCredentialsEncoding)),
    };
    if !crypto.is_utf8(&decoded) {
        return (writes, Outcome::Deny(Deny::InvalidCredentialsEncoding));
    }
    let (username, password) = match split_once_colon(&decoded) {
        Some(p) => p,
        None => return (writes, Outcome::Deny(Deny::InvalidCredentialsFormat)),
    };
    if !authenticate(users, crypto, &username, &password) {
        if let Some(store) = &cfg.tokens {
            let (ws, r) = verify_token(store, crypto, &password, req.now, req.mono);
            writes = token_writes(ws);
            match r {
                Err(TokenError::Storage) => return (writes, Outcome::Deny(Deny::TokenStoreUnavailable)),
                Ok((token_user, role)) =>
                    return token_identity(writes, client_ip, req.method, is_admin, token_user, role),
                Err(_) => {}
            }
        }
        if let Some(ip) = client_ip {
            writes.push(Write::PutFailures(after_failure(failures, ip, req.mono)));
        }
        return (writes, Outcome::Deny(Deny::InvalidUsernameOrPassword));
    }
    record_success(&mut writes, client_ip);
    if is_admin {
        return (writes, Outcome::Deny(Deny::AdminRequired));
    }
    (writes, Outcome::Next { authority: NamespaceAuthority::Unrestricted, user: username, role: Some(Role::Write) })
}

/// `auth_middleware`.
pub fn auth_middleware(cfg: &Config, failures: &[FailureEntry], crypto: &Crypto, jwt: &Option<Jwt>,
                       req: &Request) -> (Vec<Write>, Outcome) {
    if !cfg.enabled {
        return (Vec::new(), Outcome::Next { authority: NamespaceAuthority::Unrestricted, user: anonymous(), role: None });
    }
    let path = &req.path;
    let open = is_public_path(path)
        || (is_web_surface(path) && (cfg.anonymous_read || cfg.public_web_ui))
        || (bytes_eq(path, b"/metrics") && cfg.public_metrics);
    if open {
        return open_path(cfg, crypto, req);
    }
    if (is_web_surface(path) || bytes_eq(path, b"/metrics")) && !req.has_auth_header {
        return (Vec::new(), Outcome::Deny(Deny::WebChallenge));
    }

    let is_docker = is_docker_path(path);
    let is_docker_catalog = bytes_eq(path, b"/v2/_catalog");
    let is_token_management = starts_with(path, b"/ui/tokens") || starts_with(path, b"/api/ui/tokens");
    let is_whoami = ends_with(path, b"/-/whoami");
    let is_admin = is_admin_path(path);
    let is_read_method = match req.method {
        HttpMethod::Get | HttpMethod::Head => true,
        _ => false,
    };
    let is_npm_audit = req.method == HttpMethod::Post
        && (bytes_eq(path, b"/npm/-/npm/v1/security/advisories/bulk")
            || bytes_eq(path, b"/npm/-/npm/v1/security/audits/quick"));

    if cfg.anonymous_read && (is_read_method || is_npm_audit) && !is_docker && !is_token_management
        && !is_whoami && !is_admin {
        return (Vec::new(), Outcome::Next {
            authority: NamespaceAuthority::Unrestricted, user: anonymous(), role: Some(Role::Read),
        });
    }
    if cfg.docker_anon_pull && is_read_method && is_docker && !is_docker_catalog && !req.has_auth_header {
        return (Vec::new(), Outcome::Next {
            authority: NamespaceAuthority::Unrestricted, user: anonymous(), role: Some(Role::Read),
        });
    }

    let client_ip = match req.peer {
        Some(peer) => Some(resolve_client_ip(peer, req.xff, req.x_real_ip, &cfg.trusted_proxies)),
        None => None,
    };
    if let Some(ip) = client_ip {
        if let Some(retry_after) = cfg.tracker.check_blocked(failures, ip, req.mono) {
            return (Vec::new(), Outcome::Deny(Deny::TooManyRequests(retry_after)));
        }
    }
    let auth_header = match &req.auth_header {
        Some(h) => h,
        None => return (Vec::new(), Outcome::Deny(Deny::AuthenticationRequired)),
    };
    if let Some(token) = strip_prefix(auth_header, b"Bearer ") {
        return bearer(cfg, crypto, failures, jwt, req, &token, client_ip, is_admin);
    }
    basic(cfg, crypto, failures, req, auth_header, client_ip, is_admin)
}
