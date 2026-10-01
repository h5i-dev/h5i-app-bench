// Copied from matrix-construct/tuwunel @ 7801b8e by extract_upstream.py. Do not edit.
/// Reports whether a user was joined in a selected state snapshot.
///
/// Missing or invalid membership state is treated as `leave`, so lookup errors
/// return `false`.
use std::ops::Deref;
use std::sync::Arc;
use futures::FutureExt;
use futures::Stream;
use futures::StreamExt;
use futures::TryFutureExt;
use futures::TryStreamExt;
use ruma::OwnedEventId;
use ruma::UserId;
use ruma::events::StateEventType;
use ruma::events::TimelineEventType;
use ruma::events::room::member::MembershipState;
use ruma::events::room::member::RoomMemberEventContent;
use serde::Deserialize;
use tuwunel_core::Result;
use tuwunel_core::at;
use tuwunel_core::err;
use tuwunel_core::implement;
use tuwunel_core::matrix::Event;
use tuwunel_core::matrix::Pdu;
use tuwunel_core::matrix::StateKey;
use tuwunel_core::utils::result::FlatOk;
use tuwunel_core::utils::stream::BroadbandExt;
use tuwunel_core::utils::stream::IterStream;
use tuwunel_core::utils::stream::ReadyExt;
use tuwunel_core::utils::stream::TryBroadbandExt;
use tuwunel_core::utils::stream::TryIgnore;
use tuwunel_core::utils::stream::TryTools;
use crate::rooms::short::ShortEventId;
use crate::rooms::short::ShortStateHash;
use crate::rooms::short::ShortStateKey;
use crate::rooms::state_compressor::CompressedState;
use crate::rooms::state_compressor::compress_state_event;
use crate::rooms::state_compressor::parse_compressed_state_event;

#[implement(super::Service)]
#[inline]
pub async fn user_was_joined(&self, shortstatehash: ShortStateHash, user_id: &UserId) -> bool {
	self.user_membership(shortstatehash, user_id)
		.await == MembershipState::Join
}

/// Reports whether a user was invited or joined in a selected state snapshot.
///
/// Missing or invalid membership state is treated as `leave`, so lookup errors
/// return `false`.
#[implement(super::Service)]
#[inline]
pub async fn user_was_invited(&self, shortstatehash: ShortStateHash, user_id: &UserId) -> bool {
	let s = self
		.user_membership(shortstatehash, user_id)
		.await;
	s == MembershipState::Join || s == MembershipState::Invite
}

/// Returns a user's membership in a selected state snapshot.
///
/// Missing state, unavailable events, and invalid membership content all fall
/// back to [`MembershipState::Leave`].
#[implement(super::Service)]
pub async fn user_membership(
	&self,
	shortstatehash: ShortStateHash,
	user_id: &UserId,
) -> MembershipState {
	self.state_get_content(shortstatehash, &StateEventType::RoomMember, user_id.as_str())
		.await
		.map_or(MembershipState::Leave, |c: RoomMemberEventContent| c.membership)
}

/// MSC4115: the user's room membership "just after" the given PDU landed.
///
/// `pdu_shortstatehash` returns state-before-the-event, so a member event
/// targeting `user_id` overrides that lookup with its own content. Missing or
/// invalid state falls back to [`MembershipState::Leave`].
#[implement(super::Service)]
pub async fn user_membership_at_pdu(&self, user_id: &UserId, pdu: &Pdu) -> MembershipState {
	if pdu.kind() == &TimelineEventType::RoomMember
		&& pdu.state_key() == Some(user_id.as_str())
		&& let Ok(content) = pdu.get_content::<RoomMemberEventContent>()
	{
		return content.membership;
	}

	let Ok(shortstatehash) = self
		.services
		.state
		.pdu_shortstatehash(pdu.event_id())
		.await
	else {
		return MembershipState::Leave;
	};

	self.user_membership(shortstatehash, user_id)
		.await
}

/// Deserializes one event's content from a selected state snapshot.
///
/// The event is selected by `(event_type, state_key)`. State, short-ID,
/// timeline, and content errors are returned to the caller.
#[implement(super::Service)]
pub async fn state_get_content<T>(
	&self,
	shortstatehash: ShortStateHash,
	event_type: &StateEventType,
	state_key: &str,
) -> Result<T>
where
	T: for<'de> Deserialize<'de> + Send,
{
	self.state_get(shortstatehash, event_type, state_key)
		.await
		.and_then(|event| event.get_content())
}

/// Returns one PDU from a selected state snapshot.
///
/// The event is selected by `(event_type, state_key)`. Short-ID and timeline
/// lookup failures are returned to the caller.
#[implement(super::Service)]
pub async fn state_get(
	&self,
	shortstatehash: ShortStateHash,
	event_type: &StateEventType,
	state_key: &str,
) -> Result<Pdu> {
	let event_id: OwnedEventId = self
		.state_get_id(shortstatehash, event_type, state_key)
		.await?;

	self.services.timeline.get_pdu(&event_id).await
}

/// Returns one event ID from a selected state snapshot.
///
/// Both the state tuple's short key and its short event ID must resolve.
#[implement(super::Service)]
pub async fn state_get_id(
	&self,
	shortstatehash: ShortStateHash,
	event_type: &StateEventType,
	state_key: &str,
) -> Result<OwnedEventId> {
	let shorteventid = self
		.state_get_shortid(shortstatehash, event_type, state_key)
		.await?;

	self.services
		.short
		.get_eventid_from_short(shorteventid)
		.await
}

/// Returns one short event ID from a selected state snapshot.
///
/// The method resolves `(event_type, state_key)` to a short state key and
/// searches the compressed snapshot. An absent tuple is returned as not found.
#[implement(super::Service)]
pub async fn state_get_shortid(
	&self,
	shortstatehash: ShortStateHash,
	event_type: &StateEventType,
	state_key: &str,
) -> Result<ShortEventId> {
	let shortstatekey = self
		.services
		.short
		.get_shortstatekey(event_type, state_key)
		.await?;

	let start = compress_state_event(shortstatekey, 0);
	let end = compress_state_event(shortstatekey, u64::MAX);
	self.load_full_state(shortstatehash)
		.map_ok(|full_state| {
			full_state
				.range(start..=end)
				.next()
				.copied()
				.map(parse_compressed_state_event)
				.map(at!(1))
				.ok_or(err!(Request(NotFound("Not found in room state"))))
		})
		.await?
}

/// Streams resolvable keyed events from a state snapshot.
///
/// Events without a state key and entries with failed short-ID or timeline
/// lookups are omitted by the underlying best-effort PDU stream.
#[implement(super::Service)]
pub fn state_full(
	&self,
	shortstatehash: ShortStateHash,
) -> impl Stream<Item = ((StateEventType, StateKey), impl Event)> + Send + '_ {
	self.state_full_pdus(shortstatehash)
		.ready_filter_map(|pdu| {
			Some(((pdu.kind().to_cow_str().into(), pdu.state_key()?.into()), pdu))
		})
}

/// Streams every resolvable PDU from a state snapshot.
///
/// Snapshot, reverse-mapping, and timeline failures are silently skipped. Use
/// [`Self::state_full_pdus_strict`] when completeness is required.
#[implement(super::Service)]
pub fn state_full_pdus(
	&self,
	shortstatehash: ShortStateHash,
) -> impl Stream<Item = impl Event> + Send + '_ {
	let short_ids = self
		.state_full_shortids(shortstatehash)
		.ignore_err()
		.map(at!(1));

	self.services
		.short
		.multi_get_eventid_from_short(short_ids)
		.ready_filter_map(Result::ok)
		.broad_filter_map(async |event_id: OwnedEventId| {
			self.services
				.timeline
				.get_pdu(&event_id)
				.await
				.ok()
		})
}

/// Streams every PDU in a state snapshot while preserving errors.
///
/// Snapshot and reverse-mapping failures are emitted before any partial ID map.
/// Timeline lookup failures are yielded for their individual entries.
#[implement(super::Service)]
pub fn state_full_pdus_strict(
	&self,
	shortstatehash: ShortStateHash,
) -> impl Stream<Item = Result<impl Event>> + Send + '_ {
	self.state_full_ids_strict(shortstatehash)
		.broad_and_then(async |(_, event_id)| self.services.timeline.get_pdu(&event_id).await)
}

/// Streams short state keys and resolvable event IDs from a snapshot.
///
/// Snapshot and reverse-mapping failures are skipped, so this best-effort
/// stream can be partial. Use [`Self::state_full_ids_strict`] for completeness.
#[implement(super::Service)]
pub fn state_full_ids(
	&self,
	shortstatehash: ShortStateHash,
) -> impl Stream<Item = (ShortStateKey, OwnedEventId)> + Send + '_ {
	self.state_full_shortids(shortstatehash)
		.ignore_err()
		.unzip()
		.map(|(shortstatekeys, shorteventids): (Vec<_>, Vec<_>)| {
			self.services
				.short
				.multi_get_eventid_from_short(shorteventids.into_iter().stream())
				.zip(shortstatekeys.into_iter().stream())
				.ready_filter_map(|(eid, ssk)| eid.ok().map(|eid| (ssk, eid)))
		})
		.flatten_stream()
}

/// Streams a complete short-state-key to event-ID map for a snapshot.
///
/// Snapshot and reverse-mapping failures are returned without yielding a
/// partial map.
#[implement(super::Service)]
pub fn state_full_ids_strict(
	&self,
	shortstatehash: ShortStateHash,
) -> impl Stream<Item = Result<(ShortStateKey, OwnedEventId)>> + Send + '_ {
	self.state_full_shortids(shortstatehash)
		.try_unzip::<Vec<_>, Vec<_>>()
		.and_then(async move |(shortstatekeys, shorteventids)| {
			self.services
				.short
				.multi_get_eventid_from_short(shorteventids.into_iter().stream())
				.zip(shortstatekeys.into_iter().stream())
				.map(|(event_id, shortstatekey)| {
					event_id.map(|event_id| (shortstatekey, event_id))
				})
				.try_collect::<Vec<_>>()
				.await
		})
		.map_ok(Vec::into_iter)
		.map_ok(IterStream::try_stream)
		.try_flatten_stream()
}

/// Streams every compressed `(short state key, short event ID)` pair.
///
/// A snapshot-load failure is yielded as an error. Once loaded, the immutable
/// compressed state is copied into the stream without further lookups.
#[implement(super::Service)]
pub fn state_full_shortids(
	&self,
	shortstatehash: ShortStateHash,
) -> impl Stream<Item = Result<(ShortStateKey, ShortEventId)>> + Send + '_ {
	self.load_full_state(shortstatehash)
		.map_ok(|full_state| {
			full_state
				.deref()
				.iter()
				.copied()
				.map(parse_compressed_state_event)
				.collect()
		})
		.map_ok(Vec::into_iter)
		.map_ok(IterStream::try_stream)
		.try_flatten_stream()
}

#[implement(super::Service)]
#[tracing::instrument(name = "load", level = "debug", skip(self))]
async fn load_full_state(&self, shortstatehash: ShortStateHash) -> Result<Arc<CompressedState>> {
	self.services
		.state_compressor
		.load_shortstatehash_info(shortstatehash)
		.map_err(|e| err!(Database("Missing state IDs: {e}")))
		.map_ok(|vec| {
			vec.last()
				.expect("at least one layer")
				.full_state
				.clone()
		})
		.await
}

