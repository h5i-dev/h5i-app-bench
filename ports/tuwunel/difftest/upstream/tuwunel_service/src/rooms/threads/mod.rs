// Copied from matrix-construct/tuwunel @ 7801b8e by extract_upstream.py. Do not edit.
use futures::Stream;
use futures::StreamExt;
use futures::TryFutureExt;
use ruma::RoomId;
use ruma::UserId;
use ruma::api::client::threads::get_threads::v1::IncludeThreads;
use serde::Deserialize;
use tuwunel_core::Event;
use tuwunel_core::Result;
use tuwunel_core::matrix::pdu::PduCount;
use tuwunel_core::matrix::pdu::PduEvent;
use tuwunel_core::matrix::pdu::PduId;
use tuwunel_core::matrix::pdu::RawPduId;
use tuwunel_core::utils::ReadyExt;
use tuwunel_core::utils::stream::TryIgnore;
use tuwunel_core::utils::stream::WidebandExt;
use tuwunel_database::Deserialized;

impl Service {
	pub fn threads_until<'a>(
		&'a self,
		user_id: &'a UserId,
		room_id: &'a RoomId,
		count: PduCount,
		include: &'a IncludeThreads,
	) -> impl Stream<Item = Result<(PduCount, PduEvent)>> + Send {
		let participated = matches!(include, IncludeThreads::Participated);

		self.services
			.short
			.get_shortroomid(room_id)
			.map_ok(move |shortroomid| PduId {
				shortroomid,
				count: count.saturating_sub(1),
			})
			.map_ok(Into::into)
			.map_ok(move |current: RawPduId| {
				self.db
					.threadactivityid_rootid
					.rev_raw_stream_from(&current)
					.ignore_err()
					.map(|(key, root_id)| (RawPduId::from(key), RawPduId::from(root_id)))
					.ready_take_while(move |(activity_id, _)| {
						activity_id.shortroomid() == current.shortroomid()
					})
					.map(move |(activity_id, root_id)| {
						(activity_id, root_id, user_id, participated)
					})
					.wide_filter_map(async |(activity_id, root_id, user_id, participated)| {
						self.live_thread(user_id, participated, activity_id, root_id)
							.await
					})
					.map(Ok)
			})
			.try_flatten_stream()
	}

	/// Resolve one activity row to its thread root, skipping and reaping rows
	/// the validity pointer has left behind.
	async fn live_thread(
		&self,
		user_id: &UserId,
		participated: bool,
		activity_id: RawPduId,
		root_id: RawPduId,
	) -> Option<(PduCount, PduEvent)> {
		let count = activity_id.pdu_count();

		let pointer = self
			.db
			.threadrootid_latestcount
			.get(&root_id)
			.await
			.deserialized()
			.map(PduCount::from_unsigned)
			.ok()?;

		if count != pointer {
			// A row ahead of the pointer is a write in flight; only rows behind
			// the pointer are dead and safe to reap.
			if count < pointer {
				self.db
					.threadactivityid_rootid
					.remove(&activity_id);
			}

			return None;
		}

		if participated && !self.is_participant(&root_id, user_id).await {
			return None;
		}

		let mut pdu = self
			.services
			.timeline
			.get_pdu_from_id(&root_id)
			.await
			.ok()?;

		pdu.remove_transaction_id_unless_sender(Some(user_id))
			.ok()?;

		Some((count, pdu))
	}

	async fn is_participant(&self, root_id: &RawPduId, user_id: &UserId) -> bool {
		self.db
			.threadid_userids
			.get(root_id)
			.await
			.is_ok_and(|participants| {
				participants
					.split(|&byte| byte == 0xFF)
					.any(|user| user == user_id.as_bytes())
			})
	}

}

mod stub;
pub use stub::*;
