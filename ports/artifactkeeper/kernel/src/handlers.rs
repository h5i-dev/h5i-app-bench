//! Handler-side gates: the format-handler helpers of `api/middleware/auth.rs`
//! (`require_auth_basic`, `require_auth_basic_scope`, `require_scope_response`)
//! and `api/handlers/permissions.rs` `create_permission` up to its INSERT.
use crate::strs::bytes_eq;
use crate::tables::{Db, Permission, Query};
use crate::net::CidrRange;
use crate::trusted::Oracle;
use crate::permission::{validate_conditions, validate_principal};
use crate::resolve::Write;
use crate::{AppError, AuthExtension};

/// The `Response` of the format-handler helpers.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum GateError {
    /// 401 with `WWW-Authenticate: Basic realm=...`.
    Unauthorized,
    /// 403 "Token does not have required scope: ...".
    MissingScope,
}

/// `require_auth_basic`.
pub fn require_auth_basic(auth: &Option<AuthExtension>) -> Result<AuthExtension, GateError> {
    match auth {
        Some(ext) => Ok(ext.duplicate()),
        None => Err(GateError::Unauthorized),
    }
}

/// `require_auth_basic_scope`.
pub fn require_auth_basic_scope(auth: &Option<AuthExtension>, scope: &[u8]) -> Result<AuthExtension, GateError> {
    let ext = require_auth_basic(auth)?;
    if !ext.has_scope(scope) {
        return Err(GateError::MissingScope);
    }
    Ok(ext)
}

/// `require_scope_response`.
pub fn require_scope_response(auth: &Option<AuthExtension>, scope: &[u8]) -> Result<(), GateError> {
    if let Some(ext) = auth {
        if !ext.has_scope(scope) {
            return Err(GateError::MissingScope);
        }
    }
    Ok(())
}

/// `PermissionConditions`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Conditions {
    pub allowed_cidrs: Option<Vec<Vec<u8>>>,
}

/// `CreatePermissionRequest`, decoded.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct CreatePermissionRequest {
    pub principal_type: Vec<u8>,
    pub principal_id: u64,
    pub target_type: Vec<u8>,
    pub target_id: u64,
    pub actions: Vec<Vec<u8>>,
    pub conditions: Option<Conditions>,
}

/// `permissions.rs` `require_auth`.
pub fn require_auth(auth: &Option<AuthExtension>) -> Result<AuthExtension, AppError> {
    match auth {
        Some(ext) => Ok(ext.duplicate()),
        None => Err(AppError::Authentication),
    }
}

/// `actions.iter().any(|action| action != "read")`.
fn any_not_read(actions: &[Vec<u8>]) -> bool {
    let mut i = 0;
    while i < actions.len() {
        if !bytes_eq(&actions[i], b"read") {
            return true;
        }
        i += 1;
    }
    false
}

/// `validate_anonymous_rule`.
pub fn validate_anonymous_rule(payload: &CreatePermissionRequest) -> Result<(), AppError> {
    if !bytes_eq(&payload.principal_type, b"anonymous") {
        return Ok(());
    }
    if !bytes_eq(&payload.target_type, b"repository") && !bytes_eq(&payload.target_type, b"project") {
        return Err(AppError::Validation);
    }
    if any_not_read(&payload.actions) {
        return Err(AppError::Validation);
    }
    Ok(())
}

/// The ranges of validated `allowed_cidrs`, as the row stores them.
fn parse_cidrs(oracle: &Oracle, cidrs: &[Vec<u8>]) -> Vec<CidrRange> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < cidrs.len() {
        match CidrRange::parse(oracle, &cidrs[i]) {
            Ok(c) => out.push(c),
            Err(_) => {}
        }
        i += 1;
    }
    out
}

/// `UNIQUE(principal_type, principal_id, target_type, target_id)`.
fn duplicate(db: &Db, payload: &CreatePermissionRequest) -> bool {
    let mut i = 0;
    while i < db.permissions.len() {
        let p = &db.permissions[i];
        if bytes_eq(&p.principal_type, &payload.principal_type)
            && p.principal_id == payload.principal_id
            && bytes_eq(&p.target_type, &payload.target_type)
            && p.target_id == payload.target_id
        {
            return true;
        }
        i += 1;
    }
    false
}

/// `create_permission`: the gates, then the INSERT as a write. A
/// duplicate key is `Conflict` (`map_permission_write_error`).
pub fn create_permission(db: &Db, oracle: &Oracle, auth: &Option<AuthExtension>,
                         payload: &CreatePermissionRequest) -> (Vec<Write>, Result<(), AppError>) {
    let mut writes = Vec::new();
    let r = create_permission_gates(db, oracle, auth, payload);
    if let Err(e) = r {
        return (writes, Err(e));
    }
    if db.fails(Query::InsertPermission) {
        return (writes, Err(AppError::Database));
    }
    if duplicate(db, payload) {
        return (writes, Err(AppError::Conflict));
    }
    let allowed_cidrs = match &payload.conditions {
        Some(c) => match &c.allowed_cidrs {
            Some(cidrs) => Some(parse_cidrs(oracle, cidrs)),
            None => None,
        },
        None => None,
    };
    writes.push(Write::InsertPermission(Permission {
        principal_type: payload.principal_type.clone(),
        principal_id: payload.principal_id,
        target_type: payload.target_type.clone(),
        target_id: payload.target_id,
        actions: payload.actions.clone(),
        allowed_cidrs,
    }));
    (writes, Ok(()))
}

fn create_permission_gates(db: &Db, oracle: &Oracle, auth: &Option<AuthExtension>,
                           payload: &CreatePermissionRequest) -> Result<(), AppError> {
    let auth = require_auth(auth)?;
    auth.require_scope(b"write")?;
    auth.require_admin()?;
    validate_principal(db, &payload.principal_type, payload.principal_id)?;
    if let Some(conditions) = &payload.conditions {
        validate_conditions(oracle, &conditions.allowed_cidrs)?;
    }
    validate_anonymous_rule(payload)?;
    Ok(())
}
