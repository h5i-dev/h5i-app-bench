//! `crates/defguard_core/src/auth/mod.rs` (`SessionExtractor`, `SessionInfo`,
//! `role!`/`AdminRole`) and `handlers/mod.rs` (`user_for_admin_or_self`,
//! `device_for_admin_or_self`). Database lookups are inputs: the session row
//! the cookie names, the API token's user, the users with their groups.

/// `SessionState`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum SessionState {
    NotVerified,
    PasswordVerified,
    MultiFactorVerified,
    ApiTokenVerified,
}

/// The `session` row (`expires` in nanoseconds since the epoch, UTC).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Session {
    pub user_id: u64,
    pub state: SessionState,
    pub expires: i64,
}

/// A user with what the guards read: `mfa_enabled`, `is_active`, the names
/// of the groups it belongs to (`member_of`).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct User {
    pub id: u64,
    pub username: Vec<u8>,
    pub mfa_enabled: bool,
    pub is_active: bool,
    pub groups: Vec<Vec<u8>>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Device {
    pub id: u64,
    pub user_id: u64,
}

/// What the request presents.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Credential {
    /// `Authorization: Bearer`, with the user of the matching API token
    /// (`try_find_by_auth_token` joins `user.is_active`), or `None`.
    Bearer(Option<u64>),
    /// A session cookie, with the row it names, or `None`.
    Cookie(Option<Session>),
    Nothing,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AuthError {
    /// 401 "Invalid API token"
    InvalidApiToken,
    /// 401 "Session expired" (the row is deleted)
    SessionExpired,
    /// 401 "Session not found"
    SessionNotFound,
    /// 401 "Session is required"
    SessionRequired,
    /// 401 "User not found"
    UserNotFound,
    /// 401 "MFA not verified"
    MfaNotVerified,
    /// 403 "Token authentication is not allowed for normal users"
    TokenNotAllowed,
    /// 403 "user is disabled"
    UserDisabled,
    /// 403 "access denied" / "requires privileged access"
    Forbidden,
    /// 404 "... not found"
    NotFound,
}

/// `Session::expired`: `expires < now`.
pub fn expired(s: &Session, now: i64) -> bool {
    s.expires < now
}

/// `SessionExtractor::from_request_parts`. With a business licence, a bearer
/// header decides alone; otherwise only the cookie counts.
pub fn extract_session(license_active: bool, cred: &Credential, now: i64) -> Result<Session, AuthError> {
    match cred {
        Credential::Bearer(found) => {
            if license_active {
                match found {
                    Some(uid) => Ok(Session { user_id: *uid, state: SessionState::ApiTokenVerified, expires: now }),
                    None => Err(AuthError::InvalidApiToken),
                }
            } else {
                // The header is not read; there is no cookie.
                Err(AuthError::SessionRequired)
            }
        }
        Credential::Cookie(row) => match row {
            None => Err(AuthError::SessionNotFound),
            Some(s) => {
                if expired(s, now) {
                    Err(AuthError::SessionExpired)
                } else {
                    Ok(s.clone())
                }
            }
        },
        Credential::Nothing => Err(AuthError::SessionRequired),
    }
}

fn bytes_eq(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
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

fn contains_name(names: &Vec<Vec<u8>>, n: &[u8]) -> bool {
    let mut i = 0;
    while i < names.len() {
        if bytes_eq(&names[i], n) {
            return true;
        }
        i += 1;
    }
    false
}

/// `SessionInfo::contains_any_group`: a group of the user is named in `names`.
pub fn contains_any_group(u: &User, names: &Vec<Vec<u8>>) -> bool {
    let mut i = 0;
    while i < u.groups.len() {
        if contains_name(names, &u.groups[i]) {
            return true;
        }
        i += 1;
    }
    false
}

pub fn find_user(us: &Vec<User>, id: u64) -> Option<User> {
    let mut i = 0;
    while i < us.len() {
        if us[i].id == id {
            return Some(us[i].clone());
        }
        i += 1;
    }
    None
}

/// `SessionInfo`: the session's user, with `is_admin` (member of a group with
/// the `is_admin` flag; `admin_groups` are their names).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Info {
    pub session: Session,
    pub user: User,
    pub is_admin: bool,
}

/// `SessionInfo::from_request_parts`.
pub fn session_info(
    license_active: bool,
    cred: &Credential,
    us: &Vec<User>,
    admin_groups: &Vec<Vec<u8>>,
    now: i64,
) -> Result<Info, AuthError> {
    match extract_session(license_active, cred, now) {
        Err(e) => Err(e),
        Ok(s) => match find_user(us, s.user_id) {
            None => Err(AuthError::UserNotFound),
            Some(u) => {
                if u.mfa_enabled && s.state != SessionState::MultiFactorVerified && s.state != SessionState::ApiTokenVerified {
                    return Err(AuthError::MfaNotVerified);
                }
                let is_admin = contains_any_group(&u, admin_groups);
                if !is_admin && s.state == SessionState::ApiTokenVerified {
                    return Err(AuthError::TokenNotAllowed);
                }
                Ok(Info { session: s, user: u, is_admin })
            }
        },
    }
}

/// `AdminRole::from_request_parts` (`role!(AdminRole, Permission::IsAdmin)`).
pub fn admin_role(
    license_active: bool,
    cred: &Credential,
    us: &Vec<User>,
    admin_groups: &Vec<Vec<u8>>,
    now: i64,
) -> Result<Info, AuthError> {
    match session_info(license_active, cred, us, admin_groups, now) {
        Err(e) => Err(e),
        Ok(info) => {
            if !info.user.is_active {
                Err(AuthError::UserDisabled)
            } else if contains_any_group(&info.user, admin_groups) {
                Ok(info)
            } else {
                Err(AuthError::Forbidden)
            }
        }
    }
}

fn find_user_by_name(us: &Vec<User>, name: &[u8]) -> Option<User> {
    let mut i = 0;
    while i < us.len() {
        if bytes_eq(&us[i].username, name) {
            return Some(us[i].clone());
        }
        i += 1;
    }
    None
}

/// `user_for_admin_or_self`.
pub fn user_for_admin_or_self(info: &Info, us: &Vec<User>, username: &[u8]) -> Result<User, AuthError> {
    if bytes_eq(&info.user.username, username) || info.is_admin {
        match find_user_by_name(us, username) {
            Some(u) => Ok(u),
            None => Err(AuthError::NotFound),
        }
    } else {
        Err(AuthError::Forbidden)
    }
}

/// `device_for_admin_or_self`: an admin finds any device; anyone else only
/// their own (`find_by_id_and_username`), and another user's device is
/// "not found".
pub fn device_for_admin_or_self(info: &Info, ds: &Vec<Device>, id: u64) -> Result<Device, AuthError> {
    let mut i = 0;
    while i < ds.len() {
        if ds[i].id == id && (info.is_admin || ds[i].user_id == info.user.id) {
            return Ok(ds[i].clone());
        }
        i += 1;
    }
    Err(AuthError::NotFound)
}
