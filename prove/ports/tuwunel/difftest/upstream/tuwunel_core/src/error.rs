use std::fmt;

use tracing::Level;

/// Upstream's `Error`, reduced to its kind.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Error {
    /// `Request(ErrorKind, ..)`, by kind name (`Forbidden`, `NotFound`, ..).
    Request(&'static str),
    /// `HttpJson(status, ..)`: the `M_SENDER_IGNORED` reply.
    HttpJson(&'static str),
    Database,
    Arithmetic,
    /// A token or content that fails to parse.
    Parse,
    Other,
}

impl Error {
    pub fn is_not_found(&self) -> bool {
        matches!(self, Error::Request("NotFound"))
    }
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{self:?}")
    }
}

impl std::error::Error for Error {}

impl From<std::num::ParseIntError> for Error {
    fn from(_: std::num::ParseIntError) -> Self {
        Error::Parse
    }
}

impl From<serde_json::Error> for Error {
    fn from(_: serde_json::Error) -> Self {
        Error::Parse
    }
}

impl From<ruma::TryFromIntError> for Error {
    fn from(_: ruma::TryFromIntError) -> Self {
        Error::Arithmetic
    }
}

pub fn inspect_log_level<E: fmt::Display>(_e: &E, _level: Level) {}
