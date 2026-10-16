//! Falsification and non-vacuity tests for proofs/Properties.lean, on
//! in-memory worlds drawn like the differential test's (no database).
use oxicloud_kernel::acl::{check, role_grants};
use oxicloud_kernel::grantapi::{transition, Env, Reply, Request};
use oxicloud_kernel::model::*;

use crate::tests::{near_grant, random_resource, random_subject, Rng, DRIVES, GHOST, GROUPS, OTHER, PERMS, ROLES, TOKENS, USERS};

const N: usize = 60_000;
const MIN_HITS: usize = 300;
const NOW: i64 = 1_000_000;

/// A world like `tests::world`, built directly.
pub fn world(r: &mut Rng) -> Db {
    let users = USERS.iter().map(|&id| User { id, is_external: r.chance(30) }).collect();
    let mut memberships: Vec<Membership> = vec![];
    for _ in 0..r.below(6) {
        let group_id = r.pick(&GROUPS);
        let member = if r.chance(60) { Member::User(r.pick(&USERS)) } else { Member::Group(r.pick(&[200, 201, 202, 1])) };
        if member != Member::Group(group_id) && !memberships.iter().any(|m| m.group_id == group_id && m.member == member) {
            memberships.push(Membership { group_id, member });
        }
    }
    let mut drives = vec![];
    let mut folders: Vec<Folder> = vec![];
    let mut next = 400;
    for (k, &d) in DRIVES.iter().enumerate() {
        let b = |r: &mut Rng| r.chance(20);
        drives.push(Drive { id: d, kind: if k == 1 { DriveKind::Personal } else { DriveKind::Shared },
            policies: DrivePolicies { read_only: b(r), forbid_sharing: b(r), forbid_external_sharing: b(r),
                forbid_public_links: b(r), forbid_owner_role_change: b(r) } });
        let root = next;
        next += 1;
        folders.push(Folder { id: root, drive_id: d, lpath: vec![root] });
        let mut mine = vec![root];
        for _ in 0..r.below(4) {
            let parent = r.pick(&mine);
            let mut lpath = folders.iter().find(|f| f.id == parent).unwrap().lpath.clone();
            lpath.push(next);
            folders.push(Folder { id: next, drive_id: d, lpath });
            mine.push(next);
            next += 1;
        }
    }
    let mut files = vec![];
    for id in 500..500 + r.below(5) {
        let f = folders[r.below(folders.len() as u64) as usize].clone();
        files.push(File { id, drive_id: f.drive_id, folder_id: Some(f.id) });
    }
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
            _ => Resource::Playlist(r.pick(&OTHER)),
        };
        if grants.iter().any(|g| g.subject == subject && g.resource == resource) {
            continue;
        }
        let expires_at = match r.below(4) { 0 => Some(NOW - 10), 1 => Some(NOW + 10), _ => None };
        grants.push(Grant { id: 900 + k, subject, resource, role: r.pick(&ROLES), granted_by: r.pick(&USERS), expires_at });
    }
    Db { users, memberships, grants, drives, folders, files }
}

fn live(g: &Grant) -> bool {
    g.expires_at.map_or(true, |t| t > NOW)
}

fn query(db: &Db, r: &mut Rng) -> (Subject, Permission, Resource) {
    let (s, res) = if !db.grants.is_empty() && r.chance(60) { near_grant(db, r) } else { (random_subject(r), random_resource(r)) };
    (s, r.pick(&PERMS), res)
}

fn checks(seed: u64, mut f: impl FnMut(&Db, bool, Subject, Permission, Resource, bool) -> bool) {
    let mut r = Rng(seed);
    let mut hits = 0;
    for _ in 0..N {
        let db = world(&mut r);
        let ro = r.chance(10);
        let (s, p, res) = query(&db, &mut r);
        let ok = check(&db, ro, NOW, s, p, res);
        if f(&db, ro, s, p, res, ok) {
            hits += 1;
        }
    }
    assert!(hits >= MIN_HITS, "premises held {hits} times");
}

fn drive_of(db: &Db, r: Resource) -> Option<u64> {
    match r {
        Resource::Folder(x) => db.folders.iter().find(|f| f.id == x).map(|f| f.drive_id),
        Resource::File(x) => db.files.iter().find(|f| f.id == x).map(|f| f.drive_id),
        Resource::Drive(x) => Some(x),
        _ => None,
    }
}

#[test]
fn read_only_blocks_mutations() {
    checks(1, |db, ro, _, p, res, ok| {
        let drive_ro = drive_of(db, res).and_then(|d| db.drives.iter().find(|x| x.id == d)).map_or(false, |d| d.policies.read_only);
        if p == Permission::Read || !(ro || drive_ro) { return false }
        assert!(!ok);
        true
    });
}

#[test]
fn expired_grants_ignored() {
    checks(2, |db, ro, s, p, res, ok| {
        if db.grants.iter().all(live) { return false }
        let mut db2 = db.clone();
        db2.grants.retain(live);
        assert_eq!(check(&db2, ro, NOW, s, p, res), ok);
        true
    });
}


#[test]
fn token_needs_its_own_grant() {
    checks(4, |db, _, s, _, _, ok| {
        let Subject::Token(t) = s else { return false };
        if !ok { return false }
        assert!(db.grants.iter().any(|g| g.subject == Subject::Token(t) && live(g)));
        true
    });
}

#[test]
fn share_needs_owner() {
    checks(5, |db, _, _, p, _, ok| {
        if p != Permission::Share || !ok { return false }
        assert!(db.grants.iter().any(|g| g.role == Role::Owner && live(g)));
        true
    });
}

#[test]
fn role_expansion_is_monotone() {
    // `role_grants` grows with the role's rank: an Owner has every permission.
    for p in PERMS {
        assert!(role_grants(Role::Owner, p));
        if role_grants(Role::Viewer, p) {
            for r in ROLES { assert!(role_grants(r, p)) }
        }
    }
}

fn request(db: &Db, r: &mut Rng) -> (u64, Request) {
    let owners: Vec<(u64, u64)> = db.grants.iter().filter_map(|g| match (g.subject, g.resource) {
        (Subject::User(u), Resource::Drive(d)) if g.role == Role::Owner && u != GHOST && live(g) => Some((u, d)), _ => None }).collect();
    let (caller, d) = if !owners.is_empty() && r.chance(60) { let (u, d) = r.pick(&owners); (u, Some(d)) } else { (r.pick(&USERS), None) };
    let (mut subject, mut resource) = if !db.grants.is_empty() && r.chance(50) { near_grant(db, r) } else { (random_subject(r), random_resource(r)) };
    if let Some(d) = d {
        let inside: Vec<Resource> = std::iter::once(Resource::Drive(d))
            .chain(db.folders.iter().filter(|f| f.drive_id == d).map(|f| Resource::Folder(f.id)))
            .chain(db.files.iter().filter(|f| f.drive_id == d).map(|f| Resource::File(f.id))).collect();
        resource = r.pick(&inside);
        if r.chance(30) { subject = Subject::User(caller) }
    }
    let role = r.pick(&ROLES);
    let req = match r.below(2) {
        0 => Request::CreateGrant { resource, subject, role, expires_at: None },
        _ => Request::SetRole { resource, subject, role, expires_at: None },
    };
    (caller, req)
}

fn writes(seed: u64, mut f: impl FnMut(&Db, u64, Request, &Db, &Result<Reply, ErrorKind>) -> bool) {
    let mut r = Rng(seed);
    let mut hits = 0;
    for _ in 0..N {
        let db = world(&mut r);
        let (caller, req) = request(&db, &mut r);
        let env = Env { migration_readonly: r.chance(5), now: NOW, fresh: 9999 };
        let (after, out) = transition(&db, &env, caller, req);
        if f(&db, caller, req, &after, &out) {
            hits += 1;
        }
    }
    assert!(hits >= MIN_HITS, "premises held {hits} times");
}

#[test]
fn create_needs_share() {
    writes(6, |db, caller, req, _, out| {
        let Request::CreateGrant { resource, .. } = req else { return false };
        if out.is_err() { return false }
        assert!(check(db, false, NOW, Subject::User(caller), Permission::Share, resource));
        true
    });
}

#[test]
fn create_respects_sharing_policies() {
    writes(7, |db, _, req, _, out| {
        let Request::CreateGrant { resource, subject, .. } = req else { return false };
        if out.is_err() || matches!(resource, Resource::Drive(_) | Resource::Playlist(_) | Resource::Calendar(_) | Resource::AddressBook(_)) { return false }
        let d = drive_of(db, resource).unwrap();
        let p = db.drives.iter().find(|x| x.id == d).unwrap().policies;
        assert!(!p.forbid_sharing);
        if matches!(subject, Subject::Token(_)) { assert!(!p.forbid_public_links) }
        true
    });
}

#[test]
fn personal_drive_members_fixed() {
    writes(8, |db, _, req, after, out| {
        let r = match req { Request::CreateGrant { resource, .. } | Request::SetRole { resource, .. } => resource, _ => return false };
        if r != Resource::Drive(301) { return false }
        assert!(out.is_err());
        assert_eq!(after, db);
        true
    });
}

#[test]
fn drive_keeps_an_owner() {
    writes(9, |db, _, req, after, out| {
        let r = match req { Request::CreateGrant { resource, .. } | Request::SetRole { resource, .. } => resource, _ => return false };
        let Resource::Drive(d) = r else { return false };
        let owners = |x: &Db| x.grants.iter().filter(|g| g.resource == Resource::Drive(d) && g.role == Role::Owner).count();
        if out.is_err() || owners(db) == 0 { return false }
        assert!(owners(after) >= 1);
        true
    });
}

#[test]
fn failed_write_changes_nothing() {
    writes(10, |db, _, _, after, out| {
        if out.is_ok() { return false }
        assert_eq!(after, db);
        true
    });
}
