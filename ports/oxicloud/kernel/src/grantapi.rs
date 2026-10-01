//! The grant endpoints (`interfaces/api/handlers/grant_handler.rs`
//! `create_grant`, `set_role`, `revoke_grant`), `DriveManagementService`
//! `set_member_role` and `remove_member`, and the `DrivePolicies` gates they
//! call. Every statement runs in autocommit upstream, so a request that
//! fails after a write keeps it: the reply carries the tables as they end.
use crate::acl::{check, clear_role, drive_of, drive_policies, set_role};
use crate::model::*;

/// The server state a request sees.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Env {
    pub migration_readonly: bool,
    pub now: i64,
    /// The id a new grant row gets (`gen_random_uuid()`).
    pub fresh: u64,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Request {
    /// `POST /api/grants` with a user, group or token subject.
    CreateGrant { resource: Resource, subject: Subject, role: Role, expires_at: Option<i64> },
    /// `PUT /api/grants/role`.
    SetRole { resource: Resource, subject: Subject, role: Role, expires_at: Option<i64> },
    /// `DELETE /api/grants/{id}`.
    RevokeGrant { grant_id: u64 },
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Reply {
    Granted(Grant),
    NoContent,
}

/// `require`: a denied permission is a 404 unless the caller can read the
/// resource, then a 403.
pub fn require(db: &Db, env: &Env, s: Subject, p: Permission, r: Resource) -> Result<(), ErrorKind> {
    if check(db, env.migration_readonly, env.now, s, p, r) {
        return Ok(());
    }
    let visible = p != Permission::Read && check(db, env.migration_readonly, env.now, s, Permission::Read, r);
    if visible { Err(ErrorKind::AccessDenied) } else { Err(ErrorKind::NotFound) }
}

fn find_drive(db: &Db, id: u64) -> Option<Drive> {
    let mut i = 0;
    while i < db.drives.len() {
        if db.drives[i].id == id {
            return Some(db.drives[i]);
        }
        i += 1;
    }
    None
}

/// The `drive_policies` lookup at the top of `create_grant`.
fn policies_for(db: &Db, r: Resource) -> Result<DrivePolicies, ErrorKind> {
    match r {
        Resource::File(_) | Resource::Folder(_) => match drive_of(db, r) {
            Some(d) => Ok(drive_policies(db, d)),
            None => Err(ErrorKind::Internal),
        },
        Resource::Drive(id) => match find_drive(db, id) {
            Some(d) => Ok(d.policies),
            None => Err(ErrorKind::Internal),
        },
        _ => Ok(drive_policies(db, u64::MAX)),
    }
}

/// `get_user_flags(uid).is_external`.
fn user_is_external(db: &Db, uid: u64) -> Result<bool, ErrorKind> {
    let mut i = 0;
    while i < db.users.len() {
        if db.users[i].id == uid {
            return Ok(db.users[i].is_external);
        }
        i += 1;
    }
    Err(ErrorKind::Internal)
}

/// `DrivePolicies::refuse_external_sharing`.
pub fn refuse_external_sharing(p: &DrivePolicies, s: Subject, is_external: bool) -> Result<(), ErrorKind> {
    if !p.forbid_external_sharing {
        return Ok(());
    }
    match s {
        Subject::User(_) => {
            if !is_external { Ok(()) } else { Err(ErrorKind::OperationNotSupported) }
        }
        _ => Ok(()),
    }
}

/// `refuse_if_personal`.
fn refuse_if_personal(db: &Db, drive_id: u64) -> Result<(), ErrorKind> {
    match find_drive(db, drive_id) {
        Some(d) => {
            if d.kind == DriveKind::Personal { Err(ErrorKind::OperationNotSupported) } else { Ok(()) }
        }
        None => Err(ErrorKind::Internal),
    }
}

/// `refuse_if_forbid_external_sharing`.
fn refuse_if_forbid_external_sharing(db: &Db, drive_id: u64, s: Subject) -> Result<(), ErrorKind> {
    let uid = match s {
        Subject::User(u) => u,
        _ => return Ok(()),
    };
    let d = match find_drive(db, drive_id) {
        Some(d) => d,
        None => return Err(ErrorKind::Internal),
    };
    if !d.policies.forbid_external_sharing {
        return Ok(());
    }
    let ext = user_is_external(db, uid)?;
    refuse_external_sharing(&d.policies, s, ext)
}

/// `list_grants_on_resource(..).any(|g| g.subject == subject && g.role == Owner)`;
/// the listing does not filter expired grants.
fn subject_is_owner(db: &Db, drive_id: u64, s: Subject) -> bool {
    let mut i = 0;
    while i < db.grants.len() {
        let g = db.grants[i];
        if g.resource == Resource::Drive(drive_id) && g.subject == s && g.role == Role::Owner {
            return true;
        }
        i += 1;
    }
    false
}

fn owner_count(db: &Db, drive_id: u64) -> usize {
    let mut n = 0;
    let mut i = 0;
    while i < db.grants.len() {
        let g = db.grants[i];
        if g.resource == Resource::Drive(drive_id) && g.role == Role::Owner {
            n += 1;
        }
        i += 1;
    }
    n
}

/// `refuse_if_forbid_owner_role_change` for a non-admin caller.
fn refuse_if_forbid_owner_role_change(db: &Db, drive_id: u64, s: Subject, new_role: Option<Role>) -> Result<(), ErrorKind> {
    let d = match find_drive(db, drive_id) {
        Some(d) => d,
        None => return Err(ErrorKind::Internal),
    };
    if !d.policies.forbid_owner_role_change {
        return Ok(());
    }
    let touches_owner = match new_role {
        Some(Role::Owner) => true,
        _ => subject_is_owner(db, drive_id, s),
    };
    if !touches_owner {
        return Ok(());
    }
    Err(ErrorKind::OperationNotSupported)
}

/// `refuse_if_last_owner_change`.
fn refuse_if_last_owner_change(db: &Db, drive_id: u64, s: Subject) -> Result<(), ErrorKind> {
    if !subject_is_owner(db, drive_id, s) {
        return Ok(());
    }
    if owner_count(db, drive_id) <= 1 {
        return Err(ErrorKind::InvalidInput);
    }
    Ok(())
}

fn with_grants(db: &Db, grants: Vec<Grant>) -> Db {
    Db {
        users: db.users.clone(),
        memberships: db.memberships.clone(),
        grants,
        drives: db.drives.clone(),
        folders: db.folders.clone(),
        files: db.files.clone(),
    }
}

/// `DriveManagementService::set_member_role` with `caller_is_admin = false`.
pub fn set_member_role(db: &Db, env: &Env, caller: u64, drive_id: u64, s: Subject, role: Role, expires_at: Option<i64>)
    -> (Db, Result<Reply, ErrorKind>) {
    let r = Resource::Drive(drive_id);
    let gates = match require(db, env, Subject::User(caller), Permission::Manage, r) {
        Err(e) => Err(e),
        Ok(()) => match refuse_if_personal(db, drive_id) {
            Err(e) => Err(e),
            Ok(()) => match refuse_if_forbid_external_sharing(db, drive_id, s) {
                Err(e) => Err(e),
                Ok(()) => match refuse_if_forbid_owner_role_change(db, drive_id, s, Some(role)) {
                    Err(e) => Err(e),
                    Ok(()) => {
                        if role != Role::Owner { refuse_if_last_owner_change(db, drive_id, s) } else { Ok(()) }
                    }
                },
            },
        },
    };
    match gates {
        Err(e) => (db.clone(), Err(e)),
        Ok(()) => {
            let (grants, g) = set_role(&db.grants, caller, s, role, r, expires_at, env.fresh);
            (with_grants(db, grants), Ok(Reply::Granted(g)))
        }
    }
}

/// `DriveManagementService::remove_member` with `caller_is_admin = false`.
pub fn remove_member(db: &Db, env: &Env, caller: u64, drive_id: u64, s: Subject) -> (Db, Result<Reply, ErrorKind>) {
    let r = Resource::Drive(drive_id);
    let gates = match require(db, env, Subject::User(caller), Permission::Manage, r) {
        Err(e) => Err(e),
        Ok(()) => match refuse_if_personal(db, drive_id) {
            Err(e) => Err(e),
            Ok(()) => match refuse_if_forbid_owner_role_change(db, drive_id, s, None) {
                Err(e) => Err(e),
                Ok(()) => refuse_if_last_owner_change(db, drive_id, s),
            },
        },
    };
    match gates {
        Err(e) => (db.clone(), Err(e)),
        Ok(()) => (with_grants(db, clear_role(&db.grants, s, r)), Ok(Reply::NoContent)),
    }
}

fn is_drive(r: Resource) -> bool {
    match r {
        Resource::Drive(_) => true,
        _ => false,
    }
}

/// The policy gates of `create_grant` after `require(Share)`.
fn create_gates(db: &Db, r: Resource, s: Subject) -> Result<(), ErrorKind> {
    let p = policies_for(db, r)?;
    if !is_drive(r) && p.forbid_sharing {
        return Err(ErrorKind::OperationNotSupported);
    }
    let token = match s {
        Subject::Token(_) => true,
        _ => false,
    };
    if token && (p.forbid_public_links || p.forbid_sharing) {
        return Err(ErrorKind::OperationNotSupported);
    }
    if p.forbid_external_sharing && !is_drive(r) {
        match s {
            Subject::User(uid) => {
                let ext = user_is_external(db, uid)?;
                return refuse_external_sharing(&p, s, ext);
            }
            _ => {}
        }
    }
    Ok(())
}

/// `create_grant`.
pub fn create_grant(db: &Db, env: &Env, caller: u64, r: Resource, s: Subject, role: Role, expires_at: Option<i64>)
    -> (Db, Result<Reply, ErrorKind>) {
    match require(db, env, Subject::User(caller), Permission::Share, r) {
        Err(e) => return (db.clone(), Err(e)),
        Ok(()) => {}
    }
    match create_gates(db, r, s) {
        Err(e) => return (db.clone(), Err(e)),
        Ok(()) => {}
    }
    match r {
        Resource::Drive(d) => set_member_role(db, env, caller, d, s, role, expires_at),
        _ => {
            let (grants, g) = set_role(&db.grants, caller, s, role, r, expires_at, env.fresh);
            (with_grants(db, grants), Ok(Reply::Granted(g)))
        }
    }
}

/// The `set_role` handler.
pub fn set_role_handler(db: &Db, env: &Env, caller: u64, r: Resource, s: Subject, role: Role, expires_at: Option<i64>)
    -> (Db, Result<Reply, ErrorKind>) {
    match require(db, env, Subject::User(caller), Permission::Share, r) {
        Err(e) => return (db.clone(), Err(e)),
        Ok(()) => {}
    }
    match r {
        Resource::Drive(d) => set_member_role(db, env, caller, d, s, role, expires_at),
        _ => {
            let (grants, g) = set_role(&db.grants, caller, s, role, r, expires_at, env.fresh);
            (with_grants(db, grants), Ok(Reply::Granted(g)))
        }
    }
}

fn find_grant(db: &Db, id: u64) -> Option<Grant> {
    let mut i = 0;
    while i < db.grants.len() {
        if db.grants[i].id == id {
            return Some(db.grants[i]);
        }
        i += 1;
    }
    None
}

/// `revoke`: `DELETE FROM storage.role_grants WHERE id = $1`.
pub fn revoke(grants: &[Grant], id: u64) -> Vec<Grant> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < grants.len() {
        let g = grants[i];
        if g.id != id {
            out.push(g);
        }
        i += 1;
    }
    out
}

/// `revoke_grant`, in upstream's order.
pub fn revoke_grant(db: &Db, env: &Env, caller: u64, grant_id: u64) -> (Db, Result<Reply, ErrorKind>) {
    let g = match find_grant(db, grant_id) {
        Some(g) => g,
        None => return (db.clone(), Ok(Reply::NoContent)),
    };
    match g.resource {
        Resource::Drive(d) => {
            let after = with_grants(db, revoke(&db.grants, grant_id));
            let (after2, res) = remove_member(&after, env, caller, d, g.subject);
            match res {
                Err(e) => (after, Err(e)),
                Ok(_) => (after2, Ok(Reply::NoContent)),
            }
        }
        _ => {
            if g.granted_by != caller {
                match require(db, env, Subject::User(caller), Permission::Share, g.resource) {
                    Err(e) => return (db.clone(), Err(e)),
                    Ok(()) => {}
                }
            }
            let after = revoke(&db.grants, grant_id);
            let after = clear_role(&after, g.subject, g.resource);
            (with_grants(db, after), Ok(Reply::NoContent))
        }
    }
}

/// One request from the authenticated user `caller`.
pub fn transition(db: &Db, env: &Env, caller: u64, req: Request) -> (Db, Result<Reply, ErrorKind>) {
    match req {
        Request::CreateGrant { resource, subject, role, expires_at } =>
            create_grant(db, env, caller, resource, subject, role, expires_at),
        Request::SetRole { resource, subject, role, expires_at } =>
            set_role_handler(db, env, caller, resource, subject, role, expires_at),
        Request::RevokeGrant { grant_id } => revoke_grant(db, env, caller, grant_id),
    }
}
