// Stub head of `server/access/profiles.rs`: the types below are copied; the
// `try_from` parsers and test constructors are not.
use crate::prelude::*;
use std::collections::BTreeSet;

use crate::filter::{Filter, FilterValid, FilterValidResolved};

// Copied from kanidm/kanidm @ f608c4f by extract_upstream.py. Do not edit.
#[derive(Debug, Clone)]
pub struct AccessControlSearchResolved<'a> {
    pub acp: &'a AccessControlSearch,
    pub receiver_condition: AccessControlReceiverCondition,
    pub target_condition: AccessControlTargetCondition,
}

#[derive(Debug, Clone)]
pub struct AccessControlSearch {
    pub acp: AccessControlProfile,
    pub attrs: BTreeSet<Attribute>,
}

#[derive(Debug, Clone)]
pub struct AccessControlDeleteResolved<'a> {
    pub acp: &'a AccessControlDelete,
    pub receiver_condition: AccessControlReceiverCondition,
    pub target_condition: AccessControlTargetCondition,
}

#[derive(Debug, Clone)]
pub struct AccessControlDelete {
    pub acp: AccessControlProfile,
}

#[derive(Debug, Clone)]
pub struct AccessControlCreateResolved<'a> {
    pub acp: &'a AccessControlCreate,
    pub receiver_condition: AccessControlReceiverCondition,
    pub target_condition: AccessControlTargetCondition,
}

#[derive(Debug, Clone)]
pub struct AccessControlCreate {
    pub acp: AccessControlProfile,
    pub classes: Vec<AttrString>,
    pub attrs: Vec<Attribute>,
}

#[derive(Debug, Clone)]
pub struct AccessControlModifyResolved<'a> {
    pub acp: &'a AccessControlModify,
    pub receiver_condition: AccessControlReceiverCondition,
    pub target_condition: AccessControlTargetCondition,
}

#[derive(Debug, Clone)]
pub struct AccessControlModify {
    pub acp: AccessControlProfile,
    pub presattrs: Vec<Attribute>,
    pub remattrs: Vec<Attribute>,
    pub pres_classes: Vec<AttrString>,
    pub rem_classes: Vec<AttrString>,
}

#[derive(Debug, Clone)]
pub enum AccessControlReceiver {
    None,
    Group(BTreeSet<Uuid>),
    EntryManager,
}

#[derive(Debug, Clone)]
pub enum AccessControlReceiverCondition {
    // None,
    GroupChecked,
    EntryManager,
}

#[derive(Debug, Clone)]
pub enum AccessControlTarget {
    None,
    Scope(Filter<FilterValid>),
}

#[derive(Debug, Clone)]
pub enum AccessControlTargetCondition {
    // None,
    Scope(Filter<FilterValidResolved>),
}

#[derive(Debug, Clone)]
pub struct AccessControlProfile {
    pub name: String,
    // Currently we retrieve this but don't use it. We could depending on how we change
    // the acp update routine.
    #[allow(dead_code)]
    uuid: Uuid,
    pub receiver: AccessControlReceiver,
    pub target: AccessControlTarget,
}

// ---- Test seam (not upstream): build a profile; name and uuid are labels. ----

impl AccessControlProfile {
    pub fn difftest_new(receiver: AccessControlReceiver, target: AccessControlTarget) -> Self {
        AccessControlProfile {
            name: String::new(),
            uuid: Uuid::nil(),
            receiver,
            target,
        }
    }
}
