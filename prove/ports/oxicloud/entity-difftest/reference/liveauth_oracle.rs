use oxicloud::domain::{entities::user::{UserFlags,UserRole},errors::{DomainError,ErrorKind}}; use oxicloud::interfaces::{errors::AppError,middleware::user::LiveRole}; use uuid::Uuid;use http::StatusCode;use smol_str::SmolStr;
fn decide_internal_user(
    flags: Result<UserFlags, DomainError>,
    caller_id: Uuid,
) -> Result<(), AppError> {
    match flags {
        Ok(flags) if flags.is_external => Err(AppError::new(
            StatusCode::FORBIDDEN,
            "External users cannot access this endpoint",
            "Forbidden",
        )),
        Ok(_) => Ok(()),
        // A caller with NO user row lands here. The arm used to be a blanket
        // `_ => Ok(())`, i.e. fail-OPEN: any lookup failure — including
        // `NotFound` — admitted the caller. This is the only middleware
        // guarding `/webdav`, `/caldav` and `/carddav`, so a principal
        // without an `auth.users` row (an anonymous share session) walked
        // straight through the "internal users only" gate.
        //
        // `NotFound` is now a denial. Other errors (a DB blip) stay open
        // deliberately: this gate is a *restriction* on external users, not
        // the authentication check, and failing every DAV request closed
        // during a transient database hiccup trades one outage for a worse
        // one. The authentication decision above it is what must fail
        // closed, and does.
        Err(e) if matches!(e.kind, ErrorKind::NotFound) => {
            tracing::info!(
                target: "audit",
                event = "authz.denied",
                reason = "no_user_row",
                caller_id = %caller_id,
                "👮🏻‍♂️ principal has no user record — refused an internal-user endpoint",
            );
            Err(AppError::new(
                StatusCode::FORBIDDEN,
                "This endpoint requires a user account",
                "Forbidden",
            ))
        }
        Err(_) => Ok(()),
    }
}
fn anonymous_live_role(claim_role: &str) -> Option<LiveRole> {
    UserRole::from_session(claim_role)
        .filter(|r| r.is_anonymous())
        .map(|r| LiveRole::Active(SmolStr::new_static(r.as_str())))
}
fn decide_live_role(
    flags: Result<UserFlags, DomainError>,
    user_id: Uuid,
    claim_role: &str,
) -> LiveRole {
    match flags {
        Ok(flags) if flags.active => LiveRole::Active(SmolStr::new_static(flags.role.as_str())),
        Ok(_) => {
            audit_token_revoked(user_id, "deactivated");
            LiveRole::Revoked
        }
        // The user row is gone — a definitive revocation; fail closed.
        Err(e) if matches!(e.kind, ErrorKind::NotFound) => {
            audit_token_revoked(user_id, "deleted");
            LiveRole::Revoked
        }
        // Transient lookup failure (DB blip): fail open on the claim role so
        // a momentary outage doesn't 401 every authenticated user at once.
        Err(e) => {
            tracing::warn!(
                user_id = %user_id,
                error = %e,
                "live-user re-check failed transiently; allowing request on the JWT claim role (fail-open)"
            );
            LiveRole::Active(SmolStr::new(claim_role))
        }
    }
}
fn audit_token_revoked(user_id: Uuid, reason: &'static str) {
    tracing::info!(
        target: "audit",
        event = "auth.token_revoked",
        reason = reason,
        caller_id = %user_id,
        "👮🏻‍♂️ valid token presented for an account that is no longer active — rejected"
    );
}
pub fn internal(f:Result<UserFlags,DomainError>,id:Uuid)->Result<(),AppError>{decide_internal_user(f,id)}
pub fn anonymous(s:&str)->Option<LiveRole>{anonymous_live_role(s)}
pub fn live(f:Result<UserFlags,DomainError>,id:Uuid,s:&str)->LiveRole{decide_live_role(f,id,s)}
