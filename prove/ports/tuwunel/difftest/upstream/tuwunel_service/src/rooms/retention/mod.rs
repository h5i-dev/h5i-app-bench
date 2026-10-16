use ruma::EventId;
use tuwunel_core::{PduEvent, Result, err};

pub struct Service;

impl Service {
    pub async fn get_original_pdu(&self, _event_id: &EventId) -> Result<PduEvent> {
        Err(err!(Request(NotFound("not retained"))))
    }
}
