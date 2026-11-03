#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Ecosystem {Conda,PyPi,Npm,Cargo}
impl Ecosystem {
    /// Canonical identifier, matching the purl type where one exists.
    pub fn as_str(self) -> &'static str {
        match self {
            Ecosystem::Conda => "conda",
            Ecosystem::PyPi => "pypi",
            Ecosystem::Npm => "npm",
            Ecosystem::Cargo => "cargo",
        }
    }
}
fn main(){
println!("as_str/Conda\t{:?}",Ecosystem::Conda.as_str().as_bytes());
println!("as_str/PyPi\t{:?}",Ecosystem::PyPi.as_str().as_bytes());
println!("as_str/Npm\t{:?}",Ecosystem::Npm.as_str().as_bytes());
println!("as_str/Cargo\t{:?}",Ecosystem::Cargo.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(Ecosystem::Conda.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::ecosystem_99735155::Ecosystem::Conda.as_str(),"ecosystem_99735155/as_str/Conda");
assert_eq!(Ecosystem::PyPi.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::ecosystem_99735155::Ecosystem::PyPi.as_str(),"ecosystem_99735155/as_str/PyPi");
assert_eq!(Ecosystem::Npm.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::ecosystem_99735155::Ecosystem::Npm.as_str(),"ecosystem_99735155/as_str/Npm");
assert_eq!(Ecosystem::Cargo.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::ecosystem_99735155::Ecosystem::Cargo.as_str(),"ecosystem_99735155/as_str/Cargo");
}
