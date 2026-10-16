// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use crate::upstream::academy_auth_contracts::refresh_token::AuthRefreshTokenService;
use crate::upstream::academy_di::Build;
use crate::upstream::academy_models::{auth::RefreshToken, session::SessionRefreshTokenHash};
use crate::upstream::academy_shared_contracts::{hash::HashService, secret::SecretService};
use crate::upstream::academy_utils::trace_instrument;

use super::AuthServiceConfig;

#[derive(Debug, Clone)]
pub struct AuthRefreshTokenServiceImpl<Secret, Hash> {
    pub secret: Secret,
    pub hash: Hash,
    pub config: AuthServiceConfig,
}

impl<Secret, Hash> AuthRefreshTokenService for AuthRefreshTokenServiceImpl<Secret, Hash>
where
    Secret: SecretService,
    Hash: HashService,
{
    fn issue(&self) -> RefreshToken {
        self.secret
            .generate(self.config.refresh_token_length)
            .0
            .into()
    }

    fn hash(&self, refresh_token: &RefreshToken) -> SessionRefreshTokenHash {
        self.hash.sha256(refresh_token).into()
    }
}
