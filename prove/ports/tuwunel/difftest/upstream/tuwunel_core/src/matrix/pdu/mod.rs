//! The PDU as stored in `pduid_pdu`, with the copied count and id types.
mod count;
mod id;
mod raw_id;

use ruma::{OwnedEventId, OwnedRoomId, OwnedUserId, UInt, UserId, events::{TimelineEventType, room::member::MembershipState}};
use serde::{Deserialize, Serialize};
use serde_json::value::RawValue as RawJsonValue;

pub use self::{Count as PduCount, Id as PduId, Pdu as PduEvent, RawId as RawPduId, count::Count, id::Id, raw_id::*};
use super::ShortRoomId;
use crate::Result;

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Pdu {
    #[serde(rename = "type")]
    pub kind: TimelineEventType,
    pub content: Box<RawJsonValue>,
    pub event_id: OwnedEventId,
    pub room_id: OwnedRoomId,
    pub sender: OwnedUserId,
    #[serde(skip_serializing_if = "Option::is_none", default)]
    pub state_key: Option<String>,
    pub origin_server_ts: UInt,
    #[serde(skip_serializing_if = "Option::is_none", default)]
    pub unsigned: Option<Box<RawJsonValue>>,
}

/// The `unsigned` edits; presentation only, so they keep the PDU.
impl Pdu {
    pub fn remove_transaction_id_unless_sender(&mut self, _user_id: Option<&UserId>) -> Result {
        Ok(())
    }
    pub fn add_age(&mut self) -> Result {
        Ok(())
    }
    pub fn add_membership(&mut self, _membership: &MembershipState) -> Result {
        Ok(())
    }
    pub fn remove_thread_bundle(&mut self) -> Result {
        Ok(())
    }
    pub fn remove_replacement_bundle(&mut self) -> Result {
        Ok(())
    }
    pub fn set_thread_count(&mut self, _count: usize) -> Result {
        Ok(())
    }
    pub fn set_thread_latest_event<T>(&mut self, _latest: &T) -> Result {
        Ok(())
    }
}

impl PartialEq for Pdu {
    fn eq(&self, o: &Self) -> bool {
        self.event_id == o.event_id
    }
}
