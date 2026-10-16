// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::future::Future;

use thiserror::Error;

pub trait CaptchaService: Send + Sync + 'static {
    /// Return the public reCAPTCHA sitekey if reCAPTCHA is enabled.
    #[allow(clippy::needless_lifetimes, reason = "automock")]
    fn get_recaptcha_sitekey<'a>(&'a self) -> Option<&'a str>;

    /// Verify the given reCAPTCHA response.
    #[allow(clippy::needless_lifetimes, reason = "automock")]
    fn check<'a>(
        &self,
        response: Option<&'a str>,
    ) -> impl Future<Output = Result<(), CaptchaCheckError>> + Send;
}

#[derive(Debug, Error)]
pub enum CaptchaCheckError {
    #[error("The response is invalid or the user is probably not human.")]
    Failed,
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}
