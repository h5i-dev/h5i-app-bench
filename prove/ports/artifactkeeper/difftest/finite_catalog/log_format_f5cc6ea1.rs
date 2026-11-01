#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum LogFormat {Pretty,Json}
impl LogFormat {
    /// Canonical name, for the startup log line.
    fn name(self) -> &'static str {
        match self {
            Self::Pretty => "pretty",
            Self::Json => "json",
        }
    }
}
fn main(){
println!("name/Pretty\t{:?}",LogFormat::Pretty.name().as_bytes());
println!("name/Json\t{:?}",LogFormat::Json.name().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(LogFormat::Pretty.name().as_bytes(),artifactkeeper_kernel::finite_catalog::log_format_f5cc6ea1::LogFormat::Pretty.name(),"log_format_f5cc6ea1/name/Pretty");
assert_eq!(LogFormat::Json.name().as_bytes(),artifactkeeper_kernel::finite_catalog::log_format_f5cc6ea1::LogFormat::Json.name(),"log_format_f5cc6ea1/name/Json");
}
