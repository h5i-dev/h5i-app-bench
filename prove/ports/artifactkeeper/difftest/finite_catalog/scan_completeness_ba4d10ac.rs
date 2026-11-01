#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ScanCompleteness {Complete,Partial,NotCataloged}
impl ScanCompleteness {
    /// Stable lowercase form used by the `scan_completeness` CHECK
    /// constraint (migration 090, widened by migration 223) and by the
    /// SBOM document JSON field.
    pub fn as_str(self) -> &'static str {
        match self {
            ScanCompleteness::Complete => "complete",
            ScanCompleteness::Partial => "partial",
            ScanCompleteness::NotCataloged => "not_cataloged",
        }
    }
}
fn main(){
println!("as_str/Complete\t{:?}",ScanCompleteness::Complete.as_str().as_bytes());
println!("as_str/Partial\t{:?}",ScanCompleteness::Partial.as_str().as_bytes());
println!("as_str/NotCataloged\t{:?}",ScanCompleteness::NotCataloged.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(ScanCompleteness::Complete.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::scan_completeness_ba4d10ac::ScanCompleteness::Complete.as_str(),"scan_completeness_ba4d10ac/as_str/Complete");
assert_eq!(ScanCompleteness::Partial.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::scan_completeness_ba4d10ac::ScanCompleteness::Partial.as_str(),"scan_completeness_ba4d10ac/as_str/Partial");
assert_eq!(ScanCompleteness::NotCataloged.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::scan_completeness_ba4d10ac::ScanCompleteness::NotCataloged.as_str(),"scan_completeness_ba4d10ac/as_str/NotCataloged");
}
