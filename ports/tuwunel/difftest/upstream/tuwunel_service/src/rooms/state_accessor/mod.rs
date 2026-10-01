// Copied from matrix-construct/tuwunel @ 7801b8e by extract_upstream.py. Do not edit.
use futures::FutureExt;
use futures::TryFutureExt;
use ruma::RoomId;
use ruma::events::StateEventType;
use ruma::events::room::history_visibility::HistoryVisibility;
use ruma::events::room::history_visibility::RoomHistoryVisibilityEventContent;
use tuwunel_core::utils::BoolExt;

mod room_state;
mod server_can;
mod state;
mod user_can;

impl Service {
	/// Reports whether the room is world-readable.
	///
	/// Missing, unreadable, or invalid history-visibility state is treated as not
	/// world-readable.
	pub async fn is_world_readable(&self, room_id: &RoomId) -> bool {
		self.room_state_get_content(room_id, &StateEventType::RoomHistoryVisibility, "")
			.await
			.map(|c: RoomHistoryVisibilityEventContent| {
				c.history_visibility == HistoryVisibility::WorldReadable
			})
			.unwrap_or(false)
	}

	/// Reports whether an encryption state event is present.
	///
	/// This checks that the event can be loaded, but does not deserialize its
	/// content or validate an encryption algorithm.
	pub async fn is_encrypted_room(&self, room_id: &RoomId) -> bool {
		self.room_state_get(room_id, &StateEventType::RoomEncryption, "")
			.await
			.is_ok()
	}

}

mod stub;
pub use stub::*;
