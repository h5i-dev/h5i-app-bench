//! Separate 2,048-line contract; the original 32-line snapshot ABI is unchanged.
use crate::pricing::{finish, ERROR, MAX_PRICE, MAX_QUANTITY};
pub const MAX_LINES: usize = 2048;
pub const fn width(cap: usize) -> usize { 2 * cap + 3 }
pub fn at(row: &[u64], cap: usize) -> u64 {
    if cap == 0 || cap > MAX_LINES || row.len() != width(cap) { return ERROR; }
    total_with(row[0] as usize, cap, row[width(cap)-2], row[width(cap)-1],
        |j| row[1+j], |j| row[1+cap+j])
}
#[inline(always)]
pub fn total_with(count: usize, cap: usize, kind: u64, value: u64,
    price: impl Fn(usize)->u64, quantity: impl Fn(usize)->u64) -> u64 {
    if cap == 0 || cap > MAX_LINES || count > cap || kind > 2 || value > MAX_PRICE { return ERROR; }
    let mut subtotal=0;
    let mut j=0;
    while j<count {
        let p=price(j); let q=quantity(j);
        if p>MAX_PRICE || q==0 || q>MAX_QUANTITY { return ERROR; }
        subtotal+=p*q; j+=1;
    }
    // At maximum bounds: subtotal*10,000 < 2.048e18 < u64::MAX.
    finish(subtotal,kind,value)
}
