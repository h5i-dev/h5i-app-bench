//! wastebin (matze/wastebin @ c0ec968) as an h5i-app kernel.
//!
//! The decisions that guard a paste: how its URL id is decoded, which file
//! extensions are accepted, who may delete it, when it has expired, when
//! reading it burns it, and when its content may be shown or cached. Each
//! module names the upstream code it follows. Text is bytes; the database is
//! a list of `entries` rows; cryptography and HMAC cookie signing are inputs
//! (see DEVIATIONS.md).

pub mod ext;
pub mod id;
pub mod store;
