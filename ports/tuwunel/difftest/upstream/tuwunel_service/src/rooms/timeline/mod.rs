// Copied from matrix-construct/tuwunel @ 7801b8e by extract_upstream.py. Do not edit.
/// Returns the state snapshot after every room event at or before a count.
///
/// The boundary is inclusive because a client's sync position is often the
/// count of the newest event it received, and need not belong to this room.
/// The snapshot precedes the first event strictly after the count, falling
/// back to current state only when no event follows; a count before the room's
/// first recorded snapshot is not found.
use futures::FutureExt;
use futures::TryFutureExt;
use futures::TryStreamExt;
use futures::future::select_ok;
use futures::pin_mut;
use ruma::EventId;
use ruma::OwnedEventId;
use ruma::RoomId;
use ruma::UserId;
use ruma::api::Direction;
use serde::Deserialize;
use tuwunel_core::matrix::pdu::PduId;
use tuwunel_core::matrix::pdu::RawPduId;
use tuwunel_core::Err;
use tuwunel_core::Result;
use tuwunel_core::at;
use tuwunel_core::err;
use tuwunel_core::implement;
use tuwunel_core::matrix::ShortEventId;
use tuwunel_core::matrix::pdu::PduCount;
use tuwunel_core::matrix::pdu::PduEvent;
use tuwunel_core::utils::result::LogErr;
use tuwunel_core::utils::result::NotFound;
use tuwunel_core::utils::stream::TryReadyExt;
use tuwunel_database::Deserialized;
use crate::rooms::short::ShortRoomId;
use crate::rooms::short::ShortStateHash;

mod pdus;
pub use self::pdus::*;

#[implement(Service)]
#[tracing::instrument(skip(self), level = "debug")]
pub async fn shortstatehash_after(
	&self,
	room_id: &RoomId,
	count: PduCount,
) -> Result<ShortStateHash> {
	let shortroomid: ShortRoomId = self
		.services
		.short
		.get_shortroomid(room_id)
		.map_err(|e| err!(Request(NotFound("Room {room_id:?} not found: {e:?}"))))
		.await?;

	let after = PduId { shortroomid, count };
	let count = match self.next_timeline_count(&after).await {
		| Ok(count) => count,
		| Err(e) if !e.is_not_found() => return Err(e),
		| Err(_) => {
			return self
				.services
				.state
				.get_room_shortstatehash(room_id)
				.await;
		},
	};

	let next = PduId { shortroomid, count };
	let shorteventid = self.get_shorteventid_from_pdu_id(&next).await?;

	self.services
		.state
		.get_shortstatehash(shorteventid)
		.await
}

/// Returns the state snapshot at the room event directly after a count.
///
/// The `after` boundary is exclusive and need not identify an existing event
/// or even belong to the room.
#[implement(Service)]
#[tracing::instrument(skip(self), level = "debug")]
pub async fn next_shortstatehash(
	&self,
	room_id: &RoomId,
	after: PduCount,
) -> Result<ShortStateHash> {
	let shortroomid: ShortRoomId = self
		.services
		.short
		.get_shortroomid(room_id)
		.await
		.map_err(|e| err!(Request(NotFound("Room {room_id:?} not found: {e:?}"))))?;

	let after = PduId { shortroomid, count: after };

	let next = PduId {
		shortroomid,
		count: self.next_timeline_count(&after).await?,
	};

	let shorteventid = self.get_shorteventid_from_pdu_id(&next).await?;

	self.services
		.state
		.get_shortstatehash(shorteventid)
		.await
}

/// Returns the room timeline count directly after an encoded PDU ID.
///
/// The boundary is exclusive and need not identify an existing row. Its room
/// component selects the timeline prefix to scan.
#[implement(Service)]
#[tracing::instrument(skip(self), level = "debug")]
pub async fn next_timeline_count(&self, after: &PduId) -> Result<PduCount> {
	let after = Self::pdu_count_to_id(after.shortroomid, after.count, Direction::Forward);

	let pdu_ids = self
		.db
		.pduid_pdu
		.keys_raw_from(&after)
		.ready_try_take_while(|pdu_id: &RawPduId| Ok(pdu_id.is_room_eq(after)))
		.ready_and_then(|pdu_id: RawPduId| Ok(pdu_id.pdu_count()));

	pin_mut!(pdu_ids);
	pdu_ids
		.try_next()
		.await
		.log_err()?
		.ok_or(err!(Request(NotFound("No more PDU's found in room"))))
}

/// Returns the latest normal timeline count at or below an optional bound.
///
/// Backfilled counts are not returned. When no normal event qualifies, the
/// sentinel `PduCount::max()` is returned instead of a not-found error;
/// `sender_user` affects presentation only.
#[implement(Service)]
#[tracing::instrument(skip(self), level = "debug")]
pub async fn last_timeline_count(
	&self,
	sender_user: Option<&UserId>,
	room_id: &RoomId,
	upper_bound: Option<PduCount>,
) -> Result<PduCount> {
	let upper_bound = upper_bound.unwrap_or_else(PduCount::max);
	let pdus_rev = self.pdus_rev(sender_user, room_id, None);

	pin_mut!(pdus_rev);
	let last_count = pdus_rev
		.ready_try_skip_while(|&(pducount, _)| Ok(pducount > upper_bound))
		.try_next()
		.await?
		.map(at!(0))
		.filter(|&count| matches!(count, PduCount::Normal(_)))
		.unwrap_or_else(PduCount::max);

	Ok(last_count)
}

#[implement(Service)]
async fn count_to_id(
	&self,
	room_id: &RoomId,
	count: PduCount,
	dir: Direction,
) -> Result<RawPduId> {
	let shortroomid: ShortRoomId = self
		.services
		.short
		.get_shortroomid(room_id)
		.await
		.map_err(|e| err!(Request(NotFound("Room {room_id:?} not found: {e:?}"))))?;

	Ok(Self::pdu_count_to_id(shortroomid, count, dir))
}

#[implement(Service)]
fn pdu_count_to_id(shortroomid: ShortRoomId, count: PduCount, dir: Direction) -> RawPduId {
	// In raw key order, backfilled zero precedes every stored row. It has no base
	// event, so retaining it keeps the `from` bound exclusive.
	let count = match (count, dir) {
		| (PduCount::Backfilled(0), Direction::Forward) => count,
		| _ => count.saturating_inc(dir),
	};

	let pdu_id = PduId { shortroomid, count };

	pdu_id.into()
}

/// Returns a decoded PDU from accepted or outlier storage.
///
/// Both lookups are polled concurrently, so if duplicate rows exist the first
/// successful lookup determines the returned value.
#[implement(Service)]
pub async fn get_pdu(&self, event_id: &EventId) -> Result<PduEvent> { self.get(event_id).await }

/// Returns a decoded PDU by its accepted timeline ID.
///
/// The accepted row is read directly without consulting the event-ID mapping
/// or outlier storage.
#[implement(Service)]
pub async fn get_pdu_from_id(&self, pdu_id: &RawPduId) -> Result<PduEvent> {
	self.get_from_id(pdu_id).await
}

/// Deserializes an event from accepted or outlier storage into `T`.
///
/// Both lookups are polled concurrently, so if duplicate rows exist the first
/// successful lookup determines the returned value.
#[implement(Service)]
#[inline]
pub async fn get<T>(&self, event_id: &EventId) -> Result<T>
where
	T: for<'de> Deserialize<'de>,
{
	let accepted = self.get_non_outlier(event_id);
	let outlier = self.get_outlier(event_id);

	pin_mut!(accepted, outlier);
	select_ok([accepted.left_future(), outlier.right_future()])
		.await
		.map(at!(0))
}

/// Deserializes an event from outlier storage into `T`.
///
/// Accepted timeline storage is not consulted, and storage or decoding errors
/// propagate to the caller.
#[implement(Service)]
#[inline]
pub async fn get_outlier<T>(&self, event_id: &EventId) -> Result<T>
where
	T: for<'de> Deserialize<'de>,
{
	self.db
		.eventid_outlierpdu
		.get(event_id)
		.await
		.deserialized()
}

/// Deserializes a PDU from the accepted timeline into `T`.
///
/// Resolves the event ID through `eventid_pduid` and reads `pduid_pdu`, without
/// consulting outliers. Storage and decoding errors propagate to the caller.
#[implement(Service)]
#[inline]
pub async fn get_non_outlier<T>(&self, event_id: &EventId) -> Result<T>
where
	T: for<'de> Deserialize<'de>,
{
	let pdu_id = self.get_pdu_id(event_id).await?;

	self.get_from_id(&pdu_id).await
}

/// Deserializes an accepted timeline row into `T` by PDU ID.
///
/// The row is read directly without consulting the event-ID mapping or outlier
/// storage.
#[implement(Service)]
#[inline]
pub async fn get_from_id<T>(&self, pdu_id: &RawPduId) -> Result<T>
where
	T: for<'de> Deserialize<'de>,
{
	self.db.pduid_pdu.get(pdu_id).await.deserialized()
}

/// Returns the room-local timeline count assigned to an accepted event.
///
/// The event ID is resolved through the accepted event-to-PDU mapping.
#[implement(Service)]
pub async fn get_pdu_count(&self, event_id: &EventId) -> Result<PduCount> {
	self.get_pdu_id(event_id)
		.await
		.map(RawPduId::pdu_count)
}

/// Returns the short event ID represented by an accepted PDU ID.
///
/// The accepted row supplies the full event ID, which is then resolved through
/// the short-ID service.
#[implement(Service)]
pub async fn get_shorteventid_from_pdu_id(&self, pdu_id: &PduId) -> Result<ShortEventId> {
	let event_id = self.get_event_id_from_pdu_id(pdu_id).await?;

	self.services
		.short
		.get_shorteventid(&event_id)
		.await
}

/// Returns the event ID stored at an accepted PDU ID.
///
/// The accepted row is decoded as a PDU to recover its event ID.
#[implement(Service)]
pub async fn get_event_id_from_pdu_id(&self, pdu_id: &PduId) -> Result<OwnedEventId> {
	let pdu_id: RawPduId = (*pdu_id).into();

	self.get_pdu_from_id(&pdu_id)
		.map_ok(|pdu| pdu.event_id)
		.await
}

/// Returns the accepted timeline ID associated with an event.
///
/// Outlier storage is not consulted because outliers have no room timeline
/// position.
#[implement(Service)]
pub async fn get_pdu_id(&self, event_id: &EventId) -> Result<RawPduId> {
	self.db
		.eventid_pduid
		.get(event_id)
		.await
		.map(|handle| RawPduId::from(&*handle))
}


mod stub;
pub use stub::*;
