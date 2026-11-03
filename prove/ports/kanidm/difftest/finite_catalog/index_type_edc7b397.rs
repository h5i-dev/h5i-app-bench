#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum IndexType {Equality,Presence,SubString,Ordering}
impl IndexType {
    pub fn as_idx_str(&self) -> &str {
        match self {
            IndexType::Equality => "eq",
            IndexType::Presence => "pres",
            IndexType::SubString => "sub",
            IndexType::Ordering => "ord",
        }
    }
}
fn main(){
println!("as_idx_str/Equality\t{:?}",IndexType::Equality.as_idx_str().as_bytes());
println!("as_idx_str/Presence\t{:?}",IndexType::Presence.as_idx_str().as_bytes());
println!("as_idx_str/SubString\t{:?}",IndexType::SubString.as_idx_str().as_bytes());
println!("as_idx_str/Ordering\t{:?}",IndexType::Ordering.as_idx_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(IndexType::Equality.as_idx_str().as_bytes(),kanidm_kernel::finite_catalog::index_type_edc7b397::IndexType::Equality.as_idx_str(),"index_type_edc7b397/as_idx_str/Equality");
assert_eq!(IndexType::Presence.as_idx_str().as_bytes(),kanidm_kernel::finite_catalog::index_type_edc7b397::IndexType::Presence.as_idx_str(),"index_type_edc7b397/as_idx_str/Presence");
assert_eq!(IndexType::SubString.as_idx_str().as_bytes(),kanidm_kernel::finite_catalog::index_type_edc7b397::IndexType::SubString.as_idx_str(),"index_type_edc7b397/as_idx_str/SubString");
assert_eq!(IndexType::Ordering.as_idx_str().as_bytes(),kanidm_kernel::finite_catalog::index_type_edc7b397::IndexType::Ordering.as_idx_str(),"index_type_edc7b397/as_idx_str/Ordering");
}
