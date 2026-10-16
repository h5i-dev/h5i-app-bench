// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::future::Future;

use crate::upstream::academy_models::user::UserId;

pub trait MfaDisableService<Txn: Send + Sync + 'static>: Send + Sync + 'static {
    /// Completely disable MFA for the given user by deleting all TOTP devices
    /// and invalidating the MFA recovery code.
    fn disable(
        &self,
        txn: &mut Txn,
        user_id: UserId,
    ) -> impl Future<Output = anyhow::Result<()>> + Send;
}
