#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum EdgeKind {Runtime,Build,Dev,Optional,Peer,Constrains}
impl EdgeKind {
    /// Canonical identifier.
    pub fn as_str(self) -> &'static str {
        match self {
            EdgeKind::Runtime => "runtime",
            EdgeKind::Build => "build",
            EdgeKind::Dev => "dev",
            EdgeKind::Optional => "optional",
            EdgeKind::Peer => "peer",
            EdgeKind::Constrains => "constrains",
        }
    }
}
fn main(){
println!("as_str/Runtime\t{:?}",EdgeKind::Runtime.as_str().as_bytes());
println!("as_str/Build\t{:?}",EdgeKind::Build.as_str().as_bytes());
println!("as_str/Dev\t{:?}",EdgeKind::Dev.as_str().as_bytes());
println!("as_str/Optional\t{:?}",EdgeKind::Optional.as_str().as_bytes());
println!("as_str/Peer\t{:?}",EdgeKind::Peer.as_str().as_bytes());
println!("as_str/Constrains\t{:?}",EdgeKind::Constrains.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(EdgeKind::Runtime.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::edge_kind_99735155::EdgeKind::Runtime.as_str(),"edge_kind_99735155/as_str/Runtime");
assert_eq!(EdgeKind::Build.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::edge_kind_99735155::EdgeKind::Build.as_str(),"edge_kind_99735155/as_str/Build");
assert_eq!(EdgeKind::Dev.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::edge_kind_99735155::EdgeKind::Dev.as_str(),"edge_kind_99735155/as_str/Dev");
assert_eq!(EdgeKind::Optional.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::edge_kind_99735155::EdgeKind::Optional.as_str(),"edge_kind_99735155/as_str/Optional");
assert_eq!(EdgeKind::Peer.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::edge_kind_99735155::EdgeKind::Peer.as_str(),"edge_kind_99735155/as_str/Peer");
assert_eq!(EdgeKind::Constrains.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::edge_kind_99735155::EdgeKind::Constrains.as_str(),"edge_kind_99735155/as_str/Constrains");
}
