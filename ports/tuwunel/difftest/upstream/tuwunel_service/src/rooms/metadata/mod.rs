// Copied from matrix-construct/tuwunel @ 7801b8e by extract_upstream.py. Do not edit.
/// Reports whether at least one timeline PDU is stored for a room.
///
/// A room without a short ID is absent. Database scan errors are skipped, so a
/// failed or empty scan also returns `false`.
use futures::FutureExt;
use futures::Stream;
use futures::StreamExt;
use futures::pin_mut;
use ruma::RoomId;
use tuwunel_core::implement;
use tuwunel_core::utils::future::BoolExt;
use tuwunel_core::utils::stream::TryIgnore;
use tuwunel_core::utils::stream::WidebandExt;

#[implement(Service)]
pub async fn exists(&self, room_id: &RoomId) -> bool {
	let Ok(prefix) = self.services.short.get_shortroomid(room_id).await else {
		return false;
	};

	// Look for PDUs in that room.
	let keys = self
		.db
		.pduid_pdu
		.keys_prefix_raw(&prefix)
		.ignore_err();

	pin_mut!(keys);
	keys.next().await.is_some()
}


mod stub;
pub use stub::*;
