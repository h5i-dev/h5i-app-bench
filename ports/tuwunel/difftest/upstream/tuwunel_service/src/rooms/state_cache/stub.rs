use tuwunel_database::Map;

use crate::Svc;

#[derive(Default)]
pub struct Data {
    pub userroomid_joinedcount: Map,
    pub roomuserid_joinedcount: Map,
    pub userroomid_invitestate: Map,
    pub userroomid_knockedstate: Map,
    pub userroomid_leftstate: Map,
    pub roomuserid_leftcount: Map,
    pub roomuseroncejoinedids: Map,
}

pub struct Service {
    pub db: Data,
    pub services: Svc,
}
