#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ProgressKind {Count,Approximate}
impl ProgressKind {
    pub fn as_str(self) -> &'static str {
        match self {
            ProgressKind::Count => "count",
            ProgressKind::Approximate => "approximate",
        }
    }
}
fn main(){
println!("as_str/Count\t{:?}",ProgressKind::Count.as_str().as_bytes());
println!("as_str/Approximate\t{:?}",ProgressKind::Approximate.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(ProgressKind::Count.as_str().as_bytes(),oxicloud_kernel::finite_catalog::progress_kind_dbd87cc3::ProgressKind::Count.as_str(),"progress_kind_dbd87cc3/as_str/Count");
assert_eq!(ProgressKind::Approximate.as_str().as_bytes(),oxicloud_kernel::finite_catalog::progress_kind_dbd87cc3::ProgressKind::Approximate.as_str(),"progress_kind_dbd87cc3/as_str/Approximate");
}
