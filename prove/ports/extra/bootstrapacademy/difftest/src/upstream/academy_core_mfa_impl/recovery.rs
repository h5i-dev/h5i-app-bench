// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use crate::upstream::academy_core_mfa_contracts::recovery::MfaRecoveryService;
use crate::upstream::academy_di::Build;
use crate::upstream::academy_models::{mfa::MfaRecoveryCode, user::UserId};
use crate::upstream::academy_persistence_contracts::mfa::MfaRepository;
use crate::upstream::academy_shared_contracts::{hash::HashService, secret::SecretService};
use crate::upstream::academy_utils::trace_instrument;
use anyhow::Context;

#[derive(Debug, Clone)]
pub struct MfaRecoveryServiceImpl<Secret, Hash, MfaRepo> {
    pub secret: Secret,
    pub hash: Hash,
    pub mfa_repo: MfaRepo,
}

impl<Txn, Secret, Hash, MfaRepo> MfaRecoveryService<Txn>
    for MfaRecoveryServiceImpl<Secret, Hash, MfaRepo>
where
    Txn: Send + Sync + 'static,
    Secret: SecretService,
    Hash: HashService,
    MfaRepo: MfaRepository<Txn>,
{
    async fn setup(&self, txn: &mut Txn, user_id: UserId) -> anyhow::Result<MfaRecoveryCode> {
        let recovery_code = self.secret.generate_mfa_recovery_code();

        let hash = self.hash.sha256(&recovery_code).into();
        self.mfa_repo
            .save_mfa_recovery_code_hash(txn, user_id, hash)
            .await
            .context("Failed to save MFA recovery code hash in database")?;

        Ok(recovery_code)
    }
}
