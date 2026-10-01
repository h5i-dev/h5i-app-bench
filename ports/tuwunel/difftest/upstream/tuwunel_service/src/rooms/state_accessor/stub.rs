use ruma::RoomId;
use tuwunel_core::{Result, err};

use crate::Svc;

pub struct Service {
    pub services: Svc,
}

/// Power levels are not modeled: only `/event` with
/// `include_unredacted_content` reads them.
pub struct RoomPowerLevels {
    pub redact: i64,
}

impl RoomPowerLevels {
    pub fn for_user(&self, _user_id: &ruma::UserId) -> i64 {
        0
    }
}

impl Service {
    pub async fn get_power_levels(&self, _room_id: &RoomId) -> Result<RoomPowerLevels> {
        Err(err!(Request(NotFound("power levels not modeled"))))
    }
}
