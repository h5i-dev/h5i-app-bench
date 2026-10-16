//! The configuration the copied code reads.
use ruma::OwnedServerName;

mod net;

/// Upstream: a `RegexSet`; here exact host names.
#[derive(Clone, Debug, Default)]
pub struct RegexSet(pub Vec<String>);

impl RegexSet {
    pub fn is_empty(&self) -> bool {
        self.0.is_empty()
    }
    pub fn is_match(&self, s: &str) -> bool {
        self.0.iter().any(|x| x == s)
    }
}

#[derive(Clone, Debug)]
pub struct Config {
    pub server_name: OwnedServerName,
    pub forbidden_remote_server_names: RegexSet,
    pub allowed_remote_server_names_experimental: RegexSet,
    pub fetch_unreceived_contexts_over_federation: bool,
    pub allow_federation: bool,
    pub allow_room_admins_to_request_unredacted_events: bool,
}
