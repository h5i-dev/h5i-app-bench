#![cfg(feature = "gpu")]
#![no_std]
use cuda_std::{kernel, thread};
#[path = "../../../src/pricing.rs"]
mod pricing;
#[path = "../../../src/wide.rs"]
mod wide;

// Commands: query IDs followed by (cart, slot, new price, new quantity).
// Within a round each (cart, slot) occurs once. One stream orders apply/query.
#[kernel]
pub unsafe fn resident_apply(rows: *mut u64, commands: &[u64], queries: usize, updates: usize, cap: usize) {
    let i = thread::index_1d() as usize;
    if i < updates {
        let p = queries + i*4;
        let off = commands[p] as usize * wide::width(cap);
        let slot = commands[p+1] as usize;
        unsafe {
            *rows.add(off+1+slot) = commands[p+2];
            *rows.add(off+1+cap+slot) = commands[p+3];
        }
    }
}

#[kernel]
pub unsafe fn resident_scan(rows: &[u64], commands: &[u64], out: *mut u64, queries: usize, cap: usize) {
    let i = thread::block_idx_x() as usize;
    let lane = thread::thread_idx_x() as usize;
    if i >= queries { return; }
    let cart = commands[i] as usize;
    let stride = wide::width(cap);
    let ok = cap > 0 && cap <= wide::MAX_LINES && cart < rows.len()/stride;
    let mut sum = 0u64;
    let mut bad = if ok { 0u32 } else { 1u32 };
    if ok {
        let off = cart*stride;
        let count = rows[off] as usize;
        if count > cap || rows[off+stride-2] > 2 || rows[off+stride-1] > pricing::MAX_PRICE { bad=1; }
        let mut j=lane;
        while j<count.min(cap) {
            let p=rows[off+1+j]; let q=rows[off+1+cap+j];
            if p>pricing::MAX_PRICE || q==0 || q>pricing::MAX_QUANTITY { bad=1; } else { sum+=p*q; }
            j+=32;
        }
    }
    let mut offset=16;
    while offset>0 {
        let other=unsafe {cuda_std::warp::warp_shuffle_down(u32::MAX,sum,offset,32)};
        let other_bad=unsafe {cuda_std::warp::warp_shuffle_down(u32::MAX,bad,offset,32)};
        sum+=other.0; bad|=other_bad.0; offset/=2;
    }
    if lane==0 { unsafe { *out.add(i)=if bad!=0 {pricing::ERROR} else {
        let off=cart*stride; pricing::finish(sum,rows[off+stride-2],rows[off+stride-1])
    }; } }
}

// One thread owns a queried cart and all of its round-robin patches. This
// avoids races/atomics even with sixteen patches to that cart in one round.
#[kernel]
pub unsafe fn resident_delta(rows: *mut u64, sums: *mut u64, totals: *mut u64,
    commands: &[u64], out: *mut u64, queries: usize, updates: usize, cap: usize) {
    let i=thread::index_1d() as usize;
    if i>=queries { return; }
    let cart=commands[i] as usize; let off=cart*wide::width(cap);
    let mut k=i;
    unsafe {
        let mut sum=*sums.add(cart);
        while k<updates {
            let p=queries+4*k; let slot=commands[p+1] as usize;
            let price=commands[p+2]; let qty=commands[p+3];
            sum-=*rows.add(off+1+slot) * *rows.add(off+1+cap+slot);
            sum+=price*qty;
            *rows.add(off+1+slot)=price; *rows.add(off+1+cap+slot)=qty;
            k+=queries;
        }
        if i<updates {
            *sums.add(cart)=sum;
            *totals.add(cart)=pricing::finish(sum,*rows.add(off+wide::width(cap)-2),*rows.add(off+wide::width(cap)-1));
        }
        *out.add(i)=*totals.add(cart);
    }
}
