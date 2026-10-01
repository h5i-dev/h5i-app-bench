//! `pdu_metadata`: the relation index (`relations.rs` is copied); bundled
//! aggregations and the ignored-thread view change presentation only and
//! leave the PDU as it is.
use std::collections::BTreeSet;

use ruma::{OwnedUserId, UserId, events::AnySyncMessageLikeEvent, serde::Raw};
use tuwunel_core::PduEvent;
use tuwunel_database::Map;

use crate::Svc;

mod relations;

#[derive(Default)]
pub struct Data {
    pub tofrom_relation: Map,
}

pub struct Service {
    pub db: Data,
    pub services: Svc,
}

pub enum IgnoredThreadView {
    Unchanged,
    WithoutSummary { root: Option<Box<PduEvent>> },
    Adjusted { root: Option<Box<PduEvent>>, count: Option<usize>, latest: Option<Raw<AnySyncMessageLikeEvent>> },
}

impl Service {
    pub async fn bundle_aggregations(&self, _sender_user: &UserId, pdu: PduEvent) -> PduEvent {
        pdu
    }

    pub async fn ignored_thread_view(&self, _sender_user: &UserId, _ignored: &BTreeSet<OwnedUserId>, _pdu: &PduEvent) -> IgnoredThreadView {
        IgnoredThreadView::Unchanged
    }
}
