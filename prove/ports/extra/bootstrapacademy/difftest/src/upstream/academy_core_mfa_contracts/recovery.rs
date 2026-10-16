// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::future::Future;

use crate::upstream::academy_models::{mfa::MfaRecoveryCode, user::UserId};

pub trait MfaRecoveryService<Txn: Send + Sync + 'static>: Send + Sync + 'static {
    /// Generate a new MFA recovery code for the given user.
    fn setup(
        &self,
        txn: &mut Txn,
        user_id: UserId,
    ) -> impl Future<Output = anyhow::Result<MfaRecoveryCode>> + Send;
}
