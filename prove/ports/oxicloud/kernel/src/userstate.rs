//! Complete account snapshots and credential-presence decisions from `domain/entities/user.rs`.
use crate::{bytes, session::Timestamp, userrole::UserRole};
#[derive(Clone, Copy)]
pub enum FederationKind { MagicLink, Ocm, Oidc }
pub fn federation_bytes(kind: FederationKind) -> Vec<u8> {
    match kind {
        FederationKind::MagicLink => bytes::copy(b"magic_link"),
        FederationKind::Ocm => bytes::copy(b"ocm"),
        FederationKind::Oidc => bytes::copy(b"oidc"),
    }
}
pub fn federation_parse(raw: &[u8]) -> Option<FederationKind> {
    if bytes::equal(raw, b"magic_link") { return Some(FederationKind::MagicLink); }
    if bytes::equal(raw, b"ocm") { return Some(FederationKind::Ocm); }
    if bytes::equal(raw, b"oidc") { return Some(FederationKind::Oidc); }
    None
}
pub struct User {
    pub id: u128,
    pub username: Option<Vec<u8>>,
    pub email: Vec<u8>,
    pub password_hash: Option<Vec<u8>>,
    pub role: UserRole,
    pub storage_quota_bytes: i64,
    pub storage_used_bytes: i64,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
    pub last_login_at: Option<Timestamp>,
    pub active: bool,
    pub federation_kind: Option<FederationKind>,
    pub federation_issuer: Option<Vec<u8>>,
    pub federation_subject: Option<Vec<u8>>,
    pub image: Option<Vec<u8>>,
    pub is_external: bool,
    pub given_name: Option<Vec<u8>>,
    pub family_name: Option<Vec<u8>>,
    pub email_verified_at: Option<Timestamp>,
    pub preferred_locale: Option<Vec<u8>>,
    pub notify_on_share: bool,
    pub ui_preferences: Vec<u8>,
}
pub struct UserParts {
    pub id: u128,
    pub username: Option<Vec<u8>>,
    pub email: Vec<u8>,
    pub password_hash: Option<Vec<u8>>,
    pub role: UserRole,
    pub storage_quota_bytes: i64,
    pub storage_used_bytes: i64,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
    pub last_login_at: Option<Timestamp>,
    pub active: bool,
    pub federation_kind: Option<FederationKind>,
    pub federation_issuer: Option<Vec<u8>>,
    pub federation_subject: Option<Vec<u8>>,
    pub image: Option<Vec<u8>>,
    pub is_external: bool,
    pub given_name: Option<Vec<u8>>,
    pub family_name: Option<Vec<u8>>,
    pub email_verified_at: Option<Timestamp>,
    pub preferred_locale: Option<Vec<u8>>,
    pub notify_on_share: bool,
    pub ui_preferences: Vec<u8>,
}
pub fn from_data_full(id: u128, username: Option<Vec<u8>>, email: Vec<u8>, password_hash: Option<Vec<u8>>, role: UserRole, storage_quota_bytes: i64, storage_used_bytes: i64, created_at: Timestamp, updated_at: Timestamp, last_login_at: Option<Timestamp>, active: bool, federation_kind: Option<FederationKind>, federation_issuer: Option<Vec<u8>>, federation_subject: Option<Vec<u8>>, image: Option<Vec<u8>>, is_external: bool, given_name: Option<Vec<u8>>, family_name: Option<Vec<u8>>, email_verified_at: Option<Timestamp>, preferred_locale: Option<Vec<u8>>, notify_on_share: bool, ui_preferences: Vec<u8>) -> User {
    User { id, username, email, password_hash, role, storage_quota_bytes, storage_used_bytes, created_at, updated_at, last_login_at, active, federation_kind, federation_issuer, federation_subject, image, is_external, given_name, family_name, email_verified_at, preferred_locale, notify_on_share, ui_preferences }
}
pub fn from_data(id: u128, username: Option<Vec<u8>>, email: Vec<u8>, password_hash: Option<Vec<u8>>, role: UserRole, storage_quota_bytes: i64, storage_used_bytes: i64, created_at: Timestamp, updated_at: Timestamp, last_login_at: Option<Timestamp>, active: bool) -> User {
    User { id, username, email, password_hash, role, storage_quota_bytes, storage_used_bytes, created_at, updated_at, last_login_at, active, federation_kind: None, federation_issuer: None, federation_subject: None, image: None, is_external: false, given_name: None, family_name: None, email_verified_at: None, preferred_locale: None, notify_on_share: true, ui_preferences: bytes::copy(b"{}") }
}
pub fn into_parts(s: User) -> UserParts {
    UserParts { id: s.id, username: s.username, email: s.email, password_hash: s.password_hash, role: s.role, storage_quota_bytes: s.storage_quota_bytes, storage_used_bytes: s.storage_used_bytes, created_at: s.created_at, updated_at: s.updated_at, last_login_at: s.last_login_at, active: s.active, federation_kind: s.federation_kind, federation_issuer: s.federation_issuer, federation_subject: s.federation_subject, image: s.image, is_external: s.is_external, given_name: s.given_name, family_name: s.family_name, email_verified_at: s.email_verified_at, preferred_locale: s.preferred_locale, notify_on_share: s.notify_on_share, ui_preferences: s.ui_preferences }
}
pub fn id(s: &User) -> u128 { s.id }
pub fn username(s: &User) -> &Option<Vec<u8>> { &s.username }
pub fn email(s: &User) -> &Vec<u8> { &s.email }
pub fn password_hash(s: &User) -> &Option<Vec<u8>> { &s.password_hash }
pub fn role(s: &User) -> UserRole { s.role }
pub fn storage_quota_bytes(s: &User) -> i64 { s.storage_quota_bytes }
pub fn storage_used_bytes(s: &User) -> i64 { s.storage_used_bytes }
pub fn created_at(s: &User) -> Timestamp { s.created_at }
pub fn updated_at(s: &User) -> Timestamp { s.updated_at }
pub fn last_login_at(s: &User) -> Option<Timestamp> { s.last_login_at }
pub fn is_active(s: &User) -> bool { s.active }
pub fn federation_kind(s: &User) -> Option<FederationKind> { s.federation_kind }
pub fn federation_issuer(s: &User) -> &Option<Vec<u8>> { &s.federation_issuer }
pub fn federation_subject(s: &User) -> &Option<Vec<u8>> { &s.federation_subject }
pub fn image(s: &User) -> &Option<Vec<u8>> { &s.image }
pub fn is_external(s: &User) -> bool { s.is_external }
pub fn given_name(s: &User) -> &Option<Vec<u8>> { &s.given_name }
pub fn family_name(s: &User) -> &Option<Vec<u8>> { &s.family_name }
pub fn email_verified_at(s: &User) -> Option<Timestamp> { s.email_verified_at }
pub fn preferred_locale(s: &User) -> &Option<Vec<u8>> { &s.preferred_locale }
pub fn notify_on_share(s: &User) -> bool { s.notify_on_share }
pub fn ui_preferences(s: &User) -> &Vec<u8> { &s.ui_preferences }
pub fn has_password(s: &User) -> bool {
    match &s.password_hash { Some(_) => true, None => false }
}
pub fn is_oidc_user(s: &User) -> bool {
    match &s.federation_issuer { Some(_) => true, None => false }
}
pub fn has_login_credential(s: &User) -> bool {
    has_password(s) || match &s.federation_subject { Some(_) => true, None => false }
}
pub fn is_email_verified(s: &User) -> bool {
    match s.email_verified_at { Some(_) => true, None => false }
}
