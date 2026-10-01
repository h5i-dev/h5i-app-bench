//! Global account data (the ignore lists) as JSON per user; no room data.
use std::collections::HashMap;

use futures::Stream;
use ruma::{OwnedUserId, RoomId, UserId, events::{AnyRawAccountDataEvent, GlobalAccountDataEventType}};
use serde::de::DeserializeOwned;
use tuwunel_core::{Result, err};

#[derive(Default)]
pub struct Service {
    pub global: HashMap<(OwnedUserId, String), serde_json::Value>,
}

impl Service {
    pub async fn get_global<T: DeserializeOwned>(&self, user_id: &UserId, kind: GlobalAccountDataEventType) -> Result<T> {
        let v = self
            .global
            .get(&(user_id.to_owned(), kind.to_string()))
            .ok_or_else(|| err!(Request(NotFound("no account data"))))?;
        Ok(serde_json::from_value(v.clone())?)
    }

    pub fn changes_since_fallible<'a>(
        &'a self,
        _room_id: Option<&'a RoomId>,
        _user_id: &'a UserId,
        _since: u64,
        _to: Option<u64>,
    ) -> impl Stream<Item = Result<AnyRawAccountDataEvent>> + Send + 'a {
        futures::stream::empty()
    }
}
