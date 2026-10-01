//! The domain types (`domain/services/authorization.rs`) and the rows the
//! ported code reads. UUIDs are `u64`.

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Subject {
    User(u64),
    Group(u64),
    Token(u64),
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Resource {
    Folder(u64),
    File(u64),
    Drive(u64),
    Calendar(u64),
    AddressBook(u64),
    Playlist(u64),
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Permission {
    Read,
    Create,
    Share,
    Comment,
    Delete,
    Update,
    Manage,
}

/// `Role`, listed in `storage.grant_role`'s order: `MIN(role)` is the
/// strongest.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Role {
    Owner,
    Editor,
    Contributor,
    Commenter,
    Viewer,
}

/// `storage.role_grants`; `expires_at` in seconds.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Grant {
    pub id: u64,
    pub subject: Subject,
    pub resource: Resource,
    pub role: Role,
    pub granted_by: u64,
    pub expires_at: Option<i64>,
}

/// `auth.users`: the columns the engine reads.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct User {
    pub id: u64,
    pub is_external: bool,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Member {
    User(u64),
    Group(u64),
}

/// `auth.subject_group_members`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Membership {
    pub group_id: u64,
    pub member: Member,
}

/// `DrivePolicies`, the effective bag (`storage.drives_effective`), already
/// decoded; the knobs the ported code reads.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct DrivePolicies {
    pub read_only: bool,
    pub forbid_sharing: bool,
    pub forbid_external_sharing: bool,
    pub forbid_public_links: bool,
    pub forbid_owner_role_change: bool,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum DriveKind {
    Personal,
    Shared,
}

/// `storage.drives`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Drive {
    pub id: u64,
    pub kind: DriveKind,
    pub policies: DrivePolicies,
}

/// `storage.folders`: `lpath` is the ltree of folder ids from the root.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Folder {
    pub id: u64,
    pub drive_id: u64,
    pub lpath: Vec<u64>,
}

/// `storage.files`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct File {
    pub id: u64,
    pub drive_id: u64,
    pub folder_id: Option<u64>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Db {
    pub users: Vec<User>,
    pub memberships: Vec<Membership>,
    pub grants: Vec<Grant>,
    pub drives: Vec<Drive>,
    pub folders: Vec<Folder>,
    pub files: Vec<File>,
}

/// `DomainError`'s kind, for the paths the ported code takes.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ErrorKind {
    NotFound,
    AccessDenied,
    InvalidInput,
    OperationNotSupported,
    Internal,
}
