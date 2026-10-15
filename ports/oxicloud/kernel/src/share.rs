//! Pure sharing state from domain/entities/share.rs.
#[derive(Clone, Copy)]
pub enum ShareItemType { File, Folder }

pub struct Share {
    pub id: u128,
    pub item_id: Vec<u8>,
    pub item_name: Option<Vec<u8>>,
    pub item_type: ShareItemType,
    pub token: Vec<u8>,
    pub password_hash: Option<Vec<u8>>,
    pub expires_at: Option<u64>,
    pub created_at: u64,
    pub created_by: u128,
    pub access_count: u64,
}

/// Upstream `Share::from_raw`.
pub fn from_raw(
    id: u128,
    item_id: Vec<u8>,
    item_name: Option<Vec<u8>>,
    item_type: ShareItemType,
    token: Vec<u8>,
    password_hash: Option<Vec<u8>>,
    expires_at: Option<u64>,
    created_at: u64,
    created_by: u128,
    access_count: u64,
) -> Share {
    Share { id, item_id, item_name, item_type, token, password_hash, expires_at, created_at, created_by, access_count }
}
/// Upstream `Share::with_password`.
pub fn with_password(mut s: Share, hash: Option<Vec<u8>>) -> Share {
    s.password_hash = hash;
    s
}
/// Upstream `Share::with_token`.
pub fn with_token(mut s: Share, token: Vec<u8>) -> Share {
    s.token = token;
    s
}
/// Upstream `Share::increment_access_count`.
pub fn increment_access_count(mut s: Share) -> Share {
    s.access_count += 1;
    s
}
/// Upstream `Share::has_password`.
pub fn has_password(s: &Share) -> bool {
    match s.password_hash { Some(_) => true, None => false }
}

/// Upstream `Share::id`.
pub fn id(s: &Share) -> u128 { s.id }

/// Upstream `Share::item_id`.
pub fn item_id(s: &Share) -> &Vec<u8> { &s.item_id }

/// Upstream `Share::item_name`.
pub fn item_name(s: &Share) -> &Option<Vec<u8>> { &s.item_name }

/// Upstream `Share::item_type`.
pub fn item_type(s: &Share) -> &ShareItemType { &s.item_type }

/// Upstream `Share::token`.
pub fn token(s: &Share) -> &Vec<u8> { &s.token }

/// Upstream `Share::password_hash`.
pub fn password_hash(s: &Share) -> &Option<Vec<u8>> { &s.password_hash }

/// Upstream `Share::expires_at`.
pub fn expires_at(s: &Share) -> Option<u64> { s.expires_at }

/// Upstream `Share::created_at`.
pub fn created_at(s: &Share) -> u64 { s.created_at }

/// Upstream `Share::created_by`.
pub fn created_by(s: &Share) -> u128 { s.created_by }

/// Upstream `Share::access_count`.
pub fn access_count(s: &Share) -> u64 { s.access_count }
