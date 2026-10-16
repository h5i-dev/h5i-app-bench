use ruma::{UserId, events::{GlobalAccountDataEventType, ignored_user_list::{IgnoredUserListEvent, IgnoredUserListEventContent}}};

use crate::Svc;

pub struct Service {
    pub services: Svc,
}

impl Service {
    /// The user's `m.ignored_user_list`.
    pub async fn ignored_users(&self, user_id: &UserId) -> Option<IgnoredUserListEventContent> {
        self.services
            .account_data
            .get_global::<IgnoredUserListEvent>(user_id, GlobalAccountDataEventType::IgnoredUserList)
            .await
            .ok()
            .map(|e| e.content)
    }
}
