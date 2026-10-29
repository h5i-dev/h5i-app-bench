//! Pure reference harness compiled from immutable upstream Git objects.
//! Full entities remain unchanged; selected private decisions use the pinned
//! method bodies with explicit clock input and external carrier adapters.
extern crate self as oxicloud;
#[path="../reference/user.rs"] pub mod user_ref;
#[path="../reference/session.rs"] pub mod session_ref;
#[path="../reference/share.rs"] pub mod share_ref;
#[path="../reference/magic_link_token.rs"] pub mod magic_link_token_ref;
#[path="../reference/subject_group.rs"] pub mod subject_group_ref;
#[path="../reference/entity_errors.rs"] pub mod entity_errors_ref;
#[path="../reference/drive.rs"] pub mod drive_ref;
pub use entity_errors_ref as entity_errors;

pub mod common { pub mod errors { pub use crate::domain::errors::*; }
 pub mod config { include!(concat!(env!("CARGO_MANIFEST_DIR"),"/reference/config.rs")); } }
pub mod domain {
 pub mod errors { include!(concat!(env!("CARGO_MANIFEST_DIR"),"/reference/domain_errors.rs")); }
 pub mod entities { pub use crate::user_ref as user; pub use crate::session_ref as session; pub use crate::share_ref as share; pub use crate::magic_link_token_ref as magic_link_token; pub use crate::subject_group_ref as subject_group; pub use crate::entity_errors_ref as entity_errors; pub use crate::drive_ref as drive; }
 pub mod services { pub mod authorization { include!(concat!(env!("CARGO_MANIFEST_DIR"),"/reference/authorization.rs")); } }
}
pub mod application { pub mod ports { pub mod authorization_ports { include!(concat!(env!("CARGO_MANIFEST_DIR"),"/reference/admin.rs")); } } }
pub mod interfaces {
 pub mod errors { include!(concat!(env!("CARGO_MANIFEST_DIR"),"/reference/app_error.rs")); }
 pub mod middleware { pub mod user { include!(concat!(env!("CARGO_MANIFEST_DIR"),"/reference/live_role.rs")); } }
}
#[cfg(test)] mod tests;
#[cfg(test)] mod userrole;
#[cfg(test)] mod authwire;
#[cfg(test)] mod session;
#[cfg(test)] mod validation;
#[cfg(test)] mod share;
#[cfg(test)] mod subjectgroup;
#[cfg(test)] mod magiclink;
#[cfg(test)] mod userstate;
#[cfg(test)] mod admin;
#[cfg(test)] mod liveauth;
#[cfg(test)] mod policydefaults;
