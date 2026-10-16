// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::future::Future;

use crate::upstream::academy_models::{
    user::UserId,
    withdrawal::{
        WithdrawalConsent, WithdrawalReference, WithdrawalSubject, WithdrawalTextVersion,
    },
};

pub trait WithdrawalConsentService<Txn: Send + Sync + 'static>: Send + Sync + 'static {
    /// Record the declarations a consumer gave before placing an order.
    fn record(
        &self,
        txn: &mut Txn,
        user_id: UserId,
        subject: WithdrawalSubject,
        reference: Option<WithdrawalReference>,
        text_version: WithdrawalTextVersion,
    ) -> impl Future<Output = anyhow::Result<WithdrawalConsent>> + Send;
}
