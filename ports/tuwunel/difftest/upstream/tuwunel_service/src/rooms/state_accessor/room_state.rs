// Copied from matrix-construct/tuwunel @ 7801b8e by extract_upstream.py. Do not edit.
/// Deserializes one current state event's content.
///
/// The event is selected by `(event_type, state_key)`. Snapshot lookup,
/// timeline lookup, and content errors are returned to the caller.
use futures::Stream;
use futures::StreamExt;
use futures::TryFutureExt;
use ruma::RoomId;
use ruma::events::StateEventType;
use serde::Deserialize;
use tuwunel_core::Result;
use tuwunel_core::err;
use tuwunel_core::implement;
use tuwunel_core::matrix::Event;
use tuwunel_core::matrix::Pdu;
use tuwunel_core::matrix::StateKey;

#[implement(super::Service)]
pub async fn room_state_get_content<T>(
	&self,
	room_id: &RoomId,
	event_type: &StateEventType,
	state_key: &str,
) -> Result<T>
where
	T: for<'de> Deserialize<'de> + Send,
{
	self.room_state_get(room_id, event_type, state_key)
		.await
		.and_then(|event| event.get_content())
}

/// Streams the room's full current state with type and state keys.
///
/// Failure to resolve the current snapshot is yielded as an error. Entries
/// whose IDs, PDUs, or state keys cannot be resolved are skipped.
#[implement(super::Service)]
#[tracing::instrument(skip(self), level = "debug")]
pub fn room_state_full<'a>(
	&'a self,
	room_id: &'a RoomId,
) -> impl Stream<Item = Result<((StateEventType, StateKey), impl Event)>> + Send + 'a {
	self.services
		.state
		.get_room_shortstatehash(room_id)
		.map_ok(|shortstatehash| self.state_full(shortstatehash).map(Ok))
		.map_err(move |e| err!(Database("Missing state for {room_id:?}: {e:?}")))
		.try_flatten_stream()
}

/// Streams every resolvable PDU in the room's current state.
///
/// Failure to resolve the current snapshot is yielded as an error. Individual
/// state entries with missing reverse mappings or PDUs are skipped.
#[implement(super::Service)]
#[tracing::instrument(skip(self), level = "debug")]
pub fn room_state_full_pdus<'a>(
	&'a self,
	room_id: &'a RoomId,
) -> impl Stream<Item = Result<impl Event>> + Send + 'a {
	self.services
		.state
		.get_room_shortstatehash(room_id)
		.map_ok(|shortstatehash| self.state_full_pdus(shortstatehash).map(Ok))
		.map_err(move |e| err!(Database("Missing state for {room_id:?}: {e:?}")))
		.try_flatten_stream()
}

/// Returns one current state PDU.
///
/// The event is selected by `(event_type, state_key)`. Snapshot, short-ID, and
/// timeline lookup failures are returned to the caller.
#[implement(super::Service)]
#[tracing::instrument(skip(self), level = "debug")]
pub async fn room_state_get(
	&self,
	room_id: &RoomId,
	event_type: &StateEventType,
	state_key: &str,
) -> Result<Pdu> {
	self.services
		.state
		.get_room_shortstatehash(room_id)
		.and_then(|shortstatehash| self.state_get(shortstatehash, event_type, state_key))
		.await
}

