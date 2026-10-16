//! Access control profiles (access/profiles.rs), as parsed by the
//! `try_from` functions, which are not ported. Names and uuids, which only
//! label logs, are left out.
use crate::{Attribute, FilterComp, FilterResolved, Uuid};

/// `AccessControlReceiver`.
pub enum AccessControlReceiver {
    None,
    Group(Vec<Uuid>),
    EntryManager,
}

/// `AccessControlReceiverCondition`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AccessControlReceiverCondition {
    GroupChecked,
    EntryManager,
}

/// `AccessControlTarget`; the scope is a `Filter<FilterValid>`.
pub enum AccessControlTarget {
    None,
    Scope(FilterComp),
}

/// `AccessControlTargetCondition`; the scope is a `Filter<FilterValidResolved>`.
pub enum AccessControlTargetCondition {
    Scope(FilterResolved),
}

/// `AccessControlProfile`.
pub struct AccessControlProfile {
    pub receiver: AccessControlReceiver,
    pub target: AccessControlTarget,
}

/// `AccessControlSearch`.
pub struct AccessControlSearch {
    pub acp: AccessControlProfile,
    pub attrs: Vec<Attribute>,
}

/// `AccessControlSearchResolved`. Upstream borrows the profile; this holds
/// a copy of the part the checks read (`acp.attrs`).
pub struct AccessControlSearchResolved {
    pub attrs: Vec<Attribute>,
    pub receiver_condition: AccessControlReceiverCondition,
    pub target_condition: AccessControlTargetCondition,
}

/// `AccessControlDelete`.
pub struct AccessControlDelete {
    pub acp: AccessControlProfile,
}

/// `AccessControlDeleteResolved`.
pub struct AccessControlDeleteResolved {
    pub receiver_condition: AccessControlReceiverCondition,
    pub target_condition: AccessControlTargetCondition,
}

/// `AccessControlCreate`.
pub struct AccessControlCreate {
    pub acp: AccessControlProfile,
    pub classes: Vec<Vec<u8>>,
    pub attrs: Vec<Attribute>,
}

/// `AccessControlCreateResolved`, with copies of `acp.classes`, `acp.attrs`.
pub struct AccessControlCreateResolved {
    pub classes: Vec<Vec<u8>>,
    pub attrs: Vec<Attribute>,
    pub receiver_condition: AccessControlReceiverCondition,
    pub target_condition: AccessControlTargetCondition,
}

/// `AccessControlModify`.
pub struct AccessControlModify {
    pub acp: AccessControlProfile,
    pub presattrs: Vec<Attribute>,
    pub remattrs: Vec<Attribute>,
    pub pres_classes: Vec<Vec<u8>>,
    pub rem_classes: Vec<Vec<u8>>,
}

/// The four sets of an `AccessControlModify` (the part `modify_pres_test`
/// reads), copied out of the profile.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ModifyGrants {
    pub presattrs: Vec<Attribute>,
    pub remattrs: Vec<Attribute>,
    pub pres_classes: Vec<Vec<u8>>,
    pub rem_classes: Vec<Vec<u8>>,
}

/// `AccessControlModifyResolved`.
pub struct AccessControlModifyResolved {
    pub acp: ModifyGrants,
    pub receiver_condition: AccessControlReceiverCondition,
    pub target_condition: AccessControlTargetCondition,
}
