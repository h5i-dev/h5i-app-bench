use uuid::Uuid;
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Subject {
    /// A registered OxiCloud user (`auth.users.id`).
    User(Uuid),
    /// A user group (reserved for future use; no group CRUD in v1).
    Group(Uuid),
    /// An anonymous share token (`storage.shares.id`).
    Token(Uuid),
}
impl Subject {
    /// SQL discriminator string matching the `subject_type` CHECK constraint.
    pub fn type_str(&self) -> &'static str {
        match self {
            Subject::User(_) => "user",
            Subject::Group(_) => "group",
            Subject::Token(_) => "token",
        }
    }

    /// The raw UUID regardless of variant.
    pub fn id(&self) -> Uuid {
        match self {
            Subject::User(id) | Subject::Group(id) | Subject::Token(id) => *id,
        }
    }

    /// The `auth.users.id` behind this subject, if there is one.
    ///
    /// `None` for `Token` (a public-share link) and `Group`, neither of
    /// which has a user row. Use this — never [`Self::id`] — wherever a
    /// value is about to be written to a column with an FK to
    /// `auth.users`, or recorded as "this person did something":
    /// `Subject::id()` would hand back a share id that satisfies neither.
    pub fn user_id(&self) -> Option<Uuid> {
        match self {
            Subject::User(id) => Some(*id),
            Subject::Group(_) | Subject::Token(_) => None,
        }
    }

    /// The `storage.shares.id` behind this subject, if it is a share token.
    ///
    /// Counterpart to [`Self::user_id`]. Binding this as a nullable SQL
    /// parameter lets one query serve both principal kinds: for a user it
    /// is `NULL`, so any `subject_id = $n` comparison against it is `NULL`
    /// — never true — and the existing plan is unchanged.
    pub fn token_id(&self) -> Option<Uuid> {
        match self {
            Subject::Token(id) => Some(*id),
            Subject::User(_) | Subject::Group(_) => None,
        }
    }

    /// Reconstruct from a SQL row's `(subject_type, subject_id)` pair.
    ///
    /// `"external"` is no longer accepted: PR-2 of the external-users
    /// work folded the federated-identity case into `Subject::User(uuid)`
    /// with `auth.users.is_external = TRUE`. The DB CHECK constraint
    /// on `storage.role_grants.subject_type` was narrowed to match.
    pub fn from_parts(subject_type: &str, id: Uuid) -> Option<Self> {
        match subject_type {
            "user" => Some(Subject::User(id)),
            "group" => Some(Subject::Group(id)),
            "token" => Some(Subject::Token(id)),
            _ => None,
        }
    }
}
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Resource {
    Folder(Uuid),
    File(Uuid),
    /// A drive — root scope for a tree of folders/files plus its own
    /// membership and policy bag. Added in D0; membership lives in
    /// `storage.role_grants` (no separate `drive_members` table).
    Drive(Uuid),
    /// A CalDAV calendar. Membership + sharing lives in
    /// `storage.role_grants` with `resource_type='calendar'` —
    /// replaces the pre-Round-3 dedicated `caldav.calendar_shares`
    /// table and the `check_calendar_access` bespoke helper. No
    /// cascade parent (calendars are top-level per user); the engine
    /// resolves directly against `role_grants` on the resource.
    Calendar(Uuid),
    /// A CardDAV address book. Same shape as `Calendar` —
    /// `storage.role_grants` with `resource_type='address_book'`
    /// replaces `carddav.address_book_shares` and the
    /// `check_address_book_access` bespoke helper.
    AddressBook(Uuid),
    /// A music playlist. Same shape as `Calendar`/`AddressBook` —
    /// `storage.role_grants` with `resource_type='playlist'` replaces
    /// the pre-Round-3 dedicated `music.playlist_shares` table and the
    /// bespoke `user_has_access` / `user_can_write` helpers on
    /// `MusicStorageAdapter`.
    Playlist(Uuid),
}
impl Resource {
    pub fn type_str(&self) -> &'static str {
        match self {
            Resource::Folder(_) => "folder",
            Resource::File(_) => "file",
            Resource::Drive(_) => "drive",
            Resource::Calendar(_) => "calendar",
            Resource::AddressBook(_) => "address_book",
            Resource::Playlist(_) => "playlist",
        }
    }

    pub fn id(&self) -> Uuid {
        match self {
            Resource::Folder(id)
            | Resource::File(id)
            | Resource::Drive(id)
            | Resource::Calendar(id)
            | Resource::AddressBook(id)
            | Resource::Playlist(id) => *id,
        }
    }

    pub fn from_parts(resource_type: &str, id: Uuid) -> Option<Self> {
        match resource_type {
            "folder" => Some(Resource::Folder(id)),
            "file" => Some(Resource::File(id)),
            "drive" => Some(Resource::Drive(id)),
            "calendar" => Some(Resource::Calendar(id)),
            "address_book" => Some(Resource::AddressBook(id)),
            "playlist" => Some(Resource::Playlist(id)),
            _ => None,
        }
    }

    /// Parse `(item_type, item_id)` from an API-facing pair of strings
    /// (favorites, recent, batch endpoints all take this shape).
    /// Combines UUID parse + type mapping so callers stay one-line and
    /// error shapes are identical across surfaces. Returns
    /// `DomainError::new(InvalidInput, …)` on malformed input; callers
    /// that need the anti-enum 404 shape do that separately by feeding
    /// the parsed `Resource` into `authz.require(...)`.
    pub fn parse(
        item_type: &str,
        item_id: &str,
    ) -> Result<Self, crate::common::errors::DomainError> {
        use crate::common::errors::{DomainError, ErrorKind};
        let uuid = Uuid::parse_str(item_id).map_err(|_| {
            DomainError::new(
                ErrorKind::InvalidInput,
                "Resource",
                format!("Invalid item UUID '{item_id}'"),
            )
        })?;
        Self::from_parts(item_type, uuid).ok_or_else(|| {
            DomainError::new(
                ErrorKind::InvalidInput,
                "Resource",
                format!("Unsupported item type '{item_type}'"),
            )
        })
    }
}
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Permission {
    /// View resource content / list folder contents.
    Read,
    /// Create child resources inside (only meaningful on folders).
    Create,
    /// Grant permissions to other subjects.
    Share,
    /// Add comments (reserved — comments feature not implemented yet).
    Comment,
    /// Delete the resource.
    Delete,
    /// Modify the resource (rename, move, edit content).
    Update,
    /// Configure the resource's settings, add/remove members, change role
    /// assignments. Used by:
    /// - Drive owners managing drive membership and policies.
    /// - Group owners managing the group itself (Group-as-Resource, future).
    ///
    /// Folder and file resources do not currently surface a `Manage` check;
    /// the permission lives in the enum because the role bundle (`Owner`)
    /// includes it, and the resource types that DO check it (`Drive`,
    /// `Group`) are added in subsequent PRs (see `docs/plan/drive.md`).
    Manage,
}
impl Permission {
    /// Every permission, in a stable order. Used by `Role::expand()` and SQL
    /// `permission = ANY(...)` lookups.
    pub const ALL: [Permission; 7] = [
        Permission::Read,
        Permission::Create,
        Permission::Share,
        Permission::Comment,
        Permission::Delete,
        Permission::Update,
        Permission::Manage,
    ];

    pub fn as_str(&self) -> &'static str {
        match self {
            Permission::Read => "read",
            Permission::Create => "create",
            Permission::Share => "share",
            Permission::Comment => "comment",
            Permission::Delete => "delete",
            Permission::Update => "update",
            Permission::Manage => "manage",
        }
    }

    /// Parse a permission from its SQL discriminator string. Returns None
    /// for unknown values.
    pub fn parse(s: &str) -> Option<Self> {
        match s {
            "read" => Some(Permission::Read),
            "create" => Some(Permission::Create),
            "share" => Some(Permission::Share),
            "comment" => Some(Permission::Comment),
            "delete" => Some(Permission::Delete),
            "update" => Some(Permission::Update),
            "manage" => Some(Permission::Manage),
            _ => None,
        }
    }
}
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Role {
    Viewer,
    Commenter,
    Contributor,
    Editor,
    Owner,
}
impl Role {
    /// Expand the role into its permission bundle. Single source of truth —
    /// any code that needs "does this role include Permission X?" routes
    /// through here (or its inverse, `roles_implying`).
    pub fn expand(self) -> &'static [Permission] {
        match self {
            Role::Viewer => &[Permission::Read],
            Role::Commenter => &[Permission::Read, Permission::Comment],
            Role::Contributor => &[Permission::Read, Permission::Create],
            Role::Editor => &[
                Permission::Read,
                Permission::Comment,
                Permission::Create,
                Permission::Update,
            ],
            Role::Owner => &[
                Permission::Read,
                Permission::Comment,
                Permission::Create,
                Permission::Update,
                Permission::Share,
                Permission::Delete,
                Permission::Manage,
            ],
        }
    }

    /// Lowercase discriminator — matches the SQL `role` ENUM values in
    /// `storage.role_grants` (after the `::text` cast).
    pub fn as_str(self) -> &'static str {
        match self {
            Role::Viewer => "viewer",
            Role::Commenter => "commenter",
            Role::Contributor => "contributor",
            Role::Editor => "editor",
            Role::Owner => "owner",
        }
    }

    /// Parse a role from its SQL discriminator. Returns `None` for unknown
    /// values. The `"admin"` legacy alias is handled by `RoleDto` at the
    /// wire boundary — the database only ever stores the canonical names.
    pub fn parse(s: &str) -> Option<Self> {
        match s {
            "viewer" => Some(Role::Viewer),
            "commenter" => Some(Role::Commenter),
            "contributor" => Some(Role::Contributor),
            "editor" => Some(Role::Editor),
            "owner" => Some(Role::Owner),
            _ => None,
        }
    }

    /// Every role, in declaration order. Mirrors the `storage.grant_role`
    /// ENUM order in PG, which is weakest-to-strongest as written here for
    /// historical reasons (`storage.grant_role` declares strongest first).
    pub const ALL: [Role; 5] = [
        Role::Viewer,
        Role::Commenter,
        Role::Contributor,
        Role::Editor,
        Role::Owner,
    ];
}
