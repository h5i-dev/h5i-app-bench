// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::future::Future;

use crate::upstream::academy_models::user::UserNameOrEmailAddress;

pub trait SessionFailedAuthCountService: Send + Sync + 'static {
    /// Return the number of failed authentication attempts for the given login.
    fn get(
        &self,
        name_or_email: &UserNameOrEmailAddress,
    ) -> impl Future<Output = anyhow::Result<u64>> + Send;

    /// Increment the number of failed authentication attempts for the given
    /// login.
    fn increment(
        &self,
        name_or_email: &UserNameOrEmailAddress,
    ) -> impl Future<Output = anyhow::Result<()>> + Send;

    /// Reset the number of failed authentication attempts for the given login.
    fn reset(
        &self,
        name_or_email: &UserNameOrEmailAddress,
    ) -> impl Future<Output = anyhow::Result<()>> + Send;
}
