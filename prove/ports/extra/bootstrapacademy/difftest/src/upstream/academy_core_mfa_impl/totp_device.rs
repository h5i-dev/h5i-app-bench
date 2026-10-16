// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use crate::upstream::academy_core_mfa_contracts::totp_device::{MfaTotpDeviceConfirmError, MfaTotpDeviceService};
use crate::upstream::academy_di::Build;
use crate::upstream::academy_models::{
    mfa::{TotpCode, TotpDevice, TotpDeviceId, TotpDevicePatch, TotpDevicePatchRef, TotpSetup},
    user::UserId,
};
use crate::upstream::academy_persistence_contracts::mfa::MfaRepository;
use crate::upstream::academy_shared_contracts::{
    id::IdService,
    time::TimeService,
    totp::{TotpCheckError, TotpService},
};
use crate::upstream::academy_utils::{patch::Patch, trace_instrument};
use anyhow::Context;
use crate::upstream::tracing::trace;

#[derive(Debug, Clone, Default)]
pub struct MfaTotpDeviceServiceImpl<Id, Time, Totp, MfaRepo> {
    pub id: Id,
    pub time: Time,
    pub totp: Totp,
    pub mfa_repo: MfaRepo,
}

impl<Txn, Id, Time, Totp, MfaRepo> MfaTotpDeviceService<Txn>
    for MfaTotpDeviceServiceImpl<Id, Time, Totp, MfaRepo>
where
    Txn: Send + Sync + 'static,
    Id: IdService,
    Time: TimeService,
    Totp: TotpService,
    MfaRepo: MfaRepository<Txn>,
{
    async fn create(&self, txn: &mut Txn, user_id: UserId) -> anyhow::Result<TotpSetup> {
        let (secret, setup) = self.totp.generate_secret();

        let totp_device = TotpDevice {
            id: self.id.generate(),
            user_id,
            enabled: false,
            created_at: self.time.now(),
        };

        self.mfa_repo
            .create_totp_device(txn, &totp_device, &secret)
            .await
            .context("Failed to save totp device in database")?;

        Ok(setup)
    }

    async fn confirm(
        &self,
        txn: &mut Txn,
        totp_device: TotpDevice,
        code: TotpCode,
    ) -> Result<TotpDevice, MfaTotpDeviceConfirmError> {
        trace!("get secret");
        let secret = self
            .mfa_repo
            .get_totp_device_secret(txn, totp_device.id)
            .await
            .context("Failed to get totp device secret from database")?;

        trace!("check code");
        self.totp
            .check(&code, secret)
            .await
            .map_err(|err| match err {
                TotpCheckError::InvalidCode | TotpCheckError::RecentlyUsed => {
                    MfaTotpDeviceConfirmError::InvalidCode
                }
                TotpCheckError::Other(err) => err.context("Failed to check totp code").into(),
            })?;

        trace!("update device");
        let patch = TotpDevicePatch::new().update_enabled(true);
        self.mfa_repo
            .update_totp_device(txn, totp_device.id, patch.as_ref())
            .await
            .context("Failed to update totp device in database")?;

        Ok(totp_device.update(patch))
    }

    async fn reset(
        &self,
        txn: &mut Txn,
        totp_device_id: TotpDeviceId,
    ) -> anyhow::Result<TotpSetup> {
        let (secret, setup) = self.totp.generate_secret();

        trace!("update device");
        self.mfa_repo
            .update_totp_device(
                txn,
                totp_device_id,
                TotpDevicePatchRef::new().update_enabled(&false),
            )
            .await
            .context("Failed to update totp device in database")?;

        trace!("update secret");
        self.mfa_repo
            .save_totp_device_secret(txn, totp_device_id, &secret)
            .await
            .context("Failed to update totp device secret in database")?;

        Ok(setup)
    }
}
