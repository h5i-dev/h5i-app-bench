#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum AuditStreamMode {Off,Stdout}
impl AuditStreamMode {
    /// Canonical name, for the startup log line.
    pub fn name(self) -> &'static str {
        match self {
            Self::Off => "off",
            Self::Stdout => "stdout",
        }
    }
}
fn main(){
println!("name/Off\t{:?}",AuditStreamMode::Off.name().as_bytes());
println!("name/Stdout\t{:?}",AuditStreamMode::Stdout.name().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(AuditStreamMode::Off.name().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_stream_mode_8053ef47::AuditStreamMode::Off.name(),"audit_stream_mode_8053ef47/name/Off");
assert_eq!(AuditStreamMode::Stdout.name().as_bytes(),artifactkeeper_kernel::finite_catalog::audit_stream_mode_8053ef47::AuditStreamMode::Stdout.name(),"audit_stream_mode_8053ef47/name/Stdout");
}
