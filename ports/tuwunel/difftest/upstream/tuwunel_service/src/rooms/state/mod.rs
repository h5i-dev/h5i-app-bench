// Copied from matrix-construct/tuwunel @ 7801b8e by extract_upstream.py. Do not edit.
use futures::FutureExt;
use futures::Stream;
use futures::StreamExt;
use futures::TryFutureExt;
use futures::TryStreamExt;
use ruma::EventId;
use ruma::RoomId;
use tuwunel_core::Event;
use tuwunel_core::Result;
use tuwunel_core::implement;
use tuwunel_core::result::FlatOk;
use tuwunel_core::result::NotFound;
use tuwunel_core::trace;
use tuwunel_core::utils::BoolExt;
use tuwunel_core::utils::IterStream;
use tuwunel_core::utils::ReadyExt;
use tuwunel_core::utils::TryReadyExt;
use tuwunel_core::utils::stream::TryBroadbandExt;
use tuwunel_core::utils::stream::TryIgnore;
use tuwunel_core::utils::stream::WidebandExt;
use tuwunel_database::Deserialized;
use crate::rooms::short::ShortEventId;
use crate::rooms::short::ShortStateHash;

#[implement(Service)]
#[tracing::instrument(
	level = "debug"
	skip(self),
	ret(level = "trace"),
)]
/// Returns the short hash of a room's current state snapshot.
///
/// The lookup reads only the current room-to-state mapping and does not
/// reconstruct the snapshot.
pub async fn get_room_shortstatehash(&self, room_id: &RoomId) -> Result<ShortStateHash> {
	self.db
		.roomid_shortstatehash
		.get(room_id)
		.await
		.deserialized()
}

/// Returns the state hash recorded for an event.
///
/// The event ID is first resolved to its short event ID before the snapshot
/// association is read.
#[implement(Service)]
pub async fn pdu_shortstatehash(&self, event_id: &EventId) -> Result<ShortStateHash> {
	self.services
		.short
		.get_shorteventid(event_id)
		.and_then(|shorteventid| self.get_shortstatehash(shorteventid))
		.await
}

#[implement(Service)]
#[tracing::instrument(
	level = "debug"
	skip(self),
	ret(level = "trace"),
)]
/// Returns the state hash recorded for a short event ID.
///
/// This is the direct lookup used after an event ID has already been shortened.
pub async fn get_shortstatehash(&self, shorteventid: ShortEventId) -> Result<ShortStateHash> {
	const BUFSIZE: usize = size_of::<ShortEventId>();

	self.db
		.shorteventid_shortstatehash
		.aqry::<BUFSIZE, _>(&shorteventid)
		.await
		.deserialized()
}


mod stub;
pub use stub::*;
