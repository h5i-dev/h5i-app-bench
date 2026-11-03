#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum RunStatus {Running,Paused,CancelRequested,Completed,Failed,Cancelled}
impl RunStatus {
    /// Stable label matching the SQL storage form.
    pub fn as_str(self) -> &'static str {
        match self {
            RunStatus::Running => "Running",
            RunStatus::Paused => "Paused",
            RunStatus::CancelRequested => "CancelRequested",
            RunStatus::Completed => "Completed",
            RunStatus::Failed => "Failed",
            RunStatus::Cancelled => "Cancelled",
        }
    }
    /// The set the exclusivity partial index scopes. Read: "a run in
    /// this state blocks a fresh dispatch."
    pub fn is_non_terminal(self) -> bool {
        matches!(
            self,
            RunStatus::Running | RunStatus::Paused | RunStatus::CancelRequested
        )
    }
}
fn main(){
println!("as_str/Running\t{:?}",RunStatus::Running.as_str().as_bytes());
println!("as_str/Paused\t{:?}",RunStatus::Paused.as_str().as_bytes());
println!("as_str/CancelRequested\t{:?}",RunStatus::CancelRequested.as_str().as_bytes());
println!("as_str/Completed\t{:?}",RunStatus::Completed.as_str().as_bytes());
println!("as_str/Failed\t{:?}",RunStatus::Failed.as_str().as_bytes());
println!("as_str/Cancelled\t{:?}",RunStatus::Cancelled.as_str().as_bytes());
println!("is_non_terminal/Running\t{:?}",RunStatus::Running.is_non_terminal());
println!("is_non_terminal/Paused\t{:?}",RunStatus::Paused.is_non_terminal());
println!("is_non_terminal/CancelRequested\t{:?}",RunStatus::CancelRequested.is_non_terminal());
println!("is_non_terminal/Completed\t{:?}",RunStatus::Completed.is_non_terminal());
println!("is_non_terminal/Failed\t{:?}",RunStatus::Failed.is_non_terminal());
println!("is_non_terminal/Cancelled\t{:?}",RunStatus::Cancelled.is_non_terminal());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(RunStatus::Running.as_str().as_bytes(),oxicloud_kernel::finite_catalog::run_status_dbd87cc3::RunStatus::Running.as_str(),"run_status_dbd87cc3/as_str/Running");
assert_eq!(RunStatus::Paused.as_str().as_bytes(),oxicloud_kernel::finite_catalog::run_status_dbd87cc3::RunStatus::Paused.as_str(),"run_status_dbd87cc3/as_str/Paused");
assert_eq!(RunStatus::CancelRequested.as_str().as_bytes(),oxicloud_kernel::finite_catalog::run_status_dbd87cc3::RunStatus::CancelRequested.as_str(),"run_status_dbd87cc3/as_str/CancelRequested");
assert_eq!(RunStatus::Completed.as_str().as_bytes(),oxicloud_kernel::finite_catalog::run_status_dbd87cc3::RunStatus::Completed.as_str(),"run_status_dbd87cc3/as_str/Completed");
assert_eq!(RunStatus::Failed.as_str().as_bytes(),oxicloud_kernel::finite_catalog::run_status_dbd87cc3::RunStatus::Failed.as_str(),"run_status_dbd87cc3/as_str/Failed");
assert_eq!(RunStatus::Cancelled.as_str().as_bytes(),oxicloud_kernel::finite_catalog::run_status_dbd87cc3::RunStatus::Cancelled.as_str(),"run_status_dbd87cc3/as_str/Cancelled");
assert_eq!(RunStatus::Running.is_non_terminal(),oxicloud_kernel::finite_catalog::run_status_dbd87cc3::RunStatus::Running.is_non_terminal(),"run_status_dbd87cc3/is_non_terminal/Running");
assert_eq!(RunStatus::Paused.is_non_terminal(),oxicloud_kernel::finite_catalog::run_status_dbd87cc3::RunStatus::Paused.is_non_terminal(),"run_status_dbd87cc3/is_non_terminal/Paused");
assert_eq!(RunStatus::CancelRequested.is_non_terminal(),oxicloud_kernel::finite_catalog::run_status_dbd87cc3::RunStatus::CancelRequested.is_non_terminal(),"run_status_dbd87cc3/is_non_terminal/CancelRequested");
assert_eq!(RunStatus::Completed.is_non_terminal(),oxicloud_kernel::finite_catalog::run_status_dbd87cc3::RunStatus::Completed.is_non_terminal(),"run_status_dbd87cc3/is_non_terminal/Completed");
assert_eq!(RunStatus::Failed.is_non_terminal(),oxicloud_kernel::finite_catalog::run_status_dbd87cc3::RunStatus::Failed.is_non_terminal(),"run_status_dbd87cc3/is_non_terminal/Failed");
assert_eq!(RunStatus::Cancelled.is_non_terminal(),oxicloud_kernel::finite_catalog::run_status_dbd87cc3::RunStatus::Cancelled.is_non_terminal(),"run_status_dbd87cc3/is_non_terminal/Cancelled");
}
