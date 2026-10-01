// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use crate::upstream::academy_core_withdrawal_contracts::consent::WithdrawalConsentService;
use crate::upstream::academy_di::Build;
use crate::upstream::academy_models::{
    user::UserId,
    withdrawal::{
        WithdrawalConsent, WithdrawalReference, WithdrawalSubject, WithdrawalTextVersion,
    },
};
use crate::upstream::academy_persistence_contracts::withdrawal::WithdrawalRepository;
use crate::upstream::academy_shared_contracts::{id::IdService, time::TimeService};
use crate::upstream::academy_utils::trace_instrument;

#[derive(Debug, Clone, Default)]
pub struct WithdrawalConsentServiceImpl<Id, Time, WithdrawalRepo> {
    pub id: Id,
    pub time: Time,
    pub withdrawal_repo: WithdrawalRepo,
}

impl<Txn, Id, Time, WithdrawalRepo> WithdrawalConsentService<Txn>
    for WithdrawalConsentServiceImpl<Id, Time, WithdrawalRepo>
where
    Txn: Send + Sync + 'static,
    Id: IdService,
    Time: TimeService,
    WithdrawalRepo: WithdrawalRepository<Txn>,
{
    async fn record(
        &self,
        txn: &mut Txn,
        user_id: UserId,
        subject: WithdrawalSubject,
        reference: Option<WithdrawalReference>,
        text_version: WithdrawalTextVersion,
    ) -> anyhow::Result<WithdrawalConsent> {
        let consent = WithdrawalConsent {
            id: self.id.generate(),
            user_id,
            subject,
            reference,
            text_version,
            consented_at: self.time.now(),
        };

        self.withdrawal_repo.create(txn, &consent).await?;

        Ok(consent)
    }
}
