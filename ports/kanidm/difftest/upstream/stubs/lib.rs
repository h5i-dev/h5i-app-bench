//! A crate laid out like `kanidmd_lib` (server/lib/src) so that the copied
//! access module resolves `crate::` paths unchanged. Files and items marked
//! "Copied" in their header come from f608c4f; the rest are stubs.
#![allow(dead_code, unused_imports, unused_variables, unused_mut, clippy::all)]

#[macro_use]
pub mod macros;
pub mod constants;
pub mod entry;
pub mod event;
pub mod filter;
pub mod modify;
pub mod prelude;
pub mod server;
pub mod value;
pub mod valueset;
