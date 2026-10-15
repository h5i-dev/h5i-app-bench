//! Compile verbatim private pure functions from the pinned upstream into a test oracle.
use std::{env, fs, path::PathBuf};
fn item(source: &str, declaration: &str) -> String {
    let start = source.find(declaration).expect("pinned declaration");
    let open = start + source[start..].find('{').unwrap();
    let mut depth = 0;
    for (offset, byte) in source.as_bytes()[open..].iter().enumerate() {
        if *byte == b'{' { depth += 1; }
        if *byte == b'}' {
            depth -= 1;
            if depth == 0 { return source[start..=open+offset].to_owned(); }
        }
    }
    panic!("unterminated pinned item")
}
fn main() {
    let path = "../upstream-src/src/application/services/auth_application_service.rs";
    println!("cargo:rerun-if-changed={path}");
    let source = fs::read_to_string(path).unwrap();
    let mut oracle = item(&source, "struct EmailVerificationDecision {");
    oracle.push_str(&item(&source, "fn classify_email_verification("));
    oracle.push_str(&item(&source, "fn validate_dpop_jkt("));
    oracle.push_str(r#"
        pub fn email(claim: Option<bool>, required: bool) -> (bool, Option<&'static str>) {
            let decision = classify_email_verification(claim, required);
            (decision.reject, decision.reason)
        }
        pub fn jkt(raw: &str) -> Result<String, &'static str> { validate_dpop_jkt(raw) }
    "#);
    fs::write(PathBuf::from(env::var_os("OUT_DIR").unwrap()).join("auth_oracle.rs"), oracle).unwrap();
    let path = "../upstream-src/src/domain/entities/magic_link_token.rs";
    println!("cargo:rerun-if-changed={path}");
    let source = fs::read_to_string(path).unwrap();
    let mut oracle = String::from("use chrono::{DateTime, Utc}; use oxicloud::domain::entities::magic_link_token::MagicLinkStatus; pub struct Snapshot { pub expires_at: DateTime<Utc>, pub status: MagicLinkStatus } impl Snapshot {");
    // Preserve the pinned methods, substituting the clock input for deterministic boundary tests.
    for name in ["is_expired", "is_redeemable"] {
        let method = item(&source, &format!("pub fn {name}(&self)"));
        let method = method.replace("(&self)", "(&self, now: DateTime<Utc>)")
            .replace("Utc::now()", "now").replace("self.is_expired()", "self.is_expired(now)");
        oracle.push_str(&method);
    }
    oracle.push('}');
    fs::write(PathBuf::from(env::var_os("OUT_DIR").unwrap()).join("magic_oracle.rs"), oracle).unwrap();

    let path = "../upstream-src/src/application/ports/authorization_ports.rs";
    println!("cargo:rerun-if-changed={path}");
    let source = fs::read_to_string(path).unwrap();
    let mut oracle = String::from("use oxicloud::domain::{services::authorization::Subject, entities::user::UserRole};");
    oracle.push_str(&item(&source, "fn system_admin_denial_reason("));
    oracle.push_str("pub fn reason(s: Subject, r: UserRole, e: bool, a: bool) -> Option<&'static str> { system_admin_denial_reason(s,r,e,a) }");
    fs::write(PathBuf::from(env::var_os("OUT_DIR").unwrap()).join("admin_oracle.rs"), oracle).unwrap();
    let path = "../upstream-src/src/interfaces/middleware/user.rs";
    println!("cargo:rerun-if-changed={path}");
    let source = fs::read_to_string(path).unwrap();
    let mut oracle = String::from(r#"
      use oxicloud::domain::{entities::user::{UserFlags,UserRole},errors::{DomainError,ErrorKind}};
      use oxicloud::interfaces::{errors::AppError,middleware::user::LiveRole};
      use uuid::Uuid;
      macro_rules! ignored_event { ($($tt:tt)*) => {} }
      mod tracing { pub(crate) use ignored_event as info; pub(crate) use ignored_event as warn; }
      fn audit_token_revoked(_: Uuid, _: &'static str) {}
    "#);
    for name in ["decide_internal_user", "anonymous_live_role", "decide_live_role"] {
        let function=item(&source,&format!("fn {name}("))
            .replace("StatusCode::FORBIDDEN","403u16.try_into().unwrap()")
            .replace("SmolStr::new_static(r.as_str())","r.as_str().into()")
            .replace("SmolStr::new_static(flags.role.as_str())","flags.role.as_str().into()")
            .replace("SmolStr::new(claim_role)","claim_role.into()");
        oracle.push_str(&function);
    }
    oracle.push_str(r#"
      pub fn internal(f: Result<UserFlags,DomainError>, id: Uuid)->Result<(),AppError> { decide_internal_user(f,id) }
      pub fn anonymous(s: &str)->Option<LiveRole> { anonymous_live_role(s) }
      pub fn live(f: Result<UserFlags,DomainError>, id: Uuid, s: &str)->LiveRole { decide_live_role(f,id,s) }
    "#);
    fs::write(PathBuf::from(env::var_os("OUT_DIR").unwrap()).join("liveauth_oracle.rs"), oracle).unwrap();

}
