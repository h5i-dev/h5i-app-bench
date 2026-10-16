// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::{net::IpAddr, time::Duration};

use crate::upstream::academy_cache_contracts::CacheService;
use crate::upstream::academy_core_session_contracts::login_throttle::{
    SessionLoginThrottleError, SessionLoginThrottleService,
};
use crate::upstream::academy_di::Build;
use crate::upstream::academy_models::user::UserNameOrEmailAddress;
use crate::upstream::academy_shared_contracts::{hash::HashService, time::TimeService};
use crate::upstream::academy_utils::trace_instrument;
use anyhow::Context;
use chrono::{DateTime, TimeDelta, Utc};
use serde::{Deserialize, Serialize};
use crate::upstream::tracing::trace;

#[derive(Debug, Clone)]
pub struct SessionLoginThrottleServiceImpl<Time, Hash, Cache> {
    pub time: Time,
    pub hash: Hash,
    pub cache: Cache,
    pub config: SessionLoginThrottleConfig,
}

#[derive(Debug, Clone)]
pub struct SessionLoginThrottleConfig {
    /// Number of failed attempts against one login after which it is locked.
    pub fails_before_lock: u64,
    /// Lifetime of the counter of failed attempts against one login.
    pub fail_window: Duration,
    /// Length of the first lock. Every following one is twice as long as the
    /// one before it.
    pub lock_initial: Duration,
    /// Longest lock a login can receive.
    pub lock_max: Duration,
    /// Number of failed attempts from one client address after which further
    /// attempts from it are refused.
    ///
    /// An address is shared by everybody behind the same NAT, so this budget is
    /// deliberately far larger than the per login one.
    pub fails_per_ip: u64,
    /// Lifetime of the counter of failed attempts from one client address, and
    /// the length of the block that follows it.
    pub ip_window: Duration,
}

/// Failed attempts counted in one bucket of the cache.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
struct FailedAttempts {
    /// Number of failed attempts counted so far.
    count: u64,
    /// Point in time until which further attempts are refused, if the bucket
    /// is over its budget.
    #[serde(default)]
    blocked_until: Option<DateTime<Utc>>,
}

impl<Time, Hash, Cache> SessionLoginThrottleService
    for SessionLoginThrottleServiceImpl<Time, Hash, Cache>
where
    Time: TimeService,
    Hash: HashService,
    Cache: CacheService,
{
    // The login identifier does not belong in the logs of every failed attempt.
    async fn check(
        &self,
        name_or_email: &UserNameOrEmailAddress,
        client_ip: IpAddr,
    ) -> Result<(), SessionLoginThrottleError> {
        let now = self.time.now();

        // The address is only looked at once the login itself is in the clear,
        // so a locked login costs a single cache read.
        if let Some(retry_after) = self
            .blocked_for(&self.account_key(name_or_email), now)
            .await?
        {
            trace!("login attempt refused");
            return Err(SessionLoginThrottleError::TooManyFailedAttempts(
                retry_after,
            ));
        }

        if let Some(retry_after) = self.blocked_for(&self.ip_key(client_ip), now).await? {
            trace!("login attempt refused");
            return Err(SessionLoginThrottleError::TooManyFailedAttempts(
                retry_after,
            ));
        }

        Ok(())
    }

    async fn record_account_failure(
        &self,
        name_or_email: &UserNameOrEmailAddress,
    ) -> anyhow::Result<()> {
        let now = self.time.now();
        let key = self.account_key(name_or_email);
        let count = self.get(&key).await?.map_or(0, |a| a.count) + 1;

        // The first `fails_before_lock` attempts pass unhindered; each one after
        // that is answered with a lock twice as long as the previous one, up to
        // `lock_max`.
        let blocked_until = (count >= self.config.fails_before_lock).then(|| {
            let steps = count - self.config.fails_before_lock;
            let lock = self
                .config
                .lock_initial
                .saturating_mul(2u32.saturating_pow(steps.try_into().unwrap_or(u32::MAX)))
                .min(self.config.lock_max);
            now + TimeDelta::from_std(lock).unwrap_or(TimeDelta::MAX)
        });

        let ttl = self.ttl(now, self.config.fail_window, blocked_until);
        self.set(
            &key,
            FailedAttempts {
                count,
                blocked_until,
            },
            ttl,
        )
        .await
    }

    async fn record_ip_failure(&self, client_ip: IpAddr) -> anyhow::Result<()> {
        let now = self.time.now();
        let key = self.ip_key(client_ip);
        let count = self.get(&key).await?.map_or(0, |a| a.count) + 1;

        // Unlike a single login, an address is not locked for longer and longer:
        // it is shared by everybody behind the same NAT, so it only waits out
        // one window.
        let blocked_until = (count >= self.config.fails_per_ip)
            .then(|| now + TimeDelta::from_std(self.config.ip_window).unwrap_or(TimeDelta::MAX));

        let ttl = self.ttl(now, self.config.ip_window, blocked_until);
        self.set(
            &key,
            FailedAttempts {
                count,
                blocked_until,
            },
            ttl,
        )
        .await
    }

    async fn reset(&self, name_or_email: &UserNameOrEmailAddress) -> anyhow::Result<()> {
        self.cache
            .remove(&self.account_key(name_or_email))
            .await
            .context("Failed to reset failed login attempts in cache")
    }
}

impl<Time, Hash, Cache> SessionLoginThrottleServiceImpl<Time, Hash, Cache>
where
    Hash: HashService,
    Cache: CacheService,
{
    /// Return how long the given bucket is still blocked for, if it is.
    async fn blocked_for(&self, key: &str, now: DateTime<Utc>) -> anyhow::Result<Option<Duration>> {
        Ok(self
            .get(key)
            .await?
            .and_then(|attempts| attempts.blocked_until)
            .and_then(|blocked_until| (blocked_until - now).to_std().ok()))
    }

    async fn get(&self, key: &str) -> anyhow::Result<Option<FailedAttempts>> {
        self.cache
            .get(key)
            .await
            .context("Failed to get failed login attempts from cache")
    }

    async fn set(&self, key: &str, attempts: FailedAttempts, ttl: Duration) -> anyhow::Result<()> {
        self.cache
            .set(key, &attempts, Some(ttl))
            .await
            .context("Failed to save failed login attempts in cache")
    }

    /// Keep a bucket at least until its block has passed, so a lock cannot be
    /// shaken off by letting the counter expire.
    fn ttl(
        &self,
        now: DateTime<Utc>,
        window: Duration,
        blocked_until: Option<DateTime<Utc>>,
    ) -> Duration {
        blocked_until
            .and_then(|blocked_until| (blocked_until - now).to_std().ok())
            .unwrap_or_default()
            .max(window)
    }

    fn account_key(&self, name_or_email: &UserNameOrEmailAddress) -> String {
        let value = match name_or_email {
            UserNameOrEmailAddress::Name(name) => name,
            UserNameOrEmailAddress::Email(email) => email.as_str(),
        }
        .to_lowercase();
        format!("login_throttle_account:{}", self.hash_hex(&value))
    }

    fn ip_key(&self, client_ip: IpAddr) -> String {
        format!(
            "login_throttle_ip:{}",
            self.hash_hex(&client_ip.to_string())
        )
    }

    fn hash_hex(&self, value: &str) -> String {
        hex::encode(self.hash.sha256(&value.to_owned()).0)
    }
}

impl<Time, Hash, Cache> SessionLoginThrottleServiceImpl<Time, Hash, Cache> {
    pub fn new(time: Time, hash: Hash, cache: Cache, config: SessionLoginThrottleConfig) -> Self {
        Self {
            time,
            hash,
            cache,
            config,
        }
    }
}
