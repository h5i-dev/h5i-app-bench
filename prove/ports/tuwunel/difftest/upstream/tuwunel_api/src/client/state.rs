// Copied from matrix-construct/tuwunel @ 7801b8e by extract_upstream.py. Do not edit.
/// # `GET /_matrix/client/v3/rooms/{roomid}/state`
///
/// Get all state events for a room.
///
/// - If not joined: Only works if current room history visibility is world
///   readable
use axum::extract::State;
use futures::FutureExt;
use futures::TryFutureExt;
use futures::TryStreamExt;
use ruma::api::client::state::get_state_event_for_key;
use ruma::api::client::state::get_state_event_for_key::v3::StateEventFormat;
use ruma::api::client::state::get_state_events;
use serde_json::json;
use serde_json::value::to_raw_value;
use tuwunel_core::Err;
use tuwunel_core::Result;
use tuwunel_core::err;
use tuwunel_core::matrix::Event;
use tuwunel_core::result::NotFound;
use tuwunel_core::utils::BoolExt;
use tuwunel_core::utils::stream::TryBroadbandExt;
use crate::Ruma;
use crate::client::with_membership;

pub(crate) async fn get_state_events_route(
	State(services): State<crate::State>,
	body: Ruma<get_state_events::v3::Request>,
) -> Result<get_state_events::v3::Response> {
	let sender_user = body.sender_user();

	if !services
		.state_accessor
		.user_can_see_state_events(sender_user, &body.room_id)
		.await
	{
		return Err!(Request(Forbidden("You don't have permission to view the room state.")));
	}

	let encrypted = services
		.state_accessor
		.is_encrypted_room(&body.room_id)
		.await;

	let room_state = services
		.state_accessor
		.room_state_full_pdus(&body.room_id)
		.map_ok(Event::into_pdu)
		.broad_and_then(async |pdu| {
			Ok(with_membership(&services, pdu, sender_user, encrypted).await)
		})
		.map_ok(Event::into_format)
		.try_collect()
		.await?;

	Ok(get_state_events::v3::Response { room_state })
}

/// # `GET /_matrix/client/v3/rooms/{roomid}/state/{eventType}/{stateKey}`
///
/// Get single state event of a room with the specified state key.
/// The optional query parameter `?format=event|content` allows returning the
/// full room state event or just the state event's content (default behaviour)
///
/// - If not joined: Only works if current room history visibility is world
///   readable
pub(crate) async fn get_state_events_for_key_route(
	State(services): State<crate::State>,
	body: Ruma<get_state_event_for_key::v3::Request>,
) -> Result<get_state_event_for_key::v3::Response> {
	let sender_user = body.sender_user();

	if !services
		.state_accessor
		.user_can_see_state_events(sender_user, &body.room_id)
		.await
	{
		return Err!(Request(NotFound(debug_warn!(
			"You don't have permission to view the room state."
		))));
	}

	let event = services
		.state_accessor
		.room_state_get(&body.room_id, &body.event_type, &body.state_key)
		.await
		.map_err(|e| {
			err!(Request(NotFound(debug_warn!(
				room_id = ?body.room_id,
				event_type = ?body.event_type,
				"Failed to get state event: {e}.",
			))))
		})?;

	let event_or_content = match body.format {
		| StateEventFormat::Event => json!({
			"content": event.content(),
			"event_id": event.event_id(),
			"origin_server_ts": event.origin_server_ts(),
			"room_id": event.room_id(),
			"sender": event.sender(),
			"state_key": event.state_key(),
			"type": event.kind(),
			"unsigned": event.unsigned(),
		}),

		| _ => event.get_content_as_value(),
	};

	let event_or_content = to_raw_value(&event_or_content).expect("serializable JSON value");

	Ok(get_state_event_for_key::v3::Response::new(event_or_content))
}

