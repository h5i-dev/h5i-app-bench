#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ErrCause {Handler,Timeout,Panicked}
impl ErrCause {
    /// Stable label for the `cause` tracing field. Log aggregators key
    /// on these — renaming here IS a breaking change to any dashboard
    /// filtering on `cause = "handler"`.
    pub fn as_str(self) -> &'static str {
        match self {
            ErrCause::Handler => "handler",
            ErrCause::Timeout => "timeout",
            ErrCause::Panicked => "panicked",
        }
    }
}
fn main(){
println!("as_str/Handler\t{:?}",ErrCause::Handler.as_str().as_bytes());
println!("as_str/Timeout\t{:?}",ErrCause::Timeout.as_str().as_bytes());
println!("as_str/Panicked\t{:?}",ErrCause::Panicked.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(ErrCause::Handler.as_str().as_bytes(),oxicloud_kernel::finite_catalog::err_cause_75575f17::ErrCause::Handler.as_str(),"err_cause_75575f17/as_str/Handler");
assert_eq!(ErrCause::Timeout.as_str().as_bytes(),oxicloud_kernel::finite_catalog::err_cause_75575f17::ErrCause::Timeout.as_str(),"err_cause_75575f17/as_str/Timeout");
assert_eq!(ErrCause::Panicked.as_str().as_bytes(),oxicloud_kernel::finite_catalog::err_cause_75575f17::ErrCause::Panicked.as_str(),"err_cause_75575f17/as_str/Panicked");
}
