//! Stub of kanidm_proto: `attribute.rs` and `constants.rs` are copied.
#![allow(dead_code, clippy::all)]
pub mod attribute;
pub mod constants;

pub mod internal {
    /// Stub: the variants the copied code names.
    #[derive(Debug, Clone, PartialEq, Eq)]
    pub enum OperationError {
        InvalidState,
        InvalidAcpState(String),
        FilterUuidResolution,
    }
}
