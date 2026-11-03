#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum VendoringTool {AuditWheel,Delocate,DelvEWheel}
impl VendoringTool {
    /// Stable lowercase wire form, used in `detection_method`.
    pub fn as_str(self) -> &'static str {
        match self {
            VendoringTool::AuditWheel => "auditwheel",
            VendoringTool::Delocate => "delocate",
            VendoringTool::DelvEWheel => "delvewheel",
        }
    }
}
fn main(){
println!("as_str/AuditWheel\t{:?}",VendoringTool::AuditWheel.as_str().as_bytes());
println!("as_str/Delocate\t{:?}",VendoringTool::Delocate.as_str().as_bytes());
println!("as_str/DelvEWheel\t{:?}",VendoringTool::DelvEWheel.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(VendoringTool::AuditWheel.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::vendoring_tool_8d235a49::VendoringTool::AuditWheel.as_str(),"vendoring_tool_8d235a49/as_str/AuditWheel");
assert_eq!(VendoringTool::Delocate.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::vendoring_tool_8d235a49::VendoringTool::Delocate.as_str(),"vendoring_tool_8d235a49/as_str/Delocate");
assert_eq!(VendoringTool::DelvEWheel.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::vendoring_tool_8d235a49::VendoringTool::DelvEWheel.as_str(),"vendoring_tool_8d235a49/as_str/DelvEWheel");
}
