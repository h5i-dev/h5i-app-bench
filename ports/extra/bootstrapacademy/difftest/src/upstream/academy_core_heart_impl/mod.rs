// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use crate::upstream::academy_auth_contracts::{AuthResultExt, AuthService};
use crate::upstream::academy_core_coin_contracts::coin::{CoinAddCoinsError, CoinService};
use crate::upstream::academy_core_heart_contracts::{
    HeartFeatureService, HeartGetError, HeartRefillError, heart::HeartService,
};
use crate::upstream::academy_core_withdrawal_contracts::consent::WithdrawalConsentService;
use crate::upstream::academy_di::Build;
use crate::upstream::academy_models::{
    auth::AccessToken,
    heart::{HeartConfig, Hearts},
    user::UserIdOrSelf,
    withdrawal::{WithdrawalConsentDeclaration, WithdrawalSubject},
};
use crate::upstream::academy_persistence_contracts::{Database, Transaction, user::UserRepository};
use crate::upstream::academy_utils::trace_instrument;
use chrono::NaiveTime;

pub mod heart;


#[derive(Debug, Clone)]
pub struct HeartFeatureServiceImpl<Db, Auth, UserRepo, Heart, Coin, WithdrawalConsentS> {
    pub db: Db,
    pub auth: Auth,
    pub user_repo: UserRepo,
    pub heart: Heart,
    pub coin: Coin,
    pub withdrawal_consent: WithdrawalConsentS,
    pub config: HeartFeatureConfig,
}

#[derive(Debug, Clone)]
pub struct HeartFeatureConfig {
    pub hearts_max: u64,
    pub hearts_refill_price: u64,
    pub auto_refill_time: NaiveTime,
}

impl<Db, Auth, UserRepo, Heart, Coin, WithdrawalConsentS> HeartFeatureService
    for HeartFeatureServiceImpl<Db, Auth, UserRepo, Heart, Coin, WithdrawalConsentS>
where
    Db: Database,
    Auth: AuthService<Db::Transaction>,
    UserRepo: UserRepository<Db::Transaction>,
    Heart: HeartService<Db::Transaction>,
    Coin: CoinService<Db::Transaction>,
    WithdrawalConsentS: WithdrawalConsentService<Db::Transaction>,
{
    fn get_config(&self) -> HeartConfig {
        HeartConfig {
            hearts_max: self.config.hearts_max,
            hearts_refill_price: self.config.hearts_refill_price,
        }
    }

    async fn get(
        &self,
        token: &AccessToken,
        user_id: UserIdOrSelf,
    ) -> Result<Hearts, HeartGetError> {
        let auth = self.auth.authenticate(token).await.map_auth_err()?;
        let user_id = user_id.unwrap_or(auth.user_id);
        auth.ensure_self_or_admin(user_id).map_auth_err()?;

        let mut txn = self.db.begin_transaction().await?;

        if !self.user_repo.exists(&mut txn, user_id).await? {
            return Err(HeartGetError::UserNotFound);
        }

        self.heart.get(&mut txn, user_id).await.map_err(Into::into)
    }

    async fn refill(
        &self,
        token: &AccessToken,
        declaration: WithdrawalConsentDeclaration,
    ) -> Result<Hearts, HeartRefillError> {
        // Refilling hearts is a purchase of digital content, so the order is
        // only accepted if the consumer gave the declarations under
        // § 356 Abs. 6 Nr. 2 BGB.
        let withdrawal_text_version = declaration
            .text_version()
            .ok_or(HeartRefillError::WithdrawalConsentMissing)?
            .clone();

        let auth = self.auth.authenticate(token).await.map_auth_err()?;
        let user_id = auth.user_id;

        let mut txn = self.db.begin_transaction().await?;

        let hearts = self.heart.get(&mut txn, user_id).await?;
        if hearts.hearts >= self.config.hearts_max {
            return Ok(hearts);
        }

        self.coin
            .add_coins(
                &mut txn,
                user_id,
                -(self.config.hearts_refill_price as i64),
                false,
                Some("Hearts".try_into().unwrap()),
                false,
            )
            .await
            .map_err(|err| match err {
                CoinAddCoinsError::NotEnoughCoins => HeartRefillError::NotEnoughCoins,
                CoinAddCoinsError::Other(err) => err.into(),
            })?;

        let hearts = self
            .heart
            .add(&mut txn, user_id, self.config.hearts_max as _)
            .await
            .map_err(anyhow::Error::from)?;

        self.withdrawal_consent
            .record(
                &mut txn,
                user_id,
                WithdrawalSubject::Hearts,
                None,
                withdrawal_text_version,
            )
            .await?;

        txn.commit().await?;

        Ok(hearts)
    }
}
