//! The utility modules the copied code names; `stream`, `future`, `bool`,
//! `result` and `math` hold copied files.
pub mod bool;
pub mod future;
pub mod math;
pub mod result;
pub mod stream;

pub use self::{
    bool::BoolExt,
    future::{BoolExt as FutureBoolExt, OptionStream, TryExtExt as TryFutureExtExt},
    stream::{IterStream, ReadyExt, Tools as StreamTools, TryReadyExt},
};

/// `utils::bytes::u64_from_u8`.
pub fn u64_from_u8(v: &[u8]) -> u64 {
    u64::from_be_bytes(v.try_into().expect("8 bytes"))
}

pub mod rand {
    pub fn index(i: usize) -> usize {
        i
    }
}
