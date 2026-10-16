//! The `Event` trait, reduced to the accessors the copied code calls.
mod filter;
mod relation;

use ruma::{EventId, RoomId, UInt, UserId, events::TimelineEventType, serde::Raw};
use serde::de::DeserializeOwned;
use serde_json::value::RawValue as RawJsonValue;

pub use self::{filter::Matches, relation::RelationTypeEqual};
use super::Pdu;
use crate::Result;

pub type StateKey = String;

/// A served event: `into_format` keeps the PDU's JSON.
pub trait FromPdu {
    fn from_pdu(pdu: Pdu) -> Self;
}

impl<T> FromPdu for Raw<T> {
    fn from_pdu(pdu: Pdu) -> Self {
        Raw::from_json_value(serde_json::to_value(&pdu).expect("pdu serializes"))
    }
}

pub trait Event: Send + Sync + Sized {
    fn as_pdu(&self) -> &Pdu;
    fn into_pdu(self) -> Pdu;

    fn kind(&self) -> &TimelineEventType {
        &self.as_pdu().kind
    }
    fn sender(&self) -> &UserId {
        &self.as_pdu().sender
    }
    fn room_id(&self) -> &RoomId {
        &self.as_pdu().room_id
    }
    fn event_id(&self) -> &EventId {
        &self.as_pdu().event_id
    }
    fn state_key(&self) -> Option<&str> {
        self.as_pdu().state_key.as_deref()
    }
    fn content(&self) -> &RawJsonValue {
        &self.as_pdu().content
    }
    fn unsigned(&self) -> Option<&RawJsonValue> {
        self.as_pdu().unsigned.as_deref()
    }
    fn origin_server_ts(&self) -> UInt {
        self.as_pdu().origin_server_ts
    }
    fn get_content<T: DeserializeOwned>(&self) -> Result<T> {
        Ok(serde_json::from_str(self.content().get())?)
    }
    fn get_content_as_value(&self) -> serde_json::Value {
        serde_json::from_str(self.content().get()).expect("content is JSON")
    }
    fn is_redacted(&self) -> bool {
        false
    }
    fn into_format<T: FromPdu>(self) -> T {
        T::from_pdu(self.into_pdu())
    }
}

impl Event for Pdu {
    fn as_pdu(&self) -> &Pdu {
        self
    }
    fn into_pdu(self) -> Pdu {
        self
    }
}

impl Event for &Pdu {
    fn as_pdu(&self) -> &Pdu {
        self
    }
    fn into_pdu(self) -> Pdu {
        self.clone()
    }
}
