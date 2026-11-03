#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum StateAfter {Off,Stable,Unstable}
impl StateAfter {
	fn requested(self) -> bool { !matches!(self, Self::Off) }
}
fn main(){
println!("requested/Off\t{:?}",StateAfter::Off.requested());
println!("requested/Stable\t{:?}",StateAfter::Stable.requested());
println!("requested/Unstable\t{:?}",StateAfter::Unstable.requested());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(StateAfter::Off.requested(),tuwunel_kernel::finite_catalog::state_after_c4e3af58::StateAfter::Off.requested(),"state_after_c4e3af58/requested/Off");
assert_eq!(StateAfter::Stable.requested(),tuwunel_kernel::finite_catalog::state_after_c4e3af58::StateAfter::Stable.requested(),"state_after_c4e3af58/requested/Stable");
assert_eq!(StateAfter::Unstable.requested(),tuwunel_kernel::finite_catalog::state_after_c4e3af58::StateAfter::Unstable.requested(),"state_after_c4e3af58/requested/Unstable");
}
