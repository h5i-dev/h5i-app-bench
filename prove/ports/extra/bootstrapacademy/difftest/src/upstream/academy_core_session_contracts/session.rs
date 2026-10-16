// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::future::Future;

use crate::upstream::academy_models::{
    auth::Login,
    session::{DeviceName, SessionId},
    user::{UserComposite, UserId},
};
use thiserror::Error;

pub trait SessionService<Txn: Send + Sync + 'static>: Send + Sync + 'static {
    /// Create a new session for the given user.
    ///
    /// `mfa_verified` records whether the second factor of the user was
    /// verified before the session was created. Only sessions created with a
    /// verified second factor grant administrative privileges.
    fn create(
        &self,
        txn: &mut Txn,
        user_composite: UserComposite,
        device_name: Option<DeviceName>,
        update_last_login: bool,
        mfa_verified: bool,
    ) -> impl Future<Output = anyhow::Result<Login>> + Send;

    /// Refresh the given session by invalidating the current access/refresh
    /// token pair and generating a new one.
    fn refresh(
        &self,
        txn: &mut Txn,
        session_id: SessionId,
    ) -> impl Future<Output = Result<Login, SessionRefreshError>> + Send;

    /// Delete the given session and invalidate the current access/refresh token
    /// pair.
    fn delete(
        &self,
        txn: &mut Txn,
        session_id: SessionId,
    ) -> impl Future<Output = anyhow::Result<bool>> + Send;

    /// Delete all sessions of the given user and invalidate all associated
    /// access/refresh token pairs.
    fn delete_by_user(
        &self,
        txn: &mut Txn,
        user_id: UserId,
    ) -> impl Future<Output = anyhow::Result<()>> + Send;
}

#[derive(Debug, Error)]
pub enum SessionRefreshError {
    #[error("The session does not exist.")]
    NotFound,
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}
