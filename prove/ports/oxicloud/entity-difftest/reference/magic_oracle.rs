use chrono::{DateTime,Utc}; use oxicloud::domain::entities::magic_link_token::MagicLinkStatus; pub struct Snapshot {pub expires_at:DateTime<Utc>,pub status:MagicLinkStatus} impl Snapshot {    pub fn is_expired(&self, now: DateTime<Utc>) -> bool {
        now > self.expires_at
    }    pub fn is_redeemable(&self, now: DateTime<Utc>) -> bool {
        self.status == MagicLinkStatus::Pending && !self.is_expired(now)
    }}
