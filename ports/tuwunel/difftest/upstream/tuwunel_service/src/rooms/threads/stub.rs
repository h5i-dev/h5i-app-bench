use tuwunel_database::Map;

use crate::Svc;

#[derive(Default)]
pub struct Data {
    pub threadid_userids: Map,
    pub threadactivityid_rootid: Map,
    pub threadrootid_latestcount: Map,
}

pub struct Service {
    pub db: Data,
    pub services: Svc,
}
