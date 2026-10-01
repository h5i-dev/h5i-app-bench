//! Full state snapshots, as `load_shortstatehash_info` returns them (one
//! layer). `compress_state_event` and `parse_compressed_state_event` are
//! upstream's.
use std::{collections::{BTreeSet, HashMap}, sync::Arc};

use tuwunel_core::{Result, err, utils::u64_from_u8};

use super::short::{ShortEventId, ShortStateHash, ShortStateKey};

pub type CompressedStateEvent = [u8; 16];
pub type CompressedState = BTreeSet<CompressedStateEvent>;

#[derive(Clone, Default)]
pub struct ShortStateInfo {
    pub shortstatehash: ShortStateHash,
    pub full_state: Arc<CompressedState>,
}

#[derive(Default)]
pub struct Service {
    pub snapshots: HashMap<ShortStateHash, Arc<CompressedState>>,
}

impl Service {
    pub async fn load_shortstatehash_info(&self, shortstatehash: ShortStateHash) -> Result<Vec<ShortStateInfo>> {
        match self.snapshots.get(&shortstatehash) {
            Some(s) => Ok(vec![ShortStateInfo { shortstatehash, full_state: s.clone() }]),
            None => Err(err!(Request(NotFound("no such state")))),
        }
    }
}

pub fn compress_state_event(shortstatekey: ShortStateKey, shorteventid: ShortEventId) -> CompressedStateEvent {
    let mut v = [0u8; 16];
    v[..8].copy_from_slice(&shortstatekey.to_be_bytes());
    v[8..].copy_from_slice(&shorteventid.to_be_bytes());
    v
}

pub fn parse_compressed_state_event(compressed_event: CompressedStateEvent) -> (ShortStateKey, ShortEventId) {
    (u64_from_u8(&compressed_event[0..8]), u64_from_u8(&compressed_event[8..]))
}
