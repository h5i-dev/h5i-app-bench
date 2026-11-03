#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum UnresolvedKind {Unparsed,MissingDependency,ConditionalNotInstalled,VirtualPackage,Ambiguous}
impl UnresolvedKind {
    /// Canonical identifier.
    pub fn as_str(self) -> &'static str {
        match self {
            UnresolvedKind::Unparsed => "unparsed",
            UnresolvedKind::MissingDependency => "missing_dependency",
            UnresolvedKind::ConditionalNotInstalled => "conditional_not_installed",
            UnresolvedKind::VirtualPackage => "virtual_package",
            UnresolvedKind::Ambiguous => "ambiguous",
        }
    }
    /// Whether this row means *we* did not understand the input, as opposed to
    /// understanding it and correctly producing no node.
    pub fn is_parse_failure(self) -> bool {
        matches!(self, UnresolvedKind::Unparsed)
    }
    /// Whether this row means the graph is missing something it should have.
    pub fn is_graph_gap(self) -> bool {
        matches!(
            self,
            UnresolvedKind::Unparsed
                | UnresolvedKind::MissingDependency
                | UnresolvedKind::Ambiguous
        )
    }
}
fn main(){
println!("as_str/Unparsed\t{:?}",UnresolvedKind::Unparsed.as_str().as_bytes());
println!("as_str/MissingDependency\t{:?}",UnresolvedKind::MissingDependency.as_str().as_bytes());
println!("as_str/ConditionalNotInstalled\t{:?}",UnresolvedKind::ConditionalNotInstalled.as_str().as_bytes());
println!("as_str/VirtualPackage\t{:?}",UnresolvedKind::VirtualPackage.as_str().as_bytes());
println!("as_str/Ambiguous\t{:?}",UnresolvedKind::Ambiguous.as_str().as_bytes());
println!("is_parse_failure/Unparsed\t{:?}",UnresolvedKind::Unparsed.is_parse_failure());
println!("is_parse_failure/MissingDependency\t{:?}",UnresolvedKind::MissingDependency.is_parse_failure());
println!("is_parse_failure/ConditionalNotInstalled\t{:?}",UnresolvedKind::ConditionalNotInstalled.is_parse_failure());
println!("is_parse_failure/VirtualPackage\t{:?}",UnresolvedKind::VirtualPackage.is_parse_failure());
println!("is_parse_failure/Ambiguous\t{:?}",UnresolvedKind::Ambiguous.is_parse_failure());
println!("is_graph_gap/Unparsed\t{:?}",UnresolvedKind::Unparsed.is_graph_gap());
println!("is_graph_gap/MissingDependency\t{:?}",UnresolvedKind::MissingDependency.is_graph_gap());
println!("is_graph_gap/ConditionalNotInstalled\t{:?}",UnresolvedKind::ConditionalNotInstalled.is_graph_gap());
println!("is_graph_gap/VirtualPackage\t{:?}",UnresolvedKind::VirtualPackage.is_graph_gap());
println!("is_graph_gap/Ambiguous\t{:?}",UnresolvedKind::Ambiguous.is_graph_gap());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(UnresolvedKind::Unparsed.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::unresolved_kind_99735155::UnresolvedKind::Unparsed.as_str(),"unresolved_kind_99735155/as_str/Unparsed");
assert_eq!(UnresolvedKind::MissingDependency.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::unresolved_kind_99735155::UnresolvedKind::MissingDependency.as_str(),"unresolved_kind_99735155/as_str/MissingDependency");
assert_eq!(UnresolvedKind::ConditionalNotInstalled.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::unresolved_kind_99735155::UnresolvedKind::ConditionalNotInstalled.as_str(),"unresolved_kind_99735155/as_str/ConditionalNotInstalled");
assert_eq!(UnresolvedKind::VirtualPackage.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::unresolved_kind_99735155::UnresolvedKind::VirtualPackage.as_str(),"unresolved_kind_99735155/as_str/VirtualPackage");
assert_eq!(UnresolvedKind::Ambiguous.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::unresolved_kind_99735155::UnresolvedKind::Ambiguous.as_str(),"unresolved_kind_99735155/as_str/Ambiguous");
assert_eq!(UnresolvedKind::Unparsed.is_parse_failure(),artifactkeeper_kernel::finite_catalog::unresolved_kind_99735155::UnresolvedKind::Unparsed.is_parse_failure(),"unresolved_kind_99735155/is_parse_failure/Unparsed");
assert_eq!(UnresolvedKind::MissingDependency.is_parse_failure(),artifactkeeper_kernel::finite_catalog::unresolved_kind_99735155::UnresolvedKind::MissingDependency.is_parse_failure(),"unresolved_kind_99735155/is_parse_failure/MissingDependency");
assert_eq!(UnresolvedKind::ConditionalNotInstalled.is_parse_failure(),artifactkeeper_kernel::finite_catalog::unresolved_kind_99735155::UnresolvedKind::ConditionalNotInstalled.is_parse_failure(),"unresolved_kind_99735155/is_parse_failure/ConditionalNotInstalled");
assert_eq!(UnresolvedKind::VirtualPackage.is_parse_failure(),artifactkeeper_kernel::finite_catalog::unresolved_kind_99735155::UnresolvedKind::VirtualPackage.is_parse_failure(),"unresolved_kind_99735155/is_parse_failure/VirtualPackage");
assert_eq!(UnresolvedKind::Ambiguous.is_parse_failure(),artifactkeeper_kernel::finite_catalog::unresolved_kind_99735155::UnresolvedKind::Ambiguous.is_parse_failure(),"unresolved_kind_99735155/is_parse_failure/Ambiguous");
assert_eq!(UnresolvedKind::Unparsed.is_graph_gap(),artifactkeeper_kernel::finite_catalog::unresolved_kind_99735155::UnresolvedKind::Unparsed.is_graph_gap(),"unresolved_kind_99735155/is_graph_gap/Unparsed");
assert_eq!(UnresolvedKind::MissingDependency.is_graph_gap(),artifactkeeper_kernel::finite_catalog::unresolved_kind_99735155::UnresolvedKind::MissingDependency.is_graph_gap(),"unresolved_kind_99735155/is_graph_gap/MissingDependency");
assert_eq!(UnresolvedKind::ConditionalNotInstalled.is_graph_gap(),artifactkeeper_kernel::finite_catalog::unresolved_kind_99735155::UnresolvedKind::ConditionalNotInstalled.is_graph_gap(),"unresolved_kind_99735155/is_graph_gap/ConditionalNotInstalled");
assert_eq!(UnresolvedKind::VirtualPackage.is_graph_gap(),artifactkeeper_kernel::finite_catalog::unresolved_kind_99735155::UnresolvedKind::VirtualPackage.is_graph_gap(),"unresolved_kind_99735155/is_graph_gap/VirtualPackage");
assert_eq!(UnresolvedKind::Ambiguous.is_graph_gap(),artifactkeeper_kernel::finite_catalog::unresolved_kind_99735155::UnresolvedKind::Ambiguous.is_graph_gap(),"unresolved_kind_99735155/is_graph_gap/Ambiguous");
}
