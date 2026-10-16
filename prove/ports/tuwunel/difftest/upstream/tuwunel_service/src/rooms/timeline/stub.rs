use ruma::{EventId, RoomId};
use tuwunel_core::{PduCount, Result, err};
use tuwunel_database::Map;

use crate::Svc;

#[derive(Default)]
pub struct Data {
    pub pduid_pdu: Map,
    pub eventid_pduid: Map,
    pub eventid_outlierpdu: Map,
}

pub struct Service {
    pub db: Data,
    pub services: Svc,
}

/// Federation is off: nothing to backfill or fetch.
impl Service {
    pub async fn backfill_if_required(&self, _room_id: &RoomId, _from: PduCount) -> Result {
        Ok(())
    }

    pub async fn fetch_remote_event(&self, _room_id: &RoomId, _event_id: &EventId) -> Result {
        Err(err!(Request(NotFound("federation is off"))))
    }
}
