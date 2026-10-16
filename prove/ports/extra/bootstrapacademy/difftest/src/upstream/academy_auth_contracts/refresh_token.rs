// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use crate::upstream::academy_models::{auth::RefreshToken, session::SessionRefreshTokenHash};

pub trait AuthRefreshTokenService: Send + Sync + 'static {
    /// Generate a new refresh token.
    fn issue(&self) -> RefreshToken;

    /// Return the hash of the given refresh token.
    fn hash(&self, refresh_token: &RefreshToken) -> SessionRefreshTokenHash;
}
