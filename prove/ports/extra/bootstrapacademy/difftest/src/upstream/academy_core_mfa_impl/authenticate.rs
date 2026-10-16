// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use crate::upstream::academy_core_mfa_contracts::{
    authenticate::{MfaAuthenticateError, MfaAuthenticateResult, MfaAuthenticateService},
    disable::MfaDisableService,
};
use crate::upstream::academy_di::Build;
use crate::upstream::academy_models::{mfa::MfaAuthentication, user::UserId};
use crate::upstream::academy_persistence_contracts::mfa::MfaRepository;
use crate::upstream::academy_shared_contracts::{
    hash::HashService,
    totp::{TotpCheckError, TotpService},
};
use crate::upstream::academy_utils::trace_instrument;
use anyhow::Context;
use crate::upstream::tracing::trace;

#[derive(Debug, Clone, Default)]
pub struct MfaAuthenticateServiceImpl<Hash, Totp, MfaDisable, MfaRepo> {
    pub hash: Hash,
    pub totp: Totp,
    pub mfa_disable: MfaDisable,
    pub mfa_repo: MfaRepo,
}

impl<Txn, Hash, Totp, MfaDisable, MfaRepo> MfaAuthenticateService<Txn>
    for MfaAuthenticateServiceImpl<Hash, Totp, MfaDisable, MfaRepo>
where
    Txn: Send + Sync + 'static,
    Hash: HashService,
    Totp: TotpService,
    MfaDisable: MfaDisableService<Txn>,
    MfaRepo: MfaRepository<Txn>,
{
    async fn authenticate(
        &self,
        txn: &mut Txn,
        user_id: UserId,
        cmd: MfaAuthentication,
    ) -> Result<MfaAuthenticateResult, MfaAuthenticateError> {
        trace!("list totp secrets");
        let totp_secrets = self
            .mfa_repo
            .list_enabled_totp_device_secrets_by_user(txn, user_id)
            .await
            .context("Failed to get totp secrets from database")?;

        if totp_secrets.is_empty() {
            trace!("no totp secrets");
            return Ok(MfaAuthenticateResult::Disabled);
        }

        if let Some(recovery_code) = cmd.recovery_code {
            trace!("try recovery code");

            if let Some(hash) = self
                .mfa_repo
                .get_mfa_recovery_code_hash(txn, user_id)
                .await
                .context("Failed to get recovery code hash from database")?
                && self.hash.sha256(&recovery_code) == *hash
            {
                trace!("recovery code matches");
                self.mfa_disable
                    .disable(txn, user_id)
                    .await
                    .context("Failed to disable MFA")?;
                return Ok(MfaAuthenticateResult::Reset);
            }
        }

        if let Some(code) = cmd.totp_code {
            trace!("try totp code");

            for secret in totp_secrets {
                match self.totp.check(&code, secret).await {
                    Ok(()) => {
                        trace!("totp code matches");
                        return Ok(MfaAuthenticateResult::Ok);
                    }
                    Err(TotpCheckError::InvalidCode | TotpCheckError::RecentlyUsed) => (),
                    Err(TotpCheckError::Other(err)) => {
                        return Err(err.context("Failed to check totp code").into());
                    }
                }
            }
        }

        trace!("all mfa options failed");

        Err(MfaAuthenticateError::Failed)
    }
}
