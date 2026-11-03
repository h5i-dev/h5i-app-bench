#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Fallback {Absent,Ceiling,AuthMissing,AllCommitted,Entries,Canary,CreateMismatch,Unevaluable,Error}
impl Fallback {
	fn name(self) -> &'static str {
		match self {
			| Self::Absent => "absent",
			| Self::Ceiling => "ceiling",
			| Self::AuthMissing => "auth_missing",
			| Self::AllCommitted => "all_committed",
			| Self::Entries => "entries",
			| Self::Canary => "canary",
			| Self::CreateMismatch => "create_mismatch",
			| Self::Unevaluable => "unevaluable",
			| Self::Error => "error",
		}
	}
}
fn main(){
println!("name/Absent\t{:?}",Fallback::Absent.name().as_bytes());
println!("name/Ceiling\t{:?}",Fallback::Ceiling.name().as_bytes());
println!("name/AuthMissing\t{:?}",Fallback::AuthMissing.name().as_bytes());
println!("name/AllCommitted\t{:?}",Fallback::AllCommitted.name().as_bytes());
println!("name/Entries\t{:?}",Fallback::Entries.name().as_bytes());
println!("name/Canary\t{:?}",Fallback::Canary.name().as_bytes());
println!("name/CreateMismatch\t{:?}",Fallback::CreateMismatch.name().as_bytes());
println!("name/Unevaluable\t{:?}",Fallback::Unevaluable.name().as_bytes());
println!("name/Error\t{:?}",Fallback::Error.name().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(Fallback::Absent.name().as_bytes(),tuwunel_kernel::finite_catalog::fallback_08cb57a8::Fallback::Absent.name(),"fallback_08cb57a8/name/Absent");
assert_eq!(Fallback::Ceiling.name().as_bytes(),tuwunel_kernel::finite_catalog::fallback_08cb57a8::Fallback::Ceiling.name(),"fallback_08cb57a8/name/Ceiling");
assert_eq!(Fallback::AuthMissing.name().as_bytes(),tuwunel_kernel::finite_catalog::fallback_08cb57a8::Fallback::AuthMissing.name(),"fallback_08cb57a8/name/AuthMissing");
assert_eq!(Fallback::AllCommitted.name().as_bytes(),tuwunel_kernel::finite_catalog::fallback_08cb57a8::Fallback::AllCommitted.name(),"fallback_08cb57a8/name/AllCommitted");
assert_eq!(Fallback::Entries.name().as_bytes(),tuwunel_kernel::finite_catalog::fallback_08cb57a8::Fallback::Entries.name(),"fallback_08cb57a8/name/Entries");
assert_eq!(Fallback::Canary.name().as_bytes(),tuwunel_kernel::finite_catalog::fallback_08cb57a8::Fallback::Canary.name(),"fallback_08cb57a8/name/Canary");
assert_eq!(Fallback::CreateMismatch.name().as_bytes(),tuwunel_kernel::finite_catalog::fallback_08cb57a8::Fallback::CreateMismatch.name(),"fallback_08cb57a8/name/CreateMismatch");
assert_eq!(Fallback::Unevaluable.name().as_bytes(),tuwunel_kernel::finite_catalog::fallback_08cb57a8::Fallback::Unevaluable.name(),"fallback_08cb57a8/name/Unevaluable");
assert_eq!(Fallback::Error.name().as_bytes(),tuwunel_kernel::finite_catalog::fallback_08cb57a8::Fallback::Error.name(),"fallback_08cb57a8/name/Error");
}
