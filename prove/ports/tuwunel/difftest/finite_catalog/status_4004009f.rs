#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Status {Scheduled,Active,Complete,Failed}
impl Status {
	/// Tests whether no further execution transition is expected.
	///
	/// Complete and failed tasks are terminal. Scheduled and active tasks can
	/// still transition as their futures run.
	#[must_use]
	pub fn is_terminal(self) -> bool { matches!(self, Self::Complete | Self::Failed) }
	/// Returns the lowercase status spelling used by administrative responses.
	///
	/// The returned string is static and allocation-free. Each enum variant has
	/// one stable spelling.
	#[must_use]
	pub fn as_str(self) -> &'static str {
		match self {
			| Self::Scheduled => "scheduled",
			| Self::Active => "active",
			| Self::Complete => "complete",
			| Self::Failed => "failed",
		}
	}
}
fn main(){
println!("is_terminal/Scheduled\t{:?}",Status::Scheduled.is_terminal());
println!("is_terminal/Active\t{:?}",Status::Active.is_terminal());
println!("is_terminal/Complete\t{:?}",Status::Complete.is_terminal());
println!("is_terminal/Failed\t{:?}",Status::Failed.is_terminal());
println!("as_str/Scheduled\t{:?}",Status::Scheduled.as_str().as_bytes());
println!("as_str/Active\t{:?}",Status::Active.as_str().as_bytes());
println!("as_str/Complete\t{:?}",Status::Complete.as_str().as_bytes());
println!("as_str/Failed\t{:?}",Status::Failed.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(Status::Scheduled.is_terminal(),tuwunel_kernel::finite_catalog::status_4004009f::Status::Scheduled.is_terminal(),"status_4004009f/is_terminal/Scheduled");
assert_eq!(Status::Active.is_terminal(),tuwunel_kernel::finite_catalog::status_4004009f::Status::Active.is_terminal(),"status_4004009f/is_terminal/Active");
assert_eq!(Status::Complete.is_terminal(),tuwunel_kernel::finite_catalog::status_4004009f::Status::Complete.is_terminal(),"status_4004009f/is_terminal/Complete");
assert_eq!(Status::Failed.is_terminal(),tuwunel_kernel::finite_catalog::status_4004009f::Status::Failed.is_terminal(),"status_4004009f/is_terminal/Failed");
assert_eq!(Status::Scheduled.as_str().as_bytes(),tuwunel_kernel::finite_catalog::status_4004009f::Status::Scheduled.as_str(),"status_4004009f/as_str/Scheduled");
assert_eq!(Status::Active.as_str().as_bytes(),tuwunel_kernel::finite_catalog::status_4004009f::Status::Active.as_str(),"status_4004009f/as_str/Active");
assert_eq!(Status::Complete.as_str().as_bytes(),tuwunel_kernel::finite_catalog::status_4004009f::Status::Complete.as_str(),"status_4004009f/as_str/Complete");
assert_eq!(Status::Failed.as_str().as_bytes(),tuwunel_kernel::finite_catalog::status_4004009f::Status::Failed.as_str(),"status_4004009f/as_str/Failed");
}
