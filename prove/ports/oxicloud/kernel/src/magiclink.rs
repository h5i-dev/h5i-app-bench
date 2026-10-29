//! Pure magic-link row state, discriminators, and explicit-time redemption policy.
use crate::bytes;
use crate::session::Timestamp;
#[derive(Clone, Copy)]
pub enum MagicLinkResourceKind { File, Folder }
#[derive(Clone, Copy)]
pub enum MagicLinkStatus { Pending, Used, Expired }
pub fn resource_bytes(value: MagicLinkResourceKind) -> Vec<u8> {
    match value {
        MagicLinkResourceKind::File => bytes::copy(b"file"),
        MagicLinkResourceKind::Folder => bytes::copy(b"folder"),
    }
}
pub fn resource_parse(raw: &[u8]) -> Option<MagicLinkResourceKind> {
    if bytes::equal(raw, b"file") { return Some(MagicLinkResourceKind::File); }
    if bytes::equal(raw, b"folder") { return Some(MagicLinkResourceKind::Folder); }
    None
}
pub fn status_bytes(value: MagicLinkStatus) -> Vec<u8> {
    match value {
        MagicLinkStatus::Pending => bytes::copy(b"pending"),
        MagicLinkStatus::Used => bytes::copy(b"used"),
        MagicLinkStatus::Expired => bytes::copy(b"expired"),
    }
}
pub fn status_parse(raw: &[u8]) -> Option<MagicLinkStatus> {
    if bytes::equal(raw, b"pending") { return Some(MagicLinkStatus::Pending); }
    if bytes::equal(raw, b"used") { return Some(MagicLinkStatus::Used); }
    if bytes::equal(raw, b"expired") { return Some(MagicLinkStatus::Expired); }
    None
}
pub struct MagicLinkToken {
    pub id: u128,
    pub token: Vec<u8>,
    pub user_id: u128,
    pub status: MagicLinkStatus,
    pub issued_at: Timestamp,
    pub expires_at: Timestamp,
    pub used_at: Option<Timestamp>,
    pub resource_kind: Option<MagicLinkResourceKind>,
    pub resource_id: Option<u128>,
    pub request_challenge: Option<Vec<u8>>,
}
pub fn from_raw(id: u128, token: Vec<u8>, user_id: u128, status: MagicLinkStatus, issued_at: Timestamp, expires_at: Timestamp, used_at: Option<Timestamp>, resource_kind: Option<MagicLinkResourceKind>, resource_id: Option<u128>, request_challenge: Option<Vec<u8>>) -> MagicLinkToken {
    MagicLinkToken { id, token, user_id, status, issued_at, expires_at, used_at, resource_kind, resource_id, request_challenge }
}
pub fn id(s: &MagicLinkToken) -> u128 { s.id }
pub fn token(s: &MagicLinkToken) -> &Vec<u8> { &s.token }
pub fn user_id(s: &MagicLinkToken) -> u128 { s.user_id }
pub fn status(s: &MagicLinkToken) -> MagicLinkStatus { s.status }
pub fn issued_at(s: &MagicLinkToken) -> Timestamp { s.issued_at }
pub fn expires_at(s: &MagicLinkToken) -> Timestamp { s.expires_at }
pub fn used_at(s: &MagicLinkToken) -> Option<Timestamp> { s.used_at }
pub fn resource_kind(s: &MagicLinkToken) -> Option<MagicLinkResourceKind> { s.resource_kind }
pub fn resource_id(s: &MagicLinkToken) -> Option<u128> { s.resource_id }
pub fn request_challenge(s: &MagicLinkToken) -> &Option<Vec<u8>> { &s.request_challenge }
/// Upstream clock read is supplied by the shell once for the decision.
pub fn is_expired(s: &MagicLinkToken, now: Timestamp) -> bool {
    now.seconds > s.expires_at.seconds ||
        (now.seconds == s.expires_at.seconds && now.nanoseconds > s.expires_at.nanoseconds)
}
pub fn is_redeemable(s: &MagicLinkToken, now: Timestamp) -> bool {
    match s.status {
        MagicLinkStatus::Pending => !is_expired(s, now),
        _ => false,
    }
}
