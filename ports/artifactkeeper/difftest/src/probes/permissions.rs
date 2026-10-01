//! Private items of `api/handlers/permissions.rs` for the tests.
use super::*;

pub(crate) fn require_auth(a: Option<AuthExtension>) -> Result<AuthExtension> {
    super::require_auth(a)
}
pub(crate) fn validate_anonymous_rule(p: &CreatePermissionRequest) -> Result<()> {
    super::validate_anonymous_rule(p)
}
