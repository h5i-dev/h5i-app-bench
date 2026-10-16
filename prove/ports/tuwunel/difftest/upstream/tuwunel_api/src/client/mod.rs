//! The client modules the tests reach, re-exported as upstream's
//! `client/mod.rs` does.
pub(super) mod context;
pub(super) mod membership;
pub(super) mod message;
pub(super) mod relations;
pub(super) mod room;
pub(super) mod state;
pub(super) mod threads;

pub(super) use context::*;
pub(super) use membership::*;
pub(super) use message::*;
pub(super) use relations::*;
pub(super) use room::*;
pub(super) use state::*;
pub(super) use threads::*;
