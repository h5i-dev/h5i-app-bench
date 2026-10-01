//! `academy_core/session/impl`: `SessionLoginThrottleServiceImpl`
//! (login_throttle.rs) and `SessionFailedAuthCountServiceImpl`
//! (failed_auth_count.rs).
use crate::{valkey, cache_write, lower, CacheKey, CacheValue, Config, Ctx, Env, Error, FailedAttempts, NameOrEmail,
    Write};

fn login_value(name_or_email: &NameOrEmail) -> Vec<u8> {
    match name_or_email {
        NameOrEmail::Name(n) => lower(n),
        NameOrEmail::Email(e) => lower(e),
    }
}

/// `SessionLoginThrottleServiceImpl::account_key`.
pub fn account_key(name_or_email: &NameOrEmail) -> CacheKey {
    CacheKey::ThrottleAccount(login_value(name_or_email))
}

/// `SessionLoginThrottleServiceImpl::ip_key`.
pub fn ip_key(client_ip: u64) -> CacheKey {
    CacheKey::ThrottleIp(client_ip)
}

/// `SessionLoginThrottleServiceImpl::get`.
fn get(ctx: &Ctx, env: &Env, key: &CacheKey) -> Option<FailedAttempts> {
    match valkey::get(&ctx.cache, env.now, key) {
        Some(CacheValue::Attempts(a)) => Some(a),
        _ => None,
    }
}

/// `SessionLoginThrottleServiceImpl::blocked_for`: `(blocked_until -
/// now).to_std().ok()`, which is `Some(0)` at `blocked_until == now`.
pub fn blocked_for(ctx: &Ctx, env: &Env, key: &CacheKey) -> Option<u64> {
    match get(ctx, env, key) {
        Some(a) => match a.blocked_until {
            Some(b) => {
                if b >= env.now {
                    Some(b - env.now)
                } else {
                    None
                }
            }
            None => None,
        },
        None => None,
    }
}

/// `SessionLoginThrottleServiceImpl::check`.
pub fn check(ctx: &Ctx, env: &Env, name_or_email: &NameOrEmail, client_ip: u64) -> Result<(), Error> {
    // The address is only looked at once the login itself is in the clear.
    match blocked_for(ctx, env, &account_key(name_or_email)) {
        Some(retry_after) => return Err(Error::TooManyFailedAttempts(retry_after)),
        None => {}
    }
    match blocked_for(ctx, env, &ip_key(client_ip)) {
        Some(retry_after) => return Err(Error::TooManyFailedAttempts(retry_after)),
        None => {}
    }
    Ok(())
}

/// `SessionLoginThrottleServiceImpl::ttl`: keep a bucket at least until its
/// block has passed.
pub fn ttl(now: u64, window: u64, blocked_until: Option<u64>) -> u64 {
    let rest = match blocked_until {
        Some(b) => {
            if b >= now { b - now } else { 0 }
        }
        None => 0,
    };
    if rest > window { rest } else { window }
}

fn set(ctx: &mut Ctx, env: &Env, key: CacheKey, attempts: FailedAttempts, ttl: u64) {
    let e = valkey::entry(env.now, key, CacheValue::Attempts(attempts), Some(ttl));
    cache_write(ctx, Write::CacheSet(e));
}

fn count_of(a: Option<FailedAttempts>) -> u64 {
    match a {
        Some(a) => a.count,
        None => 0,
    }
}

/// `2u32.saturating_pow(steps.try_into().unwrap_or(u32::MAX))`.
pub fn pow2_saturating(steps: u64) -> u64 {
    if steps >= 32 { 4294967295 } else { 1u64 << steps }
}

/// `u64::saturating_mul`.
pub fn saturating_mul(a: u64, b: u64) -> u64 {
    if a != 0 && b > u64::MAX / a { u64::MAX } else { a * b }
}

/// The lock after `count` failures: `lock_initial * 2^(count -
/// fails_before_lock)`, capped at `lock_max`.
pub fn lock_for(c: &Config, count: u64) -> u64 {
    let steps = count - c.fails_before_lock;
    let lock = saturating_mul(c.lock_initial, pow2_saturating(steps));
    if lock < c.lock_max { lock } else { c.lock_max }
}

/// `SessionLoginThrottleServiceImpl::record_account_failure`.
pub fn record_account_failure(c: &Config, ctx: &mut Ctx, env: &Env, name_or_email: &NameOrEmail) {
    let key = account_key(name_or_email);
    let count = count_of(get(ctx, env, &key)).saturating_add(1);
    let blocked_until = if count >= c.fails_before_lock {
        Some(env.now.saturating_add(lock_for(c, count)))
    } else {
        None
    };
    let ttl = ttl(env.now, c.fail_window, blocked_until);
    set(ctx, env, key, FailedAttempts { count, blocked_until }, ttl);
}

/// `SessionLoginThrottleServiceImpl::record_ip_failure`: one window, not
/// growing locks.
pub fn record_ip_failure(c: &Config, ctx: &mut Ctx, env: &Env, client_ip: u64) {
    let key = ip_key(client_ip);
    let count = count_of(get(ctx, env, &key)).saturating_add(1);
    let blocked_until = if count >= c.fails_per_ip { Some(env.now.saturating_add(c.ip_window)) } else { None };
    let ttl = ttl(env.now, c.ip_window, blocked_until);
    set(ctx, env, key, FailedAttempts { count, blocked_until }, ttl);
}

/// `SessionLoginThrottleServiceImpl::reset`.
pub fn reset(ctx: &mut Ctx, name_or_email: &NameOrEmail) {
    cache_write(ctx, Write::CacheRemove(account_key(name_or_email)));
}

/// `SessionFailedAuthCountServiceImpl::cache_key`.
pub fn failed_auth_key(name_or_email: &NameOrEmail) -> CacheKey {
    CacheKey::FailedAuth(login_value(name_or_email))
}

fn failed_count(ctx: &Ctx, env: &Env, key: &CacheKey) -> u64 {
    match valkey::get(&ctx.cache, env.now, key) {
        Some(CacheValue::Count(n)) => n,
        _ => 0,
    }
}

/// `SessionFailedAuthCountServiceImpl::get`.
pub fn failed_auth_get(ctx: &Ctx, env: &Env, name_or_email: &NameOrEmail) -> u64 {
    failed_count(ctx, env, &failed_auth_key(name_or_email))
}

/// `SessionFailedAuthCountServiceImpl::increment`: no ttl.
pub fn failed_auth_increment(ctx: &mut Ctx, env: &Env, name_or_email: &NameOrEmail) {
    let key = failed_auth_key(name_or_email);
    let count = failed_count(ctx, env, &key);
    let e = valkey::entry(env.now, key, CacheValue::Count(count.saturating_add(1)), None);
    cache_write(ctx, Write::CacheSet(e));
}

/// `SessionFailedAuthCountServiceImpl::reset`.
pub fn failed_auth_reset(ctx: &mut Ctx, name_or_email: &NameOrEmail) {
    cache_write(ctx, Write::CacheRemove(failed_auth_key(name_or_email)));
}
