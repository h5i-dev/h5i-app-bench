#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum PolicyType {MaxAgeDays,MaxVersions,NoDownloadsDays,TagPatternKeep,TagPatternDelete,SizeQuotaBytes}
impl PolicyType {
    /// Wire-format name. Inverse of `parse`. Used in log/error messages so
    /// the unit suite can assert on the exact string the executors emit.
    pub(crate) fn as_wire_str(self) -> &'static str {
        match self {
            Self::MaxAgeDays => "max_age_days",
            Self::MaxVersions => "max_versions",
            Self::NoDownloadsDays => "no_downloads_days",
            Self::TagPatternKeep => "tag_pattern_keep",
            Self::TagPatternDelete => "tag_pattern_delete",
            Self::SizeQuotaBytes => "size_quota_bytes",
        }
    }
}
fn main(){
println!("as_wire_str/MaxAgeDays\t{:?}",PolicyType::MaxAgeDays.as_wire_str().as_bytes());
println!("as_wire_str/MaxVersions\t{:?}",PolicyType::MaxVersions.as_wire_str().as_bytes());
println!("as_wire_str/NoDownloadsDays\t{:?}",PolicyType::NoDownloadsDays.as_wire_str().as_bytes());
println!("as_wire_str/TagPatternKeep\t{:?}",PolicyType::TagPatternKeep.as_wire_str().as_bytes());
println!("as_wire_str/TagPatternDelete\t{:?}",PolicyType::TagPatternDelete.as_wire_str().as_bytes());
println!("as_wire_str/SizeQuotaBytes\t{:?}",PolicyType::SizeQuotaBytes.as_wire_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(PolicyType::MaxAgeDays.as_wire_str().as_bytes(),artifactkeeper_kernel::finite_catalog::policy_type_080e6210::PolicyType::MaxAgeDays.as_wire_str(),"policy_type_080e6210/as_wire_str/MaxAgeDays");
assert_eq!(PolicyType::MaxVersions.as_wire_str().as_bytes(),artifactkeeper_kernel::finite_catalog::policy_type_080e6210::PolicyType::MaxVersions.as_wire_str(),"policy_type_080e6210/as_wire_str/MaxVersions");
assert_eq!(PolicyType::NoDownloadsDays.as_wire_str().as_bytes(),artifactkeeper_kernel::finite_catalog::policy_type_080e6210::PolicyType::NoDownloadsDays.as_wire_str(),"policy_type_080e6210/as_wire_str/NoDownloadsDays");
assert_eq!(PolicyType::TagPatternKeep.as_wire_str().as_bytes(),artifactkeeper_kernel::finite_catalog::policy_type_080e6210::PolicyType::TagPatternKeep.as_wire_str(),"policy_type_080e6210/as_wire_str/TagPatternKeep");
assert_eq!(PolicyType::TagPatternDelete.as_wire_str().as_bytes(),artifactkeeper_kernel::finite_catalog::policy_type_080e6210::PolicyType::TagPatternDelete.as_wire_str(),"policy_type_080e6210/as_wire_str/TagPatternDelete");
assert_eq!(PolicyType::SizeQuotaBytes.as_wire_str().as_bytes(),artifactkeeper_kernel::finite_catalog::policy_type_080e6210::PolicyType::SizeQuotaBytes.as_wire_str(),"policy_type_080e6210/as_wire_str/SizeQuotaBytes");
}
