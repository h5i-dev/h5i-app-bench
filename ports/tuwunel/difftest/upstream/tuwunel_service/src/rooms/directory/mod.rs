use ruma::{RoomId, api::client::room::initial_sync::v3::Visibility};

pub struct Service;

impl Service {
    pub async fn visibility(&self, _room_id: &RoomId) -> Visibility {
        Visibility::Private
    }
}
