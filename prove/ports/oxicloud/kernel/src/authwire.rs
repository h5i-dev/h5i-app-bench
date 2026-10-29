//! Discriminators and principal identity from domain/services/authorization.rs.
use crate::bytes;
use crate::model::{Subject, Resource, Permission, Role};

/// Upstream `Subject::type_str`.
pub fn subject_bytes(value: Subject) -> Vec<u8> {
    match value {
        Subject::User(_) => bytes::copy(b"user"),
        Subject::Group(_) => bytes::copy(b"group"),
        Subject::Token(_) => bytes::copy(b"token"),
    }
}

/// Upstream `Subject::from_parts`.
pub fn subject_parse(raw: &[u8], id: u64) -> Option<Subject> {
    if bytes::equal(raw, b"user") { return Some(Subject::User(id)); }
    if bytes::equal(raw, b"group") { return Some(Subject::Group(id)); }
    if bytes::equal(raw, b"token") { return Some(Subject::Token(id)); }
    None
}

/// Upstream `Subject::id`.
pub fn subject_id(value: Subject) -> u64 {
    match value {
        Subject::User(id) => id,
        Subject::Group(id) => id,
        Subject::Token(id) => id,
    }
}

/// Upstream `Resource::type_str`.
pub fn resource_bytes(value: Resource) -> Vec<u8> {
    match value {
        Resource::Folder(_) => bytes::copy(b"folder"),
        Resource::File(_) => bytes::copy(b"file"),
        Resource::Drive(_) => bytes::copy(b"drive"),
        Resource::Calendar(_) => bytes::copy(b"calendar"),
        Resource::AddressBook(_) => bytes::copy(b"address_book"),
        Resource::Playlist(_) => bytes::copy(b"playlist"),
    }
}

/// Upstream `Resource::from_parts`.
pub fn resource_parse(raw: &[u8], id: u64) -> Option<Resource> {
    if bytes::equal(raw, b"folder") { return Some(Resource::Folder(id)); }
    if bytes::equal(raw, b"file") { return Some(Resource::File(id)); }
    if bytes::equal(raw, b"drive") { return Some(Resource::Drive(id)); }
    if bytes::equal(raw, b"calendar") { return Some(Resource::Calendar(id)); }
    if bytes::equal(raw, b"address_book") { return Some(Resource::AddressBook(id)); }
    if bytes::equal(raw, b"playlist") { return Some(Resource::Playlist(id)); }
    None
}

/// Upstream `Resource::id`.
pub fn resource_id(value: Resource) -> u64 {
    match value {
        Resource::Folder(id) => id,
        Resource::File(id) => id,
        Resource::Drive(id) => id,
        Resource::Calendar(id) => id,
        Resource::AddressBook(id) => id,
        Resource::Playlist(id) => id,
    }
}

/// Upstream `Permission::as_str`.
pub fn permission_bytes(value: Permission) -> Vec<u8> {
    match value {
        Permission::Read => bytes::copy(b"read"),
        Permission::Create => bytes::copy(b"create"),
        Permission::Share => bytes::copy(b"share"),
        Permission::Comment => bytes::copy(b"comment"),
        Permission::Delete => bytes::copy(b"delete"),
        Permission::Update => bytes::copy(b"update"),
        Permission::Manage => bytes::copy(b"manage"),
    }
}

/// Upstream `Permission::parse`.
pub fn permission_parse(raw: &[u8]) -> Option<Permission> {
    if bytes::equal(raw, b"read") { return Some(Permission::Read); }
    if bytes::equal(raw, b"create") { return Some(Permission::Create); }
    if bytes::equal(raw, b"share") { return Some(Permission::Share); }
    if bytes::equal(raw, b"comment") { return Some(Permission::Comment); }
    if bytes::equal(raw, b"delete") { return Some(Permission::Delete); }
    if bytes::equal(raw, b"update") { return Some(Permission::Update); }
    if bytes::equal(raw, b"manage") { return Some(Permission::Manage); }
    None
}

/// Upstream `Permission::ALL`, in its stable order.
pub fn permission_all() -> Vec<Permission> {
    let mut out = Vec::new();
    out.push(Permission::Read);
    out.push(Permission::Create);
    out.push(Permission::Share);
    out.push(Permission::Comment);
    out.push(Permission::Delete);
    out.push(Permission::Update);
    out.push(Permission::Manage);
    out
}

/// Upstream `Role::as_str`.
pub fn role_bytes(value: Role) -> Vec<u8> {
    match value {
        Role::Viewer => bytes::copy(b"viewer"),
        Role::Commenter => bytes::copy(b"commenter"),
        Role::Contributor => bytes::copy(b"contributor"),
        Role::Editor => bytes::copy(b"editor"),
        Role::Owner => bytes::copy(b"owner"),
    }
}

/// Upstream `Role::parse`.
pub fn role_parse(raw: &[u8]) -> Option<Role> {
    if bytes::equal(raw, b"viewer") { return Some(Role::Viewer); }
    if bytes::equal(raw, b"commenter") { return Some(Role::Commenter); }
    if bytes::equal(raw, b"contributor") { return Some(Role::Contributor); }
    if bytes::equal(raw, b"editor") { return Some(Role::Editor); }
    if bytes::equal(raw, b"owner") { return Some(Role::Owner); }
    None
}

/// Upstream `Role::ALL`, in its stable order.
pub fn role_all() -> Vec<Role> {
    let mut out = Vec::new();
    out.push(Role::Viewer);
    out.push(Role::Commenter);
    out.push(Role::Contributor);
    out.push(Role::Editor);
    out.push(Role::Owner);
    out
}

/// Upstream `Subject::user_id`.
pub fn subject_user_id(value: Subject) -> Option<u64> {
    match value {
        Subject::User(id) => Some(id),
        Subject::Group(_) | Subject::Token(_) => None,
    }
}

/// Upstream `Subject::token_id`.
pub fn subject_token_id(value: Subject) -> Option<u64> {
    match value {
        Subject::Token(id) => Some(id),
        Subject::User(_) | Subject::Group(_) => None,
    }
}
