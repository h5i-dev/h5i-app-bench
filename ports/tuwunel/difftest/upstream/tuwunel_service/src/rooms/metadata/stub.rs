use tuwunel_database::Map;

use crate::Svc;

#[derive(Default)]
pub struct Data {
    pub pduid_pdu: Map,
}

pub struct Service {
    pub db: Data,
    pub services: Svc,
}
