#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum SbomFormat {CycloneDX,SPDX}
impl SbomFormat {
    pub fn as_str(&self) -> &'static str {
        match self {
            SbomFormat::CycloneDX => "cyclonedx",
            SbomFormat::SPDX => "spdx",
        }
    }
    pub fn content_type(&self) -> &'static str {
        match self {
            SbomFormat::CycloneDX => "application/vnd.cyclonedx+json",
            SbomFormat::SPDX => "application/spdx+json",
        }
    }
}
fn main(){
println!("as_str/CycloneDX\t{:?}",SbomFormat::CycloneDX.as_str().as_bytes());
println!("as_str/SPDX\t{:?}",SbomFormat::SPDX.as_str().as_bytes());
println!("content_type/CycloneDX\t{:?}",SbomFormat::CycloneDX.content_type().as_bytes());
println!("content_type/SPDX\t{:?}",SbomFormat::SPDX.content_type().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(SbomFormat::CycloneDX.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::sbom_format_104be95e::SbomFormat::CycloneDX.as_str(),"sbom_format_104be95e/as_str/CycloneDX");
assert_eq!(SbomFormat::SPDX.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::sbom_format_104be95e::SbomFormat::SPDX.as_str(),"sbom_format_104be95e/as_str/SPDX");
assert_eq!(SbomFormat::CycloneDX.content_type().as_bytes(),artifactkeeper_kernel::finite_catalog::sbom_format_104be95e::SbomFormat::CycloneDX.content_type(),"sbom_format_104be95e/content_type/CycloneDX");
assert_eq!(SbomFormat::SPDX.content_type().as_bytes(),artifactkeeper_kernel::finite_catalog::sbom_format_104be95e::SbomFormat::SPDX.content_type(),"sbom_format_104be95e/content_type/SPDX");
}
