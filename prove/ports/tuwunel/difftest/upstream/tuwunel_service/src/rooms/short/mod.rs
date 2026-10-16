//! The short-id maps, read as upstream's `short` service does.
use futures::{Stream, StreamExt};
use ruma::{EventId, OwnedEventId, RoomId, events::StateEventType};
use tuwunel_core::{Error, Result, err, matrix::StateKey};
use tuwunel_database::{Deserialized, Map};

pub use tuwunel_core::matrix::{ShortEventId, ShortId, ShortRoomId, ShortStateKey};
pub type ShortStateHash = ShortId;

#[derive(Default)]
pub struct Data {
    pub eventid_shorteventid: Map,
    pub shorteventid_eventid: Map,
    pub statekey_shortstatekey: Map,
    pub shortstatekey_statekey: Map,
    pub roomid_shortroomid: Map,
}

#[derive(Default)]
pub struct Service {
    pub db: Data,
}

impl Service {
    pub async fn get_shorteventid(&self, event_id: &EventId) -> Result<ShortEventId> {
        self.db.eventid_shorteventid.get(event_id).await.deserialized()
    }

    pub async fn get_shortstatekey(&self, event_type: &StateEventType, state_key: &str) -> Result<ShortStateKey> {
        let key = (event_type.to_string(), state_key);
        self.db.statekey_shortstatekey.qry(&(key.0.as_str(), key.1)).await.deserialized()
    }

    pub async fn get_eventid_from_short(&self, shorteventid: ShortEventId) -> Result<OwnedEventId> {
        self.db
            .shorteventid_eventid
            .get(&shorteventid)
            .await
            .deserialized()
            .map_err(|_| err!(Database("Failed to find EventId from short")))
    }

    pub fn multi_get_eventid_from_short<'a, S>(&'a self, shorteventid: S) -> impl Stream<Item = Result<OwnedEventId>> + Send + 'a
    where
        S: Stream<Item = ShortEventId> + Send + 'a,
    {
        shorteventid.then(async |s| self.db.shorteventid_eventid.get(&s).await.deserialized())
    }

    pub async fn get_statekey_from_short(&self, shortstatekey: ShortStateKey) -> Result<(StateEventType, StateKey)> {
        let v = self.db.shortstatekey_statekey.get(&shortstatekey).await?;
        let i = v.iter().position(|&b| b == 0xFF).ok_or(Error::Database)?;
        let t = std::str::from_utf8(&v[..i]).map_err(|_| Error::Database)?;
        let k = std::str::from_utf8(&v[i + 1..]).map_err(|_| Error::Database)?;
        Ok((StateEventType::from(t), StateKey::from(k)))
    }

    pub fn multi_get_statekey_from_short<'a, S>(&'a self, shortstatekey: S) -> impl Stream<Item = Result<(StateEventType, StateKey)>> + Send + 'a
    where
        S: Stream<Item = ShortStateKey> + Send + 'a,
    {
        shortstatekey.then(async |s| self.get_statekey_from_short(s).await)
    }

    pub async fn get_shortroomid(&self, room_id: &RoomId) -> Result<ShortRoomId> {
        self.db.roomid_shortroomid.get(room_id).await.deserialized()
    }
}
