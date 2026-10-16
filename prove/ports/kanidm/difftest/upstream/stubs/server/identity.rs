// Stub of `server/identity.rs`: `Identity` keeps the fields the access module
// reads. The enums and methods below the stub are copied.
use crate::prelude::*;
use serde::{Deserialize, Serialize};
use std::{collections::BTreeSet, hash::Hash, sync::Arc};

#[derive(Debug, Clone)]
pub struct Identity {
    pub origin: IdentType,
    pub(crate) scope: AccessScope,
}

impl Identity {
    pub fn difftest_new(origin: IdentType, scope: AccessScope) -> Self {
        Identity { origin, scope }
    }
}
