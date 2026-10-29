use oxicloud::domain::{services::authorization::Subject,entities::user::UserRole};
use oxicloud::common::errors::DomainError;
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum AuthzDenialVisibility {
    /// Caller has `Read` on the resource — 403 Forbidden.
    Visible,
    /// Caller has no `Read` — 404 anti-enum.
    Hidden,
}
impl AuthzDenialVisibility {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Visible => "visible",
            Self::Hidden => "hidden",
        }
    }
}
fn system_admin_denial_reason(
    subject: Subject,
    role: UserRole,
    is_external: bool,
    active: bool,
) -> Option<&'static str> {
    match subject {
        Subject::User(_) if !active => Some("inactive"),
        Subject::User(_) if is_external => Some("external_account"),
        // `at_least`, not `!=`: an admin gate must admit anything ranked
        // above admin too, or a more privileged role would be refused
        // admin surfaces it strictly outranks.
        Subject::User(_) if !role.at_least(UserRole::Admin) => Some("not_admin"),
        Subject::User(_) => None,
        _ => Some("unsupported_subject"),
    }
}
pub trait AuthorizationEngine {    fn require_system_admin(
        &self,
        subject: Subject,
        role: UserRole,
        is_external: bool,
        active: bool,
    ) -> Result<(), DomainError> {
        let reason = system_admin_denial_reason(subject, role, is_external, active);
        let Some(reason) = reason else {
            return Ok(());
        };

        tracing::info!(
            target: "audit",
            event = "authz.admin_denied",
            reason,
            subject_type = subject.type_str(),
            caller_id = %subject.id(),
            role = role.as_str(),
            is_external,
            active,
            "👮🏻‍♂️ system-administrator permission denied"
        );
        Err(DomainError::access_denied(
            "System",
            "Admin access required",
        ))
    }}
pub struct Oracle; impl AuthorizationEngine for Oracle {}
