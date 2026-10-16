// Copied from matrix-construct/tuwunel @ 7801b8e by extract_upstream.py. Do not edit.
/// Standard item yielded by decoded room timeline streams.
///
/// The count is the event's room-local pagination token. The producer
/// determines whether the decoded PDU receives presentation adjustments.
use futures::Stream;
use futures::StreamExt;
use futures::TryFutureExt;
use futures::TryStreamExt;
use ruma::RoomId;
use ruma::UserId;
use ruma::api::Direction;
use tuwunel_core::Result;
use tuwunel_core::implement;
use tuwunel_core::matrix::pdu::PduCount;
use tuwunel_core::matrix::pdu::PduEvent;
use tuwunel_core::utils::result::LogErr;
use tuwunel_core::utils::stream::TryIgnore;
use tuwunel_core::utils::stream::TryReadyExt;
use tuwunel_core::utils::stream::TryWidebandExt;
use tuwunel_database::KeyVal;
use super::RawPduId;

pub type PdusIterItem = (PduCount, PduEvent);

/// Streams accepted room events after an optional count in forward order.
///
/// The count boundary is exclusive and defaults to the minimum count. The
/// optional user controls presentation only; stream, storage, and decoding
/// errors remain visible to the caller.
#[implement(super::Service)]
#[tracing::instrument(skip(self), level = "debug")]
pub fn pdus<'a>(
	&'a self,
	user_id: Option<&'a UserId>,
	room_id: &'a RoomId,
	from: Option<PduCount>,
) -> impl Stream<Item = Result<PdusIterItem>> + Send + 'a {
	let from = from.unwrap_or_else(PduCount::min);
	self.count_to_id(room_id, from, Direction::Forward)
		.map_ok(move |current| {
			let prefix = current.shortroomid();
			self.db
				.pduid_pdu
				.raw_stream_from(&current)
				.ready_try_take_while(move |(key, _)| Ok(key.starts_with(&prefix)))
				.ready_and_then(move |item| Self::each_slice(item, user_id))
		})
		.try_flatten_stream()
}

/// Streams accepted room events before an optional count in reverse order.
///
/// The count boundary is exclusive and defaults to the maximum count. The
/// optional user controls presentation only; stream, storage, and decoding
/// errors remain visible to the caller.
#[implement(super::Service)]
#[tracing::instrument(skip(self), level = "debug")]
pub fn pdus_rev<'a>(
	&'a self,
	user_id: Option<&'a UserId>,
	room_id: &'a RoomId,
	until: Option<PduCount>,
) -> impl Stream<Item = Result<PdusIterItem>> + Send + 'a {
	let until = until.unwrap_or_else(PduCount::max);
	self.count_to_id(room_id, until, Direction::Backward)
		.map_ok(move |current| {
			let prefix = current.shortroomid();
			self.db
				.pduid_pdu
				.rev_raw_stream_from(&current)
				.ready_try_take_while(move |(key, _)| Ok(key.starts_with(&prefix)))
				.ready_and_then(move |item| Self::each_slice(item, user_id))
		})
		.try_flatten_stream()
}

#[implement(super::Service)]
fn each_slice((pdu_id, pdu): KeyVal<'_>, user_id: Option<&UserId>) -> Result<PdusIterItem> {
	let pdu_id: RawPduId = pdu_id.into();
	let pdu = serde_json::from_slice::<PduEvent>(pdu)?;

	Self::each_pdu((pdu_id, pdu), user_id)
}

#[implement(super::Service)]
fn each_pdu(
	(pdu_id, mut pdu): (RawPduId, PduEvent),
	user_id: Option<&UserId>,
) -> Result<PdusIterItem> {
	pdu.remove_transaction_id_unless_sender(user_id)?;
	pdu.add_age().log_err().ok();

	Ok((pdu_id.pdu_count(), pdu))
}

