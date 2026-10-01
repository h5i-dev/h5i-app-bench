// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::{future::Future, net::IpAddr, time::Duration};

use crate::upstream::academy_models::user::UserNameOrEmailAddress;
use thiserror::Error;

/// Server side brake on password guessing.
///
/// Independent of the captcha: the captcha hook in
/// [`crate::SessionFeatureService::create_session`] only asks the client to
/// solve a challenge and does nothing at all while reCAPTCHA is switched off,
/// whereas this service refuses the attempt outright. Both counters live in the
/// cache and expire on their own.
pub trait SessionLoginThrottleService: Send + Sync + 'static {
    /// Return an error if the given login is locked or the client address has
    /// used up its budget of failed attempts.
    fn check(
        &self,
        name_or_email: &UserNameOrEmailAddress,
        client_ip: IpAddr,
    ) -> impl Future<Output = Result<(), SessionLoginThrottleError>> + Send;

    /// Count a failed attempt against the given login and lock it once too many
    /// of them have failed.
    ///
    /// Every lock is longer than the one before it, up to a configured maximum.
    fn record_account_failure(
        &self,
        name_or_email: &UserNameOrEmailAddress,
    ) -> impl Future<Output = anyhow::Result<()>> + Send;

    /// Count a failed attempt against the given client address.
    fn record_ip_failure(
        &self,
        client_ip: IpAddr,
    ) -> impl Future<Output = anyhow::Result<()>> + Send;

    /// Forget the failed attempts counted against the given login.
    fn reset(
        &self,
        name_or_email: &UserNameOrEmailAddress,
    ) -> impl Future<Output = anyhow::Result<()>> + Send;
}

#[derive(Debug, Error)]
pub enum SessionLoginThrottleError {
    /// Further attempts are refused for the given time.
    #[error("Too many failed login attempts")]
    TooManyFailedAttempts(Duration),
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}
