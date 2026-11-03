#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Phase {Derived,Attached}
impl Phase {
    fn as_str(self) -> &'static str {
        match self {
            Phase::Derived => "derived",
            Phase::Attached => "attached",
        }
    }
}
fn main(){
println!("as_str/Derived\t{:?}",Phase::Derived.as_str().as_bytes());
println!("as_str/Attached\t{:?}",Phase::Attached.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(Phase::Derived.as_str().as_bytes(),oxicloud_kernel::finite_catalog::phase_ce65bf5b::Phase::Derived.as_str(),"phase_ce65bf5b/as_str/Derived");
assert_eq!(Phase::Attached.as_str().as_bytes(),oxicloud_kernel::finite_catalog::phase_ce65bf5b::Phase::Attached.as_str(),"phase_ce65bf5b/as_str/Attached");
}
