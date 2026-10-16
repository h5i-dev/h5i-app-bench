//! Name tables and ActionSet operations from `policy/action.rs`.
use crate::{
    acts::{Action, Family},
    bytes,
};

/// Enum variant count, excluding `Action::None`.
pub fn action_count(family: Family) -> usize {
    match family {
        Family::S3 => 71,
        Family::Admin => 91,
        Family::Sts => 2,
        Family::Kms => 18,
        Family::None => 0,
    }
}

/// The S3Action, AdminAction, StsAction and KmsAction name tables, in declaration order.
pub fn action_name(family: Family, index: usize) -> Vec<u8> {
    match family {
        Family::S3 => s3_name(index),
        Family::Admin => admin_name(index),
        Family::Sts => sts_name(index),
        Family::Kms => kms_name(index),
        Family::None => Vec::new(),
    }
}

/// S3Action name table.
pub fn s3_name(index: usize) -> Vec<u8> {
    match index / 16 {
        0 => s3_name_0(index),
        1 => s3_name_1(index),
        2 => s3_name_2(index),
        3 => s3_name_3(index),
        4 => s3_name_4(index),
        _ => Vec::new(),
    }
}

fn s3_name_0(index: usize) -> Vec<u8> {
    match index {
        0 => b"s3:*".to_vec(),
        1 => b"s3:AbortMultipartUpload".to_vec(),
        2 => b"s3:CreateBucket".to_vec(),
        3 => b"s3:DeleteBucket".to_vec(),
        4 => b"s3:ForceDeleteBucket".to_vec(),
        5 => b"s3:ForceDeleteObject".to_vec(),
        6 => b"s3:DeleteBucketPolicy".to_vec(),
        7 => b"s3:DeleteBucketPublicAccessBlock".to_vec(),
        8 => b"s3:DeleteBucketCors".to_vec(),
        9 => b"s3:DeleteObject".to_vec(),
        10 => b"s3:GetBucketLocation".to_vec(),
        11 => b"s3:GetBucketNotification".to_vec(),
        12 => b"s3:GetBucketPolicy".to_vec(),
        13 => b"s3:GetBucketPublicAccessBlock".to_vec(),
        14 => b"s3:GetBucketCors".to_vec(),
        15 => b"s3:GetBucketAcl".to_vec(),
        _ => Vec::new(),
    }
}

fn s3_name_1(index: usize) -> Vec<u8> {
    match index {
        16 => b"s3:PutBucketAcl".to_vec(),
        17 => b"s3:GetObject".to_vec(),
        18 => b"s3:GetObjectAcl".to_vec(),
        19 => b"s3:GetObjectAttributes".to_vec(),
        20 => b"s3:HeadBucket".to_vec(),
        21 => b"s3:ListAllMyBuckets".to_vec(),
        22 => b"s3:ListBucket".to_vec(),
        23 => b"s3:GetBucketPolicyStatus".to_vec(),
        24 => b"s3:ListBucketVersions".to_vec(),
        25 => b"s3:ListBucketMultipartUploads".to_vec(),
        26 => b"s3:ListenNotification".to_vec(),
        27 => b"s3:ListenBucketNotification".to_vec(),
        28 => b"s3:ListMultipartUploadParts".to_vec(),
        29 => b"s3:PutBucketLifecycle".to_vec(),
        30 => b"s3:GetBucketLifecycle".to_vec(),
        31 => b"s3:PutBucketLogging".to_vec(),
        _ => Vec::new(),
    }
}

fn s3_name_2(index: usize) -> Vec<u8> {
    match index {
        32 => b"s3:GetBucketLogging".to_vec(),
        33 => b"s3:PutBucketNotification".to_vec(),
        34 => b"s3:PutBucketPolicy".to_vec(),
        35 => b"s3:PutBucketPublicAccessBlock".to_vec(),
        36 => b"s3:PutBucketCors".to_vec(),
        37 => b"s3:PutObject".to_vec(),
        38 => b"s3:PutObjectAcl".to_vec(),
        39 => b"s3:DeleteObjectVersion".to_vec(),
        40 => b"s3:DeleteObjectVersionTagging".to_vec(),
        41 => b"s3:GetObjectVersion".to_vec(),
        42 => b"s3:GetObjectVersionAttributes".to_vec(),
        43 => b"s3:GetObjectVersionTagging".to_vec(),
        44 => b"s3:PutObjectVersionTagging".to_vec(),
        45 => b"s3:BypassGovernanceRetention".to_vec(),
        46 => b"s3:PutObjectRetention".to_vec(),
        47 => b"s3:GetObjectRetention".to_vec(),
        _ => Vec::new(),
    }
}

fn s3_name_3(index: usize) -> Vec<u8> {
    match index {
        48 => b"s3:GetObjectLegalHold".to_vec(),
        49 => b"s3:PutObjectLegalHold".to_vec(),
        50 => b"s3:GetBucketObjectLockConfiguration".to_vec(),
        51 => b"s3:PutBucketObjectLockConfiguration".to_vec(),
        52 => b"s3:GetBucketTagging".to_vec(),
        53 => b"s3:PutBucketTagging".to_vec(),
        54 => b"s3:GetObjectTagging".to_vec(),
        55 => b"s3:PutObjectTagging".to_vec(),
        56 => b"s3:DeleteObjectTagging".to_vec(),
        57 => b"s3:PutBucketEncryption".to_vec(),
        58 => b"s3:GetBucketEncryption".to_vec(),
        59 => b"s3:PutBucketVersioning".to_vec(),
        60 => b"s3:GetBucketVersioning".to_vec(),
        61 => b"s3:GetReplicationConfiguration".to_vec(),
        62 => b"s3:PutReplicationConfiguration".to_vec(),
        63 => b"s3:ReplicateObject".to_vec(),
        _ => Vec::new(),
    }
}

fn s3_name_4(index: usize) -> Vec<u8> {
    match index {
        64 => b"s3:ReplicateDelete".to_vec(),
        65 => b"s3:ReplicateTags".to_vec(),
        66 => b"s3:GetObjectVersionForReplication".to_vec(),
        67 => b"s3:RestoreObject".to_vec(),
        68 => b"s3:ResetBucketReplicationState".to_vec(),
        69 => b"s3:PutObjectFanOut".to_vec(),
        70 => b"s3:GetBucketQuota".to_vec(),
        _ => Vec::new(),
    }
}

/// AdminAction name table.
pub fn admin_name(index: usize) -> Vec<u8> {
    match index / 16 {
        0 => admin_name_0(index),
        1 => admin_name_1(index),
        2 => admin_name_2(index),
        3 => admin_name_3(index),
        4 => admin_name_4(index),
        5 => admin_name_5(index),
        _ => Vec::new(),
    }
}

fn admin_name_0(index: usize) -> Vec<u8> {
    match index {
        0 => b"admin:Heal".to_vec(),
        1 => b"admin:Decommission".to_vec(),
        2 => b"admin:Rebalance".to_vec(),
        3 => b"admin:StorageInfo".to_vec(),
        4 => b"admin:Prometheus".to_vec(),
        5 => b"admin:DataUsageInfo".to_vec(),
        6 => b"admin:ForceUnlock".to_vec(),
        7 => b"admin:TopLocksInfo".to_vec(),
        8 => b"admin:Profiling".to_vec(),
        9 => b"admin:ServerTrace".to_vec(),
        10 => b"admin:ConsoleLog".to_vec(),
        11 => b"admin:ServerInfo".to_vec(),
        12 => b"admin:OBDInfo".to_vec(),
        13 => b"admin:LicenseInfo".to_vec(),
        14 => b"admin:BandwidthMonitor".to_vec(),
        15 => b"admin:InspectData".to_vec(),
        _ => Vec::new(),
    }
}

fn admin_name_1(index: usize) -> Vec<u8> {
    match index {
        16 => b"admin:ServerUpdate".to_vec(),
        17 => b"admin:ServiceRestart".to_vec(),
        18 => b"admin:ServiceStop".to_vec(),
        19 => b"admin:ServiceFreeze".to_vec(),
        20 => b"admin:ConfigUpdate".to_vec(),
        21 => b"admin:CreateUser".to_vec(),
        22 => b"admin:DeleteUser".to_vec(),
        23 => b"admin:ListUsers".to_vec(),
        24 => b"admin:EnableUser".to_vec(),
        25 => b"admin:DisableUser".to_vec(),
        26 => b"admin:GetUser".to_vec(),
        27 => b"admin:SiteReplicationAdd".to_vec(),
        28 => b"admin:SiteReplicationDisable".to_vec(),
        29 => b"admin:SiteReplicationRemove".to_vec(),
        30 => b"admin:SiteReplicationResync".to_vec(),
        31 => b"admin:SiteReplicationInfo".to_vec(),
        _ => Vec::new(),
    }
}

fn admin_name_2(index: usize) -> Vec<u8> {
    match index {
        32 => b"admin:SiteReplicationOperation".to_vec(),
        33 => b"admin:CreateServiceAccount".to_vec(),
        34 => b"admin:UpdateServiceAccount".to_vec(),
        35 => b"admin:RemoveServiceAccount".to_vec(),
        36 => b"admin:ListServiceAccounts".to_vec(),
        37 => b"admin:ListTemporaryAccounts".to_vec(),
        38 => b"admin:AddUserToGroup".to_vec(),
        39 => b"admin:RemoveUserFromGroup".to_vec(),
        40 => b"admin:GetGroup".to_vec(),
        41 => b"admin:ListGroups".to_vec(),
        42 => b"admin:EnableGroup".to_vec(),
        43 => b"admin:DisableGroup".to_vec(),
        44 => b"admin:CreatePolicy".to_vec(),
        45 => b"admin:DeletePolicy".to_vec(),
        46 => b"admin:GetPolicy".to_vec(),
        47 => b"admin:AttachUserOrGroupPolicy".to_vec(),
        _ => Vec::new(),
    }
}

fn admin_name_3(index: usize) -> Vec<u8> {
    match index {
        48 => b"admin:UpdatePolicyAssociation".to_vec(),
        49 => b"admin:ListUserPolicies".to_vec(),
        50 => b"admin:SetBucketQuota".to_vec(),
        51 => b"admin:SetBucketTarget".to_vec(),
        52 => b"admin:GetBucketTarget".to_vec(),
        53 => b"admin:SetBucketOnDemandMigration".to_vec(),
        54 => b"admin:GetBucketOnDemandMigration".to_vec(),
        55 => b"admin:GetMetrics".to_vec(),
        56 => b"admin:ReplicationDiff".to_vec(),
        57 => b"admin:GetReplicationMetrics".to_vec(),
        58 => b"admin:ImportBucketMetadata".to_vec(),
        59 => b"admin:ExportBucketMetadata".to_vec(),
        60 => b"admin:GetTableCatalog".to_vec(),
        61 => b"admin:MigrateTableCatalog".to_vec(),
        62 => b"admin:GetTableBucket".to_vec(),
        63 => b"admin:SetTableBucket".to_vec(),
        _ => Vec::new(),
    }
}

fn admin_name_4(index: usize) -> Vec<u8> {
    match index {
        64 => b"admin:GetTableNamespace".to_vec(),
        65 => b"admin:SetTableNamespace".to_vec(),
        66 => b"admin:UpdateTableNamespaceProperties".to_vec(),
        67 => b"admin:DeleteTableNamespace".to_vec(),
        68 => b"admin:GetTable".to_vec(),
        69 => b"admin:SetTable".to_vec(),
        70 => b"admin:CreateTable".to_vec(),
        71 => b"admin:RegisterTable".to_vec(),
        72 => b"admin:CommitTable".to_vec(),
        73 => b"admin:DeleteTable".to_vec(),
        74 => b"admin:GetTableLifecycle".to_vec(),
        75 => b"admin:SetTableLifecycle".to_vec(),
        76 => b"admin:GetTableCredentials".to_vec(),
        77 => b"admin:RunTableMaintenance".to_vec(),
        78 => b"admin:GetTableMetadataLocation".to_vec(),
        79 => b"admin:SetTableMetadataLocation".to_vec(),
        _ => Vec::new(),
    }
}

fn admin_name_5(index: usize) -> Vec<u8> {
    match index {
        80 => b"admin:GetTableMetadata".to_vec(),
        81 => b"admin:SetTableMetadata".to_vec(),
        82 => b"admin:SetTier".to_vec(),
        83 => b"admin:ListTier".to_vec(),
        84 => b"admin:ExportIAM".to_vec(),
        85 => b"admin:ImportIAM".to_vec(),
        86 => b"admin:ListBatchJobs".to_vec(),
        87 => b"admin:DescribeBatchJob".to_vec(),
        88 => b"admin:StartBatchJob".to_vec(),
        89 => b"admin:CancelBatchJob".to_vec(),
        90 => b"admin:*".to_vec(),
        _ => Vec::new(),
    }
}

/// StsAction name table.
pub fn sts_name(index: usize) -> Vec<u8> {
    match index {
        0 => b"sts:*".to_vec(),
        1 => b"sts:AssumeRole".to_vec(),
        _ => Vec::new(),
    }
}

/// KmsAction name table.
pub fn kms_name(index: usize) -> Vec<u8> {
    match index / 16 {
        0 => kms_name_0(index),
        1 => kms_name_1(index),
        _ => Vec::new(),
    }
}

fn kms_name_0(index: usize) -> Vec<u8> {
    match index {
        0 => b"kms:*".to_vec(),
        1 => b"kms:Configure".to_vec(),
        2 => b"kms:ServiceControl".to_vec(),
        3 => b"kms:ClearCache".to_vec(),
        4 => b"kms:GenerateDataKey".to_vec(),
        5 => b"kms:DeleteKey".to_vec(),
        6 => b"kms:EnableKey".to_vec(),
        7 => b"kms:DisableKey".to_vec(),
        8 => b"kms:RotateKey".to_vec(),
        9 => b"kms:UpdateKeyDescription".to_vec(),
        10 => b"kms:TagResource".to_vec(),
        11 => b"kms:UntagResource".to_vec(),
        12 => b"kms:ListKeys".to_vec(),
        13 => b"kms:DescribeKey".to_vec(),
        14 => b"kms:Decrypt".to_vec(),
        15 => b"kms:Backup".to_vec(),
        _ => Vec::new(),
    }
}

fn kms_name_1(index: usize) -> Vec<u8> {
    match index {
        16 => b"kms:Restore".to_vec(),
        17 => b"kms:Rekey".to_vec(),
        _ => Vec::new(),
    }
}

/// Membership in an action enum's name table; invalid names are rejected.
pub fn contains_name(family: Family, name: &[u8]) -> bool {
    let mut i = 0;
    while i < action_count(family) {
        if bytes::eq(&action_name(family, i), name) {
            return true;
        }
        i += 1;
    }
    false
}

/// `AdminAction::is_valid`: upstream enumerates all its variants.
pub fn admin_is_valid(name: &[u8]) -> bool {
    contains_name(Family::Admin, name)
}
/// `ActionSet::is_empty`.
pub fn is_empty(set: &[Action]) -> bool {
    set.len() == 0
}
/// `ActionSet::deref`.
pub fn as_slice(set: &[Action]) -> &[Action] {
    set
}
/// `ActionSet::push_unique`.
pub fn push_unique(set: &mut Vec<Action>, a: Action) {
    let mut i = 0;
    while i < set.len() {
        if set[i] == a {
            return;
        }
        i += 1;
    }
    set.push(a);
}
/// `ActionSet::is_match`.
pub fn set_is_match(set: &[Action], a: &Action) -> bool {
    crate::acts::set_is_match_for_effect(set, a, false)
}
/// `Action::is_match`.
pub fn action_is_match(this: &Action, a: &Action) -> bool {
    crate::acts::action_is_match_for_effect(this, a, false)
}
/// `ActionSet::is_valid`: intentionally accepts every constructed set, including None.
pub fn is_valid(_set: &[Action]) -> bool {
    true
}
/// `Vec::contains` over actions, factored out to avoid nested-loop control flow in Aeneas.
pub fn member(set: &[Action], a: &Action) -> bool {
    let mut i = 0;
    while i < set.len() {
        if set[i] == *a {
            return true;
        }
        i += 1;
    }
    false
}
fn covers(left: &[Action], right: &[Action]) -> bool {
    let mut i = 0;
    while i < left.len() {
        if !member(right, &left[i]) {
            return false;
        }
        i += 1;
    }
    true
}
/// `ActionSet::eq`: mutual membership, irrespective of order or multiplicity.
pub fn eq(left: &[Action], right: &[Action]) -> bool {
    covers(left, right) && covers(right, left)
}
