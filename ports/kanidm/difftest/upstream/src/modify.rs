// Stub of `modify.rs`: the items below are copied.
use crate::prelude::*;
use serde::{Deserialize, Serialize};
use std::slice;

// Copied from kanidm/kanidm @ f608c4f by extract_upstream.py. Do not edit.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct ModifyValid;
#[derive(Debug, Clone)]
#[allow(clippy::large_enum_variant)]
pub enum Modify {
    /// This value *should* exist for this attribute.
    Present(Attribute, Value),
    /// This value *should not* exist for this attribute.
    Removed(Attribute, PartialValue),
    /// This attr should not exist, and if it does exist, will have all content removed.
    Purged(Attribute),
    /// This attr and value must exist *in this state* for this change to proceed.
    Assert(Attribute, PartialValue),
    /// Set and replace the entire content of an attribute. This requires both presence
    /// and removal access to the attribute to proceed.
    Set(Attribute, ValueSet),
}

#[derive(Clone, Debug, Default)]
pub struct ModifyList<VALID> {
    // This is never read, it's just used for state machine enforcement.
    #[allow(dead_code)]
    valid: VALID,
    // The order of this list matters. Each change must be done in order.
    mods: Vec<Modify>,
}

impl ModifyList<ModifyValid> {
    pub fn iter(&self) -> slice::Iter<'_, Modify> {
        self.mods.iter()
    }
}

// ---- Test seam (not upstream): build a modify list. ----

impl ModifyList<ModifyValid> {
    pub fn difftest_new(mods: Vec<Modify>) -> Self {
        ModifyList { valid: ModifyValid, mods }
    }
}
