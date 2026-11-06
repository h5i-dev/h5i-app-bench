//! `src/rate_limiter.rs` `RateLimiter::take_token` and `check_rate_limit`:
//! the per-user, per-action token bucket kept in `publish_limit_buckets`.
//!
//! Upstream runs one `INSERT .. ON CONFLICT DO UPDATE` statement:
//! a new bucket starts with `burst` tokens at `now`; an existing one gets
//! `tokens_to_add = floor((now - last_refill) / rate)`, then
//! `tokens = least(burst, greatest(0, tokens - 1) + tokens_to_add)` and
//! `last_refill += rate * tokens_to_add`. The request passes when the
//! returned `tokens >= 1`. Times are integer milliseconds here (upstream:
//! epoch seconds as `double`, a `rate` interval in milliseconds).

/// A `publish_limit_buckets` row's state.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Bucket {
    pub tokens: i64,
    pub last_refill: i64,
}

/// `take_token` for one request at `now`. `rate` is the refill interval
/// (positive), `burst` the bucket size (an override's or the default).
/// For `now >= last_refill` the division is the floor upstream takes.
pub fn take_token(bucket: Option<Bucket>, now: i64, rate: i64, burst: i64) -> Bucket {
    match bucket {
        None => Bucket { tokens: burst, last_refill: now },
        Some(b) => {
            let add = (now - b.last_refill) / rate;
            let kept = if b.tokens - 1 > 0 { b.tokens - 1 } else { 0 };
            let tokens = if add >= burst - kept { burst } else { kept + add };
            Bucket { tokens, last_refill: b.last_refill + rate * add }
        }
    }
}

/// `check_rate_limit`: the bucket afterwards, and whether the request passes.
pub fn check_rate_limit(bucket: Option<Bucket>, now: i64, rate: i64, burst: i64) -> (Bucket, bool) {
    let b = take_token(bucket, now, rate, burst);
    (b, b.tokens >= 1)
}
