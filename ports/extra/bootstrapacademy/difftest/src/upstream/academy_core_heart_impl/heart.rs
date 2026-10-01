// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use crate::upstream::academy_core_heart_contracts::heart::{HeartAddError, HeartService};
use crate::upstream::academy_di::Build;
use crate::upstream::academy_models::{heart::Hearts, user::UserId};
use crate::upstream::academy_persistence_contracts::heart::HeartRepository;
use crate::upstream::academy_shared_contracts::time::TimeService;
use crate::upstream::academy_utils::trace_instrument;
use chrono::{DateTime, TimeDelta, Utc};

use super::HeartFeatureConfig;

#[derive(Debug, Clone)]
pub struct HeartServiceImpl<Time, HeartRepo> {
    pub time: Time,
    pub heart_repo: HeartRepo,
    pub config: HeartFeatureConfig,
}

impl<Txn, Time, HeartRepo> HeartService<Txn> for HeartServiceImpl<Time, HeartRepo>
where
    Txn: Send + Sync + 'static,
    Time: TimeService,
    HeartRepo: HeartRepository<Txn>,
{
    async fn get(&self, txn: &mut Txn, user_id: UserId) -> anyhow::Result<Hearts> {
        Ok(self.apply_auto_refill(self.heart_repo.get(txn, user_id).await?))
    }

    async fn add(
        &self,
        txn: &mut Txn,
        user_id: UserId,
        hearts: i64,
    ) -> Result<Hearts, HeartAddError> {
        let current = self.apply_auto_refill(self.heart_repo.get(txn, user_id).await?);

        let hearts = Hearts {
            hearts: u64::try_from(current.hearts as i64 + hearts)
                .map_err(|_| HeartAddError::NotEnoughHearts)?
                .min(self.config.hearts_max),
            ..current
        };

        self.heart_repo.set(txn, user_id, hearts).await?;

        Ok(hearts)
    }
}

impl<Time, HeartRepo> HeartServiceImpl<Time, HeartRepo>
where
    Time: TimeService,
{
    fn apply_auto_refill(&self, hearts: Option<Hearts>) -> Hearts {
        let last_auto_refill = self.last_auto_refill();
        match hearts {
            Some(hearts) if hearts.last_refill >= last_auto_refill => hearts,
            _ => Hearts {
                hearts: self.config.hearts_max,
                last_refill: last_auto_refill,
            },
        }
    }

    fn last_auto_refill(&self) -> DateTime<Utc> {
        let now = self.time.now();
        let today_with_time = now.with_time(self.config.auto_refill_time).unwrap();
        if today_with_time <= now {
            today_with_time
        } else {
            today_with_time - TimeDelta::days(1)
        }
    }
}
