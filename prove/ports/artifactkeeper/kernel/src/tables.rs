//! A snapshot of the tables the authorization queries read. Each query of
//! upstream is a scan here, with the same WHERE, JOIN and EXISTS semantics.
use crate::net::CidrRange;
use crate::{User, Visibility};

/// The statements a request can issue; `Db::failing` makes one fail as the
/// driver would (pool timeout, connection loss).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Query {
    /// `repo_visibility_middleware`: `SELECT ... FROM repositories WHERE key = $1`.
    RepoByKey,
    /// `repo_visibility_middleware`: the role-assignment `EXISTS`.
    RoleGrant,
    /// `PermissionService::check_repository_action`.
    RepositoryAction,
    /// `PermissionService::check_anonymous_repository_action`.
    AnonymousAction,
    /// `PermissionService::has_any_rules_for_target`.
    AnyRules,
    /// `PermissionService::query_actions`.
    QueryActions,
    /// `PermissionService::validate_principal` existence check.
    PrincipalExists,
    /// `AuthConfigService::validate_download_ticket`.
    Ticket,
    /// `try_resolve_ticket_auth`: the ticket's user.
    TicketUser,
    /// `principal_must_change_password`.
    MustChangePassword,
    /// `create_permission`'s INSERT.
    InsertPermission,
}

/// A `repositories` row. `visibility` is `None` when the column does not
/// decode (`try_get` fails).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Repository {
    pub id: u64,
    pub key: Vec<u8>,
    pub visibility: Option<Visibility>,
    pub project_id: Option<u64>,
}

/// A `permissions` row. `allowed_cidrs` is `conditions->'allowed_cidrs'`,
/// each entry as Postgres's `::inet` reads it; `None` when the key is absent.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Permission {
    pub principal_type: Vec<u8>,
    pub principal_id: u64,
    pub target_type: Vec<u8>,
    pub target_id: u64,
    pub actions: Vec<Vec<u8>>,
    pub allowed_cidrs: Option<Vec<CidrRange>>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Role {
    pub id: u64,
    pub permissions: Vec<Vec<u8>>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct RoleAssignment {
    pub user_id: u64,
    pub role_id: u64,
    pub repository_id: Option<u64>,
}

/// A `download_tickets` row; `live` is `expires_at > NOW()`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Ticket {
    pub ticket: Vec<u8>,
    pub user_id: u64,
    pub resource_path: Option<Vec<u8>>,
    pub live: bool,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Db {
    pub users: Vec<User>,
    pub groups: Vec<u64>,
    /// `user_group_members (user_id, group_id)`.
    pub members: Vec<(u64, u64)>,
    pub repositories: Vec<Repository>,
    pub permissions: Vec<Permission>,
    pub roles: Vec<Role>,
    pub role_assignments: Vec<RoleAssignment>,
    pub tickets: Vec<Ticket>,
    pub failing: Vec<Query>,
}

impl Db {
    pub fn fails(&self, q: Query) -> bool {
        let mut i = 0;
        while i < self.failing.len() {
            if self.failing[i] == q {
                return true;
            }
            i += 1;
        }
        false
    }
}
