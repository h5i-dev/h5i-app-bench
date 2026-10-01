//! `infrastructure/services/pg_acl_engine.rs` `PgAclEngine`: the permission
//! check and the grant writes, deciding from the current tables (the caches
//! are left out; see DEVIATIONS.md). Each SQL query is a scan with the same
//! WHERE clause.
use crate::model::*;

/// `subject_group::INTERNAL_GROUP_ID`, every non-external user's group.
pub const INTERNAL_GROUP_ID: u64 = 1;

/// `Role::expand` as a membership test.
pub fn role_grants(role: Role, p: Permission) -> bool {
    match role {
        Role::Viewer => p == Permission::Read,
        Role::Commenter => p == Permission::Read || p == Permission::Comment,
        Role::Contributor => p == Permission::Read || p == Permission::Create,
        Role::Editor => p == Permission::Read || p == Permission::Comment || p == Permission::Create
            || p == Permission::Update,
        Role::Owner => true,
    }
}

/// `role = ANY(roles_implying(permission))`.
pub fn role_implies(role: Role, p: Permission) -> bool {
    match p {
        Permission::Read => true,
        Permission::Comment => role == Role::Commenter || role == Role::Editor || role == Role::Owner,
        Permission::Create => role == Role::Contributor || role == Role::Editor || role == Role::Owner,
        Permission::Update => role == Role::Editor || role == Role::Owner,
        Permission::Delete | Permission::Share | Permission::Manage => role == Role::Owner,
    }
}

/// `read_only_gate_applies`.
pub fn read_only_gate_applies(p: Permission) -> bool {
    p != Permission::Read
}

fn contains(ids: &[u64], x: u64) -> bool {
    let mut i = 0;
    while i < ids.len() {
        if ids[i] == x {
            return true;
        }
        i += 1;
    }
    false
}

/// `SELECT is_external FROM auth.users WHERE id = $1`, a missing row as true.
fn is_external(db: &Db, uid: u64) -> bool {
    let mut i = 0;
    while i < db.users.len() {
        if db.users[i].id == uid {
            return db.users[i].is_external;
        }
        i += 1;
    }
    true
}

/// The CTE's join: the member is the user, or a group already found.
fn member_reaches(m: Member, uid: u64, found: &[u64]) -> bool {
    match m {
        Member::User(u) => u == uid,
        Member::Group(g) => contains(found, g),
    }
}

/// One step of the recursive CTE in `groups_for_user`: groups that list
/// the user, or a group already found, as a member.
fn add_parents(db: &Db, uid: u64, found: Vec<u64>) -> (Vec<u64>, bool) {
    let mut out = found;
    let mut grew = false;
    let mut i = 0;
    while i < db.memberships.len() {
        let m = db.memberships[i];
        if member_reaches(m.member, uid, &out) && !contains(&out, m.group_id) {
            out.push(m.group_id);
            grew = true;
        }
        i += 1;
    }
    (out, grew)
}

/// `SubjectGroupPgRepository::groups_for_user`: the recursive CTE, run to a
/// fixpoint. Each round adds a group or stops, so `memberships.len() + 1`
/// rounds suffice.
pub fn groups_for_user(db: &Db, uid: u64) -> Vec<u64> {
    let mut found = Vec::new();
    let mut round = 0;
    let mut grew = true;
    while grew && round <= db.memberships.len() {
        let (next, g) = add_parents(db, uid, found);
        found = next;
        grew = g;
        round += 1;
    }
    found
}

fn push_new(mut v: Vec<u64>, x: u64) -> Vec<u64> {
    if !contains(&v, x) {
        v.push(x);
    }
    v
}

/// `expand_user`: the user, the internal group unless external, and every
/// group reached through memberships.
pub fn expand_user(db: &Db, uid: u64) -> Vec<u64> {
    let mut set = Vec::new();
    set.push(uid);
    if !is_external(db, uid) {
        set = push_new(set, INTERNAL_GROUP_ID);
    }
    let direct = groups_for_user(db, uid);
    let mut i = 0;
    while i < direct.len() {
        set = push_new(set, direct[i]);
        i += 1;
    }
    set
}

/// `subject_match_set`'s two lists: the accepted subject types (`user`,
/// `group`, `token` as 0, 1, 2) and ids.
pub fn subject_match_set(db: &Db, s: Subject) -> (Vec<u8>, Vec<u64>) {
    match s {
        Subject::User(uid) => {
            let mut types = Vec::new();
            types.push(0);
            types.push(1);
            (types, expand_user(db, uid))
        }
        Subject::Group(g) => {
            let mut types = Vec::new();
            types.push(1);
            let mut ids = Vec::new();
            ids.push(g);
            (types, ids)
        }
        Subject::Token(t) => {
            let mut types = Vec::new();
            types.push(2);
            let mut ids = Vec::new();
            ids.push(t);
            (types, ids)
        }
    }
}

fn subject_type(s: Subject) -> u8 {
    match s {
        Subject::User(_) => 0,
        Subject::Group(_) => 1,
        Subject::Token(_) => 2,
    }
}

fn subject_id(s: Subject) -> u64 {
    match s {
        Subject::User(x) | Subject::Group(x) | Subject::Token(x) => x,
    }
}

fn contains_u8(xs: &[u8], x: u8) -> bool {
    let mut i = 0;
    while i < xs.len() {
        if xs[i] == x {
            return true;
        }
        i += 1;
    }
    false
}

/// `subject_type = ANY($1) AND subject_id = ANY($2)`: the two lists are
/// matched independently, as in the SQL.
fn subject_matches(g: &Grant, types: &[u8], ids: &[u64]) -> bool {
    contains_u8(types, subject_type(g.subject)) && contains(ids, subject_id(g.subject))
}

/// `expires_at IS NULL OR expires_at > NOW()`.
fn live(g: &Grant, now: i64) -> bool {
    match g.expires_at {
        None => true,
        Some(t) => t > now,
    }
}

/// `direct_grant_exists` and `file_direct_grant_exists`.
pub fn direct_grant_exists(db: &Db, types: &[u8], ids: &[u64], p: Permission, r: Resource, now: i64) -> bool {
    let mut i = 0;
    while i < db.grants.len() {
        let g = db.grants[i];
        if subject_matches(&g, types, ids) && role_implies(g.role, p) && g.resource == r && live(&g, now) {
            return true;
        }
        i += 1;
    }
    false
}

fn find_folder(db: &Db, id: u64) -> Option<Folder> {
    let mut i = 0;
    while i < db.folders.len() {
        let f = db.folders[i].clone();
        if f.id == id {
            return Some(f);
        }
        i += 1;
    }
    None
}

/// ltree `a @> b`: `a` is an ancestor of `b` or equal to it.
pub fn lpath_contains(a: &[u64], b: &[u64]) -> bool {
    if a.len() > b.len() {
        return false;
    }
    let mut i = 0;
    while i < a.len() {
        if a[i] != b[i] {
            return false;
        }
        i += 1;
    }
    true
}

/// The `JOIN storage.folders gf` side of `folder_cascade_grant_exists`.
fn grant_folder_covers(db: &Db, g: &Grant, target: &[u64]) -> bool {
    match g.resource {
        Resource::Folder(fid) => match find_folder(db, fid) {
            Some(gf) => lpath_contains(&gf.lpath, target),
            None => false,
        },
        _ => false,
    }
}

/// `folder_cascade_grant_exists`: a live grant on the folder or an ancestor.
pub fn folder_cascade_grant_exists(db: &Db, types: &[u8], ids: &[u64], p: Permission, folder_id: u64, now: i64) -> bool {
    let target = match find_folder(db, folder_id) {
        Some(f) => f.lpath,
        None => return false,
    };
    let mut i = 0;
    while i < db.grants.len() {
        let g = db.grants[i];
        if subject_matches(&g, types, ids) && role_implies(g.role, p) && live(&g, now)
            && grant_folder_covers(db, &g, &target) {
            return true;
        }
        i += 1;
    }
    false
}

fn find_file(db: &Db, id: u64) -> Option<File> {
    let mut i = 0;
    while i < db.files.len() {
        if db.files[i].id == id {
            return Some(db.files[i]);
        }
        i += 1;
    }
    None
}

/// `query_parent_point`: `SELECT folder_id FROM storage.files WHERE id = $1`.
fn file_parent_folder(db: &Db, file_id: u64) -> Option<u64> {
    match find_file(db, file_id) {
        Some(f) => f.folder_id,
        None => None,
    }
}

/// `cascade_grant_cached` without the cache.
pub fn cascade_grant(db: &Db, s: Subject, r: Resource, p: Permission, now: i64) -> bool {
    match r {
        Resource::Folder(id) => {
            let (types, ids) = subject_match_set(db, s);
            folder_cascade_grant_exists(db, &types, &ids, p, id, now)
        }
        Resource::File(id) => {
            let folder_allowed = match file_parent_folder(db, id) {
                Some(parent) => {
                    let (types, ids) = subject_match_set(db, s);
                    folder_cascade_grant_exists(db, &types, &ids, p, parent, now)
                }
                None => false,
            };
            if folder_allowed {
                return true;
            }
            let (types, ids) = subject_match_set(db, s);
            direct_grant_exists(db, &types, &ids, p, r, now)
        }
        _ => false,
    }
}

/// `drive_of`: the drive of a folder or file, if the row exists.
pub fn drive_of(db: &Db, r: Resource) -> Option<u64> {
    match r {
        Resource::Folder(id) => match find_folder(db, id) {
            Some(f) => Some(f.drive_id),
            None => None,
        },
        Resource::File(id) => match find_file(db, id) {
            Some(f) => Some(f.drive_id),
            None => None,
        },
        _ => None,
    }
}

fn stronger(a: Option<Role>, b: Role) -> Option<Role> {
    match a {
        None => Some(b),
        Some(x) => {
            if role_rank(b) < role_rank(x) { Some(b) } else { Some(x) }
        }
    }
}

/// Position in `storage.grant_role`.
pub fn role_rank(r: Role) -> u8 {
    match r {
        Role::Owner => 0,
        Role::Editor => 1,
        Role::Contributor => 2,
        Role::Commenter => 3,
        Role::Viewer => 4,
    }
}

/// `caller_role_on_drive_cached`: `MIN(g.role)` over the caller's live
/// grants on the drive.
pub fn caller_role_on_drive(db: &Db, s: Subject, drive_id: u64, now: i64) -> Option<Role> {
    let (types, ids) = subject_match_set(db, s);
    let mut best: Option<Role> = None;
    let mut i = 0;
    while i < db.grants.len() {
        let g = db.grants[i];
        if subject_matches(&g, &types, &ids) && g.resource == Resource::Drive(drive_id) && live(&g, now) {
            best = stronger(best, g.role);
        }
        i += 1;
    }
    best
}

/// `drive_policies_cached`: the effective policies, or the defaults when
/// the drive has no row.
pub fn drive_policies(db: &Db, drive_id: u64) -> DrivePolicies {
    let mut i = 0;
    while i < db.drives.len() {
        if db.drives[i].id == drive_id {
            return db.drives[i].policies;
        }
        i += 1;
    }
    DrivePolicies {
        read_only: false,
        forbid_sharing: false,
        forbid_external_sharing: false,
        forbid_public_links: false,
        forbid_owner_role_change: false,
    }
}

fn role_has(r: Option<Role>, p: Permission) -> bool {
    match r {
        Some(role) => role_grants(role, p),
        None => false,
    }
}

/// `check_inner`. `migration_readonly` is the server-wide flag.
pub fn check(db: &Db, migration_readonly: bool, now: i64, s: Subject, p: Permission, r: Resource) -> bool {
    if read_only_gate_applies(p) && migration_readonly {
        return false;
    }
    let is_storage = match r {
        Resource::Folder(_) | Resource::File(_) => true,
        _ => false,
    };
    if is_storage {
        let drive_id = match drive_of(db, r) {
            Some(d) => d,
            None => return false,
        };
        if read_only_gate_applies(p) && drive_policies(db, drive_id).read_only {
            return false;
        }
        if role_has(caller_role_on_drive(db, s, drive_id, now), p) {
            return true;
        }
    }
    match r {
        Resource::Folder(_) | Resource::File(_) => cascade_grant(db, s, r, p, now),
        Resource::Drive(id) => {
            if read_only_gate_applies(p) && drive_policies(db, id).read_only {
                return false;
            }
            role_has(caller_role_on_drive(db, s, id, now), p)
        }
        Resource::Calendar(_) | Resource::AddressBook(_) | Resource::Playlist(_) => {
            let (types, ids) = subject_match_set(db, s);
            direct_grant_exists(db, &types, &ids, p, r, now)
        }
    }
}

fn same_key(g: &Grant, s: Subject, r: Resource) -> bool {
    g.subject == s && g.resource == r
}

/// `set_role`: `INSERT .. ON CONFLICT (subject, resource) DO UPDATE` of role,
/// expiry and grantor. `fresh` is the id a new row gets.
pub fn set_role(grants: &[Grant], granted_by: u64, s: Subject, role: Role, r: Resource, expires_at: Option<i64>, fresh: u64)
    -> (Vec<Grant>, Grant) {
    let mut out = Vec::new();
    let mut result = Grant { id: fresh, subject: s, resource: r, role, granted_by, expires_at };
    let mut found = false;
    let mut i = 0;
    while i < grants.len() {
        let g = grants[i];
        if same_key(&g, s, r) {
            let updated = Grant { id: g.id, subject: s, resource: r, role, granted_by, expires_at };
            out.push(updated);
            result = updated;
            found = true;
        } else {
            out.push(g);
        }
        i += 1;
    }
    if !found {
        out.push(result);
    }
    (out, result)
}

/// `clear_role`: delete the subject's grant on the resource.
pub fn clear_role(grants: &[Grant], s: Subject, r: Resource) -> Vec<Grant> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < grants.len() {
        let g = grants[i];
        if !same_key(&g, s, r) {
            out.push(g);
        }
        i += 1;
    }
    out
}
