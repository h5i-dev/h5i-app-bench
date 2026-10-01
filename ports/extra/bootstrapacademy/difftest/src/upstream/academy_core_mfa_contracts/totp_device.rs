// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::future::Future;

use crate::upstream::academy_models::{
    mfa::{TotpCode, TotpDevice, TotpDeviceId, TotpSetup},
    user::UserId,
};
use thiserror::Error;

pub trait MfaTotpDeviceService<Txn: Send + Sync + 'static>: Send + Sync + 'static {
    /// Create a new unconfirmed TOTP device.
    fn create(
        &self,
        txn: &mut Txn,
        user_id: UserId,
    ) -> impl Future<Output = anyhow::Result<TotpSetup>> + Send;

    /// Confirm a previously created TOTP device.
    fn confirm(
        &self,
        txn: &mut Txn,
        totp_device: TotpDevice,
        code: TotpCode,
    ) -> impl Future<Output = Result<TotpDevice, MfaTotpDeviceConfirmError>> + Send;

    /// Reset an existing TOTP device.
    fn reset(
        &self,
        txn: &mut Txn,
        totp_device_id: TotpDeviceId,
    ) -> impl Future<Output = anyhow::Result<TotpSetup>> + Send;
}

#[derive(Debug, Error)]
pub enum MfaTotpDeviceConfirmError {
    #[error("The totp code is incorrect.")]
    InvalidCode,
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}
