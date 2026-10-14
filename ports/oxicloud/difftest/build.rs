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
}
