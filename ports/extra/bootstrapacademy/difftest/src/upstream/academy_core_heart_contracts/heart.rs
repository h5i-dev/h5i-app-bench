// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::future::Future;

use crate::upstream::academy_models::{heart::Hearts, user::UserId};
use thiserror::Error;

/// Get and update user hearts.
///
/// Handles auto refill transparently.
pub trait HeartService<Txn: Send + Sync + 'static>: Send + Sync + 'static {
    /// Return the hearts of the given user.
    fn get(
        &self,
        txn: &mut Txn,
        user_id: UserId,
    ) -> impl Future<Output = anyhow::Result<Hearts>> + Send;

    /// Add hearts for the given user.
    ///
    /// Limits the number of hearts to the configured maximum.
    /// Trying to reduce the number of hearts below zero returns an error.
    fn add(
        &self,
        txn: &mut Txn,
        user_id: UserId,
        hearts: i64,
    ) -> impl Future<Output = Result<Hearts, HeartAddError>> + Send;
}

#[derive(Debug, Error)]
pub enum HeartAddError {
    #[error("The user does not have enough hearts")]
    NotEnoughHearts,
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}
