//! Pure session state from domain/entities/session.rs.
use crate::bytes;

/// UTC timestamp components, transported without consulting the clock.
#[derive(Clone, Copy)]
pub struct Timestamp { pub seconds: i64, pub nanoseconds: u32 }

#[derive(Clone, Copy)]
pub enum SessionOrigin { Password, Opaque, MagicLink, Oidc, Device, Unknown }

/// Upstream `SessionOrigin::as_str`.
pub fn origin_bytes(origin: SessionOrigin) -> Vec<u8> {
    match origin {
        SessionOrigin::Password => bytes::copy(b"password"),
        SessionOrigin::Opaque => bytes::copy(b"opaque"),
        SessionOrigin::MagicLink => bytes::copy(b"magic_link"),
        SessionOrigin::Oidc => bytes::copy(b"oidc"),
        SessionOrigin::Device => bytes::copy(b"device"),
        SessionOrigin::Unknown => bytes::copy(b"unknown"),
    }
}
/// Upstream `SessionOrigin::from_wire`.
pub fn origin_from_wire(raw: &[u8]) -> SessionOrigin {
    if bytes::equal(raw, b"password") { return SessionOrigin::Password; }
    if bytes::equal(raw, b"opaque") { return SessionOrigin::Opaque; }
    if bytes::equal(raw, b"magic_link") { return SessionOrigin::MagicLink; }
    if bytes::equal(raw, b"oidc") { return SessionOrigin::Oidc; }
    if bytes::equal(raw, b"device") { return SessionOrigin::Device; }
    SessionOrigin::Unknown
}

pub struct Session {
    pub id: u128,
    pub user_id: u128,
    pub refresh_token: Vec<u8>,
    pub expires_at: Timestamp,
    pub ip_address: Option<Vec<u8>>,
    pub user_agent: Option<Vec<u8>>,
    pub created_at: Timestamp,
    pub revoked: bool,
    pub family_id: u128,
    pub oidc_id_token: Option<Vec<u8>>,
    pub oidc_sid: Option<Vec<u8>>,
    pub dpop_jkt: Option<Vec<u8>>,
    pub origin: SessionOrigin,
    pub last_seen_at: Timestamp,
}

/// Upstream `Session::from_raw`.
pub fn from_raw(
    id: u128,
    user_id: u128,
    refresh_token: Vec<u8>,
    expires_at: Timestamp,
    ip_address: Option<Vec<u8>>,
    user_agent: Option<Vec<u8>>,
    created_at: Timestamp,
    revoked: bool,
    family_id: u128,
    oidc_id_token: Option<Vec<u8>>,
    oidc_sid: Option<Vec<u8>>,
    dpop_jkt: Option<Vec<u8>>,
    origin: SessionOrigin,
    last_seen_at: Timestamp,
) -> Session {
    Session { id, user_id, refresh_token, expires_at, ip_address, user_agent, created_at, revoked, family_id, oidc_id_token, oidc_sid, dpop_jkt, origin, last_seen_at }
}

/// Upstream `Session::with_dpop_jkt`.
pub fn with_dpop_jkt(mut s: Session, jkt: Vec<u8>) -> Session {
    match s.dpop_jkt { Some(_) => panic!("session key already bound"), None => () }
    s.dpop_jkt = Some(jkt);
    s
}
/// Upstream `Session::with_oidc_id_token`.
pub fn with_oidc_id_token(mut s: Session, token: Vec<u8>) -> Session {
    s.oidc_id_token = Some(token);
    s
}
/// Upstream `Session::with_oidc_sid`.
pub fn with_oidc_sid(mut s: Session, sid: Vec<u8>) -> Session {
    s.oidc_sid = Some(sid);
    s
}
/// Upstream `Session::revoke`.
pub fn revoke(s: &mut Session) { s.revoked = true; }

/// Upstream `Session::id`.
pub fn id(s: &Session) -> u128 { s.id }

/// Upstream `Session::user_id`.
pub fn user_id(s: &Session) -> u128 { s.user_id }

/// Upstream `Session::refresh_token`.
pub fn refresh_token(s: &Session) -> &Vec<u8> { &s.refresh_token }

/// Upstream `Session::expires_at`.
pub fn expires_at(s: &Session) -> Timestamp { s.expires_at }

/// Upstream `Session::ip_address`.
pub fn ip_address(s: &Session) -> &Option<Vec<u8>> { &s.ip_address }

/// Upstream `Session::user_agent`.
pub fn user_agent(s: &Session) -> &Option<Vec<u8>> { &s.user_agent }

/// Upstream `Session::created_at`.
pub fn created_at(s: &Session) -> Timestamp { s.created_at }

/// Upstream `Session::is_revoked`.
pub fn is_revoked(s: &Session) -> bool { s.revoked }

/// Upstream `Session::family_id`.
pub fn family_id(s: &Session) -> u128 { s.family_id }

/// Upstream `Session::oidc_id_token`.
pub fn oidc_id_token(s: &Session) -> &Option<Vec<u8>> { &s.oidc_id_token }

/// Upstream `Session::oidc_sid`.
pub fn oidc_sid(s: &Session) -> &Option<Vec<u8>> { &s.oidc_sid }

/// Upstream `Session::dpop_jkt`.
pub fn dpop_jkt(s: &Session) -> &Option<Vec<u8>> { &s.dpop_jkt }

/// Upstream `Session::origin`.
pub fn origin(s: &Session) -> SessionOrigin { s.origin }

/// Upstream `Session::last_seen_at`.
pub fn last_seen_at(s: &Session) -> Timestamp { s.last_seen_at }
