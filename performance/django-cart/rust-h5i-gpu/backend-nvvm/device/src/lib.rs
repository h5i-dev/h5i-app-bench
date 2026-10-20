#![cfg(feature = "gpu")]
#![no_std]
use cuda_std::{kernel, thread};
#[path = "../../../src/pricing.rs"]
mod pricing;
#[path = "../../../src/wide.rs"]
mod wide;
const WIDTH: usize = pricing::MAX_LINES * 2 + 3;
#[kernel]
pub unsafe fn cart_batch(rows: &[u64], out: *mut u64, n: usize) {
    let i = thread::index_1d() as usize;
    if i < n {
        let value = if i >= rows.len() / WIDTH {
            pricing::ERROR
        } else {
            let row = &rows[i * WIDTH..(i + 1) * WIDTH];
            let count = row[0] as usize;
            if count > pricing::MAX_LINES {
                pricing::ERROR
            } else {
                pricing::total(
                    &row[1..1 + count],
                    &row[1 + pricing::MAX_LINES..1 + pricing::MAX_LINES + count],
                    row[WIDTH - 2],
                    row[WIDTH - 1],
                )
            }
        };
        unsafe {
            *out.add(i) = value;
        }
    }
}

/// Adjacent GPU threads read adjacent cart words at every line position.
#[kernel]
pub unsafe fn cart_batch_soa(rows: &[u64], out: *mut u64, n: usize) {
    let i = thread::index_1d() as usize;
    if i < n {
        let value = if n > rows.len() / WIDTH { pricing::ERROR } else {
            pricing::total_with(rows[i] as usize, rows[65 * n + i], rows[66 * n + i],
                |j| rows[(1 + j) * n + i], |j| rows[(33 + j) * n + i])
        };
        unsafe { *out.add(i) = value; }
    }
}

/// Wide scalar ablation: one thread per cart, SoA for adjacent-cart reads.
#[kernel]
pub unsafe fn cart_wide_soa(rows: &[u64], out: *mut u64, n: usize, cap: usize) {
    let i=thread::index_1d() as usize;
    if i<n {
        let value=if cap>wide::MAX_LINES || n>rows.len()/wide::width(cap) { pricing::ERROR }
        else { wide::total_with(rows[i] as usize,cap,rows[(1+2*cap)*n+i],rows[(2+2*cap)*n+i],
            |j|rows[(1+j)*n+i],|j|rows[(1+cap+j)*n+i]) };
        unsafe { *out.add(i)=value; }
    }
}

/// Wide cooperative reduction: one 32-thread warp/block per cart, AoS data.
#[kernel]
pub unsafe fn cart_wide_cooperative(rows: &[u64], out: *mut u64, n: usize, cap: usize) {
    let cart=thread::block_idx_x() as usize;
    let lane=thread::thread_idx_x() as usize;
    if cart>=n { return; }
    let stride=wide::width(cap);
    let shape_ok=cap>0 && cap<=wide::MAX_LINES && n<=rows.len()/stride;
    let mut sum=0u64;let mut bad=if shape_ok {0u32}else{1u32};
    if shape_ok {
        let off=cart*stride;let count=rows[off] as usize;
        if count>cap || rows[off+stride-2]>2 || rows[off+stride-1]>pricing::MAX_PRICE {bad=1;}
        let mut j=lane;
        while j<count.min(cap) {
            let p=rows[off+1+j];let q=rows[off+1+cap+j];
            if p>pricing::MAX_PRICE || q==0 || q>pricing::MAX_QUANTITY {bad=1;} else {sum+=p*q;}
            j+=32;
        }
    }
    let mut offset=16;
    while offset>0 {
        // All 32 lanes participate, including lanes without any item.
        let other=unsafe {cuda_std::warp::warp_shuffle_down(u32::MAX,sum,offset,32)};
        let other_bad=unsafe {cuda_std::warp::warp_shuffle_down(u32::MAX,bad,offset,32)};
        sum+=other.0;bad|=other_bad.0;offset/=2;
    }
    if lane==0 {unsafe {*out.add(cart)=if bad!=0 {pricing::ERROR} else {
        let off=cart*stride;pricing::finish(sum,rows[off+stride-2],rows[off+stride-1])
    };}}
}
