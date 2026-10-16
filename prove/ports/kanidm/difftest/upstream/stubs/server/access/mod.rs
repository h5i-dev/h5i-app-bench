// Stub head of `server/access/mod.rs`: the uses and module declarations of
// upstream's, without the cache and SCIM types. The items below are copied.
use hashbrown::HashMap;
use std::{collections::BTreeSet, sync::Arc};

use uuid::Uuid;

use crate::{
    entry::{Entry, EntryInit, EntryNew},
    event::{CreateEvent, DeleteEvent, ModifyEvent, SearchEvent},
    filter::{Filter, FilterValid, ResolveFilterCacheReadTxn},
    modify::Modify,
    prelude::*,
};

use self::profiles::{
    AccessControlCreate, AccessControlCreateResolved, AccessControlDelete,
    AccessControlDeleteResolved, AccessControlModify, AccessControlModifyResolved,
    AccessControlReceiver, AccessControlReceiverCondition, AccessControlSearch,
    AccessControlSearchResolved, AccessControlTarget, AccessControlTargetCondition,
};

use self::{
    create::{apply_create_access, CreateResult},
    delete::{apply_delete_access, DeleteResult},
    modify::{apply_modify_access, ModifyResult},
    search::{apply_search_access, SearchResult},
};

mod create;
mod delete;
mod migration;
mod modify;
pub mod profiles;
mod protected;
mod search;
