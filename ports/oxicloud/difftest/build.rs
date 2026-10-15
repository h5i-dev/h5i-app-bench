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

}
