//! `academy_cache/valkey` `ValkeyCache`: `get`, `set` (`PSETEX` when a ttl is
//! given) and `remove`. An entry is gone once `now >= expires`.
use crate::{bytes_eq, CacheEntry, CacheKey, CacheValue, Write};

pub fn key_eq(a: &CacheKey, b: &CacheKey) -> bool {
    match (a, b) {
        (CacheKey::Invalidated(x), CacheKey::Invalidated(y)) => *x == *y,
        (CacheKey::FailedAuth(x), CacheKey::FailedAuth(y)) => bytes_eq(x, y),
        (CacheKey::ThrottleAccount(x), CacheKey::ThrottleAccount(y)) => bytes_eq(x, y),
        (CacheKey::ThrottleIp(x), CacheKey::ThrottleIp(y)) => *x == *y,
        _ => false,
    }
}

fn live(e: &CacheEntry, now: u64) -> bool {
    match e.expires {
        Some(t) => now < t,
        None => true,
    }
}

/// `CacheService::get`.
pub fn get(cache: &Vec<CacheEntry>, now: u64, key: &CacheKey) -> Option<CacheValue> {
    let mut i = 0;
    while i < cache.len() {
        if key_eq(&cache[i].key, key) {
            if live(&cache[i], now) {
                return Some(cache[i].value.clone());
            }
            return None;
        }
        i += 1;
    }
    None
}

/// The entry `CacheService::set` stores.
pub fn entry(now: u64, key: CacheKey, value: CacheValue, ttl: Option<u64>) -> CacheEntry {
    let expires = match ttl {
        Some(t) => Some(now.saturating_add(t)),
        None => None,
    };
    CacheEntry { key, value, expires }
}

fn remove(cache: &Vec<CacheEntry>, key: &CacheKey) -> Vec<CacheEntry> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < cache.len() {
        if !key_eq(&cache[i].key, key) {
            out.push(cache[i].clone());
        }
        i += 1;
    }
    out
}

/// The effect of a cache write. Database writes leave the cache alone.
pub fn apply(cache: &mut Vec<CacheEntry>, w: &Write) {
    match w {
        Write::CacheSet(e) => {
            let mut rest = remove(cache, &e.key);
            rest.push(e.clone());
            *cache = rest;
        }
        Write::CacheRemove(k) => *cache = remove(cache, k),
        _ => {}
    }
}
