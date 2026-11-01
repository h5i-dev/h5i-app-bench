#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum FlatKeyWriteClaim {NotApplicable,Claimed,AlreadyOwned}
impl FlatKeyWriteClaim {
    /// True when this outcome represents a claim row freshly inserted by the
    /// current request that must be rolled back if the gated write fails.
    pub fn needs_release_on_failure(self) -> bool {
        matches!(self, FlatKeyWriteClaim::Claimed)
    }
}
fn main(){
println!("needs_release_on_failure/NotApplicable\t{:?}",FlatKeyWriteClaim::NotApplicable.needs_release_on_failure());
println!("needs_release_on_failure/Claimed\t{:?}",FlatKeyWriteClaim::Claimed.needs_release_on_failure());
println!("needs_release_on_failure/AlreadyOwned\t{:?}",FlatKeyWriteClaim::AlreadyOwned.needs_release_on_failure());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(FlatKeyWriteClaim::NotApplicable.needs_release_on_failure(),artifactkeeper_kernel::finite_catalog::flat_key_write_claim_6572c2eb::FlatKeyWriteClaim::NotApplicable.needs_release_on_failure(),"flat_key_write_claim_6572c2eb/needs_release_on_failure/NotApplicable");
assert_eq!(FlatKeyWriteClaim::Claimed.needs_release_on_failure(),artifactkeeper_kernel::finite_catalog::flat_key_write_claim_6572c2eb::FlatKeyWriteClaim::Claimed.needs_release_on_failure(),"flat_key_write_claim_6572c2eb/needs_release_on_failure/Claimed");
assert_eq!(FlatKeyWriteClaim::AlreadyOwned.needs_release_on_failure(),artifactkeeper_kernel::finite_catalog::flat_key_write_claim_6572c2eb::FlatKeyWriteClaim::AlreadyOwned.needs_release_on_failure(),"flat_key_write_claim_6572c2eb/needs_release_on_failure/AlreadyOwned");
}
