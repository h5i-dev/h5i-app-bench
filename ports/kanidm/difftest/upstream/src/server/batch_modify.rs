// Stub of `server/batch_modify.rs`: the type and struct below are copied.
use crate::prelude::*;
use std::collections::BTreeMap;

// Copied from kanidm/kanidm @ f608c4f by extract_upstream.py. Do not edit.
pub type ModSetValid = BTreeMap<Uuid, ModifyList<ModifyValid>>;

pub struct BatchModifyEvent {
    pub ident: Identity,
    pub modset: ModSetValid,
}
