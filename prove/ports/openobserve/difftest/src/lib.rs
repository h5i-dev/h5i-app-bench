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

/// The gRPC interceptor (`api/grpc/src/handler/grpc/auth/mod.rs`, whole file)
/// with the caches it reads as DashMaps, and the cache readers verbatim.
pub mod grpc_world {
    pub mod common {
        pub mod infra {
            pub mod config {
                use std::sync::LazyLock;

                use dashmap::DashMap;

                use super::super::super::config::meta::user::User;
                use super::super::super::infra::table::{org_users::OrgUserRecord, users::UserRecord};
                pub static ORG_INGESTION_TOKENS: LazyLock<DashMap<String, String>> = LazyLock::new(DashMap::new);
                pub static ROOT_USER: LazyLock<DashMap<String, User>> = LazyLock::new(DashMap::new);
                pub static ORG_USERS: LazyLock<DashMap<String, OrgUserRecord>> = LazyLock::new(DashMap::new);
                pub static USERS: LazyLock<DashMap<String, UserRecord>> = LazyLock::new(DashMap::new);
            }
        }
    }
    pub mod config {
        pub const DEFAULT_ORG: &str = "default";
        pub struct Grpc {
            pub org_header_key: String,
        }
        pub struct Cfg {
            pub grpc: Grpc,
        }
        pub fn get_config() -> Cfg {
            Cfg { grpc: Grpc { org_header_key: "organization".to_string() } }
        }
        pub mod meta {
            pub mod cluster {
                pub static INTERNAL: std::sync::Mutex<String> = std::sync::Mutex::new(String::new());
                pub fn get_internal_grpc_token() -> String {
                    INTERNAL.lock().unwrap().clone()
                }
            }
            pub mod user {
                #[derive(Clone, Debug, PartialEq, Eq)]
                pub enum UserRole {
                    Root,
                    Admin,
                    Editor,
                    Viewer,
                    User,
                    ServiceAccount,
                    SreAgent,
                }
                #[derive(Clone, Debug, PartialEq, Eq)]
                pub enum UserType {
                    Internal,
                    External,
                }
                impl UserType {
                    pub fn is_external(&self) -> bool {
                        matches!(self, UserType::External)
                    }
                }
                #[derive(Clone, Debug, PartialEq, Eq)]
                pub struct User {
                    pub email: String,
                    pub first_name: String,
                    pub last_name: String,
                    pub password: String,
                    pub salt: String,
                    pub token: String,
                    pub rum_token: Option<String>,
                    pub role: UserRole,
                    pub org: String,
                    pub is_external: bool,
                    pub password_ext: Option<String>,
                }
            }
        }
    }
    pub mod infra {
        pub mod table {
            pub mod org_ingestion_tokens {
                include!(concat!(env!("OUT_DIR"), "/infra_ingestion.rs"));
            }
            pub mod org_users {
                use super::super::super::config::meta::user::UserRole;
                #[derive(Clone, Debug)]
                pub struct OrgUserRecord {
                    pub email: String,
                    pub org_id: String,
                    pub role: UserRole,
                    pub token: String,
                    pub rum_token: Option<String>,
                }
            }
            pub mod users {
                use super::super::super::config::meta::user::UserType;
                #[derive(Clone, Debug)]
                pub struct UserRecord {
                    pub email: String,
                    pub first_name: String,
                    pub last_name: String,
                    pub password: String,
                    pub salt: String,
                    pub password_ext: Option<String>,
                    pub user_type: UserType,
                }
            }
        }
    }
    pub mod db {
        pub mod org_users {
            use super::super::common::infra::config::{ORG_USERS, USERS};
            use super::super::config::meta::user::User;
            include!(concat!(env!("OUT_DIR"), "/db_org_users.rs"));
        }
        pub mod user {
            use super::super::common::infra::config::ORG_USERS;
            use super::super::config::{DEFAULT_ORG, meta::user::UserRole};
            include!(concat!(env!("OUT_DIR"), "/db_user.rs"));
        }
        pub mod org_ingestion_tokens {
            include!(concat!(env!("OUT_DIR"), "/db_ingestion.rs"));
        }
    }
    pub mod openobserve_core {
        pub mod auth {
            /// The hash oracle the kernel also reads: `(password, salt) -> hash`.
            pub static HASHES: std::sync::Mutex<Vec<(String, String, Option<String>)>> =
                std::sync::Mutex::new(Vec::new());
            pub fn try_get_hash(pass: &str, salt: &str) -> Option<String> {
                HASHES.lock().unwrap().iter().find(|(p, s, _)| p == pass && s == salt).and_then(|(_, _, h)| h.clone())
            }
            pub fn get_hash(pass: &str, salt: &str) -> String {
                try_get_hash(pass, salt).unwrap()
            }
        }
    }
    pub mod grpc_auth {
        use super::{common, config, db, infra, openobserve_core};
        include!(concat!(env!("OUT_DIR"), "/grpc_auth.rs"));

        pub fn seam_check_auth_inner(req: Request<()>, allow: bool) -> Result<Request<()>, Status> {
            check_auth_inner(req, allow)
        }
        pub fn seam_token_matches(t: &str, i: &str, s: Option<&str>) -> bool {
            token_matches(t, i, s)
        }
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
