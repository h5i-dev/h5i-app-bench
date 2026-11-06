//! Delegated (`o2dt.`) tokens: `config/src/utils/delegation.rs` `verify` and
//! `api/common/src/auth/delegation.rs` `verified_claims`, `check_route`,
//! `path_org`, `in_scope`, `segments_match`, `LinkFacts::{from_rows, admit}`,
//! `validate_delegated` (steps 0-5), `touch_due`. Upstream order is kept.
//!
//! HMAC-SHA256, base64 and JSON decoding are not computed here: the shell
//! fills `VerifyOracle` from the real functions for this token. Database
//! reads are tables the kernel searches by the keys it computes.
use crate::bytes::{bytes_eq, constant_time_eq, contains, split_once, split_slash, starts_with, strip_prefix, suffix};
use crate::tables::{alert_id_literals, assistant_scope, reserved_stream_slots, slack_action_scope};

pub const TOKEN_VERSION: u8 = 1;
/// Clock skew allowed between the minting node and this one, in seconds.
pub const MAX_IAT_SKEW_SECS: i64 = 60;
/// An hour plus that skew; a longer-lived token was not minted by O2.
pub const MAX_LIFETIME_SECS: i64 = 3660;
pub const TOUCH_INTERVAL_MICROS: i64 = 60_000_000;

/// `axum::http::Method`; every extension method is `Other`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Method {
    Get,
    Post,
    Put,
    Delete,
    Head,
    Options,
    Connect,
    Patch,
    Trace,
    Other,
}

/// A route segment pattern. `AlertId` is upstream's `Id(ALERT_ID_LITERALS)`,
/// the only `Id` table.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Seg {
    Lit(Vec<u8>),
    Param,
    Stream,
    AlertId,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ScopeRoute {
    pub v2: bool,
    pub segments: Vec<Seg>,
    pub methods: Vec<Method>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Claims {
    pub v: u8,
    pub sub: Vec<u8>,
    pub org: Vec<u8>,
    pub lid: Vec<u8>,
    pub scope: Vec<u8>,
    pub iat: i64,
    pub exp: i64,
    pub jti: Vec<u8>,
}

/// Which `DelegationError::Malformed` message upstream produces.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Malformed {
    /// "expected o2dt.<claims>.<mac>"
    Shape,
    /// "mac: ..."
    MacEncoding,
    /// "claims: ..." (base64 or JSON)
    ClaimsEncoding,
    IssuedInFuture,
    LifetimeOverAnHour,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum DelegationError {
    Malformed(Malformed),
    BadSignature,
    UnsupportedVersion(u8),
    Expired,
}

/// What `verify` gets from functions the kernel does not compute, for the
/// `<claims>` and `<mac>` parts of this token.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct VerifyOracle {
    /// `BASE64_URL_SAFE_NO_PAD.decode(mac_b64)`.
    pub given_mac: Option<Vec<u8>>,
    /// `mac(&keys.current, claims_b64)`.
    pub mac_current: Vec<u8>,
    /// `mac(previous, claims_b64)` when a previous key is configured.
    pub mac_previous: Option<Vec<u8>>,
    /// The base64 and JSON decoding of `claims_b64`.
    pub claims: Option<Claims>,
}

/// The time and version checks of `verify`, after the signature.
pub fn check_claims(claims: Claims, now: i64) -> Result<Claims, DelegationError> {
    if claims.v != TOKEN_VERSION {
        return Err(DelegationError::UnsupportedVersion(claims.v));
    }
    if claims.exp <= now {
        return Err(DelegationError::Expired);
    }
    if claims.iat > now + MAX_IAT_SKEW_SECS {
        return Err(DelegationError::Malformed(Malformed::IssuedInFuture));
    }
    if claims.exp - claims.iat > MAX_LIFETIME_SECS {
        return Err(DelegationError::Malformed(Malformed::LifetimeOverAnHour));
    }
    Ok(claims)
}

/// `verify(keys, token, now)`.
pub fn verify(token: &[u8], o: &VerifyOracle, now: i64) -> Result<Claims, DelegationError> {
    let rest = match strip_prefix(token, b"o2dt.") {
        None => return Err(DelegationError::Malformed(Malformed::Shape)),
        Some(rest) => rest,
    };
    match split_once(&rest, b'.') {
        None => return Err(DelegationError::Malformed(Malformed::Shape)),
        Some(_) => {}
    }
    let given = match &o.given_mac {
        None => return Err(DelegationError::Malformed(Malformed::MacEncoding)),
        Some(given) => given,
    };
    let current_ok = constant_time_eq(&o.mac_current, given);
    let previous_ok = match &o.mac_previous {
        None => false,
        Some(m) => constant_time_eq(m, given),
    };
    if !(current_ok || previous_ok) {
        return Err(DelegationError::BadSignature);
    }
    match &o.claims {
        None => Err(DelegationError::Malformed(Malformed::ClaimsEncoding)),
        Some(claims) => check_claims(claims.clone(), now),
    }
}

/// Why a delegated token was forbidden (upstream logs it; every one is 403).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Forbidden {
    UnknownScope,
    Proxy,
    NoOrg,
    OtherOrg,
    OutOfScope,
    UnknownLink,
    LinkRevoked,
    InstallationRevoked,
    NotLinkedUser,
    OrgNotConnected,
    NotMember,
    Blocked,
}

/// `AuthError` as the delegated path returns it.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AuthError {
    /// 401.
    Unauthorized,
    /// 403.
    Forbidden(Forbidden),
    /// 503: a store read failed.
    Unavailable,
}

/// `scope_routes(scope)`.
pub fn scope_routes(scope: &[u8]) -> Option<Vec<ScopeRoute>> {
    if bytes_eq(scope, b"assistant") {
        Some(assistant_scope())
    } else if bytes_eq(scope, b"slack_action") {
        Some(slack_action_scope())
    } else {
        None
    }
}

/// `relative_path`: one leading `/` stripped.
pub fn relative_path(path: &[u8]) -> Vec<u8> {
    if starts_with(path, b"/") {
        suffix(path, 1)
    } else {
        suffix(path, 0)
    }
}

/// `path_org(relative)`: the org segment, when it is non-empty and followed
/// by more of the path.
pub fn path_org(relative: &[u8]) -> Option<Vec<u8>> {
    let cols = split_slash(relative);
    let (org_idx, rest_len) = if cols.len() >= 2 && bytes_eq(&cols[0], b"v2") {
        (1, cols.len() - 2)
    } else {
        (0, cols.len() - 1)
    };
    if cols[org_idx].len() > 0 && rest_len > 0 {
        Some(cols[org_idx].clone())
    } else {
        None
    }
}

fn method_in(methods: &[Method], m: Method) -> bool {
    let mut i = 0;
    while i < methods.len() {
        if methods[i] == m {
            return true;
        }
        i += 1;
    }
    false
}

/// One `segments_match` slot.
pub fn seg_matches(pat: &Seg, col: &[u8]) -> bool {
    match pat {
        Seg::Lit(lit) => bytes_eq(col, lit),
        Seg::Param => col.len() > 0,
        Seg::Stream => col.len() > 0 && !contains(&reserved_stream_slots(), col),
        Seg::AlertId => col.len() > 0 && !contains(&alert_id_literals(), col),
    }
}

/// `segments_match(patterns, columns)`.
pub fn segments_match(patterns: &[Seg], columns: &[Vec<u8>]) -> bool {
    if patterns.len() != columns.len() {
        return false;
    }
    let mut i = 0;
    while i < patterns.len() {
        if !seg_matches(&patterns[i], &columns[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// `in_scope(routes, method, path)`.
pub fn in_scope(routes: &[ScopeRoute], method: Method, path: &[u8]) -> bool {
    if method == Method::Delete {
        return false;
    }
    let (is_v2, rest) = match strip_prefix(path, b"v2/") {
        Some(rest) => (true, rest),
        None => (false, suffix(path, 0)),
    };
    let columns = split_slash(&rest);
    let mut i = 0;
    while i < routes.len() {
        if routes[i].v2 == is_v2
            && method_in(&routes[i].methods, method)
            && segments_match(&routes[i].segments, &columns)
        {
            return true;
        }
        i += 1;
    }
    false
}

/// `in_assistant_scope(method, path)`.
pub fn in_assistant_scope(method: Method, path: &[u8]) -> bool {
    in_scope(&assistant_scope(), method, path)
}

/// `in_slack_action_scope(method, path)`.
pub fn in_slack_action_scope(method: Method, path: &[u8]) -> bool {
    in_scope(&slack_action_scope(), method, path)
}

/// `check_route(path, path_prefix, method, claims)`.
pub fn check_route(path: &[u8], path_prefix: &[u8], method: Method, claims: &Claims) -> Result<(), AuthError> {
    if bytes_eq(path_prefix, b"/proxy/") {
        return Err(AuthError::Forbidden(Forbidden::Proxy));
    }
    let routes = match scope_routes(&claims.scope) {
        None => return Err(AuthError::Forbidden(Forbidden::UnknownScope)),
        Some(routes) => routes,
    };
    let relative = relative_path(path);
    match path_org(&relative) {
        None => Err(AuthError::Forbidden(Forbidden::NoOrg)),
        Some(org) => {
            if !bytes_eq(&org, &claims.org) {
                Err(AuthError::Forbidden(Forbidden::OtherOrg))
            } else if !in_scope(&routes, method, &relative) {
                Err(AuthError::Forbidden(Forbidden::OutOfScope))
            } else {
                Ok(())
            }
        }
    }
}

/// `verified_claims(token, slack_on, keys, now, disabled_reason)`.
/// `keys_ok` is whether `signing_keys()` succeeded; `disabled_orgs` lists
/// the orgs for which `disabled_reason` is `Some`.
pub fn verified_claims(
    token: &[u8],
    slack_on: bool,
    keys_ok: bool,
    o: &VerifyOracle,
    now: i64,
    disabled_orgs: &[Vec<u8>],
) -> Result<Claims, AuthError> {
    if !slack_on {
        return Err(AuthError::Unauthorized);
    }
    if !keys_ok {
        return Err(AuthError::Unauthorized);
    }
    let claims = match verify(token, o, now) {
        Err(_) => return Err(AuthError::Unauthorized),
        Ok(c) => c,
    };
    if contains(disabled_orgs, &claims.org) {
        return Err(AuthError::Unauthorized);
    }
    match scope_routes(&claims.scope) {
        None => Err(AuthError::Forbidden(Forbidden::UnknownScope)),
        Some(_) => Ok(claims),
    }
}

/// An `external_identity_links` row.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct LinkRow {
    pub id: Vec<u8>,
    pub installation_id: Vec<u8>,
    pub user_email: Vec<u8>,
    pub revoked: bool,
    pub last_used_at: i64,
}

/// A `slack_installations` row and `served_org_ids(installation)`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Installation {
    pub id: Vec<u8>,
    pub revoked: bool,
    pub served_orgs: Vec<Vec<u8>>,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Refusal {
    UnknownLink,
    LinkRevoked,
    InstallationRevoked,
}

/// `LinkFacts` without its load instant.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct LinkFacts {
    pub installation_id: Vec<u8>,
    pub user_email: Vec<u8>,
    pub refusal: Option<Refusal>,
    pub orgs: Vec<Vec<u8>>,
    pub last_used_at: i64,
}

/// `LinkFacts::refused`.
pub fn refused(reason: Refusal) -> LinkFacts {
    LinkFacts {
        installation_id: Vec::new(),
        user_email: Vec::new(),
        refusal: Some(reason),
        orgs: Vec::new(),
        last_used_at: 0,
    }
}

/// `LinkFacts::from_rows(link, installation, orgs)`.
pub fn from_rows(link: Option<LinkRow>, installation: Option<Installation>, orgs: Vec<Vec<u8>>) -> LinkFacts {
    let link = match link {
        None => return refused(Refusal::UnknownLink),
        Some(link) => link,
    };
    let refusal = if link.revoked {
        Some(Refusal::LinkRevoked)
    } else {
        match installation {
            None => Some(Refusal::InstallationRevoked),
            Some(i) => {
                if i.revoked {
                    Some(Refusal::InstallationRevoked)
                } else {
                    None
                }
            }
        }
    };
    LinkFacts {
        installation_id: link.installation_id,
        user_email: link.user_email,
        refusal,
        orgs,
        last_used_at: link.last_used_at,
    }
}

/// `LinkFacts::admit(claims)`.
pub fn admit(facts: &LinkFacts, claims: &Claims) -> Result<(), AuthError> {
    match facts.refusal {
        Some(Refusal::UnknownLink) => return Err(AuthError::Forbidden(Forbidden::UnknownLink)),
        Some(Refusal::LinkRevoked) => return Err(AuthError::Forbidden(Forbidden::LinkRevoked)),
        Some(Refusal::InstallationRevoked) => {
            return Err(AuthError::Forbidden(Forbidden::InstallationRevoked));
        }
        None => {}
    }
    if !bytes_eq(&facts.user_email, &claims.sub) {
        return Err(AuthError::Forbidden(Forbidden::NotLinkedUser));
    }
    if !contains(&facts.orgs, &claims.org) {
        return Err(AuthError::Forbidden(Forbidden::OrgNotConnected));
    }
    Ok(())
}

/// `touch_due(last_used_at, now)`.
pub fn touch_due(last_used_at: i64, now: i64) -> bool {
    now - last_used_at >= TOUCH_INTERVAL_MICROS
}

/// `config::meta::user::UserRole`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum UserRole {
    Root,
    Admin,
    Editor,
    Viewer,
    User,
    ServiceAccount,
    SreAgent,
}

/// What `get_user(Some(org), email)` returns for one membership.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Member {
    pub org: Vec<u8>,
    pub email: Vec<u8>,
    pub role: UserRole,
    pub is_external: bool,
}

/// The stores and configuration `validate_delegated` reads.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct DelegationEnv {
    pub slack_on: bool,
    pub keys_ok: bool,
    pub disabled_orgs: Vec<Vec<u8>>,
    /// Whether the link store reads succeed (otherwise 503).
    pub store_ok: bool,
    pub links: Vec<LinkRow>,
    pub installations: Vec<Installation>,
    pub members: Vec<Member>,
    /// Emails `domain_management::evaluate_cached` denies.
    pub denied: Vec<Vec<u8>>,
}

/// `DelegatedCaller` plus the `AuthValidationResult` fields it comes with.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Delegated {
    pub user_email: Vec<u8>,
    pub user_role: UserRole,
    pub is_internal_user: bool,
    pub link_id: Vec<u8>,
    pub installation_id: Vec<u8>,
    pub org: Vec<u8>,
    pub jti: Vec<u8>,
    pub scope: Vec<u8>,
}

fn find_link(links: &[LinkRow], id: &[u8]) -> Option<LinkRow> {
    let mut i = 0;
    while i < links.len() {
        if bytes_eq(&links[i].id, id) {
            return Some(links[i].clone());
        }
        i += 1;
    }
    None
}

fn find_installation(insts: &[Installation], id: &[u8]) -> Option<Installation> {
    let mut i = 0;
    while i < insts.len() {
        if bytes_eq(&insts[i].id, id) {
            return Some(insts[i].clone());
        }
        i += 1;
    }
    None
}

/// `get_user(Some(org), email)`.
pub fn find_member(members: &[Member], org: &[u8], email: &[u8]) -> Option<Member> {
    let mut i = 0;
    while i < members.len() {
        if bytes_eq(&members[i].org, org) && bytes_eq(&members[i].email, email) {
            return Some(members[i].clone());
        }
        i += 1;
    }
    None
}

/// `link_facts(lid)` on a cache miss: the link, its installation, the orgs it serves.
pub fn load_link_facts(env: &DelegationEnv, lid: &[u8]) -> LinkFacts {
    match find_link(&env.links, lid) {
        None => from_rows(None, None, Vec::new()),
        Some(link) => {
            let installation = find_installation(&env.installations, &link.installation_id);
            let orgs = match &installation {
                Some(i) => i.served_orgs.clone(),
                None => Vec::new(),
            };
            from_rows(Some(link), installation, orgs)
        }
    }
}

/// `validate_delegated(token, path, path_prefix, method)`, steps 0-5.
pub fn validate_delegated(
    env: &DelegationEnv,
    o: &VerifyOracle,
    now: i64,
    token: &[u8],
    path: &[u8],
    path_prefix: &[u8],
    method: Method,
) -> Result<Delegated, AuthError> {
    let claims = match verified_claims(token, env.slack_on, env.keys_ok, o, now, &env.disabled_orgs) {
        Err(e) => return Err(e),
        Ok(c) => c,
    };
    match check_route(path, path_prefix, method, &claims) {
        Err(e) => return Err(e),
        Ok(()) => {}
    }
    if !env.store_ok {
        return Err(AuthError::Unavailable);
    }
    let facts = load_link_facts(env, &claims.lid);
    match admit(&facts, &claims) {
        Err(e) => return Err(e),
        Ok(()) => {}
    }
    let user = match find_member(&env.members, &claims.org, &claims.sub) {
        None => return Err(AuthError::Forbidden(Forbidden::NotMember)),
        Some(u) => u,
    };
    if user.is_external && contains(&env.denied, &user.email) {
        return Err(AuthError::Forbidden(Forbidden::Blocked));
    }
    Ok(Delegated {
        user_email: claims.sub,
        user_role: user.role,
        is_internal_user: !user.is_external,
        link_id: claims.lid,
        installation_id: facts.installation_id,
        org: claims.org,
        jti: claims.jti,
        scope: claims.scope,
    })
}
