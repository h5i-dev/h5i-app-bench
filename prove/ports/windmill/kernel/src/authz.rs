//! Request authorization helpers of `backend/windmill-api-auth/src/lib.rs` @ 9dedc42:
//! `check_scopes`, `is_effectively_unscoped` (with `scope_restrictions`), `is_owner`,
//! `require_is_owner`, `require_owner_of_path`, `require_path_read_access_for_preview`,
//! `get_perm_in_extra_perms_for_authed`, `is_instance_admin`, `require_instance_admin`.
use crate::bytes::{eq, split, starts_with};
use crate::scopes::{from_scope_string, includes, Scope};

/// One `(name, can_write, is_owner)` entry of `ApiAuthed::folders`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Folder {
    pub name: Vec<u8>,
    pub can_write: bool,
    pub is_owner: bool,
}

/// The fields of `ApiAuthed` these decisions read.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Authed {
    pub username: Vec<u8>,
    pub is_admin: bool,
    pub groups: Vec<Vec<u8>>,
    pub folders: Vec<Folder>,
    /// `scopes.is_some()`.
    pub has_scopes: bool,
    pub scopes: Vec<Vec<u8>>,
    /// `job_id.is_some()` (a `WM_TOKEN` job token).
    pub has_job_id: bool,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AuthzError {
    BadRequest,
    PermissionDenied,
    NotAuthorized,
    RequireAdmin,
}

/// `s.starts_with("if_jobs:filter_tags:")`.
pub fn is_filter_tags(s: &[u8]) -> bool {
    let p: Vec<u8> = b"if_jobs:filter_tags:".to_vec();
    starts_with(s, &p)
}

/// `s` parses to a scope that `includes` `req`.
pub fn parsed_includes(s: &[u8], req: &Scope) -> bool {
    match from_scope_string(s) {
        Some(s) => includes(&s, req),
        None => false,
    }
}

/// Some scope other than a tag filter parses and grants `req` (the loop of
/// `check_scopes`, which returns `Ok` at the first such scope).
pub fn any_grants(list: &[Vec<u8>], req: &Scope) -> bool {
    let mut i = 0;
    while i < list.len() {
        if !is_filter_tags(&list[i]) && parsed_includes(&list[i], req) {
            return true;
        }
        i += 1;
    }
    false
}

/// `check_scopes(authed, || required)`. Upstream's loop sets `is_scoped_token` at the
/// first scope that is not a tag filter and returns `Ok` at the first one that grants
/// `required`; afterwards it denies iff `is_scoped_token`. Here those are the two
/// helpers `any_grants` and `!is_effectively_unscoped`.
pub fn check_scopes(a: &Authed, required: &[u8]) -> Result<(), AuthzError> {
    if !a.has_scopes {
        return Ok(());
    }
    let req = match from_scope_string(required) {
        Some(r) => r,
        None => return Err(AuthzError::BadRequest),
    };
    if any_grants(&a.scopes, &req) {
        return Ok(());
    }
    if !is_effectively_unscoped(true, &a.scopes) {
        return Err(AuthzError::PermissionDenied);
    }
    Ok(())
}

/// `is_effectively_unscoped(scopes)`: no scope other than `if_jobs:filter_tags:` ones.
pub fn is_effectively_unscoped(has_scopes: bool, list: &[Vec<u8>]) -> bool {
    if !has_scopes {
        return true;
    }
    let mut i = 0;
    while i < list.len() {
        if !is_filter_tags(&list[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// `is_owner(authed, name)`.
pub fn is_owner(a: &Authed, name: &[u8]) -> bool {
    if a.is_admin {
        return true;
    }
    let mut i = 0;
    while i < a.folders.len() {
        if eq(&a.folders[i].name, name) && a.folders[i].is_owner {
            return true;
        }
        i += 1;
    }
    false
}

/// `require_is_owner(authed, name)`.
pub fn require_is_owner(a: &Authed, name: &[u8]) -> Result<(), AuthzError> {
    if is_owner(a, name) { Ok(()) } else { Err(AuthzError::NotAuthorized) }
}

pub const U: &[u8] = b"u";
pub const F: &[u8] = b"f";
pub const HUB: &[u8] = b"hub";
/// `seg == ".."`.
pub fn is_dotdot(seg: &[u8]) -> bool {
    seg.len() == 2 && seg[0] == 46 && seg[1] == 46
}

/// `require_owner_of_path(authed, path)`.
pub fn require_owner_of_path(a: &Authed, path: &[u8]) -> Result<(), AuthzError> {
    if a.is_admin {
        return Ok(());
    }
    if path.len() == 0 {
        return Err(AuthzError::BadRequest);
    }
    let parts = split(path, 47);
    if parts.len() < 2 {
        return Err(AuthzError::BadRequest);
    }
    if eq(&parts[0], U) {
        if eq(&parts[1], &a.username) { Ok(()) } else { Err(AuthzError::BadRequest) }
    } else if eq(&parts[0], F) {
        require_is_owner(a, &parts[1])
    } else {
        Err(AuthzError::BadRequest)
    }
}

/// `path.split('/').any(|seg| seg == "..")`.
pub fn has_dotdot_segment(parts: &[Vec<u8>]) -> bool {
    let mut i = 0;
    while i < parts.len() {
        if is_dotdot(&parts[i]) {
            return true;
        }
        i += 1;
    }
    false
}

/// `path.contains('\0')`.
pub fn has_nul(path: &[u8]) -> bool {
    let mut i = 0;
    while i < path.len() {
        if path[i] == 0 {
            return true;
        }
        i += 1;
    }
    false
}

/// Some folder of the caller (any access) is named `name`.
pub fn has_folder(a: &Authed, name: &[u8]) -> bool {
    let mut i = 0;
    while i < a.folders.len() {
        if eq(&a.folders[i].name, name) {
            return true;
        }
        i += 1;
    }
    false
}

/// `require_path_read_access_for_preview(authed, &Some(path))` (`None` is `Ok`).
pub fn require_path_read_access_for_preview(a: &Authed, path: &[u8]) -> Result<(), AuthzError> {
    let parts = split(path, 47);
    if (path.len() > 0 && path[0] == 47) || has_dotdot_segment(&parts) || has_nul(path) {
        return Err(AuthzError::BadRequest);
    }
    if a.is_admin {
        return Ok(());
    }
    if path.len() == 0 {
        return Ok(());
    }
    if parts.len() < 2 {
        return Err(AuthzError::BadRequest);
    }
    if eq(&parts[0], U) {
        if eq(&parts[1], &a.username) { Ok(()) } else { Err(AuthzError::BadRequest) }
    } else if eq(&parts[0], F) {
        if has_folder(a, &parts[1]) { Ok(()) } else { Err(AuthzError::BadRequest) }
    } else if eq(&parts[0], HUB) {
        Ok(())
    } else {
        Err(AuthzError::BadRequest)
    }
}

/// One entry of an `extra_perms` JSON object: the key and, when the value is a JSON
/// boolean, that boolean.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct PermEntry {
    pub key: Vec<u8>,
    pub is_bool: bool,
    pub value: bool,
}

/// `obj.get(k).and_then(as_bool)` as `(found_bool, value)`; JSON object keys are unique.
pub fn lookup(obj: &[PermEntry], k: &[u8]) -> (bool, bool) {
    let mut i = 0;
    while i < obj.len() {
        if eq(&obj[i].key, k) {
            return (obj[i].is_bool, obj[i].value);
        }
        i += 1;
    }
    (false, false)
}

/// `format!("{kind}/{name}")` for a one-byte `kind`.
pub fn key_for(kind: u8, name: &[u8]) -> Vec<u8> {
    let mut out = Vec::new();
    out.push(kind);
    out.push(47);
    let mut i = 0;
    while i < name.len() {
        out.push(name[i]);
        i += 1;
    }
    out
}

/// `get_perm_in_extra_perms_for_authed(v, authed)`. `is_object` is whether `v` is a JSON
/// object; the result is `(is_some, value)`.
pub fn get_perm_in_extra_perms(is_object: bool, obj: &[PermEntry], a: &Authed) -> (bool, bool) {
    if !is_object {
        return (false, false);
    }
    let mut res_some = false;
    let mut res = false;
    let (f, v) = lookup(obj, &key_for(117, &a.username));
    if f {
        if v {
            return (true, true);
        }
        res_some = true;
        res = false;
    }
    let mut i = 0;
    while i < a.groups.len() {
        let (f, v) = lookup(obj, &key_for(103, &a.groups[i]));
        if f {
            if v {
                return (true, true);
            }
            res_some = true;
            res = false;
        }
        i += 1;
    }
    (res_some, res)
}

/// `is_instance_admin(authed)`.
pub fn is_instance_admin(a: &Authed) -> bool {
    a.is_admin && !a.has_job_id
}

/// `require_instance_admin(authed)`.
pub fn require_instance_admin(a: &Authed) -> Result<(), AuthzError> {
    if a.has_job_id {
        return Err(AuthzError::NotAuthorized);
    }
    if !a.is_admin {
        return Err(AuthzError::RequireAdmin);
    }
    Ok(())
}
