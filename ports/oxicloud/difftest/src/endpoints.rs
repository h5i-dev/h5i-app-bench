//! The grant endpoints against OxiCloud: the handlers' gate sequence is
//! transcribed from `grant_handler.rs` (they take the whole `AppState`), and
//! everything they call is OxiCloud's own: `PgAclEngine`, the `DrivePolicies`
//! gates, `DrivePgRepository`, `UserPgRepository` and
//! `DriveManagementService`. Both sides start from the same tables; the
//! reply and the grants table afterwards are compared.
use std::sync::Arc;

use oxicloud::application::ports::authorization_ports::AuthorizationEngine;
use oxicloud::application::services::drive_management_service::DriveManagementService;
use oxicloud::domain::entities::drive::{DrivePolicies as UPolicies, ExternalSharingGateContext, PublicLinkGateContext,
    SharingGateContext};
use oxicloud::domain::errors::{DomainError, ErrorKind as UK};
use oxicloud::domain::repositories::drive_repository::DriveRepository;
use oxicloud::domain::services::authorization::{Permission as UP, Resource as UR, Role as URole, Subject as US};
use oxicloud::infrastructure::repositories::pg::{DrivePgRepository, SubjectGroupPgRepository, UserPgRepository};
use oxicloud_kernel::grantapi::{transition, Env, Reply, Request};
use oxicloud_kernel::model::*;
use sqlx::PgPool;
use uuid::Uuid;

use crate::tests::*;

fn urole(r: Role) -> URole {
    match r {
        Role::Owner => URole::Owner,
        Role::Editor => URole::Editor,
        Role::Contributor => URole::Contributor,
        Role::Commenter => URole::Commenter,
        Role::Viewer => URole::Viewer,
    }
}

fn kind(e: &DomainError) -> ErrorKind {
    match e.kind {
        UK::NotFound => ErrorKind::NotFound,
        UK::AccessDenied => ErrorKind::AccessDenied,
        UK::InvalidInput => ErrorKind::InvalidInput,
        UK::UnsupportedOperation => ErrorKind::OperationNotSupported,
        _ => ErrorKind::Internal,
    }
}

type Out = Result<(), ErrorKind>;

fn ts(t: Option<i64>) -> Option<chrono::DateTime<chrono::Utc>> {
    t.map(|t| chrono::DateTime::from_timestamp(t, 0).unwrap())
}

/// `grant_handler::create_grant` for a user, group or token subject.
async fn create_grant(ctx: &Ctx, caller: Uuid, resource: UR, subject: US, role: URole, exp: Option<i64>) -> Out {
    let authz = &ctx.engine;
    authz.require(US::User(caller), UP::Share, resource).await.map_err(|e| kind(&e))?;
    let drive_policies = match resource {
        UR::File(id) => ctx.drives.get_policies_for_file(id).await,
        UR::Folder(id) => ctx.drives.get_policies_for_folder(id).await,
        UR::Drive(id) => ctx.drives.get_by_id(id).await.map(|d| d.drive.typed_policies()),
        UR::Calendar(_) | UR::AddressBook(_) | UR::Playlist(_) => Ok(UPolicies::default()),
    };
    let drive_policies = drive_policies.map_err(|_| ErrorKind::Internal)?;
    if !matches!(resource, UR::Drive(_)) {
        drive_policies.refuse_sharing(SharingGateContext { caller_id: caller, resource_type: resource.type_str(),
            resource_id: resource.id() }).map_err(|e| kind(&e))?;
    }
    if matches!(subject, US::Token(_)) {
        drive_policies.refuse_public_links(PublicLinkGateContext { caller_id: caller, item_type: resource.type_str(),
            item_id: resource.id() }).map_err(|e| kind(&e))?;
    }
    if drive_policies.forbid_external_sharing && !matches!(resource, UR::Drive(_)) && let US::User(uid) = subject {
        let is_external = ctx.users.get_user_flags(uid).await.map_err(|_| ErrorKind::Internal)?.is_external;
        drive_policies.refuse_external_sharing(subject, is_external, ExternalSharingGateContext { caller_id: caller,
            stage: "late_user", drive_id: None, resource_type: Some(resource.type_str()), resource_id: Some(resource.id()) })
            .map_err(|e| kind(&e))?;
    }
    if let UR::Drive(drive_id) = resource {
        ctx.mgmt.set_member_role(caller, false, drive_id, subject, role, ts(exp)).await.map_err(|e| kind(&e))?;
    } else {
        authz.set_role(caller, subject, role, resource, ts(exp)).await.map_err(|e| kind(&e))?;
    }
    Ok(())
}

/// `grant_handler::set_role`.
async fn set_role(ctx: &Ctx, caller: Uuid, resource: UR, subject: US, role: URole, exp: Option<i64>) -> Out {
    let authz = &ctx.engine;
    authz.require(US::User(caller), UP::Share, resource).await.map_err(|e| kind(&e))?;
    if let UR::Drive(drive_id) = resource {
        ctx.mgmt.set_member_role(caller, false, drive_id, subject, role, ts(exp)).await.map_err(|e| kind(&e))?;
    } else {
        authz.set_role(caller, subject, role, resource, ts(exp)).await.map_err(|e| kind(&e))?;
    }
    Ok(())
}

/// `grant_handler::revoke_grant`; `Ok` stands for 204.
async fn revoke_grant(ctx: &Ctx, caller: Uuid, grant_id: Uuid) -> Out {
    let authz = &ctx.engine;
    let (subject, resource, granter) = match authz.find_grant_full_by_id(grant_id).await {
        Ok(Some(t)) => t,
        Ok(None) => return Ok(()),
        Err(e) => return Err(kind(&e)),
    };
    if let UR::Drive(drive_id) = resource {
        authz.revoke(grant_id).await.map_err(|e| kind(&e))?;
        ctx.mgmt.remove_member(caller, false, drive_id, subject).await.map_err(|e| kind(&e))?;
    } else {
        if granter != caller {
            authz.require(US::User(caller), UP::Share, resource).await.map_err(|e| kind(&e))?;
        }
        authz.revoke(grant_id).await.map_err(|e| kind(&e))?;
        authz.clear_role(subject, resource).await.map_err(|e| kind(&e))?;
    }
    Ok(())
}

struct Ctx {
    engine: Arc<oxicloud::infrastructure::services::pg_acl_engine::PgAclEngine>,
    drives: Arc<DrivePgRepository>,
    users: Arc<UserPgRepository>,
    mgmt: DriveManagementService,
}

fn ctx(pool: &Arc<PgPool>, readonly: bool) -> Ctx {
    let engine = Arc::new(engine(pool, readonly));
    let drives = Arc::new(DrivePgRepository::new(pool.clone()));
    let users = Arc::new(UserPgRepository::new(pool.clone()));
    let mgmt = DriveManagementService::new(drives.clone(), engine.clone(), Arc::new(SubjectGroupPgRepository::new(pool.clone())),
        users.clone());
    Ctx { engine, drives, users, mgmt }
}

/// The grants table, without ids, sorted.
async fn grant_rows(pool: &PgPool) -> Vec<(String, u64, String, u64, String, u64, Option<i64>)> {
    let mut v: Vec<(String, u64, String, u64, String, u64, Option<i64>)> = sqlx::query_as::<_, (String, Uuid, String, Uuid, String, Uuid, Option<chrono::DateTime<chrono::Utc>>)>(
        "SELECT subject_type, subject_id, resource_type, resource_id, role::text, granted_by, expires_at FROM storage.role_grants")
        .fetch_all(pool).await.unwrap().into_iter()
        .map(|(st, si, rt, ri, ro, gb, ex)| (st, si.as_u128() as u64, rt, ri.as_u128() as u64, ro, gb.as_u128() as u64,
            ex.map(|t| t.timestamp()))).collect();
    v.sort();
    v
}

fn kernel_rows(db: &Db) -> Vec<(String, u64, String, u64, String, u64, Option<i64>)> {
    let st = |s: Subject| match s { Subject::User(_) => "user", Subject::Group(_) => "group", Subject::Token(_) => "token" };
    let sid = |s: Subject| match s { Subject::User(x) | Subject::Group(x) | Subject::Token(x) => x };
    let rid = |r: Resource| match r { Resource::Folder(x) | Resource::File(x) | Resource::Drive(x) | Resource::Calendar(x)
        | Resource::AddressBook(x) | Resource::Playlist(x) => x };
    let mut v: Vec<_> = db.grants.iter().map(|g| (st(g.subject).to_string(), sid(g.subject), res_type(g.resource).to_string(),
        rid(g.resource), role_str(g.role).to_string(), g.granted_by, g.expires_at)).collect();
    v.sort();
    v
}

fn request(db: &Db, r: &mut Rng) -> Request {
    let (subject, resource) = if r.chance(50) && !db.grants.is_empty() { near_grant(db, r) }
        else { (random_subject(r), random_resource(r)) };
    let role = r.pick(&ROLES);
    let now = now_secs();
    let expires_at = match r.below(4) { 0 => Some(now + 86_400), _ => None };
    match r.below(3) {
        0 => Request::CreateGrant { resource, subject, role, expires_at },
        1 => Request::SetRole { resource, subject, role, expires_at },
        _ => Request::RevokeGrant { grant_id: if r.chance(85) && !db.grants.is_empty() {
            db.grants[r.below(db.grants.len() as u64) as usize].id } else { 999 } },
    }
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn endpoints_agree() {
    let pool = Arc::new(PgPool::connect(DB).await.unwrap());
    let mut r = Rng(0xE4D9_0123_4567_89AB);
    let cases: usize = std::env::var("CASES").ok().and_then(|s| s.parse().ok()).unwrap_or(600);
    let mut seen = std::collections::BTreeMap::new();
    for case in 0..cases {
        let db = world(&pool, &mut r).await;
        let readonly = r.chance(5);
        let c = ctx(&pool, readonly);
        // Half the time an owner of a drive acting inside it; else mostly
        // someone holding a grant.
        let now = now_secs();
        let owners: Vec<(u64, u64)> = db.grants.iter().filter_map(|g| match (g.subject, g.resource) {
            (Subject::User(u), Resource::Drive(d)) if g.role == Role::Owner && u != GHOST
                && g.expires_at.map_or(true, |t| t > now) => Some((u, d)), _ => None }).collect();
        let owner = if !owners.is_empty() && r.chance(50) { Some(r.pick(&owners)) } else { None };
        let caller = if let Some((u, _)) = owner { u } else if r.chance(70) {
            let holders: Vec<u64> = db.grants.iter().filter_map(|g| match g.subject { Subject::User(u) if u != GHOST => Some(u), _ => None }).collect();
            if holders.is_empty() { r.pick(&USERS) } else { r.pick(&holders) }
        } else { r.pick(&USERS) };
        let mut req = request(&db, &mut r);
        if let Some((_, d)) = owner {
            let inside: Vec<Resource> = std::iter::once(Resource::Drive(d))
                .chain(db.folders.iter().filter(|f| f.drive_id == d).map(|f| Resource::Folder(f.id)))
                .chain(db.files.iter().filter(|f| f.drive_id == d).map(|f| Resource::File(f.id))).collect();
            let res = r.pick(&inside);
            let me = r.chance(30);
            let who = |s: Subject| if me { Subject::User(caller) } else { s };
            req = match req {
                Request::CreateGrant { subject, role, expires_at, .. } => Request::CreateGrant { resource: res, subject: who(subject), role, expires_at },
                Request::SetRole { subject, role, expires_at, .. } => Request::SetRole { resource: res, subject: who(subject), role, expires_at },
                x => x,
            };
        }
        let env = Env { migration_readonly: readonly, now: now_secs(), fresh: 9999 };
        let (after, got) = transition(&db, &env, caller, req);
        let want = match req {
            Request::CreateGrant { resource, subject, role, expires_at } =>
                create_grant(&c, uid(caller), uresource(resource), usubject(subject), urole(role), expires_at).await,
            Request::SetRole { resource, subject, role, expires_at } =>
                set_role(&c, uid(caller), uresource(resource), usubject(subject), urole(role), expires_at).await,
            Request::RevokeGrant { grant_id } => revoke_grant(&c, uid(caller), uid(grant_id)).await,
        };
        let got_unit = got.map(|_: Reply| ());
        assert_eq!(got_unit, want, "case {case}: caller {caller} {req:?}\n{db:#?}");
        assert_eq!(kernel_rows(&after), grant_rows(&pool).await, "case {case} grants: caller {caller} {req:?}");
        let label = format!("{} {:?}", match req { Request::CreateGrant { .. } => "create", Request::SetRole { .. } => "set",
            Request::RevokeGrant { .. } => "revoke" }, want);
        *seen.entry(label).or_insert(0) += 1;
    }
    println!("{seen:#?}");
}
