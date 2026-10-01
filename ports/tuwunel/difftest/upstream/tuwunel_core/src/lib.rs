#![allow(unused_imports, unused_variables, dead_code)]
//! Stub of tuwunel_core around the copied files: the error type and its
//! macros, the PDU and the `Event` trait, the configuration and the
//! utility re-exports the copied code names.
pub mod config;
pub mod error;
pub mod matrix;
pub mod utils;

pub use ::arrayvec;
pub use ::smallvec;
pub use ::tracing::{debug, error as error_log, info, trace, warn};
pub use ::tuwunel_macros::{ctor, implement};

pub use error::Error;
pub use matrix::{Event, Pdu, PduCount, PduEvent, PduId, RawPduId};
pub use utils::result;

pub type Result<T = (), E = Error> = std::result::Result<T, E>;

#[macro_export]
macro_rules! Err {
    ($($args:tt)*) => {
        Err($crate::err!($($args)*))
    };
}

/// The error kind of upstream's `err!`: the `Request` variant keeps its
/// `ErrorKind` name; messages are dropped.
#[macro_export]
macro_rules! err {
    (HttpJson($status:ident, $($args:tt)+)) => {
        $crate::error::Error::HttpJson(stringify!($status))
    };
    (Request($kind:ident($($args:tt)*))) => {
        $crate::error::Error::Request(stringify!($kind))
    };
    (Database($($args:tt)*)) => {
        $crate::error::Error::Database
    };
    (Arithmetic($($args:tt)*)) => {
        $crate::error::Error::Arithmetic
    };
    ($($args:tt)*) => {
        $crate::error::Error::Other
    };
}

#[macro_export]
macro_rules! debug_warn {
    ($($args:tt)*) => {
        ""
    };
}

#[macro_export]
macro_rules! expected {
    ($($t:tt)*) => {{ $($t)* }};
}

#[macro_export]
macro_rules! extract_variant {
    ( $e:expr, $( $variant:path )|* ) => {
        match $e {
            $( $variant(value) => Some(value), )*
            _ => None,
        }
    };
}

#[macro_export]
macro_rules! is_false {
    () => {
        |x| !x
    };
}

#[macro_export]
macro_rules! is_equal_to {
    ($val:ident) => {
        |x| x == $val
    };
    ($val:expr) => {
        |x| x == $val
    };
}

#[macro_export]
macro_rules! is_not_equal_to {
    ($val:ident) => {
        |x| x != $val
    };
    ($val:expr) => {
        |x| x != $val
    };
}

#[macro_export]
macro_rules! ref_at {
    ($idx:tt) => {
        |ref t| &t.$idx
    };
}

#[macro_export]
macro_rules! at {
    ($idx:tt) => {
        |t| t.$idx
    };
}
