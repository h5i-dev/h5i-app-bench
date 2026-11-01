#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum InventoryCompleteness {Complete,Declared,Partial,None}
impl InventoryCompleteness {
    /// String form embedded in the SBOM document.
    pub fn as_str(self) -> &'static str {
        match self {
            InventoryCompleteness::Complete => "complete",
            InventoryCompleteness::Declared => "declared",
            InventoryCompleteness::Partial => "partial",
            InventoryCompleteness::None => "none",
        }
    }
}
fn main(){
println!("as_str/Complete\t{:?}",InventoryCompleteness::Complete.as_str().as_bytes());
println!("as_str/Declared\t{:?}",InventoryCompleteness::Declared.as_str().as_bytes());
println!("as_str/Partial\t{:?}",InventoryCompleteness::Partial.as_str().as_bytes());
println!("as_str/None\t{:?}",InventoryCompleteness::None.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(InventoryCompleteness::Complete.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::inventory_completeness_0e70a8c0::InventoryCompleteness::Complete.as_str(),"inventory_completeness_0e70a8c0/as_str/Complete");
assert_eq!(InventoryCompleteness::Declared.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::inventory_completeness_0e70a8c0::InventoryCompleteness::Declared.as_str(),"inventory_completeness_0e70a8c0/as_str/Declared");
assert_eq!(InventoryCompleteness::Partial.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::inventory_completeness_0e70a8c0::InventoryCompleteness::Partial.as_str(),"inventory_completeness_0e70a8c0/as_str/Partial");
assert_eq!(InventoryCompleteness::None.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::inventory_completeness_0e70a8c0::InventoryCompleteness::None.as_str(),"inventory_completeness_0e70a8c0/as_str/None");
}
