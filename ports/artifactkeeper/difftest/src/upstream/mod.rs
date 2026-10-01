//! artifact-keeper's code, under the module paths it has upstream. Files that
//! start with "Copied from" are verbatim (extract_upstream.py); the rest are
//! stubs for what that code uses: types with the fields it reads, and the
//! services behind the trusted boundary (`AuthService`, the database).
#![allow(dead_code, unused_imports, unused_variables, unused_mut, clippy::all)]

pub mod api;
pub mod config;
pub mod error;
pub mod models;
pub mod services;
pub mod util;
