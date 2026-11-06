//! `authz` against `windmill_api_auth`.
use crate::{b, bl, random_scope, Rng};
use windmill_api_auth::{
    check_scopes, get_perm_in_extra_perms_for_authed, is_effectively_unscoped, is_instance_admin,
    is_owner, require_instance_admin, require_is_owner, require_owner_of_path,
    require_path_read_access_for_preview, ApiAuthed,
};
use windmill_common::error::Error;
use windmill_kernel::authz::{self as k, AuthzError};

const NAMES: &[&str] = &["alice", "bob", "team", "a", "", "al", "alice2", "d\u{e9}"];

fn kind(r: windmill_common::error::Result<()>) -> Result<(), AuthzError> {
    match r {
        Ok(()) => Ok(()),
        Err(Error::BadRequest(_)) => Err(AuthzError::BadRequest),
        Err(Error::PermissionDenied(_)) => Err(AuthzError::PermissionDenied),
        Err(Error::NotAuthorized(_)) => Err(AuthzError::NotAuthorized),
        Err(Error::RequireAdmin(_)) => Err(AuthzError::RequireAdmin),
        Err(e) => panic!("unexpected upstream error {e:?}"),
    }
}

fn random_authed(r: &mut Rng) -> (ApiAuthed, k::Authed) {
    let username = r.pick(NAMES).to_string();
    let groups: Vec<String> = (0..r.below(3)).map(|_| r.pick(NAMES).to_string()).collect();
    let folders: Vec<(String, bool, bool)> =
        (0..r.below(4)).map(|_| (r.pick(NAMES).to_string(), r.bool(), r.bool())).collect();
    let scopes: Option<Vec<String>> = if r.below(3) == 0 {
        None
    } else {
        Some(
            (0..r.below(4))
                .map(|_| if r.below(4) == 0 { "if_jobs:filter_tags:t".to_string() } else { random_scope(r) })
                .collect(),
        )
    };
    let is_admin = r.below(4) == 0;
    let job = r.below(3) == 0;
    let u = ApiAuthed {
        username: username.clone(),
        is_admin,
        groups: groups.clone(),
        folders: folders.clone(),
        scopes: scopes.clone(),
        job_id: job.then(uuid::Uuid::nil),
        ..Default::default()
    };
    let kk = k::Authed {
        username: b(&username),
        is_admin,
        groups: bl(&groups),
        folders: folders.iter().map(|(n, w, o)| k::Folder { name: b(n), can_write: *w, is_owner: *o }).collect(),
        has_scopes: scopes.is_some(),
        scopes: scopes.as_deref().map(bl).unwrap_or_default(),
        has_job_id: job,
    };
    (u, kk)
}

fn random_path(r: &mut Rng) -> String {
    const HEADS: &[&str] = &["u", "f", "g", "hub", "", "/u", "..", "U"];
    let n = r.below(5);
    let mut parts = vec![r.pick(HEADS).to_string()];
    for _ in 0..n {
        parts.push(if r.below(6) == 0 { "..".to_string() } else { r.pick(NAMES).to_string() });
    }
    let mut p = parts.join("/");
    if r.below(20) == 0 {
        p.push('\0');
    }
    p
}

#[test]
fn check_scopes_agrees() {
    let mut r = Rng(0x3d11_0101);
    for _ in 0..200_000 {
        let (u, kk) = random_authed(&mut r);
        let req = random_scope(&mut r);
        assert_eq!(k::check_scopes(&kk, req.as_bytes()), kind(check_scopes(&u, || req.clone())), "{u:?} {req:?}");
        assert_eq!(k::is_effectively_unscoped(kk.has_scopes, &kk.scopes), is_effectively_unscoped(u.scopes.as_deref()));
    }
}

#[test]
fn path_ownership_agrees() {
    let mut r = Rng(0x3d11_0102);
    for _ in 0..200_000 {
        let (u, kk) = random_authed(&mut r);
        let p = random_path(&mut r);
        let name = r.pick(NAMES);
        assert_eq!(k::is_owner(&kk, name.as_bytes()), is_owner(&u, name));
        assert_eq!(k::require_is_owner(&kk, name.as_bytes()), kind(require_is_owner(&u, name)));
        assert_eq!(k::require_owner_of_path(&kk, p.as_bytes()), kind(require_owner_of_path(&u, &p)), "{u:?} {p:?}");
        assert_eq!(
            k::require_path_read_access_for_preview(&kk, p.as_bytes()),
            kind(require_path_read_access_for_preview(&u, &Some(p.clone()))),
            "{u:?} {p:?}"
        );
        assert_eq!(k::is_instance_admin(&kk), is_instance_admin(&u));
        assert_eq!(k::require_instance_admin(&kk), kind(require_instance_admin(&u)));
    }
}

#[test]
fn extra_perms_agree() {
    let mut r = Rng(0x3d11_0103);
    for _ in 0..200_000 {
        let (u, kk) = random_authed(&mut r);
        let mut obj = serde_json::Map::new();
        for _ in 0..r.below(5) {
            let key = format!("{}/{}", ["u", "g", "f"][r.below(3) as usize], r.pick(NAMES));
            let v = match r.below(4) {
                0 => serde_json::Value::Bool(true),
                1 => serde_json::Value::Bool(false),
                2 => serde_json::Value::from(1),
                _ => serde_json::Value::Null,
            };
            obj.insert(key, v);
        }
        let entries: Vec<k::PermEntry> = obj
            .iter()
            .map(|(key, v)| k::PermEntry { key: b(key), is_bool: v.is_boolean(), value: v.as_bool().unwrap_or(false) })
            .collect();
        let is_object = r.below(8) != 0;
        let v = if is_object { serde_json::Value::Object(obj) } else { serde_json::Value::from(3) };
        let up = get_perm_in_extra_perms_for_authed(v, &u);
        let (some, val) = k::get_perm_in_extra_perms(is_object, &entries, &kk);
        assert_eq!(if some { Some(val) } else { None }, up, "{u:?} {entries:?}");
    }
}
