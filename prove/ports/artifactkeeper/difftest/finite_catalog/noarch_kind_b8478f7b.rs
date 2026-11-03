#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum NoarchKind {Python,Generic}
impl NoarchKind {
    pub fn as_str(&self) -> &'static str {
        match self {
            NoarchKind::Python => "python",
            NoarchKind::Generic => "generic",
        }
    }
}
fn main(){
println!("as_str/Python\t{:?}",NoarchKind::Python.as_str().as_bytes());
println!("as_str/Generic\t{:?}",NoarchKind::Generic.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(NoarchKind::Python.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::noarch_kind_b8478f7b::NoarchKind::Python.as_str(),"noarch_kind_b8478f7b/as_str/Python");
assert_eq!(NoarchKind::Generic.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::noarch_kind_b8478f7b::NoarchKind::Generic.as_str(),"noarch_kind_b8478f7b/as_str/Generic");
}
