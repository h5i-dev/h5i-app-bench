#![cfg(feature = "gpu")]
#![allow(improper_ctypes_definitions)]
#![no_std]
use cuda_std::{kernel, thread};
#[path = "../../../src/predicate.rs"]
mod policy;
#[kernel]
pub unsafe fn conduit_policy(rows: &[u64], out: *mut u32, errors: *mut u32, n: usize) {
    let i = thread::index_1d() as usize;
    if i < n {
        let value = if i >= 128 || i >= rows.len() / policy::WORDS {
            u32::MAX
        } else {
            policy::evaluate(&rows[i * policy::WORDS..(i + 1) * policy::WORDS])
        };
        unsafe {
            *out.add(i) = value;
            *errors.add(i) = (value == u32::MAX) as u32;
        }
    }
}
