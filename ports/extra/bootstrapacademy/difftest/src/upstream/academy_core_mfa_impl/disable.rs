// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use crate::upstream::academy_auth_contracts::AuthService;
use crate::upstream::academy_core_mfa_contracts::disable::MfaDisableService;
use crate::upstream::academy_di::Build;
use crate::upstream::academy_models::user::UserId;
use crate::upstream::academy_persistence_contracts::{mfa::MfaRepository, session::SessionRepository};
use crate::upstream::academy_utils::trace_instrument;
use anyhow::Context;
use crate::upstream::tracing::trace;

#[derive(Debug, Clone)]
pub struct MfaDisableServiceImpl<Auth, MfaRepo, SessionRepo> {
    pub auth: Auth,
    pub mfa_repo: MfaRepo,
    pub session_repo: SessionRepo,
}

impl<Txn, Auth, MfaRepo, SessionRepo> MfaDisableService<Txn>
    for MfaDisableServiceImpl<Auth, MfaRepo, SessionRepo>
where
    Txn: Send + Sync + 'static,
    Auth: AuthService<Txn>,
    MfaRepo: MfaRepository<Txn>,
    SessionRepo: SessionRepository<Txn>,
{
    async fn disable(&self, txn: &mut Txn, user_id: UserId) -> anyhow::Result<()> {
        trace!("delete totp devices");
        self.mfa_repo
            .delete_totp_devices_by_user(txn, user_id)
            .await
            .context("Failed to delete totp devices from database")?;

        trace!("delete recovery code");
        self.mfa_repo
            .delete_mfa_recovery_code_hash(txn, user_id)
            .await
            .context("Failed to delete MFA recovery code hash from database")?;

        // Administrative authority is granted to a session that was
        // authenticated with the second factor, so it has to end with the
        // second factor. Without this a session stayed `mfa_verified` for the
        // whole `session.refresh_token_ttl`, and removing an administrator's
        // authenticator did not reduce that.
        trace!("clear mfa_verified on the sessions of the user");
        self.session_repo
            .clear_mfa_verified_by_user(txn, user_id)
            .await
            .context("Failed to clear mfa_verified in database")?;

        // The access token carries `mfa_verified` as well, so it has to be
        // reissued; the next refresh reads the cleared value from the session.
        self.auth
            .invalidate_access_tokens(txn, user_id)
            .await
            .context("Failed to invalidate access tokens")?;

        Ok(())
    }
}
