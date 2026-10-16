// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use crate::upstream::academy_core_coin_contracts::coin::{CoinAddCoinsError, CoinService};
use crate::upstream::academy_di::Build;
use crate::upstream::academy_models::{
    coin::{Balance, Transaction, TransactionDescription},
    user::UserId,
};
use crate::upstream::academy_persistence_contracts::coin::{CoinRepoAddCoinsError, CoinRepository};
use crate::upstream::academy_shared_contracts::{id::IdService, time::TimeService};
use crate::upstream::academy_utils::trace_instrument;

#[derive(Debug, Clone, Default)]
pub struct CoinServiceImpl<Id, Time, CoinRepo> {
    pub id: Id,
    pub time: Time,
    pub coin_repo: CoinRepo,
}

impl<Txn, Id, Time, CoinRepo> CoinService<Txn> for CoinServiceImpl<Id, Time, CoinRepo>
where
    Txn: Send + Sync + 'static,
    Id: IdService,
    Time: TimeService,
    CoinRepo: CoinRepository<Txn>,
{
    async fn add_coins(
        &self,
        txn: &mut Txn,
        user_id: UserId,
        coins: i64,
        withhold: bool,
        description: Option<TransactionDescription>,
        include_in_credit_note: bool,
    ) -> Result<Balance, CoinAddCoinsError> {
        let new_balance = self
            .coin_repo
            .add_coins(txn, user_id, coins, withhold)
            .await
            .map_err(|err| match err {
                CoinRepoAddCoinsError::NotEnoughCoins => CoinAddCoinsError::NotEnoughCoins,
                CoinRepoAddCoinsError::Other(err) => err.into(),
            })?;

        let transaction = Transaction {
            id: self.id.generate(),
            user_id,
            coins,
            description,
            created_at: self.time.now(),
            include_in_credit_note,
        };
        self.coin_repo.create_transaction(txn, &transaction).await?;

        Ok(new_balance)
    }
}
