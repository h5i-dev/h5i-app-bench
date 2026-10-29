//! Pure subject-group namespace and virtual-group mutation policy.
use crate::session::Timestamp;
pub const INTERNAL_GROUP_ID: u128 = 1;
pub const MAX_GROUP_DEPTH: u8 = 8;
const MAX_NAME_LEN: usize = 64;
pub struct SubjectGroup {
    pub id: u128,
    pub name: Vec<u8>,
    pub description: Option<Vec<u8>>,
    pub is_virtual: bool,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
}
#[derive(Clone, Copy)]
pub enum GroupMember { User(u128), Group(u128) }
#[derive(Clone, Copy)]
pub enum NameError { Empty, TooLong, InvalidStart, InvalidCharacter }
fn alphanumeric(b: u8) -> bool {
    (b >= b'a' && b <= b'z') || (b >= b'A' && b <= b'Z') || (b >= b'0' && b <= b'9')
}
fn name_byte(b: u8) -> bool {
    alphanumeric(b) || b == b'.' || b == b'-' || b == b'_'
}
fn all_name(raw: &[u8]) -> bool {
    let mut i = 0;
    while i < raw.len() {
        if !name_byte(raw[i]) { return false; }
        i += 1;
    }
    true
}
/// Upstream `SubjectGroup::validate_name`; diagnostic strings are constructed by the shell.
pub fn validate_name(raw: &[u8]) -> Result<(), NameError> {
    if raw.len() == 0 { return Err(NameError::Empty); }
    if raw.len() > MAX_NAME_LEN { return Err(NameError::TooLong); }
    if !alphanumeric(raw[0]) { return Err(NameError::InvalidStart); }
    if !all_name(raw) { return Err(NameError::InvalidCharacter); }
    Ok(())
}
pub fn is_immutable(group: &SubjectGroup) -> bool { group.is_virtual }
