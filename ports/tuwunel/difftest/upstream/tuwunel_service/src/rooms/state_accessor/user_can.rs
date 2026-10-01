// Copied from matrix-construct/tuwunel @ 7801b8e by extract_upstream.py. Do not edit.
/// Reports whether a user may see an event under its historical visibility.
///
/// Missing event state is allowed, and missing or invalid history visibility
/// defaults to `shared`. The `shared` decision also accounts for the user's
/// membership intervals around the event.
use futures::pin_mut;
use ruma::EventId;
use ruma::RoomId;
use ruma::UserId;
use ruma::events::StateEventType;
use ruma::events::room::history_visibility::HistoryVisibility;
use ruma::events::room::history_visibility::RoomHistoryVisibilityEventContent;
use tuwunel_core::implement;
use tuwunel_core::matrix::Event;
use tuwunel_core::matrix::PduCount;
use tuwunel_core::utils::FutureBoolExt;
use crate::rooms::short::ShortStateHash;

#[implement(super::Service)]
#[tracing::instrument(skip_all, level = "trace")]
pub async fn user_can_see_event(
	&self,
	user_id: &UserId,
	room_id: &RoomId,
	event_id: &EventId,
) -> bool {
	let Ok(shortstatehash) = self
		.services
		.state
		.pdu_shortstatehash(event_id)
		.await
	else {
		return true;
	};

	let history_visibility = self
		.state_get_content(shortstatehash, &StateEventType::RoomHistoryVisibility, "")
		.await
		.map_or(HistoryVisibility::Shared, |c: RoomHistoryVisibilityEventContent| {
			c.history_visibility
		});

	match history_visibility {
		| HistoryVisibility::WorldReadable => true,

		// Allow if any member on requesting server was AT LEAST invited, else deny
		| HistoryVisibility::Invited =>
			self.user_was_invited(shortstatehash, user_id)
				.await,

		// Allow if any member on requested server was joined, else deny
		| HistoryVisibility::Joined =>
			self.user_was_joined(shortstatehash, user_id)
				.await,

		// An unrecognized value is treated as shared.
		| HistoryVisibility::Shared | _ =>
			self.user_shared_history(shortstatehash, room_id, event_id, user_id)
				.await,
	}
}

/// Whether a user may see an event under `shared` history visibility.
///
/// A current member sees the whole room, which the first check answers without
/// touching room state. A former member keeps events through their latest
/// leave, and lookup failures deny access.
#[implement(super::Service)]
async fn user_shared_history(
	&self,
	shortstatehash: ShortStateHash,
	room_id: &RoomId,
	event_id: &EventId,
	user_id: &UserId,
) -> bool {
	let state_cache = &self.services.state_cache;

	if state_cache.is_joined(user_id, room_id).await
		|| self
			.user_was_joined(shortstatehash, user_id)
			.await
	{
		return true;
	}

	if !state_cache.once_joined(user_id, room_id).await {
		return false;
	}

	let Ok(left_count) = state_cache.get_left_count(room_id, user_id).await else {
		return false;
	};

	let Ok(event_count) = self
		.services
		.timeline
		.get_pdu_count(event_id)
		.await
	else {
		return false;
	};

	event_count <= PduCount::from_unsigned(left_count)
}

/// Reports whether a user may read the room's current state events.
///
/// Current membership grants immediate access. Otherwise world-readable
/// history grants access; invited and shared visibility consult current
/// invitation or retained once-joined metadata. Missing visibility defaults
/// to `shared`.
#[implement(super::Service)]
#[tracing::instrument(skip_all, level = "trace")]
pub async fn user_can_see_state_events(&self, user_id: &UserId, room_id: &RoomId) -> bool {
	if self
		.services
		.state_cache
		.is_joined(user_id, room_id)
		.await
	{
		return true;
	}

	let history_visibility = self
		.room_state_get_content(room_id, &StateEventType::RoomHistoryVisibility, "")
		.await
		.map_or(HistoryVisibility::Shared, |c: RoomHistoryVisibilityEventContent| {
			c.history_visibility
		});

	match history_visibility {
		| HistoryVisibility::WorldReadable => true,

		| HistoryVisibility::Invited =>
			self.services
				.state_cache
				.is_invited(user_id, room_id)
				.await,

		| HistoryVisibility::Shared =>
			self.services
				.state_cache
				.once_joined(user_id, room_id)
				.await,

		| _ => false,
	}
}

/// Reports whether a user may discover or inspect a room.
///
/// Current join, invite, retained left membership, or world-readable history
/// grants access. Forgetting a room clears the retained left membership and can
/// therefore remove this visibility.
#[implement(super::Service)]
pub async fn user_can_see_room(&self, user_id: &UserId, room_id: &RoomId) -> bool {
	let state_cache = &self.services.state_cache;
	let joined = state_cache.is_joined(user_id, room_id);
	let invited = state_cache.is_invited(user_id, room_id);
	let left = state_cache.is_left(user_id, room_id);
	let world_readable = self.is_world_readable(room_id);

	pin_mut!(joined, invited, left, world_readable);
	joined
		.or(invited)
		.or(left)
		.or(world_readable)
		.await
}

