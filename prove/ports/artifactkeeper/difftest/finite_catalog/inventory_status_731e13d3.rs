#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum InventoryStatus {Complete,Partial,Failed}
impl InventoryStatus {
    pub fn as_db_str(self) -> &'static str {
        match self {
            InventoryStatus::Complete => "complete",
            InventoryStatus::Partial => "partial",
            InventoryStatus::Failed => "failed",
        }
    }
}
fn main(){
println!("as_db_str/Complete\t{:?}",InventoryStatus::Complete.as_db_str().as_bytes());
println!("as_db_str/Partial\t{:?}",InventoryStatus::Partial.as_db_str().as_bytes());
println!("as_db_str/Failed\t{:?}",InventoryStatus::Failed.as_db_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(InventoryStatus::Complete.as_db_str().as_bytes(),artifactkeeper_kernel::finite_catalog::inventory_status_731e13d3::InventoryStatus::Complete.as_db_str(),"inventory_status_731e13d3/as_db_str/Complete");
assert_eq!(InventoryStatus::Partial.as_db_str().as_bytes(),artifactkeeper_kernel::finite_catalog::inventory_status_731e13d3::InventoryStatus::Partial.as_db_str(),"inventory_status_731e13d3/as_db_str/Partial");
assert_eq!(InventoryStatus::Failed.as_db_str().as_bytes(),artifactkeeper_kernel::finite_catalog::inventory_status_731e13d3::InventoryStatus::Failed.as_db_str(),"inventory_status_731e13d3/as_db_str/Failed");
}
