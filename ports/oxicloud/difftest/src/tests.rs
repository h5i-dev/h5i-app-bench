//! The kernel against OxiCloud's own `PgAclEngine`, on a PostgreSQL database
//! migrated with OxiCloud's migrations. Each case writes random rows, then
//! asks both the same permission questions.
use std::sync::atomic::AtomicBool;
use std::sync::Arc;

use oxicloud::application::ports::authorization_ports::AuthorizationEngine;
use oxicloud::domain::entities::drive::DrivePolicies as UPolicies;
use oxicloud::domain::services::authorization::{Permission as UP, Resource as UR, Subject as US};
use oxicloud::infrastructure::repositories::pg::file_blob_read_repository::FileBlobReadRepository;
use oxicloud::infrastructure::repositories::pg::folder_db_repository::FolderDbRepository;
use oxicloud::infrastructure::repositories::pg::SubjectGroupPgRepository;
use oxicloud::infrastructure::services::dedup_service::DedupService;
use oxicloud::infrastructure::services::local_blob_backend::LocalBlobBackend;
use oxicloud::infrastructure::services::pg_acl_engine::PgAclEngine;
use oxicloud_kernel::acl::check;
use oxicloud_kernel::model::*;
use sqlx::PgPool;
use uuid::Uuid;

/// These tests truncate tables. Never default to a developer's database.
pub async fn disposable_database() -> PgPool {
    let url = std::env::var("H5I_BENCH_DATABASE_URL")
        .expect("set H5I_BENCH_DATABASE_URL to a disposable PostgreSQL database");
    let database = url.rsplit('/').next().unwrap().split('?').next().unwrap();
    assert_eq!(database, "h5i_bench_disposable", "refusing destructive tests against a non-benchmark database");
    let pool = PgPool::connect(&url).await.unwrap();
    sqlx::migrate!("../upstream-src/migrations").run(&pool).await.unwrap();
    pool
}

/// xorshift64*.
pub struct Rng(pub u64);
impl Rng {
    pub fn next(&mut self) -> u64 {
        self.0 ^= self.0 >> 12;
        self.0 ^= self.0 << 25;
        self.0 ^= self.0 >> 27;
        self.0.wrapping_mul(0x2545F4914F6CDD1D)
    }
    pub fn below(&mut self, n: u64) -> u64 {
        self.next() % n
    }
    pub fn chance(&mut self, pct: u64) -> bool {
        self.below(100) < pct
    }
    pub fn pick<T: Copy>(&mut self, xs: &[T]) -> T {
        xs[self.below(xs.len() as u64) as usize]
    }
}

pub fn uid(n: u64) -> Uuid {
    Uuid::from_u128(n as u128)
}

pub const USERS: [u64; 4] = [100, 101, 102, 103];
/// A subject id with no `auth.users` row.
pub const GHOST: u64 = 104;
pub const GROUPS: [u64; 3] = [200, 201, 202];
pub const DRIVES: [u64; 2] = [300, 301];
pub const TOKENS: [u64; 2] = [700, 701];
pub const OTHER: [u64; 2] = [600, 601];

pub fn usubject(s: Subject) -> US {
    match s {
        Subject::User(x) => US::User(uid(x)),
        Subject::Group(x) => US::Group(uid(x)),
        Subject::Token(x) => US::Token(uid(x)),
    }
}
pub fn uresource(r: Resource) -> UR {
    match r {
        Resource::Folder(x) => UR::Folder(uid(x)),
        Resource::File(x) => UR::File(uid(x)),
        Resource::Drive(x) => UR::Drive(uid(x)),
        Resource::Calendar(x) => UR::Calendar(uid(x)),
        Resource::AddressBook(x) => UR::AddressBook(uid(x)),
        Resource::Playlist(x) => UR::Playlist(uid(x)),
    }
}
pub fn uperm(p: Permission) -> UP {
    match p {
        Permission::Read => UP::Read,
        Permission::Create => UP::Create,
        Permission::Share => UP::Share,
        Permission::Comment => UP::Comment,
        Permission::Delete => UP::Delete,
        Permission::Update => UP::Update,
        Permission::Manage => UP::Manage,
    }
}
pub fn role_str(r: Role) -> &'static str {
    match r {
        Role::Owner => "owner",
        Role::Editor => "editor",
        Role::Contributor => "contributor",
        Role::Commenter => "commenter",
        Role::Viewer => "viewer",
    }
}
fn type_strs(s: Subject) -> &'static str {
    match s {
        Subject::User(_) => "user",
        Subject::Group(_) => "group",
        Subject::Token(_) => "token",
    }
}
pub fn res_type(r: Resource) -> &'static str {
    match r {
        Resource::Folder(_) => "folder",
        Resource::File(_) => "file",
        Resource::Drive(_) => "drive",
        Resource::Calendar(_) => "calendar",
        Resource::AddressBook(_) => "address_book",
        Resource::Playlist(_) => "playlist",
    }
}
fn res_id(r: Resource) -> u64 {
    match r {
        Resource::Folder(x) | Resource::File(x) | Resource::Drive(x) | Resource::Calendar(x)
        | Resource::AddressBook(x) | Resource::Playlist(x) => x,
    }
}
fn sub_id(s: Subject) -> u64 {
    match s {
        Subject::User(x) | Subject::Group(x) | Subject::Token(x) => x,
    }
}

pub const ROLES: [Role; 5] = [Role::Owner, Role::Editor, Role::Contributor, Role::Commenter, Role::Viewer];
pub const PERMS: [Permission; 7] = [Permission::Read, Permission::Create, Permission::Share, Permission::Comment,
    Permission::Delete, Permission::Update, Permission::Manage];

pub fn now_secs() -> i64 {
    chrono::Utc::now().timestamp()
}

/// A random world: written to the database, returned as the kernel's `Db`.
pub async fn world(pool: &PgPool, r: &mut Rng) -> Db {
    sqlx::query("TRUNCATE storage.role_grants, storage.files, storage.folders, storage.drives, \
                 auth.subject_group_members CASCADE").execute(pool).await.unwrap();
    sqlx::query("DELETE FROM auth.subject_groups WHERE id <> '00000000-0000-0000-0000-000000000001'")
        .execute(pool).await.unwrap();
    sqlx::query("TRUNCATE auth.users CASCADE").execute(pool).await.unwrap();

    let mut users = vec![];
    for u in USERS {
        let ext = r.chance(30);
        sqlx::query("INSERT INTO auth.users (id, username, email, role, is_external) VALUES ($1, $2, $3, 'user', $4)")
            .bind(uid(u)).bind(format!("u{u}")).bind(format!("u{u}@x")).bind(ext).execute(pool).await.unwrap();
        users.push(User { id: u, is_external: ext });
    }
    for g in GROUPS {
        sqlx::query("INSERT INTO auth.subject_groups (id, name) VALUES ($1, $2)")
            .bind(uid(g)).bind(format!("g{g}")).execute(pool).await.unwrap();
    }
    let mut memberships = vec![];
    for _ in 0..r.below(6) {
        let group = r.pick(&GROUPS);
        let member = if r.chance(60) { Member::User(r.pick(&USERS)) } else { Member::Group(r.pick(&[200, 201, 202, 1])) };
        if member == Member::Group(group) || memberships.iter().any(|m: &Membership| m.group_id == group && m.member == member) {
            continue;
        }
        let (mu, mg) = match member { Member::User(u) => (Some(uid(u)), None), Member::Group(g) => (None, Some(uid(g))) };
        let ok = sqlx::query("INSERT INTO auth.subject_group_members (group_id, member_user_id, member_group_id, added_by) \
                              VALUES ($1, $2, $3, $4)")
            .bind(uid(group)).bind(mu).bind(mg).bind(uid(100)).execute(pool).await;
        if ok.is_ok() {
            memberships.push(Membership { group_id: group, member });
        }
    }

    let mut drives = vec![];
    let mut folders = vec![];
    let mut next_folder = 400;
    for (k, d) in DRIVES.iter().enumerate() {
        let personal = k == 1;
        let mut pol = serde_json::Map::new();
        for knob in ["read_only", "forbid_sharing", "forbid_external_sharing", "forbid_public_links", "forbid_owner_role_change"] {
            if r.chance(35) {
                pol.insert(knob.into(), if r.chance(5) { serde_json::json!("yes") } else { serde_json::json!(r.chance(60)) });
            }
        }
        let root = next_folder;
        next_folder += 1;
        let mut tx = pool.begin().await.unwrap();
        sqlx::query("INSERT INTO storage.drives (id, kind, default_for_user, policies) VALUES ($1, $2, $3, $4)")
            .bind(uid(*d)).bind(if personal { "personal" } else { "shared" })
            .bind(if personal { Some(uid(100)) } else { None }).bind(serde_json::Value::Object(pol))
            .execute(&mut *tx).await.unwrap();
        sqlx::query("INSERT INTO storage.folders (id, name, parent_id, drive_id) VALUES ($1, $2, NULL, $3)")
            .bind(uid(root)).bind(format!("r{root}")).bind(uid(*d)).execute(&mut *tx).await.unwrap();
        sqlx::query("UPDATE storage.drives SET root_folder_id = $1 WHERE id = $2").bind(uid(root)).bind(uid(*d))
            .execute(&mut *tx).await.unwrap();
        tx.commit().await.unwrap();
        let mut mine = vec![root];
        for _ in 0..r.below(4) {
            let id = next_folder;
            next_folder += 1;
            let parent = r.pick(&mine);
            sqlx::query("INSERT INTO storage.folders (id, name, parent_id, drive_id) VALUES ($1, $2, $3, $4)")
                .bind(uid(id)).bind(format!("f{id}")).bind(uid(parent)).bind(uid(*d)).execute(pool).await.unwrap();
            mine.push(id);
        }
        folders.extend(mine.iter().map(|f| (*f, *d)));
        let eff: serde_json::Value = sqlx::query_scalar("SELECT effective_policies FROM storage.drives_effective WHERE id = $1")
            .bind(uid(*d)).fetch_one(pool).await.unwrap();
        let p = UPolicies::from_value(&eff);
        drives.push(Drive { id: *d, kind: if personal { DriveKind::Personal } else { DriveKind::Shared },
            policies: DrivePolicies { read_only: p.read_only, forbid_sharing: p.forbid_sharing,
                forbid_external_sharing: p.forbid_external_sharing, forbid_public_links: p.forbid_public_links,
                forbid_owner_role_change: p.forbid_owner_role_change } });
    }
    // The ltree the trigger computed, back as folder ids.
    let rows: Vec<(Uuid, String)> = sqlx::query_as("SELECT id, lpath::text FROM storage.folders").fetch_all(pool).await.unwrap();
    let kfolders: Vec<Folder> = rows.iter().map(|(id, lp)| {
        let id = id.as_u128() as u64;
        let lpath = lp.split('.').map(|l| Uuid::parse_str(&l.replace('_', "-")).unwrap().as_u128() as u64).collect();
        Folder { id, drive_id: folders.iter().find(|f| f.0 == id).unwrap().1, lpath }
    }).collect();

    let mut files = vec![];
    for id in 500..500 + r.below(5) {
        let (f, d) = folders[r.below(folders.len() as u64) as usize];
        sqlx::query("INSERT INTO storage.files (id, name, folder_id, blob_hash, drive_id) VALUES ($1, $2, $3, 'h', $4)")
            .bind(uid(id)).bind(format!("x{id}")).bind(uid(f)).bind(uid(d)).execute(pool).await.unwrap();
        files.push(File { id, drive_id: d, folder_id: Some(f) });
    }

    let now = now_secs();
    let mut grants: Vec<Grant> = vec![];
    for k in 0..r.below(14) {
        let subject = match r.below(5) {
            0 | 1 => Subject::User(r.pick(&[100, 101, 102, 103, GHOST])),
            2 => Subject::Group(r.pick(&[200, 201, 202, 1])),
            3 => Subject::Token(r.pick(&TOKENS)),
            _ => Subject::User(r.pick(&USERS)),
        };
        let resource = match r.below(6) {
            0 | 1 => Resource::Folder(400 + r.below(9)),
            2 => Resource::File(500 + r.below(5)),
            3 | 4 => Resource::Drive(r.pick(&DRIVES)),
            _ => match r.below(3) { 0 => Resource::Calendar(r.pick(&OTHER)), 1 => Resource::AddressBook(r.pick(&OTHER)),
                _ => Resource::Playlist(r.pick(&OTHER)) },
        };
        if grants.iter().any(|g| g.subject == subject && g.resource == resource) {
            continue;
        }
        let role = r.pick(&ROLES);
        let expires_at = match r.below(4) { 0 => Some(now - 86_400), 1 => Some(now + 86_400), _ => None };
        let id = 900 + k;
        sqlx::query("INSERT INTO storage.role_grants (id, subject_type, subject_id, resource_type, resource_id, role, granted_by, expires_at) \
                     VALUES ($1, $2, $3, $4, $5, $6::storage.grant_role, $7, to_timestamp($8))")
            .bind(uid(id)).bind(type_strs(subject)).bind(uid(sub_id(subject))).bind(res_type(resource))
            .bind(uid(res_id(resource))).bind(role_str(role)).bind(uid(r.pick(&USERS))).bind(expires_at.map(|t| t as f64))
            .execute(pool).await.unwrap();
        grants.push(Grant { id, subject, resource, role, granted_by: 0, expires_at });
    }
    // granted_by as stored.
    let gb: Vec<(Uuid, Uuid)> = sqlx::query_as("SELECT id, granted_by FROM storage.role_grants").fetch_all(pool).await.unwrap();
    for g in grants.iter_mut() {
        g.granted_by = gb.iter().find(|x| x.0 == uid(g.id)).unwrap().1.as_u128() as u64;
    }
    Db { users, memberships, grants, drives, folders: kfolders, files }
}

pub fn engine(pool: &Arc<PgPool>, readonly: bool) -> PgAclEngine {
    let folder_repo = Arc::new(FolderDbRepository::new(pool.clone()));
    // The drive lookups the engine makes never touch blobs.
    let dir = std::env::var_os("OXICLOUD_BLOBS").map(std::path::PathBuf::from)
        .unwrap_or_else(|| std::env::temp_dir().join("oxicloud-blobs"));
    let blobs = Arc::new(LocalBlobBackend::new(&dir));
    let dedup = Arc::new(DedupService::new(blobs, pool.clone(), pool.clone()));
    let file_repo = Arc::new(FileBlobReadRepository::new(pool.clone(), dedup, folder_repo.clone()));
    PgAclEngine::new(pool.clone(), folder_repo, file_repo, Arc::new(SubjectGroupPgRepository::new(pool.clone())),
        Arc::new(AtomicBool::new(readonly)))
}

pub fn random_resource(r: &mut Rng) -> Resource {
    match r.below(7) {
        0 | 1 => Resource::Folder(400 + r.below(10)),
        2 | 3 => Resource::File(500 + r.below(6)),
        4 => Resource::Drive(r.pick(&[300, 301, 302])),
        5 => Resource::Calendar(r.pick(&OTHER)),
        _ => Resource::Playlist(r.pick(&OTHER)),
    }
}

/// A question close to an existing grant: its subject (or a member of its
/// group) on its resource (or something under it).
pub fn near_grant(db: &Db, r: &mut Rng) -> (Subject, Resource) {
    let g = db.grants[r.below(db.grants.len() as u64) as usize];
    let s = match g.subject {
        Subject::Group(gid) if r.chance(70) => {
            let members: Vec<u64> = db.memberships.iter().filter_map(|m| match m.member {
                Member::User(u) if m.group_id == gid => Some(u), _ => None }).collect();
            if members.is_empty() { Subject::User(r.pick(&USERS)) } else { Subject::User(r.pick(&members)) }
        }
        x => x,
    };
    let res = match g.resource {
        Resource::Drive(d) | Resource::Folder(d) if r.chance(50) => {
            let drive = match g.resource { Resource::Drive(d) => Some(d),
                _ => db.folders.iter().find(|f| f.id == d).map(|f| f.drive_id) };
            let inside: Vec<Resource> = db.folders.iter().filter(|f| Some(f.drive_id) == drive).map(|f| Resource::Folder(f.id))
                .chain(db.files.iter().filter(|f| Some(f.drive_id) == drive).map(|f| Resource::File(f.id))).collect();
            if inside.is_empty() { g.resource } else { r.pick(&inside) }
        }
        x => x,
    };
    (s, res)
}

pub fn random_subject(r: &mut Rng) -> Subject {
    match r.below(6) {
        0 => Subject::Group(r.pick(&[200, 201, 202, 1])),
        1 => Subject::Token(r.pick(&TOKENS)),
        2 => Subject::User(GHOST),
        _ => Subject::User(r.pick(&USERS)),
    }
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn check_agrees() {
    let pool = Arc::new(disposable_database().await);
    let mut r = Rng(0x0C1C_0A0D_1234_5678);
    let cases: usize = std::env::var("CASES").ok().and_then(|s| s.parse().ok()).unwrap_or(400);
    let (mut yes, mut no) = (0, 0);
    for case in 0..cases {
        let db = world(&pool, &mut r).await;
        let readonly = r.chance(10);
        let eng = engine(&pool, readonly);
        for q in 0..25 {
            let (s, res) = if !db.grants.is_empty() && r.chance(60) { near_grant(&db, &mut r) }
                else { (random_subject(&mut r), random_resource(&mut r)) };
            let p = r.pick(&PERMS);
            let want = eng.check(usubject(s), uperm(p), uresource(res)).await.unwrap();
            let got = check(&db, readonly, now_secs(), s, p, res);
            assert_eq!(got, want, "case {case} query {q}: {s:?} {p:?} {res:?} readonly={readonly}\n{db:#?}");
            if want { yes += 1 } else { no += 1 }
        }
    }
    println!("allowed {yes}, denied {no}");
    assert!(yes > cases && no > cases);
}
