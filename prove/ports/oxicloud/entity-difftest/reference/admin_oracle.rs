use oxicloud::domain::{services::authorization::Subject,entities::user::UserRole};
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
pub fn reason(s:Subject,r:UserRole,e:bool,a:bool)->Option<&'static str>{system_admin_denial_reason(s,r,e,a)}
