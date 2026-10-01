mod and_then_ref;
mod filter;
mod flat_ok;
mod into_is_ok;
mod is_err_or;
mod log_err;
mod map_expect;
mod map_ref;
mod not_found;
mod unwrap_or_err;

pub use self::{
    and_then_ref::AndThenRef, filter::Filter, flat_ok::FlatOk, into_is_ok::IntoIsOk, is_err_or::IsErrOr,
    log_err::LogErr, map_expect::MapExpect, map_ref::MapRef, not_found::NotFound,
};

pub type Result<T = (), E = crate::Error> = std::result::Result<T, E>;
