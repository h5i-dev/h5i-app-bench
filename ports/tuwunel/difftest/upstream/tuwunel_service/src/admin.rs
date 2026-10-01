use ruma::UserId;

pub struct Service;

impl Service {
    pub async fn user_is_admin(&self, _user_id: &UserId) -> bool {
        false
    }
}
