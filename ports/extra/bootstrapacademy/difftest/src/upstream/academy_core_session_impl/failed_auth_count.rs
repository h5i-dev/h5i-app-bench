// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use crate::upstream::academy_cache_contracts::CacheService;
use crate::upstream::academy_core_session_contracts::failed_auth_count::SessionFailedAuthCountService;
use crate::upstream::academy_di::Build;
use crate::upstream::academy_models::user::UserNameOrEmailAddress;
use crate::upstream::academy_shared_contracts::hash::HashService;
use crate::upstream::academy_utils::trace_instrument;
use anyhow::Context;

#[derive(Debug, Clone)]
pub struct SessionFailedAuthCountServiceImpl<Hash, Cache> {
    pub hash: Hash,
    pub cache: Cache,
}

impl<Hash, Cache> SessionFailedAuthCountService for SessionFailedAuthCountServiceImpl<Hash, Cache>
where
    Hash: HashService,
    Cache: CacheService,
{
    async fn get(&self, name_or_email: &UserNameOrEmailAddress) -> anyhow::Result<u64> {
        self.cache
            .get(&self.cache_key(name_or_email))
            .await
            .map(|x| x.unwrap_or(0))
            .context("Failed to get failed auth count from cache")
    }

    async fn increment(&self, name_or_email: &UserNameOrEmailAddress) -> anyhow::Result<()> {
        let cache_key = self.cache_key(name_or_email);

        let count = self
            .cache
            .get(&cache_key)
            .await
            .context("Failed to get failed auth count from cache")?
            .unwrap_or(0u64);

        self.cache
            .set(&cache_key, &(count + 1), None)
            .await
            .context("Failed to save failed auth count in cache")
    }

    async fn reset(&self, name_or_email: &UserNameOrEmailAddress) -> anyhow::Result<()> {
        self.cache
            .remove(&self.cache_key(name_or_email))
            .await
            .context("Failed to reset failed auth count in cache")
    }
}

impl<Hash, Cache> SessionFailedAuthCountServiceImpl<Hash, Cache>
where
    Hash: HashService,
{
    fn cache_key(&self, name_or_email: &UserNameOrEmailAddress) -> String {
        let hash = self.hash.sha256(
            &match name_or_email {
                UserNameOrEmailAddress::Name(name) => name,
                UserNameOrEmailAddress::Email(email) => email.as_str(),
            }
            .to_lowercase(),
        );
        format!("failed_auth_attempts:{}", hex::encode(hash.0))
    }
}
