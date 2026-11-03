#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum OciCleanupKeyFamily {Pending,Unreferenced}
impl OciCleanupKeyFamily {
    /// Family live-session guard over aliases `s` (sessions) and `c`.
    /// Pending keys are also anchored to their own session id; committed
    /// (part/final/completion temp) keys are intentionally reapable even
    /// while their session lives — see the SELECT-side comments.
    fn session_predicate_sql(self) -> &'static str {
        match self {
            OciCleanupKeyFamily::Pending => {
                "s.id = c.upload_session_id\n                       OR s.storage_temp_key = c.storage_key"
            }
            OciCleanupKeyFamily::Unreferenced => "s.storage_temp_key = c.storage_key",
        }
    }
}
fn main(){
println!("session_predicate_sql/Pending\t{:?}",OciCleanupKeyFamily::Pending.session_predicate_sql().as_bytes());
println!("session_predicate_sql/Unreferenced\t{:?}",OciCleanupKeyFamily::Unreferenced.session_predicate_sql().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(OciCleanupKeyFamily::Pending.session_predicate_sql().as_bytes(),artifactkeeper_kernel::finite_catalog::oci_cleanup_key_family_c9cc8f67::OciCleanupKeyFamily::Pending.session_predicate_sql(),"oci_cleanup_key_family_c9cc8f67/session_predicate_sql/Pending");
assert_eq!(OciCleanupKeyFamily::Unreferenced.session_predicate_sql().as_bytes(),artifactkeeper_kernel::finite_catalog::oci_cleanup_key_family_c9cc8f67::OciCleanupKeyFamily::Unreferenced.session_predicate_sql(),"oci_cleanup_key_family_c9cc8f67/session_predicate_sql/Unreferenced");
}
