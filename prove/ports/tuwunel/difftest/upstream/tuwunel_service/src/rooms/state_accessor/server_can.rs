// Copied from matrix-construct/tuwunel @ 7801b8e by extract_upstream.py. Do not edit.
/// Reports whether a server may see an event over federation.
///
/// Missing event state is allowed, and missing or invalid history visibility
/// defaults to `shared`. For `invited` and `joined`, a currently joined user
/// from the origin must also hold the required membership at the event.
use futures::StreamExt;
use ruma::EventId;
use ruma::RoomId;
use ruma::ServerName;
use ruma::events::StateEventType;
use ruma::events::room::history_visibility::HistoryVisibility;
use ruma::events::room::history_visibility::RoomHistoryVisibilityEventContent;
use tuwunel_core::implement;
use tuwunel_core::utils::stream::ReadyExt;

#[implement(super::Service)]
#[tracing::instrument(skip_all, level = "trace")]
pub async fn server_can_see_event(
	&self,
	origin: &ServerName,
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

	let current_server_members = self
		.services
		.state_cache
		.room_members(room_id)
		.ready_filter(|member| member.server_name() == origin);

	match history_visibility {
		| HistoryVisibility::Invited => {
			// Allow if any member on requesting server was AT LEAST invited, else deny
			current_server_members
				.any(|member| self.user_was_invited(shortstatehash, member))
				.await
		},
		| HistoryVisibility::Joined => {
			// Allow if any member on requested server was joined, else deny
			current_server_members
				.any(|member| self.user_was_joined(shortstatehash, member))
				.await
		},
		| HistoryVisibility::WorldReadable | HistoryVisibility::Shared | _ => true,
	}
}

