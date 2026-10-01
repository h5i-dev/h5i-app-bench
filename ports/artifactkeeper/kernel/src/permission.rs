//! `services/permission_service.rs` `PermissionService`. Each SQL query is a
//! scan of the snapshot. The in-process caches (30 s TTL) are left out: the
//! kernel answers as a cache miss, from the current tables.
use crate::strs::{any_eq, bytes_eq};
use crate::tables::{Db, Permission, Query};
use crate::net::{any_contains, CidrRange, IpAddr};
use crate::trusted::Oracle;
use crate::AppError;

/// `(SELECT project_id FROM repositories WHERE id = $n)`: `None` is SQL
/// NULL (no row, or a NULL column). Repository ids are a primary key.
pub fn project_of(db: &Db, repo_id: u64) -> Option<u64> {
    let mut i = 0;
    while i < db.repositories.len() {
        if db.repositories[i].id == repo_id {
            return db.repositories[i].project_id;
        }
        i += 1;
    }
    None
}

/// `target_id = (SELECT project_id FROM repositories WHERE id = $n)`:
/// false when the subquery is NULL.
pub fn project_is(db: &Db, repo_id: u64, target_id: u64) -> bool {
    match project_of(db, repo_id) {
        Some(pid) => pid == target_id,
        None => false,
    }
}

/// `group_id IN (SELECT group_id FROM user_group_members WHERE user_id = $1)`.
pub fn is_member(db: &Db, user_id: u64, group_id: u64) -> bool {
    let mut i = 0;
    while i < db.members.len() {
        if db.members[i].0 == user_id && db.members[i].1 == group_id {
            return true;
        }
        i += 1;
    }
    false
}

/// The principal disjunct shared by `check_repository_action` and
/// `query_actions`.
pub fn principal_matches(db: &Db, p: &Permission, user_id: u64) -> bool {
    ((bytes_eq(&p.principal_type, b"user") || bytes_eq(&p.principal_type, b"service_account"))
        && p.principal_id == user_id)
        || (bytes_eq(&p.principal_type, b"group") && is_member(db, user_id, p.principal_id))
}

/// `ip_condition_sql`: a rule without `allowed_cidrs` applies; one with it
/// applies only to a client IP inside a listed range, and a NULL client IP
/// matches nothing.
pub fn ip_condition(p: &Permission, client_ip: Option<IpAddr>) -> bool {
    match &p.allowed_cidrs {
        None => true,
        Some(cidrs) => match client_ip {
            None => false,
            Some(ip) => any_contains(cidrs, ip),
        },
    }
}

/// `(p.target_type = 'repository' AND p.target_id = $r) OR
/// (p.target_type = 'project' AND p.target_id = (SELECT project_id ...))`.
pub fn repo_target_matches(db: &Db, p: &Permission, repo_id: u64) -> bool {
    (bytes_eq(&p.target_type, b"repository") && p.target_id == repo_id)
        || (bytes_eq(&p.target_type, b"project") && project_is(db, repo_id, p.target_id))
}

/// A row of the `applicable_rules` CTE.
pub fn applicable(db: &Db, p: &Permission, client_ip: Option<IpAddr>, user_id: u64, repo_id: u64) -> bool {
    principal_matches(db, p, user_id) && repo_target_matches(db, p, repo_id) && ip_condition(p, client_ip)
}

/// `EXISTS (SELECT 1 FROM applicable_rules)`.
fn any_applicable(db: &Db, client_ip: Option<IpAddr>, user_id: u64, repo_id: u64) -> bool {
    let mut i = 0;
    while i < db.permissions.len() {
        if applicable(db, &db.permissions[i], client_ip, user_id, repo_id) {
            return true;
        }
        i += 1;
    }
    false
}

/// `EXISTS (SELECT 1 FROM applicable_rules WHERE $3 = ANY(actions) OR
/// 'admin' = ANY(actions))`.
fn any_applicable_grants(db: &Db, client_ip: Option<IpAddr>, user_id: u64, repo_id: u64, action: &[u8]) -> bool {
    let mut i = 0;
    while i < db.permissions.len() {
        let p = &db.permissions[i];
        if applicable(db, p, client_ip, user_id, repo_id) && (any_eq(&p.actions, action) || any_eq(&p.actions, b"admin")) {
            return true;
        }
        i += 1;
    }
    false
}

/// Some role with id `role_id` carries `perm`.
fn role_has(db: &Db, role_id: u64, perm: &[u8]) -> bool {
    let mut i = 0;
    while i < db.roles.len() {
        if db.roles[i].id == role_id && any_eq(&db.roles[i].permissions, perm) {
            return true;
        }
        i += 1;
    }
    false
}

/// `EXISTS (SELECT 1 FROM assigned_roles WHERE perm = ANY(permissions))`,
/// where `assigned_roles` joins the user's assignments on this repository
/// or on every repository (`repository_id IS NULL`) to `roles`.
pub fn assigned_role_has(db: &Db, user_id: u64, repo_id: u64, perm: &[u8]) -> bool {
    let mut i = 0;
    while i < db.role_assignments.len() {
        let ra = &db.role_assignments[i];
        let scoped = match ra.repository_id {
            Some(r) => r == repo_id,
            None => true,
        };
        if ra.user_id == user_id && scoped && role_has(db, ra.role_id, perm) {
            return true;
        }
        i += 1;
    }
    false
}

/// `check_repository_action`.
pub fn check_repository_action(db: &Db, client_ip: Option<IpAddr>, user_id: u64, repository_id: u64,
                               action: &[u8], is_admin: bool) -> Result<bool, AppError> {
    if is_admin {
        return Ok(true);
    }
    if db.fails(Query::RepositoryAction) {
        return Err(AppError::Database);
    }
    let owner = assigned_role_has(db, user_id, repository_id, b"admin");
    let decided = if any_applicable(db, client_ip, user_id, repository_id) {
        any_applicable_grants(db, client_ip, user_id, repository_id, action)
    } else {
        assigned_role_has(db, user_id, repository_id, action) || assigned_role_has(db, user_id, repository_id, b"admin")
    };
    Ok(owner || decided)
}

/// `check_anonymous_repository_action`.
pub fn check_anonymous_repository_action(db: &Db, client_ip: Option<IpAddr>, repository_id: u64,
                                         action: &[u8]) -> Result<bool, AppError> {
    if db.fails(Query::AnonymousAction) {
        return Err(AppError::Database);
    }
    let mut i = 0;
    while i < db.permissions.len() {
        let p = &db.permissions[i];
        if bytes_eq(&p.principal_type, b"anonymous")
            && repo_target_matches(db, p, repository_id)
            && (any_eq(&p.actions, action) || any_eq(&p.actions, b"admin"))
            && ip_condition(p, client_ip)
        {
            return Ok(true);
        }
        i += 1;
    }
    Ok(false)
}

/// The target disjunct of `has_any_rules_for_target` and `query_actions`:
/// the target itself, or for a repository its owning project.
pub fn target_matches(db: &Db, p: &Permission, target_type: &[u8], target_id: u64) -> bool {
    (bytes_eq(&p.target_type, target_type) && p.target_id == target_id)
        || (bytes_eq(target_type, b"repository")
            && bytes_eq(&p.target_type, b"project")
            && project_is(db, target_id, p.target_id))
}

/// `has_any_rules_for_target`.
pub fn has_any_rules_for_target(db: &Db, target_type: &[u8], target_id: u64) -> Result<bool, AppError> {
    if db.fails(Query::AnyRules) {
        return Err(AppError::Database);
    }
    let mut i = 0;
    while i < db.permissions.len() {
        if target_matches(db, &db.permissions[i], target_type, target_id) {
            return Ok(true);
        }
        i += 1;
    }
    Ok(false)
}

/// Push the actions of `p` not yet in `out` (`SELECT DISTINCT unnest(actions)`).
fn push_distinct(out: &mut Vec<Vec<u8>>, actions: &[Vec<u8>]) {
    let mut j = 0;
    while j < actions.len() {
        if !any_eq(out, &actions[j]) {
            out.push(actions[j].clone());
        }
        j += 1;
    }
}

/// `query_actions`.
pub fn query_actions(db: &Db, client_ip: Option<IpAddr>, user_id: u64, target_type: &[u8],
                     target_id: u64) -> Result<Vec<Vec<u8>>, AppError> {
    if db.fails(Query::QueryActions) {
        return Err(AppError::Database);
    }
    let mut out = Vec::new();
    let mut i = 0;
    while i < db.permissions.len() {
        let p = &db.permissions[i];
        if principal_matches(db, p, user_id) && target_matches(db, p, target_type, target_id) && ip_condition(p, client_ip) {
            push_distinct(&mut out, &p.actions);
        }
        i += 1;
    }
    Ok(out)
}

/// `check_permission`, through `resolve_actions` (cache miss).
pub fn check_permission(db: &Db, client_ip: Option<IpAddr>, user_id: u64, target_type: &[u8], target_id: u64,
                        action: &[u8], is_admin: bool) -> Result<bool, AppError> {
    if is_admin {
        return Ok(true);
    }
    let actions = query_actions(db, client_ip, user_id, target_type, target_id)?;
    Ok(any_eq(&actions, action))
}

/// The three queries of `principal_existence_query`.
fn user_exists(db: &Db, id: u64, service_account: bool) -> bool {
    let mut i = 0;
    while i < db.users.len() {
        if db.users[i].id == id && db.users[i].is_service_account == service_account {
            return true;
        }
        i += 1;
    }
    false
}

fn group_exists(db: &Db, id: u64) -> bool {
    let mut i = 0;
    while i < db.groups.len() {
        if db.groups[i] == id {
            return true;
        }
        i += 1;
    }
    false
}

/// `validate_principal`.
pub fn validate_principal(db: &Db, principal_type: &[u8], principal_id: u64) -> Result<(), AppError> {
    if bytes_eq(principal_type, b"anonymous") {
        if principal_id != 0 {
            return Err(AppError::Validation);
        }
        return Ok(());
    }
    let is_user = bytes_eq(principal_type, b"user");
    let is_sa = bytes_eq(principal_type, b"service_account");
    let is_group = bytes_eq(principal_type, b"group");
    if !is_user && !is_sa && !is_group {
        return Err(AppError::Validation);
    }
    if db.fails(Query::PrincipalExists) {
        return Err(AppError::Database);
    }
    let exists = if is_group {
        group_exists(db, principal_id)
    } else {
        user_exists(db, principal_id, is_sa)
    };
    if !exists {
        return Err(AppError::Validation);
    }
    Ok(())
}

/// Every entry of `cidrs` parses as a `CidrRange`.
fn all_parse(oracle: &Oracle, cidrs: &[Vec<u8>]) -> bool {
    let mut i = 0;
    while i < cidrs.len() {
        match CidrRange::parse(oracle, &cidrs[i]) {
            Ok(_) => {}
            Err(_) => return false,
        }
        i += 1;
    }
    true
}

/// `PermissionConditions::validate`.
pub fn validate_conditions(oracle: &Oracle, allowed_cidrs: &Option<Vec<Vec<u8>>>) -> Result<(), AppError> {
    if let Some(cidrs) = allowed_cidrs {
        if cidrs.len() == 0 {
            return Err(AppError::Validation);
        }
        if !all_parse(oracle, cidrs) {
            return Err(AppError::Validation);
        }
    }
    Ok(())
}
