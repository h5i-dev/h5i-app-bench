//! openobserve's own code at the pinned commit (copied by build.rs into
//! OUT_DIR, never committed), with stand-ins for the crates it names but the
//! decision logic does not reach, and the differential tests against the
//! kernel in tests.rs.
#![allow(dead_code, unused_imports)]

/// `api/common/src/auth/validator.rs` `AuthError`, the variants verbatim.
pub mod stubs {
    #[derive(Clone, Debug, PartialEq, Eq)]
    pub enum AuthError {
        Unauthorized(String),
        Forbidden(String),
        RoleRefused(String),
        NotFound(String),
        Locked { retry_after_secs: i64 },
        Unavailable(String),
    }
}

/// `config::utils`: the three upstream files the token code uses.
pub mod utils {
    pub mod str {
        include!(concat!(env!("OUT_DIR"), "/config_str.rs"));
    }
    pub mod encryption {
        use base64::{Engine, prelude::BASE64_STANDARD};
        include!(concat!(env!("OUT_DIR"), "/config_encryption.rs"));
    }
    pub mod delegation {
        include!(concat!(env!("OUT_DIR"), "/config_delegation.rs"));

        /// Test seam: upstream's private `mac`.
        pub fn seam_mac(key: &[u8], claims_b64: &str) -> Vec<u8> {
            mac(key, claims_b64)
        }
    }
}

/// The `config` crate as `api/common` sees it: `utils` above, and the Slack
/// row types reduced to the fields the delegation code reads.
pub mod config {
    pub use crate::utils;
    pub mod meta {
        pub mod slack {
            #[derive(Clone, Copy, Debug, PartialEq, Eq)]
            pub enum DisabledReason {
                Edition,
                License,
                Flag,
                MasterKey,
                SuperCluster,
            }
            #[derive(Clone, Debug, PartialEq, Eq)]
            pub struct ExternalIdentityLink {
                pub id: String,
                pub installation_id: String,
                pub user_email: String,
                pub last_used_at: i64,
                pub revoked_at: Option<i64>,
            }
            #[derive(Clone, Debug, PartialEq, Eq)]
            pub struct SlackInstallation {
                pub id: String,
                pub revoked_at: Option<i64>,
            }
        }
    }
}

/// `api/common/src/auth/delegation.rs`, plus seams for its private functions.
pub mod api_delegation {
    use crate::config;
    include!(concat!(env!("OUT_DIR"), "/api_delegation.rs"));

    pub fn seam_check_route(path: &str, prefix: &str, method: &Method, claims: &Claims) -> Result<(), AuthError> {
        check_route(path, prefix, method, claims)
    }

    pub fn seam_path_org(relative: &str) -> Option<&str> {
        path_org(relative)
    }

    pub fn seam_relative_path(path: &str) -> &str {
        relative_path(path)
    }

    pub fn seam_verified_claims(
        token: &str,
        slack_on: bool,
        keys: Option<Keys>,
        now: i64,
        disabled_orgs: &[String],
    ) -> Result<Claims, AuthError> {
        verified_claims(
            token,
            slack_on,
            || keys.ok_or_else(|| anyhow::anyhow!("no key")),
            now,
            |org| disabled_orgs.iter().any(|o| o == org).then_some(config::meta::slack::DisabledReason::Flag),
        )
    }

    /// `LinkFacts::from_rows` then `admit`; the facts' installation id and last use.
    pub fn seam_admit_rows(
        link: Option<config::meta::slack::ExternalIdentityLink>,
        installation: Option<config::meta::slack::SlackInstallation>,
        orgs: HashSet<String>,
        claims: &Claims,
    ) -> (Result<(), AuthError>, String, i64) {
        let facts = LinkFacts::from_rows(link, installation, orgs, Instant::now());
        (facts.admit(claims), facts.installation_id.clone(), facts.last_used_at)
    }

    pub fn seam_touch_due(last_used_at: i64, now: i64) -> bool {
        touch_due(last_used_at, now)
    }
}

/// `core/src/auth.rs`: `org_from_path`, `routed_path` and their constants.
pub mod core_auth {
    include!(concat!(env!("OUT_DIR"), "/core_auth.rs"));

    /// `AuthExtractor::from_request_parts` (core/src/auth.rs:346-360), retyped:
    /// it sits inside an async extractor that needs the whole server.
    pub fn extractor_org_id(uri_path: &str) -> String {
        let path = routed_path(uri_path);
        let mut path_columns = path.split('/').collect::<Vec<&str>>();
        if path_columns.len() > 1
            && let Some(v) = path_columns.last()
            && v.is_empty()
        {
            path_columns.pop();
        }
        org_from_path(&path_columns).to_string()
    }
}

/// Captures upstream's `log::debug!` reasons, which are the only place it
/// says why a delegated token was refused.
pub mod logcap {
    use std::cell::RefCell;
    use std::sync::Once;

    thread_local!(static LAST: RefCell<Vec<String>> = const { RefCell::new(Vec::new()) });

    struct Cap;
    impl log::Log for Cap {
        fn enabled(&self, _: &log::Metadata) -> bool {
            true
        }
        fn log(&self, r: &log::Record) {
            LAST.with(|l| l.borrow_mut().push(r.args().to_string()));
        }
        fn flush(&self) {}
    }

    static INIT: Once = Once::new();

    pub fn start() {
        INIT.call_once(|| {
            log::set_boxed_logger(Box::new(Cap)).unwrap();
            log::set_max_level(log::LevelFilter::Trace);
        });
        LAST.with(|l| l.borrow_mut().clear());
    }

    pub fn take() -> Vec<String> {
        LAST.with(|l| std::mem::take(&mut *l.borrow_mut()))
    }
}

#[cfg(test)]
mod tests;
