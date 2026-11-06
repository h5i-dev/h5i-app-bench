//! Copy the pinned upstream code into OUT_DIR, with the seams listed in
//! ../DEVIATIONS.md (clock reads become `crate::clock`, the one SQL UPDATE of
//! `Token::start_session` is dropped). Everything else is upstream text.
use std::{env, fs, path::PathBuf};

fn upstream(rel: &str) -> String {
    let root = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap()).join("../../../results/upstream/defguard");
    let p = root.join(rel);
    println!("cargo:rerun-if-changed={}", p.display());
    fs::read_to_string(&p).unwrap_or_else(|e| panic!("pinned upstream {}: {e}", p.display()))
}

fn replace_once(s: &str, from: &str, to: &str) -> String {
    assert_eq!(s.matches(from).count(), 1, "seam `{from}` must occur exactly once");
    s.replacen(from, to, 1)
}

fn main() {
    let out = PathBuf::from(env::var("OUT_DIR").unwrap());

    // auth/failed_login.rs, whole, with the clock as a seam.
    let fl = upstream("crates/defguard_core/src/auth/failed_login.rs");
    let fl = fl.replace("Local::now()", "crate::clock::now()");
    fs::write(out.join("failed_login.rs"), format!("use tracing::{{debug, info}};\n{fl}")).unwrap();

    // enterprise/utils.rs, whole (pure).
    let ut = upstream("crates/defguard_core/src/enterprise/utils.rs");
    let cut = ut.find("#[cfg(test)]").unwrap_or(ut.len());
    fs::write(out.join("utils.rs"), &ut[..cut]).unwrap();

    // db/models/enrollment.rs: the `Token` checks, from `is_expired` to `start_session`.
    let en = upstream("crates/defguard_core/src/db/models/enrollment.rs");
    let a = en.find("    // check if token has already expired").expect("is_expired");
    let b = en.find("    pub async fn find_by_id(pool: &PgPool, id: &str)").expect("find_by_id");
    let body = &en[a..b];
    let body = body.replace("Utc::now()", "crate::clock::utc_now()");
    let body = replace_once(
        &body,
        "                query!(\"UPDATE token SET used_at = $1 WHERE id = $2\", now, self.id)\n                    .execute(transaction)\n                    .await?;\n",
        "                let _ = transaction;\n",
    );
    fs::write(out.join("token_impl.rs"), format!("impl Token {{\n{body}}}\n")).unwrap();
}
