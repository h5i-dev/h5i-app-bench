#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum DedupScope {PerRepo,Instance}
impl DedupScope {
    /// The `dedup_scope` label persisted alongside the stats so consumers know
    /// which backend semantics produced the numbers.
    pub fn as_str(self) -> &'static str {
        match self {
            DedupScope::PerRepo => "per_repo",
            DedupScope::Instance => "instance",
        }
    }
}
fn main(){
println!("as_str/PerRepo\t{:?}",DedupScope::PerRepo.as_str().as_bytes());
println!("as_str/Instance\t{:?}",DedupScope::Instance.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(DedupScope::PerRepo.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::dedup_scope_78b2cf8c::DedupScope::PerRepo.as_str(),"dedup_scope_78b2cf8c/as_str/PerRepo");
assert_eq!(DedupScope::Instance.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::dedup_scope_78b2cf8c::DedupScope::Instance.as_str(),"dedup_scope_78b2cf8c/as_str/Instance");
}
