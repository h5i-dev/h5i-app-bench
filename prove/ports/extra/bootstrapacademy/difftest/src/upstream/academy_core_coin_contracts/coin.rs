// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::future::Future;

use crate::upstream::academy_models::{
    coin::{Balance, TransactionDescription},
    user::UserId,
};
use thiserror::Error;

pub trait CoinService<Txn: Send + Sync + 'static>: Send + Sync + 'static {
    /// Add Morphcoins to the given user's balance.
    fn add_coins(
        &self,
        txn: &mut Txn,
        user_id: UserId,
        coins: i64,
        withhold: bool,
        description: Option<TransactionDescription>,
        include_in_credit_note: bool,
    ) -> impl Future<Output = Result<Balance, CoinAddCoinsError>> + Send;
}

#[derive(Debug, Error)]
pub enum CoinAddCoinsError {
    #[error("The user does not have enough coins.")]
    NotEnoughCoins,
    #[error(transparent)]
    Other(#[from] anyhow::Error),
}
