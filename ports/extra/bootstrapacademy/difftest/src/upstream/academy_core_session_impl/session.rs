// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use crate::upstream::academy_auth_contracts::{AuthService, access_token::AuthAccessTokenService};
use crate::upstream::academy_core_session_contracts::session::{SessionRefreshError, SessionService};
use crate::upstream::academy_di::Build;
use crate::upstream::academy_models::{
    auth::Login,
    session::{DeviceName, Session, SessionId, SessionPatch},
    user::{UserComposite, UserId, UserPatch},
};
use crate::upstream::academy_persistence_contracts::{session::SessionRepository, user::UserRepository};
use crate::upstream::academy_shared_contracts::{id::IdService, time::TimeService};
use crate::upstream::academy_utils::{patch::Patch, trace_instrument};
use anyhow::Context;

#[derive(Debug, Clone, Default)]
pub struct SessionServiceImpl<Id, Time, Auth, AuthAccessToken, SessionRepo, UserRepo> {
    pub id: Id,
    pub time: Time,
    pub auth: Auth,
    pub auth_access_token: AuthAccessToken,
    pub session_repo: SessionRepo,
    pub user_repo: UserRepo,
}

impl<Txn, Id, Time, Auth, AuthAccessToken, SessionRepo, UserRepo> SessionService<Txn>
    for SessionServiceImpl<Id, Time, Auth, AuthAccessToken, SessionRepo, UserRepo>
where
    Txn: Send + Sync + 'static,
    Id: IdService,
    Time: TimeService,
    Auth: AuthService<Txn>,
    AuthAccessToken: AuthAccessTokenService,
    SessionRepo: SessionRepository<Txn>,
    UserRepo: UserRepository<Txn>,
{
    async fn create(
        &self,
        txn: &mut Txn,
        mut user_composite: UserComposite,
        device_name: Option<DeviceName>,
        update_last_login: bool,
        mfa_verified: bool,
    ) -> anyhow::Result<Login> {
        anyhow::ensure!(
            user_composite.user.enabled,
            "Ordinary session unavailable for restricted account"
        );
        let id = self.id.generate();
        let now = self.time.now();

        let session = Session {
            id,
            user_id: user_composite.user.id,
            device_name,
            created_at: now,
            updated_at: now,
            mfa_verified,
        };

        let tokens = self
            .auth
            .issue_tokens(&user_composite.user, session.id, session.mfa_verified)
            .context("Failed to issue tokens")?;

        self.session_repo
            .create(txn, &session)
            .await
            .context("Failed to create session in database")?;
        self.session_repo
            .save_refresh_token_hash(txn, session.id, tokens.refresh_token_hash)
            .await
            .context("Failed to save session refresh token hash in database")?;

        if update_last_login {
            let patch = UserPatch::new().update_last_login(Some(now));
            self.user_repo
                .update(txn, user_composite.user.id, patch.as_ref())
                .await
                .context("Failed to update user in database")?;
            user_composite.user = user_composite.user.update(patch);
        }

        Ok(Login {
            user_composite,
            session,
            access_token: tokens.access_token,
            refresh_token: tokens.refresh_token,
        })
    }

    async fn refresh(
        &self,
        txn: &mut Txn,
        session_id: SessionId,
    ) -> Result<Login, SessionRefreshError> {
        // get session and user from database
        let refresh_token_hash = self
            .session_repo
            .get_refresh_token_hash(txn, session_id)
            .await
            .context("Failed to get session refresh token hash from database")?
            .ok_or(SessionRefreshError::NotFound)?;

        let session = self
            .session_repo
            .get(txn, session_id)
            .await
            .context("Failed to get session from database")?
            .ok_or(SessionRefreshError::NotFound)?;

        let user_composite = self
            .user_repo
            .get_composite(txn, session.user_id)
            .await
            .context("Failed to get user from database")?
            .ok_or(SessionRefreshError::NotFound)?;

        if !user_composite.user.enabled {
            return Err(SessionRefreshError::NotFound);
        }

        // invalidate old access token
        self.auth_access_token
            .invalidate(refresh_token_hash)
            .await
            .context("Failed to invalidate old access token")?;

        // issue new token pair
        let tokens = self
            .auth
            .issue_tokens(&user_composite.user, session_id, session.mfa_verified)
            .context("Failed to issue tokens")?;

        // update session
        let patch = SessionPatch::new().update_updated_at(self.time.now());
        if !self
            .session_repo
            .update(txn, session.id, patch.as_ref())
            .await
            .context("Failed to update session in database")?
        {
            return Err(SessionRefreshError::NotFound);
        }
        let session = session.update(patch);

        self.session_repo
            .save_refresh_token_hash(txn, session.id, tokens.refresh_token_hash)
            .await
            .context("Failed to update session refresh token hash in database")?;

        Ok(Login {
            user_composite,
            session,
            access_token: tokens.access_token,
            refresh_token: tokens.refresh_token,
        })
    }

    async fn delete(&self, txn: &mut Txn, session_id: SessionId) -> anyhow::Result<bool> {
        if let Some(refresh_token_hash) = self
            .session_repo
            .get_refresh_token_hash(txn, session_id)
            .await
            .context("Failed to get session fresh token hash from database")?
        {
            self.auth_access_token
                .invalidate(refresh_token_hash)
                .await
                .context("Failed to invalidate access token")?;
        }

        self.session_repo
            .delete(txn, session_id)
            .await
            .context("Failed to delete session from database")
    }

    async fn delete_by_user(&self, txn: &mut Txn, user_id: UserId) -> anyhow::Result<()> {
        self.auth
            .invalidate_access_tokens(txn, user_id)
            .await
            .context("Failed to invalidate access tokens")?;

        self.session_repo
            .delete_by_user(txn, user_id)
            .await
            .context("Failed to delete sessions from database")?;

        Ok(())
    }
}
