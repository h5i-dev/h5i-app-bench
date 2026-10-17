#![cfg(feature = "gpu")]
#![allow(improper_ctypes_definitions)]
#![no_std]
use cuda_std::{kernel, thread};

#[path = "../../../src/predicate.rs"]
mod linkding;

#[kernel]
pub unsafe fn linkding_batch(
    fields: &[u8],
    lengths: &[u32],
    tags: &[u64],
    meta: &[u32],
    nodes: &[u32],
    text: &[u8],
    root: usize,
    flags: u32,
    out: *mut u32,
    errors: *mut u32,
    n: usize,
) {
    let i = thread::index_1d() as usize;
    if i < n {
        let v = if i >= 1_000_000
            || i >= fields.len() / 512
            || i >= lengths.len() / 4
            || i >= tags.len() / 8
            || i >= meta.len() / 3
        {
            2
        } else {
            linkding::evaluate(
                &fields[i * 512..(i + 1) * 512],
                &lengths[i * 4..(i + 1) * 4],
                &tags[i * 8..(i + 1) * 8],
                &meta[i * 3..(i + 1) * 3],
                nodes,
                text,
                root,
                flags,
            )
        };
        unsafe {
            *out.add(i) = if v == 2 { 0 } else { v };
            *errors.add(i) = (v == 2) as u32;
        }
    }
}
