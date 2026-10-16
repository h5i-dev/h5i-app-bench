//! Lazy loading is off in the tests; these types let the copied code build.
use std::collections::HashSet;

use ruma::{DeviceId, OwnedUserId, RoomId, UserId};

pub use ruma::api::client::filter::LazyLoadOptions as Options;

pub type Witness = HashSet<OwnedUserId>;

pub enum Mode {
    Update,
}

pub struct Context<'a> {
    pub user_id: &'a UserId,
    pub device_id: Option<&'a DeviceId>,
    pub room_id: &'a RoomId,
    pub token: Option<u64>,
    pub options: Option<&'a Options>,
    pub mode: Mode,
}

pub struct Service;

impl Service {
    pub async fn witness_retain(&self, witness: Witness, _ctx: &Context<'_>) -> Witness {
        witness
    }
}
