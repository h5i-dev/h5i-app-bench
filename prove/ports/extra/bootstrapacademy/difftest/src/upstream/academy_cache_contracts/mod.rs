// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::{fmt::Debug, future::Future, time::Duration};

use serde::{Serialize, de::DeserializeOwned};

pub trait CacheService: Sized + Send + Sync + 'static {
    /// Read a cache item.
    fn get<T: DeserializeOwned + Debug + 'static>(
        &self,
        key: &str,
    ) -> impl Future<Output = anyhow::Result<Option<T>>> + Send;

    /// Create a new or update an existing cache item.
    ///
    /// If `ttl` is set, the item is automatically removed after this timeout.
    fn set<T: Serialize + Debug + Sync + 'static>(
        &self,
        key: &str,
        value: &T,
        ttl: Option<Duration>,
    ) -> impl Future<Output = anyhow::Result<()>> + Send;

    /// Read a cache item and remove it in the same operation.
    ///
    /// Returns `None` if the cache item does not exist. Because reading and
    /// removing happen atomically, this can be used to consume single use
    /// secrets: exactly one of two concurrent callers gets the value.
    fn pop<T: DeserializeOwned + Debug + 'static>(
        &self,
        key: &str,
    ) -> impl Future<Output = anyhow::Result<Option<T>>> + Send;

    /// Remove an existing cache item.
    ///
    /// Does nothing if the cache item does not exist.
    fn remove(&self, key: &str) -> impl Future<Output = anyhow::Result<()>> + Send;

    /// Verify the connection to the cache.
    fn ping(&self) -> impl Future<Output = anyhow::Result<()>> + Send;
}
