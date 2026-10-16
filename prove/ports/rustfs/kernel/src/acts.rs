//! `policy/action.rs`: actions are matched by name (`IntoStaticStr`).
use crate::{bytes, wildmatch};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Family {
    S3,
    Admin,
    Sts,
    Kms,
    None,
}

/// An `Action`: its family and its name, e.g. `s3:GetObject`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Action {
    pub family: Family,
    pub name: Vec<u8>,
}

fn is_s3(a: &Action, name: &[u8]) -> bool {
    a.family == Family::S3 && bytes::eq(&a.name, name)
}

/// `action_requires_explicit_grant`.
pub fn action_requires_explicit_grant(a: &Action) -> bool {
    is_s3(a, b"s3:ForceDeleteBucket") || is_s3(a, b"s3:ForceDeleteObject")
}

/// `Action::is_match_for_effect`.
pub fn action_is_match_for_effect(this: &Action, a: &Action, deny: bool) -> bool {
    if !deny && is_s3(this, b"s3:*") && action_requires_explicit_grant(a) {
        return false;
    }
    wildmatch::is_match(&this.name, &a.name)
}

/// `ActionSet::is_match_for_effect`.
pub fn set_is_match_for_effect(set: &[Action], a: &Action, deny: bool) -> bool {
    let mut i = 0;
    while i < set.len() {
        if action_is_match_for_effect(&set[i], a, deny) {
            return true;
        }
        if is_s3(&set[i], b"s3:GetObjectVersion") && is_s3(a, b"s3:GetObject") {
            return true;
        }
        i += 1;
    }
    false
}

/// `ActionSet::statement_covers`.
pub fn statement_covers(actions: &[Action], not_actions: &[Action], a: &Action, deny: bool) -> bool {
    if set_is_match_for_effect(not_actions, a, true) {
        return false;
    }
    if actions.len() == 0 {
        return deny || !action_requires_explicit_grant(a);
    }
    set_is_match_for_effect(actions, a, deny)
}

/// `AdminAction::is_table_resource_scoped`.
pub fn is_table_resource_scoped(a: &Action) -> bool {
    if a.family != Family::Admin {
        return false;
    }
    let n = &a.name;
    bytes::eq(n, b"admin:GetTableBucket") || bytes::eq(n, b"admin:SetTableBucket")
        || bytes::eq(n, b"admin:GetTableNamespace") || bytes::eq(n, b"admin:SetTableNamespace")
        || bytes::eq(n, b"admin:UpdateTableNamespaceProperties") || bytes::eq(n, b"admin:DeleteTableNamespace")
        || bytes::eq(n, b"admin:GetTable") || bytes::eq(n, b"admin:SetTable")
        || bytes::eq(n, b"admin:CreateTable") || bytes::eq(n, b"admin:RegisterTable")
        || bytes::eq(n, b"admin:CommitTable") || bytes::eq(n, b"admin:DeleteTable")
        || bytes::eq(n, b"admin:GetTableLifecycle") || bytes::eq(n, b"admin:SetTableLifecycle")
        || bytes::eq(n, b"admin:GetTableCredentials") || bytes::eq(n, b"admin:RunTableMaintenance")
        || bytes::eq(n, b"admin:GetTableMetadataLocation") || bytes::eq(n, b"admin:SetTableMetadataLocation")
        || bytes::eq(n, b"admin:GetTableMetadata") || bytes::eq(n, b"admin:SetTableMetadata")
}
