//! Exact cents, with four extra decimal places until the final HALF_UP round.
//! Shared verbatim by stable CPU Rust and the Rust-CUDA device build.
pub const MAX_LINES: usize = 32;
pub const MAX_PRICE: u64 = 99_999_999; // benchmark subset, not the model's full DecimalField range
pub const MAX_QUANTITY: u64 = 1_000;
pub const ERROR: u64 = u64::MAX;

/// Prices and quantities are slices for ONE cart. No floating point money.
/// kind: 0 = none, 1 = percent (hundredths of one percent), 2 = fixed cents.
/// Tax and shipping are the upstream defaults (zero).
pub fn total(prices: &[u64], quantities: &[u64], kind: u64, value: u64) -> u64 {
    if prices.len() != quantities.len() { return ERROR; }
    total_with(prices.len(), kind, value, |i| prices[i], |i| quantities[i])
}

/// The same validated arithmetic with contiguous or transposed input access.
#[inline(always)]
pub fn total_with(count: usize, kind: u64, value: u64,
                  price: impl Fn(usize) -> u64, quantity: impl Fn(usize) -> u64) -> u64 {
    if count > MAX_LINES || kind > 2 || value > MAX_PRICE { return ERROR; }
    let mut subtotal = 0;
    let mut i = 0;
    while i < count {
        let p = price(i);
        let q = quantity(i);
        if p > MAX_PRICE || q == 0 || q > MAX_QUANTITY { return ERROR; }
        subtotal += p * q;
        i += 1;
    }
    finish(subtotal, kind, value)
}

#[inline(always)]
pub fn finish(subtotal: u64, kind: u64, value: u64) -> u64 {
    // Bounds above imply subtotal*value < 3.2e20, so cap percentages BEFORE
    // multiplication. Legacy values over 100% clamp to the subtotal upstream.
    let scaled = subtotal * 10_000;
    let discount = if kind == 1 {
        subtotal * if value > 10_000 { 10_000 } else { value }
    } else if kind == 2 {
        let fixed = value * 10_000;
        if fixed > scaled { scaled } else { fixed }
    } else {
        0
    };
    (scaled - discount + 5_000) / 10_000
}
