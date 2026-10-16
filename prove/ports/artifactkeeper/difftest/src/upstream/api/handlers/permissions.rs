// Copied from artifact-keeper/artifact-keeper @ 7c42891 by extract_upstream.py. Do not edit.
use serde::Deserialize;
use utoipa::ToSchema;
use uuid::Uuid;

use crate::api::middleware::auth::AuthExtension;
use crate::error::{AppError, Result};

/// Require that the request is authenticated, returning an error if not.
fn require_auth(auth: Option<AuthExtension>) -> Result<AuthExtension> {
    auth.ok_or_else(|| AppError::Authentication("Authentication required".to_string()))
}
#[derive(Debug, Deserialize, ToSchema)]
pub struct CreatePermissionRequest {
    pub principal_type: String,
    pub principal_id: Uuid,
    pub target_type: String,
    pub target_id: Uuid,
    pub actions: Vec<String>,
    /// Optional rule conditions (#1849). `{"allowed_cidrs": ["10.0.0.0/8"]}`
    /// restricts the grant to requests whose client IP falls inside one of
    /// the CIDR ranges; omit for an unconditional grant.
    pub conditions: Option<crate::services::permission_service::PermissionConditions>,
}
/// Write-time guard for the anonymous principal (#1849): anonymous rules are
/// the anonymous-download grant, so they may only carry `read`, only on a
/// `repository` or `project` target. Anything else would be inert (no gate
/// evaluates it) or misleading, so reject it instead of persisting a rule
/// that looks like it does something it does not.
fn validate_anonymous_rule(payload: &CreatePermissionRequest) -> Result<()> {
    if payload.principal_type != crate::services::permission_service::ANONYMOUS_PRINCIPAL_TYPE {
        return Ok(());
    }
    if payload.target_type != "repository" && payload.target_type != "project" {
        return Err(AppError::Validation(format!(
            "anonymous rules only apply to 'repository' or 'project' targets, \
             got '{}'",
            payload.target_type
        )));
    }
    if payload.actions.iter().any(|action| action != "read") {
        return Err(AppError::Validation(
            "anonymous rules may only grant the 'read' action: anonymous access is a \
             download grant and never confers write, delete, or admin"
                .to_string(),
        ));
    }
    Ok(())
}

// Appended by extract_upstream.py: private items for the tests.
#[cfg(test)]
#[path = "../../../probes/permissions.rs"]
pub(crate) mod probe;
