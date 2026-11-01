#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Field {Name,Version,Compiler}
impl Field {
	fn label(self) -> &'static str {
		match self {
			| Self::Name => "name",
			| Self::Version => "version",
			| Self::Compiler => "compiler",
		}
	}
}
fn main(){
println!("label/Name\t{:?}",Field::Name.label().as_bytes());
println!("label/Version\t{:?}",Field::Version.label().as_bytes());
println!("label/Compiler\t{:?}",Field::Compiler.label().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(Field::Name.label().as_bytes(),tuwunel_kernel::finite_catalog::field_bea9b175::Field::Name.label(),"field_bea9b175/label/Name");
assert_eq!(Field::Version.label().as_bytes(),tuwunel_kernel::finite_catalog::field_bea9b175::Field::Version.label(),"field_bea9b175/label/Version");
assert_eq!(Field::Compiler.label().as_bytes(),tuwunel_kernel::finite_catalog::field_bea9b175::Field::Compiler.label(),"field_bea9b175/label/Compiler");
}
