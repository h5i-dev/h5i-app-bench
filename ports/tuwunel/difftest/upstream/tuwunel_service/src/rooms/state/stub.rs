use tuwunel_database::Map;

use crate::Svc;

#[derive(Default)]
pub struct Data {
    pub roomid_shortstatehash: Map,
    pub shorteventid_shortstatehash: Map,
}

pub struct Service {
    pub db: Data,
    pub services: Svc,
}
